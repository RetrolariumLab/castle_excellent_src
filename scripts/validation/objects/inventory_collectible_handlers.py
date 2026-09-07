#!/usr/bin/env python3
"""Model inventory collectible handlers at $8C12-$8C7A."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8C12
ROUTINE_END = 0x8C7B
ROUTINE_SHA256 = "4c9919c8e98d00a94bdd8b85fdce835a37e81f4a5a08fcb8ea6b4416b3c8e635"
RUNTIME_HANDLER_TABLE_CPU = 0x9334
PROXIMITY_CPU = 0xA8A9
ADD_SCORE_CPU = 0x8D04
SOUND_EFFECT_CPU = 0xC272
FINALIZER_CPU = 0x8C69
INVENTORY_INDEX_BY_TYPE = {
    0x90: 1,
    0x91: 0,
    0x92: 4,
    0x93: 3,
    0x94: 5,
    0x95: 2,
}
HANDLER_TARGET_BY_TYPE = {
    runtime_type: ROUTINE_CPU + index * 0x0F
    for index, runtime_type in enumerate(INVENTORY_INDEX_BY_TYPE)
}


class InventoryCollectibleError(ValueError):
    pass


@dataclass(frozen=True)
class InventoryCollectibleResult:
    collected: bool
    inventory: tuple[int, ...]
    score_award: int
    play_sound_effect: bool
    runtime_type: int | None
    runtime_state: int | None
    lifetime: int | None


def collect_inventory_object(
    runtime_type: int, near_player: bool, inventory: tuple[int, ...]
) -> InventoryCollectibleResult:
    if runtime_type not in INVENTORY_INDEX_BY_TYPE:
        raise InventoryCollectibleError(f"unsupported runtime type: {runtime_type:#04x}")
    if type(near_player) is not bool:
        raise InventoryCollectibleError("near-player result must be boolean")
    if len(inventory) != 6 or any(not 0 <= value <= 0xFF for value in inventory):
        raise InventoryCollectibleError("inventory must contain six byte values")
    if not near_player:
        return InventoryCollectibleResult(False, inventory, 0, False, None, None, None)
    updated = list(inventory)
    index = INVENTORY_INDEX_BY_TYPE[runtime_type]
    updated[index] = (updated[index] + 1) & 0xFF
    return InventoryCollectibleResult(True, tuple(updated), 10, True, 0xA9, 5, 20)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise InventoryCollectibleError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise InventoryCollectibleError("expected a complete 32 KiB PRG region")
    return image[start:end]


def _read_word(prg: bytes, cpu_address: int) -> int:
    offset = cpu_address - PRG_BASE
    return prg[offset] | prg[offset + 1] << 8


def _find_transfer(payload: bytes, opcode: int, target: int) -> tuple[int, ...]:
    encoded = bytes((opcode, target & 0xFF, target >> 8))
    return tuple(
        ROUTINE_CPU + offset
        for offset in range(len(payload) - 2)
        if payload[offset:offset + 3] == encoded
    )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    routine = prg[ROUTINE_CPU - PRG_BASE:ROUTINE_END - PRG_BASE]
    if len(routine) != ROUTINE_END - ROUTINE_CPU:
        raise InventoryCollectibleError("inventory collectible handlers are truncated")
    if hashlib.sha256(routine).hexdigest() != ROUTINE_SHA256:
        raise InventoryCollectibleError("inventory collectible handler bytes changed")
    targets = {
        runtime_type: _read_word(
            prg, RUNTIME_HANDLER_TABLE_CPU + (runtime_type & 0x7F) * 2
        )
        for runtime_type in INVENTORY_INDEX_BY_TYPE
    }
    if targets != HANDLER_TARGET_BY_TYPE:
        raise InventoryCollectibleError("runtime collision-handler pointers changed")
    topology = {
        "proximity_calls": _find_transfer(routine, 0x20, PROXIMITY_CPU),
        "score_calls": _find_transfer(routine, 0x20, ADD_SCORE_CPU),
        "sound_calls": _find_transfer(routine, 0x20, SOUND_EFFECT_CPU),
        "finalizer_jumps": _find_transfer(routine, 0x4C, FINALIZER_CPU),
    }
    if tuple(map(len, topology.values())) != (6, 6, 1, 5):
        raise InventoryCollectibleError("inventory collectible topology changed")
    if set(INVENTORY_INDEX_BY_TYPE.values()) != set(range(6)):
        raise InventoryCollectibleError("inventory counter permutation changed")
    return {
        "range": [ROUTINE_CPU, ROUTINE_END - 1],
        "bytes": len(routine),
        "handler_targets": {f"{key:02X}": value for key, value in targets.items()},
        "inventory_indexes": INVENTORY_INDEX_BY_TYPE,
        **{name: list(addresses) for name, addresses in topology.items()},
    }


def validate_exhaustive_contract() -> dict[str, int]:
    cases = 0
    for runtime_type, expected_index in INVENTORY_INDEX_BY_TYPE.items():
        for near_player in (False, True):
            for initial in range(0x100):
                inventory = tuple(initial if index == expected_index else 0x55 for index in range(6))
                result = collect_inventory_object(runtime_type, near_player, inventory)
                expected = (initial + 1) & 0xFF if near_player else initial
                if result.inventory[expected_index] != expected:
                    raise InventoryCollectibleError("inventory increment mismatch")
                if any(
                    result.inventory[index] != inventory[index]
                    for index in range(6)
                    if index != expected_index
                ):
                    raise InventoryCollectibleError("unselected inventory counter changed")
                if result.collected != near_player or result.score_award != (10 if near_player else 0):
                    raise InventoryCollectibleError("proximity/score contract changed")
                cases += 1
    return {"runtime_types": 6, "cases": cases}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        prg = extract_prg(args.image.read_bytes())
        report = validate_rom_contract(prg)
        report["exhaustive"] = validate_exhaustive_contract()
    except (OSError, InventoryCollectibleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated six inventory collectible handlers, six-counter "
            f"permutation, and {report['exhaustive']['cases']} state cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
