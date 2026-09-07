#!/usr/bin/env python3
"""Model player input, movement, collision dispatch, and action hits at $82CE-$8679."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass, replace
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_START = 0x82CE
ROUTINE_END = 0x867A
ROUTINE_SHA256 = "2c5f5105f1b8b8883d9de37fa408cba673a1bbf44a19713815d802080135638a"
CONTROLLER_A = 0x01
CONTROLLER_B = 0x02
CONTROLLER_LEFT = 0x40
CONTROLLER_RIGHT = 0x80
CONTROLLER_HORIZONTAL = CONTROLLER_LEFT | CONTROLLER_RIGHT
ACTION_DURATION = 10
DIRECTION_LEFT = 0xFF
DIRECTION_RIGHT = 0x7F
DIRECTION_NONE = 0
HORIZONTAL_STEP = 2
RIGHT_COLLISION_OFFSET = 17
RIGHT_ACTION_OFFSET = 22
LEFT_ACTION_OFFSET = 6
ACTION_Y_OFFSET = 5
ROOM_RIGHT_BOUNDARY = 0x0131
ACTION_RIGHT_BOUNDARY = 0x0140
ACTIVE_MOTION_END = 0x21
ATTACKABLE_TYPES = frozenset((0x84, 0x87, 0x88))
ACTIVE_OBJECT_TYPE_FIRST = 0x80
ACTIVE_OBJECT_TYPE_END = 0xA8
DESTROYED_OBJECT_TYPE = 0xA8
ENTRY_CALLER = (0x8299, bytes.fromhex("20 CE 82"))
SYNTHETIC_CALLS = {
    0x8398: bytes.fromhex("A9 83 48 A9 A0 48 6C 31 00"),
    0x8435: bytes.fromhex("A9 84 48 A9 3D 48 6C 31 00"),
    0x85C1: bytes.fromhex("A9 85 48 A9 C9 48 6C 31 00"),
}


class PlayerInputMovementError(ValueError):
    pass


@dataclass(frozen=True)
class ActionState:
    countdown: int
    held_latch: int


@dataclass(frozen=True)
class HorizontalStep:
    probe_x: int
    candidate_x: int
    boundary: str | None


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int
    x: int
    y: int
    width: int
    height: int
    state: int = 0


@dataclass(frozen=True)
class ActionHit:
    objects: tuple[RuntimeObject, ...]
    matched_index: int | None
    destroyed: bool
    sound_effect: bool


def _byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerInputMovementError(f"{name} outside 0-255: {value}")


def _word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerInputMovementError(f"{name} outside 0-65535: {value}")


def active_motion_state(raw_state: int) -> int:
    _byte(raw_state, "motion state")
    return raw_state if raw_state < ACTIVE_MOTION_END else 0


def update_action_state(buttons: int, countdown: int, held_latch: int) -> ActionState:
    for value, name in ((buttons, "buttons"), (countdown, "countdown"), (held_latch, "held latch")):
        _byte(value, name)
    if not buttons & CONTROLLER_B:
        return ActionState(0, 0)
    if held_latch == 0:
        return ActionState(ACTION_DURATION, ACTION_DURATION)
    return ActionState((countdown - 1) & 0xFF if countdown else 0, held_latch)


def select_horizontal_direction(buttons: int) -> int:
    _byte(buttons, "buttons")
    horizontal = buttons & CONTROLLER_HORIZONTAL
    if horizontal in (0, CONTROLLER_HORIZONTAL):
        return DIRECTION_NONE
    return DIRECTION_LEFT if horizontal == CONTROLLER_LEFT else DIRECTION_RIGHT


def horizontal_step(direction: int, player_x: int) -> HorizontalStep:
    _byte(direction, "direction")
    _word(player_x, "player X")
    if direction == DIRECTION_RIGHT:
        probe_x = (player_x + RIGHT_COLLISION_OFFSET) & 0xFFFF
        candidate_x = (player_x + HORIZONTAL_STEP) & 0xFFFF
    elif direction == DIRECTION_LEFT:
        probe_x = (player_x - HORIZONTAL_STEP) & 0xFFFF
        candidate_x = probe_x
    else:
        raise PlayerInputMovementError(f"unsupported direction: {direction}")
    high = candidate_x >> 8
    if high not in (0, 1):
        boundary = "left"
    elif high == 1 and (candidate_x & 0xFF) >= (ROOM_RIGHT_BOUNDARY & 0xFF):
        boundary = "right"
    else:
        boundary = None
    return HorizontalStep(probe_x, candidate_x, boundary)


def action_probe(direction: int, player_x: int, player_y: int) -> tuple[int, int] | None:
    _byte(direction, "direction")
    _word(player_x, "player X")
    _byte(player_y, "player Y")
    if direction == DIRECTION_RIGHT:
        probe_x = (player_x + RIGHT_ACTION_OFFSET) & 0xFFFF
        if probe_x >= ACTION_RIGHT_BOUNDARY:
            return None
    elif direction == DIRECTION_LEFT:
        probe_x = (player_x - LEFT_ACTION_OFFSET) & 0xFFFF
        if probe_x & 0x8000:
            return None
    else:
        return None
    return (probe_x, (player_y - ACTION_Y_OFFSET) & 0xFF)


def _action_overlaps(probe_x: int, probe_y: int, obj: RuntimeObject) -> bool:
    if not ACTIVE_OBJECT_TYPE_FIRST <= obj.runtime_type < ACTIVE_OBJECT_TYPE_END:
        return False
    if probe_y < obj.y or probe_y - obj.y >= obj.height:
        return False
    if probe_x < obj.x or probe_x - obj.x >= obj.width:
        return False
    return True


def apply_action_hit(
    objects: tuple[RuntimeObject, ...], probe_x: int, probe_y: int
) -> ActionHit:
    _word(probe_x, "probe X")
    _byte(probe_y, "probe Y")
    if len(objects) != 24:
        raise PlayerInputMovementError("action scan requires 24 runtime objects")
    for index, obj in enumerate(objects):
        for value, name in (
            (obj.runtime_type, "runtime type"),
            (obj.y, "object Y"),
            (obj.width, "object width"),
            (obj.height, "object height"),
            (obj.state, "object state"),
        ):
            _byte(value, name)
        _word(obj.x, "object X")
        if not _action_overlaps(probe_x, probe_y, obj):
            continue
        if obj.runtime_type not in ATTACKABLE_TYPES:
            return ActionHit(objects, index, False, False)
        changed = list(objects)
        changed[index] = replace(obj, runtime_type=DESTROYED_OBJECT_TYPE, state=0)
        return ActionHit(tuple(changed), index, True, True)
    return ActionHit(objects, None, False, False)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerInputMovementError("expected an iNES image")
    trainer = 512 if image[6] & 0x04 else 0
    size = image[4] * 16_384
    start = 16 + trainer
    if size != PRG_SIZE or start + size > len(image):
        raise PlayerInputMovementError("expected a complete 32 KiB PRG region")
    return image[start:start + size]


def _cpu_slice(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start:start + size]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    routine = _cpu_slice(prg, ROUTINE_START, ROUTINE_END - ROUTINE_START)
    if hashlib.sha256(routine).hexdigest() != ROUTINE_SHA256:
        raise PlayerInputMovementError("player input/movement bytes changed")
    caller, expected = ENTRY_CALLER
    if _cpu_slice(prg, caller, len(expected)) != expected:
        raise PlayerInputMovementError("main-loop player-update call changed")
    for address, sequence in SYNTHETIC_CALLS.items():
        if _cpu_slice(prg, address, len(sequence)) != sequence:
            raise PlayerInputMovementError(f"synthetic call at ${address:04X} changed")
    return {
        "range": [ROUTINE_START, ROUTINE_END - 1],
        "bytes": len(routine),
        "main_loop_caller": caller,
        "synthetic_collision_calls": list(SYNTHETIC_CALLS),
    }


def validate_model_contract() -> dict[str, int]:
    action_cases = 0
    for buttons in range(0x100):
        for countdown in range(0x100):
            for held in (0, 1, 0xFF):
                state = update_action_state(buttons, countdown, held)
                if not buttons & CONTROLLER_B and state != ActionState(0, 0):
                    raise PlayerInputMovementError("released action did not clear")
                action_cases += 1
    for buttons in range(0x100):
        expected = {0: 0, 0x40: 0xFF, 0x80: 0x7F, 0xC0: 0}[buttons & 0xC0]
        if select_horizontal_direction(buttons) != expected:
            raise PlayerInputMovementError("horizontal direction mismatch")
    movement_cases = 0
    action_probe_cases = 0
    for direction in (DIRECTION_LEFT, DIRECTION_RIGHT):
        for player_x in range(0x10000):
            horizontal_step(direction, player_x)
            action_probe(direction, player_x, 0x48)
            movement_cases += 1
            action_probe_cases += 1
    blank = RuntimeObject(0, 0, 0, 1, 1)
    type_cases = 0
    for runtime_type in range(0x100):
        target = RuntimeObject(runtime_type, 100, 40, 16, 16, 0x55)
        result = apply_action_hit((target,) + (blank,) * 23, 100, 40)
        if result.destroyed != (runtime_type in ATTACKABLE_TYPES):
            raise PlayerInputMovementError("attackable type classification mismatch")
        type_cases += 1
    return {
        "action_cases": action_cases,
        "direction_cases": 0x100,
        "movement_cases": movement_cases,
        "action_probe_cases": action_probe_cases,
        "runtime_type_cases": type_cases,
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
            "model": validate_model_contract(),
            "action_example": asdict(update_action_state(CONTROLLER_B, 0, 0)),
        }
    except (OSError, PlayerInputMovementError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 940 player-update bytes, three synthetic collision "
            f"calls, {report['model']['action_cases']:,} action states, and "
            f"{report['model']['movement_cases']:,} horizontal positions"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
