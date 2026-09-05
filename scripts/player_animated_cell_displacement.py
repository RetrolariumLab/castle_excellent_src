#!/usr/bin/env python3
"""Model animated-cell forced player displacement at $8785-$8819."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys
from typing import Sequence


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8785
ROUTINE_END = 0x881A
COLLISION_SAMPLE_CPU = 0x8DD3
COLLISION_HANDLER_TABLE_CPU = 0x8F29
LEFT_CELL_FIRST = 0x56
LEFT_CELL_LAST = 0x61
RIGHT_CELL_FIRST = 0x35
RIGHT_CELL_LAST = 0x40
PLAYER_STEP = 2
RIGHT_EDGE_OFFSET = 17
RIGHT_LIMIT = 0x013F
PROBE_Y_OFFSETS = (0, 7, 15)
MOVEMENT_LATCH_SET = 0xFF
EXPECTED_SAMPLE_CALLS = (0x879A, 0x87A9, 0x87B8, 0x87F5, 0x8804, 0x8813)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A5 38 38 E9 02 85 21 A5 39 E9 00 85 22 30 36 A4 3A A6 21 "
    "A5 22 20 D3 8D B0 2B A5 3A 18 69 07 A8 A6 21 A5 22 20 D3 "
    "8D B0 1C A5 3A 18 69 0F A8 A6 21 A5 22 20 D3 8D B0 0D A5 "
    "21 85 38 A5 22 85 39 A9 FF 8D 74 07 60 A5 38 18 69 02 85 "
    "21 A5 39 69 00 85 22 A5 38 18 69 11 85 23 A5 39 69 00 85 "
    "24 A5 38 C9 3F A5 39 E9 01 B0 DB A4 3A A6 23 A5 24 20 D3 "
    "8D B0 D0 A5 3A 18 69 07 A8 A6 23 A5 24 20 D3 8D B0 C1 A5 "
    "3A 18 69 0F A8 A6 23 A5 24 20 D3 8D B0 B2 90 A3"
)


class AnimatedCellDisplacementError(ValueError):
    pass


@dataclass(frozen=True)
class AnimatedCellDisplacement:
    player_x: int
    movement_latch: int
    probes: tuple[tuple[int, int], ...]
    moved: bool
    blocked_by: str | None


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise AnimatedCellDisplacementError(f"{name} outside 0-65535: {value}")


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise AnimatedCellDisplacementError(f"{name} outside 0-255: {value}")


def _validate_collisions(collisions: Sequence[bool]) -> tuple[bool, bool, bool]:
    if len(collisions) != len(PROBE_Y_OFFSETS) or any(
        type(value) is not bool for value in collisions
    ):
        raise AnimatedCellDisplacementError("collisions must contain three booleans")
    return collisions[0], collisions[1], collisions[2]


def _sample_until_blocked(
    probe_x: int, player_y: int, collisions: tuple[bool, bool, bool]
) -> tuple[tuple[tuple[int, int], ...], bool]:
    probes: list[tuple[int, int]] = []
    for y_offset, collision in zip(PROBE_Y_OFFSETS, collisions, strict=True):
        probes.append((probe_x, (player_y + y_offset) & 0xFF))
        if collision:
            return tuple(probes), True
    return tuple(probes), False


def move_player_left(
    player_x: int,
    player_y: int,
    movement_latch: int,
    collisions: Sequence[bool],
) -> AnimatedCellDisplacement:
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    _validate_byte(movement_latch, "movement latch")
    collision_tuple = _validate_collisions(collisions)
    candidate = (player_x - PLAYER_STEP) & 0xFFFF
    if candidate & 0x8000:
        return AnimatedCellDisplacement(
            player_x, movement_latch, (), False, "negative candidate"
        )
    probes, blocked = _sample_until_blocked(candidate, player_y, collision_tuple)
    if blocked:
        return AnimatedCellDisplacement(
            player_x, movement_latch, probes, False, "collision"
        )
    return AnimatedCellDisplacement(
        candidate, MOVEMENT_LATCH_SET, probes, True, None
    )


def move_player_right(
    player_x: int,
    player_y: int,
    movement_latch: int,
    collisions: Sequence[bool],
) -> AnimatedCellDisplacement:
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    _validate_byte(movement_latch, "movement latch")
    collision_tuple = _validate_collisions(collisions)
    if player_x >= RIGHT_LIMIT:
        return AnimatedCellDisplacement(
            player_x, movement_latch, (), False, "right limit"
        )
    candidate = (player_x + PLAYER_STEP) & 0xFFFF
    edge = (player_x + RIGHT_EDGE_OFFSET) & 0xFFFF
    probes, blocked = _sample_until_blocked(edge, player_y, collision_tuple)
    if blocked:
        return AnimatedCellDisplacement(
            player_x, movement_latch, probes, False, "collision"
        )
    return AnimatedCellDisplacement(
        candidate, MOVEMENT_LATCH_SET, probes, True, None
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise AnimatedCellDisplacementError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise AnimatedCellDisplacementError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    if prg[start:start + len(EXPECTED_ROUTINE_BYTES)] != EXPECTED_ROUTINE_BYTES:
        raise AnimatedCellDisplacementError("animated-cell displacement bytes changed")
    opcode = bytes((0x20, COLLISION_SAMPLE_CPU & 0xFF, COLLISION_SAMPLE_CPU >> 8))
    calls = tuple(
        ROUTINE_CPU + offset
        for offset in range(len(EXPECTED_ROUTINE_BYTES) - 2)
        if EXPECTED_ROUTINE_BYTES[offset:offset + 3] == opcode
    )
    if calls != EXPECTED_SAMPLE_CALLS:
        raise AnimatedCellDisplacementError("collision sample call sites changed")
    left_entries = tuple(
        _read_word(prg, COLLISION_HANDLER_TABLE_CPU + cell * 2)
        for cell in range(LEFT_CELL_FIRST, LEFT_CELL_LAST + 1)
    )
    right_entries = tuple(
        _read_word(prg, COLLISION_HANDLER_TABLE_CPU + cell * 2)
        for cell in range(RIGHT_CELL_FIRST, RIGHT_CELL_LAST + 1)
    )
    if left_entries != (ROUTINE_CPU,) * 12:
        raise AnimatedCellDisplacementError("incrementing-cell handler entries changed")
    if right_entries != (0x87CB,) * 12:
        raise AnimatedCellDisplacementError("decrementing-cell handler entries changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "sample_calls": list(calls),
        "left_cell_range": [LEFT_CELL_FIRST, LEFT_CELL_LAST],
        "right_cell_range": [RIGHT_CELL_FIRST, RIGHT_CELL_LAST],
        "handler_entries": len(left_entries) + len(right_entries),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    for player_x in range(0x10000):
        left = move_player_left(player_x, 0, 0x55, (False, False, False))
        left_candidate = (player_x - PLAYER_STEP) & 0xFFFF
        expected_left = not left_candidate & 0x8000
        if left.moved != expected_left:
            raise AnimatedCellDisplacementError("left signed-boundary mismatch")
        right = move_player_right(player_x, 0, 0x55, (False, False, False))
        if right.moved != (player_x < RIGHT_LIMIT):
            raise AnimatedCellDisplacementError("right boundary mismatch")
    for player_y in range(0x100):
        expected_y = tuple((player_y + offset) & 0xFF for offset in PROBE_Y_OFFSETS)
        left = move_player_left(2, player_y, 0, (False, False, False))
        right = move_player_right(0, player_y, 0, (False, False, False))
        if tuple(y for _, y in left.probes) != expected_y:
            raise AnimatedCellDisplacementError("left probe Y mismatch")
        if tuple(y for _, y in right.probes) != expected_y:
            raise AnimatedCellDisplacementError("right probe Y mismatch")
    for mask in range(8):
        collisions = tuple(bool(mask & 1 << index) for index in range(3))
        expected_count = 3 if mask == 0 else (mask & -mask).bit_length()
        for result in (
            move_player_left(2, 0, 0x55, collisions),
            move_player_right(0, 0, 0x55, collisions),
        ):
            if result.moved != (mask == 0) or len(result.probes) != expected_count:
                raise AnimatedCellDisplacementError("collision probe order mismatch")
    return {"x_cases": 131_072, "y_cases": 512, "collision_patterns": 16}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
        report["left_example"] = asdict(
            move_player_left(0x0100, 0x40, 0, (False, False, False))
        )
        report["right_example"] = asdict(
            move_player_right(0x0100, 0x40, 0, (False, False, False))
        )
    except (OSError, AnimatedCellDisplacementError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 24 handler entries, six ordered collision calls, "
            "and all animated-cell displacement boundaries"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
