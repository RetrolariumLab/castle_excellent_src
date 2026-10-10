#!/usr/bin/env python3
"""Model the runtime type-$9F player-collision handler at $8D3D-$8D56."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8D3D
ROUTINE_END = 0x8D57
RUNTIME_HANDLER_TABLE_CPU = 0x9334
RUNTIME_TYPE = 0x9F
NEXT_RUNTIME_TYPE = 0x82
NEXT_HANDLER_CPU = 0x8D57
LOAD_AUDIO_TRACK_SET_3_CPU = 0xB881
INVULNERABILITY_DURATION = 0x28
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "AD 6B 07 10 14 A6 41 B5 4B C5 38 F0 01 60 A5 0E D0 03 20 "
    "81 B8 A9 28 85 0E 60"
)


class PowerLightError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionResult:
    invulnerability_countdown: int
    load_audio_track_set_3: bool
    refreshed: bool


def _require_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PowerLightError(f"{name} outside 0-255: {value}")


def collide_runtime_type9f(
    room_frame: int,
    object_x_lo: int,
    player_x_lo: int,
    invulnerability_countdown: int,
) -> CollisionResult:
    for value, name in (
        (room_frame, "room frame"),
        (object_x_lo, "object X low"),
        (player_x_lo, "player X low"),
        (invulnerability_countdown, "invulnerability countdown"),
    ):
        _require_byte(value, name)
    if room_frame < 0x80 or object_x_lo != player_x_lo:
        return CollisionResult(invulnerability_countdown, False, False)
    return CollisionResult(
        INVULNERABILITY_DURATION,
        invulnerability_countdown == 0,
        True,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PowerLightError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise PowerLightError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def _handler_entry(runtime_type: int) -> int:
    return RUNTIME_HANDLER_TABLE_CPU + (runtime_type & 0x7F) * 2


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    if prg[start:start + len(EXPECTED_ROUTINE_BYTES)] != EXPECTED_ROUTINE_BYTES:
        raise PowerLightError("runtime type $9F handler bytes changed")
    handler_entry = _handler_entry(RUNTIME_TYPE)
    if _read_word(prg, handler_entry) != ROUTINE_CPU:
        raise PowerLightError("runtime type $9F collision pointer changed")
    next_entry = _handler_entry(NEXT_RUNTIME_TYPE)
    if _read_word(prg, next_entry) != NEXT_HANDLER_CPU:
        raise PowerLightError("next collision-handler boundary changed")
    audio_call = bytes(
        (0x20, LOAD_AUDIO_TRACK_SET_3_CPU & 0xFF, LOAD_AUDIO_TRACK_SET_3_CPU >> 8)
    )
    if EXPECTED_ROUTINE_BYTES.count(audio_call) != 1:
        raise PowerLightError("audio call topology changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "handler_entry": handler_entry,
        "next_handler_entry": next_entry,
        "audio_target": LOAD_AUDIO_TRACK_SET_3_CPU,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    cases = 0
    for room_frame in range(0x100):
        result = collide_runtime_type9f(room_frame, 0x55, 0x55, 7)
        if result.refreshed != (room_frame >= 0x80):
            raise PowerLightError("frame-phase guard mismatch")
        cases += 1
    for object_x in range(0x100):
        for player_x in range(0x100):
            result = collide_runtime_type9f(0x80, object_x, player_x, 7)
            if result.refreshed != (object_x == player_x):
                raise PowerLightError("X equality guard mismatch")
            cases += 1
    for countdown in range(0x100):
        result = collide_runtime_type9f(0xFF, 1, 1, countdown)
        if result != CollisionResult(INVULNERABILITY_DURATION, countdown == 0, True):
            raise PowerLightError("countdown refresh/audio guard mismatch")
        cases += 1
    return {"state_cases": cases, "frame_domain": 0x100, "x_pair_domain": 0x10000}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
        report["examples"] = {
            "inactive_phase": asdict(collide_runtime_type9f(0x7F, 1, 1, 0)),
            "first_match": asdict(collide_runtime_type9f(0x80, 1, 1, 0)),
            "active_match": asdict(collide_runtime_type9f(0xFF, 1, 1, 7)),
        }
    except (OSError, PowerLightError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated runtime type-$9F pointer, audio call, and "
            f"{report['exhaustive']['state_cases']} collision states"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
