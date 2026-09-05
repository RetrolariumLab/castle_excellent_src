#!/usr/bin/env python3
"""Model the runtime-object overlap scan at $A247-$A2A9."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

try:
    from . import collision_tables
except ImportError:
    import collision_tables


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA247
ROUTINE_END = 0xA2AA
RECORD_SIZE = 6
RECORD_COUNT = 24
RECORD_BYTES = RECORD_SIZE * RECORD_COUNT
TYPE_FIRST = 0x80
TYPE_END = 0xA8
ROOM_PIXEL_WIDTH = 0x140
EXPECTED_CALL_SITES = (0x8B8F, 0x9996)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "E0 90 B0 5E B5 4A 10 51 C9 A8 B0 4D A8 A5 46 38 F5 4D 90 45 "
    "F9 9A AA B0 40 A5 44 38 F9 6A AA 85 48 A5 45 E9 00 85 49 E6 "
    "48 D0 02 E6 49 A5 49 10 06 A9 00 85 49 85 48 B5 4B C5 48 B5 "
    "4C E5 49 90 18 A5 44 18 65 47 85 48 A5 45 69 00 85 49 B5 4B "
    "C5 48 B5 4C E5 49 B0 01 60 8A 18 69 06 AA E0 90 90 9E 60"
)


class RuntimeObjectOverlapError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int = 0
    x: int = 0
    y: int = 0


@dataclass(frozen=True)
class OverlapMatch:
    record_offset: int
    left_boundary: int
    right_boundary: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RuntimeObjectOverlapError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise RuntimeObjectOverlapError(f"{name} outside 0-65535: {value}")


def _validate_record(record: RuntimeObject) -> None:
    _validate_byte(record.runtime_type, "runtime type")
    _validate_word(record.x, "runtime object X")
    _validate_byte(record.y, "runtime object Y")


def overlap_boundaries(
    *, reference_x: int, candidate_width: int, reference_width: int
) -> tuple[int, int]:
    _validate_word(reference_x, "reference X")
    _validate_byte(candidate_width, "candidate width")
    _validate_byte(reference_width, "reference width")
    left = (reference_x - candidate_width + 1) & 0xFFFF
    if left & 0x8000:
        left = 0
    right = (reference_x + reference_width) & 0xFFFF
    return left, right


def candidate_overlaps(
    record: RuntimeObject,
    *,
    reference_x: int,
    reference_y: int,
    reference_width: int,
    widths: bytes = collision_tables.EXPECTED_WIDTHS,
    heights: bytes = collision_tables.EXPECTED_HEIGHTS,
) -> tuple[int, int] | None:
    _validate_record(record)
    _validate_word(reference_x, "reference X")
    _validate_byte(reference_y, "reference Y")
    _validate_byte(reference_width, "reference width")
    if len(widths) != collision_tables.OBJECT_DIMENSION_COUNT:
        raise RuntimeObjectOverlapError("collision-width table must contain 48 bytes")
    if len(heights) != collision_tables.OBJECT_DIMENSION_COUNT:
        raise RuntimeObjectOverlapError("collision-height table must contain 48 bytes")
    if not TYPE_FIRST <= record.runtime_type < TYPE_END:
        return None
    type_index = record.runtime_type - TYPE_FIRST
    if reference_y < record.y:
        return None
    if reference_y - record.y >= heights[type_index]:
        return None
    left, right = overlap_boundaries(
        reference_x=reference_x,
        candidate_width=widths[type_index],
        reference_width=reference_width,
    )
    if record.x < left or record.x >= right:
        return None
    return left, right


def find_runtime_object_overlap(
    records: tuple[RuntimeObject, ...],
    *,
    start_offset: int,
    reference_x: int,
    reference_y: int,
    reference_width: int,
) -> OverlapMatch | None:
    if len(records) != RECORD_COUNT:
        raise RuntimeObjectOverlapError(
            f"runtime pool must contain {RECORD_COUNT} records"
        )
    if not 0 <= start_offset <= RECORD_BYTES or start_offset % RECORD_SIZE:
        raise RuntimeObjectOverlapError(
            f"start offset must be a six-byte boundary from 0 to {RECORD_BYTES}"
        )
    for record in records:
        _validate_record(record)
    for record_offset in range(start_offset, RECORD_BYTES, RECORD_SIZE):
        record = records[record_offset // RECORD_SIZE]
        boundaries = candidate_overlaps(
            record,
            reference_x=reference_x,
            reference_y=reference_y,
            reference_width=reference_width,
        )
        if boundaries is not None:
            return OverlapMatch(record_offset, *boundaries)
    return None


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RuntimeObjectOverlapError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise RuntimeObjectOverlapError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def find_call_sites(prg: bytes) -> tuple[int, ...]:
    opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(opcode) + 1)
        if prg[offset:offset + len(opcode)] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    observed = prg[start:ROUTINE_END - PRG_BASE]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise RuntimeObjectOverlapError("runtime-object overlap routine bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise RuntimeObjectOverlapError("runtime-object overlap call sites changed")
    width_start = collision_tables.OBJECT_WIDTHS_CPU - PRG_BASE
    height_start = collision_tables.OBJECT_HEIGHTS_CPU - PRG_BASE
    widths = prg[width_start:width_start + collision_tables.OBJECT_DIMENSION_COUNT]
    heights = prg[height_start:height_start + collision_tables.OBJECT_DIMENSION_COUNT]
    if widths != collision_tables.EXPECTED_WIDTHS:
        raise RuntimeObjectOverlapError("runtime collision-width table changed")
    if heights != collision_tables.EXPECTED_HEIGHTS:
        raise RuntimeObjectOverlapError("runtime collision-height table changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(observed),
        "call_sites": list(EXPECTED_CALL_SITES),
        "accepted_type_range": [TYPE_FIRST, TYPE_END - 1],
        "record_offsets": list(range(0, RECORD_BYTES, RECORD_SIZE)),
    }


def validate_exhaustive_contract() -> dict[str, object]:
    type_cases = 0
    for runtime_type in range(0x100):
        record = RuntimeObject(runtime_type, 100, 50)
        observed = candidate_overlaps(
            record, reference_x=100, reference_y=50, reference_width=16
        )
        expected = TYPE_FIRST <= runtime_type < TYPE_END
        if (observed is not None) != expected:
            raise RuntimeObjectOverlapError("active-type filter mismatch")
        type_cases += 1

    representative_types_by_height: dict[int, int] = {}
    representative_types_by_width: dict[int, int] = {}
    for type_index in range(TYPE_END - TYPE_FIRST):
        runtime_type = TYPE_FIRST + type_index
        representative_types_by_height.setdefault(
            collision_tables.EXPECTED_HEIGHTS[type_index], runtime_type
        )
        representative_types_by_width.setdefault(
            collision_tables.EXPECTED_WIDTHS[type_index], runtime_type
        )

    vertical_cases = 0
    for height, runtime_type in sorted(representative_types_by_height.items()):
        for candidate_y in range(0x100):
            for reference_y in range(0x100):
                observed = candidate_overlaps(
                    RuntimeObject(runtime_type, 100, candidate_y),
                    reference_x=100,
                    reference_y=reference_y,
                    reference_width=16,
                )
                expected = candidate_y <= reference_y < candidate_y + height
                if (observed is not None) != expected:
                    raise RuntimeObjectOverlapError("vertical overlap mismatch")
                vertical_cases += 1

    horizontal_cases = 0
    for candidate_width, runtime_type in sorted(representative_types_by_width.items()):
        for reference_width in sorted(representative_types_by_width):
            for reference_x in range(ROOM_PIXEL_WIDTH):
                left = max(0, reference_x - candidate_width + 1)
                right = reference_x + reference_width
                for candidate_x in range(ROOM_PIXEL_WIDTH):
                    observed = candidate_overlaps(
                        RuntimeObject(runtime_type, candidate_x, 50),
                        reference_x=reference_x,
                        reference_y=50,
                        reference_width=reference_width,
                    )
                    expected = left <= candidate_x < right
                    if (observed is not None) != expected:
                        raise RuntimeObjectOverlapError("horizontal overlap mismatch")
                    horizontal_cases += 1

    empty = RuntimeObject()
    records = (empty,) * 5 + (RuntimeObject(0x80, 100, 50),) + (empty,) * 18
    match = find_runtime_object_overlap(
        records,
        start_offset=0,
        reference_x=100,
        reference_y=50,
        reference_width=16,
    )
    if match is None or match.record_offset != 5 * RECORD_SIZE:
        raise RuntimeObjectOverlapError("runtime-pool scan order mismatch")
    return {
        "type_cases": type_cases,
        "vertical_cases": vertical_cases,
        "horizontal_cases": horizontal_cases,
        "candidate_widths": sorted(representative_types_by_width),
        "candidate_heights": sorted(representative_types_by_height),
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report = {"rom": validate_rom_contract(extract_prg(image_path.read_bytes()))}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    sample_records = (RuntimeObject(),) * 2 + (RuntimeObject(0x80, 100, 50),) + (
        RuntimeObject(),
    ) * 21
    sample = find_runtime_object_overlap(
        sample_records,
        start_offset=0,
        reference_x=100,
        reference_y=50,
        reference_width=16,
    )
    report["sample"] = asdict(sample) if sample is not None else None
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, RuntimeObjectOverlapError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        total = cases["type_cases"] + cases["vertical_cases"] + cases["horizontal_cases"]
        print(
            "[OK] validated two call sites, 24 record offsets, and "
            f"{total:,} type/X/Y overlap cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
