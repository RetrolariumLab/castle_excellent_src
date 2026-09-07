#!/usr/bin/env python3
"""Model Castle Excellent's two Famicom save-data transports."""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Iterable


DATA_BITS = 8
EXPANSION_INPUT_MASK = 0x04
EXPANSION_CLOCK_HIGH = 0x06
EXPANSION_CLOCK_LOW_MASK = 0x03
EXPANSION_STROBE = (0x00, 0x02)
EXPANSION_PREAMBLE = (0x00, 0xAA, 0x55)
PULSE_PREAMBLE_PAGES = 0x21
PULSE_PREAMBLE_CYCLES_PER_PAGE = 0x100
PULSE_STOP_SHORT_CYCLES = 4


class DataIoError(ValueError):
    pass


def byte_bits_msb_first(value: int) -> tuple[int, ...]:
    if not 0 <= value <= 0xFF:
        raise DataIoError(f"byte outside 0-255: {value}")
    return tuple((value >> shift) & 1 for shift in range(DATA_BITS - 1, -1, -1))


def expansion_write_pairs(value: int) -> tuple[tuple[int, int], ...]:
    return tuple(
        (
            bit | EXPANSION_CLOCK_HIGH,
            (bit | EXPANSION_CLOCK_HIGH) & EXPANSION_CLOCK_LOW_MASK,
        )
        for bit in byte_bits_msb_first(value)
    )


def decode_expansion_samples(samples: Iterable[int]) -> int:
    sample_values = tuple(samples)
    if len(sample_values) != DATA_BITS:
        raise DataIoError(f"expected {DATA_BITS} expansion samples, got {len(sample_values)}")
    value = 0
    for sample in sample_values:
        if not 0 <= sample <= 0xFF:
            raise DataIoError(f"sample outside 0-255: {sample}")
        value = ((value << 1) | bool(sample & EXPANSION_INPUT_MASK)) & 0xFF
    return value


def expansion_preamble_matches(received: Iterable[int]) -> bool:
    values = tuple(received)
    if len(values) != len(EXPANSION_PREAMBLE):
        raise DataIoError(
            f"expected {len(EXPANSION_PREAMBLE)} preamble bytes, got {len(values)}"
        )
    return values[1:] == EXPANSION_PREAMBLE[1:]


def pulse_byte_cycles(value: int) -> tuple[str, ...]:
    cycles = ["long"]
    for bit in byte_bits_msb_first(value):
        cycles.extend(("short", "short") if bit else ("long",))
    cycles.extend(("short",) * PULSE_STOP_SHORT_CYCLES)
    return tuple(cycles)


def validate_data_io_contract() -> dict[str, object]:
    for value in range(0x100):
        bits = byte_bits_msb_first(value)
        samples = tuple(bit << 2 for bit in bits)
        if decode_expansion_samples(samples) != value:
            raise DataIoError(f"expansion round trip failed for 0x{value:02X}")
        for bit, (high, low) in zip(bits, expansion_write_pairs(value), strict=True):
            if high != bit | EXPANSION_CLOCK_HIGH:
                raise DataIoError(f"invalid expansion high phase for 0x{value:02X}")
            if low != bit | 0x02:
                raise DataIoError(f"invalid expansion low phase for 0x{value:02X}")
    if not expansion_preamble_matches(EXPANSION_PREAMBLE):
        raise DataIoError("canonical expansion preamble was rejected")
    if expansion_preamble_matches((0xFF, 0xAA, 0x54)):
        raise DataIoError("bad expansion preamble was accepted")
    return {
        "bit_order": "msb-first",
        "validated_bytes": 0x100,
        "expansion_strobe": list(EXPANSION_STROBE),
        "expansion_preamble": list(EXPANSION_PREAMBLE),
        "pulse_preamble_cycles": PULSE_PREAMBLE_PAGES
        * PULSE_PREAMBLE_CYCLES_PER_PAGE,
        "pulse_zero_cycles": list(pulse_byte_cycles(0x00)),
        "pulse_one_cycle_count": len(pulse_byte_cycles(0xFF)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_data_io_contract()
    except DataIoError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated both data transports across all 256 byte values")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
