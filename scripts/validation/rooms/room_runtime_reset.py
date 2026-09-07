#!/usr/bin/env python3
"""Model room-runtime reset and conditional room-audio restart at $A3AC."""

from __future__ import annotations

import argparse
import json
import sys


RESET_FIELDS = (
    "player_movement_state_a",
    "player_movement_delay",
    "nmi_task_index",
    "pending_scroll_x",
    "applied_scroll_x",
    "player_movement_latch",
    "runtime_object_update_shared_flag",
    "player_movement_state_b",
    "room_frame_counter",
    "room_cell_animation_counter",
)
KEEP_AUDIO = "return"
RESTART_ROOM_AUDIO = "select_room_audio"


class RoomRuntimeResetError(ValueError):
    pass


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomRuntimeResetError(f"{name} outside 0-255: {value}")


def reset_room_runtime_state(state: dict[str, int]) -> dict[str, int]:
    missing = [name for name in RESET_FIELDS if name not in state]
    if missing:
        raise RoomRuntimeResetError("missing reset fields: " + ", ".join(missing))
    updated = dict(state)
    for name in RESET_FIELDS:
        _validate_byte(updated[name], name)
        updated[name] = 0
    return updated


def room_audio_action(game_over: int, stream_lo: int, stream_hi: int) -> str:
    _validate_byte(game_over, "game-over flag")
    _validate_byte(stream_lo, "audio stream pointer low")
    _validate_byte(stream_hi, "audio stream pointer high")
    if game_over or stream_lo or stream_hi:
        return KEEP_AUDIO
    return RESTART_ROOM_AUDIO


def validate_room_runtime_reset() -> dict[str, object]:
    original = {name: index + 1 for index, name in enumerate(RESET_FIELDS)}
    original["unrelated"] = 0xA5
    reset = reset_room_runtime_state(original)
    if any(reset[name] for name in RESET_FIELDS):
        raise RoomRuntimeResetError("a room-runtime reset field remained nonzero")
    if reset["unrelated"] != original["unrelated"]:
        raise RoomRuntimeResetError("room reset changed unrelated state")

    pointer_cases = 0
    for pointer in range(0x10000):
        action = room_audio_action(0, pointer & 0xFF, pointer >> 8)
        expected = RESTART_ROOM_AUDIO if pointer == 0 else KEEP_AUDIO
        if action != expected:
            raise RoomRuntimeResetError("audio pointer restart contract mismatch")
        pointer_cases += 1
    for game_over in range(1, 0x100):
        if room_audio_action(game_over, 0, 0) != KEEP_AUDIO:
            raise RoomRuntimeResetError("game over allowed room-audio restart")
    return {
        "reset_fields": list(RESET_FIELDS),
        "reset_field_count": len(RESET_FIELDS),
        "audio_pointer_cases_checked": pointer_cases,
        "nonzero_game_over_values_checked": 0xFF,
        "restart_condition": "game_over == 0 and stream_pointer == 0",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_room_runtime_reset()
    except RoomRuntimeResetError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated room-runtime reset and conditional audio restart")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
