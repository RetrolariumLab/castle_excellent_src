#!/usr/bin/env python3
"""Decode and validate Castle Excellent's room/object collision tables."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
PLAYER_FLAGS_CPU = 0xA95A
OBJECT_FLAGS_CPU = 0xAA22
OBJECT_WIDTHS_CPU = 0xAAEA
OBJECT_HEIGHTS_CPU = 0xAB1A
ROOM_OBJECT_COUNTS_CPU = 0xAB4A
ROOM_CELL_TYPE_COUNT = 100
ROOM_CELL_HALF_COUNT = 2
ROOM_CELL_FLAG_COUNT = ROOM_CELL_TYPE_COUNT * ROOM_CELL_HALF_COUNT
OBJECT_TYPE_FIRST = 0x80
OBJECT_DIMENSION_COUNT = 48
OBJECT_TYPE_END = OBJECT_TYPE_FIRST + OBJECT_DIMENSION_COUNT

EXPECTED_PLAYER_FLAGS = bytes.fromhex(
    "01 01 01 01 01 01 01 01 01 01 01 01 00 01 01 00 "
    "01 01 01 01 00 01 00 00 01 00 00 00 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 00 00 00 00 00 00 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 80 80 "
    "80 80 80 80 80 80 80 80 80 80 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 00 00 01 00 00 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 "
    "00 00 01 01 00 00 00 00 00 00 00 00 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 00 00 00 00"
)
EXPECTED_OBJECT_FLAGS = bytes.fromhex(
    "01 01 01 01 01 01 01 01 01 01 01 01 00 01 01 00 "
    "01 01 01 01 00 01 00 01 01 00 01 00 01 01 01 01 "
    "01 01 01 01 00 00 00 00 00 00 00 00 00 00 00 00 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 81 81 "
    "81 81 81 81 81 81 81 81 81 81 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 00 00 01 00 00 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 00 00 00 00 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 "
    "01 01 01 01 01 01 01 01"
)
EXPECTED_WIDTHS = bytes.fromhex(
    "10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 "
    "08 08 08 08 08 08 10 10 10 10 10 10 10 10 10 10 "
    "10 10 20 10 10 10 08 10 10 10 10 10 10 10 10 10"
)
EXPECTED_HEIGHTS = bytes.fromhex(
    "10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 "
    "10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 "
    "10 08 08 08 08 08 08 10 10 10 10 10 10 10 10 10"
)
EXPECTED_CONSUMERS = {
    0x861D: bytes.fromhex("F9 9A AA"),
    0x863B: bytes.fromhex("F9 6A AA"),
    0x8B88: bytes.fromhex("B9 6A AA"),
    0x8E0C: bytes.fromhex("BD 5A A9"),
    0x8E55: bytes.fromhex("F9 9A AA"),
    0x8E93: bytes.fromhex("F9 6A AA"),
    0x998F: bytes.fromhex("B9 6A AA"),
    0x9C6F: bytes.fromhex("BD 49 AB"),
    0x9F46: bytes.fromhex("BE 49 AB"),
    0xA124: bytes.fromhex("BD 22 AA"),
    0xA159: bytes.fromhex("F9 9A AA"),
    0xA178: bytes.fromhex("F9 6A AA"),
    0xA1BE: bytes.fromhex("BD 22 AA"),
    0xA1FD: bytes.fromhex("F9 9A AA"),
    0xA21C: bytes.fromhex("F9 6A AA"),
    0xA25B: bytes.fromhex("F9 9A AA"),
    0xA263: bytes.fromhex("F9 6A AA"),
    0xECF7: bytes.fromhex("BD 49 AB"),
}


class CollisionTableError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionFlags:
    raw: int
    negative: bool
    carry: bool


@dataclass(frozen=True)
class CollisionDimensions:
    runtime_type: int
    width: int
    height: int


def room_cell_half_index(cell: int, half: int) -> int:
    if not 0 <= cell < ROOM_CELL_TYPE_COUNT:
        raise CollisionTableError(f"room-cell type outside 0-99: {cell}")
    if half not in (0, 1):
        raise CollisionTableError(f"room-cell half outside 0-1: {half}")
    return cell * ROOM_CELL_HALF_COUNT + half


def decode_collision_flags(table: bytes, cell: int, half: int) -> CollisionFlags:
    if len(table) != ROOM_CELL_FLAG_COUNT:
        raise CollisionTableError(
            f"collision flag table has {len(table)} bytes, expected {ROOM_CELL_FLAG_COUNT}"
        )
    raw = table[room_cell_half_index(cell, half)]
    return CollisionFlags(raw, bool(raw & 0x80), bool(raw & 0x01))


def collision_dimensions(
    widths: bytes, heights: bytes, runtime_type: int
) -> CollisionDimensions:
    if len(widths) != OBJECT_DIMENSION_COUNT or len(heights) != OBJECT_DIMENSION_COUNT:
        raise CollisionTableError("runtime-object dimension table size changed")
    if not OBJECT_TYPE_FIRST <= runtime_type < OBJECT_TYPE_END:
        raise CollisionTableError(f"runtime type outside $80-$AF: ${runtime_type:02X}")
    index = runtime_type - OBJECT_TYPE_FIRST
    return CollisionDimensions(runtime_type, widths[index], heights[index])


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise CollisionTableError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise CollisionTableError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start:start + size]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    tables = (
        (PLAYER_FLAGS_CPU, EXPECTED_PLAYER_FLAGS, "player collision flags"),
        (OBJECT_FLAGS_CPU, EXPECTED_OBJECT_FLAGS, "object collision flags"),
        (OBJECT_WIDTHS_CPU, EXPECTED_WIDTHS, "object collision widths"),
        (OBJECT_HEIGHTS_CPU, EXPECTED_HEIGHTS, "object collision heights"),
    )
    for address, expected, name in tables:
        if read_cpu_range(prg, address, len(expected)) != expected:
            raise CollisionTableError(f"{name} changed")
    for address, expected in EXPECTED_CONSUMERS.items():
        if read_cpu_range(prg, address, len(expected)) != expected:
            raise CollisionTableError(f"collision-table consumer ${address:04X} changed")
    if OBJECT_HEIGHTS_CPU + OBJECT_DIMENSION_COUNT != ROOM_OBJECT_COUNTS_CPU:
        raise CollisionTableError("collision tables no longer meet room metadata")
    return {
        "range": [PLAYER_FLAGS_CPU, ROOM_OBJECT_COUNTS_CPU - 1],
        "bytes": ROOM_OBJECT_COUNTS_CPU - PLAYER_FLAGS_CPU,
        "consumers": len(EXPECTED_CONSUMERS),
    }


def validate_table_contract() -> dict[str, object]:
    covered_indexes = []
    for cell in range(ROOM_CELL_TYPE_COUNT):
        for half in range(ROOM_CELL_HALF_COUNT):
            index = room_cell_half_index(cell, half)
            if index != len(covered_indexes):
                raise CollisionTableError("room-cell half index is not contiguous")
            covered_indexes.append(index)
            decode_collision_flags(EXPECTED_PLAYER_FLAGS, cell, half)
            decode_collision_flags(EXPECTED_OBJECT_FLAGS, cell, half)
    if covered_indexes != list(range(ROOM_CELL_FLAG_COUNT)):
        raise CollisionTableError("room-cell collision tables are not fully covered")
    if set(EXPECTED_PLAYER_FLAGS) != {0x00, 0x01, 0x80}:
        raise CollisionTableError("unexpected player collision flag domain")
    if set(EXPECTED_OBJECT_FLAGS) != {0x00, 0x01, 0x81}:
        raise CollisionTableError("unexpected object collision flag domain")

    dimensions = [
        collision_dimensions(EXPECTED_WIDTHS, EXPECTED_HEIGHTS, runtime_type)
        for runtime_type in range(OBJECT_TYPE_FIRST, OBJECT_TYPE_END)
    ]
    if {item.width for item in dimensions} != {8, 16, 32}:
        raise CollisionTableError("unexpected runtime-object width domain")
    if {item.height for item in dimensions} != {8, 16}:
        raise CollisionTableError("unexpected runtime-object height domain")

    return {
        "room_cell_half_indexes": len(covered_indexes),
        "player_flag_counts": {
            f"0x{value:02X}": EXPECTED_PLAYER_FLAGS.count(value)
            for value in sorted(set(EXPECTED_PLAYER_FLAGS))
        },
        "object_flag_counts": {
            f"0x{value:02X}": EXPECTED_OBJECT_FLAGS.count(value)
            for value in sorted(set(EXPECTED_OBJECT_FLAGS))
        },
        "runtime_object_types": len(dimensions),
        "dimensions": [asdict(item) for item in dimensions],
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    report: dict[str, object] = {"rom": validate_rom_contract(prg)}
    table_report = validate_table_contract()
    if validate:
        report["tables"] = table_report
    else:
        report["summary"] = {
            "player_flag_counts": table_report["player_flag_counts"],
            "object_flag_counts": table_report["object_flag_counts"],
            "runtime_object_types": table_report["runtime_object_types"],
        }
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, CollisionTableError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated two 100x2 room-cell flag tables, 48 object "
            f"dimensions, and {len(EXPECTED_CONSUMERS)} exact consumers"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
