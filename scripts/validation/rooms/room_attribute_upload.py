#!/usr/bin/env python3
"""Model and validate Castle Excellent's two NMI attribute upload tasks."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Sequence


PRG_CPU_BASE = 0x8000
ATTRIBUTE_BUFFER_SIZE = 0x80
LEFT_TASK_ADDRESS = 0xE1F8
RIGHT_TASK_ADDRESS = 0xE358
TASKS_END_ADDRESS = 0xE45D
LEFT_PPU_ADDRESS = 0x23C8
RIGHT_PPU_ADDRESS = 0x27C8
LEFT_SOURCE_START = 0x08
LEFT_UPLOAD_BYTES = 56
RIGHT_SOURCE_START = 0x48
RIGHT_SOURCE_ROWS = 7
RIGHT_SOURCE_COLUMNS = 4
RIGHT_PADDED_ROWS = 6
RIGHT_UPLOAD_BYTES = 52
PPU_STATUS = 0x2002
PPU_ADDR = 0x2006
PPU_DATA = 0x2007
NMI_FRAME_ADDRESS = 0xC588


class RoomAttributeUploadError(ValueError):
    pass


def _validate_buffer(values: Sequence[int]) -> tuple[int, ...]:
    if len(values) != ATTRIBUTE_BUFFER_SIZE:
        raise RoomAttributeUploadError(
            f"attribute buffer has {len(values)} bytes, expected {ATTRIBUTE_BUFFER_SIZE}"
        )
    if any(not 0 <= value <= 0xFF for value in values):
        raise RoomAttributeUploadError("attribute buffer contains a non-byte value")
    return tuple(values)


def build_attribute_writes(
    attributes: Sequence[int],
) -> tuple[tuple[int, tuple[int, ...]], tuple[int, tuple[int, ...]]]:
    source = _validate_buffer(attributes)
    left = source[LEFT_SOURCE_START : LEFT_SOURCE_START + LEFT_UPLOAD_BYTES]
    right: list[int] = []
    for row in range(RIGHT_SOURCE_ROWS):
        start = RIGHT_SOURCE_START + row * 8
        values = source[start : start + RIGHT_SOURCE_COLUMNS]
        right.extend(values)
        if row < RIGHT_PADDED_ROWS:
            right.extend((values[-1],) * 4)
    if len(right) != RIGHT_UPLOAD_BYTES:
        raise RoomAttributeUploadError("right attribute expansion has wrong width")
    return (LEFT_PPU_ADDRESS, left), (RIGHT_PPU_ADDRESS, tuple(right))


def _absolute(opcode: int, address: int) -> bytes:
    return bytes((opcode, address & 0xFF, address >> 8))


def _ppu_setup(address: int, read_status: bool = True) -> bytes:
    result = bytearray()
    if read_status:
        result.extend(_absolute(0xAD, PPU_STATUS))
    result.extend((0xA9, address >> 8))
    result.extend(_absolute(0x8D, PPU_ADDR))
    result.extend((0xA9, address & 0xFF))
    result.extend(_absolute(0x8D, PPU_ADDR))
    return bytes(result)


def expected_left_task_bytes() -> bytes:
    result = bytearray(_ppu_setup(LEFT_PPU_ADDRESS))
    for offset in range(LEFT_SOURCE_START, LEFT_SOURCE_START + LEFT_UPLOAD_BYTES):
        result.extend(_absolute(0xAD, 0x0100 + offset))
        result.extend(_absolute(0x8D, PPU_DATA))
    result.extend(_absolute(0x4C, NMI_FRAME_ADDRESS))
    return bytes(result)


def expected_right_task_bytes() -> bytes:
    result = bytearray(_ppu_setup(RIGHT_PPU_ADDRESS))
    for row in range(RIGHT_SOURCE_ROWS):
        start = RIGHT_SOURCE_START + row * 8
        for column in range(RIGHT_SOURCE_COLUMNS):
            result.extend(_absolute(0xAD, 0x0100 + start + column))
            result.extend(_absolute(0x8D, PPU_DATA))
        if row < RIGHT_PADDED_ROWS:
            result.extend(_absolute(0x8D, PPU_DATA) * 4)
    result.extend((0xA2, 0x19, 0xCA, 0xD0, 0xFD))
    result.extend(_absolute(0x4C, NMI_FRAME_ADDRESS))
    return bytes(result)


def _read_prg(image: Path) -> bytes:
    data = image.read_bytes()
    if len(data) < 16 or data[:4] != b"NES\x1a":
        raise RoomAttributeUploadError(f"{image} is not an iNES image")
    trainer = 512 if data[6] & 0x04 else 0
    size = data[4] * 0x4000
    start = 16 + trainer
    prg = data[start : start + size]
    if len(prg) != 0x8000:
        raise RoomAttributeUploadError("expected a complete 32 KiB PRG-ROM")
    return prg


def validate_attribute_upload_contract(image: Path) -> dict[str, object]:
    prg = _read_prg(image)
    expected_tasks = (
        (LEFT_TASK_ADDRESS, expected_left_task_bytes()),
        (RIGHT_TASK_ADDRESS, expected_right_task_bytes()),
    )
    for address, expected in expected_tasks:
        offset = address - PRG_CPU_BASE
        actual = prg[offset : offset + len(expected)]
        if actual != expected:
            raise RoomAttributeUploadError(f"attribute task differs at ${address:04X}")
    if LEFT_TASK_ADDRESS + len(expected_tasks[0][1]) != RIGHT_TASK_ADDRESS:
        raise RoomAttributeUploadError("left attribute task boundary mismatch")
    if RIGHT_TASK_ADDRESS + len(expected_tasks[1][1]) != TASKS_END_ADDRESS:
        raise RoomAttributeUploadError("right attribute task boundary mismatch")
    writes = build_attribute_writes(range(ATTRIBUTE_BUFFER_SIZE))
    return {
        "task_range": f"0x{LEFT_TASK_ADDRESS:04X}-0x{TASKS_END_ADDRESS - 1:04X}",
        "left": {"ppu_address": "0x23C8", "bytes": len(writes[0][1])},
        "right": {
            "ppu_address": "0x27C8",
            "source_bytes": RIGHT_SOURCE_ROWS * RIGHT_SOURCE_COLUMNS,
            "output_bytes": len(writes[1][1]),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_attribute_upload_contract(args.image)
    except (OSError, RoomAttributeUploadError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print("[OK] validated both NMI attribute tasks and 108 PPU writes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
