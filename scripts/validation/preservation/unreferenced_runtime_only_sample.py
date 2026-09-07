#!/usr/bin/env python3
"""Model and audit the unreferenced runtime-object sampler at $A1D4-$A246."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

from scripts.validation.collision import collision_point_sample, collision_tables
from scripts.validation.objects import object_collision_filters


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA1D4
ROUTINE_END = 0xA247
ROUTINE_SHA256 = "c3564b2dcfb4009f208634452f7d1225d4e02e0c77545d18a8b0bb585154583b"
FALSE_FLOW_START = 0xA207
EXPECTED_INSTRUCTION_STARTS = (0xA1D4, 0xA1DE, 0xA1E8, 0xA234, 0xA239)
DISPATCH_TABLES = (
    (0x8F29, 0x926B),
    (0x926C, 0x9386),
    (0x95BF, 0x9613),
    (0xAD95, 0xADE7),
)


class RuntimeOnlySampleError(ValueError):
    pass


def extract_prg(image: bytes) -> bytes:
    try:
        return collision_point_sample.extract_prg(image)
    except collision_point_sample.CollisionPointSampleError as exc:
        raise RuntimeOnlySampleError(str(exc)) from exc


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _read_word(prg: bytes, cpu_address: int) -> int:
    data = _slice(prg, cpu_address, cpu_address + 2)
    return data[0] | data[1] << 8


def load_instruction_starts(path: Path) -> set[int]:
    starts: set[int] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("address\t"):
            continue
        try:
            starts.add(int(line.split("\t", 1)[0], 16))
        except ValueError as exc:
            raise RuntimeOnlySampleError(
                f"invalid instruction address at {path}:{line_number}"
            ) from exc
    return starts


def load_code_evidence(path: Path) -> list[tuple[int, int]]:
    ranges: list[tuple[int, int]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#") or fields[0] != "code":
            continue
        if len(fields) != 3:
            raise RuntimeOnlySampleError(
                f"invalid code evidence at {path}:{line_number}"
            )
        ranges.append((int(fields[1], 16), int(fields[2], 16)))
    return ranges


def find_direct_entries(prg: bytes) -> list[int]:
    target = bytes((ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - 2)
        if prg[offset] in (0x20, 0x4C) and prg[offset + 1:offset + 3] == target
    ]


def sample_runtime_objects(
    records: tuple[collision_point_sample.RuntimeObject, ...], *, x: int, y: int
) -> collision_point_sample.CollisionSample:
    if len(records) != collision_point_sample.RECORD_COUNT:
        raise RuntimeOnlySampleError(
            f"runtime pool has {len(records)} records, expected 24"
        )
    if not 0 <= x <= 0xFFFF or not 0 <= y <= 0xFF:
        raise RuntimeOnlySampleError("sample coordinate outside machine width")
    for record in records:
        try:
            collision_point_sample._validate_runtime_object(record)
        except collision_point_sample.CollisionPointSampleError as exc:
            raise RuntimeOnlySampleError(str(exc)) from exc
    if y >= collision_point_sample.ROOM_PIXEL_HEIGHT:
        return collision_point_sample._empty_sample(x & 0xFF)

    last_offset = 0
    for object_index, record in enumerate(records):
        object_offset = object_index * collision_point_sample.RECORD_SIZE
        last_offset = object_offset
        if not collision_point_sample.TYPE_FIRST <= record.runtime_type < collision_point_sample.TYPE_END:
            continue
        type_index = record.runtime_type - collision_point_sample.TYPE_FIRST
        height = collision_tables.EXPECTED_HEIGHTS[type_index]
        width = collision_tables.EXPECTED_WIDTHS[type_index]
        if not record.y <= y < record.y + height:
            continue
        if not record.x <= x < record.x + width:
            continue
        solid = bool(object_collision_filters.get_runtime_object_solid_flag(record.runtime_type))
        return collision_point_sample.CollisionSample(
            accumulator=record.runtime_type,
            x_register=object_offset,
            y_register=1,
            carry=solid,
            negative=False,
            zero=False,
            source="runtime-object-only",
            object_offset=object_offset,
        )
    return collision_point_sample._empty_sample(last_offset)


def validate_contract(
    prg: bytes,
    instruction_starts: set[int],
    runtime_code_ranges: list[tuple[int, int]],
    comparison_prg: bytes | None = None,
) -> dict[str, object]:
    routine = _slice(prg, ROUTINE_CPU, ROUTINE_END)
    if len(routine) != ROUTINE_END - ROUTINE_CPU:
        raise RuntimeOnlySampleError("unreferenced sampler is truncated")
    if hashlib.sha256(routine).hexdigest() != ROUTINE_SHA256:
        raise RuntimeOnlySampleError("unreferenced sampler bytes changed")
    if comparison_prg is not None and _slice(comparison_prg, ROUTINE_CPU, ROUTINE_END) != routine:
        raise RuntimeOnlySampleError("Japanese and USA sampler bytes differ")
    missing_starts = [address for address in EXPECTED_INSTRUCTION_STARTS if address not in instruction_starts]
    if missing_starts or FALSE_FLOW_START in instruction_starts:
        raise RuntimeOnlySampleError("Ghidra instruction-boundary contract changed")
    for code_start, code_end in runtime_code_ranges:
        if max(ROUTINE_CPU, code_start) <= min(ROUTINE_END - 1, code_end):
            raise RuntimeOnlySampleError("runtime evidence unexpectedly enters the sampler")
    if find_direct_entries(prg):
        raise RuntimeOnlySampleError("direct control flow unexpectedly enters the sampler")
    if bytes((ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8)) in prg:
        raise RuntimeOnlySampleError("PRG unexpectedly contains a pointer to the sampler")

    targets = []
    for table_start, table_end in DISPATCH_TABLES:
        for address in range(table_start, table_end, 2):
            target = _read_word(prg, address)
            targets.append(target)
            if ROUTINE_CPU <= target < ROUTINE_END:
                raise RuntimeOnlySampleError(f"dispatch pointer at ${address:04X} enters sampler")

    empty_records = (collision_point_sample.RuntimeObject(),) * collision_point_sample.RECORD_COUNT
    if sample_runtime_objects(empty_records, x=0x1234, y=0xA0).x_register != 0x34:
        raise RuntimeOnlySampleError("out-of-bounds guard no longer preserves X")
    if sample_runtime_objects(empty_records, x=0, y=0).x_register != 0x8A:
        raise RuntimeOnlySampleError("exhausted scan no longer leaves final record offset in X")
    for slot in range(collision_point_sample.RECORD_COUNT):
        records = list(empty_records)
        records[slot] = collision_point_sample.RuntimeObject(0x80, 0x80, 0x40)
        hit = sample_runtime_objects(tuple(records), x=0x80, y=0x40)
        if hit.object_offset != slot * collision_point_sample.RECORD_SIZE:
            raise RuntimeOnlySampleError("runtime slot order changed")

    return {
        "range": [ROUTINE_CPU, ROUTINE_END - 1],
        "bytes": len(routine),
        "dispatch_entries_checked": len(targets),
        "direct_entries": 0,
        "runtime_entries": 0,
        "runtime_slots": collision_point_sample.RECORD_COUNT,
        "revision_match": comparison_prg is not None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--facts", type=Path, required=True)
    parser.add_argument("--runtime-evidence", type=Path, required=True)
    parser.add_argument("--comparison-image", type=Path)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_contract(
            extract_prg(args.image.read_bytes()),
            load_instruction_starts(args.facts),
            load_code_evidence(args.runtime_evidence),
            extract_prg(args.comparison_image.read_bytes()) if args.comparison_image else None,
        )
    except (OSError, RuntimeOnlySampleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 115 sampler bytes, zero live entries, "
            f"{report['dispatch_entries_checked']} dispatch pointers, and 24 runtime slots"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
