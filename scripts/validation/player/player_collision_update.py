#!/usr/bin/env python3
"""Model the frame-level player collision orchestration at $9386-$93F5."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x9386
ROUTINE_END = 0x93F6
EXPECTED_CALL_SITE = 0x82A5
SAMPLE_CALL = "SamplePlayerCollisionAtScreenPixel"
DISPATCH_CALL = "DispatchPlayerCollisionSample"
ADVANCE_TRANSITION_CALL = "AdvancePlayerTransitionCountdown"
START_DEATH_CALL = "StartPlayerDeathTransition"
PROBE_OFFSETS = ((0, 0), (15, 0), (0, 15), (15, 15), (7, 7), (7, 0), (15, 0))
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "AD 72 07 F0 03 4C F6 93 A4 3A A6 38 A5 39 20 D3 8D 20 77 94 "
    "A4 3A 20 DF 94 20 D3 8D 20 77 94 A5 3A 18 69 0F A8 A6 38 "
    "A5 39 20 D3 8D 20 77 94 A5 3A 18 69 0F A8 20 DF 94 20 D3 "
    "8D 20 77 94 A5 3A 18 69 07 A8 20 DB 94 20 D3 8D 20 77 94 "
    "A4 3A 20 DB 94 20 D3 8D 20 77 94 A4 3A 20 DF 94 20 D3 8D "
    "20 77 94 AD 7C 07 F0 07 A5 0D D0 03 4C B0 8D 60"
)


class PlayerCollisionUpdateError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionProbe:
    x: int
    y: int


@dataclass(frozen=True)
class PlayerCollisionUpdatePlan:
    probes: tuple[CollisionProbe, ...]
    calls: tuple[str, ...]
    starts_death_transition: bool


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerCollisionUpdateError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerCollisionUpdateError(f"{name} outside 0-65535: {value}")


def build_collision_probes(player_x: int, player_y: int) -> tuple[CollisionProbe, ...]:
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    return tuple(
        CollisionProbe((player_x + x_offset) & 0xFFFF, (player_y + y_offset) & 0xFF)
        for x_offset, y_offset in PROBE_OFFSETS
    )


def plan_player_collision_update(
    *,
    transition_countdown: int,
    player_x: int,
    player_y: int,
    hazard_cell_contact: int,
    hazard_protection_countdown: int,
) -> PlayerCollisionUpdatePlan:
    _validate_byte(transition_countdown, "transition countdown")
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    _validate_byte(hazard_cell_contact, "hazard-cell contact")
    _validate_byte(hazard_protection_countdown, "hazard protection countdown")
    if transition_countdown:
        return PlayerCollisionUpdatePlan((), (ADVANCE_TRANSITION_CALL,), False)
    probes = build_collision_probes(player_x, player_y)
    calls = tuple(call for _probe in probes for call in (SAMPLE_CALL, DISPATCH_CALL))
    starts_death = hazard_cell_contact != 0 and hazard_protection_countdown == 0
    if starts_death:
        calls += (START_DEATH_CALL,)
    return PlayerCollisionUpdatePlan(probes, calls, starts_death)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerCollisionUpdateError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerCollisionUpdateError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise PlayerCollisionUpdateError(f"truncated PRG range at ${address:04X}")
    return result


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if _read_cpu_range(prg, ROUTINE_CPU, len(EXPECTED_ROUTINE_BYTES)) != EXPECTED_ROUTINE_BYTES:
        raise PlayerCollisionUpdateError("player collision-update bytes changed")
    call_opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    call_sites = tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - 2)
        if prg[offset:offset + 3] == call_opcode
    )
    if call_sites != (EXPECTED_CALL_SITE,):
        raise PlayerCollisionUpdateError("player collision-update call site changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(call_sites),
        "probe_offsets": [list(offsets) for offsets in PROBE_OFFSETS],
    }


def validate_exhaustive_contract() -> dict[str, int]:
    for player_x in range(0x10000):
        probes = build_collision_probes(player_x, 0)
        for probe, (x_offset, _y_offset) in zip(probes, PROBE_OFFSETS):
            if probe.x != (player_x + x_offset) & 0xFFFF:
                raise PlayerCollisionUpdateError("player collision X wrap mismatch")
    for player_y in range(0x100):
        probes = build_collision_probes(0, player_y)
        for probe, (_x_offset, y_offset) in zip(probes, PROBE_OFFSETS):
            if probe.y != (player_y + y_offset) & 0xFF:
                raise PlayerCollisionUpdateError("player collision Y wrap mismatch")
    state_cases = 0
    for transition in range(0x100):
        for hazard_contact in range(2):
            for protection in range(2):
                result = plan_player_collision_update(
                    transition_countdown=transition,
                    player_x=0,
                    player_y=0,
                    hazard_cell_contact=hazard_contact,
                    hazard_protection_countdown=protection,
                )
                expected_death = transition == 0 and hazard_contact != 0 and protection == 0
                if result.starts_death_transition != expected_death:
                    raise PlayerCollisionUpdateError("player collision state mismatch")
                state_cases += 1
    return {"player_x_cases": 0x10000, "player_y_cases": 0x100, "state_cases": state_cases}


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
            plan_player_collision_update(
                transition_countdown=0,
                player_x=0x0138,
                player_y=0x98,
                hazard_cell_contact=0xFF,
                hazard_protection_countdown=0,
            )
        )
    except (OSError, PlayerCollisionUpdateError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated one frame call, seven ordered collision probes, "
            "65,536 X values, and every Y/transition boundary"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
