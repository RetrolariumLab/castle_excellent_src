#!/usr/bin/env python3
"""Model the shared room-cell sample address builder at $8ECB-$8F0F."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8ECB
ROUTINE_END = 0x8F10
ROOM_CELLS = 0x0400
ROOM_WIDTH = 20
EXPECTED_CALL_SITES = (0x89FC, 0x8ACA, 0x8AF4, 0x8DF7, 0x9B0D, 0xA1AD, 0xA88A)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "85 28 85 2A 86 27 86 29 84 1B A9 00 85 2C 98 4A 4A 4A 85 2B "
    "06 2B 26 2C 06 2B 26 2C 18 65 2B 85 2B 90 02 E6 2C 06 2B "
    "26 2C 06 2B 26 2C A9 04 18 65 2C 85 2C 46 2A 66 29 46 2A "
    "66 29 46 2A 66 29 46 2A 66 29 60"
)


class RoomCellSampleAddressError(ValueError):
    pass


@dataclass(frozen=True)
class RoomCellSampleAddress:
    sample_x: int
    sample_y: int
    cell_pointer: int
    column: int
    accumulator: int
    x_register: int
    y_register: int
    carry: bool
    negative: bool
    zero: bool


def prepare_room_cell_sample_address(x: int, y: int) -> RoomCellSampleAddress:
    if not 0 <= x <= 0xFFFF:
        raise RoomCellSampleAddressError(f"sample X outside 0-65535: {x}")
    if not 0 <= y <= 0xFF:
        raise RoomCellSampleAddressError(f"sample Y outside 0-255: {y}")
    cell_pointer = ROOM_CELLS + (y >> 3) * ROOM_WIDTH
    column = x >> 4
    column_lo = column & 0xFF
    return RoomCellSampleAddress(
        sample_x=x,
        sample_y=y,
        cell_pointer=cell_pointer,
        column=column,
        accumulator=(cell_pointer >> 8) & 0xFF,
        x_register=x & 0xFF,
        y_register=y,
        carry=bool(x & 0x08),
        negative=bool(column_lo & 0x80),
        zero=column_lo == 0,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomCellSampleAddressError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise RoomCellSampleAddressError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise RoomCellSampleAddressError(f"truncated PRG range at ${address:04X}")
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
        raise RoomCellSampleAddressError("room-cell sample address routine changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise RoomCellSampleAddressError("room-cell sample address call sites changed")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(EXPECTED_CALL_SITES),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    x_cases = 0
    for x in range(0x10000):
        result = prepare_room_cell_sample_address(x, 0)
        if result.column != x >> 4:
            raise RoomCellSampleAddressError("16-bit sample column mismatch")
        if result.carry != bool(x & 8):
            raise RoomCellSampleAddressError("final carry does not preserve X bit 3")
        if result.negative != bool((x >> 4) & 0x80):
            raise RoomCellSampleAddressError("final negative flag mismatch")
        if result.zero != (((x >> 4) & 0xFF) == 0):
            raise RoomCellSampleAddressError("final zero flag mismatch")
        x_cases += 1

    y_cases = 0
    for y in range(0x100):
        result = prepare_room_cell_sample_address(0, y)
        expected = ROOM_CELLS + (y >> 3) * ROOM_WIDTH
        if result.cell_pointer != expected:
            raise RoomCellSampleAddressError("room-row pointer mismatch")
        if result.accumulator != expected >> 8:
            raise RoomCellSampleAddressError("returned pointer high byte mismatch")
        y_cases += 1
    return {"x_cases": x_cases, "y_cases": y_cases}


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report: dict[str, object] = {
        "rom": validate_rom_contract(extract_prg(image_path.read_bytes()))
    }
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    report["samples"] = {
        "top_left": asdict(prepare_room_cell_sample_address(0, 0)),
        "bottom_right": asdict(prepare_room_cell_sample_address(319, 159)),
    }
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, RoomCellSampleAddressError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        print(
            "[OK] validated seven call sites and "
            f"{sum(cases.values()):,} complete X/Y machine-value cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
