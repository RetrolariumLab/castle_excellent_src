#!/usr/bin/env python3
"""Model Castle Excellent's 10x10 castle-map marker placement."""

from __future__ import annotations

import argparse
import json
import sys


ROOM_COUNT = 100
MAP_COLUMNS = 10
VISITED_MARKER_TOP_LEFT = 0x20C6
VISITED_MARKER_ROW_STRIDE = 0x40
VISITED_MARKER_COLUMN_STRIDE = 2
VISITED_MARKER_TILES = (0x07, 0x08, 0x09, 0x0A)
CURRENT_MARKER_Y_BASE = 0x33
CURRENT_MARKER_X_BASE = 0x34
CURRENT_MARKER_STRIDE = 0x10
CURRENT_MARKER_TILE = 0xF0


class CastleMapError(ValueError):
    pass


def room_coordinates(zero_based_room: int) -> tuple[int, int]:
    if not 0 <= zero_based_room < ROOM_COUNT:
        raise CastleMapError(f"room outside 0-{ROOM_COUNT - 1}: {zero_based_room}")
    return divmod(zero_based_room, MAP_COLUMNS)


def visited_room_marker(zero_based_room: int) -> tuple[int, int, tuple[int, ...]]:
    row, column = room_coordinates(zero_based_room)
    top = (
        VISITED_MARKER_TOP_LEFT
        + row * VISITED_MARKER_ROW_STRIDE
        + column * VISITED_MARKER_COLUMN_STRIDE
    )
    return top, top + 0x20, VISITED_MARKER_TILES


def current_room_sprite(one_based_room: int) -> tuple[int, int, int, int]:
    if not 1 <= one_based_room <= ROOM_COUNT:
        raise CastleMapError(f"one-based room outside 1-{ROOM_COUNT}: {one_based_room}")
    row, column = room_coordinates(one_based_room - 1)
    return (
        CURRENT_MARKER_Y_BASE + row * CURRENT_MARKER_STRIDE,
        CURRENT_MARKER_TILE,
        0,
        CURRENT_MARKER_X_BASE + column * CURRENT_MARKER_STRIDE,
    )


def validate_castle_map_contract() -> dict[str, object]:
    markers = tuple(visited_room_marker(room) for room in range(ROOM_COUNT))
    if len({top for top, _, _ in markers}) != ROOM_COUNT:
        raise CastleMapError("visited-room marker addresses are not unique")
    sprites = tuple(current_room_sprite(room) for room in range(1, ROOM_COUNT + 1))
    if len({(sprite[0], sprite[3]) for sprite in sprites}) != ROOM_COUNT:
        raise CastleMapError("current-room sprite positions are not unique")
    return {
        "room_count": ROOM_COUNT,
        "grid": [MAP_COLUMNS, ROOM_COUNT // MAP_COLUMNS],
        "first_visited_marker": [f"0x{value:04X}" for value in markers[0][:2]],
        "last_visited_marker": [f"0x{value:04X}" for value in markers[-1][:2]],
        "first_current_sprite": list(sprites[0]),
        "last_current_sprite": list(sprites[-1]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_castle_map_contract()
    except CastleMapError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated all 100 castle-map tile and OAM marker positions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
