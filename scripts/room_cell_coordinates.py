#!/usr/bin/env python3
"""Model Castle Excellent's room-cell addressing and mutable-cell ordinals."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import sys
from typing import Sequence


ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
ROOM_CELLS_BASE = 0x0400
TILES_PER_CELL = 2
PIXELS_PER_TILE = 8
MAX_TILE_COLUMN = ROOM_WIDTH * TILES_PER_CELL - 1
NMI_TASK_REQUEST_COUNT = 23
FIRST_ROOM_ROW_TASK = 1

PERSISTENT_MUTABLE_CELLS = frozenset((0x19, 0x1C, 0x1F, 0x22, 0x25, 0x29))
PERSISTENT_MUTABLE_RIGHT_CELLS = frozenset(
    (0x1A, 0x1D, 0x20, 0x23, 0x26, 0x2A)
)
RESTORED_MUTABLE_ANCHORS = frozenset((0x54, 0x62))
RESTORED_MUTABLE_LOWER_CELLS = frozenset((0x55, 0x63))
STANDARD_RESTORED_CELLS = (0x54, 0x55)
ALTERNATE_RESTORED_CELLS = (0x62, 0x63)
ALTERNATE_NEIGHBOR_CELL = 0x16
MUTABLE_CELL_STATE_BIT_MASKS = tuple(1 << bit for bit in range(8))


class RoomCellError(ValueError):
    pass


@dataclass(frozen=True)
class MutableCellRestoration:
    ordinal: int
    offset: int
    state_byte_index: int
    state_bit_mask: int
    anchor_cell: int
    lower_cell: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomCellError(f"{name} outside 0-255: {value}")


def _room_bytes(room: Sequence[int]) -> bytes:
    if len(room) != ROOM_CELL_COUNT:
        raise RoomCellError(
            f"room must contain {ROOM_CELL_COUNT} cells, got {len(room)}"
        )
    data = bytes(room)
    return data


def pixel_to_tile(pixel_x: int, pixel_y: int) -> tuple[int, int]:
    """Reproduce $A58A: A:X is a 16-bit X position and Y is an 8-bit Y."""
    if not 0 <= pixel_x <= 0xFFFF:
        raise RoomCellError(f"pixel X outside 0-65535: {pixel_x}")
    _validate_byte(pixel_y, "pixel Y")
    return (pixel_x >> 3) & 0xFF, pixel_y >> 3


def room_cell_offset(tile_x: int, tile_y: int) -> int:
    """Reproduce $A5A4 relative to the room buffer at $0400."""
    if not 0 <= tile_x <= MAX_TILE_COLUMN:
        raise RoomCellError(f"tile column outside 0-{MAX_TILE_COLUMN}: {tile_x}")
    if not 0 <= tile_y < ROOM_HEIGHT:
        raise RoomCellError(f"tile row outside 0-{ROOM_HEIGHT - 1}: {tile_y}")
    return tile_y * ROOM_WIDTH + tile_x // TILES_PER_CELL


def room_cell_row_from_address(address: int) -> int:
    """Reproduce $94C3's destructive pointer shift and divide-by-five result."""
    last_address = ROOM_CELLS_BASE + ROOM_CELL_COUNT - 1
    if not ROOM_CELLS_BASE <= address <= last_address:
        raise RoomCellError(
            f"room-cell address outside 0x{ROOM_CELLS_BASE:04X}-"
            f"0x{last_address:04X}: 0x{address:04X}"
        )
    quarter_scaled_low = (address >> 2) & 0x7F
    return quarter_scaled_low // (ROOM_WIDTH // 4)


def room_cell_update_tasks(address: int, *, include_next_row: bool) -> tuple[int, ...]:
    """Return the NMI task indexes marked by $949C or $94AC."""
    row = room_cell_row_from_address(address)
    tasks = (FIRST_ROOM_ROW_TASK + row,)
    if include_next_row and row < ROOM_HEIGHT:
        tasks += (FIRST_ROOM_ROW_TASK + row + 1,)
    if any(task >= NMI_TASK_REQUEST_COUNT for task in tasks):
        raise RoomCellError(f"room-cell update task outside request array: {tasks}")
    return tasks


def is_mutable_anchor(cell: int) -> bool:
    return cell == 0x54 or cell in PERSISTENT_MUTABLE_CELLS


def find_mutable_ordinal(
    room: Sequence[int], tile_x: int, tile_y: int
) -> int | None:
    """Reproduce $A66D, returning the carry-clear ordinal or ``None``."""
    data = _room_bytes(room)
    offset = room_cell_offset(tile_x, tile_y)
    cell = data[offset]
    if (
        cell in RESTORED_MUTABLE_LOWER_CELLS
        or cell in PERSISTENT_MUTABLE_RIGHT_CELLS
    ):
        if tile_y == 0:
            return None
        tile_y -= 1
        offset = room_cell_offset(tile_x, tile_y)
        cell = data[offset]
    if cell not in RESTORED_MUTABLE_ANCHORS and cell not in PERSISTENT_MUTABLE_CELLS:
        return None
    return 1 + sum(is_mutable_anchor(previous) for previous in data[:offset])


