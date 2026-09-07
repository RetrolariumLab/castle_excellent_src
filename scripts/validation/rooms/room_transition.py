#!/usr/bin/env python3
"""Model Castle Excellent's room-transition completion state at $952D."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import sys


RUNTIME_MIRROR_SIZE = 15
PLAYER_X_LO_OFFSET = 11
PLAYER_X_HI_OFFSET = 12
PLAYER_Y_OFFSET = 13
UNPAUSED_MODE = 0xFF
RENDER_RESUME_CALLS = (
    "ResetPpuScroll",
    "EnableNmi",
    "WaitForVblankAndEnableRendering",
)


class RoomTransitionError(ValueError):
    pass


@dataclass(frozen=True)
class RoomTransitionResult:
    runtime_mirror: bytes
    state_mirror: tuple[int, int]
    pause_mode: int
    render_calls: tuple[str, ...]


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomTransitionError(f"{name} outside 0-255: {value}")


def finish_room_transition(
    runtime_mirror: bytes,
    *,
    player_x: int,
    player_y: int,
    state_byte0: int,
    state_byte1: int,
) -> RoomTransitionResult:
    if len(runtime_mirror) != RUNTIME_MIRROR_SIZE:
        raise RoomTransitionError(
            f"runtime mirror must contain {RUNTIME_MIRROR_SIZE} bytes"
        )
    if not 0 <= player_x <= 0xFFFF:
        raise RoomTransitionError(f"player X outside 0-65535: {player_x}")
    _validate_byte(player_y, "player Y")
    _validate_byte(state_byte0, "transition state byte 0")
    _validate_byte(state_byte1, "transition state byte 1")
    updated = bytearray(runtime_mirror)
    updated[PLAYER_X_LO_OFFSET] = player_x & 0xFF
    updated[PLAYER_X_HI_OFFSET] = player_x >> 8
    updated[PLAYER_Y_OFFSET] = player_y
    return RoomTransitionResult(
        runtime_mirror=bytes(updated),
        state_mirror=(state_byte0, state_byte1),
        pause_mode=UNPAUSED_MODE,
        render_calls=RENDER_RESUME_CALLS,
    )


def validate_room_transition_contract() -> dict[str, object]:
    original = bytes(range(RUNTIME_MIRROR_SIZE))
    result = finish_room_transition(
        original,
        player_x=0x01F8,
        player_y=0x98,
        state_byte0=0x28,
        state_byte1=0x09,
    )
    if result.runtime_mirror[:PLAYER_X_LO_OFFSET] != original[:PLAYER_X_LO_OFFSET]:
        raise RoomTransitionError("transition overwrote unrelated runtime bytes")
    if result.runtime_mirror[14] != original[14]:
        raise RoomTransitionError("transition overwrote runtime byte 14")
    return {
        "runtime_mirror_size": RUNTIME_MIRROR_SIZE,
        "player_offsets": [PLAYER_X_LO_OFFSET, PLAYER_X_HI_OFFSET, PLAYER_Y_OFFSET],
        "mirrored_player": list(
            result.runtime_mirror[PLAYER_X_LO_OFFSET : PLAYER_Y_OFFSET + 1]
        ),
        "state_mirror": list(result.state_mirror),
        "pause_mode": result.pause_mode,
        "render_calls": list(result.render_calls),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_room_transition_contract()
    except RoomTransitionError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated room-transition state mirroring and render resume")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
