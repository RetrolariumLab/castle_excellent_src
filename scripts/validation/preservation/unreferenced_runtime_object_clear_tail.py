#!/usr/bin/env python3
"""Validate the unreferenced code-shaped bytes at $8C7B-$8C7F."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
RANGE_START = 0x8C7B
RANGE_END = 0x8C80
CLEAR_CURRENT_RUNTIME_OBJECT = 0xA024
EXPECTED_BYTES = bytes.fromhex("A6 41 4C 24 A0")
EXPECTED_SHA256 = "2401ab48e7bc1ac2fc143a492c02288696eab1ef60d9b2a3b8dea66d648c4f04"


class UnreferencedRuntimeObjectClearTailError(ValueError):
    pass


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise UnreferencedRuntimeObjectClearTailError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise UnreferencedRuntimeObjectClearTailError(
            "expected a complete 32 KiB PRG region"
        )
    return image[start:end]


def load_instruction_starts(path: Path) -> set[int]:
    starts: set[int] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("address\t"):
            continue
        try:
            starts.add(int(line.split("\t", 1)[0], 16))
        except ValueError as exc:
            raise UnreferencedRuntimeObjectClearTailError(
                f"invalid instruction address at {path}:{line_number}"
            ) from exc
    return starts


def load_code_evidence(path: Path) -> list[tuple[int, int]]:
    ranges: list[tuple[int, int]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#") or fields[0] != "code":
            continue
        if len(fields) != 3:
            raise UnreferencedRuntimeObjectClearTailError(
                f"invalid code evidence at {path}:{line_number}"
            )
        ranges.append((int(fields[1], 16), int(fields[2], 16)))
    return ranges


def hypothetical_decode(sequence: bytes) -> dict[str, int]:
    if sequence != EXPECTED_BYTES:
        raise UnreferencedRuntimeObjectClearTailError("unexpected hypothetical tail bytes")
    return {
        "object_offset_address": sequence[1],
        "jump_target": sequence[3] | sequence[4] << 8,
    }


def _pointer_hits(prg: bytes) -> list[tuple[int, int]]:
    targets = set(range(RANGE_START, RANGE_END))
    return [
        (PRG_BASE + offset, prg[offset] | prg[offset + 1] << 8)
        for offset in range(len(prg) - 1)
        if (prg[offset] | prg[offset + 1] << 8) in targets
    ]


def validate_contract(
    prg: bytes,
    instruction_starts: set[int],
    runtime_code_ranges: list[tuple[int, int]],
) -> dict[str, object]:
    start = RANGE_START - PRG_BASE
    actual = prg[start:start + len(EXPECTED_BYTES)]
    if actual != EXPECTED_BYTES:
        raise UnreferencedRuntimeObjectClearTailError("unreferenced byte sequence changed")
    if hashlib.sha256(actual).hexdigest() != EXPECTED_SHA256:
        raise UnreferencedRuntimeObjectClearTailError("unreferenced byte hash changed")
    decoded = hypothetical_decode(actual)
    if decoded["jump_target"] != CLEAR_CURRENT_RUNTIME_OBJECT:
        raise UnreferencedRuntimeObjectClearTailError("hypothetical jump target changed")
    if prg[start - 1] != 0x60:
        raise UnreferencedRuntimeObjectClearTailError("preceding RTS boundary changed")
    if prg[RANGE_END - PRG_BASE:RANGE_END - PRG_BASE + 3] != b"\x20\xA9\xA8":
        raise UnreferencedRuntimeObjectClearTailError("following routine boundary changed")
    false_instructions = sorted(
        address for address in instruction_starts if RANGE_START <= address < RANGE_END
    )
    if false_instructions:
        joined = ", ".join(f"${address:04X}" for address in false_instructions)
        raise UnreferencedRuntimeObjectClearTailError(
            f"Ghidra still decodes typed data at {joined}"
        )
    for code_start, code_end in runtime_code_ranges:
        if max(RANGE_START, code_start) <= min(RANGE_END - 1, code_end):
            raise UnreferencedRuntimeObjectClearTailError(
                "runtime code evidence reaches typed data"
            )
    pointer_hits = _pointer_hits(prg)
    if pointer_hits:
        address, target = pointer_hits[0]
        raise UnreferencedRuntimeObjectClearTailError(
            f"PRG word at ${address:04X} points into typed data at ${target:04X}"
        )
    return {
        "range": [RANGE_START, RANGE_END - 1],
        "bytes": len(EXPECTED_BYTES),
        "instruction_starts": len(false_instructions),
        "pointer_hits": len(pointer_hits),
        "hypothetical_decode": decoded,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--facts", type=Path, required=True)
    parser.add_argument("--runtime-evidence", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = validate_contract(
            extract_prg(args.image.read_bytes()),
            load_instruction_starts(args.facts),
            load_code_evidence(args.runtime_evidence),
        )
    except (OSError, UnreferencedRuntimeObjectClearTailError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated five unreferenced bytes, zero Ghidra/runtime code "
            "starts, and zero PRG pointer targets"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
