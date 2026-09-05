#!/usr/bin/env python3
"""Model animated-cell and runtime-object collision filters at $A044-$A0C3."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
CLASSIFIER_CPU = 0xA044
TYPE_FILTER_CPU = 0xA05E
TYPE_FILTER_TABLE_CPU = 0xA06B
SOLID_FILTER_CPU = 0xA091
SOLID_FILTER_TABLE_CPU = 0xA09E
RUNTIME_TYPE_FIRST = 0x80
RUNTIME_TYPE_LAST_CONSUMED = 0xA7
PHYSICAL_TABLE_SIZE = 38
LOGICAL_TABLE_SIZE = 40
DECREMENTING_CELL_FIRST = 0x35
DECREMENTING_CELL_END = 0x41
INCREMENTING_CELL_FIRST = 0x56
INCREMENTING_CELL_END = 0x62
EXPECTED_CLASSIFIER_BYTES = bytes.fromhex(
    "C9 35 90 08 C9 41 B0 04 A0 00 38 60 C9 56 90 08 C9 62 B0 04 "
    "A0 FF 38 60 18 60"
)
EXPECTED_TYPE_FILTER_ROUTINE_BYTES = bytes.fromhex(
    "A8 08 10 05 28 B9 EB 9F 60 28 A9 FF 60"
)
EXPECTED_SOLID_FILTER_ROUTINE_BYTES = bytes.fromhex(
    "A8 08 10 05 28 B9 1E A0 60 28 A9 FF 60"
)
EXPECTED_TYPE_FILTER_PHYSICAL = (
    (0xFF,) * 4 + (0x00,) * 6 + (0xFF,) * 28
)
EXPECTED_SOLID_FILTER_PHYSICAL = (
    (0xFF, 0x00, 0x00, 0x00)
    + (0xFF,) * 12
    + (0x00,) * 13
    + (0xFF, 0xFF, 0x00)
    + (0xFF,) * 6
)
EXPECTED_TYPE_FILTER_LOGICAL = EXPECTED_TYPE_FILTER_PHYSICAL + (0xA8, 0x08)
EXPECTED_SOLID_FILTER_LOGICAL = EXPECTED_SOLID_FILTER_PHYSICAL + (0xC0, 0xA0)
EXPECTED_ALIGNED_CALL_SITES = {
    CLASSIFIER_CPU: (0x83BE, 0x83D6),
    TYPE_FILTER_CPU: (0x8655, 0x8EA7),
    SOLID_FILTER_CPU: (0x8E9E, 0xA189, 0xA22D),
}
EXPECTED_RAW_CALL_MATCHES = {
    CLASSIFIER_CPU: (0x83BE, 0x83D6, 0x969B, 0x96B5, 0x96E2),
    TYPE_FILTER_CPU: (0x8655, 0x8989, 0x8EA7, 0x9771),
    SOLID_FILTER_CPU: (0x8E9E, 0xA189, 0xA22D),
}


class ObjectCollisionFilterError(ValueError):
    pass


@dataclass(frozen=True)
class AnimatedCellClassification:
    matched: bool
    direction: int | None


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise ObjectCollisionFilterError(f"{name} outside 0-255: {value}")


def classify_animated_collision_cell(cell: int) -> AnimatedCellClassification:
    _validate_byte(cell, "room cell")
    if DECREMENTING_CELL_FIRST <= cell < DECREMENTING_CELL_END:
        return AnimatedCellClassification(True, 0x00)
    if INCREMENTING_CELL_FIRST <= cell < INCREMENTING_CELL_END:
        return AnimatedCellClassification(True, 0xFF)
    return AnimatedCellClassification(False, None)


def _logical_table_value(runtime_type: int, values: tuple[int, ...], name: str) -> int:
    _validate_byte(runtime_type, "runtime type")
    if runtime_type < RUNTIME_TYPE_FIRST:
        return 0xFF
    if runtime_type > RUNTIME_TYPE_LAST_CONSUMED:
        raise ObjectCollisionFilterError(
            f"{name} input exceeds proven consumer domain $00-$A7: ${runtime_type:02X}"
        )
    return values[runtime_type - RUNTIME_TYPE_FIRST]


def get_type84_to89_filter(runtime_type: int) -> int:
    return _logical_table_value(
        runtime_type, EXPECTED_TYPE_FILTER_LOGICAL, "type-84-to-89 filter"
    )


def get_runtime_object_solid_flag(runtime_type: int) -> int:
    return _logical_table_value(
        runtime_type, EXPECTED_SOLID_FILTER_LOGICAL, "solid filter"
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise ObjectCollisionFilterError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise ObjectCollisionFilterError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise ObjectCollisionFilterError(f"truncated PRG range at ${address:04X}")
    return result


def find_call_sites(prg: bytes, target: int) -> tuple[int, ...]:
    opcode = bytes((0x20, target & 0xFF, target >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(opcode) + 1)
        if prg[offset:offset + len(opcode)] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    exact_ranges = (
        (CLASSIFIER_CPU, EXPECTED_CLASSIFIER_BYTES, "animated-cell classifier"),
        (TYPE_FILTER_CPU, EXPECTED_TYPE_FILTER_ROUTINE_BYTES, "type filter"),
        (SOLID_FILTER_CPU, EXPECTED_SOLID_FILTER_ROUTINE_BYTES, "solid filter"),
    )
    for address, expected, name in exact_ranges:
        if read_cpu_range(prg, address, len(expected)) != expected:
            raise ObjectCollisionFilterError(f"{name} routine bytes changed")
    type_physical = tuple(
        read_cpu_range(prg, TYPE_FILTER_TABLE_CPU, PHYSICAL_TABLE_SIZE)
    )
    solid_physical = tuple(
        read_cpu_range(prg, SOLID_FILTER_TABLE_CPU, PHYSICAL_TABLE_SIZE)
    )
    if type_physical != EXPECTED_TYPE_FILTER_PHYSICAL:
        raise ObjectCollisionFilterError("type-filter physical table changed")
    if solid_physical != EXPECTED_SOLID_FILTER_PHYSICAL:
        raise ObjectCollisionFilterError("solid-filter physical table changed")
    type_logical = tuple(
        read_cpu_range(prg, TYPE_FILTER_TABLE_CPU, LOGICAL_TABLE_SIZE)
    )
    solid_logical = tuple(
        read_cpu_range(prg, SOLID_FILTER_TABLE_CPU, LOGICAL_TABLE_SIZE)
    )
    if type_logical != EXPECTED_TYPE_FILTER_LOGICAL:
        raise ObjectCollisionFilterError("type-filter logical table changed")
    if solid_logical != EXPECTED_SOLID_FILTER_LOGICAL:
        raise ObjectCollisionFilterError("solid-filter logical table changed")
    for target, expected_matches in EXPECTED_RAW_CALL_MATCHES.items():
        if find_call_sites(prg, target) != expected_matches:
            raise ObjectCollisionFilterError(
                f"opcode matches for collision filter ${target:04X} changed"
            )
    return {
        "module_range": [CLASSIFIER_CPU, SOLID_FILTER_TABLE_CPU + PHYSICAL_TABLE_SIZE - 1],
        "physical_table_bytes": PHYSICAL_TABLE_SIZE * 2,
        "logical_table_entries": LOGICAL_TABLE_SIZE * 2,
        "overlap_entries": {
            "type_filter": list(type_logical[-2:]),
            "solid_filter": list(solid_logical[-2:]),
        },
        "aligned_call_sites": {
            f"0x{target:04X}": list(calls)
            for target, calls in EXPECTED_ALIGNED_CALL_SITES.items()
        },
        "additional_opcode_matches": {
            f"0x{target:04X}": [
                match
                for match in EXPECTED_RAW_CALL_MATCHES[target]
                if match not in calls
            ]
            for target, calls in EXPECTED_ALIGNED_CALL_SITES.items()
        },
    }


def validate_exhaustive_contract() -> dict[str, object]:
    decrementing_cells: list[int] = []
    incrementing_cells: list[int] = []
    for cell in range(0x100):
        result = classify_animated_collision_cell(cell)
        if result.direction == 0:
            decrementing_cells.append(cell)
        elif result.direction == 0xFF:
            incrementing_cells.append(cell)
        elif result != AnimatedCellClassification(False, None):
            raise ObjectCollisionFilterError("unexpected animated-cell classification")
    expected_decrementing = list(range(DECREMENTING_CELL_FIRST, DECREMENTING_CELL_END))
    expected_incrementing = list(range(INCREMENTING_CELL_FIRST, INCREMENTING_CELL_END))
    if decrementing_cells != expected_decrementing:
        raise ObjectCollisionFilterError("decrementing animated-cell range changed")
    if incrementing_cells != expected_incrementing:
        raise ObjectCollisionFilterError("incrementing animated-cell range changed")

    type_filter_values = {
        runtime_type: get_type84_to89_filter(runtime_type)
        for runtime_type in range(RUNTIME_TYPE_LAST_CONSUMED + 1)
    }
    zero_type_filter = [
        runtime_type for runtime_type, value in type_filter_values.items() if value == 0
    ]
    if zero_type_filter != list(range(0x84, 0x8A)):
        raise ObjectCollisionFilterError("type-84-to-89 zero domain changed")

    solid_values = {
        runtime_type: get_runtime_object_solid_flag(runtime_type)
        for runtime_type in range(RUNTIME_TYPE_LAST_CONSUMED + 1)
    }
    non_solid_types = [
        runtime_type for runtime_type, value in solid_values.items() if value == 0
    ]
    expected_non_solid = [0x81, 0x82, 0x83, *range(0x90, 0x9D), 0x9F]
    if non_solid_types != expected_non_solid:
        raise ObjectCollisionFilterError("runtime-object non-solid domain changed")
    return {
        "cell_values": 0x100,
        "runtime_type_values": RUNTIME_TYPE_LAST_CONSUMED + 1,
        "decrementing_cells": decrementing_cells,
        "incrementing_cells": incrementing_cells,
        "type_filter_zero_types": zero_type_filter,
        "non_solid_types": non_solid_types,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report = {"rom": validate_rom_contract(extract_prg(image_path.read_bytes()))}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    report["samples"] = {
        "decrementing_cell": asdict(classify_animated_collision_cell(0x35)),
        "incrementing_cell": asdict(classify_animated_collision_cell(0x56)),
        "ordinary_cell": asdict(classify_animated_collision_cell(0x53)),
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
    except (OSError, ObjectCollisionFilterError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 256 cell values, 168 runtime-type values, seven "
            "aligned call sites, five additional opcode matches, and two "
            "overlapping logical tables"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
