#!/usr/bin/env python3
"""Model the player/object-span overlap predicate at $9613-$965B."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x9613
VERTICAL_SPAN = 0x10
LEFT_REACH = 0x0F
ROOM_PIXEL_WIDTH = 0x140
CALL_OPCODE = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
EXPECTED_CALL_SITES = (0x9855, 0x993D, 0x99B0)
REPRESENTATIVE_WIDTHS = (0, 1, 7, 8, 15, 16, 31, 32, 255)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "A5 46 18 69 10 38 E5 3A 90 3D E9 10 B0 39 A5 44 38 E9 0F 85 48 "
    "A5 45 E9 00 85 49 A5 49 10 06 A9 00 85 49 85 48 A5 38 C5 48 A5 "
    "39 E5 49 90 18 A5 44 18 65 47 85 48 A5 45 69 00 85 49 A5 38 C5 "
    "48 A5 39 E5 49 B0 01 60 38 60"
)


class PlayerObjectSpanError(ValueError):
    pass


@dataclass(frozen=True)
class SpanResult:
    adjusted_bottom: int
    left: int | None
    right: int | None
    overlaps: bool


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerObjectSpanError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerObjectSpanError(f"{name} outside 0-65535: {value}")


def test_player_against_object_span(
    *, object_x: int, object_y: int, width: int, player_x: int, player_y: int
) -> SpanResult:
    """Return the routine's carry-clear overlap result and computed bounds."""
    _validate_word(object_x, "object X")
    _validate_byte(object_y, "object Y")
    _validate_byte(width, "object width")
    _validate_word(player_x, "player X")
    _validate_byte(player_y, "player Y")

    adjusted_bottom = (object_y + VERTICAL_SPAN) & 0xFF
    if player_y > adjusted_bottom or adjusted_bottom - player_y >= VERTICAL_SPAN:
        return SpanResult(adjusted_bottom, None, None, False)

    left = (object_x - LEFT_REACH) & 0xFFFF
    if left & 0x8000:
        left = 0
    if player_x < left:
        return SpanResult(adjusted_bottom, left, None, False)

    right = (object_x + width) & 0xFFFF
    return SpanResult(adjusted_bottom, left, right, player_x < right)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerObjectSpanError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerObjectSpanError("expected a complete 32 KiB PRG region")
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
        raise PlayerObjectSpanError("player/object-span routine bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise PlayerObjectSpanError("player/object-span call sites changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_CPU + len(observed) - 1],
        "routine_bytes": len(observed),
        "call_sites": list(EXPECTED_CALL_SITES),
    }


def validate_exhaustive_contract() -> dict[str, object]:
    vertical_cases = 0
    for object_y in range(0x100):
        adjusted_bottom = (object_y + VERTICAL_SPAN) & 0xFF
        for player_y in range(0x100):
            result = test_player_against_object_span(
                object_x=16,
                object_y=object_y,
                width=16,
                player_x=16,
                player_y=player_y,
            )
            expected = max(0, adjusted_bottom - LEFT_REACH) <= player_y <= adjusted_bottom
            if result.overlaps != expected:
                raise PlayerObjectSpanError("vertical-span mismatch")
            vertical_cases += 1

    horizontal_cases = 0
    for width in REPRESENTATIVE_WIDTHS:
        for object_x in range(ROOM_PIXEL_WIDTH):
            left = max(0, object_x - LEFT_REACH)
            right = object_x + width
            for player_x in range(ROOM_PIXEL_WIDTH):
                result = test_player_against_object_span(
                    object_x=object_x,
                    object_y=0,
                    width=width,
                    player_x=player_x,
                    player_y=VERTICAL_SPAN,
                )
                expected = left <= player_x < right
                if result.overlaps != expected:
                    raise PlayerObjectSpanError("horizontal-span mismatch")
                horizontal_cases += 1

    return {
        "vertical_cases": vertical_cases,
        "horizontal_cases": horizontal_cases,
        "representative_widths": list(REPRESENTATIVE_WIDTHS),
        "left_reach": LEFT_REACH,
        "vertical_span": VERTICAL_SPAN,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report = {"rom": validate_rom_contract(extract_prg(image_path.read_bytes()))}
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    sample = test_player_against_object_span(
        object_x=0x80, object_y=0x40, width=0x10, player_x=0x78, player_y=0x50
    )
    report["sample"] = asdict(sample)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, PlayerObjectSpanError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        exhaustive = report["exhaustive"]
        print(
            "[OK] validated three call sites, every Y pair, and "
            f"{exhaustive['horizontal_cases']:,} room-width X/width cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
