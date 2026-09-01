#!/usr/bin/env python3
"""Model HUD score, lives, and inventory formatting at $A497-$A572."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys


PRG_CPU_BASE = 0x8000
PRG_SIZE = 0x8000
SCORE_DIGIT_COUNT = 5
SCORE_BUFFER_SIZE = 8
LIFE_SCRATCH_DIGIT_COUNT = 3
INVENTORY_COUNT = 6
DIGIT_TILE_ZERO = 0x60
BLANK_TILE = 0xFF
STATUS_TILES_READY = 0x00
STATUS_TILES_LOCKED = 0xFF
INVENTORY_MAX_VALUE = 9

DECIMAL_PLACE_VALUES = (10_000, 1_000, 100, 10, 1)
DECIMAL_HIGH_BYTES = bytes(value >> 8 for value in DECIMAL_PLACE_VALUES)
DECIMAL_LOW_BYTES = bytes(value & 0xFF for value in DECIMAL_PLACE_VALUES)
MUTABLE_CELL_BIT_MASKS = bytes((0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80))
UNREFERENCED_BIT_INDEX_HELPER_BYTES = bytes(
    (
        0x85, 0x1B, 0x29, 0x07, 0xA8, 0xA5, 0x1B, 0x86,
        0x1B, 0x46, 0x1B, 0x6A, 0x46, 0x1B, 0x6A, 0x46,
        0x1B, 0x6A, 0xAA, 0xB9, 0x5B, 0xA5, 0x60,
    )
)

DECIMAL_HIGH_CPU = 0xA551
DECIMAL_LOW_CPU = 0xA556
MUTABLE_MASKS_CPU = 0xA55B
UNREFERENCED_HELPER_CPU = 0xA573


class StatusFormatError(ValueError):
    pass


@dataclass(frozen=True)
class StatusFormatResult:
    score_buffer: bytes
    life_scratch_tiles: bytes
    uploaded_life_tiles: bytes
    inventory_tiles: bytes
    busy: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise StatusFormatError(f"{name} outside 0-255: {value}")


def begin_status_tile_formatting(score_buffer: bytes | bytearray) -> tuple[int, bytes]:
    if len(score_buffer) != SCORE_BUFFER_SIZE:
        raise StatusFormatError(
            f"score buffer has {len(score_buffer)} bytes, expected {SCORE_BUFFER_SIZE}"
        )
    return STATUS_TILES_LOCKED, bytes(SCORE_BUFFER_SIZE)


def format_score_tiles(score: int) -> bytes:
    if not 0 <= score <= 0xFFFF:
        raise StatusFormatError(f"score outside 0-65535: {score}")
    remainder = score
    digits: list[int] = []
    for place in DECIMAL_PLACE_VALUES:
        digit = 0
        while remainder >= place:
            remainder -= place
            digit += 1
        digits.append(digit + DIGIT_TILE_ZERO)
    for index, tile in enumerate(digits):
        if tile != DIGIT_TILE_ZERO:
            break
        digits[index] = BLANK_TILE
    return bytes(digits)


def format_life_scratch_tiles(lives: int) -> bytes:
    _validate_byte(lives, "player lives")
    hundreds, remainder = divmod(lives, 100)
    tens, ones = divmod(remainder, 10)
    tiles = [
        ones + DIGIT_TILE_ZERO,
        tens + DIGIT_TILE_ZERO,
        hundreds + DIGIT_TILE_ZERO,
    ]
    if tiles[2] == DIGIT_TILE_ZERO:
        tiles[2] = BLANK_TILE
        if tiles[1] == DIGIT_TILE_ZERO:
            tiles[1] = BLANK_TILE
    return bytes(tiles)


def format_inventory_tiles(inventory: bytes | bytearray) -> bytes:
    if len(inventory) != INVENTORY_COUNT:
        raise StatusFormatError(
            f"inventory has {len(inventory)} counters, expected {INVENTORY_COUNT}"
        )
    return bytes(min(value, INVENTORY_MAX_VALUE) + DIGIT_TILE_ZERO for value in inventory)


def format_status_tiles(
    score: int,
    lives: int,
    inventory: bytes | bytearray,
) -> StatusFormatResult:
    busy, score_buffer = begin_status_tile_formatting(bytes(SCORE_BUFFER_SIZE))
    if busy != STATUS_TILES_LOCKED:
        raise StatusFormatError("status formatter did not acquire the upload interlock")
    score_buffer = format_score_tiles(score) + score_buffer[SCORE_DIGIT_COUNT:]
    life_tiles = format_life_scratch_tiles(lives)
    inventory_tiles = format_inventory_tiles(inventory)
    return StatusFormatResult(
        score_buffer=score_buffer,
        life_scratch_tiles=life_tiles,
        uploaded_life_tiles=bytes((life_tiles[1], life_tiles[0])),
        inventory_tiles=inventory_tiles,
        busy=STATUS_TILES_READY,
    )


def _extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise StatusFormatError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or len(image) < prg_end:
        raise StatusFormatError("expected a complete 32 KiB PRG image")
    return image[prg_start:prg_end]


def _table_at(prg: bytes, address: int, expected: bytes, name: str) -> None:
    offset = address - PRG_CPU_BASE
    actual = prg[offset:offset + len(expected)]
    if actual != expected:
        raise StatusFormatError(f"{name} mismatch at ${address:04X}: {actual.hex()}")


def validate_status_format(image: bytes) -> dict[str, object]:
    prg = _extract_prg(image)
    _table_at(prg, DECIMAL_HIGH_CPU, DECIMAL_HIGH_BYTES, "decimal high-byte table")
    _table_at(prg, DECIMAL_LOW_CPU, DECIMAL_LOW_BYTES, "decimal low-byte table")
    _table_at(prg, MUTABLE_MASKS_CPU, MUTABLE_CELL_BIT_MASKS, "mutable-cell bit masks")
    _table_at(
        prg,
        UNREFERENCED_HELPER_CPU,
        UNREFERENCED_BIT_INDEX_HELPER_BYTES,
        "unreferenced bit-index helper bytes",
    )

    for score in range(0x10000):
        actual = format_score_tiles(score)
        expected = [int(digit) + DIGIT_TILE_ZERO for digit in f"{score:05d}"]
        for index, digit in enumerate(f"{score:05d}"):
            if digit != "0":
                break
            expected[index] = BLANK_TILE
        if actual != bytes(expected):
            raise StatusFormatError(f"score formatting mismatch at {score}")

    for lives in range(0x100):
        tiles = format_life_scratch_tiles(lives)
        ones = lives % 10 + DIGIT_TILE_ZERO
        tens = (lives // 10) % 10 + DIGIT_TILE_ZERO
        hundreds = lives // 100 + DIGIT_TILE_ZERO
        if hundreds == DIGIT_TILE_ZERO:
            hundreds = BLANK_TILE
            if tens == DIGIT_TILE_ZERO:
                tens = BLANK_TILE
        if tiles != bytes((ones, tens, hundreds)):
            raise StatusFormatError(f"life formatting mismatch at {lives}")

    inventory_cases = 0
    for position in range(INVENTORY_COUNT):
        for value in range(0x100):
            inventory = bytearray(INVENTORY_COUNT)
            inventory[position] = value
            actual = format_inventory_tiles(inventory)[position]
            expected = min(value, INVENTORY_MAX_VALUE) + DIGIT_TILE_ZERO
            if actual != expected:
                raise StatusFormatError("inventory saturation mismatch")
            inventory_cases += 1

    return {
        "score_values_checked": 0x10000,
        "life_values_checked": 0x100,
        "inventory_cases_checked": inventory_cases,
        "score_buffer_bytes": SCORE_BUFFER_SIZE,
        "score_tiles": SCORE_DIGIT_COUNT,
        "life_scratch_tiles": LIFE_SCRATCH_DIGIT_COUNT,
        "uploaded_life_tiles": 2,
        "inventory_tiles": INVENTORY_COUNT,
        "typed_rom_bytes": (
            len(DECIMAL_HIGH_BYTES)
            + len(DECIMAL_LOW_BYTES)
            + len(MUTABLE_CELL_BIT_MASKS)
            + len(UNREFERENCED_BIT_INDEX_HELPER_BYTES)
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_status_format(args.image.read_bytes())
    except (OSError, StatusFormatError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 65,536 scores, 256 life counts, 1,536 inventory "
            "cases, and 41 typed ROM bytes"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
