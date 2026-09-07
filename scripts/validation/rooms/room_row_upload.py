#!/usr/bin/env python3
"""Model and validate Castle Excellent's 20 NMI room-row upload tasks."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Sequence


INES_HEADER_SIZE = 16
PRG_CPU_BASE = 0x8000
ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
LEFT_NAMETABLE_COLUMNS = 14
RIGHT_NAMETABLE_COLUMNS = ROOM_WIDTH - LEFT_NAMETABLE_COLUMNS
ROOM_CELLS_ADDRESS = 0x0400
LEFT_TILE_TABLE_ADDRESS = 0xFF30
RIGHT_TILE_TABLE_ADDRESS = 0xFF94
TILE_TABLE_SIZE = 100
PPU_ADDR = 0x2006
PPU_DATA = 0x2007
NMI_FRAME_ADDRESS = 0xC588
FIRST_HANDLER_ADDRESS = 0xC8BC
HANDLER_SIZE = 0x143
HANDLER_COUNT = ROOM_HEIGHT
HANDLERS_END_ADDRESS = FIRST_HANDLER_ADDRESS + HANDLER_COUNT * HANDLER_SIZE
LEFT_FIRST_PPU_ADDRESS = 0x20E4
RIGHT_FIRST_PPU_ADDRESS = 0x24E0
NAMETABLE_ROW_BYTES = 0x20


class RoomRowUploadError(ValueError):
    pass


def handler_address(row: int) -> int:
    _validate_row(row)
    return FIRST_HANDLER_ADDRESS + row * HANDLER_SIZE


def row_ppu_addresses(row: int) -> tuple[int, int]:
    _validate_row(row)
    offset = row * NAMETABLE_ROW_BYTES
    return LEFT_FIRST_PPU_ADDRESS + offset, RIGHT_FIRST_PPU_ADDRESS + offset


def _validate_row(row: int) -> None:
    if not 0 <= row < ROOM_HEIGHT:
        raise RoomRowUploadError(f"room row outside 0-{ROOM_HEIGHT - 1}: {row}")


def _validate_bytes(values: Sequence[int], count: int, name: str) -> tuple[int, ...]:
    if len(values) != count:
        raise RoomRowUploadError(f"{name} has {len(values)} bytes, expected {count}")
    if any(not 0 <= value <= 0xFF for value in values):
        raise RoomRowUploadError(f"{name} contains a value outside byte range")
    return tuple(values)


def build_row_writes(
    room_cells: Sequence[int],
    left_tiles: Sequence[int],
    right_tiles: Sequence[int],
    row: int,
) -> tuple[tuple[int, tuple[int, ...]], tuple[int, tuple[int, ...]]]:
    """Return the left/right nametable writes for one logical room row."""
    _validate_row(row)
    cells = _validate_bytes(room_cells, ROOM_CELL_COUNT, "room cell buffer")
    left = _validate_bytes(left_tiles, TILE_TABLE_SIZE, "left tile table")
    right = _validate_bytes(right_tiles, TILE_TABLE_SIZE, "right tile table")
    row_cells = cells[row * ROOM_WIDTH : (row + 1) * ROOM_WIDTH]
    invalid = [cell for cell in row_cells if cell >= TILE_TABLE_SIZE]
    if invalid:
        raise RoomRowUploadError(f"room row contains cells outside tile tables: {invalid}")

    def expand(selected: Sequence[int]) -> tuple[int, ...]:
        return tuple(tile for cell in selected for tile in (left[cell], right[cell]))

    left_address, right_address = row_ppu_addresses(row)
    return (
        (left_address, expand(row_cells[:LEFT_NAMETABLE_COLUMNS])),
        (right_address, expand(row_cells[LEFT_NAMETABLE_COLUMNS:])),
    )


def _absolute_instruction(opcode: int, address: int) -> bytes:
    return bytes((opcode, address & 0xFF, address >> 8))


def _ppu_address_setup(address: int) -> bytes:
    return bytes(
        (
            0xA9,
            address >> 8,
            0x8D,
            PPU_ADDR & 0xFF,
            PPU_ADDR >> 8,
            0xA9,
            address & 0xFF,
            0x8D,
            PPU_ADDR & 0xFF,
            PPU_ADDR >> 8,
        )
    )


def expected_handler_bytes(row: int) -> bytes:
    """Encode the proven unrolled instruction template for one row task."""
    _validate_row(row)
    left_address, right_address = row_ppu_addresses(row)
    result = bytearray(_ppu_address_setup(left_address))
    for column in range(ROOM_WIDTH):
        if column == LEFT_NAMETABLE_COLUMNS:
            result.extend(_ppu_address_setup(right_address))
        cell_address = ROOM_CELLS_ADDRESS + row * ROOM_WIDTH + column
        result.extend(_absolute_instruction(0xAE, cell_address))
        result.extend(_absolute_instruction(0xBD, LEFT_TILE_TABLE_ADDRESS))
        result.extend(_absolute_instruction(0x8D, PPU_DATA))
        result.extend(_absolute_instruction(0xBD, RIGHT_TILE_TABLE_ADDRESS))
        result.extend(_absolute_instruction(0x8D, PPU_DATA))
    result.extend(_absolute_instruction(0x4C, NMI_FRAME_ADDRESS))
    encoded = bytes(result)
    if len(encoded) != HANDLER_SIZE:
        raise RoomRowUploadError(
            f"encoded handler has {len(encoded)} bytes, expected {HANDLER_SIZE}"
        )
    return encoded


def _read_prg(image: Path) -> bytes:
    data = image.read_bytes()
    if len(data) < INES_HEADER_SIZE or data[:4] != b"NES\x1a":
        raise RoomRowUploadError(f"{image} is not an iNES image")
    trainer_size = 512 if data[6] & 0x04 else 0
    prg_size = data[4] * 0x4000
    start = INES_HEADER_SIZE + trainer_size
    prg = data[start : start + prg_size]
    if len(prg) != prg_size or prg_size != 0x8000:
        raise RoomRowUploadError("expected a complete 32 KiB PRG-ROM")
    return prg


def validate_room_row_contract(image: Path) -> dict[str, object]:
    prg = _read_prg(image)
    for row in range(ROOM_HEIGHT):
        address = handler_address(row)
        offset = address - PRG_CPU_BASE
        actual = prg[offset : offset + HANDLER_SIZE]
        expected = expected_handler_bytes(row)
        if actual != expected:
            difference = next(
                index
                for index, (actual_byte, expected_byte) in enumerate(
                    zip(actual, expected, strict=True)
                )
                if actual_byte != expected_byte
            )
            raise RoomRowUploadError(
                f"row {row} handler differs at ${address + difference:04X}"
            )
    left_offset = LEFT_TILE_TABLE_ADDRESS - PRG_CPU_BASE
    right_offset = RIGHT_TILE_TABLE_ADDRESS - PRG_CPU_BASE
    left_tiles = prg[left_offset : left_offset + TILE_TABLE_SIZE]
    right_tiles = prg[right_offset : right_offset + TILE_TABLE_SIZE]
    cells = tuple(range(ROOM_WIDTH)) * ROOM_HEIGHT
    writes = build_row_writes(cells, left_tiles, right_tiles, ROOM_HEIGHT - 1)
    if tuple(len(tiles) for _, tiles in writes) != (
        LEFT_NAMETABLE_COLUMNS * 2,
        RIGHT_NAMETABLE_COLUMNS * 2,
    ):
        raise RoomRowUploadError("room-row PPU write widths do not match 14+6 cells")
    return {
        "handler_range": f"0x{FIRST_HANDLER_ADDRESS:04X}-0x{HANDLERS_END_ADDRESS - 1:04X}",
        "handler_count": HANDLER_COUNT,
        "handler_size": HANDLER_SIZE,
        "room_cells": ROOM_CELL_COUNT,
        "left_columns": LEFT_NAMETABLE_COLUMNS,
        "right_columns": RIGHT_NAMETABLE_COLUMNS,
        "first_ppu_addresses": [
            f"0x{address:04X}" for address in row_ppu_addresses(0)
        ],
        "last_ppu_addresses": [
            f"0x{address:04X}" for address in row_ppu_addresses(ROOM_HEIGHT - 1)
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_room_row_contract(args.image)
    except (OSError, RoomRowUploadError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 20 unrolled room-row handlers, 400 cell lookups, "
            "and 800 PPU tile writes"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
