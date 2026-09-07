#!/usr/bin/env python3
"""Model the 10-by-10 castle room-navigation helpers at $A7DB-$A834."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROOM_COLUMNS = 10
ROOM_ROWS = 10
ROOM_COUNT = ROOM_COLUMNS * ROOM_ROWS
RIGHTMOST_TABLE_CPU = 0xA821
LEFTMOST_TABLE_CPU = 0xA82B
RIGHTMOST_ROOMS = tuple(range(10, ROOM_COUNT + 1, ROOM_COLUMNS))
LEFTMOST_ROOMS = tuple(range(1, ROOM_COUNT, ROOM_COLUMNS))


class RoomNavigationError(ValueError):
    pass


@dataclass(frozen=True)
class RoomPosition:
    number: int
    row: int
    column: int


@dataclass(frozen=True)
class RoomNeighbors:
    above: int
    below: int
    left: int
    right: int


def _validate_room_number(room_number: int) -> None:
    if not 1 <= room_number <= ROOM_COUNT:
        raise RoomNavigationError(
            f"one-based room number outside 1-{ROOM_COUNT}: {room_number}"
        )


def room_position(room_number: int) -> RoomPosition:
    _validate_room_number(room_number)
    zero_based = room_number - 1
    return RoomPosition(
        number=room_number,
        row=zero_based // ROOM_COLUMNS,
        column=zero_based % ROOM_COLUMNS,
    )


def move_above(room_number: int) -> int:
    position = room_position(room_number)
    return room_number if position.row == 0 else room_number - ROOM_COLUMNS


def move_below(room_number: int) -> int:
    position = room_position(room_number)
    return room_number if position.row == ROOM_ROWS - 1 else room_number + ROOM_COLUMNS


def move_left(room_number: int) -> int:
    position = room_position(room_number)
    return room_number if position.column == 0 else room_number - 1


def move_right(room_number: int) -> int:
    position = room_position(room_number)
    return room_number if position.column == ROOM_COLUMNS - 1 else room_number + 1


def room_neighbors(room_number: int) -> RoomNeighbors:
    return RoomNeighbors(
        above=move_above(room_number),
        below=move_below(room_number),
        left=move_left(room_number),
        right=move_right(room_number),
    )


def descending_edge_search(room_number: int, edge_rooms: tuple[int, ...]) -> int:
    if not 0 <= room_number <= 0xFF:
        raise RoomNavigationError(f"search value outside 0-255: {room_number}")
    if len(edge_rooms) != ROOM_ROWS:
        raise RoomNavigationError(f"edge table must contain {ROOM_ROWS} rooms")
    for index in range(ROOM_ROWS - 1, -1, -1):
        if room_number == edge_rooms[index]:
            return index
    return 0xFF


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomNavigationError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise RoomNavigationError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _cpu_offset(address: int) -> int:
    return address - PRG_BASE


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    expected_tables = (
        (RIGHTMOST_TABLE_CPU, bytes(RIGHTMOST_ROOMS)),
        (LEFTMOST_TABLE_CPU, bytes(LEFTMOST_ROOMS)),
    )
    for address, expected in expected_tables:
        start = _cpu_offset(address)
        if prg[start:start + len(expected)] != expected:
            raise RoomNavigationError(f"room-edge table at ${address:04X} changed")
    routine_bytes = bytes.fromhex(
        "A5 37 C9 0B 90 04 E9 0A 85 37 60 "
        "A5 37 C9 5B B0 04 69 0A 85 37 60 "
        "A5 37 20 0B A8 F0 05 18 69 01 85 37 60 "
        "A5 37 20 16 A8 F0 05 38 E9 01 85 37 60 "
        "A2 09 DD 21 A8 F0 03 CA 10 F8 60 "
        "A2 09 DD 2B A8 F0 03 CA 10 F8 60"
    )
    routine_start = _cpu_offset(0xA7DB)
    if prg[routine_start:routine_start + len(routine_bytes)] != routine_bytes:
        raise RoomNavigationError("room-navigation routine bytes changed")
    return {
        "routine_range": [0xA7DB, 0xA820],
        "routine_bytes": len(routine_bytes),
        "rightmost_rooms": list(RIGHTMOST_ROOMS),
        "leftmost_rooms": list(LEFTMOST_ROOMS),
    }


def validate_exhaustive_contract() -> dict[str, object]:
    positions: list[RoomPosition] = []
    for room_number in range(1, ROOM_COUNT + 1):
        position = room_position(room_number)
        neighbors = room_neighbors(room_number)
        positions.append(position)
        expected = RoomNeighbors(
            above=(
                room_number
                if position.row == 0
                else room_number - ROOM_COLUMNS
            ),
            below=(
                room_number
                if position.row == ROOM_ROWS - 1
                else room_number + ROOM_COLUMNS
            ),
            left=(room_number if position.column == 0 else room_number - 1),
            right=(
                room_number
                if position.column == ROOM_COLUMNS - 1
                else room_number + 1
            ),
        )
        if neighbors != expected:
            raise RoomNavigationError("room-neighbor mapping mismatch")
        if not all(1 <= value <= ROOM_COUNT for value in asdict(neighbors).values()):
            raise RoomNavigationError("room movement escaped the castle grid")
        if move_below(neighbors.above) != room_number and position.row != 0:
            raise RoomNavigationError("vertical room movement is not reversible")
        if move_right(neighbors.left) != room_number and position.column != 0:
            raise RoomNavigationError("horizontal room movement is not reversible")
        right_index = descending_edge_search(room_number, RIGHTMOST_ROOMS)
        left_index = descending_edge_search(room_number, LEFTMOST_ROOMS)
        if (right_index != 0xFF) != (position.column == ROOM_COLUMNS - 1):
            raise RoomNavigationError("right-edge search mismatch")
        if (left_index != 0xFF) != (position.column == 0):
            raise RoomNavigationError("left-edge search mismatch")
        if right_index != 0xFF and right_index != position.row:
            raise RoomNavigationError("right-edge row index mismatch")
        if left_index != 0xFF and left_index != position.row:
            raise RoomNavigationError("left-edge row index mismatch")
    for value in range(0x100):
        expected_right = (
            RIGHTMOST_ROOMS.index(value) if value in RIGHTMOST_ROOMS else 0xFF
        )
        expected_left = (
            LEFTMOST_ROOMS.index(value) if value in LEFTMOST_ROOMS else 0xFF
        )
        if descending_edge_search(value, RIGHTMOST_ROOMS) != expected_right:
            raise RoomNavigationError("right-edge byte-domain mismatch")
        if descending_edge_search(value, LEFTMOST_ROOMS) != expected_left:
            raise RoomNavigationError("left-edge byte-domain mismatch")
    return {
        "rooms": len(positions),
        "rows": ROOM_ROWS,
        "columns": ROOM_COLUMNS,
        "edge_search_values": 0x100,
        "corner_neighbors": {
            "1": asdict(room_neighbors(1)),
            "10": asdict(room_neighbors(10)),
            "91": asdict(room_neighbors(91)),
            "100": asdict(room_neighbors(100)),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_rom_contract(extract_prg(Path(args.image).read_bytes()))
        document["grid"] = validate_exhaustive_contract()
    except (OSError, RoomNavigationError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated all 100 rooms and both ten-entry edge tables")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
