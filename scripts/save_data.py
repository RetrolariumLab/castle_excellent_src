#!/usr/bin/env python3
"""Decode and encode Castle Excellent's 394-byte save-data payload."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
RUNTIME_STATE_SIZE = 14
MUTABLE_REGION_SIZE = 120
OBJECT_REGION_SIZE = 150
VISITED_FLAGS_SIZE = 100
SIGNATURE_SIZE = 8
PAYLOAD_SIZE = 394
BACKWARD_SIGNATURE_ADDRESS = 0xFC99
BACKWARD_SIGNATURE_TEXT = b"GNUTUEDEB"
WIRE_SIGNATURE = b"BEDEUTUN"
RUNTIME_OFFSET = 2
MUTABLE_OFFSET = RUNTIME_OFFSET + RUNTIME_STATE_SIZE
OBJECT_OFFSET = MUTABLE_OFFSET + MUTABLE_REGION_SIZE
VISITED_OFFSET = OBJECT_OFFSET + OBJECT_REGION_SIZE
SIGNATURE_OFFSET = VISITED_OFFSET + VISITED_FLAGS_SIZE


class SaveDataError(ValueError):
    pass


@dataclass(frozen=True)
class SaveState:
    room_index: int
    runtime_tail: int
    runtime_state: bytes
    mutable_region: bytes
    object_region: bytes
    visited_flags: bytes


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise SaveDataError(f"{name} outside 0-255: {value}")


def _validate_region(data: bytes, size: int, name: str) -> None:
    if len(data) != size:
        raise SaveDataError(f"{name} must contain {size} bytes, got {len(data)}")


def encode_payload(state: SaveState) -> bytes:
    _validate_byte(state.room_index, "room index")
    _validate_byte(state.runtime_tail, "runtime tail")
    _validate_region(state.runtime_state, RUNTIME_STATE_SIZE, "runtime state")
    _validate_region(state.mutable_region, MUTABLE_REGION_SIZE, "mutable region")
    _validate_region(state.object_region, OBJECT_REGION_SIZE, "object region")
    _validate_region(state.visited_flags, VISITED_FLAGS_SIZE, "visited flags")
    payload = b"".join(
        (
            bytes((state.room_index, state.runtime_tail)),
            state.runtime_state,
            state.mutable_region[::-1],
            state.object_region[::-1],
            state.visited_flags[::-1],
            WIRE_SIGNATURE,
        )
    )
    if len(payload) != PAYLOAD_SIZE:
        raise SaveDataError(f"encoded payload has unexpected size {len(payload)}")
    return payload


def decode_payload(payload: bytes) -> SaveState:
    if len(payload) != PAYLOAD_SIZE:
        raise SaveDataError(f"save payload must contain {PAYLOAD_SIZE} bytes")
    if payload[SIGNATURE_OFFSET:] != WIRE_SIGNATURE:
        raise SaveDataError("save payload signature mismatch")
    return SaveState(
        room_index=payload[0],
        runtime_tail=payload[1],
        runtime_state=payload[RUNTIME_OFFSET:MUTABLE_OFFSET],
        mutable_region=payload[MUTABLE_OFFSET:OBJECT_OFFSET][::-1],
        object_region=payload[OBJECT_OFFSET:VISITED_OFFSET][::-1],
        visited_flags=payload[VISITED_OFFSET:SIGNATURE_OFFSET][::-1],
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise SaveDataError("image is not an iNES ROM")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 0x4000
    prg_start = 16 + trainer_size
    prg = image[prg_start : prg_start + prg_size]
    if len(prg) != PRG_SIZE:
        raise SaveDataError(f"expected {PRG_SIZE} PRG bytes, got {len(prg)}")
    return prg


def validate_save_data(image: bytes) -> dict[str, object]:
    prg = extract_prg(image)
    signature_offset = BACKWARD_SIGNATURE_ADDRESS - PRG_BASE
    backward_text = prg[signature_offset : signature_offset + len(BACKWARD_SIGNATURE_TEXT)]
    if backward_text != BACKWARD_SIGNATURE_TEXT:
        raise SaveDataError(f"unexpected backward signature text: {backward_text!r}")
    if backward_text[1:][::-1] != WIRE_SIGNATURE:
        raise SaveDataError("ROM signature traversal does not produce the wire signature")
    state = SaveState(
        room_index=100,
        runtime_tail=0xA5,
        runtime_state=bytes(range(RUNTIME_STATE_SIZE)),
        mutable_region=bytes(value & 0xFF for value in range(MUTABLE_REGION_SIZE)),
        object_region=bytes((value * 3) & 0xFF for value in range(OBJECT_REGION_SIZE)),
        visited_flags=bytes((value * 5) & 0xFF for value in range(VISITED_FLAGS_SIZE)),
    )
    payload = encode_payload(state)
    if decode_payload(payload) != state:
        raise SaveDataError("save payload failed its encode/decode round trip")
    return {
        "payload_size": PAYLOAD_SIZE,
        "field_offsets": {
            "room_index": 0,
            "runtime_tail": 1,
            "runtime_state": RUNTIME_OFFSET,
            "mutable_region": MUTABLE_OFFSET,
            "object_region": OBJECT_OFFSET,
            "visited_flags": VISITED_OFFSET,
            "signature": SIGNATURE_OFFSET,
        },
        "field_sizes": {
            "runtime_state": RUNTIME_STATE_SIZE,
            "mutable_region": MUTABLE_REGION_SIZE,
            "object_region": OBJECT_REGION_SIZE,
            "visited_flags": VISITED_FLAGS_SIZE,
            "signature": SIGNATURE_SIZE,
        },
        "wire_signature": WIRE_SIGNATURE.decode("ascii"),
        "rom_signature_text": backward_text.decode("ascii"),
        "descending_regions": ["mutable_region", "object_region", "visited_flags"],
        "unchecked_receive_status_offsets": [1],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_save_data(Path(args.image).read_bytes())
    except (OSError, SaveDataError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated the 394-byte save payload and exact ROM signature")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
