#!/usr/bin/env python3
"""Validate the unreferenced code-shaped bytes at $A2AA-$A2B0."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
RANGE_START = 0xA2AA
RANGE_END = 0xA2B1
EXPECTED_BYTES = bytes.fromhex("98 4A 4A 4A 85 F8 60")
EXPECTED_SHA256 = "e689528db8131a3798d863545815331f70c8d695a242458eb2ff4637fc6cb392"
NEIGHBOR_POINTER_CPU = 0x95BF
NEIGHBOR_RETURN_CPU = 0xA2A9
DISPATCH_TABLES = (
    (0x8F29, 0x926B),
    (0x926C, 0x9386),
    (0x95BF, 0x9613),
    (0xAD95, 0xADE7),
)


class UnreferencedNmiTaskBytesError(ValueError):
    pass


def hypothetical_nmi_task_index(y: int) -> int:
    if not 0 <= y <= 0xFF:
        raise UnreferencedNmiTaskBytesError(f"Y outside 0-255: {y}")
    return y >> 3


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise UnreferencedNmiTaskBytesError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise UnreferencedNmiTaskBytesError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def load_instruction_starts(path: Path) -> set[int]:
    starts: set[int] = set()
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("address\t"):
            continue
        try:
            starts.add(int(line.split("\t", 1)[0], 16))
        except ValueError as exc:
            raise UnreferencedNmiTaskBytesError(
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
            raise UnreferencedNmiTaskBytesError(
                f"invalid code evidence at {path}:{line_number}"
            )
        ranges.append((int(fields[1], 16), int(fields[2], 16)))
    return ranges


def validate_contract(
    prg: bytes,
    instruction_starts: set[int],
    runtime_code_ranges: list[tuple[int, int]],
) -> dict[str, object]:
    start = RANGE_START - PRG_BASE
    actual = prg[start:start + len(EXPECTED_BYTES)]
    if actual != EXPECTED_BYTES:
        raise UnreferencedNmiTaskBytesError("unreferenced byte sequence changed")
    if hashlib.sha256(actual).hexdigest() != EXPECTED_SHA256:
        raise UnreferencedNmiTaskBytesError("unreferenced byte hash changed")
    false_instructions = sorted(
        address for address in instruction_starts if RANGE_START <= address < RANGE_END
    )
    if false_instructions:
        joined = ", ".join(f"${address:04X}" for address in false_instructions)
        raise UnreferencedNmiTaskBytesError(f"Ghidra still decodes data at {joined}")
    for code_start, code_end in runtime_code_ranges:
        if max(RANGE_START, code_start) <= min(RANGE_END - 1, code_end):
            raise UnreferencedNmiTaskBytesError("runtime code evidence reaches typed data")
    targets = []
    for table_start, table_end in DISPATCH_TABLES:
        for address in range(table_start, table_end, 2):
            target = _read_word(prg, address)
            targets.append(target)
            if RANGE_START <= target < RANGE_END:
                raise UnreferencedNmiTaskBytesError(
                    f"dispatch pointer at ${address:04X} enters typed data"
                )
    if _read_word(prg, NEIGHBOR_POINTER_CPU) != NEIGHBOR_RETURN_CPU:
        raise UnreferencedNmiTaskBytesError("neighboring shared-return pointer changed")
    if bytes((RANGE_START & 0xFF, RANGE_START >> 8)) in prg:
        raise UnreferencedNmiTaskBytesError("PRG unexpectedly contains a pointer to $A2AA")
    for y in range(0x100):
        if hypothetical_nmi_task_index(y) != y // 8:
            raise UnreferencedNmiTaskBytesError("hypothetical shift model mismatch")
    return {
        "range": [RANGE_START, RANGE_END - 1],
        "bytes": len(EXPECTED_BYTES),
        "dispatch_entries_checked": len(targets),
        "instruction_starts": len(false_instructions),
        "hypothetical_y_values": 0x100,
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
    except (OSError, UnreferencedNmiTaskBytesError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated seven unreferenced bytes, zero Ghidra/runtime code "
            f"starts, and {report['dispatch_entries_checked']} dispatch entries"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
