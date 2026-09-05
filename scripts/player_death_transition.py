#!/usr/bin/env python3
"""Model the animated hazard and player death handlers at $8DAB-$8DD2."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

try:
    from .player_collision_dispatch import (
        ROOM_HANDLER_COUNT,
        ROOM_TABLE_CPU,
        RUNTIME_HANDLER_COUNT,
        RUNTIME_TABLE_CPU,
        decode_pointer_table,
    )
except ImportError:
    from player_collision_dispatch import (
        ROOM_HANDLER_COUNT,
        ROOM_TABLE_CPU,
        RUNTIME_HANDLER_COUNT,
        RUNTIME_TABLE_CPU,
        decode_pointer_table,
    )


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ANIMATED_HAZARD_ROUTINE_CPU = 0x8DAB
ROUTINE_CPU = 0x8DB0
ROUTINE_END = 0x8DD3
TRANSITION_FRAMES = 0x80
GAME_OVER_ACTIVE = 0xFF
AUDIO_TRACK_SET = 2
DIRECT_JUMP_CPU = 0x93F2
ANIMATED_ROOM_HANDLER_TYPES = (0x45, 0x46, 0x47, 0x48)
ROOM_HANDLER_TYPES = (
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x0E, 0x0F, 0x10, 0x11,
    0x2F, 0x30, 0x31, 0x32, 0x33, 0x35, 0x36, 0x37, 0x38, 0x39,
    0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40, 0x56, 0x57, 0x58,
    0x59, 0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61,
)
RUNTIME_HANDLER_TYPES = (
    0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C,
    0x8D, 0x8E, 0x8F, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6,
)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A5 0E 0D 72 07 F0 01 60 A9 80 8D 72 07 A9 00 8D 79 07 "
    "A5 13 F0 05 C6 13 4C D0 8D A9 FF 8D CC 07 4C 7D B8"
)
EXPECTED_ANIMATED_HAZARD_BYTES = bytes.fromhex("A5 40 10 01 60")
EXPECTED_DIRECT_JUMP = bytes.fromhex("4C B0 8D")


class PlayerDeathTransitionError(ValueError):
    pass


@dataclass(frozen=True)
class PlayerDeathTransitionResult:
    started: bool
    transition_countdown: int
    action_countdown: int
    reserve_lives: int
    game_over_active: int
    audio_track_set: int | None


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerDeathTransitionError(f"{name} outside 0-255: {value}")


def start_player_death_transition(
    *,
    invulnerability_countdown: int,
    transition_countdown: int,
    action_countdown: int,
    reserve_lives: int,
    game_over_active: int,
) -> PlayerDeathTransitionResult:
    for value, name in (
        (invulnerability_countdown, "invulnerability countdown"),
        (transition_countdown, "transition countdown"),
        (action_countdown, "action countdown"),
        (reserve_lives, "reserve lives"),
        (game_over_active, "game-over state"),
    ):
        _validate_byte(value, name)
    if invulnerability_countdown | transition_countdown:
        return PlayerDeathTransitionResult(
            False,
            transition_countdown,
            action_countdown,
            reserve_lives,
            game_over_active,
            None,
        )
    if reserve_lives:
        reserve_lives -= 1
    else:
        game_over_active = GAME_OVER_ACTIVE
    return PlayerDeathTransitionResult(
        True,
        TRANSITION_FRAMES,
        0,
        reserve_lives,
        game_over_active,
        AUDIO_TRACK_SET,
    )


def handle_animated_player_hazard(
    *,
    animation_counter: int,
    invulnerability_countdown: int,
    transition_countdown: int,
    action_countdown: int,
    reserve_lives: int,
    game_over_active: int,
) -> PlayerDeathTransitionResult:
    _validate_byte(animation_counter, "animation counter")
    if animation_counter & 0x80:
        for value, name in (
            (invulnerability_countdown, "invulnerability countdown"),
            (transition_countdown, "transition countdown"),
            (action_countdown, "action countdown"),
            (reserve_lives, "reserve lives"),
            (game_over_active, "game-over state"),
        ):
            _validate_byte(value, name)
        return PlayerDeathTransitionResult(
            False,
            transition_countdown,
            action_countdown,
            reserve_lives,
            game_over_active,
            None,
        )
    return start_player_death_transition(
        invulnerability_countdown=invulnerability_countdown,
        transition_countdown=transition_countdown,
        action_countdown=action_countdown,
        reserve_lives=reserve_lives,
        game_over_active=game_over_active,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerDeathTransitionError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerDeathTransitionError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise PlayerDeathTransitionError(f"truncated PRG range at ${address:04X}")
    return result


def _handler_types(
    prg: bytes, table_cpu: int, count: int, first_type: int, target: int = ROUTINE_CPU
) -> tuple[int, ...]:
    table = decode_pointer_table(_read_cpu_range(prg, table_cpu, count * 2))
    return tuple(
        first_type + index
        for index, handler in enumerate(table)
        if handler == target
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if (
        _read_cpu_range(
            prg, ANIMATED_HAZARD_ROUTINE_CPU, len(EXPECTED_ANIMATED_HAZARD_BYTES)
        )
        != EXPECTED_ANIMATED_HAZARD_BYTES
    ):
        raise PlayerDeathTransitionError("animated player-hazard bytes changed")
    if _read_cpu_range(prg, ROUTINE_CPU, len(EXPECTED_ROUTINE_BYTES)) != EXPECTED_ROUTINE_BYTES:
        raise PlayerDeathTransitionError("player death-transition bytes changed")
    if _read_cpu_range(prg, DIRECT_JUMP_CPU, 3) != EXPECTED_DIRECT_JUMP:
        raise PlayerDeathTransitionError("hazard-contact jump target changed")
    room_types = _handler_types(prg, ROOM_TABLE_CPU, ROOM_HANDLER_COUNT, 0)
    runtime_types = _handler_types(prg, RUNTIME_TABLE_CPU, RUNTIME_HANDLER_COUNT, 0x80)
    animated_types = _handler_types(
        prg,
        ROOM_TABLE_CPU,
        ROOM_HANDLER_COUNT,
        0,
        ANIMATED_HAZARD_ROUTINE_CPU,
    )
    if animated_types != ANIMATED_ROOM_HANDLER_TYPES:
        raise PlayerDeathTransitionError("animated room-hazard references changed")
    if room_types != ROOM_HANDLER_TYPES:
        raise PlayerDeathTransitionError("room-cell death-handler references changed")
    if runtime_types != RUNTIME_HANDLER_TYPES:
        raise PlayerDeathTransitionError("runtime death-handler references changed")
    return {
        "routine_range": [ANIMATED_HAZARD_ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ANIMATED_HAZARD_BYTES) + len(EXPECTED_ROUTINE_BYTES),
        "direct_jump": DIRECT_JUMP_CPU,
        "animated_room_handler_types": list(animated_types),
        "room_handler_types": list(room_types),
        "runtime_handler_types": list(runtime_types),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    guard_cases = 0
    for invulnerability in range(0x100):
        for transition in range(0x100):
            result = start_player_death_transition(
                invulnerability_countdown=invulnerability,
                transition_countdown=transition,
                action_countdown=0x5A,
                reserve_lives=3,
                game_over_active=0xA5,
            )
            expected_started = invulnerability == 0 and transition == 0
            if result.started != expected_started:
                raise PlayerDeathTransitionError("death-transition guard mismatch")
            if not expected_started and result != PlayerDeathTransitionResult(
                False, transition, 0x5A, 3, 0xA5, None
            ):
                raise PlayerDeathTransitionError("blocked death mutated state")
            guard_cases += 1
    for lives in range(0x100):
        result = start_player_death_transition(
            invulnerability_countdown=0,
            transition_countdown=0,
            action_countdown=0xFF,
            reserve_lives=lives,
            game_over_active=0,
        )
        expected_lives = lives - 1 if lives else 0
        expected_game_over = 0 if lives else GAME_OVER_ACTIVE
        if (
            result.reserve_lives != expected_lives
            or result.game_over_active != expected_game_over
            or result.transition_countdown != TRANSITION_FRAMES
            or result.action_countdown != 0
            or result.audio_track_set != AUDIO_TRACK_SET
        ):
            raise PlayerDeathTransitionError("reserve-life branch mismatch")
    animation_cases = 0
    for animation_counter in range(0x100):
        result = handle_animated_player_hazard(
            animation_counter=animation_counter,
            invulnerability_countdown=0,
            transition_countdown=0,
            action_countdown=7,
            reserve_lives=3,
            game_over_active=0,
        )
        if result.started != (animation_counter < 0x80):
            raise PlayerDeathTransitionError("animated player-hazard phase mismatch")
        animation_cases += 1
    return {
        "guard_cases": guard_cases,
        "reserve_life_cases": 0x100,
        "animation_cases": animation_cases,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
        report["sample"] = asdict(
            start_player_death_transition(
                invulnerability_countdown=0,
                transition_countdown=0,
                action_countdown=7,
                reserve_lives=3,
                game_over_active=0,
            )
        )
    except (OSError, PlayerDeathTransitionError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 40 handler bytes, 61 table references, one direct "
            "jump, 65,536 guard cases, and every animation/life value"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
