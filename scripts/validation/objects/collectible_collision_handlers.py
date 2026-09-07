#!/usr/bin/env python3
"""Model runtime collectible collision handlers at $8C80-$8CF1."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8C80
ROUTINE_END = 0x8CF2
PROXIMITY_CPU = 0xA8A9
ADD_SCORE_CPU = 0x8D04
TRANSFORM_CPU = 0x8C6E
RUNTIME_HANDLER_TABLE_CPU = 0x9334
PROTECTION_DURATION = 0x28
EFFECT_LATCH_SET = 0xFF
COLLECTIBLE_SPECS = {
    0x83: (100, 9),
    0x96: (100, 9),
    0x98: (20, 6),
    0x99: (40, 7),
    0x9A: (80, 8),
    0x9B: (100, 9),
}
EXPECTED_HANDLER_TARGETS = {
    0x83: 0x8C80,
    0x96: 0x8C9E,
    0x98: 0x8CB2,
    0x99: 0x8CC2,
    0x9A: 0x8CD2,
    0x9B: 0x8CE2,
}
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "20 A9 A8 90 01 60 EE CD 07 A9 64 20 04 8D A5 0D D0 03 20 79 "
    "B8 A9 28 85 0D A9 09 4C 6E 8C 20 A9 A8 90 01 60 A9 FF 85 0F "
    "A9 64 20 04 8D A9 09 4C 6E 8C 20 A9 A8 90 01 60 A9 14 20 04 "
    "8D A9 06 4C 6E 8C 20 A9 A8 90 01 60 A9 28 20 04 8D A9 07 4C "
    "6E 8C 20 A9 A8 90 01 60 A9 50 20 04 8D A9 08 4C 6E 8C 20 A9 "
    "A8 90 01 60 A9 64 20 04 8D A9 09 4C 6E 8C"
)


class CollectibleCollisionError(ValueError):
    pass


@dataclass(frozen=True)
class CollectibleResult:
    collected: bool
    score_award: int
    collected_state: int | None
    screen_state: int
    protection_countdown: int
    effect_latch: int
    load_audio_track_set_1: bool


def collect_runtime_object(
    runtime_type: int,
    near_player: bool,
    screen_state: int,
    protection_countdown: int,
    effect_latch: int,
) -> CollectibleResult:
    if runtime_type not in COLLECTIBLE_SPECS:
        raise CollectibleCollisionError(f"unsupported runtime type: {runtime_type:#04x}")
    for value, name in (
        (screen_state, "screen state"),
        (protection_countdown, "protection countdown"),
        (effect_latch, "effect latch"),
    ):
        if not 0 <= value <= 0xFF:
            raise CollectibleCollisionError(f"{name} outside 0-255: {value}")
    if type(near_player) is not bool:
        raise CollectibleCollisionError("near-player result must be boolean")
    if not near_player:
        return CollectibleResult(
            False, 0, None, screen_state, protection_countdown, effect_latch, False
        )
    score, state = COLLECTIBLE_SPECS[runtime_type]
    load_audio = False
    if runtime_type == 0x83:
        screen_state = (screen_state + 1) & 0xFF
        load_audio = protection_countdown == 0
        protection_countdown = PROTECTION_DURATION
    elif runtime_type == 0x96:
        effect_latch = EFFECT_LATCH_SET
    return CollectibleResult(
        True,
        score,
        state,
        screen_state,
        protection_countdown,
        effect_latch,
        load_audio,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise CollectibleCollisionError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise CollectibleCollisionError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def _find_calls(payload: bytes, target: int) -> tuple[int, ...]:
    opcode = bytes((0x20, target & 0xFF, target >> 8))
    return tuple(
        ROUTINE_CPU + offset
        for offset in range(len(payload) - 2)
        if payload[offset:offset + 3] == opcode
    )


def _find_jumps(payload: bytes, target: int) -> tuple[int, ...]:
    opcode = bytes((0x4C, target & 0xFF, target >> 8))
    return tuple(
        ROUTINE_CPU + offset
        for offset in range(len(payload) - 2)
        if payload[offset:offset + 3] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    if prg[start:start + len(EXPECTED_ROUTINE_BYTES)] != EXPECTED_ROUTINE_BYTES:
        raise CollectibleCollisionError("collectible handler bytes changed")
    targets = {
        runtime_type: _read_word(
            prg,
            RUNTIME_HANDLER_TABLE_CPU + (runtime_type & 0x7F) * 2,
        )
        for runtime_type in EXPECTED_HANDLER_TARGETS
    }
    if targets != EXPECTED_HANDLER_TARGETS:
        raise CollectibleCollisionError("runtime collision-handler entries changed")
    proximity_calls = _find_calls(EXPECTED_ROUTINE_BYTES, PROXIMITY_CPU)
    score_calls = _find_calls(EXPECTED_ROUTINE_BYTES, ADD_SCORE_CPU)
    transform_jumps = _find_jumps(EXPECTED_ROUTINE_BYTES, TRANSFORM_CPU)
    if not (len(proximity_calls) == len(score_calls) == len(transform_jumps) == 6):
        raise CollectibleCollisionError("collectible call/jump topology changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "handler_targets": {f"{key:02X}": value for key, value in targets.items()},
        "proximity_calls": list(proximity_calls),
        "score_calls": list(score_calls),
        "transform_jumps": list(transform_jumps),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    cases = 0
    for runtime_type, (score, state) in COLLECTIBLE_SPECS.items():
        for near_player in (False, True):
            for screen_state in range(0x100):
                for protection in range(0x100):
                    result = collect_runtime_object(
                        runtime_type, near_player, screen_state, protection, 0x55
                    )
                    if result.collected != near_player:
                        raise CollectibleCollisionError("proximity guard mismatch")
                    if near_player and (result.score_award, result.collected_state) != (
                        score,
                        state,
                    ):
                        raise CollectibleCollisionError("collectible score/state mismatch")
                    if runtime_type == 0x83 and near_player:
                        expected_audio = protection == 0
                        if (
                            result.screen_state != (screen_state + 1) & 0xFF
                            or result.protection_countdown != PROTECTION_DURATION
                            or result.load_audio_track_set_1 != expected_audio
                        ):
                            raise CollectibleCollisionError("runtime type $83 effect mismatch")
                    if runtime_type == 0x96 and near_player and result.effect_latch != 0xFF:
                        raise CollectibleCollisionError("runtime type $96 effect mismatch")
                    cases += 1
    return {"runtime_types": 6, "state_cases": cases}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["exhaustive"] = validate_exhaustive_contract()
        report["examples"] = {
            f"{runtime_type:02X}": asdict(
                collect_runtime_object(runtime_type, True, 0, 0, 0)
            )
            for runtime_type in COLLECTIBLE_SPECS
        }
    except (OSError, CollectibleCollisionError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated six collectible handlers, exact pointer topology, "
            "and all proximity/effect state cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
