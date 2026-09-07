#!/usr/bin/env python3
"""Model Castle Excellent's NMI status-tile upload contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Sequence


INES_HEADER_SIZE = 16
PRG_CPU_BASE = 0x8000
NMI_HANDLER_HIGH_ADDRESS = 0xC88E
NMI_HANDLER_LOW_ADDRESS = 0xC8A5
NMI_TASK_COUNT = 23
STATUS_TASK_ADDRESS = 0xC804
FIRST_ROOM_ROW_TASK_ADDRESS = 0xC8BC
STATUS_SCORE_PPU_ADDRESS = 0x2096
STATUS_INVENTORY_PPU_ADDRESS = 0x2087
STATUS_LIVES_PPU_ADDRESS = 0x20A8
STATUS_SCORE_TILE_COUNT = 5
STATUS_INVENTORY_TILE_COUNT = 6
STATUS_LIVES_FORMATTED_TILE_COUNT = 3
STATUS_INVENTORY_UPLOAD_ORDER = (0, 1, 5, 4, 3, 2)
STATUS_LIVES_UPLOAD_ORDER = (1, 0)


class StatusUploadError(ValueError):
    pass


def _validate_tiles(tiles: Sequence[int], count: int, name: str) -> tuple[int, ...]:
    if len(tiles) != count:
        raise StatusUploadError(f"{name} has {len(tiles)} tiles, expected {count}")
    if any(not 0 <= tile <= 0xFF for tile in tiles):
        raise StatusUploadError(f"{name} contains a value outside byte range")
    return tuple(tiles)


def build_status_writes(
    score_tiles: Sequence[int],
    inventory_tiles: Sequence[int],
    lives_tiles: Sequence[int],
) -> tuple[tuple[int, tuple[int, ...]], ...]:
    """Return the three sequential PPU writes performed at $C80C-$C87C."""
    score = _validate_tiles(score_tiles, STATUS_SCORE_TILE_COUNT, "score buffer")
    inventory = _validate_tiles(
        inventory_tiles, STATUS_INVENTORY_TILE_COUNT, "inventory buffer"
    )
    lives = _validate_tiles(
        lives_tiles, STATUS_LIVES_FORMATTED_TILE_COUNT, "lives buffer"
    )
    return (
        (STATUS_SCORE_PPU_ADDRESS, score),
        (
            STATUS_INVENTORY_PPU_ADDRESS,
            tuple(inventory[index] for index in STATUS_INVENTORY_UPLOAD_ORDER),
        ),
        (
            STATUS_LIVES_PPU_ADDRESS,
            tuple(lives[index] for index in STATUS_LIVES_UPLOAD_ORDER),
        ),
    )


def read_first_handler_pair(image: Path) -> tuple[int, int]:
    data = image.read_bytes()
    if len(data) < INES_HEADER_SIZE or data[:4] != b"NES\x1a":
        raise StatusUploadError(f"{image} is not an iNES image")
    prg_size = data[4] * 0x4000
    prg = data[INES_HEADER_SIZE : INES_HEADER_SIZE + prg_size]
    high_offset = NMI_HANDLER_HIGH_ADDRESS - PRG_CPU_BASE
    low_offset = NMI_HANDLER_LOW_ADDRESS - PRG_CPU_BASE
    high = prg[high_offset : high_offset + NMI_TASK_COUNT]
    low = prg[low_offset : low_offset + NMI_TASK_COUNT]
    if len(high) != NMI_TASK_COUNT or len(low) != NMI_TASK_COUNT:
        raise StatusUploadError("NMI handler tables fall outside PRG-ROM")
    handlers = tuple(
        (high_byte << 8) | low_byte
        for high_byte, low_byte in zip(high, low, strict=True)
    )
    return handlers[0], handlers[1]


def validate_status_contract(image: Path) -> dict[str, object]:
    first_handlers = read_first_handler_pair(image)
    if first_handlers != (STATUS_TASK_ADDRESS, FIRST_ROOM_ROW_TASK_ADDRESS):
        raise StatusUploadError(f"unexpected first NMI handlers: {first_handlers}")
    writes = build_status_writes(range(5), range(6), range(3))
    expected = (
        (STATUS_SCORE_PPU_ADDRESS, (0, 1, 2, 3, 4)),
        (STATUS_INVENTORY_PPU_ADDRESS, (0, 1, 5, 4, 3, 2)),
        (STATUS_LIVES_PPU_ADDRESS, (1, 0)),
    )
    if writes != expected:
        raise StatusUploadError("status PPU write order does not match the handler")
    return {
        "status_task": f"0x{STATUS_TASK_ADDRESS:04X}",
        "busy_fallback_task": f"0x{FIRST_ROOM_ROW_TASK_ADDRESS:04X}",
        "writes": [
            {
                "ppu_address": f"0x{address:04X}",
                "source_order": list(source_order),
            }
            for address, source_order in writes
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_status_contract(args.image)
    except (OSError, StatusUploadError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated status interlock, three PPU destinations, "
            "and 13 uploaded tiles"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
