#!/usr/bin/env python3
"""Model the room-cell-only collision sampler at $A1A3-$A1D3."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

from scripts.validation.collision import collision_tables


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0xA1A3
ROUTINE_END = 0xA1D4
ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_PIXEL_WIDTH = ROOM_WIDTH * 16
ROOM_PIXEL_HEIGHT = ROOM_HEIGHT * 8
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
EMPTY_ROOM_CELL = 0x53
PAIR_INDEX_FIRST = 0x8A
PAIR_INDEX_END = 0x92
EXPECTED_CALL_SITES = (0x8BD2, 0x8BE4, 0x99E1, 0x99F3)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "C0 A0 90 06 18 A9 53 A2 00 60 20 CB 8E A4 29 B1 2B AA A5 27 "
    "4A 4A 4A 4A 8A 2A AA BD 22 AA 20 CA A6 D0 06 A5 40 10 02 A9 "
    "00 48 4A 68 08 8A 4A 28 60"
)


class RoomCollisionSampleError(ValueError):
    pass


@dataclass(frozen=True)
class RoomCollisionSample:
    accumulator: int
    x_register: int
    y_register: int
    carry: bool
    negative: bool
    zero: bool
    collision_flags: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RoomCollisionSampleError(f"{name} outside 0-255: {value}")


def room_cell_index(x: int, y: int) -> int | None:
    if not 0 <= x < ROOM_PIXEL_WIDTH:
        raise RoomCollisionSampleError(
            f"collision X outside room pixel domain 0-{ROOM_PIXEL_WIDTH - 1}: {x}"
        )
    _validate_byte(y, "collision Y")
    if y >= ROOM_PIXEL_HEIGHT:
        return None
    return (y >> 3) * ROOM_WIDTH + (x >> 4)


def sample_room_collision_at_pixel(
    room_cells: bytes,
    *,
    x: int,
    y: int,
    animation_counter: int = 0,
) -> RoomCollisionSample:
    if len(room_cells) != ROOM_CELL_COUNT:
        raise RoomCollisionSampleError(
            f"room buffer has {len(room_cells)} bytes, expected {ROOM_CELL_COUNT}"
        )
    if any(cell >= collision_tables.ROOM_CELL_TYPE_COUNT for cell in room_cells):
        raise RoomCollisionSampleError("room buffer contains a cell type above 99")
    if not 0 <= x < ROOM_PIXEL_WIDTH:
        raise RoomCollisionSampleError(
            f"collision X outside room pixel domain 0-{ROOM_PIXEL_WIDTH - 1}: {x}"
        )
    _validate_byte(y, "collision Y")
    _validate_byte(animation_counter, "animation counter")
    cell_index = room_cell_index(x, y)
    if cell_index is None:
        return RoomCollisionSample(
            accumulator=EMPTY_ROOM_CELL,
            x_register=0,
            y_register=y,
            carry=False,
            negative=False,
            zero=True,
            collision_flags=0,
        )

    cell = room_cells[cell_index]
    half = (x >> 3) & 1
    pair_index = cell * 2 + half
    raw_flags = collision_tables.EXPECTED_OBJECT_FLAGS[pair_index]
    effective_flags = raw_flags
    pair_matched = PAIR_INDEX_FIRST <= pair_index < PAIR_INDEX_END
    if pair_matched and animation_counter & 0x80:
        effective_flags = 0
    return RoomCollisionSample(
        accumulator=cell,
        x_register=pair_index,
        y_register=0 if pair_matched else 0xFF,
        carry=bool(effective_flags & 0x01),
        negative=bool(effective_flags & 0x80),
        zero=effective_flags == 0,
        collision_flags=effective_flags,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomCollisionSampleError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise RoomCollisionSampleError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise RoomCollisionSampleError(f"truncated PRG range at ${address:04X}")
    return result


def find_call_sites(prg: bytes) -> tuple[int, ...]:
    opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(opcode) + 1)
        if prg[offset:offset + len(opcode)] == opcode
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if _read_cpu_range(prg, ROUTINE_CPU, len(EXPECTED_ROUTINE_BYTES)) != EXPECTED_ROUTINE_BYTES:
        raise RoomCollisionSampleError("room collision-sampler bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise RoomCollisionSampleError("room collision-sampler call sites changed")
    flags = _read_cpu_range(
        prg, collision_tables.OBJECT_FLAGS_CPU, collision_tables.ROOM_CELL_FLAG_COUNT
    )
    if flags != collision_tables.EXPECTED_OBJECT_FLAGS:
        raise RoomCollisionSampleError("object collision-flag table changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(EXPECTED_CALL_SITES),
        "room_geometry": [ROOM_WIDTH, ROOM_HEIGHT],
    }


def validate_exhaustive_contract() -> dict[str, int]:
    coordinate_cases = 0
    for y in range(ROOM_PIXEL_HEIGHT):
        for x in range(ROOM_PIXEL_WIDTH):
            expected = (y >> 3) * ROOM_WIDTH + (x >> 4)
            if room_cell_index(x, y) != expected:
                raise RoomCollisionSampleError("room-cell address mismatch")
            coordinate_cases += 1

    cell_cases = 0
    for cell in range(collision_tables.ROOM_CELL_TYPE_COUNT):
        room = bytes([cell]) * ROOM_CELL_COUNT
        for half in (0, 1):
            for counter in (0x00, 0x80):
                result = sample_room_collision_at_pixel(
                    room, x=half * 8, y=0, animation_counter=counter
                )
                pair_index = cell * 2 + half
                expected = collision_tables.EXPECTED_OBJECT_FLAGS[pair_index]
                if PAIR_INDEX_FIRST <= pair_index < PAIR_INDEX_END and counter & 0x80:
                    expected = 0
                if result.collision_flags != expected:
                    raise RoomCollisionSampleError("room collision flags mismatch")
                if result.accumulator != cell or result.x_register != pair_index:
                    raise RoomCollisionSampleError("room collision return registers mismatch")
                cell_cases += 1
    return {"coordinate_cases": coordinate_cases, "cell_cases": cell_cases}


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report: dict[str, object] = {
        "rom": validate_rom_contract(extract_prg(image_path.read_bytes()))
    }
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    room = bytes([0x2F]) * ROOM_CELL_COUNT
    report["sample"] = asdict(sample_room_collision_at_pixel(room, x=0, y=0))
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, RoomCollisionSampleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        print(
            "[OK] validated four call sites and "
            f"{sum(cases.values()):,} coordinate/cell-half/animation cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
