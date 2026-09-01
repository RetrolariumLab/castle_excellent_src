#!/usr/bin/env python3
"""Model Castle Excellent's runtime-type and mutable-cell collision filters."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import sys


RUNTIME_TYPE_FIRST = 0x90
RUNTIME_TYPE_END = 0x96
NORMALIZED_EMPTY_CELL = 0x53
MUTABLE_COLLISION_CELLS = frozenset((0x54, 0x55, 0x62, 0x63))
CARRY_FLAG = 0x01


class CollisionCellError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionSample:
    cell: int
    status: int

    @property
    def carry(self) -> bool:
        return bool(self.status & CARRY_FLAG)


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise CollisionCellError(f"{name} outside 0-255: {value}")


def runtime_type_matches_90_to_95(runtime_type: int) -> bool:
    """Return the $9552 carry-clear case."""
    _validate_byte(runtime_type, "runtime type")
    return RUNTIME_TYPE_FIRST <= runtime_type < RUNTIME_TYPE_END


def normalize_collision_sample(cell: int, status: int) -> CollisionSample:
    """Reproduce $955D after the lower sampler has returned A and P."""
    _validate_byte(cell, "room cell")
    _validate_byte(status, "processor status")
    if cell in MUTABLE_COLLISION_CELLS:
        return CollisionSample(NORMALIZED_EMPTY_CELL, status & ~CARRY_FLAG)
    return CollisionSample(cell, status)


def validate_collision_cell_contract() -> dict[str, object]:
    matching_types = tuple(
        value for value in range(0x100) if runtime_type_matches_90_to_95(value)
    )
    if matching_types != tuple(range(RUNTIME_TYPE_FIRST, RUNTIME_TYPE_END)):
        raise CollisionCellError("runtime-type carry contract is not exactly $90-$95")
    normalized_count = 0
    for cell in range(0x100):
        for status in range(0x100):
            result = normalize_collision_sample(cell, status)
            if cell in MUTABLE_COLLISION_CELLS:
                normalized_count += 1
                if result.cell != NORMALIZED_EMPTY_CELL or result.carry:
                    raise CollisionCellError("mutable collision cell was not normalized")
                if (result.status ^ status) & ~CARRY_FLAG:
                    raise CollisionCellError("normalization changed a non-carry flag")
            elif result != CollisionSample(cell, status):
                raise CollisionCellError("ordinary collision sample changed")
    return {
        "matching_runtime_types": list(matching_types),
        "mutable_collision_cells": sorted(MUTABLE_COLLISION_CELLS),
        "normalized_cell": NORMALIZED_EMPTY_CELL,
        "sample_status_cases_checked": 0x10000,
        "normalized_cases": normalized_count,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_collision_cell_contract()
    except CollisionCellError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] exhaustively validated runtime-type and collision-cell filters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
