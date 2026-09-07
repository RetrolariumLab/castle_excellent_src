#!/usr/bin/env python3
"""Model scroll, division, and palette helpers at $C43D-$C4FC."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
SCROLL_START_CPU = 0xC43D
DIVIDE_START_CPU = 0xC47A
PALETTE_START_CPU = 0xC4CD
HELPERS_END_CPU = 0xC4FD

PPU_STATUS = 0x2002
PPU_ADDRESS = 0x2006
PPU_DATA = 0x2007
PALETTE_DESTINATION_HIGH = 0x3F
PALETTE_DESTINATION_LOW = 0x00
PALETTE_BYTES = 0x20
SCROLL_PLAYER_OFFSET = 0x40
SCROLL_MAXIMUM = 0x80
SCROLL_SCALE_NUMERATOR = 2
SCROLL_SCALE_DENOMINATOR = 3

RANGE_HASHES = (
    (
        SCROLL_START_CPU,
        DIVIDE_START_CPU,
        "669e72126ad35dadeb69b65559c8d3727db14411fde3086f5b00f76dad511e10",
        "horizontal-scroll updater",
    ),
    (
        DIVIDE_START_CPU,
        PALETTE_START_CPU,
        "dde6566567b94e71f363a6440503c514fa7b0fc379ddefba348e326072ad532c",
        "unsigned divide helper",
    ),
    (
        PALETTE_START_CPU,
        HELPERS_END_CPU,
        "f623ae2577bcbffc5e2bbbd62e240564b83cbb8c306aa76798821c96035cddbb",
        "palette uploader",
    ),
    (
        SCROLL_START_CPU,
        HELPERS_END_CPU,
        "a6d4a5c352745ec0710b100994092d2838b6a6f40b2f5de65479af5d0e583e8e",
        "complete scroll/math/palette helper range",
    ),
)

EXPECTED_ENTRYPOINT_CALLERS = {
    SCROLL_START_CPU: (
        (0x82AE, 0x20),
        (0x869A, 0x20),
        (0x86C0, 0x20),
        (0x86D3, 0x4C),
        (0x86F4, 0x20),
        (0x871E, 0x4C),
        (0x873D, 0x20),
        (0x9469, 0x20),
        (0xFDAA, 0x20),
    ),
    DIVIDE_START_CPU: ((0x8D3A, 0x4C), (0xC472, 0x20)),
    PALETTE_START_CPU: (
        (0xA359, 0x4C),
        (0xEA93, 0x20),
        (0xF909, 0x20),
        (0xFE9E, 0x20),
    ),
}
PALETTE_SETUP_CALLS = ((PALETTE_START_CPU, 0x8158), (PALETTE_START_CPU + 3, 0x8164))


class ScrollMathPaletteError(ValueError):
    pass


@dataclass(frozen=True)
class DivisionResult:
    quotient: int
    remainder: int
    divisor_scratch: int
    quotient_bit_scratch: int
    carry_set: bool
    divided: bool


@dataclass(frozen=True)
class ScrollResult:
    scroll_x: int
    updated: bool


@dataclass(frozen=True)
class PaletteUploadResult:
    ppu_writes: tuple[tuple[int, int], ...]
    bytes_uploaded: int
    nmi_disabled: bool
    rendering_disabled: bool


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise ScrollMathPaletteError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise ScrollMathPaletteError(f"{name} outside 0-65535: {value}")


def divide_unsigned16(
    dividend: int, divisor: int, *, quotient_initial: int = 0
) -> DivisionResult:
    """Follow the shift/subtract machine semantics of the helper at $C47A."""
    _validate_word(dividend, "dividend")
    _validate_word(divisor, "divisor")
    _validate_word(quotient_initial, "initial quotient")
    if divisor == 0:
        return DivisionResult(
            quotient_initial, dividend, divisor, 0, True, False
        )

    divisor_scratch = divisor
    quotient_bit = 1
    quotient = 0
    remainder = dividend
    while divisor_scratch & 0x8000 == 0:
        divisor_scratch = (divisor_scratch << 1) & 0xFFFF
        quotient_bit = (quotient_bit << 1) & 0xFFFF

    while True:
        if remainder >= divisor_scratch:
            remainder = (remainder - divisor_scratch) & 0xFFFF
            quotient = (quotient + quotient_bit) & 0xFFFF

        divisor_carry = divisor_scratch & 1
        divisor_scratch >>= 1
        if divisor_carry:
            return DivisionResult(
                quotient, remainder, divisor_scratch, quotient_bit, True, True
            )

        quotient_bit_carry = quotient_bit & 1
        quotient_bit >>= 1
        if quotient_bit_carry:
            return DivisionResult(
                quotient, remainder, divisor_scratch, quotient_bit, True, True
            )


def update_horizontal_scroll(
    *, player_x: int, pause_mode: int, current_scroll_x: int
) -> ScrollResult:
    _validate_word(player_x, "player X")
    _validate_byte(pause_mode, "pause mode")
    _validate_byte(current_scroll_x, "current scroll X")
    if pause_mode:
        return ScrollResult(current_scroll_x, False)

    offset = (player_x - SCROLL_PLAYER_OFFSET) & 0xFFFF
    if player_x < SCROLL_PLAYER_OFFSET:
        return ScrollResult(0, True)
    offset_low = offset & 0xFF
    if offset_low == 0:
        return ScrollResult(0, True)
    if offset_low >= 0xC0:
        return ScrollResult(SCROLL_MAXIMUM, True)
    numerator = offset_low * SCROLL_SCALE_NUMERATOR
    quotient = divide_unsigned16(numerator, SCROLL_SCALE_DENOMINATOR).quotient
    return ScrollResult(quotient & 0xFF, True)


def upload_palette(palette: bytes) -> PaletteUploadResult:
    if len(palette) != PALETTE_BYTES:
        raise ScrollMathPaletteError(
            f"palette has {len(palette)} bytes, expected {PALETTE_BYTES}"
        )
    writes: list[tuple[int, int]] = [
        (PPU_ADDRESS, PALETTE_DESTINATION_HIGH),
        (PPU_ADDRESS, PALETTE_DESTINATION_LOW),
    ]
    writes.extend((PPU_DATA, value) for value in palette)
    writes.append((PPU_ADDRESS, PALETTE_DESTINATION_HIGH))
    writes.extend((PPU_ADDRESS, PALETTE_DESTINATION_LOW) for _write in range(3))
    return PaletteUploadResult(tuple(writes), len(palette), True, True)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise ScrollMathPaletteError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise ScrollMathPaletteError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _find_opcode_target(prg: bytes, opcode: int, target: int) -> list[int]:
    needle = bytes((opcode, target & 0xFF, target >> 8))
    return [
        PRG_BASE + offset
        for offset in range(len(prg) - len(needle) + 1)
        if prg[offset:offset + len(needle)] == needle
    ]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise ScrollMathPaletteError("expected a 32 KiB PRG region")
    for start, end, expected_hash, name in RANGE_HASHES:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise ScrollMathPaletteError(f"{name} bytes changed")
    for target, callers in EXPECTED_ENTRYPOINT_CALLERS.items():
        for source, opcode in callers:
            expected = bytes((opcode, target & 0xFF, target >> 8))
            if _slice(prg, source, source + 3) != expected:
                raise ScrollMathPaletteError(f"caller at ${source:04X} changed")
        for opcode in (0x20, 0x4C):
            expected_sources = [
                source
                for source, expected_opcode in callers
                if expected_opcode == opcode
            ]
            if _find_opcode_target(prg, opcode, target) != expected_sources:
                raise ScrollMathPaletteError(
                    f"entrypoint topology for ${target:04X} changed"
                )
    for source, target in PALETTE_SETUP_CALLS:
        expected = bytes((0x20, target & 0xFF, target >> 8))
        if _slice(prg, source, source + 3) != expected:
            raise ScrollMathPaletteError("palette NMI/render setup changed")
    return {
        "range": [SCROLL_START_CPU, HELPERS_END_CPU - 1],
        "bytes": HELPERS_END_CPU - SCROLL_START_CPU,
        "scroll_bytes": DIVIDE_START_CPU - SCROLL_START_CPU,
        "divide_bytes": PALETTE_START_CPU - DIVIDE_START_CPU,
        "palette_bytes": HELPERS_END_CPU - PALETTE_START_CPU,
        "entrypoints": len(EXPECTED_ENTRYPOINT_CALLERS),
        "callers": sum(len(callers) for callers in EXPECTED_ENTRYPOINT_CALLERS.values()),
        "palette_upload_bytes": PALETTE_BYTES,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    scroll_cases = 0
    for player_x in range(0x10000):
        result = update_horizontal_scroll(
            player_x=player_x, pause_mode=0, current_scroll_x=0x5A
        )
        offset_low = (player_x - SCROLL_PLAYER_OFFSET) & 0xFF
        if player_x < SCROLL_PLAYER_OFFSET or offset_low == 0:
            expected = 0
        elif offset_low >= 0xC0:
            expected = SCROLL_MAXIMUM
        else:
            expected = offset_low * 2 // 3
        if result.scroll_x != expected or not result.updated:
            raise ScrollMathPaletteError("horizontal-scroll mapping mismatch")
        scroll_cases += 1

    pause_cases = 0
    for pause_mode in range(0x100):
        result = update_horizontal_scroll(
            player_x=0x0100, pause_mode=pause_mode, current_scroll_x=0x5A
        )
        expected = SCROLL_MAXIMUM if pause_mode == 0 else 0x5A
        if result.scroll_x != expected or result.updated != (pause_mode == 0):
            raise ScrollMathPaletteError("pause scroll gate mismatch")
        pause_cases += 1

    divide_cases = 0
    for dividend in range(0x10000):
        result = divide_unsigned16(dividend, 3)
        quotient, remainder = divmod(dividend, 3)
        if (
            result.quotient != quotient
            or result.remainder != remainder
            or not result.carry_set
            or not result.divided
        ):
            raise ScrollMathPaletteError("unsigned division-by-three mismatch")
        divide_cases += 1
    return {
        "scroll_cases": scroll_cases,
        "pause_cases": pause_cases,
        "divide_cases": divide_cases,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
    except (OSError, ScrollMathPaletteError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 192 scroll/math/palette bytes, 15 callers, "
            "all player coordinates, and all divide-by-three dividends"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
