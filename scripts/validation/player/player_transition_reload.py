#!/usr/bin/env python3
"""Model player transition countdown and room reload at $93F6-$9476."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x93F6
ROUTINE_END = 0x9477
PROTECTION_BONUS = 0x0A
SCREEN_STATE_PROTECTION_BASE = 0x28
UNPAUSED_MODE = 0xFF
GAME_OVER_CALL = "RunGameOverSequence"
RELOAD_CALLS = (
    "SaveCurrentRoomObjectState",
    "DecodeRoom",
    "LoadRoomObjects",
    "ApplyRoomPersistentState",
    "ResetRoomRuntimeState",
    "ResetNmiTaskRequests",
    "ClearRoomNametablesAndSprites",
    "InitializeRoomStatusDisplay",
    "BuildRoomAttributeTables",
    "UploadRoomAttributeTables",
    "UpdateHorizontalScroll",
    "WaitForVblankAndEnableRendering",
    "EnableNmi",
)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "CE 72 07 F0 01 60 A5 10 85 38 A5 11 85 39 A5 12 85 3A A5 14 "
    "0D CD 07 F0 14 A5 14 C5 0D B0 02 A5 0D AC CD 07 F0 02 A9 28 "
    "18 69 0A 85 0D A9 00 8D 72 07 A5 13 D0 08 AD CC 07 F0 03 "
    "4C 31 FE 20 58 87 A6 37 CA 20 30 E8 20 E9 EB A2 02 BD 13 07 "
    "95 16 CA 10 F8 A2 04 BD 16 07 95 19 CA 10 F8 20 B7 EC 20 AC "
    "A3 20 78 95 20 4C B6 20 C9 B6 20 17 E9 20 BD B7 20 3D C4 "
    "A9 FF 8D C4 07 20 6A 81 4C 5E 81"
)


class PlayerTransitionReloadError(ValueError):
    pass


@dataclass(frozen=True)
class PlayerTransitionReloadResult:
    transition_countdown: int
    completed: bool
    player_x: int
    player_y: int
    hazard_protection_countdown: int
    decoded_room_index: int | None
    reload_object_state: bytes
    reload_mutable_state: bytes
    pause_mode: int
    calls: tuple[str, ...]


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerTransitionReloadError(f"{name} outside 0-255: {value}")


def extend_hazard_protection(
    current: int, transition_mirror: int, screen_state: int
) -> int:
    _validate_byte(current, "hazard protection countdown")
    _validate_byte(transition_mirror, "transition protection mirror")
    _validate_byte(screen_state, "transition screen state")
    if transition_mirror == 0 and screen_state == 0:
        return current
    base = max(transition_mirror, current)
    if screen_state:
        base = SCREEN_STATE_PROTECTION_BASE
    return (base + PROTECTION_BONUS) & 0xFF


def advance_player_transition(
    *,
    transition_countdown: int,
    current_player_x: int,
    current_player_y: int,
    saved_player_x: int,
    saved_player_y: int,
    hazard_protection_countdown: int,
    transition_protection_mirror: int,
    transition_screen_state: int,
    reserve_lives: int,
    game_over_active: int,
    current_room: int,
    current_object_state: bytes,
    current_mutable_state: bytes,
    pause_mode: int,
) -> PlayerTransitionReloadResult:
    for value, name in (
        (transition_countdown, "transition countdown"),
        (current_player_y, "current player Y"),
        (saved_player_y, "saved player Y"),
        (reserve_lives, "reserve lives"),
        (game_over_active, "game-over state"),
        (pause_mode, "pause mode"),
    ):
        _validate_byte(value, name)
    for value, name in (
        (current_player_x, "current player X"),
        (saved_player_x, "saved player X"),
    ):
        if not 0 <= value <= 0xFFFF:
            raise PlayerTransitionReloadError(f"{name} outside 0-65535: {value}")
    if not 1 <= current_room <= 100:
        raise PlayerTransitionReloadError(f"room outside 1-100: {current_room}")
    if len(current_object_state) != 3 or len(current_mutable_state) != 5:
        raise PlayerTransitionReloadError("expected three object and five mutable-state bytes")
    next_countdown = (transition_countdown - 1) & 0xFF
    if next_countdown:
        return PlayerTransitionReloadResult(
            next_countdown,
            False,
            current_player_x,
            current_player_y,
            hazard_protection_countdown,
            None,
            b"",
            b"",
            pause_mode,
            (),
        )
    protection = extend_hazard_protection(
        hazard_protection_countdown,
        transition_protection_mirror,
        transition_screen_state,
    )
    if reserve_lives == 0 and game_over_active != 0:
        return PlayerTransitionReloadResult(
            0,
            True,
            saved_player_x,
            saved_player_y,
            protection,
            None,
            b"",
            b"",
            pause_mode,
            (GAME_OVER_CALL,),
        )
    return PlayerTransitionReloadResult(
        0,
        True,
        saved_player_x,
        saved_player_y,
        protection,
        current_room - 1,
        bytes(current_object_state),
        bytes(current_mutable_state),
        UNPAUSED_MODE,
        RELOAD_CALLS,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerTransitionReloadError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise PlayerTransitionReloadError("expected a complete 32 KiB PRG region")
    return image[start:end]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    observed = prg[start:start + len(EXPECTED_ROUTINE_BYTES)]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise PlayerTransitionReloadError("player transition-reload bytes changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(observed),
        "reload_calls": list(RELOAD_CALLS),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    countdown_cases = 0
    for countdown in range(0x100):
        result = advance_player_transition(
            transition_countdown=countdown,
            current_player_x=0x1234,
            current_player_y=0x56,
            saved_player_x=0x0100,
            saved_player_y=0x98,
            hazard_protection_countdown=0,
            transition_protection_mirror=0,
            transition_screen_state=0,
            reserve_lives=1,
            game_over_active=0,
            current_room=1,
            current_object_state=b"\x00\x00\x00",
            current_mutable_state=b"\x00\x00\x00\x00\x00",
            pause_mode=0,
        )
        if result.completed != (countdown == 1):
            raise PlayerTransitionReloadError("transition countdown completion mismatch")
        countdown_cases += 1
    protection_cases = 0
    for current in range(0x100):
        for mirror in range(0x100):
            for screen_state in (0, 1):
                result = extend_hazard_protection(current, mirror, screen_state)
                if mirror == 0 and screen_state == 0:
                    expected = current
                elif screen_state:
                    expected = 0x32
                else:
                    expected = (max(current, mirror) + PROTECTION_BONUS) & 0xFF
                if result != expected:
                    raise PlayerTransitionReloadError("hazard protection extension mismatch")
                protection_cases += 1
    return {"countdown_cases": countdown_cases, "protection_cases": protection_cases}


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
            advance_player_transition(
                transition_countdown=1,
                current_player_x=0,
                current_player_y=0,
                saved_player_x=0x0130,
                saved_player_y=0x98,
                hazard_protection_countdown=5,
                transition_protection_mirror=10,
                transition_screen_state=0,
                reserve_lives=2,
                game_over_active=0,
                current_room=71,
                current_object_state=b"\x01\x02\x03",
                current_mutable_state=b"\x04\x05\x06\x07\x08",
                pause_mode=0,
            )
        )
    except (OSError, PlayerTransitionReloadError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 129 transition/reload bytes, every countdown value, "
            "131,072 protection cases, and the complete reload call order"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
