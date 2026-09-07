#!/usr/bin/env python3
"""Model Castle Excellent's staging-to-DMA OAM transforms."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Sequence


INES_HEADER_SIZE = 16
PRG_CPU_BASE = 0x8000
OAM_ROTATION_TABLE_ADDRESS = 0xC79D
OAM_ROTATION_TABLE_BYTES = 16
OAM_USED_ROTATION_OFFSETS = 15
OAM_SPRITE_SIZE = 4
OAM_SPRITE_COUNT = 64
OAM_BUFFER_SIZE = OAM_SPRITE_SIZE * OAM_SPRITE_COUNT
OAM_INTERLEAVE_BLOCK_SIZE = 32
OAM_INTERLEAVE_BLOCK_COUNT = 8
OAM_FRAME_COUNT = 8
EXPECTED_ROTATION_OFFSETS = tuple(range(0, 32, 4)) * 2


class OamDmaError(ValueError):
    pass


def _validate_oam_buffer(data: Sequence[int], name: str) -> bytes:
    if len(data) != OAM_BUFFER_SIZE:
        raise OamDmaError(f"{name} has {len(data)} bytes, expected {OAM_BUFFER_SIZE}")
    if any(not 0 <= value <= 0xFF for value in data):
        raise OamDmaError(f"{name} contains a value outside byte range")
    return bytes(data)


def build_dma_oam(
    staging: Sequence[int], frame_counter: int, rotation_offsets: Sequence[int]
) -> bytes:
    """Reproduce the eight-block transpose at $C6B9-$C79C."""
    source = _validate_oam_buffer(staging, "staging OAM")
    if not 0 <= frame_counter <= 0xFF:
        raise OamDmaError(f"frame counter is not a byte: {frame_counter}")
    if len(rotation_offsets) < OAM_USED_ROTATION_OFFSETS:
        raise OamDmaError(
            f"rotation table has {len(rotation_offsets)} bytes, "
            f"expected at least {OAM_USED_ROTATION_OFFSETS}"
        )
    output = bytearray(OAM_BUFFER_SIZE)
    frame = frame_counter & (OAM_FRAME_COUNT - 1)
    for block in range(OAM_INTERLEAVE_BLOCK_COUNT):
        table_index = frame + block
        column_offset = rotation_offsets[table_index]
        if column_offset % OAM_SPRITE_SIZE or column_offset >= OAM_INTERLEAVE_BLOCK_SIZE:
            raise OamDmaError(f"invalid OAM rotation offset: {column_offset}")
        output_base = block * OAM_INTERLEAVE_BLOCK_SIZE
        for row in range(OAM_INTERLEAVE_BLOCK_COUNT):
            source_offset = row * OAM_INTERLEAVE_BLOCK_SIZE + column_offset
            destination = output_base + row * OAM_SPRITE_SIZE
            output[destination : destination + OAM_SPRITE_SIZE] = source[
                source_offset : source_offset + OAM_SPRITE_SIZE
            ]
    return bytes(output)


def reverse_dma_oam(dma_oam: Sequence[int]) -> bytes:
    """Reverse all 64 four-byte hardware sprite records."""
    source = _validate_oam_buffer(dma_oam, "DMA OAM")
    output = bytearray(OAM_BUFFER_SIZE)
    for destination_sprite in range(OAM_SPRITE_COUNT):
        source_sprite = OAM_SPRITE_COUNT - 1 - destination_sprite
        destination = destination_sprite * OAM_SPRITE_SIZE
        source_offset = source_sprite * OAM_SPRITE_SIZE
        output[destination : destination + OAM_SPRITE_SIZE] = source[
            source_offset : source_offset + OAM_SPRITE_SIZE
        ]
    return bytes(output)


def read_rotation_offsets(image: Path) -> tuple[int, ...]:
    data = image.read_bytes()
    if len(data) < INES_HEADER_SIZE or data[:4] != b"NES\x1a":
        raise OamDmaError(f"{image} is not an iNES image")
    prg_size = data[4] * 0x4000
    prg = data[INES_HEADER_SIZE : INES_HEADER_SIZE + prg_size]
    offset = OAM_ROTATION_TABLE_ADDRESS - PRG_CPU_BASE
    table = prg[offset : offset + OAM_ROTATION_TABLE_BYTES]
    if len(table) != OAM_ROTATION_TABLE_BYTES:
        raise OamDmaError("OAM rotation table falls outside PRG-ROM")
    return tuple(table)


def validate_oam_contract(image: Path) -> dict[str, object]:
    offsets = read_rotation_offsets(image)
    if offsets != EXPECTED_ROTATION_OFFSETS:
        raise OamDmaError(f"unexpected OAM rotation table: {offsets}")
    staging = bytes(value for sprite in range(64) for value in (sprite,) * 4)
    frame_zero = build_dma_oam(staging, 0, offsets)
    frame_seven = build_dma_oam(staging, 7, offsets)
    expected_zero = tuple((block + row * 8) for block in range(8) for row in range(8))
    expected_seven = tuple(((block + 7) % 8 + row * 8) for block in range(8) for row in range(8))
    if tuple(frame_zero[::4]) != expected_zero or tuple(frame_seven[::4]) != expected_seven:
        raise OamDmaError("OAM interleave order does not match the assembly")
    if reverse_dma_oam(reverse_dma_oam(frame_zero)) != frame_zero:
        raise OamDmaError("OAM reversal is not an involution")
    return {
        "rotation_table_address": f"0x{OAM_ROTATION_TABLE_ADDRESS:04X}",
        "used_rotation_offsets": OAM_USED_ROTATION_OFFSETS,
        "unused_final_offset": offsets[-1],
        "frame_count": OAM_FRAME_COUNT,
        "sprite_count": OAM_SPRITE_COUNT,
        "frame_zero_sprite_order": list(expected_zero),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_oam_contract(args.image)
    except (OSError, OamDmaError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 64-sprite OAM interleave, eight frame rotations, "
            "and full sprite-order reversal"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
