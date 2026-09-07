#!/usr/bin/env python3
"""Model player-driven horizontal runtime-object pushing at $881A-$89E0."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys
from typing import Sequence


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_START = 0x881A
ROUTINE_END = 0x89E1
ROUTINE_SHA256 = "0d3e1aaae4bd9310be90f84713c44f5f25e8b57d7d335b14e412922b3cf972f8"
HORIZONTAL_RUNTIME_TABLE = 0x921D
HANDLER_TYPE_FIRST = 0x8A
HANDLER_TYPE_LAST = 0x8F
SPECIAL_HANDLER_TYPE = 0x8E
SPECIAL_HANDLER = 0x89E1
DIRECT_CALLER = (0x89E6, bytes.fromhex("20 1A 88"))
ROOM_SAMPLE_ROUTINE = 0x955D
PLAYER_SAMPLE_ROUTINE = 0x8DD3
ROOM_SAMPLE_CALLS = (0x882D, 0x883D, 0x884D, 0x895A, 0x896D, 0x8980)
PLAYER_SAMPLE_CALLS = (0x886B, 0x888C, 0x88AD, 0x88CD, 0x88EE, 0x890F)
MOTION_INACTIVE_THRESHOLD = 0x21
DIRECTION_LEFT = 0xFF
DIRECTION_RIGHT = 0x7F
OBJECT_SUPPORT_Y_OFFSET = 17
PROBE_Y_OFFSETS = (0, 7, 15)
RIGHT_PLAYER_TOP_OFFSET = 17
RIGHT_PLAYER_LOWER_OFFSET = 16
LEFT_PLAYER_TOP_OFFSET = 2
LEFT_PLAYER_LOWER_OFFSET = 1
OBJECT_WIDTH = 16
MOVE_STEP = 2
ROOM_RIGHT_BOUNDARY = 0x0140
DESTROYABLE_TYPE_FIRST = 0x84
DESTROYABLE_TYPE_END = 0x8A
DESTROYED_OBJECT_TYPE = 0xA8


class PlayerObjectPushError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionSample:
    value: int
    carry: bool
    object_offset: int | None = None


@dataclass(frozen=True)
class PushResult:
    player_x: int
    object_x: int
    direction_latch: int
    moved: bool
    blocked_by: str | None
    support_probes: tuple[tuple[int, int], ...]
    player_probes: tuple[tuple[int, int], ...]
    object_probes: tuple[tuple[int, int], ...]
    destroyed_object_offset: int | None


def _byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerObjectPushError(f"{name} outside 0-255: {value}")


def _word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerObjectPushError(f"{name} outside 0-65535: {value}")


def _booleans(values: Sequence[bool], name: str) -> tuple[bool, bool, bool]:
    if len(values) != 3 or any(type(value) is not bool for value in values):
        raise PlayerObjectPushError(f"{name} must contain three booleans")
    return values[0], values[1], values[2]


def _player_hits(
    values: Sequence[int | None], pushed_offset: int
) -> tuple[int | None, int | None, int | None]:
    if len(values) != 3:
        raise PlayerObjectPushError("player collisions must contain three entries")
    for value in values:
        if value is not None:
            _byte(value, "player collision object offset")
    _byte(pushed_offset, "pushed object offset")
    return values[0], values[1], values[2]


def _front_samples(values: Sequence[CollisionSample]) -> tuple[CollisionSample, ...]:
    if len(values) != 3:
        raise PlayerObjectPushError("object collisions must contain three samples")
    for sample in values:
        _byte(sample.value, "collision value")
        if type(sample.carry) is not bool:
            raise PlayerObjectPushError("collision carry must be boolean")
        if sample.object_offset is not None:
            _byte(sample.object_offset, "collision object offset")
    return tuple(values)


def _empty_result(
    player_x: int,
    object_x: int,
    direction_latch: int,
    blocked_by: str,
    support_probes: tuple[tuple[int, int], ...] = (),
    player_probes: tuple[tuple[int, int], ...] = (),
    object_probes: tuple[tuple[int, int], ...] = (),
) -> PushResult:
    return PushResult(
        player_x,
        object_x,
        direction_latch,
        False,
        blocked_by,
        support_probes,
        player_probes,
        object_probes,
        None,
    )


def push_player_and_object(
    *,
    motion_state: int,
    motion_phase: int,
    direction: int,
    player_x: int,
    player_y: int,
    object_x: int,
    object_y: int,
    pushed_offset: int,
    direction_latch: int,
    support_collisions: Sequence[bool],
    player_collisions: Sequence[int | None],
    object_collisions: Sequence[CollisionSample],
) -> PushResult:
    for value, name in (
        (motion_state, "motion state"),
        (motion_phase, "motion phase"),
        (direction, "direction"),
        (player_y, "player Y"),
        (object_y, "object Y"),
        (direction_latch, "direction latch"),
    ):
        _byte(value, name)
    _word(player_x, "player X")
    _word(object_x, "object X")
    supports = _booleans(support_collisions, "support collisions")
    player_hits = _player_hits(player_collisions, pushed_offset)
    front_samples = _front_samples(object_collisions)
    if direction not in (DIRECTION_LEFT, DIRECTION_RIGHT):
        raise PlayerObjectPushError(f"unsupported direction: {direction}")

    active_motion = motion_state if motion_state < MOTION_INACTIVE_THRESHOLD else 0
    if active_motion or motion_phase:
        return _empty_result(player_x, object_x, direction_latch, "player motion")

    support_y = (object_y + OBJECT_SUPPORT_Y_OFFSET) & 0xFF
    support_probes: list[tuple[int, int]] = []
    for x_offset, collision in zip(PROBE_Y_OFFSETS, supports, strict=True):
        support_probes.append(((object_x + x_offset) & 0xFFFF, support_y))
        if collision:
            break
    else:
        return _empty_result(
            player_x,
            object_x,
            direction_latch,
            "object unsupported",
            tuple(support_probes),
        )

    if direction == DIRECTION_RIGHT:
        player_x_offsets = (
            RIGHT_PLAYER_TOP_OFFSET,
            RIGHT_PLAYER_LOWER_OFFSET,
            RIGHT_PLAYER_LOWER_OFFSET,
        )
    else:
        player_x_offsets = (
            -LEFT_PLAYER_TOP_OFFSET,
            -LEFT_PLAYER_LOWER_OFFSET,
            -LEFT_PLAYER_LOWER_OFFSET,
        )
    player_probes: list[tuple[int, int]] = []
    for x_offset, y_offset, hit_offset in zip(
        player_x_offsets, PROBE_Y_OFFSETS, player_hits, strict=True
    ):
        player_probes.append(
            (((player_x + x_offset) & 0xFFFF), (player_y + y_offset) & 0xFF)
        )
        if hit_offset is not None and hit_offset != pushed_offset:
            return _empty_result(
                player_x,
                object_x,
                direction_latch,
                "player obstruction",
                tuple(support_probes),
                tuple(player_probes),
            )

    front_x = (
        (object_x + OBJECT_WIDTH) & 0xFFFF
        if direction == DIRECTION_RIGHT
        else (object_x - 1) & 0xFFFF
    )
    if front_x >= ROOM_RIGHT_BOUNDARY:
        return _empty_result(
            player_x,
            object_x,
            direction_latch,
            "room boundary",
            tuple(support_probes),
            tuple(player_probes),
        )

    object_probes: list[tuple[int, int]] = []
    destroyed_offset: int | None = None
    for index, (y_offset, sample) in enumerate(
        zip(PROBE_Y_OFFSETS, front_samples, strict=True)
    ):
        object_probes.append((front_x, (object_y + y_offset) & 0xFF))
        blocked = sample.carry or (index < 2 and bool(sample.value & 0x80))
        if not blocked:
            continue
        if DESTROYABLE_TYPE_FIRST <= sample.value < DESTROYABLE_TYPE_END:
            destroyed_offset = sample.object_offset
            break
        return _empty_result(
            player_x,
            object_x,
            direction_latch,
            "object obstruction",
            tuple(support_probes),
            tuple(player_probes),
            tuple(object_probes),
        )

    delta = MOVE_STEP if direction == DIRECTION_RIGHT else -MOVE_STEP
    return PushResult(
        (player_x + delta) & 0xFFFF,
        (object_x + delta) & 0xFFFF,
        direction,
        True,
        None,
        tuple(support_probes),
        tuple(player_probes),
        tuple(object_probes),
        destroyed_offset,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerObjectPushError("expected an iNES image")
    trainer = 512 if image[6] & 0x04 else 0
    size = image[4] * 16_384
    start = 16 + trainer
    if size != PRG_SIZE or start + size > len(image):
        raise PlayerObjectPushError("expected a complete 32 KiB PRG region")
    return image[start:start + size]


def _cpu_slice(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start:start + size]


def _read_word(prg: bytes, address: int) -> int:
    raw = _cpu_slice(prg, address, 2)
    return raw[0] | raw[1] << 8


def _call_sites(routine: bytes, target: int) -> tuple[int, ...]:
    opcode = bytes((0x20, target & 0xFF, target >> 8))
    return tuple(
        ROUTINE_START + offset
        for offset in range(len(routine) - 2)
        if routine[offset:offset + 3] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    routine = _cpu_slice(prg, ROUTINE_START, ROUTINE_END - ROUTINE_START)
    if hashlib.sha256(routine).hexdigest() != ROUTINE_SHA256:
        raise PlayerObjectPushError("player/object push bytes changed")
    caller, expected = DIRECT_CALLER
    if _cpu_slice(prg, caller, len(expected)) != expected:
        raise PlayerObjectPushError("type-$8E direct caller changed")
    if _call_sites(routine, ROOM_SAMPLE_ROUTINE) != ROOM_SAMPLE_CALLS:
        raise PlayerObjectPushError("normalized collision sample topology changed")
    if _call_sites(routine, PLAYER_SAMPLE_ROUTINE) != PLAYER_SAMPLE_CALLS:
        raise PlayerObjectPushError("player collision sample topology changed")
    handlers = {
        runtime_type: _read_word(
            prg, HORIZONTAL_RUNTIME_TABLE + (runtime_type - 0x80) * 2
        )
        for runtime_type in range(HANDLER_TYPE_FIRST, HANDLER_TYPE_LAST + 1)
    }
    for runtime_type, target in handlers.items():
        expected_target = SPECIAL_HANDLER if runtime_type == SPECIAL_HANDLER_TYPE else ROUTINE_START
        if target != expected_target:
            raise PlayerObjectPushError(
                f"horizontal type ${runtime_type:02X} handler changed"
            )
    return {
        "range": [ROUTINE_START, ROUTINE_END - 1],
        "bytes": len(routine),
        "horizontal_handlers": handlers,
        "direct_caller": caller,
        "room_sample_calls": list(ROOM_SAMPLE_CALLS),
        "player_sample_calls": list(PLAYER_SAMPLE_CALLS),
    }


def _base_arguments(direction: int, player_x: int = 0x0080, object_x: int = 0x0090) -> dict[str, object]:
    return {
        "motion_state": 0,
        "motion_phase": 0,
        "direction": direction,
        "player_x": player_x,
        "player_y": 0x40,
        "object_x": object_x,
        "object_y": 0x40,
        "pushed_offset": 0x18,
        "direction_latch": 0,
        "support_collisions": (True, False, False),
        "player_collisions": (None, None, None),
        "object_collisions": (
            CollisionSample(0x53, False),
            CollisionSample(0x53, False),
            CollisionSample(0x53, False),
        ),
    }


def validate_model_contract() -> dict[str, int]:
    horizontal_cases = 0
    for direction in (DIRECTION_LEFT, DIRECTION_RIGHT):
        for player_x in range(0x10000):
            result = push_player_and_object(**_base_arguments(direction, player_x=player_x))
            expected = (player_x + (2 if direction == DIRECTION_RIGHT else -2)) & 0xFFFF
            if result.player_x != expected:
                raise PlayerObjectPushError("player movement arithmetic mismatch")
            horizontal_cases += 1
        for object_x in range(0x10000):
            result = push_player_and_object(**_base_arguments(direction, object_x=object_x))
            front = (object_x + (16 if direction == DIRECTION_RIGHT else -1)) & 0xFFFF
            if result.moved != (front < ROOM_RIGHT_BOUNDARY):
                raise PlayerObjectPushError("object boundary mismatch")
            horizontal_cases += 1

    for runtime_type in range(0x100):
        arguments = _base_arguments(DIRECTION_RIGHT)
        arguments["object_collisions"] = (
            CollisionSample(runtime_type, True, 0x30),
            CollisionSample(0x53, False),
            CollisionSample(0x53, False),
        )
        result = push_player_and_object(**arguments)
        if result.moved != (DESTROYABLE_TYPE_FIRST <= runtime_type < DESTROYABLE_TYPE_END):
            raise PlayerObjectPushError("destroyable runtime-type mismatch")
    for state in range(0x100):
        arguments = _base_arguments(DIRECTION_RIGHT)
        arguments["motion_state"] = state
        result = push_player_and_object(**arguments)
        if result.moved != (state == 0 or state >= MOTION_INACTIVE_THRESHOLD):
            raise PlayerObjectPushError("active-motion normalization mismatch")
    for mask in range(8):
        arguments = _base_arguments(DIRECTION_RIGHT)
        arguments["support_collisions"] = tuple(
            bool(mask & 1 << index) for index in range(3)
        )
        result = push_player_and_object(**arguments)
        expected_count = 3 if mask == 0 else (mask & -mask).bit_length()
        if result.moved != (mask != 0) or len(result.support_probes) != expected_count:
            raise PlayerObjectPushError("support probe order mismatch")
        arguments = _base_arguments(DIRECTION_RIGHT)
        arguments["player_collisions"] = tuple(
            0x24 if mask & 1 << index else None for index in range(3)
        )
        result = push_player_and_object(**arguments)
        expected_count = 3 if mask == 0 else (mask & -mask).bit_length()
        if result.moved != (mask == 0) or len(result.player_probes) != expected_count:
            raise PlayerObjectPushError("player clearance probe order mismatch")
    return {
        "horizontal_cases": horizontal_cases,
        "runtime_type_cases": 0x100,
        "motion_state_cases": 0x100,
        "support_patterns": 8,
        "player_collision_patterns": 8,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["model"] = validate_model_contract()
        report["example"] = asdict(
            push_player_and_object(**_base_arguments(DIRECTION_RIGHT))
        )
    except (OSError, PlayerObjectPushError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 455 push-controller bytes, six handler entries, "
            "and 262,144 horizontal boundary cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
