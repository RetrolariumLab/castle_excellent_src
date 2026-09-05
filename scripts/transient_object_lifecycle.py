#!/usr/bin/env python3
"""Model runtime-object type 32, 40, and 41 lifecycle handlers."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass, replace
import json
from pathlib import Path
import sys

try:
    from . import runtime_object_dispatch
except ImportError:
    import runtime_object_dispatch


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_START = 0x9FF3
ROUTINE_END = 0xA044
REPLACEMENT_TABLE_CPU = 0xA00D
TYPE32_INDEX = 32
TYPE40_INDEX = 40
TYPE41_INDEX = 41
TYPE32_HANDLER = 0x9FF3
TYPE40_HANDLER = 0xA01C
TYPE41_HANDLER = 0xA033
TYPE40_STATE_LIMIT = 0x0F
FRAME_MODULO30_PERIOD = 30
EXPECTED_REPLACEMENT_TYPES = (
    0x84, 0x85, 0x85, 0x87, 0x87, 0x84, 0x84, 0x84,
    0x84, 0x87, 0x84, 0x85, 0x84, 0x85, 0x84,
)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "D6 4E F0 01 60 A5 00 29 01 F0 02 A9 FF 95 4E AD 6A 07 4A A8 B9 "
    "0D A0 95 4A 60 84 85 85 87 87 84 84 84 84 87 84 85 84 85 84 "
    "F6 4E B5 4E C9 0F 90 0E A9 00 95 4A 95 4B 95 4C 95 4D 95 4E "
    "95 4F 60 AD 6B 07 4A 90 06 B5 4D F0 02 D6 4D D6 4F F0 E1 60"
)


class TransientObjectLifecycleError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int
    x_lo: int
    x_hi: int
    y: int
    state: int
    byte5: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise TransientObjectLifecycleError(f"{name} outside 0-255: {value}")


def _validate_record(record: RuntimeObject) -> None:
    for field, value in asdict(record).items():
        _validate_byte(value, field.replace("_", " "))


def clear_runtime_object() -> RuntimeObject:
    return RuntimeObject(0, 0, 0, 0, 0, 0)


def update_type32(
    record: RuntimeObject, *, frame_counter: int, frame_modulo30: int
) -> RuntimeObject:
    _validate_record(record)
    _validate_byte(frame_counter, "frame counter")
    if not 0 <= frame_modulo30 < FRAME_MODULO30_PERIOD:
        raise TransientObjectLifecycleError(
            f"modulo-30 counter outside 0-29: {frame_modulo30}"
        )
    state = (record.state - 1) & 0xFF
    if state:
        return replace(record, state=state)
    return replace(
        record,
        runtime_type=EXPECTED_REPLACEMENT_TYPES[frame_modulo30 >> 1],
        state=0xFF if frame_counter & 1 else 0,
    )


def update_type40(record: RuntimeObject) -> RuntimeObject:
    _validate_record(record)
    state = (record.state + 1) & 0xFF
    if state >= TYPE40_STATE_LIMIT:
        return clear_runtime_object()
    return replace(record, state=state)


def update_type41(record: RuntimeObject, *, room_frame_counter: int) -> RuntimeObject:
    _validate_record(record)
    _validate_byte(room_frame_counter, "room frame counter")
    y = record.y
    if room_frame_counter & 1 and y:
        y -= 1
    lifetime = (record.byte5 - 1) & 0xFF
    if lifetime == 0:
        return clear_runtime_object()
    return replace(record, y=y, byte5=lifetime)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise TransientObjectLifecycleError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise TransientObjectLifecycleError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_START - PRG_BASE
    observed = prg[start:ROUTINE_END - PRG_BASE]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise TransientObjectLifecycleError("transient-object lifecycle bytes changed")
    table_start = REPLACEMENT_TABLE_CPU - PRG_BASE
    table = tuple(prg[table_start:table_start + len(EXPECTED_REPLACEMENT_TYPES)])
    if table != EXPECTED_REPLACEMENT_TYPES:
        raise TransientObjectLifecycleError("type-32 replacement table changed")
    pointers = runtime_object_dispatch.decode_handler_pointers(prg)
    expected_handlers = {
        TYPE32_INDEX: TYPE32_HANDLER,
        TYPE40_INDEX: TYPE40_HANDLER,
        TYPE41_INDEX: TYPE41_HANDLER,
    }
    if any(pointers[index] != address for index, address in expected_handlers.items()):
        raise TransientObjectLifecycleError("transient-object handler pointers changed")
    return {
        "routine_range": [ROUTINE_START, ROUTINE_END - 1],
        "routine_bytes": len(observed),
        "handler_pointers": expected_handlers,
        "replacement_table_address": REPLACEMENT_TABLE_CPU,
        "replacement_types": list(table),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    base = RuntimeObject(0xA0, 0x34, 0x01, 0x60, 0, 0x20)
    type32_state_cases = 0
    for state in range(0x100):
        result = update_type32(replace(base, state=state), frame_counter=0, frame_modulo30=0)
        decremented = (state - 1) & 0xFF
        expected_type = EXPECTED_REPLACEMENT_TYPES[0] if decremented == 0 else 0xA0
        if result.state != decremented or result.runtime_type != expected_type:
            raise TransientObjectLifecycleError("type-32 countdown mismatch")
        type32_state_cases += 1

    type32_replacement_cases = 0
    for frame_counter in range(0x100):
        for frame_modulo30 in range(FRAME_MODULO30_PERIOD):
            result = update_type32(
                replace(base, state=1),
                frame_counter=frame_counter,
                frame_modulo30=frame_modulo30,
            )
            expected_state = 0xFF if frame_counter & 1 else 0
            expected_type = EXPECTED_REPLACEMENT_TYPES[frame_modulo30 >> 1]
            if result.state != expected_state or result.runtime_type != expected_type:
                raise TransientObjectLifecycleError("type-32 replacement mismatch")
            type32_replacement_cases += 1

    type40_cases = 0
    for state in range(0x100):
        result = update_type40(replace(base, runtime_type=0xA8, state=state))
        incremented = (state + 1) & 0xFF
        expected = clear_runtime_object() if incremented >= TYPE40_STATE_LIMIT else replace(
            base, runtime_type=0xA8, state=incremented
        )
        if result != expected:
            raise TransientObjectLifecycleError("type-40 lifetime mismatch")
        type40_cases += 1

    type41_motion_cases = 0
    for room_frame_counter in range(0x100):
        for y in range(0x100):
            record = replace(base, runtime_type=0xA9, y=y, byte5=2)
            result = update_type41(record, room_frame_counter=room_frame_counter)
            expected_y = y - 1 if room_frame_counter & 1 and y else y
            if result.y != expected_y or result.byte5 != 1:
                raise TransientObjectLifecycleError("type-41 vertical motion mismatch")
            type41_motion_cases += 1

    type41_lifetime_cases = 0
    for lifetime in range(0x100):
        record = replace(base, runtime_type=0xA9, byte5=lifetime)
        result = update_type41(record, room_frame_counter=0)
        decremented = (lifetime - 1) & 0xFF
        expected = clear_runtime_object() if decremented == 0 else replace(
            record, byte5=decremented
        )
        if result != expected:
            raise TransientObjectLifecycleError("type-41 lifetime mismatch")
        type41_lifetime_cases += 1

    return {
        "type32_state_cases": type32_state_cases,
        "type32_replacement_cases": type32_replacement_cases,
        "type40_cases": type40_cases,
        "type41_motion_cases": type41_motion_cases,
        "type41_lifetime_cases": type41_lifetime_cases,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report = {"rom": validate_rom_contract(extract_prg(image_path.read_bytes()))}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, TransientObjectLifecycleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        print(
            "[OK] validated three transient handlers, 15 replacement types, and "
            f"{sum(cases.values()):,} state/frame cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
