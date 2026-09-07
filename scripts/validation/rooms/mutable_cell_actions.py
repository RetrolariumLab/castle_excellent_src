#!/usr/bin/env python3
"""Model inventory-backed persistent mutable-cell actions at $A5DD-$A66C."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
COLLISION_HANDLER_TABLE_CPU = 0x9155
MUTABLE_ACTION_PROBE_Y_OFFSET = 0x10
MOTION_INACTIVE_THRESHOLD = 0x21
ACTION_ALIGNMENT_MASK = 0x0F
ACTION_ALIGNED_REMAINDER = 0x08
LEFT_BOUNDARY_X = 0x0011
RIGHT_BOUNDARY_X = 0x0120
BOUNDARY_DELAY_FRAMES = 9
ACTION_CALL_ORDER = (
    "ConvertPixelPositionToTileCoordinates",
    "FindMutableCellOrdinalAtPosition",
    "RestoreMutableCellByOrdinal",
    "StartMutableCellOpenSoundEffect",
)


class MutableCellActionError(ValueError):
    pass


@dataclass(frozen=True)
class MutableCellActionEntry:
    anchor_cell: int
    paired_cell: int
    inventory_index: int
    handler: int


@dataclass(frozen=True)
class MutableCellActionResult:
    applied: bool
    inventory_count: int
    probe_y: int
    movement_delay: int
    calls: tuple[str, ...]


ACTION_ENTRIES = (
    MutableCellActionEntry(0x19, 0x1A, 4, 0xA5DD),
    MutableCellActionEntry(0x1C, 0x1D, 3, 0xA5E7),
    MutableCellActionEntry(0x1F, 0x20, 5, 0xA5F1),
    MutableCellActionEntry(0x22, 0x23, 2, 0xA5FB),
    MutableCellActionEntry(0x25, 0x26, 0, 0xA605),
    MutableCellActionEntry(0x29, 0x2A, 1, 0xA60F),
)
STATIC_CODE_RANGES = tuple(
    (entry.handler, ACTION_ENTRIES[index + 1].handler - 1)
    if index + 1 < len(ACTION_ENTRIES)
    else (entry.handler, 0xA615)
    for index, entry in enumerate(ACTION_ENTRIES)
)


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise MutableCellActionError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise MutableCellActionError(f"{name} outside 0-65535: {value}")


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise MutableCellActionError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise MutableCellActionError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def cpu_offset(address: int) -> int:
    if not PRG_BASE <= address <= 0xFFFF:
        raise MutableCellActionError(f"CPU address outside PRG: ${address:04X}")
    return address - PRG_BASE


def normalize_player_motion_state(motion_state: int) -> int:
    _validate_byte(motion_state, "player motion state")
    if motion_state >= MOTION_INACTIVE_THRESHOLD:
        return 0
    return motion_state


def mutable_cell_action_ready(
    inventory_count: int,
    motion_state: int,
    motion_phase: int,
    player_y: int,
) -> bool:
    _validate_byte(inventory_count, "inventory count")
    _validate_byte(motion_phase, "player motion phase")
    _validate_byte(player_y, "player Y")
    return (
        inventory_count != 0
        and (normalize_player_motion_state(motion_state) | motion_phase) == 0
        and (player_y & ACTION_ALIGNMENT_MASK) == ACTION_ALIGNED_REMAINDER
    )


def needs_boundary_movement_delay(direction: int, player_x: int) -> bool:
    _validate_byte(direction, "player direction")
    _validate_word(player_x, "player X")
    if direction & 0x80:
        return player_x < LEFT_BOUNDARY_X
    return player_x >= RIGHT_BOUNDARY_X


def apply_mutable_cell_action(
    *,
    inventory_count: int,
    motion_state: int,
    motion_phase: int,
    player_y: int,
    probe_y: int,
    direction: int,
    player_x: int,
    movement_delay: int,
) -> MutableCellActionResult:
    _validate_byte(probe_y, "collision probe Y")
    _validate_byte(movement_delay, "movement delay")
    ready = mutable_cell_action_ready(
        inventory_count, motion_state, motion_phase, player_y
    )
    if not ready:
        return MutableCellActionResult(
            False, inventory_count, probe_y, movement_delay, ()
        )
    delay = movement_delay
    if needs_boundary_movement_delay(direction, player_x):
        delay = BOUNDARY_DELAY_FRAMES
    return MutableCellActionResult(
        True,
        inventory_count - 1,
        (probe_y - MUTABLE_ACTION_PROBE_Y_OFFSET) & 0xFF,
        delay,
        ACTION_CALL_ORDER,
    )


def expected_handler_bytes(index: int) -> bytes:
    if not 0 <= index < len(ACTION_ENTRIES):
        raise MutableCellActionError(f"handler index outside 0-5: {index}")
    inventory_address = 0x05 + ACTION_ENTRIES[index].inventory_index
    encoded = bytearray((0xA5, inventory_address, 0x20, 0x58, 0xA6))
    encoded.extend((0xC6, inventory_address))
    if index + 1 < len(ACTION_ENTRIES):
        encoded.extend((0x4C, 0x16, 0xA6))
    return bytes(encoded)


def load_static_code_ranges(path: Path) -> tuple[tuple[int, int], ...]:
    ranges: list[tuple[int, int]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fields = raw.split()
        if not fields or fields[0].startswith("#"):
            continue
        if len(fields) != 3 or fields[0] != "code":
            raise MutableCellActionError(
                f"invalid static code evidence at {path}:{line_number}"
            )
        ranges.append((int(fields[1], 16), int(fields[2], 16)))
    return tuple(ranges)


def mutable_action_static_ranges(
    ranges: tuple[tuple[int, int], ...],
) -> tuple[tuple[int, int], ...]:
    start = STATIC_CODE_RANGES[0][0]
    end = STATIC_CODE_RANGES[-1][1]
    return tuple(item for item in ranges if max(item[0], start) <= min(item[1], end))


def validate_rom_contract(prg: bytes, static_evidence: Path) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise MutableCellActionError(f"PRG has {len(prg)} bytes, expected {PRG_SIZE}")
    pointer_pairs = 0
    for index, entry in enumerate(ACTION_ENTRIES):
        for cell in (entry.anchor_cell, entry.paired_cell):
            at = cpu_offset(COLLISION_HANDLER_TABLE_CPU) + cell * 2
            pointer = prg[at] | (prg[at + 1] << 8)
            if pointer != entry.handler:
                raise MutableCellActionError(
                    f"cell ${cell:02X} points to ${pointer:04X}, "
                    f"expected ${entry.handler:04X}"
                )
            pointer_pairs += 1
        encoded = expected_handler_bytes(index)
        at = cpu_offset(entry.handler)
        if prg[at:at + len(encoded)] != encoded:
            raise MutableCellActionError(
                f"mutable-cell handler ${entry.handler:04X} bytes changed"
            )
    observed_ranges = mutable_action_static_ranges(
        load_static_code_ranges(static_evidence)
    )
    if observed_ranges != STATIC_CODE_RANGES:
        raise MutableCellActionError(
            f"static code evidence {observed_ranges!r} does not match handlers"
        )
    return {
        "actions": [asdict(entry) for entry in ACTION_ENTRIES],
        "collision_table_pointer_entries": pointer_pairs,
        "static_code_ranges": [list(item) for item in observed_ranges],
        "handler_bytes": sum(len(expected_handler_bytes(i)) for i in range(6)),
    }


def validate_exhaustive_contract() -> dict[str, int]:
    for motion_state in range(0x100):
        expected_motion = motion_state if motion_state < MOTION_INACTIVE_THRESHOLD else 0
        if normalize_player_motion_state(motion_state) != expected_motion:
            raise MutableCellActionError("motion-state normalization mismatch")
        for motion_phase in range(0x100):
            expected = (expected_motion | motion_phase) == 0
            if mutable_cell_action_ready(1, motion_state, motion_phase, 0x08) != expected:
                raise MutableCellActionError("motion readiness mismatch")
            if mutable_cell_action_ready(1, motion_state, motion_phase, 0x07):
                raise MutableCellActionError("misaligned player passed readiness guard")
    for inventory_count in range(0x100):
        if mutable_cell_action_ready(inventory_count, 0, 0, 0x08) != (
            inventory_count != 0
        ):
            raise MutableCellActionError("inventory readiness mismatch")
    for player_y in range(0x100):
        expected = (player_y & ACTION_ALIGNMENT_MASK) == ACTION_ALIGNED_REMAINDER
        if mutable_cell_action_ready(1, 0, 0, player_y) != expected:
            raise MutableCellActionError("vertical alignment mismatch")
    boundary_cases = 0
    for direction in (0x00, 0x7F, 0x80, 0xFF):
        for player_x in range(0x10000):
            expected = (
                player_x < LEFT_BOUNDARY_X
                if direction & 0x80
                else player_x >= RIGHT_BOUNDARY_X
            )
            if needs_boundary_movement_delay(direction, player_x) != expected:
                raise MutableCellActionError("boundary-delay mismatch")
            boundary_cases += 1
    for direction in range(0x100):
        for player_x in (0, 0x10, 0x11, 0x011F, 0x0120, 0xFFFF):
            expected = (
                player_x < LEFT_BOUNDARY_X
                if direction & 0x80
                else player_x >= RIGHT_BOUNDARY_X
            )
            if needs_boundary_movement_delay(direction, player_x) != expected:
                raise MutableCellActionError("direction-sign mismatch")
            boundary_cases += 1
    for probe_y in range(0x100):
        result = apply_mutable_cell_action(
            inventory_count=1,
            motion_state=0,
            motion_phase=0,
            player_y=0x08,
            probe_y=probe_y,
            direction=0,
            player_x=0,
            movement_delay=0xA5,
        )
        if result.probe_y != (probe_y - MUTABLE_ACTION_PROBE_Y_OFFSET) & 0xFF:
            raise MutableCellActionError("probe-Y subtraction mismatch")
        if result.movement_delay != 0xA5 or result.calls != ACTION_CALL_ORDER:
            raise MutableCellActionError("successful action side effects changed")
    return {
        "motion_phase_cases": 0x20000,
        "inventory_cases": 0x100,
        "alignment_cases": 0x100,
        "boundary_cases": boundary_cases,
        "probe_y_cases": 0x100,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument(
        "--static-evidence", default="config/reconstruction/static_code_evidence.txt"
    )
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        prg = extract_prg(Path(args.image).read_bytes())
        document = validate_rom_contract(prg, Path(args.static_evidence))
        document["exhaustive"] = validate_exhaustive_contract()
    except (OSError, MutableCellActionError, ValueError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated six inventory-backed mutable-cell actions, "
            "12 collision pointers, and all readiness/boundary byte domains"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