def restore_mutable_cell(
    room: Sequence[int], ordinal: int, *, preceding_cell: int = 0
) -> tuple[bytes, MutableCellRestoration | None]:
    """Reproduce $A70A's scan, cell writes, and persistent-state bit selection."""
    data = bytearray(_room_bytes(room))
    if not 1 <= ordinal <= 0xFF:
        raise RoomCellError(f"mutable-cell ordinal outside 1-255: {ordinal}")
    _validate_byte(preceding_cell, "preceding cell")
    remaining = ordinal
    for offset, cell in enumerate(data):
        if not is_mutable_anchor(cell):
            continue
        remaining -= 1
        if remaining:
            continue
        left = data[offset - 1] if offset else preceding_cell
        right = data[offset + 1] if offset + 1 < len(data) else 0
        alternate = ALTERNATE_NEIGHBOR_CELL in (left, right)
        anchor_cell, lower_cell = (
            ALTERNATE_RESTORED_CELLS if alternate else STANDARD_RESTORED_CELLS
        )
        if offset + ROOM_WIDTH >= len(data):
            raise RoomCellError("mutable-cell anchor has no lower room row")
        data[offset] = anchor_cell
        data[offset + ROOM_WIDTH] = lower_cell
        zero_based_ordinal = ordinal - 1
        result = MutableCellRestoration(
            ordinal=ordinal,
            offset=offset,
            state_byte_index=zero_based_ordinal >> 3,
            state_bit_mask=MUTABLE_CELL_STATE_BIT_MASKS[zero_based_ordinal & 7],
            anchor_cell=anchor_cell,
            lower_cell=lower_cell,
        )
        return bytes(data), result
    return bytes(data), None


def validate_room_cell_contract() -> dict[str, object]:
    mapped_offsets = tuple(
        room_cell_offset(tile_x, tile_y)
        for tile_y in range(ROOM_HEIGHT)
        for tile_x in range(MAX_TILE_COLUMN + 1)
    )
    if set(mapped_offsets) != set(range(ROOM_CELL_COUNT)):
        raise RoomCellError("tile-to-cell conversion does not cover the room exactly")
    if any(
        mapped_offsets.count(offset) != TILES_PER_CELL
        for offset in range(ROOM_CELL_COUNT)
    ):
        raise RoomCellError("each room cell must be selected by exactly two tiles")
    for offset in range(ROOM_CELL_COUNT):
        address = ROOM_CELLS_BASE + offset
        expected_row = offset // ROOM_WIDTH
        if room_cell_row_from_address(address) != expected_row:
            raise RoomCellError(f"wrong row for room-cell offset {offset}")
        expected_tasks = (expected_row + 1, expected_row + 2)
        if room_cell_update_tasks(address, include_next_row=True) != expected_tasks:
            raise RoomCellError(f"wrong adjacent tasks for room-cell offset {offset}")

    room = bytearray(ROOM_CELL_COUNT)
    candidate_offsets = tuple(21 + index * 22 for index in range(8))
    for index, offset in enumerate(candidate_offsets):
        room[offset] = sorted(PERSISTENT_MUTABLE_CELLS)[index % 6]
        if index & 1:
            room[offset - 1] = ALTERNATE_NEIGHBOR_CELL
    for ordinal in range(len(candidate_offsets), 0, -1):
        room_bytes, restored = restore_mutable_cell(room, ordinal)
        if restored is None or restored.offset != candidate_offsets[ordinal - 1]:
            raise RoomCellError(f"failed to restore mutable-cell ordinal {ordinal}")
        room[:] = room_bytes

    return {
        "room_grid": [ROOM_WIDTH, ROOM_HEIGHT],
        "tile_grid": [MAX_TILE_COLUMN + 1, ROOM_HEIGHT],
        "room_cell_count": ROOM_CELL_COUNT,
        "persistent_anchor_types": sorted(PERSISTENT_MUTABLE_CELLS),
        "persistent_right_types": sorted(PERSISTENT_MUTABLE_RIGHT_CELLS),
        "validated_ordinals": len(candidate_offsets),
        "state_bit_masks": list(MUTABLE_CELL_STATE_BIT_MASKS),
        "first_row_tasks": list(
            room_cell_update_tasks(ROOM_CELLS_BASE, include_next_row=True)
        ),
        "last_row_tasks": list(
            room_cell_update_tasks(
                ROOM_CELLS_BASE + ROOM_CELL_COUNT - 1, include_next_row=True
            )
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_room_cell_contract()
    except RoomCellError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated room-cell coordinates, ordinals, and restoration")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
