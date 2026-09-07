#!/usr/bin/env python3
"""Model the runtime type-$81/$82 collision handlers at $8D57-$8DAA."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass, replace
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
TYPE82_CPU = 0x8D57
TYPE81_CPU = 0x8D70
ROUTINE_END = 0x8DAB
PLAYER_HANDLER_TABLE_CPU = 0x9334
DOWN_HANDLER_TABLE_CPU = 0x8FF1
UP_HANDLER_TABLE_CPU = 0x9107
HORIZONTAL_HANDLER_TABLE_CPU = 0x921D
NO_OP_HANDLER_CPU = 0x926B
PROXIMITY_CPU = 0xA8A9
LOAD_AUDIO_TRACK_SET_4_CPU = 0xB885
LOAD_AUDIO_TRACK_SET_7_CPU = 0xB88D
COMPLETION_CPU = 0xFE8E
REPLACEMENT_TYPE = 0x91
CLONE_ROOM = 0x59
HORIZONTAL_SHIFT = 0x10
TYPE82_BYTES = bytes.fromhex(
    "AD CC 07 D0 13 20 A9 A8 B0 0E 20 85 B8 A5 DB 05 DC D0 FA 68 68 4C 8E FE 60"
)
TYPE81_BYTES = bytes.fromhex(
    "20 A9 A8 B0 FA 20 8D B8 A5 DB 05 DC D0 FA A6 41 A9 91 95 4A B5 4B 38 E9 10 "
    "95 4B B0 02 D6 4C A5 37 C9 59 D0 15 A9 91 85 D4 B5 4B 38 E9 10 85 D5 B5 4C "
    "E9 00 85 D6 B5 4D 85 D7 60"
)
TYPE82_SHA256 = "92025b2c4f40de949e042221dc88524a9453ead92f83bdbee936df103d5a8967"
TYPE81_SHA256 = "38ae7747ecc931274cf96a431d5e75452dd55d30f97c455f65975f4a6fe840eb"


class RuntimeTypes8182Error(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeRecord:
    runtime_type: int
    x: int
    y: int
    state: int
    byte5: int


@dataclass(frozen=True)
class Type82Result:
    load_audio_track_set_4: bool
    discarded_stack_bytes: int
    completion_target: int | None


@dataclass(frozen=True)
class Type81Result:
    current: RuntimeRecord
    clone: RuntimeRecord
    load_audio_track_set_7: bool
    clone_written: bool


def _require_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RuntimeTypes8182Error(f"{name} outside 0-255: {value}")


def _validate_record(record: RuntimeRecord, name: str) -> None:
    _require_byte(record.runtime_type, f"{name} type")
    if not 0 <= record.x <= 0xFFFF:
        raise RuntimeTypes8182Error(f"{name} X outside 0-65535: {record.x}")
    for value, field in ((record.y, "Y"), (record.state, "state"), (record.byte5, "byte5")):
        _require_byte(value, f"{name} {field}")


def collide_runtime_type82(game_over_active: int, near_player: bool) -> Type82Result:
    _require_byte(game_over_active, "game-over flag")
    if game_over_active or not near_player:
        return Type82Result(False, 0, None)
    return Type82Result(True, 2, COMPLETION_CPU)


def collide_runtime_type81(
    room: int,
    near_player: bool,
    current: RuntimeRecord,
    clone: RuntimeRecord,
) -> Type81Result:
    _require_byte(room, "room")
    _validate_record(current, "current record")
    _validate_record(clone, "clone record")
    if not near_player:
        return Type81Result(current, clone, False, False)
    shifted = replace(
        current,
        runtime_type=REPLACEMENT_TYPE,
        x=(current.x - HORIZONTAL_SHIFT) & 0xFFFF,
    )
    if room != CLONE_ROOM:
        return Type81Result(shifted, clone, True, False)
    spawned = replace(
        clone,
        runtime_type=REPLACEMENT_TYPE,
        x=(shifted.x - HORIZONTAL_SHIFT) & 0xFFFF,
        y=shifted.y,
    )
    return Type81Result(shifted, spawned, True, True)


def audio_waits(pointer_lo: int, pointer_hi: int) -> bool:
    _require_byte(pointer_lo, "audio pointer low")
    _require_byte(pointer_hi, "audio pointer high")
    return bool(pointer_lo | pointer_hi)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RuntimeTypes8182Error("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise RuntimeTypes8182Error("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def _entry(table_cpu: int, runtime_type: int) -> int:
    return table_cpu + (runtime_type - 0x80) * 2


def _require_call(prg: bytes, source: int, target: int, opcode: int = 0x20) -> None:
    expected = bytes((opcode, target & 0xFF, target >> 8))
    offset = source - PRG_BASE
    if prg[offset:offset + 3] != expected:
        raise RuntimeTypes8182Error(
            f"expected ${opcode:02X} target ${target:04X} at ${source:04X}"
        )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    type82_start = TYPE82_CPU - PRG_BASE
    type81_start = TYPE81_CPU - PRG_BASE
    if prg[type82_start:type81_start] != TYPE82_BYTES:
        raise RuntimeTypes8182Error("runtime type $82 handler bytes changed")
    if prg[type81_start:ROUTINE_END - PRG_BASE] != TYPE81_BYTES:
        raise RuntimeTypes8182Error("runtime type $81 handler bytes changed")
    if hashlib.sha256(TYPE82_BYTES).hexdigest() != TYPE82_SHA256:
        raise RuntimeTypes8182Error("runtime type $82 handler hash changed")
    if hashlib.sha256(TYPE81_BYTES).hexdigest() != TYPE81_SHA256:
        raise RuntimeTypes8182Error("runtime type $81 handler hash changed")
    expected_pointers = {
        _entry(PLAYER_HANDLER_TABLE_CPU, 0x81): TYPE81_CPU,
        _entry(PLAYER_HANDLER_TABLE_CPU, 0x82): TYPE82_CPU,
    }
    for table_cpu in (DOWN_HANDLER_TABLE_CPU, UP_HANDLER_TABLE_CPU, HORIZONTAL_HANDLER_TABLE_CPU):
        expected_pointers[_entry(table_cpu, 0x81)] = TYPE81_CPU
        expected_pointers[_entry(table_cpu, 0x82)] = NO_OP_HANDLER_CPU
    for address, expected in expected_pointers.items():
        if _read_word(prg, address) != expected:
            raise RuntimeTypes8182Error(f"collision pointer at ${address:04X} changed")
    for source in (0x8D5C, 0x8D70):
        _require_call(prg, source, PROXIMITY_CPU)
    _require_call(prg, 0x8D61, LOAD_AUDIO_TRACK_SET_4_CPU)
    _require_call(prg, 0x8D75, LOAD_AUDIO_TRACK_SET_7_CPU)
    _require_call(prg, 0x8D6C, COMPLETION_CPU, 0x4C)
    if prg[0x8D6A - PRG_BASE:0x8D6C - PRG_BASE] != b"\x68\x68":
        raise RuntimeTypes8182Error("type $82 synthetic-return discard changed")
    return {
        "routine_range": [TYPE82_CPU, ROUTINE_END - 1],
        "routine_bytes": len(TYPE82_BYTES) + len(TYPE81_BYTES),
        "pointer_entries": len(expected_pointers),
        "completion_target": COMPLETION_CPU,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    current = RuntimeRecord(0x81, 0, 0x44, 0x55, 0x66)
    clone = RuntimeRecord(0xAA, 0x1234, 0x77, 0x88, 0x99)
    for game_over in range(0x100):
        for near in (False, True):
            triggered = collide_runtime_type82(game_over, near)
            if bool(triggered.completion_target) != (game_over == 0 and near):
                raise RuntimeTypes8182Error("type $82 guard mismatch")
    for pointer_lo in range(0x100):
        for pointer_hi in range(0x100):
            if audio_waits(pointer_lo, pointer_hi) != bool(pointer_lo or pointer_hi):
                raise RuntimeTypes8182Error("audio wait predicate mismatch")
    for x in range(0x10000):
        result = collide_runtime_type81(CLONE_ROOM, True, replace(current, x=x), clone)
        if result.current.x != (x - 0x10) & 0xFFFF:
            raise RuntimeTypes8182Error("type $81 current X transform mismatch")
        if result.clone.x != (x - 0x20) & 0xFFFF:
            raise RuntimeTypes8182Error("type $81 clone X transform mismatch")
    for room in range(0x100):
        result = collide_runtime_type81(room, True, current, clone)
        if result.clone_written != (room == CLONE_ROOM):
            raise RuntimeTypes8182Error("type $81 clone-room guard mismatch")
    for y in range(0x100):
        result = collide_runtime_type81(CLONE_ROOM, True, replace(current, y=y), clone)
        if result.clone.y != y:
            raise RuntimeTypes8182Error("type $81 clone Y mismatch")
    return {
        "type82_guard_cases": 0x200,
        "audio_pointer_pairs": 0x10000,
        "x_values": 0x10000,
        "room_values": 0x100,
        "y_values": 0x100,
    }


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
            "type82_completion": asdict(collide_runtime_type82(0, True)),
            "type81_room59": asdict(
                collide_runtime_type81(
                    CLONE_ROOM,
                    True,
                    RuntimeRecord(0x81, 0x0010, 0x40, 3, 4),
                    RuntimeRecord(0, 0, 0, 5, 6),
                )
            ),
        }
    except (OSError, RuntimeTypes8182Error) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated runtime type-$81/$82 handlers, eight collision "
            "pointers, terminal dispatch, and exhaustive machine-width states"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
