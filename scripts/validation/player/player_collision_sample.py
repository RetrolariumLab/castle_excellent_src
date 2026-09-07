#!/usr/bin/env python3
"""Model the player room-cell/runtime-object sampler at $8DD3-$8ECA."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

from scripts.validation.collision import collision_tables
from scripts.validation.objects import object_collision_filters


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
ROUTINE_CPU = 0x8DD3
ROUTINE_END = 0x8ECB
SCREEN_Y_FIRST = 0x10
SCREEN_Y_END = 0xB0
ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_PIXEL_WIDTH = ROOM_WIDTH * 16
ROOM_PIXEL_HEIGHT = ROOM_HEIGHT * 8
ROOM_CELL_COUNT = ROOM_WIDTH * ROOM_HEIGHT
EMPTY_ROOM_CELL = 0x53
RECORD_SIZE = 6
RECORD_COUNT = 24
RECORD_BYTES = RECORD_SIZE * RECORD_COUNT
TYPE_FIRST = 0x80
TYPE_END = 0xA8
RESTRICTED_TYPE_FIRST = 0x90
RESTRICTED_TYPE_END = 0x96
SPECIAL_RUNTIME_TYPE = 0x86
SPECIAL_PHASE_THRESHOLD = 8
SPECIAL_BOTTOM_SPAN = 8
PAIR_INDEX_FIRST = 0x8A
PAIR_INDEX_END = 0x92
OFFSET_TABLE_CPU = 0x8F10
EXPECTED_OFFSET_TABLE = bytes(range(0, RECORD_BYTES + 1, RECORD_SIZE))
EXPECTED_CALL_SITES = (
    0x835C,
    0x8367,
    0x8371,
    0x83B7,
    0x83CF,
    0x83E6,
    0x856E,
    0x8584,
    0x8596,
    0x879A,
    0x87A9,
    0x87B8,
    0x87F5,
    0x8804,
    0x8813,
    0x886B,
    0x888C,
    0x88AD,
    0x88CD,
    0x88EE,
    0x890F,
    0x9394,
    0x939F,
    0x93AF,
    0x93BE,
    0x93CD,
    0x93D8,
    0x93E3,
)
EXPECTED_ROUTINE_BYTES = bytes.fromhex(
    "C0 10 90 10 C0 B0 B0 0C C9 00 F0 11 C9 01 D0 04 E0 40 90 09 "
    "18 A9 53 A2 00 8E CB 07 60 48 98 38 E9 10 A8 68 20 CB 8E A4 "
    "29 B1 2B C9 53 F0 29 AA A5 27 4A 4A 4A 4A 8A 2A AA BD 5A A9 "
    "F0 1A 20 CA A6 D0 06 A4 40 10 02 A9 00 48 A9 00 8D CB 07 68 "
    "48 4A 68 08 8A 4A 28 60 A0 00 84 1D A4 1D BE 10 8F 86 41 "
    "B5 4A F0 7D C9 A8 B0 79 CE CB 07 EE CB 07 F0 07 B5 4A 20 52 "
    "95 90 6A A8 A5 1B 38 F5 4D 90 62 F9 9A AA B0 5D C0 86 D0 "
    "1C 48 AD 6B 07 4A 4A 4A 4A C9 08 B0 0F 68 C9 F8 90 48 A5 "
    "3C F0 07 D0 42 68 4C B7 8E 68 A5 27 85 2B A5 28 85 2C A5 "
    "2B 38 F5 4B 85 2B A5 2C F5 4C 90 28 85 2C A5 2B F9 6A "
    "AA B0 1F A5 2C D0 1B B5 4A 20 91 A0 18 F0 01 38 B5 4A 20 "
    "5E A0 D0 01 18 B5 4A A0 00 8C CB 07 A0 01 60 E6 1D A5 1D "
    "C9 18 B0 03 4C 2F 8E 18 A9 53 A0 00 8C CB 07 60"
)


class PlayerCollisionSampleError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int = 0
    x: int = 0
    y: int = 0


@dataclass(frozen=True)
class PlayerCollisionSample:
    accumulator: int
    x_register: int
    y_register: int
    carry: bool
    negative: bool
    zero: bool
    source: str
    current_object_offset: int | None = None
    object_offset: int | None = None
    raw_collision_flags: int | None = None
    object_filter_active: int = 0


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise PlayerCollisionSampleError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise PlayerCollisionSampleError(f"{name} outside 0-65535: {value}")


def _validate_runtime_object(record: RuntimeObject) -> None:
    _validate_byte(record.runtime_type, "runtime type")
    _validate_word(record.x, "runtime object X")
    _validate_byte(record.y, "runtime object Y")
    if record.runtime_type and record.runtime_type < TYPE_FIRST:
        raise PlayerCollisionSampleError(
            "active runtime records must retain their high-bit type marker"
        )


def room_cell_index(screen_x: int, screen_y: int) -> int | None:
    _validate_word(screen_x, "screen X")
    _validate_byte(screen_y, "screen Y")
    if not 0 <= screen_x < ROOM_PIXEL_WIDTH:
        return None
    if not SCREEN_Y_FIRST <= screen_y < SCREEN_Y_END:
        return None
    room_y = screen_y - SCREEN_Y_FIRST
    return (room_y >> 3) * ROOM_WIDTH + (screen_x >> 4)


def _empty_sample(screen_y: int, x_register: int = 0) -> PlayerCollisionSample:
    return PlayerCollisionSample(
        accumulator=EMPTY_ROOM_CELL,
        x_register=x_register,
        y_register=screen_y,
        carry=False,
        negative=False,
        zero=True,
        source="empty",
    )


def _special_type_vertical_match(
    vertical_delta: int, room_frame_counter: int, player_motion_state: int
) -> bool:
    if (room_frame_counter >> 4) >= SPECIAL_PHASE_THRESHOLD:
        return True
    return vertical_delta >= SPECIAL_BOTTOM_SPAN and player_motion_state == 0


def sample_player_collision_at_screen_pixel(
    room_cells: bytes,
    records: tuple[RuntimeObject, ...],
    *,
    x: int,
    y: int,
    animation_counter: int = 0,
    object_filter_active: int = 0,
    room_frame_counter: int = 0,
    player_motion_state: int = 0,
) -> PlayerCollisionSample:
    if len(room_cells) != ROOM_CELL_COUNT:
        raise PlayerCollisionSampleError(
            f"room buffer has {len(room_cells)} bytes, expected {ROOM_CELL_COUNT}"
        )
    if any(cell >= collision_tables.ROOM_CELL_TYPE_COUNT for cell in room_cells):
        raise PlayerCollisionSampleError("room buffer contains a cell type above 99")
    if len(records) != RECORD_COUNT:
        raise PlayerCollisionSampleError(
            f"runtime pool has {len(records)} records, expected {RECORD_COUNT}"
        )
    for record in records:
        _validate_runtime_object(record)
    _validate_word(x, "screen X")
    _validate_byte(y, "screen Y")
    _validate_byte(animation_counter, "animation counter")
    _validate_byte(object_filter_active, "object filter")
    _validate_byte(room_frame_counter, "room frame counter")
    _validate_byte(player_motion_state, "player motion state")

    cell_index = room_cell_index(x, y)
    if cell_index is None:
        return _empty_sample(y)

    room_y = y - SCREEN_Y_FIRST
    cell = room_cells[cell_index]
    half = (x >> 3) & 1
    pair_index = cell * 2 + half
    raw_flags = collision_tables.EXPECTED_PLAYER_FLAGS[pair_index]
    if cell != EMPTY_ROOM_CELL and raw_flags:
        pair_matched = PAIR_INDEX_FIRST <= pair_index < PAIR_INDEX_END
        effective_flags = raw_flags
        y_register = 0xFF
        if pair_matched:
            y_register = animation_counter
            if animation_counter & 0x80:
                effective_flags = 0
        return PlayerCollisionSample(
            accumulator=cell,
            x_register=pair_index,
            y_register=y_register,
            carry=bool(effective_flags & 0x01),
            negative=bool(effective_flags & 0x80),
            zero=effective_flags == 0,
            source="room-cell",
            raw_collision_flags=raw_flags,
        )

    last_offset = 0
    for object_index, record in enumerate(records):
        object_offset = object_index * RECORD_SIZE
        last_offset = object_offset
        if not TYPE_FIRST <= record.runtime_type < TYPE_END:
            continue
        if object_filter_active and not (
            RESTRICTED_TYPE_FIRST <= record.runtime_type < RESTRICTED_TYPE_END
        ):
            continue
        type_index = record.runtime_type - TYPE_FIRST
        height = collision_tables.EXPECTED_HEIGHTS[type_index]
        width = collision_tables.EXPECTED_WIDTHS[type_index]
        if room_y < record.y:
            continue
        vertical_delta = room_y - record.y
        if vertical_delta >= height:
            continue
        if record.runtime_type == SPECIAL_RUNTIME_TYPE and not _special_type_vertical_match(
            vertical_delta, room_frame_counter, player_motion_state
        ):
            continue
        if x < record.x or x - record.x >= width:
            continue
        solid = bool(
            object_collision_filters.get_runtime_object_solid_flag(
                record.runtime_type
            )
        )
        pass_through = not bool(
            object_collision_filters.get_type84_to89_filter(record.runtime_type)
        )
        return PlayerCollisionSample(
            accumulator=record.runtime_type,
            x_register=object_offset,
            y_register=1,
            carry=solid and not pass_through,
            negative=False,
            zero=False,
            source="runtime-object",
            current_object_offset=object_offset,
            object_offset=object_offset,
        )
    return PlayerCollisionSample(
        accumulator=EMPTY_ROOM_CELL,
        x_register=last_offset,
        y_register=0,
        carry=False,
        negative=False,
        zero=True,
        source="empty",
        current_object_offset=last_offset,
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise PlayerCollisionSampleError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    prg_start = 16 + trainer_size
    prg_end = prg_start + prg_size
    if prg_size != PRG_SIZE or prg_end > len(image):
        raise PlayerCollisionSampleError("expected a complete 32 KiB PRG region")
    return image[prg_start:prg_end]


def _read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    result = prg[start:start + size]
    if len(result) != size:
        raise PlayerCollisionSampleError(f"truncated PRG range at ${address:04X}")
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
        raise PlayerCollisionSampleError("player collision-sampler bytes changed")
    if find_call_sites(prg) != EXPECTED_CALL_SITES:
        raise PlayerCollisionSampleError("player collision-sampler call sites changed")
    if _read_cpu_range(prg, OFFSET_TABLE_CPU, len(EXPECTED_OFFSET_TABLE)) != EXPECTED_OFFSET_TABLE:
        raise PlayerCollisionSampleError("runtime-object offset table changed")
    if _read_cpu_range(
        prg, collision_tables.PLAYER_FLAGS_CPU, collision_tables.ROOM_CELL_FLAG_COUNT
    ) != collision_tables.EXPECTED_PLAYER_FLAGS:
        raise PlayerCollisionSampleError("player collision-flag table changed")
    if _read_cpu_range(
        prg, collision_tables.OBJECT_WIDTHS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    ) != collision_tables.EXPECTED_WIDTHS:
        raise PlayerCollisionSampleError("runtime collision-width table changed")
    if _read_cpu_range(
        prg, collision_tables.OBJECT_HEIGHTS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    ) != collision_tables.EXPECTED_HEIGHTS:
        raise PlayerCollisionSampleError("runtime collision-height table changed")
    object_collision_filters.validate_rom_contract(prg)
    return {
        "routine_range": [ROUTINE_CPU, ROUTINE_END - 1],
        "routine_bytes": len(EXPECTED_ROUTINE_BYTES),
        "call_sites": list(EXPECTED_CALL_SITES),
        "screen_bounds": [ROOM_PIXEL_WIDTH, SCREEN_Y_FIRST, SCREEN_Y_END],
        "runtime_records": RECORD_COUNT,
    }


def validate_exhaustive_contract() -> dict[str, int]:
    empty_records = (RuntimeObject(),) * RECORD_COUNT
    empty_room = bytes([EMPTY_ROOM_CELL]) * ROOM_CELL_COUNT

    coordinate_cases = 0
    for room_y in range(ROOM_PIXEL_HEIGHT):
        screen_y = room_y + SCREEN_Y_FIRST
        for x in range(ROOM_PIXEL_WIDTH):
            expected = (room_y >> 3) * ROOM_WIDTH + (x >> 4)
            if room_cell_index(x, screen_y) != expected:
                raise PlayerCollisionSampleError("screen-to-room cell address mismatch")
            coordinate_cases += 1

    boundary_cases = 0
    for x in range(0x10000):
        expected = 0 if x < ROOM_PIXEL_WIDTH else None
        actual = room_cell_index(x, SCREEN_Y_FIRST)
        if (actual is not None) != (expected is not None):
            raise PlayerCollisionSampleError("16-bit horizontal boundary mismatch")
        boundary_cases += 1
    for screen_y in range(0x100):
        expected = SCREEN_Y_FIRST <= screen_y < SCREEN_Y_END
        if (room_cell_index(0, screen_y) is not None) != expected:
            raise PlayerCollisionSampleError("byte-wide vertical boundary mismatch")
        boundary_cases += 1

    cell_cases = 0
    for cell in range(collision_tables.ROOM_CELL_TYPE_COUNT):
        room = bytes([cell]) * ROOM_CELL_COUNT
        for half in (0, 1):
            for counter in (0x00, 0x80):
                result = sample_player_collision_at_screen_pixel(
                    room,
                    empty_records,
                    x=half * 8,
                    y=SCREEN_Y_FIRST,
                    animation_counter=counter,
                )
                raw = collision_tables.EXPECTED_PLAYER_FLAGS[cell * 2 + half]
                expected_room = cell != EMPTY_ROOM_CELL and raw != 0
                if (result.source == "room-cell") != expected_room:
                    raise PlayerCollisionSampleError("room-cell routing mismatch")
                if expected_room:
                    special = PAIR_INDEX_FIRST <= cell * 2 + half < PAIR_INDEX_END
                    effective = 0 if special and counter & 0x80 else raw
                    if result.carry != bool(effective & 1):
                        raise PlayerCollisionSampleError("room-cell carry mismatch")
                    if result.negative != bool(effective & 0x80):
                        raise PlayerCollisionSampleError("room-cell negative mismatch")
                cell_cases += 1

    runtime_type_cases = 0
    for runtime_type in range(TYPE_FIRST, TYPE_END):
        records = (RuntimeObject(runtime_type, 100, 50),) + empty_records[1:]
        result = sample_player_collision_at_screen_pixel(
            empty_room,
            records,
            x=100,
            y=50 + SCREEN_Y_FIRST,
            room_frame_counter=0x80,
        )
        if result.source != "runtime-object":
            raise PlayerCollisionSampleError("accepted runtime type did not match")
        expected_carry = bool(
            object_collision_filters.get_runtime_object_solid_flag(runtime_type)
            and object_collision_filters.get_type84_to89_filter(runtime_type)
        )
        if result.carry != expected_carry:
            raise PlayerCollisionSampleError("runtime-object carry mismatch")
        filtered = sample_player_collision_at_screen_pixel(
            empty_room,
            records,
            x=100,
            y=50 + SCREEN_Y_FIRST,
            object_filter_active=0xFF,
            room_frame_counter=0x80,
        )
        expected_match = RESTRICTED_TYPE_FIRST <= runtime_type < RESTRICTED_TYPE_END
        if (filtered.source == "runtime-object") != expected_match:
            raise PlayerCollisionSampleError("restricted runtime-type filter mismatch")
        runtime_type_cases += 2

    geometry_cases = 0
    record = RuntimeObject(TYPE_FIRST, 100, 50)
    records = (record,) + empty_records[1:]
    width = collision_tables.EXPECTED_WIDTHS[0]
    height = collision_tables.EXPECTED_HEIGHTS[0]
    for room_y in range(ROOM_PIXEL_HEIGHT):
        for x in range(ROOM_PIXEL_WIDTH):
            result = sample_player_collision_at_screen_pixel(
                empty_room, records, x=x, y=room_y + SCREEN_Y_FIRST
            )
            expected = 100 <= x < 100 + width and 50 <= room_y < 50 + height
            if (result.source == "runtime-object") != expected:
                raise PlayerCollisionSampleError("runtime-object geometry mismatch")
            geometry_cases += 1

    special_type_cases = 0
    height = collision_tables.EXPECTED_HEIGHTS[SPECIAL_RUNTIME_TYPE - TYPE_FIRST]
    for vertical_delta in range(height):
        records = (
            RuntimeObject(SPECIAL_RUNTIME_TYPE, 100, 50),
        ) + empty_records[1:]
        for frame in range(0x100):
            for motion in (0, 1):
                result = sample_player_collision_at_screen_pixel(
                    empty_room,
                    records,
                    x=100,
                    y=50 + vertical_delta + SCREEN_Y_FIRST,
                    room_frame_counter=frame,
                    player_motion_state=motion,
                )
                expected = _special_type_vertical_match(vertical_delta, frame, motion)
                if (result.source == "runtime-object") != expected:
                    raise PlayerCollisionSampleError("special type-$86 behavior mismatch")
                special_type_cases += 1

    slot_cases = 0
    for slot in range(RECORD_COUNT):
        records = [RuntimeObject()] * RECORD_COUNT
        records[slot] = RuntimeObject(TYPE_FIRST, 100, 50)
        result = sample_player_collision_at_screen_pixel(
            empty_room, tuple(records), x=100, y=50 + SCREEN_Y_FIRST
        )
        if result.object_offset != slot * RECORD_SIZE:
            raise PlayerCollisionSampleError("runtime-object scan order mismatch")
        slot_cases += 1
    return {
        "coordinate_cases": coordinate_cases,
        "boundary_cases": boundary_cases,
        "cell_cases": cell_cases,
        "runtime_type_cases": runtime_type_cases,
        "geometry_cases": geometry_cases,
        "special_type_cases": special_type_cases,
        "slot_cases": slot_cases,
    }


def build_report(image_path: Path, validate: bool) -> dict[str, object]:
    report: dict[str, object] = {
        "rom": validate_rom_contract(extract_prg(image_path.read_bytes()))
    }
    if validate:
        report["exhaustive"] = validate_exhaustive_contract()
    room = bytes([EMPTY_ROOM_CELL]) * ROOM_CELL_COUNT
    records = (RuntimeObject(TYPE_FIRST, 100, 50),) + (RuntimeObject(),) * 23
    report["sample"] = asdict(
        sample_player_collision_at_screen_pixel(
            room, records, x=100, y=50 + SCREEN_Y_FIRST
        )
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image, args.validate)
    except (OSError, PlayerCollisionSampleError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        cases = report["exhaustive"]
        print(
            "[OK] validated 28 call sites, 24 runtime slots, and "
            f"{sum(cases.values()):,} player collision cases"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
