#!/usr/bin/env python3
"""Model the four room-boundary transition paths at $867A-$8757."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys

if __package__:
    from scripts import room_navigation
else:
    import room_navigation


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_START = 0x867A
ROUTINE_END = 0x8758
ROUTINE_SHA256 = "e8523538d3a54102df654278bd1bee18f6ca40adeab31f86cc6946e61fa2ae84"
PLAYER_X_ALIGNMENT_MASK = 0xFFF8
ABOVE_ENTRY_Y = 0x98
BELOW_ENTRY_Y = 0x10
LEFT_ENTRY_X = 0x0130
RIGHT_ENTRY_X = 0x0000
ENTRANCE_PROBE_Y_OFFSET = 0x10
ENTRY_CALLERS = {
    0x867A: (0x82D8, bytes.fromhex("4C 7A 86")),
    0x86A0: (0x840C, bytes.fromhex("4C A0 86")),
    0x86C6: (0x8551, bytes.fromhex("4C C6 86")),
    0x870F: (0x855A, bytes.fromhex("4C 0F 87")),
}
VERTICAL_CALLS = {
    "above": (
        "SaveCurrentRoomObjectState",
        "MoveToRoomAbove",
        "LoadRoom",
        "UpdateHorizontalScroll",
        "FinishRoomTransition",
    ),
    "below": (
        "SaveCurrentRoomObjectState",
        "MoveToRoomBelow",
        "LoadRoom",
        "UpdateHorizontalScroll",
        "FinishRoomTransition",
    ),
}


class RoomBoundaryTransitionError(ValueError):
    pass


@dataclass(frozen=True)
class BoundaryTransitionResult:
    direction: str
    room_number: int
    player_x: int
    player_y: int
    saved_player: tuple[int, int, int] | None
    screen_state: int | None
    mutable_probe: tuple[int, int] | None
    mutable_restored: bool
    calls: tuple[str, ...]


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise RoomBoundaryTransitionError(f"{name} outside 0-65535: {value}")


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomBoundaryTransitionError(f"{name} outside 0-255: {value}")


def _saved_player(player_x: int, player_y: int) -> tuple[int, int, int]:
    return (player_x & 0xFF, player_x >> 8, player_y)


def apply_room_boundary(
    direction: str,
    room_number: int,
    player_x: int,
    player_y: int,
    *,
    mutable_found: bool = False,
) -> BoundaryTransitionResult:
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    room_navigation.room_position(room_number)
    if direction in ("above", "below"):
        aligned_x = player_x & PLAYER_X_ALIGNMENT_MASK
        if direction == "above":
            next_room = room_navigation.move_above(room_number)
            next_y = ABOVE_ENTRY_Y
        else:
            next_room = room_navigation.move_below(room_number)
            next_y = BELOW_ENTRY_Y
        return BoundaryTransitionResult(
            direction,
            next_room,
            aligned_x,
            next_y,
            _saved_player(aligned_x, next_y),
            0,
            None,
            False,
            VERTICAL_CALLS[direction],
        )
    if direction not in ("left", "right"):
        raise RoomBoundaryTransitionError(f"unknown direction: {direction}")
    position = room_navigation.room_position(room_number)
    at_edge = position.column == (0 if direction == "left" else 9)
    edge_call = (
        "FindLeftmostCastleRoom"
        if direction == "left"
        else "FindRightmostCastleRoom"
    )
    entry_x = LEFT_ENTRY_X if direction == "left" else RIGHT_ENTRY_X
    if at_edge:
        clamped_x = RIGHT_ENTRY_X if direction == "left" else LEFT_ENTRY_X
        return BoundaryTransitionResult(
            direction,
            room_number,
            clamped_x,
            player_y,
            None,
            None,
            None,
            False,
            (edge_call, "UpdateHorizontalScroll"),
        )
    move_call = "MoveToRoomLeft" if direction == "left" else "MoveToRoomRight"
    next_room = (
        room_navigation.move_left(room_number)
        if direction == "left"
        else room_navigation.move_right(room_number)
    )
    calls = (
        edge_call,
        "SaveCurrentRoomObjectState",
        move_call,
        "LoadRoom",
        "UpdateHorizontalScroll",
        "ConvertPixelPositionToTileCoordinates",
        "FindMutableCellOrdinalAtPosition",
    )
    if mutable_found:
        calls += ("RestoreMutableCellByOrdinal",)
    calls += ("FinishRoomTransition",)
    return BoundaryTransitionResult(
        direction,
        next_room,
        entry_x,
        player_y,
        _saved_player(entry_x, player_y),
        0,
        (entry_x, (player_y - ENTRANCE_PROBE_Y_OFFSET) & 0xFF),
        mutable_found,
        calls,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomBoundaryTransitionError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise RoomBoundaryTransitionError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _cpu_slice(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start:start + size]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    routine = _cpu_slice(prg, ROUTINE_START, ROUTINE_END - ROUTINE_START)
    if hashlib.sha256(routine).hexdigest() != ROUTINE_SHA256:
        raise RoomBoundaryTransitionError("room-boundary transition bytes changed")
    for target, (caller, expected) in ENTRY_CALLERS.items():
        if _cpu_slice(prg, caller, len(expected)) != expected:
            raise RoomBoundaryTransitionError(
                f"entry caller ${caller:04X} for ${target:04X} changed"
            )
    return {
        "range": [ROUTINE_START, ROUTINE_END - 1],
        "bytes": len(routine),
        "entry_callers": {
            f"0x{target:04X}": f"0x{caller:04X}"
            for target, (caller, _) in ENTRY_CALLERS.items()
        },
    }


def validate_exhaustive_contract() -> dict[str, int]:
    vertical_x_cases = 0
    for direction in ("above", "below"):
        for player_x in range(0x10000):
            result = apply_room_boundary(direction, 55, player_x, 0)
            if result.player_x != player_x & PLAYER_X_ALIGNMENT_MASK:
                raise RoomBoundaryTransitionError("vertical X alignment mismatch")
            if result.saved_player != _saved_player(result.player_x, result.player_y):
                raise RoomBoundaryTransitionError("vertical saved-player mismatch")
            vertical_x_cases += 1
    vertical_room_cases = 0
    for direction in ("above", "below"):
        for room_number in range(1, room_navigation.ROOM_COUNT + 1):
            result = apply_room_boundary(direction, room_number, 0x0127, 0)
            expected_room = (
                room_navigation.move_above(room_number)
                if direction == "above"
                else room_navigation.move_below(room_number)
            )
            if result.room_number != expected_room:
                raise RoomBoundaryTransitionError("vertical room mapping mismatch")
            vertical_room_cases += 1
    horizontal_cases = 0
    for direction in ("left", "right"):
        for room_number in range(1, room_navigation.ROOM_COUNT + 1):
            for player_y in range(0x100):
                for mutable_found in (False, True):
                    result = apply_room_boundary(
                        direction,
                        room_number,
                        0xA55A,
                        player_y,
                        mutable_found=mutable_found,
                    )
                    position = room_navigation.room_position(room_number)
                    at_edge = position.column == (0 if direction == "left" else 9)
                    if at_edge:
                        if result.saved_player is not None or result.mutable_probe is not None:
                            raise RoomBoundaryTransitionError("edge clamp reloaded room state")
                    else:
                        expected_probe = (
                            LEFT_ENTRY_X if direction == "left" else RIGHT_ENTRY_X,
                            (player_y - ENTRANCE_PROBE_Y_OFFSET) & 0xFF,
                        )
                        if result.mutable_probe != expected_probe:
                            raise RoomBoundaryTransitionError("entrance probe mismatch")
                        if result.mutable_restored != mutable_found:
                            raise RoomBoundaryTransitionError("mutable restore branch mismatch")
                    horizontal_cases += 1
    return {
        "vertical_x_cases": vertical_x_cases,
        "vertical_room_cases": vertical_room_cases,
        "horizontal_cases": horizontal_cases,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = {
            "rom": validate_rom_contract(extract_prg(args.image.read_bytes())),
            "model": validate_exhaustive_contract(),
            "examples": {
                direction: asdict(apply_room_boundary(direction, 55, 0x0127, 0x48))
                for direction in ("above", "below", "left", "right")
            },
        }
    except (OSError, RoomBoundaryTransitionError, room_navigation.RoomNavigationError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 222 room-boundary bytes, four callers, "
            f"{report['model']['vertical_x_cases']:,} vertical-X, "
            f"{report['model']['vertical_room_cases']:,} vertical-room, and "
            f"{report['model']['horizontal_cases']:,} horizontal cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
