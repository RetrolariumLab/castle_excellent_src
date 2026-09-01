#!/usr/bin/env python3
"""Model Castle Excellent's 16-bit player and object X-coordinate helpers."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import sys


WORD_MASK = 0xFFFF
BYTE_MASK = 0xFF
PLAYER_X_OFFSETS = (7, 15)
RUNTIME_OBJECT_X_OFFSETS = (0, 7, 8, 15, 17, -2)


class XCoordinateError(ValueError):
    pass


@dataclass(frozen=True)
class AxCoordinate:
    accumulator_high: int
    index_low: int

    @property
    def value(self) -> int:
        return (self.accumulator_high << 8) | self.index_low


def _validate_position(position: int) -> None:
    if not 0 <= position <= WORD_MASK:
        raise XCoordinateError(f"X position outside 0-65535: {position}")


def offset_x_6502(position: int, offset: int) -> AxCoordinate:
    """Apply the helpers' low-byte ADC/SBC and propagated carry/borrow."""
    _validate_position(position)
    low = position & BYTE_MASK
    high = position >> 8
    if offset >= 0:
        low_total = low + offset
        low = low_total & BYTE_MASK
        high = (high + (low_total > BYTE_MASK)) & BYTE_MASK
    else:
        magnitude = -offset
        borrow = low < magnitude
        low = (low - magnitude) & BYTE_MASK
        high = (high - borrow) & BYTE_MASK
    return AxCoordinate(accumulator_high=high, index_low=low)


def validate_x_coordinate_contract() -> dict[str, object]:
    offsets = PLAYER_X_OFFSETS + RUNTIME_OBJECT_X_OFFSETS
    for position in range(WORD_MASK + 1):
        for offset in offsets:
            result = offset_x_6502(position, offset)
            expected = (position + offset) & WORD_MASK
            if result.value != expected:
                raise XCoordinateError(
                    f"wrong result for 0x{position:04X} {offset:+d}: "
                    f"0x{result.value:04X}"
                )
    return {
        "register_contract": {"A": "high byte", "X": "low byte"},
        "player_offsets": list(PLAYER_X_OFFSETS),
        "runtime_object_offsets": list(RUNTIME_OBJECT_X_OFFSETS),
        "positions_checked": WORD_MASK + 1,
        "helper_cases_checked": (WORD_MASK + 1) * len(offsets),
        "carry_example": vars(offset_x_6502(0x00F8, 15)),
        "borrow_example": vars(offset_x_6502(0x0101, -2)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_x_coordinate_contract()
    except XCoordinateError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] exhaustively validated player and runtime-object X helpers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
