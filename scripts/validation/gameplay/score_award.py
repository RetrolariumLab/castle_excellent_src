#!/usr/bin/env python3
"""Model the score-award flow at $8D04-$8D3C and type-$97 pickup."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
TYPE97_CPU = 0x8CF2
TYPE97_END = 0x8D04
ADD_SCORE_CPU = 0x8D04
ADD_SCORE_END = 0x8D3D
DIVIDE_SCORE_CPU = 0x8D2A
DIVIDE_UNSIGNED_CPU = 0xC47A
PROXIMITY_CPU = 0xA8A9
TRANSFORM_CPU = 0x8C6E
RUNTIME_HANDLER_TABLE_CPU = 0x9334
TYPE97_RUNTIME_TYPE = 0x97
TYPE97_SCORE_AWARD = 100
TYPE97_COLLECTED_STATE = 9
SCORE_LIFE_INTERVAL = 1000
EXPECTED_SCORE_CALLS = (
    0x8C1B, 0x8C2A, 0x8C39, 0x8C48, 0x8C57, 0x8C66, 0x8C8B,
    0x8CAA, 0x8CBA, 0x8CCA, 0x8CDA, 0x8CEA, 0x8CFA,
)
EXPECTED_TYPE97_BYTES = bytes.fromhex(
    "20 A9 A8 90 01 60 A9 64 20 04 8D E6 13 A9 09 4C 6E 8C"
)
EXPECTED_ADD_SCORE_BYTES = bytes.fromhex(
    "48 AD C7 07 D0 1E 20 2A 8D A4 27 68 18 65 0B 85 0B 90 02 "
    "E6 0C 20 2A 8D 98 45 27 F0 06 E6 13 D0 02 C6 13 60 68 60 "
    "A5 0B 85 2B A5 0C 85 2C A9 03 85 2A A9 E8 85 29 4C 7A C4"
)


class ScoreAwardError(ValueError):
    pass


@dataclass(frozen=True)
class ScoreAwardResult:
    score: int
    lives: int
    extra_life_awarded: bool


@dataclass(frozen=True)
class Type97Result:
    collected: bool
    score: int
    lives: int
    collected_state: int | None
    score_life_awarded: bool


def _require_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise ScoreAwardError(f"{name} outside 0-255: {value}")


def add_player_score(
    score: int, lives: int, award: int, demo_active: bool = False
) -> ScoreAwardResult:
    if not 0 <= score <= 0xFFFF:
        raise ScoreAwardError(f"score outside 0-65535: {score}")
    _require_byte(lives, "lives")
    _require_byte(award, "award")
    if type(demo_active) is not bool:
        raise ScoreAwardError("demo-active flag must be boolean")
    if demo_active:
        return ScoreAwardResult(score, lives, False)
    previous_bucket = score // SCORE_LIFE_INTERVAL
    new_score = (score + award) & 0xFFFF
    extra_life = previous_bucket != new_score // SCORE_LIFE_INTERVAL
    if extra_life:
        lives = min(lives + 1, 0xFF)
    return ScoreAwardResult(new_score, lives, extra_life)


def collect_runtime_type97(
    near_player: bool,
    score: int,
    lives: int,
    demo_active: bool = False,
) -> Type97Result:
    if type(near_player) is not bool:
        raise ScoreAwardError("near-player result must be boolean")
    if not near_player:
        _require_byte(lives, "lives")
        if not 0 <= score <= 0xFFFF:
            raise ScoreAwardError(f"score outside 0-65535: {score}")
        return Type97Result(False, score, lives, None, False)
    awarded = add_player_score(score, lives, TYPE97_SCORE_AWARD, demo_active)
    return Type97Result(
        True,
        awarded.score,
        (awarded.lives + 1) & 0xFF,
        TYPE97_COLLECTED_STATE,
        awarded.extra_life_awarded,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise ScoreAwardError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise ScoreAwardError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def _find_absolute(prg: bytes, opcode: int, target: int) -> tuple[int, ...]:
    encoded = bytes((opcode, target & 0xFF, target >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - 2)
        if prg[offset:offset + 3] == encoded
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    type97_start = TYPE97_CPU - PRG_BASE
    score_start = ADD_SCORE_CPU - PRG_BASE
    if prg[type97_start:type97_start + len(EXPECTED_TYPE97_BYTES)] != EXPECTED_TYPE97_BYTES:
        raise ScoreAwardError("runtime type $97 handler bytes changed")
    if prg[score_start:score_start + len(EXPECTED_ADD_SCORE_BYTES)] != EXPECTED_ADD_SCORE_BYTES:
        raise ScoreAwardError("score-award routine bytes changed")
    handler_entry = RUNTIME_HANDLER_TABLE_CPU + (TYPE97_RUNTIME_TYPE & 0x7F) * 2
    if _read_word(prg, handler_entry) != TYPE97_CPU:
        raise ScoreAwardError("runtime type $97 pointer changed")
    if _find_absolute(prg, 0x20, ADD_SCORE_CPU) != EXPECTED_SCORE_CALLS:
        raise ScoreAwardError("score-award call sites changed")
    if _find_absolute(EXPECTED_ADD_SCORE_BYTES, 0x20, DIVIDE_SCORE_CPU) != (0x8006, 0x8015):
        raise ScoreAwardError("score quotient helper calls changed")
    if EXPECTED_TYPE97_BYTES[:3] != bytes((0x20, PROXIMITY_CPU & 0xFF, PROXIMITY_CPU >> 8)):
        raise ScoreAwardError("type $97 proximity call changed")
    if EXPECTED_TYPE97_BYTES[-3:] != bytes((0x4C, TRANSFORM_CPU & 0xFF, TRANSFORM_CPU >> 8)):
        raise ScoreAwardError("type $97 transform jump changed")
    if EXPECTED_ADD_SCORE_BYTES[-3:] != bytes((0x4C, DIVIDE_UNSIGNED_CPU & 0xFF, DIVIDE_UNSIGNED_CPU >> 8)):
        raise ScoreAwardError("unsigned division tail jump changed")
    return {
        "type97_range": [TYPE97_CPU, TYPE97_END - 1],
        "score_range": [ADD_SCORE_CPU, ADD_SCORE_END - 1],
        "type97_bytes": len(EXPECTED_TYPE97_BYTES),
        "score_bytes": len(EXPECTED_ADD_SCORE_BYTES),
        "score_call_sites": list(EXPECTED_SCORE_CALLS),
        "handler_entry": handler_entry,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    cases = 0
    for score in range(0x10000):
        for award in (10, 20, 40, 80, 100):
            result = add_player_score(score, 7, award)
            expected_score = (score + award) & 0xFFFF
            expected_extra = score // 1000 != expected_score // 1000
            if result != ScoreAwardResult(expected_score, 8 if expected_extra else 7, expected_extra):
                raise ScoreAwardError("score transition mismatch")
            cases += 1
    boundary_scores = {0, 0xFFFF}
    for boundary in range(0, 0x10000, 1000):
        boundary_scores.update((boundary, max(0, boundary - 1), min(0xFFFF, boundary + 1)))
    for score in boundary_scores:
        for award in range(0x100):
            add_player_score(score, 0xFE, award)
            cases += 1
    for lives in range(0x100):
        if add_player_score(950, lives, 100).lives != min(lives + 1, 0xFF):
            raise ScoreAwardError("extra-life saturation mismatch")
        if add_player_score(100, lives, 100).lives != lives:
            raise ScoreAwardError("non-threshold life mutation")
        cases += 2
    return {"state_cases": cases, "score_domain": 0x10000, "award_domain": 0x100}


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
            "threshold": asdict(add_player_score(950, 1, 100)),
            "demo": asdict(add_player_score(950, 1, 100, True)),
            "type97": asdict(collect_runtime_type97(True, 950, 1)),
        }
    except (OSError, ScoreAwardError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated type-$97 collection, score topology, and "
            f"{report['exhaustive']['state_cases']} score/life cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
