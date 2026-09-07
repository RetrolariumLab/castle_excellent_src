#!/usr/bin/env python3
"""Decode directional player collision-handler matrices at $8F29-$926A."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
TABLE_START = 0x8F29
TABLE_END = 0x926B
TABLE_STRIDE = 0x116
ROOM_CELL_COUNT = 100
RUNTIME_TYPE_FIRST = 0x80
RUNTIME_TYPE_LAST_PHYSICAL = 0xA6
RUNTIME_ENTRY_COUNT = 39
NO_OP_HANDLER = 0x926B
UNSAFE_HORIZONTAL_A7_POINTER = 0xB060
WHOLE_SHA256 = "7b3d3412331c077036be027322e13c9bab607de978e0a471d6558dacd7f5df0c"


@dataclass(frozen=True)
class PhysicalTable:
    name: str
    address: int
    entries: int
    first_index: int
    sha256: str


PHYSICAL_TABLES = (
    PhysicalTable("down_room", 0x8F29, 100, 0x00, "91d6797f2e7217e3cbbf3a036cbff2e678fa90b82dff32aaa854d99b7ac44126"),
    PhysicalTable("down_runtime", 0x8FF1, 39, 0x80, "8a1351d568df4a8113ae6a0b1f5a65041d5af9f4aadfb4313e62f20a248d166b"),
    PhysicalTable("up_room", 0x903F, 100, 0x00, "9cfc828d6dfb1675c8254f923b17990a219ac44dab8e0485965c2ac0367f4ee5"),
    PhysicalTable("up_runtime", 0x9107, 39, 0x80, "6bddc5a98bbfe7f2f3008cfbccf16d06b9b4286a60c3daa2ff5dede13e5763b2"),
    PhysicalTable("horizontal_room", 0x9155, 100, 0x00, "06f9e920dc1efe13a8d25a6ab515016613d82e68bcaa76ab9faff8223f591100"),
    PhysicalTable("horizontal_runtime", 0x921D, 39, 0x80, "b9ab8522709f422a6aeb6e5130d3624584ca914e70520b9ec7b72712191d1587"),
)

CONSUMER_LOADS = {
    0x8381: (0xBD, 0x903F),
    0x8386: (0xBD, 0x9040),
    0x838E: (0xBD, 0x9107),
    0x8393: (0xBD, 0x9108),
    0x841E: (0xBD, 0x8F29),
    0x8423: (0xBD, 0x8F2A),
    0x842B: (0xBD, 0x8FF1),
    0x8430: (0xBD, 0x8FF2),
    0x85AA: (0xBD, 0x9155),
    0x85AF: (0xBD, 0x9156),
    0x85B7: (0xBD, 0x921D),
    0x85BC: (0xBD, 0x921E),
}

SYNTHETIC_CALLS = {
    0x8398: (0x83A1, bytes.fromhex("A9 83 48 A9 A0 48 6C 31 00")),
    0x8435: (0x843E, bytes.fromhex("A9 84 48 A9 3D 48 6C 31 00")),
    0x85C1: (0x85CA, bytes.fromhex("A9 85 48 A9 C9 48 6C 31 00")),
}


class CollisionTableError(ValueError):
    pass


class UnsafeHorizontalRuntimeTypeError(CollisionTableError):
    pass


def _runtime_map(direction: str) -> dict[int, int]:
    result = {
        runtime_type: NO_OP_HANDLER
        for runtime_type in range(RUNTIME_TYPE_FIRST, RUNTIME_TYPE_LAST_PHYSICAL + 1)
    }
    result.update({
        0x81: 0x8D70,
        0x83: 0x8C80,
        0x84: 0x8DB0,
        0x85: 0x8DB0,
        0x86: 0x8DB0,
        0x87: 0x8DB0,
        0x88: 0x8DB0,
        0x89: 0x8DB0,
        0x96: 0x8C9E,
        0x97: 0x8CF2,
        0x98: 0x8CB2,
        0x99: 0x8CC2,
        0x9A: 0x8CD2,
        0x9B: 0x8CE2,
        0x9F: 0x8D3D,
        0xA6: 0x8DB0,
    })
    if direction == "down":
        result[0x8F] = 0x8DB0
    elif direction == "horizontal":
        result.update({runtime_type: 0x881A for runtime_type in (0x8A, 0x8B, 0x8C, 0x8D, 0x8F)})
        result[0x8E] = 0x89E1
    elif direction != "up":
        raise CollisionTableError(f"unknown direction: {direction}")
    return result


def _room_map(direction: str) -> dict[int, int]:
    result = {cell: NO_OP_HANDLER for cell in range(ROOM_CELL_COUNT)}
    if direction == "down":
        result.update({cell: 0x87CB for cell in range(0x35, 0x41)})
        result.update({cell: 0x8785 for cell in range(0x56, 0x62)})
    elif direction == "horizontal":
        for cells, handler in (
            ((0x19, 0x1A), 0xA5DD),
            ((0x1C, 0x1D), 0xA5E7),
            ((0x1F, 0x20), 0xA5F1),
            ((0x22, 0x23), 0xA5FB),
            ((0x25, 0x26), 0xA605),
            ((0x29, 0x2A), 0xA60F),
        ):
            result.update({cell: handler for cell in cells})
    elif direction != "up":
        raise CollisionTableError(f"unknown direction: {direction}")
    return result


ROOM_MAPS = {direction: _room_map(direction) for direction in ("down", "up", "horizontal")}
RUNTIME_MAPS = {direction: _runtime_map(direction) for direction in ("down", "up", "horizontal")}


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise CollisionTableError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise CollisionTableError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _offset(cpu_address: int) -> int:
    return cpu_address - PRG_BASE


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = _offset(cpu_address)
    return prg[offset] | prg[offset + 1] << 8


def decode_table(prg: bytes, table: PhysicalTable) -> dict[int, int]:
    return {
        table.first_index + index: _read_word(prg, table.address + index * 2)
        for index in range(table.entries)
    }


def select_handler(direction: str, collision_value: int) -> int:
    if not 0 <= collision_value <= 0xFF:
        raise CollisionTableError(f"collision value outside 0-255: {collision_value}")
    if collision_value < 0x80:
        if collision_value >= ROOM_CELL_COUNT:
            raise CollisionTableError(f"room cell outside 0-99: {collision_value}")
        return ROOM_MAPS[direction][collision_value]
    if collision_value == 0xA7:
        if direction == "horizontal":
            raise UnsafeHorizontalRuntimeTypeError(
                "horizontal runtime table has no physical type-$A7 entry"
            )
        return NO_OP_HANDLER
    if collision_value > RUNTIME_TYPE_LAST_PHYSICAL:
        raise CollisionTableError(f"runtime type outside $80-$A7: {collision_value:#04x}")
    return RUNTIME_MAPS[direction][collision_value]


def load_instruction_starts(path: Path) -> set[int]:
    starts: set[int] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("address"):
            continue
        starts.add(int(line.split("\t", 1)[0], 16))
    return starts


def validate_rom_contract(prg: bytes, instruction_starts: set[int] | None = None) -> dict[str, object]:
    whole = prg[_offset(TABLE_START):_offset(TABLE_END)]
    if hashlib.sha256(whole).hexdigest() != WHOLE_SHA256:
        raise CollisionTableError("directional collision-table bytes changed")
    decoded: dict[str, dict[int, int]] = {}
    for table in PHYSICAL_TABLES:
        payload = prg[_offset(table.address):_offset(table.address) + table.entries * 2]
        if hashlib.sha256(payload).hexdigest() != table.sha256:
            raise CollisionTableError(f"{table.name} bytes changed")
        decoded[table.name] = decode_table(prg, table)
    for direction in ("down", "up", "horizontal"):
        if decoded[f"{direction}_room"] != ROOM_MAPS[direction]:
            raise CollisionTableError(f"{direction} room-cell map changed")
        if decoded[f"{direction}_runtime"] != RUNTIME_MAPS[direction]:
            raise CollisionTableError(f"{direction} runtime map changed")
    if _read_word(prg, 0x903F) != NO_OP_HANDLER or _read_word(prg, 0x9155) != NO_OP_HANDLER:
        raise CollisionTableError("logical type-$A7 overlap changed")
    if _read_word(prg, 0x926B) != UNSAFE_HORIZONTAL_A7_POINTER:
        raise CollisionTableError("horizontal type-$A7 boundary sentinel changed")
    for address, (opcode, operand) in CONSUMER_LOADS.items():
        at = _offset(address)
        if prg[at:at + 3] != bytes((opcode, operand & 0xFF, operand >> 8)):
            raise CollisionTableError(f"consumer load changed at ${address:04X}")
    for address, (_, encoded) in SYNTHETIC_CALLS.items():
        at = _offset(address)
        if prg[at:at + len(encoded)] != encoded:
            raise CollisionTableError(f"synthetic call changed at ${address:04X}")
    targets = set().union(*(mapping.values() for mapping in decoded.values()))
    if instruction_starts is not None:
        missing = sorted(targets - instruction_starts)
        if missing:
            raise CollisionTableError(
                "handler targets absent from Ghidra facts: "
                + ", ".join(f"${address:04X}" for address in missing)
            )
    return {
        "range": [TABLE_START, TABLE_END - 1],
        "bytes": len(whole),
        "tables": [asdict(table) for table in PHYSICAL_TABLES],
        "distinct_targets": sorted(targets),
        "consumer_loads": len(CONSUMER_LOADS),
        "synthetic_calls": {f"{address:04X}": continuation for address, (continuation, _) in SYNTHETIC_CALLS.items()},
        "horizontal_a7": "unrepresented; raw boundary read would be $B060",
    }


def validate_exhaustive_contract() -> dict[str, int]:
    cases = 0
    for direction in ("down", "up", "horizontal"):
        for cell in range(ROOM_CELL_COUNT):
            if select_handler(direction, cell) != ROOM_MAPS[direction][cell]:
                raise CollisionTableError("room-cell selection mismatch")
            cases += 1
        for runtime_type in range(RUNTIME_TYPE_FIRST, RUNTIME_TYPE_LAST_PHYSICAL + 1):
            if select_handler(direction, runtime_type) != RUNTIME_MAPS[direction][runtime_type]:
                raise CollisionTableError("runtime selection mismatch")
            cases += 1
    for direction in ("down", "up"):
        if select_handler(direction, 0xA7) != NO_OP_HANDLER:
            raise CollisionTableError("logical type-$A7 overlap mismatch")
        cases += 1
    try:
        select_handler("horizontal", 0xA7)
    except UnsafeHorizontalRuntimeTypeError:
        cases += 1
    else:
        raise CollisionTableError("unsafe horizontal type-$A7 was accepted")
    return {"selection_cases": cases, "physical_entries": 417, "logical_entries": 420}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--facts", type=Path)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        starts = load_instruction_starts(args.facts) if args.facts else None
        report = validate_rom_contract(extract_prg(args.image.read_bytes()), starts)
        report["exhaustive"] = validate_exhaustive_contract()
    except (OSError, CollisionTableError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated six directional collision-handler tables, "
            "12 consumers, three synthetic calls, and 420 logical selections"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
