#!/usr/bin/env python3
"""Validate PRG tail padding, room-cell tile tables, and vectors."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
PADDING_START = 0xFEE8
LEFT_TABLE_CPU = 0xFF30
RIGHT_TABLE_CPU = 0xFF94
VECTOR_PADDING_CPU = 0xFFF8
VECTORS_CPU = 0xFFFA
LEFT_SHA256 = "2fb6f6bbf2219c5903d55f3d2bcdd73e3ba2a00905bc34b6997d2b39965b03d3"
RIGHT_SHA256 = "5bef7345ad59b34cf2c50cd9cda4d97b994161e9bee5c75a1ed69098ec9e505c"
PADDING_SHA256 = "51cfa32fece0135f38198da2529e7c6a0c1f53747984d55705077b7f6920cc76"
VECTOR_SHA256 = "71e4896df2858d8da91e3302dfabfa68e1629e3dd3ca4fb72fcb755cc224f775"
EXPECTED_VECTORS = {"nmi": 0xC569, "reset": 0x8225, "irq": 0xC6B8}


class PrgTailDataError(ValueError):
    pass


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PrgTailDataError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise PrgTailDataError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _slice(prg: bytes, start: int, end: int) -> bytes:
    return prg[start - PRG_BASE:end - PRG_BASE]


def tile_pair(prg: bytes, cell_type: int) -> tuple[int, int]:
    if not 0 <= cell_type < 100:
        raise PrgTailDataError(f"room-cell type outside 0-99: {cell_type}")
    return (
        prg[LEFT_TABLE_CPU - PRG_BASE + cell_type],
        prg[RIGHT_TABLE_CPU - PRG_BASE + cell_type],
    )


def read_vectors(prg: bytes) -> dict[str, int]:
    data = _slice(prg, VECTORS_CPU, 0x10000)
    return {
        name: data[index] | data[index + 1] << 8
        for name, index in (("nmi", 0), ("reset", 2), ("irq", 4))
    }


def count_table_reads(facts: str, address: int) -> int:
    operand = f"0x{address:04x},X"
    return sum(
        1
        for line in facts.splitlines()
        if "\tLDA\t" in line and f"\t{operand}\t" in line
    )


def validate_contract(prg: bytes, facts: str) -> dict[str, object]:
    padding = _slice(prg, PADDING_START, LEFT_TABLE_CPU)
    left = _slice(prg, LEFT_TABLE_CPU, RIGHT_TABLE_CPU)
    right = _slice(prg, RIGHT_TABLE_CPU, VECTOR_PADDING_CPU)
    vector_block = _slice(prg, VECTORS_CPU, 0x10000)
    checks = (
        (padding, PADDING_SHA256, "tail padding"),
        (left, LEFT_SHA256, "left tile table"),
        (right, RIGHT_SHA256, "right tile table"),
        (vector_block, VECTOR_SHA256, "interrupt vectors"),
    )
    for data, expected, name in checks:
        if hashlib.sha256(data).hexdigest() != expected:
            raise PrgTailDataError(f"{name} bytes changed")
    if padding != b"\xFF" * 72 or _slice(prg, VECTOR_PADDING_CPU, VECTORS_CPU) != b"\xFF\xFF":
        raise PrgTailDataError("PRG tail padding changed")
    if read_vectors(prg) != EXPECTED_VECTORS:
        raise PrgTailDataError("interrupt vector target changed")
    left_reads = count_table_reads(facts, LEFT_TABLE_CPU)
    right_reads = count_table_reads(facts, RIGHT_TABLE_CPU)
    if (left_reads, right_reads) != (400, 400):
        raise PrgTailDataError(
            f"expected 400 reads per tile table, got {left_reads}/{right_reads}"
        )
    pairs = [tile_pair(prg, cell_type) for cell_type in range(100)]
    return {
        "range": [PADDING_START, 0xFFFF],
        "bytes": 0x10000 - PADDING_START,
        "table_entries": len(pairs),
        "table_reads": {"left": left_reads, "right": right_reads},
        "vectors": read_vectors(prg),
        "mutable_restored_pairs": {f"0x{cell:02X}": pairs[cell] for cell in (0x62, 0x63)},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--facts", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_contract(
            extract_prg(args.image.read_bytes()), args.facts.read_text(encoding="utf-8")
        )
    except (OSError, PrgTailDataError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 200 room-cell tile entries, 800 table reads, "
            "80 padding bytes, and three interrupt vectors"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
