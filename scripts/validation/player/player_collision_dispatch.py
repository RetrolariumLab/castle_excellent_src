#!/usr/bin/env python3
"""Decode the player collision-result dispatcher at $9477-$949B."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x9477
ROUTINE_END = 0x949C
ROOM_TABLE_CPU = 0x926C
ROOM_HANDLER_COUNT = 100
RUNTIME_TABLE_CPU = 0x9334
RUNTIME_HANDLER_COUNT = 41
RUNTIME_TYPE_FIRST = 0x80
RUNTIME_TYPE_LAST_CONSUMED = 0xA7
NO_OP_HANDLER_CPU = 0x926B
SYNTHETIC_RETURN_CPU = 0x949B
EXPECTED_ROOM_TABLE_SHA256 = (
    "5d66feaf5a6dd43bba732da875fdb3785cae7e3e22df8869b12459a198dadf8f"
)
EXPECTED_RUNTIME_TABLE_SHA256 = (
    "3c5a3afb9c19eb8e2e6644d89f239dcfd247f5381b224e9fa775e1be2ca68cb1"
)
EXPECTED_CALL_SITES = (0x9397, 0x93A2, 0x93B2, 0x93C1, 0x93D0, 0x93DB, 0x93E6)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "0A AA B0 0D BD 6C 92 85 31 BD 6D 92 85 32 4C 92 94 BD 34 93 "
    "85 31 BD 35 93 85 32 A9 94 48 A9 9A 48 6C 31 00 60"
)


class PlayerCollisionDispatchError(ValueError):
    pass


@dataclass(frozen=True)
class CollisionHandlerSelection:
    sample: int
    domain: str
    type_index: int
    doubled_index: int
    handler: int
    synthetic_return: int
    pushed_return: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerCollisionDispatchError(f"{name} outside 0-255: {value}")


def decode_pointer_table(data: bytes) -> tuple[int, ...]:
    if len(data) % 2:
        raise PlayerCollisionDispatchError("pointer table has an odd byte count")
    return tuple(data[index] | data[index + 1] << 8 for index in range(0, len(data), 2))


def select_collision_handler(
    sample: int,
    room_handlers: tuple[int, ...],
    runtime_handlers: tuple[int, ...],
) -> CollisionHandlerSelection:
    _validate_byte(sample, "collision sample")
    if sample & RUNTIME_TYPE_FIRST:
        domain = "runtime-object"
        type_index = sample & 0x7F
        handlers = runtime_handlers
    else:
        domain = "room-cell"
        type_index = sample
        handlers = room_handlers
    if type_index >= len(handlers):
        raise PlayerCollisionDispatchError(
            f"{domain} index {type_index} exceeds {len(handlers)} handlers"
        )
    return CollisionHandlerSelection(
        sample=sample,
        domain=domain,
        type_index=type_index,
        doubled_index=(sample << 1) & 0xFF,
        handler=handlers[type_index],
        synthetic_return=SYNTHETIC_RETURN_CPU,
        pushed_return=SYNTHETIC_RETURN_CPU - 1,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerCollisionDispatchError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerCollisionDispatchError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise PlayerCollisionDispatchError(f"truncated PRG range at ${address:04X}")
    return result


def find_call_sites(prg: bytes) -> tuple[int, ...]:
    opcode = bytes((0x20, ROUTINE_CPU & 0xFF, ROUTINE_CPU >> 8))
    return tuple(
        PRG_BASE + offset
        for offset in range(len(prg) - len(opcode) + 1)
        if prg[offset:offset + len(opcode)] == opcode
    )


def _validate_handler_targets(handlers: tuple[int, ...], name: str) -> None:
    for index, handler in enumerate(handlers):
        if not PRG_BASE <= handler <= 0xFFFF:
            raise PlayerCollisionDispatchError(
                f"{name} handler {index} points outside PRG: ${handler:04X}"
            )


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    if _read_cpu_range(prg, ROUTINE_CPU, len(EXPECTED_ROUTINE_BYTES)) != EXPECTED_ROUTINE_BYTES:
        raise PlayerCollisionDispatchError("player collision-dispatch bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise PlayerCollisionDispatchError("player collision-dispatch call sites changed")
    if _read_cpu_range(prg, NO_OP_HANDLER_CPU, 1) != b"\x60":
        raise PlayerCollisionDispatchError("shared no-op collision handler changed")

    room_bytes = _read_cpu_range(prg, ROOM_TABLE_CPU, ROOM_HANDLER_COUNT * 2)
    runtime_bytes = _read_cpu_range(
        prg, RUNTIME_TABLE_CPU, RUNTIME_HANDLER_COUNT * 2
    )
    if hashlib.sha256(room_bytes).hexdigest() != EXPECTED_ROOM_TABLE_SHA256:
        raise PlayerCollisionDispatchError("room-cell collision-handler table changed")
    if hashlib.sha256(runtime_bytes).hexdigest() != EXPECTED_RUNTIME_TABLE_SHA256:
        raise PlayerCollisionDispatchError("runtime collision-handler table changed")
    room_handlers = decode_pointer_table(room_bytes)
    runtime_handlers = decode_pointer_table(runtime_bytes)
    _validate_handler_targets(room_handlers, "room-cell")
    _validate_handler_targets(runtime_handlers, "runtime")

    selections = tuple(
        select_collision_handler(value, room_handlers, runtime_handlers)
        for value in range(ROOM_HANDLER_COUNT)
    ) + tuple(
        select_collision_handler(value, room_handlers, runtime_handlers)
        for value in range(RUNTIME_TYPE_FIRST, RUNTIME_TYPE_LAST_CONSUMED + 1)
    )
    if any(selection.doubled_index != selection.type_index * 2 for selection in selections):
        raise PlayerCollisionDispatchError("ASL-derived handler index mismatch")
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(EXPECTED_CALL_SITES),
        "room_handlers": ROOM_HANDLER_COUNT,
        "runtime_handlers": RUNTIME_HANDLER_COUNT,
        "consumed_samples": len(selections),
        "unique_room_targets": len(set(room_handlers)),
        "unique_runtime_targets": len(set(runtime_handlers)),
        "room_target_counts": {
            f"0x{target:04X}": count
            for target, count in sorted(Counter(room_handlers).items())
        },
        "runtime_target_counts": {
            f"0x{target:04X}": count
            for target, count in sorted(Counter(runtime_handlers).items())
        },
        "synthetic_return": SYNTHETIC_RETURN_CPU,
        "pushed_return": SYNTHETIC_RETURN_CPU - 1,
    }


def build_report(image_path: Path) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    report = validate_rom_contract(prg)
    room_handlers = decode_pointer_table(
        _read_cpu_range(prg, ROOM_TABLE_CPU, ROOM_HANDLER_COUNT * 2)
    )
    runtime_handlers = decode_pointer_table(
        _read_cpu_range(prg, RUNTIME_TABLE_CPU, RUNTIME_HANDLER_COUNT * 2)
    )
    report["samples"] = {
        "empty_room_cell": asdict(
            select_collision_handler(0x53, room_handlers, runtime_handlers)
        ),
        "runtime_type_90": asdict(
            select_collision_handler(0x90, room_handlers, runtime_handlers)
        ),
    }
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image)
    except (OSError, PlayerCollisionDispatchError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated seven dispatch calls, 100 room handlers, "
            "41 runtime handlers, and the synthetic return"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
