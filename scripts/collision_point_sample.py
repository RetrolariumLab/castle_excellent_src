#!/usr/bin/env python3
"""Model the room-cell/runtime-object point sampler at $A0C4-$A1A2."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

try:
    from . import collision_tables, object_collision_filters
except ImportError:
    import collision_tables
    import object_collision_filters


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA0C4
ROUTINE_END = 0xA1A3
ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_PIXEL_WIDTH = ROOM_WIDTH * 16
ROOM_PIXEL_HEIGHT = ROOM_HEIGHT * 8
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
EMPTY_ROOM_CELL = 0x53
RECORD_SIZE = 6
RECORD_COUNT = 24
RECORD_BYTES = RECORD_SIZE * RECORD_COUNT
TYPE_FIRST = 0x80
TYPE_END = 0xA8
PAIR_INDEX_FIRST = 0x8A
PAIR_INDEX_END = 0x92
OFFSET_TABLE_CPU = 0x8F10
EXPECTED_OFFSET_TABLE = bytes(range(0, RECORD_BYTES + 1, RECORD_SIZE))
EXPECTED_CALL_SITES = (
    0x955D,
    0x9B2B,
    0x9B4D,
    0x9B6F,
    0x9BBF,
    0x9C0F,
    0x9D10,
    0x9D31,
    0x9D41,
    0x9D51,
    0x9DFF,
    0x9E0D,
    0x9E1B,
    0x9E2E,
    0x9E3E,
    0x9E4E,
    0x9E59,
    0x9E69,
    0x9E79,
    0x9E84,
    0x9E94,
    0x9EA4,
    0x9F0A,
    0x9F1B,
    0x9F2A,
    0x9F3F,
    0x9F8F,
    0x9FA0,
    0x9FD0,
    0x9FE1,
)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "C0 A0 90 06 18 A9 53 A0 00 60 85 28 86 27 85 2A 86 29 84 1B "
    "A9 00 85 2C 98 4A 4A 4A 85 2B 06 2B 26 2C 06 2B 26 2C 18 65 "
    "2B 85 2B 90 02 E6 2C 06 2B 26 2C 06 2B 26 2C A9 04 18 65 2C "
    "85 2C 46 2A 66 29 46 2A 66 29 46 2A 66 29 46 2A 66 29 A4 29 "
    "B1 2B C9 53 F0 22 AA A5 27 4A 4A 4A 4A 8A 2A AA BD 22 AA F0 "
    "13 20 CA A6 D0 06 A4 40 10 02 A9 00 48 4A 68 08 8A 4A 28 60 "
    "A0 00 84 1D A4 1D BE 10 8F E4 41 F0 4C B5 4A F0 48 C9 A8 B0 "
    "44 A8 A5 1B 38 F5 4D 90 3C F9 9A AA B0 37 A5 27 85 2B A5 28 "
    "85 2C A5 2B 38 F5 4B 85 2B A5 2C F5 4C 85 2C 90 20 A5 2B "
    "38 F9 6A AA 85 2B A5 2C E9 00 85 2C B0 10 86 42 B5 4A 20 91 "
    "A0 18 F0 01 38 B5 4A A0 01 60 E6 1D A5 1D C9 18 90 A3 18 A9 "
    "53 A0 00 60"
)


class CollisionPointSampleError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int = 0
    x: int = 0
    y: int = 0


@dataclass(frozen=True)
class CollisionSample:
    accumulator: int
    x_register: int
    y_register: int
    carry: bool
    negative: bool
    zero: bool
    source: str
    object_offset: int | None = None
    raw_collision_flags: int | None = None


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise CollisionPointSampleError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise CollisionPointSampleError(f"{name} outside 0-65535: {value}")


def _validate_runtime_object(record: RuntimeObject) -> None:
    _validate_byte(record.runtime_type, "runtime type")
    _validate_word(record.x, "runtime object X")
    _validate_byte(record.y, "runtime object Y")
    if record.runtime_type and record.runtime_type < TYPE_FIRST:
        raise CollisionPointSampleError(
            "active runtime records must retain their high-bit type marker"
        )


def room_cell_index(x: int, y: int) -> int | None:
    if not 0 <= x < ROOM_PIXEL_WIDTH:
        raise CollisionPointSampleError(
            f"collision X outside room pixel domain 0-{ROOM_PIXEL_WIDTH - 1}: {x}"
        )
    _validate_byte(y, "collision Y")
    if y >= ROOM_PIXEL_HEIGHT:
        return None
    return (y >> 3) * ROOM_WIDTH + (x >> 4)


def _empty_sample(x_register: int) -> CollisionSample:
    return CollisionSample(
        accumulator=EMPTY_ROOM_CELL,
        x_register=x_register,
        y_register=0,
        carry=False,
        negative=False,
        zero=True,
        source="empty",
    )


def sample_collision_at_pixel(
    room_cells: bytes,
    records: tuple[RuntimeObject, ...],
    *,
    x: int,
    y: int,
    current_object_offset: int = 0xFF,
    animation_counter: int = 0,
) -> CollisionSample:
    if len(room_cells) != ROOM_CELL_COUNT:
        raise CollisionPointSampleError(
            f"room buffer has {len(room_cells)} bytes, expected {ROOM_CELL_COUNT}"
        )
    if any(cell >= collision_tables.ROOM_CELL_TYPE_COUNT for cell in room_cells):
        raise CollisionPointSampleError("room buffer contains a cell type above 99")
    if len(records) != RECORD_COUNT:
        raise CollisionPointSampleError(
            f"runtime pool has {len(records)} records, expected {RECORD_COUNT}"
        )
    for record in records:
        _validate_runtime_object(record)
    _validate_word(x, "collision X")
    _validate_byte(y, "collision Y")
    _validate_byte(current_object_offset, "current object offset")
    _validate_byte(animation_counter, "animation counter")

    cell_index = room_cell_index(x, y)
    if cell_index is None:
        return _empty_sample(x & 0xFF)

    cell = room_cells[cell_index]
    half = (x >> 3) & 1
    pair_index = cell * 2 + half
    raw_flags = collision_tables.EXPECTED_OBJECT_FLAGS[pair_index]
    if cell != EMPTY_ROOM_CELL and raw_flags:
        pair_matched = PAIR_INDEX_FIRST <= pair_index < PAIR_INDEX_END
        effective_flags = raw_flags
        y_register = 0 if pair_matched else 0xFF
        if pair_matched:
            y_register = animation_counter
            if animation_counter & 0x80:
                effective_flags = 0
        return CollisionSample(
            accumulator=cell,
            x_register=pair_index,
            y_register=y_register,
            carry=bool(effective_flags & 0x01),
            negative=bool(effective_flags & 0x80),
            zero=effective_flags == 0,
            source="room-cell",
            raw_collision_flags=raw_flags,
        )

    last_offset = 0
    for object_index, record in enumerate(records):
        object_offset = object_index * RECORD_SIZE
        last_offset = object_offset
        if object_offset == current_object_offset:
            continue
        if not TYPE_FIRST <= record.runtime_type < TYPE_END:
            continue
        type_index = record.runtime_type - TYPE_FIRST
        height = collision_tables.EXPECTED_HEIGHTS[type_index]
        width = collision_tables.EXPECTED_WIDTHS[type_index]
        if not record.y <= y < record.y + height:
            continue
        if not record.x <= x < record.x + width:
            continue
        solid = bool(
            object_collision_filters.get_runtime_object_solid_flag(
                record.runtime_type
            )
        )
        return CollisionSample(
            accumulator=record.runtime_type,
            x_register=object_offset,
            y_register=1,
            carry=solid,
            negative=False,
            zero=False,
            source="runtime-object",
            object_offset=object_offset,
        )
    return _empty_sample(last_offset)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise CollisionPointSampleError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise CollisionPointSampleError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise CollisionPointSampleError(f"truncated PRG range at ${address:04X}")
    return result


def find_call_sites(prg: bytes) -> tuple[int, ...]:
    opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(opcode) + 1)
        if prg[offset:offset + len(opcode)] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if _read_cpu_range(prg, ROUTINE_CPU, len(EXPECTED_ROUTINE_BYTES)) != EXPECTED_ROUTINE_BYTES:
        raise CollisionPointSampleError("collision point-sampler bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise CollisionPointSampleError("collision point-sampler call sites changed")
    if _read_cpu_range(prg, OFFSET_TABLE_CPU, len(EXPECTED_OFFSET_TABLE)) != EXPECTED_OFFSET_TABLE:
        raise CollisionPointSampleError("runtime-object offset table changed")
    if _read_cpu_range(
        prg, collision_tables.OBJECT_FLAGS_CPU, collision_tables.ROOM_CELL_FLAG_COUNT
    ) != collision_tables.EXPECTED_OBJECT_FLAGS:
        raise CollisionPointSampleError("object collision-flag table changed")
    if _read_cpu_range(
        prg, collision_tables.OBJECT_WIDTHS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    ) != collision_tables.EXPECTED_WIDTHS:
        raise CollisionPointSampleError("runtime collision-width table changed")
    if _read_cpu_range(
        prg, collision_tables.OBJECT_HEIGHTS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    ) != collision_tables.EXPECTED_HEIGHTS:
        raise CollisionPointSampleError("runtime collision-height table changed")
    object_collision_filters.validate_rom_contract(prg)
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(EXPECTED_CALL_SITES),
        "room_geometry": [ROOM_WIDTH, ROOM_HEIGHT],
        "runtime_records": RECORD_COUNT,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    empty_records = (RuntimeObject(),) * RECORD_COUNT
    coordinate_cases = 0
    coordinate_room = bytes([EMPTY_ROOM_CELL]) * ROOM_CELL_COUNT
    for y in range(ROOM_PIXEL_HEIGHT):
        for x in range(ROOM_PIXEL_WIDTH):
            expected_index = (y // 8) * ROOM_WIDTH + (x // 16)
            if room_cell_index(x, y) != expected_index:
                raise CollisionPointSampleError("room-cell address mismatch")
            coordinate_cases += 1

    cell_cases = 0
    for cell in range(collision_tables.ROOM_CELL_TYPE_COUNT):
        room = bytes([cell]) * ROOM_CELL_COUNT
        for half in (0, 1):
            for animation_counter in (0x00, 0x80):
                sample = sample_collision_at_pixel(
                    room,
                    empty_records,
                    x=half * 8,
                    y=0,
                    animation_counter=animation_counter,
                )
                raw = collision_tables.EXPECTED_OBJECT_FLAGS[cell * 2 + half]
                expected_room_source = cell != EMPTY_ROOM_CELL and raw != 0
                if (sample.source == "room-cell") != expected_room_source:
                    raise CollisionPointSampleError("room-cell flag routing mismatch")
                if expected_room_source:
                    special = PAIR_INDEX_FIRST <= cell * 2 + half < PAIR_INDEX_END
                    effective = 0 if special and animation_counter & 0x80 else raw
                    if sample.carry != bool(effective & 1):
                        raise CollisionPointSampleError("room-cell carry mismatch")
                    if sample.negative != bool(effective & 0x80):
                        raise CollisionPointSampleError("room-cell negative mismatch")
                cell_cases += 1

    runtime_type_cases = 0
    room = bytes([EMPTY_ROOM_CELL]) * ROOM_CELL_COUNT
    for runtime_type in range(TYPE_FIRST, TYPE_END):
        records = (RuntimeObject(runtime_type, 100, 50),) + (RuntimeObject(),) * 23
        sample = sample_collision_at_pixel(room, records, x=100, y=50)
        if sample.source != "runtime-object":
            raise CollisionPointSampleError("accepted runtime type did not match")
        expected_solid = bool(
            object_collision_filters.get_runtime_object_solid_flag(runtime_type)
        )
        if sample.carry != expected_solid:
            raise CollisionPointSampleError("runtime-object solidity mismatch")
        runtime_type_cases += 1

    geometry_cases = 0
    record = RuntimeObject(TYPE_FIRST, 100, 50)
    records = (record,) + (RuntimeObject(),) * 23
    width = collision_tables.EXPECTED_WIDTHS[0]
    height = collision_tables.EXPECTED_HEIGHTS[0]
    for y in range(ROOM_PIXEL_HEIGHT):
        for x in range(ROOM_PIXEL_WIDTH):
            sample = sample_collision_at_pixel(room, records, x=x, y=y)
            expected = 100 <= x < 100 + width and 50 <= y < 50 + height
            if (sample.source == "runtime-object") != expected:
                raise CollisionPointSampleError("runtime-object point geometry mismatch")
            geometry_cases += 1

    slot_cases = 0
    for slot in range(RECORD_COUNT):
        records = [RuntimeObject()] * RECORD_COUNT
        records[slot] = RuntimeObject(TYPE_FIRST, 100, 50)
        sample = sample_collision_at_pixel(room, tuple(records), x=100, y=50)
        if sample.object_offset != slot * RECORD_SIZE:
            raise CollisionPointSampleError("runtime-object scan order mismatch")
        slot_cases += 1
    return {
        "coordinate_cases": coordinate_cases,
        "cell_cases": cell_cases,
        "runtime_type_cases": runtime_type_cases,
        "geometry_cases": geometry_cases,
        "slot_cases": slot_cases,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report: dict[str, object] = {
        "rom": validate_rom_contract(extract_prg(image_path.read_bytes()))
    }
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    room = bytes([EMPTY_ROOM_CELL]) * ROOM_CELL_COUNT
    records = (RuntimeObject(0x80, 100, 50),) + (RuntimeObject(),) * 23
    report["sample"] = asdict(
        sample_collision_at_pixel(room, records, x=100, y=50)
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, CollisionPointSampleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        total = sum(cases.values())
        print(
            "[OK] validated 30 call sites, 24 runtime slots, and "
            f"{total:,} coordinate/cell/type/geometry cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
