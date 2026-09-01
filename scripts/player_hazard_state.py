#!/usr/bin/env python3
"""Model player protection countdowns and hazard-cell contact at $A835-$A8A8."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA835
ROOM_COLUMNS = 20
ROOM_ROWS = 20
ROOM_CELL_COUNT = ROOM_COLUMNS * ROOM_ROWS
PROTECTION_TICK_MASK = 0x1F
HAZARD_PROBE_X_OFFSET = 7
HAZARD_PROBE_Y_OFFSET = 8
HAZARD_PROBE_TOP = 0x10
HAZARD_PROBE_BOTTOM = 0xB0
HAZARD_PROBE_ROOM_Y_OFFSET = 0x10
ROOM_PIXEL_WIDTH = 0x140
HAZARD_CELLS = (0x16, 0x62, 0x63)
CONTACT_INACTIVE = 0x00
CONTACT_ACTIVE = 0xFF
SELECT_ROOM_AUDIO = "SelectRoomAudio"
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A5 0E F0 0E AD 6B 07 29 1F D0 07 C6 0E D0 03 20 8A A3 "
    "A5 0D F0 0E AD 6B 07 29 1F D0 07 C6 0D D0 03 20 8A A3 "
    "AD 7C 07 A5 3A 18 69 08 A8 C0 10 90 18 C0 B0 B0 14 "
    "A5 38 18 69 07 AA A5 39 69 00 F0 0D C9 01 D0 04 E0 40 90 05 "
    "A9 00 4C 91 A8 48 98 38 E9 10 A8 68 20 CB 8E A4 29 B1 2B "
    "A2 00 C9 16 D0 02 A2 FF C9 62 D0 02 A2 FF C9 63 D0 02 A2 FF "
    "8E 7C 07 60"
)


class PlayerHazardStateError(ValueError):
    pass


@dataclass(frozen=True)
class CountdownResult:
    value: int
    restart_room_audio: bool


@dataclass(frozen=True)
class HazardContactResult:
    probe_x: int
    probe_y: int
    sampled: bool
    cell_index: int | None
    cell: int
    contact_flag: int


@dataclass(frozen=True)
class PlayerHazardFrameResult:
    hazard_protection_countdown: int
    invulnerability_countdown: int
    contact: HazardContactResult
    calls: tuple[str, ...]


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerHazardStateError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerHazardStateError(f"{name} outside 0-65535: {value}")


def tick_protection_countdown(countdown: int, room_frame: int) -> CountdownResult:
    _validate_byte(countdown, "protection countdown")
    _validate_byte(room_frame, "room frame")
    if countdown == 0 or room_frame & PROTECTION_TICK_MASK:
        return CountdownResult(countdown, False)
    value = countdown - 1
    return CountdownResult(value, value == 0)


def classify_hazard_cell(cell: int) -> int:
    _validate_byte(cell, "room cell")
    return CONTACT_ACTIVE if cell in HAZARD_CELLS else CONTACT_INACTIVE


def sample_player_hazard_contact(
    room_cells: bytes,
    *,
    player_x: int,
    player_y: int,
    previous_contact_flag: int,
) -> HazardContactResult:
    if len(room_cells) != ROOM_CELL_COUNT:
        raise PlayerHazardStateError(
            f"room grid must contain {ROOM_CELL_COUNT} cells"
        )
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    _validate_byte(previous_contact_flag, "previous hazard contact flag")
    probe_x = (player_x + HAZARD_PROBE_X_OFFSET) & 0xFFFF
    probe_y = (player_y + HAZARD_PROBE_Y_OFFSET) & 0xFF
    if (
        probe_y < HAZARD_PROBE_TOP
        or probe_y >= HAZARD_PROBE_BOTTOM
        or probe_x >= ROOM_PIXEL_WIDTH
    ):
        return HazardContactResult(
            probe_x, probe_y, False, None, 0, CONTACT_INACTIVE
        )
    room_y = probe_y - HAZARD_PROBE_ROOM_Y_OFFSET
    row = room_y >> 3
    column = probe_x >> 4
    cell_index = row * ROOM_COLUMNS + column
    cell = room_cells[cell_index]
    return HazardContactResult(
        probe_x,
        probe_y,
        True,
        cell_index,
        cell,
        classify_hazard_cell(cell),
    )


def update_player_hazard_state(
    room_cells: bytes,
    *,
    hazard_protection_countdown: int,
    invulnerability_countdown: int,
    room_frame: int,
    player_x: int,
    player_y: int,
    previous_contact_flag: int,
) -> PlayerHazardFrameResult:
    invulnerability = tick_protection_countdown(
        invulnerability_countdown, room_frame
    )
    hazard_protection = tick_protection_countdown(
        hazard_protection_countdown, room_frame
    )
    calls: list[str] = []
    if invulnerability.restart_room_audio:
        calls.append(SELECT_ROOM_AUDIO)
    if hazard_protection.restart_room_audio:
        calls.append(SELECT_ROOM_AUDIO)
    return PlayerHazardFrameResult(
        hazard_protection_countdown=hazard_protection.value,
        invulnerability_countdown=invulnerability.value,
        contact=sample_player_hazard_contact(
            room_cells,
            player_x=player_x,
            player_y=player_y,
            previous_contact_flag=previous_contact_flag,
        ),
        calls=tuple(calls),
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerHazardStateError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerHazardStateError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    observed = prg[start:start + len(EXPECTED_ROUTINE_BYTES)]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise PlayerHazardStateError("player hazard-state routine bytes changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_CPU + len(observed) - 1],
        "routine_bytes": len(observed),
        "hazard_cells": list(HAZARD_CELLS),
    }


def validate_exhaustive_contract() -> dict[str, object]:
    countdown_cases = 0
    for countdown in range(0x100):
        for room_frame in range(0x100):
            result = tick_protection_countdown(countdown, room_frame)
            should_tick = countdown != 0 and room_frame & PROTECTION_TICK_MASK == 0
            expected = countdown - 1 if should_tick else countdown
            if result.value != expected or result.restart_room_audio != (
                should_tick and expected == 0
            ):
                raise PlayerHazardStateError("protection countdown mismatch")
            countdown_cases += 1
    for cell in range(0x100):
        expected = CONTACT_ACTIVE if cell in HAZARD_CELLS else CONTACT_INACTIVE
        if classify_hazard_cell(cell) != expected:
            raise PlayerHazardStateError("hazard-cell classification mismatch")
    empty_room = bytes(ROOM_CELL_COUNT)
    x_cases = 0
    for player_x in range(0x10000):
        result = sample_player_hazard_contact(
            empty_room,
            player_x=player_x,
            player_y=8,
            previous_contact_flag=0xA5,
        )
        expected = ((player_x + HAZARD_PROBE_X_OFFSET) & 0xFFFF) < ROOM_PIXEL_WIDTH
        if result.sampled != expected:
            raise PlayerHazardStateError("hazard-probe X boundary mismatch")
        x_cases += 1
    for player_y in range(0x100):
        result = sample_player_hazard_contact(
            empty_room,
            player_x=0,
            player_y=player_y,
            previous_contact_flag=0,
        )
        probe_y = (player_y + HAZARD_PROBE_Y_OFFSET) & 0xFF
        expected = HAZARD_PROBE_TOP <= probe_y < HAZARD_PROBE_BOTTOM
        if result.sampled != expected:
            raise PlayerHazardStateError("hazard-probe Y boundary mismatch")
    covered_indexes: list[int] = []
    for row in range(ROOM_ROWS):
        for column in range(ROOM_COLUMNS):
            room = bytearray(ROOM_CELL_COUNT)
            expected_index = row * ROOM_COLUMNS + column
            room[expected_index] = HAZARD_CELLS[expected_index % len(HAZARD_CELLS)]
            kwargs = {
                "player_x": column * 16,
                "player_y": row * 8 + 8,
            }
            first = sample_player_hazard_contact(
                bytes(room), previous_contact_flag=0, **kwargs
            )
            second = sample_player_hazard_contact(
                bytes(room), previous_contact_flag=0xFF, **kwargs
            )
            if first != second or first.cell_index != expected_index:
                raise PlayerHazardStateError("hazard room-cell coverage mismatch")
            if first.contact_flag != CONTACT_ACTIVE:
                raise PlayerHazardStateError("hazard room-cell contact mismatch")
            covered_indexes.append(expected_index)
    dual_expiry = update_player_hazard_state(
        empty_room,
        hazard_protection_countdown=1,
        invulnerability_countdown=1,
        room_frame=0,
        player_x=0,
        player_y=8,
        previous_contact_flag=0xFF,
    )
    if dual_expiry.calls != (SELECT_ROOM_AUDIO, SELECT_ROOM_AUDIO):
        raise PlayerHazardStateError("protection audio restart order mismatch")
    return {
        "countdown_cases": countdown_cases,
        "cell_values": 0x100,
        "player_x_cases": x_cases,
        "player_y_cases": 0x100,
        "room_cell_indexes": len(set(covered_indexes)),
        "dual_expiry": asdict(dual_expiry),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_rom_contract(extract_prg(Path(args.image).read_bytes()))
        document["exhaustive"] = validate_exhaustive_contract()
    except (OSError, PlayerHazardStateError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated protection countdowns, all 400 hazard probes, "
            "and complete X/Y/cell domains"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
