#!/usr/bin/env python3
"""Model the room-cell animation scans at $A3D2-$A496."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys


ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
PRG_CPU_BASE = 0x8000
PRG_SIZE = 0x8000

DECREMENTING_FIRST = 0x35
DECREMENTING_FRAMES = bytes(
    (0x38, 0x35, 0x36, 0x37, 0x3C, 0x39, 0x3A, 0x3B, 0x40, 0x3D, 0x3E, 0x3F)
)
DECREMENTING_REDRAW_END = 0x39
SLOW_FIRST = 0x45
SLOW_FRAMES = bytes((0x46, 0x47, 0x48, 0x45))
INCREMENTING_FIRST = 0x56
INCREMENTING_FRAMES = bytes(
    (0x57, 0x58, 0x59, 0x56, 0x5B, 0x5C, 0x5D, 0x5A, 0x5F, 0x60, 0x61, 0x5E)
)
INCREMENTING_REDRAW_END = 0x5A

SLOW_TABLE_CPU = 0xA41B
DECREMENTING_TABLE_CPU = 0xA47F
INCREMENTING_TABLE_CPU = 0xA48B


class RoomCellAnimationError(ValueError):
    pass


@dataclass(frozen=True)
class AnimationResult:
    cells: bytes
    slow_counter: int
    requested_rows: tuple[int, ...]


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomCellAnimationError(f"{name} outside 0-255: {value}")


def _advance_from_table(value: int, first: int, frames: bytes) -> int | None:
    offset = value - first
    if 0 <= offset < len(frames):
        return frames[offset]
    return None


def advance_fast_cell(value: int) -> tuple[int, bool]:
    """Return the fast-animation replacement and whether its row is requested."""
    _validate_byte(value, "room cell")
    replacement = _advance_from_table(value, DECREMENTING_FIRST, DECREMENTING_FRAMES)
    if replacement is not None:
        return replacement, value < DECREMENTING_REDRAW_END
    replacement = _advance_from_table(value, INCREMENTING_FIRST, INCREMENTING_FRAMES)
    if replacement is not None:
        return replacement, value < INCREMENTING_REDRAW_END
    return value, False


def advance_slow_cell(value: int) -> tuple[int, bool]:
    """Return the intermittent-animation replacement and redraw request."""
    _validate_byte(value, "room cell")
    replacement = _advance_from_table(value, SLOW_FIRST, SLOW_FRAMES)
    if replacement is None:
        return value, False
    return replacement, True


def animate_room_cells(
    cells: bytes | bytearray,
    room_frame_counter: int,
    slow_counter: int,
) -> AnimationResult:
    if len(cells) != ROOM_CELL_COUNT:
        raise RoomCellAnimationError(
            f"room has {len(cells)} cells, expected {ROOM_CELL_COUNT}"
        )
    _validate_byte(room_frame_counter, "room frame counter")
    _validate_byte(slow_counter, "slow animation counter")

    output = bytearray(cells)
    requested_rows: set[int] = set()
    if not room_frame_counter & 1:
        return AnimationResult(bytes(output), slow_counter, ())

    for index, value in enumerate(output):
        replacement, request = advance_fast_cell(value)
        output[index] = replacement
        if request:
            requested_rows.add(index // ROOM_WIDTH)

    slow_counter = (slow_counter + 1) & 0xFF
    if slow_counter & 0x80 or slow_counter & 0x03:
        return AnimationResult(bytes(output), slow_counter, tuple(sorted(requested_rows)))

    for index, value in enumerate(output):
        replacement, request = advance_slow_cell(value)
        output[index] = replacement
        if request:
            requested_rows.add(index // ROOM_WIDTH)
    return AnimationResult(bytes(output), slow_counter, tuple(sorted(requested_rows)))


def _extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomCellAnimationError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or len(image) < prg_end:
        raise RoomCellAnimationError("expected a complete 32 KiB PRG image")
    return image[prg_start:prg_end]


def _table_at(prg: bytes, address: int, size: int) -> bytes:
    offset = address - PRG_CPU_BASE
    return prg[offset:offset + size]


def validate_room_cell_animation(image: bytes) -> dict[str, object]:
    prg = _extract_prg(image)
    tables = (
        ("slow", SLOW_TABLE_CPU, SLOW_FRAMES),
        ("decrementing", DECREMENTING_TABLE_CPU, DECREMENTING_FRAMES),
        ("incrementing", INCREMENTING_TABLE_CPU, INCREMENTING_FRAMES),
    )
    for name, address, expected in tables:
        actual = _table_at(prg, address, len(expected))
        if actual != expected:
            raise RoomCellAnimationError(
                f"{name} frame table mismatch at ${address:04X}: {actual.hex()}"
            )

    for value in range(0x100):
        fast_value, fast_request = advance_fast_cell(value)
        in_decrementing = (
            DECREMENTING_FIRST <= value < DECREMENTING_FIRST + len(DECREMENTING_FRAMES)
        )
        in_incrementing = (
            INCREMENTING_FIRST <= value < INCREMENTING_FIRST + len(INCREMENTING_FRAMES)
        )
        if (fast_value != value) != (in_decrementing or in_incrementing):
            raise RoomCellAnimationError(f"fast mapping domain mismatch at ${value:02X}")
        expected_request = (
            DECREMENTING_FIRST <= value < DECREMENTING_REDRAW_END
            or INCREMENTING_FIRST <= value < INCREMENTING_REDRAW_END
        )
        if fast_request != expected_request:
            raise RoomCellAnimationError(f"fast redraw domain mismatch at ${value:02X}")
        slow_value, slow_request = advance_slow_cell(value)
        in_slow = SLOW_FIRST <= value < SLOW_FIRST + len(SLOW_FRAMES)
        if (slow_value != value) != in_slow or slow_request != in_slow:
            raise RoomCellAnimationError(f"slow mapping domain mismatch at ${value:02X}")

    neutral_room = bytes(ROOM_CELL_COUNT)
    cadence_cases = 0
    for frame in range(0x100):
        for counter in range(0x100):
            result = animate_room_cells(neutral_room, frame, counter)
            expected_counter = (counter + 1) & 0xFF if frame & 1 else counter
            if result.slow_counter != expected_counter:
                raise RoomCellAnimationError("slow counter cadence mismatch")
            cadence_cases += 1

    row_room = bytearray(ROOM_CELL_COUNT)
    for row in range(ROOM_HEIGHT):
        row_room[row * ROOM_WIDTH] = DECREMENTING_FIRST
    row_result = animate_room_cells(row_room, 1, 0)
    if row_result.requested_rows != tuple(range(ROOM_HEIGHT)):
        raise RoomCellAnimationError("row redraw requests do not cover the room")

    return {
        "room_cells_scanned": ROOM_CELL_COUNT,
        "frame_table_bytes": sum(len(expected) for _, _, expected in tables),
        "fast_cell_values": len(DECREMENTING_FRAMES) + len(INCREMENTING_FRAMES),
        "slow_cell_values": len(SLOW_FRAMES),
        "cadence_cases_checked": cadence_cases,
        "redraw_rows_checked": ROOM_HEIGHT,
        "slow_update_condition": "odd room frame, incremented counter nonnegative and divisible by four",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_room_cell_animation(args.image.read_bytes())
    except (OSError, RoomCellAnimationError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 400-cell room animation, 28 frame-table bytes, "
            "and 65,536 cadence cases"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
