#!/usr/bin/env python3
"""Model and exhaustively validate Castle Excellent's NES controller polling."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Iterable


SERIAL_BIT_COUNT = 8
BUTTON_NAMES = (
    "A",
    "B",
    "Select",
    "Start",
    "Up",
    "Down",
    "Left",
    "Right",
)


class ControllerInputError(ValueError):
    pass


def decode_serial_reads(reads: Iterable[int]) -> int:
    """Reproduce the D0-first, D1-fallback bit selection and eight RORs."""
    samples = list(reads)
    if len(samples) != SERIAL_BIT_COUNT:
        raise ControllerInputError(
            f"controller poll has {len(samples)} reads, expected {SERIAL_BIT_COUNT}"
        )
    result = 0
    for bit_index, sample in enumerate(samples):
        if not 0 <= sample <= 0xFF:
            raise ControllerInputError(f"invalid controller-port sample {sample}")
        serial_bit = 1 if sample & 0x01 else (sample >> 1) & 0x01
        result |= serial_bit << bit_index
    return result


def encode_serial_reads(buttons: int, data_line: int = 0) -> list[int]:
    if not 0 <= buttons <= 0xFF:
        raise ControllerInputError(f"invalid button mask {buttons}")
    if data_line not in (0, 1):
        raise ControllerInputError(f"invalid controller data line {data_line}")
    return [((buttons >> bit) & 1) << data_line for bit in range(SERIAL_BIT_COUNT)]


def pressed_button_names(buttons: int) -> list[str]:
    if not 0 <= buttons <= 0xFF:
        raise ControllerInputError(f"invalid button mask {buttons}")
    return [name for bit, name in enumerate(BUTTON_NAMES) if buttons & (1 << bit)]


def validate_all_button_masks() -> None:
    for buttons in range(0x100):
        for data_line in (0, 1):
            decoded = decode_serial_reads(encode_serial_reads(buttons, data_line))
            if decoded != buttons:
                raise ControllerInputError(
                    f"button mask ${buttons:02X} decoded as ${decoded:02X} "
                    f"from D{data_line}"
                )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--mask", type=lambda value: int(value, 0))
    args = parser.parse_args()
    try:
        validate_all_button_masks()
        if args.mask is not None:
            result = {
                "mask": f"0x{args.mask:02X}",
                "buttons": pressed_button_names(args.mask),
                "d0_reads": encode_serial_reads(args.mask, 0),
                "d1_reads": encode_serial_reads(args.mask, 1),
            }
            print(json.dumps(result, indent=2))
            return 0
    except ControllerInputError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    print(
        "[OK] exhaustively validated 256 controller masks on D0 and D1 "
        "with D0-first fallback semantics"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
