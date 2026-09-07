#!/usr/bin/env python3
"""Model Castle Excellent's new-game state initialization at $A2B1."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys


INES_HEADER_SIZE = 16
PRG_START = 0x8000
PRG_SIZE = 0x8000
INITIAL_ROOM_NUMBER = 0x47
INITIAL_PLAYER_LIVES = 3
INITIAL_PLAYER_Y = 0x98
RUNTIME_STATE_SIZE = 14
RUNTIME_LOAD_MIRROR_SIZE = 15
ROOM_STATE_SIZE = 9
MUTABLE_REGION_SIZE = 0x78
OBJECT_REGION_SIZE = 0x96
VISITED_ROOM_COUNT = 100
ROOM_PALETTE_ADDRESS = 0xC53D
STATUS_TILES_BUSY = 0xFF
OPERAND_BYTES = {
    0xA2B2: INITIAL_ROOM_NUMBER,
    0xA2B6: INITIAL_PLAYER_LIVES,
    0xA31A: RUNTIME_STATE_SIZE - 1,
    0xA327: MUTABLE_REGION_SIZE,
    0xA32F: OBJECT_REGION_SIZE,
    0xA337: ROOM_STATE_SIZE * 3,
    0xA33F: VISITED_ROOM_COUNT,
    0xA34C: INITIAL_PLAYER_Y,
    0xA352: ROOM_PALETTE_ADDRESS >> 8,
    0xA356: ROOM_PALETTE_ADDRESS & 0xFF,
}


class NewGameStateError(ValueError):
    pass


@dataclass(frozen=True)
class NewGameState:
    current_room_state: bytes
    room_state_load_mirror: bytes
    room_state_snapshot_a: bytes
    room_state_snapshot_b: bytes
    runtime_state: bytes
    runtime_load_mirror: bytes
    runtime_snapshot_a: bytes
    mutable_region: bytes
    object_region: bytes
    visited_rooms: bytes
    player_lives: int
    player_x: int
    player_y: int
    player_transition_countdown: int
    pause_mode: int
    castle_map_mode: int
    game_over_active: int
    status_tiles_busy: int
    sound_effect_busy: tuple[int, int, int, int]
    palette_address: int


def read_prg(image_path: Path) -> bytes:
    image = image_path.read_bytes()
    expected_size = INES_HEADER_SIZE + PRG_SIZE
    if len(image) < expected_size:
        raise NewGameStateError(f"image too short for 32 KiB PRG: {len(image)} bytes")
    return image[INES_HEADER_SIZE:expected_size]


def initialize_new_game(
    runtime_load_mirror: bytes,
    room_state_snapshot_b: bytes,
) -> NewGameState:
    if len(runtime_load_mirror) != RUNTIME_LOAD_MIRROR_SIZE:
        raise NewGameStateError(
            f"runtime load mirror must contain {RUNTIME_LOAD_MIRROR_SIZE} bytes"
        )
    if len(room_state_snapshot_b) != ROOM_STATE_SIZE:
        raise NewGameStateError(
            f"room snapshot B must contain {ROOM_STATE_SIZE} bytes"
        )

    initial_runtime = bytes(RUNTIME_STATE_SIZE)
    updated_runtime = bytearray(initial_runtime)
    updated_runtime[13] = INITIAL_PLAYER_Y
    updated_load_mirror = initial_runtime + runtime_load_mirror[14:15]
    updated_snapshot_b = bytes((0,)) + room_state_snapshot_b[1:]
    return NewGameState(
        current_room_state=bytes((INITIAL_ROOM_NUMBER,)) + bytes(ROOM_STATE_SIZE - 1),
        room_state_load_mirror=bytes(ROOM_STATE_SIZE),
        room_state_snapshot_a=bytes(ROOM_STATE_SIZE),
        room_state_snapshot_b=updated_snapshot_b,
        runtime_state=bytes(updated_runtime),
        runtime_load_mirror=updated_load_mirror,
        runtime_snapshot_a=initial_runtime,
        mutable_region=bytes(MUTABLE_REGION_SIZE),
        object_region=bytes(OBJECT_REGION_SIZE),
        visited_rooms=bytes(VISITED_ROOM_COUNT),
        player_lives=INITIAL_PLAYER_LIVES,
        player_x=0,
        player_y=INITIAL_PLAYER_Y,
        player_transition_countdown=0,
        pause_mode=0,
        castle_map_mode=0,
        game_over_active=0,
        status_tiles_busy=STATUS_TILES_BUSY,
        sound_effect_busy=(0, 0, 0, 0),
        palette_address=ROOM_PALETTE_ADDRESS,
    )


def validate_new_game_state(image_path: Path) -> dict[str, object]:
    prg = read_prg(image_path)
    for address, expected in OPERAND_BYTES.items():
        actual = prg[address - PRG_START]
        if actual != expected:
            raise NewGameStateError(
                f"operand at ${address:04X} is ${actual:02X}, expected ${expected:02X}"
            )

    previous_runtime = bytes(range(RUNTIME_LOAD_MIRROR_SIZE))
    previous_snapshot_b = bytes(range(0xA0, 0xA0 + ROOM_STATE_SIZE))
    result = initialize_new_game(previous_runtime, previous_snapshot_b)
    if result.runtime_load_mirror[:RUNTIME_STATE_SIZE] != bytes(RUNTIME_STATE_SIZE):
        raise NewGameStateError("initial runtime state was not mirrored as zero")
    if result.runtime_load_mirror[14] != previous_runtime[14]:
        raise NewGameStateError("runtime load-mirror byte 14 was unexpectedly changed")
    if result.room_state_snapshot_b[1:] != previous_snapshot_b[1:]:
        raise NewGameStateError("snapshot B payload was unexpectedly cleared")
    if result.runtime_state[13] != INITIAL_PLAYER_Y:
        raise NewGameStateError("active runtime Y was not updated after mirror copy")
    return {
        "initial_room_number": result.current_room_state[0],
        "initial_player_lives": result.player_lives,
        "initial_player_position": [result.player_x, result.player_y],
        "runtime_state_bytes_copied": RUNTIME_STATE_SIZE,
        "preserved_runtime_load_byte": result.runtime_load_mirror[14],
        "preserved_snapshot_b_bytes": list(result.room_state_snapshot_b[1:]),
        "mutable_region_bytes_cleared": len(result.mutable_region),
        "object_region_bytes_cleared": len(result.object_region),
        "visited_flags_cleared": len(result.visited_rooms),
        "palette_address": result.palette_address,
        "operand_bytes_checked": len(OPERAND_BYTES),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_new_game_state(args.image)
    except (OSError, NewGameStateError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated new-game state, persistent clears, and room palette"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
