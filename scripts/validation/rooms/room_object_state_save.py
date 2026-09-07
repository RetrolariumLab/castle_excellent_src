#!/usr/bin/env python3
"""Model the 24-record persistent object-state save at $8758-$8784."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8758
ROUTINE_END = 0x8785
RECORD_SIZE = 6
RECORD_COUNT = 24
RECORD_BYTES = RECORD_SIZE * RECORD_COUNT
PERSISTENT_TYPE_FIRST = 0x80
PERSISTENT_TYPE_LAST = 0xA7
EXPECTED_CALL_SITES = (0x868C, 0x86B2, 0x86E6, 0x872F, 0x9434)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A2 00 38 B5 4A 10 02 C9 A8 66 18 66 17 66 16 8A 18 69 06 "
    "AA E0 90 90 EA A5 37 8D 12 07 A5 16 8D 13 07 A5 17 8D 14 "
    "07 A5 18 8D 15 07 60"
)


class RoomObjectStateSaveError(ValueError):
    pass


@dataclass(frozen=True)
class SavedRoomObjectState:
    room: int
    bitmap: bytes


def object_is_removed_or_transient(object_type: int) -> bool:
    if not 0 <= object_type <= 0xFF:
        raise RoomObjectStateSaveError(f"object type outside 0-255: {object_type}")
    return not PERSISTENT_TYPE_FIRST <= object_type <= PERSISTENT_TYPE_LAST


def save_current_room_object_state(
    runtime_records: bytes, current_room: int
) -> SavedRoomObjectState:
    if len(runtime_records) != RECORD_BYTES:
        raise RoomObjectStateSaveError(f"runtime pool must contain {RECORD_BYTES} bytes")
    if not 1 <= current_room <= 100:
        raise RoomObjectStateSaveError(f"room outside 1-100: {current_room}")
    bitmap = 0
    for slot in range(RECORD_COUNT):
        object_type = runtime_records[slot * RECORD_SIZE]
        if object_is_removed_or_transient(object_type):
            bitmap |= 1 << slot
    return SavedRoomObjectState(current_room, bitmap.to_bytes(3, "little"))


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomObjectStateSaveError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise RoomObjectStateSaveError("expected a complete 32 KiB PRG region")
    return image[start:end]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    if prg[start:start + len(EXPECTED_ROUTINE_BYTES)] != EXPECTED_ROUTINE_BYTES:
        raise RoomObjectStateSaveError("room object-state save bytes changed")
    opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    call_sites = tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - 2)
        if prg[offset:offset + 3] == opcode
    )
    if call_sites != EXPECTED_CALL_SITES:
        raise RoomObjectStateSaveError("room object-state save call sites changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(call_sites),
        "record_count": RECORD_COUNT,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    for object_type in range(0x100):
        expected = not PERSISTENT_TYPE_FIRST <= object_type <= PERSISTENT_TYPE_LAST
        if object_is_removed_or_transient(object_type) != expected:
            raise RoomObjectStateSaveError("object persistence classification mismatch")
    for slot in range(RECORD_COUNT):
        records = bytearray(RECORD_BYTES)
        records[slot * RECORD_SIZE] = PERSISTENT_TYPE_FIRST
        bitmap = int.from_bytes(
            save_current_room_object_state(bytes(records), 1).bitmap, "little"
        )
        if bitmap != 0xFFFFFF ^ (1 << slot):
            raise RoomObjectStateSaveError("object-state slot/bit mapping mismatch")
    return {"object_types": 0x100, "record_slots": RECORD_COUNT}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
        empty_pool = save_current_room_object_state(bytes(RECORD_BYTES), 71)
        report["empty_pool"] = {
            "room": empty_pool.room,
            "bitmap_hex": empty_pool.bitmap.hex(),
        }
    except (OSError, RoomObjectStateSaveError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated five calls, 24 object-state bits, all 256 type "
            "values, and the exact 45-byte save routine"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
