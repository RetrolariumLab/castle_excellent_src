#!/usr/bin/env python3
"""Model the runtime-object/player proximity predicate at $A8A9-$A8E2."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA8A9
OBJECT_Y_OFFSET = 0x10
Y_LIMIT = 4
X_LIMIT = 5
ROOM_PIXEL_WIDTH = 0x140
CALL_OPCODE = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
EXPECTED_ALIGNED_CALL_SITES = (
    0x8C12,
    0x8C21,
    0x8C30,
    0x8C3F,
    0x8C4E,
    0x8C5D,
    0x8C80,
    0x8C9E,
    0x8CB2,
    0x8CC2,
    0x8CD2,
    0x8CE2,
    0x8CF2,
    0x8D5C,
    0x8D70,
)
EXPECTED_UNALIGNED_MATCHES = (0xC86F,)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A6 41 B5 4D 18 69 10 38 E5 3A B0 04 49 FF 69 01 C9 04 B0 25 "
    "B5 4B 38 E5 38 85 25 B5 4C E5 39 85 26 B0 0E A5 25 49 FF "
    "69 01 85 25 A5 26 49 FF 85 26 F0 02 38 60 A5 25 C9 05 60"
)


class ObjectPlayerProximityError(ValueError):
    pass


@dataclass(frozen=True)
class ProximityResult:
    object_anchor_y: int
    y_distance: int
    x_distance: int | None
    near: bool


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise ObjectPlayerProximityError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise ObjectPlayerProximityError(f"{name} outside 0-65535: {value}")


def normalize_x_delta(object_x: int, player_x: int) -> int:
    """Reproduce the routine's 16-bit subtraction and negative normalization."""
    _validate_word(object_x, "object X")
    _validate_word(player_x, "player X")
    delta = (object_x - player_x) & 0xFFFF
    if object_x >= player_x:
        return delta
    low = ((~delta & 0xFF) + 1) & 0xFF
    high = (~(delta >> 8)) & 0xFF
    return high << 8 | low


def evaluate_proximity(
    *, object_x: int, object_y: int, player_x: int, player_y: int
) -> ProximityResult:
    _validate_word(object_x, "object X")
    _validate_byte(object_y, "object Y")
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")
    object_anchor_y = (object_y + OBJECT_Y_OFFSET) & 0xFF
    y_distance = abs(object_anchor_y - player_y)
    if y_distance >= Y_LIMIT:
        return ProximityResult(object_anchor_y, y_distance, None, False)
    x_distance = normalize_x_delta(object_x, player_x)
    near = x_distance >> 8 == 0 and (x_distance & 0xFF) < X_LIMIT
    return ProximityResult(object_anchor_y, y_distance, x_distance, near)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise ObjectPlayerProximityError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise ObjectPlayerProximityError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def find_call_sites(prg: bytes) -> tuple[int, ...]:
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(CALL_OPCODE) + 1)
        if prg[offset:offset + len(CALL_OPCODE)] == CALL_OPCODE
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    start = ROUTINE_CPU - PRG_BASE
    observed = prg[start:start + len(EXPECTED_ROUTINE_BYTES)]
    if observed != EXPECTED_ROUTINE_BYTES:
        raise ObjectPlayerProximityError("object/player proximity routine bytes changed")
    raw_matches = find_call_sites(prg)
    expected_matches = tuple(
        sorted(EXPECTED_ALIGNED_CALL_SITES + EXPECTED_UNALIGNED_MATCHES)
    )
    if raw_matches != expected_matches:
        raise ObjectPlayerProximityError("object/player proximity byte matches changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_CPU + len(observed) - 1],
        "routine_bytes": len(observed),
        "aligned_call_sites": list(EXPECTED_ALIGNED_CALL_SITES),
        "incidental_unaligned_matches": list(EXPECTED_UNALIGNED_MATCHES),
    }


def validate_exhaustive_contract() -> dict[str, object]:
    y_cases = 0
    for object_y in range(0x100):
        for player_y in range(0x100):
            result = evaluate_proximity(
                object_x=0,
                object_y=object_y,
                player_x=0,
                player_y=player_y,
            )
            expected = abs(((object_y + OBJECT_Y_OFFSET) & 0xFF) - player_y)
            if result.y_distance != expected:
                raise ObjectPlayerProximityError("Y-distance mismatch")
            if result.near != (expected < Y_LIMIT):
                raise ObjectPlayerProximityError("Y-threshold mismatch")
            y_cases += 1

    negative_delta_cases = 0
    for magnitude in range(1, 0x10000):
        observed = normalize_x_delta(0, magnitude)
        expected = magnitude - 0x100 if magnitude & 0xFF == 0 else magnitude
        if observed != expected:
            raise ObjectPlayerProximityError("negative X normalization mismatch")
        negative_delta_cases += 1

    room_x_cases = 0
    compatibility_aliases: list[tuple[int, int]] = []
    for object_x in range(ROOM_PIXEL_WIDTH):
        for player_x in range(ROOM_PIXEL_WIDTH):
            result = evaluate_proximity(
                object_x=object_x,
                object_y=0,
                player_x=player_x,
                player_y=OBJECT_Y_OFFSET,
            )
            ideal = abs(object_x - player_x) < X_LIMIT
            if result.near != ideal:
                compatibility_aliases.append((object_x, player_x))
            room_x_cases += 1
    expected_aliases = [(object_x, object_x + 0x100) for object_x in range(0x40)]
    if compatibility_aliases != expected_aliases:
        raise ObjectPlayerProximityError("unexpected room-width X compatibility aliases")

    return {
        "y_cases": y_cases,
        "negative_delta_cases": negative_delta_cases,
        "room_x_cases": room_x_cases,
        "negative_page_aliases": len(compatibility_aliases),
        "x_limit": X_LIMIT,
        "y_limit": Y_LIMIT,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    report = {"rom": validate_rom_contract(prg)}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, ObjectPlayerProximityError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        exhaustive = report["exhaustive"]
        print(
            "[OK] validated 15 call sites, one unaligned byte match, all Y "
            "pairs, 65,535 negative X deltas, and "
            f"{exhaustive['room_x_cases']:,} room-width X pairs"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
