#!/usr/bin/env python3
"""Model Castle Excellent's game-over and type-$82 completion sequences."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
GAME_OVER_CPU = 0xFE31
GAME_OVER_END = 0xFE84
MESSAGE_CPU = 0xFE84
MESSAGE_END = 0xFE8E
COMPLETION_CPU = 0xFE8E
COMPLETION_END = 0xFED5
HIGH_SCORE_CPU = 0xFED5
HIGH_SCORE_END = 0xFEE8
GAME_OVER_ENTRY_CPU = 0x9431
COMPLETION_ENTRY_CPU = 0x8D6C
GAME_OVER_SHA256 = "6fe5da2cb7f70b58d11202a525ddbe85a04cedc8e8609f1b5c34df5578415e3e"
MESSAGE_SHA256 = "2f320d2ef595b2d4921ad800c63a28f5be00bdab18e2ad1ab3bfecc7d3914428"
COMPLETION_SHA256 = "ad4bb881e05f3a789c51e345b469706e610391d35a83ca7b5983b265e3055aec"
HIGH_SCORE_SHA256 = "81daeff952e6bee73e380f83ddf06d49974cb1d229787840d9981ba6084184ad"
EXPECTED_MESSAGE = bytes.fromhex("77 71 7D 75 FF 7F 86 75 82 00")
GAME_OVER_CALLS = (
    (0xFE31, 0xFED5),
    (0xFE34, 0xB64C),
    (0xFE37, 0x8158),
    (0xFE3A, 0x8164),
    (0xFE52, 0xFCEA),
    (0xFE55, 0xB906),
    (0xFE58, 0xB918),
    (0xFE5B, 0xB87D),
    (0xFE6E, 0xB923),
)
COMPLETION_CALLS = (
    (0xFE8E, 0xFED5),
    (0xFE93, 0xF973),
    (0xFE9E, 0xC4CD),
    (0xFEA3, 0x8175),
    (0xFEA6, 0x8158),
    (0xFEA9, 0xB906),
    (0xFEAC, 0xB918),
    (0xFEAF, 0xB885),
    (0xFEB7, 0x816A),
    (0xFECA, 0xB923),
)


class EndSequenceError(ValueError):
    pass


@dataclass(frozen=True)
class EndingRoute:
    audio_track_set: int
    waits_for_audio: bool
    reset_delay_vblanks: int
    terminal_target: int | None
    freezes_after_audio: bool


def update_high_score(player_score: int, high_score: int) -> int:
    for value, name in ((player_score, "player score"), (high_score, "high score")):
        if not 0 <= value <= 0xFFFF:
            raise EndSequenceError(f"{name} outside 0-65535: {value}")
    return player_score if player_score >= high_score else high_score


def game_over_route() -> EndingRoute:
    return EndingRoute(2, True, 60, 0x8225, False)


def type82_completion_route() -> EndingRoute:
    return EndingRoute(4, True, 0, None, True)


def decode_message(tiles: bytes) -> str:
    if not tiles or tiles[-1] != 0:
        raise EndSequenceError("game-over tile string is not zero terminated")
    decoded = []
    for tile in tiles[:-1]:
        if tile == 0xFF:
            decoded.append(" ")
        elif 0x71 <= tile <= 0x86:
            decoded.append(chr(tile - 0x30))
        else:
            raise EndSequenceError(f"unsupported game-over tile ${tile:02X}")
    return "".join(decoded)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise EndSequenceError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise EndSequenceError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def _require_transfer(prg: bytes, source: int, target: int, opcode: int) -> None:
    expected = bytes((opcode, target & 0xFF, target >> 8))
    if _slice(prg, source, source + 3) != expected:
        raise EndSequenceError(f"control transfer at ${source:04X} changed")


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    ranges = (
        (GAME_OVER_CPU, GAME_OVER_END, GAME_OVER_SHA256, "game-over sequence"),
        (MESSAGE_CPU, MESSAGE_END, MESSAGE_SHA256, "game-over message"),
        (COMPLETION_CPU, COMPLETION_END, COMPLETION_SHA256, "completion sequence"),
        (HIGH_SCORE_CPU, HIGH_SCORE_END, HIGH_SCORE_SHA256, "high-score update"),
    )
    for start, end, expected_hash, name in ranges:
        if hashlib.sha256(_slice(prg, start, end)).hexdigest() != expected_hash:
            raise EndSequenceError(f"{name} bytes changed")
    if _slice(prg, MESSAGE_CPU, MESSAGE_END) != EXPECTED_MESSAGE:
        raise EndSequenceError("game-over message bytes changed")
    if decode_message(EXPECTED_MESSAGE) != "GAME OVER":
        raise EndSequenceError("game-over message decode changed")
    _require_transfer(prg, GAME_OVER_ENTRY_CPU, GAME_OVER_CPU, 0x4C)
    _require_transfer(prg, COMPLETION_ENTRY_CPU, COMPLETION_CPU, 0x4C)
    for source, target in GAME_OVER_CALLS + COMPLETION_CALLS:
        _require_transfer(prg, source, target, 0x20)
    _require_transfer(prg, 0xFE81, 0x8225, 0x4C)
    if _slice(prg, 0xFED3, 0xFED5) != b"\xF0\xFE":
        raise EndSequenceError("completion terminal self-loop changed")
    if prg.count(bytes((0x20, HIGH_SCORE_CPU & 0xFF, HIGH_SCORE_CPU >> 8))) != 2:
        raise EndSequenceError("high-score helper call count changed")
    return {
        "range": [GAME_OVER_CPU, HIGH_SCORE_END - 1],
        "bytes": HIGH_SCORE_END - GAME_OVER_CPU,
        "message": decode_message(EXPECTED_MESSAGE),
        "calls": len(GAME_OVER_CALLS) + len(COMPLETION_CALLS),
    }


def validate_score_contract() -> dict[str, int]:
    boundary_values = (0, 1, 0x7FFF, 0x8000, 0xFFFF)
    cases = 0
    for player_score in range(0x10000):
        for high_score in boundary_values:
            if update_high_score(player_score, high_score) != max(player_score, high_score):
                raise EndSequenceError("high-score comparison mismatch")
            cases += 1
    for high_score in range(0x10000):
        for player_score in boundary_values:
            if update_high_score(player_score, high_score) != max(player_score, high_score):
                raise EndSequenceError("high-score comparison mismatch")
            cases += 1
    return {"score_cases": cases, "boundary_values": len(boundary_values)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_rom_contract(extract_prg(args.image.read_bytes()))
        report["scores"] = validate_score_contract()
        report["routes"] = {
            "game_over": asdict(game_over_route()),
            "type82_completion": asdict(type82_completion_route()),
        }
    except (OSError, EndSequenceError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 183 ending bytes, GAME OVER text, 19 calls, and "
            f"{report['scores']['score_cases']} score comparisons"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
