#!/usr/bin/env python3
"""Validate and describe room status-screen data and its pointer loads."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from scripts.validation.room_data import extract_rom


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
INITIAL_ATTRIBUTES_CPU = 0xB7AD
INITIAL_ATTRIBUTE_COUNT = 16

STATUS_TILE_STREAMS = (
    ("status_208e", 0x208E, 0xB77C, 0xB78B),
    ("status_2062", 0x2062, 0xB78B, 0xB797),
    ("status_20a2", 0x20A2, 0xB797, 0xB79E),
    ("status_206e", 0x206E, 0xB79E, INITIAL_ATTRIBUTES_CPU),
)

# Each pair is the address of an LDA #high and LDA #low instruction.
STATUS_POINTER_LOADS = (
    (0xB6DC, 0xB6E0, 0xB77C),
    (0xB6F4, 0xB6F8, 0xB79E),
    (0xB714, 0xB718, 0x079D),
    (0xB72F, 0xB733, 0xB78B),
    (0xB747, 0xB74B, 0xB797),
)


class RoomScreenDataError(ValueError):
    pass


def cpu_offset(address: int) -> int:
    if not PRG_BASE <= address < PRG_BASE + PRG_SIZE:
        raise RoomScreenDataError(f"CPU address outside fixed PRG: ${address:04X}")
    return address - PRG_BASE


def parse_terminated_tiles(prg: bytes, start: int, limit: int) -> bytes:
    if len(prg) != PRG_SIZE:
        raise RoomScreenDataError(f"PRG size is {len(prg)}, expected {PRG_SIZE}")
    start_offset = cpu_offset(start)
    limit_offset = cpu_offset(limit)
    if start_offset >= limit_offset:
        raise RoomScreenDataError("invalid status tile-stream bounds")
    try:
        terminator = prg.index(0, start_offset, limit_offset)
    except ValueError as exc:
        raise RoomScreenDataError(f"unterminated status tiles at ${start:04X}") from exc
    if terminator + 1 != limit_offset:
        raise RoomScreenDataError(
            f"status tiles at ${start:04X} leave bytes after their terminator"
        )
    return prg[start_offset:terminator]


def read_immediate(prg: bytes, instruction: int) -> int:
    offset = cpu_offset(instruction)
    if prg[offset] != 0xA9:
        raise RoomScreenDataError(f"expected LDA immediate at ${instruction:04X}")
    return prg[offset + 1]


def validate_status_pointer_loads(prg: bytes) -> None:
    for high_instruction, low_instruction, expected in STATUS_POINTER_LOADS:
        actual = (
            read_immediate(prg, high_instruction) << 8
            | read_immediate(prg, low_instruction)
        )
        if actual != expected:
            raise RoomScreenDataError(
                f"status pointer at ${high_instruction:04X}/${low_instruction:04X} "
                f"is ${actual:04X}, expected ${expected:04X}"
            )


def analyze_room_screen(prg: bytes) -> dict[str, object]:
    validate_status_pointer_loads(prg)
    streams = []
    for name, ppu_address, start, limit in STATUS_TILE_STREAMS:
        tiles = parse_terminated_tiles(prg, start, limit)
        streams.append(
            {
                "name": name,
                "ppu_address": f"0x{ppu_address:04X}",
                "data_address": f"0x{start:04X}",
                "tile_count": len(tiles),
                "tiles": list(tiles),
            }
        )
    attributes_offset = cpu_offset(INITIAL_ATTRIBUTES_CPU)
    attributes = prg[
        attributes_offset:attributes_offset + INITIAL_ATTRIBUTE_COUNT
    ]
    if len(attributes) != INITIAL_ATTRIBUTE_COUNT:
        raise RoomScreenDataError("truncated initial room attribute data")
    return {
        "status_streams": streams,
        "status_tile_count": sum(stream["tile_count"] for stream in streams),
        "initial_attributes_address": f"0x{INITIAL_ATTRIBUTES_CPU:04X}",
        "initial_attributes": list(attributes),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True, help="Castle Excellent iNES image")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        prg, _chr_data = extract_rom(Path(args.image).read_bytes())
        result = analyze_room_screen(prg)
    except (OSError, RoomScreenDataError, ValueError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            f"[OK] validated {len(result['status_streams'])} room status streams, "
            f"{result['status_tile_count']} tiles, and "
            f"{len(result['initial_attributes'])} initial attribute bytes"
        )
        return 0
    print(json.dumps(result, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
