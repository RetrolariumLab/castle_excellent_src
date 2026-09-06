#!/usr/bin/env python3
"""Model Castle Excellent's 24-record runtime-object frame dispatcher."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


INES_HEADER_SIZE = 16
PRG_START = 0x8000
PRG_SIZE = 0x8000
HANDLER_TABLE_ADDRESS = 0x95BF
HANDLER_COUNT = 42
RECORD_SIZE = 6
RECORD_COUNT = 24
RECORD_BYTES = RECORD_SIZE * RECORD_COUNT
TYPE_INDEX_MASK = 0x7F
VISIBLE_Y_LIMIT = 0xA0
PUSHABLE_UPDATE_ADDRESS = 0x965C
PUSHABLE_UPDATE_END = 0x9796
PUSHABLE_UPDATE_SHA256 = (
    "dc5f140df69220dde6eb596ba2075f4d3e17f2e6d8c11e5d6d1ddb7b31dc195b"
)
PUSHABLE_UPDATE_TYPES = (0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F)
PUSHABLE_COMMON_HANDLER = 0x9674
LIFT_CONTROL_HANDLER = 0x965C
COLLISION_SAMPLE_ADDRESS = 0x955D
EXPECTED_PUSHABLE_SAMPLE_CALLS = (
    0x9692,
    0x96AC,
    0x96C6,
    0x970E,
    0x9721,
    0x9745,
    0x9758,
)
LIFT_UPDATE_ADDRESS = 0x9796
LIFT_UPDATE_END = 0x9A37
LIFT_UPDATE_SHA256 = (
    "ddb252f79a8420c8f1a96d14ca8c70f79dc77f5672f8224d7cf88d6260260df3"
)
SMALL_LIFT_TYPE = 0xA1
LARGE_LIFT_TYPE = 0xA2
SMALL_LIFT_HANDLER = 0x9796
LARGE_LIFT_HANDLER = 0x9869
SMALL_LIFT_WIDTH = 0x10
LARGE_LIFT_WIDTH = 0x20
LIFT_TICK_MASK = 0x1F
LIFT_TICK_PHASE = 0x1F
LIFT_CELL_STEP = 8
LIFT_RISE_ALIGNMENT_MASK = 0xF8
PLAYER_SPAN_TEST_ADDRESS = 0x9613
RUNTIME_OVERLAP_SCAN_ADDRESS = 0xA247
EXPECTED_LIFT_PLAYER_SPAN_CALLS = (0x9855, 0x993D, 0x99B0)
EXPECTED_LIFT_OVERLAP_CALLS = (0x9996,)
FLYING_BLOCK_UPDATE_ADDRESS = 0x9A37
FLYING_BLOCK_UPDATE_END = 0x9B00
FLYING_BLOCK_UPDATE_SHA256 = (
    "fddfb50be8cec18c213cf7454cf438d9788387931892b20001f2eb657f995102"
)
FLYING_BLOCK_TYPE = 0xA3
FLYING_BLOCK_HANDLER = 0x9A37
FLYING_BLOCK_STEP = 2
FLYING_BLOCK_DIRECTION_RIGHT = 0x00
FLYING_BLOCK_DIRECTION_LEFT = 0xFF
FLYING_BLOCK_WORLD_X_END = 0x0140
FLYING_BLOCK_WORLD_Y_END = 0xA0
NORMALIZED_ROOM_COLLISION_ADDRESS = 0x955D
EXPECTED_FLYING_BLOCK_COLLISION_JUMPS = (0x9AB9, 0x9ACC, 0x9ADB, 0x9AEE)
DECREMENTING_ANIMATED_CELL_FIRST = 0x35
DECREMENTING_ANIMATED_CELL_END = 0x41
INCREMENTING_ANIMATED_CELL_FIRST = 0x56
INCREMENTING_ANIMATED_CELL_END = 0x62
PUSHABLE_STEP = 2
PUSHABLE_MOTION_RIGHT = 0x7F
PUSHABLE_MOTION_LEFT = 0xFF
EMPTY_ROOM_CELL = 0x53
CRUSHABLE_RUNTIME_TYPE_FIRST = 0x84
CRUSHABLE_RUNTIME_TYPE_END = 0x8A
EXPECTED_HANDLER_POINTERS = (
    0xA2A9,
    0x9CC6,
    0xA2A9,
    0xA2A9,
    0x9CD8,
    0x9B00,
    0xA2A9,
    0x9C3B,
    0x9ECB,
    0x9D65,
    0x9674,
    0x9674,
    0x9674,
    0x9674,
    0x965C,
    0x9674,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0xA2A9,
    0x9FF3,
    0x9796,
    0x9869,
    0x9A37,
    0xA2A9,
    0xA2A9,
    0x9F74,
    0xA2A9,
    0xA01C,
    0xA033,
)


class RuntimeObjectDispatchError(ValueError):
    pass


@dataclass(frozen=True)
class RuntimeObject:
    runtime_type: int
    y: int


@dataclass(frozen=True)
class ScheduledObjectUpdate:
    record_offset: int
    type_index: int
    handler: int


@dataclass(frozen=True)
class PushableMotion:
    x: int
    direction_latch: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RuntimeObjectDispatchError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise RuntimeObjectDispatchError(f"{name} outside 0-65535: {value}")


def pushable_conveyor_delta(cell: int) -> int:
    _validate_byte(cell, "room cell")
    if DECREMENTING_ANIMATED_CELL_FIRST <= cell < DECREMENTING_ANIMATED_CELL_END:
        return PUSHABLE_STEP
    if INCREMENTING_ANIMATED_CELL_FIRST <= cell < INCREMENTING_ANIMATED_CELL_END:
        return -PUSHABLE_STEP
    return 0


def move_pushable_on_conveyor(x: int, cell: int, edge_is_clear: bool) -> PushableMotion:
    _validate_word(x, "pushable X")
    delta = pushable_conveyor_delta(cell)
    if not delta or not edge_is_clear:
        return PushableMotion(x, 0)
    direction = PUSHABLE_MOTION_RIGHT if delta > 0 else PUSHABLE_MOTION_LEFT
    return PushableMotion((x + delta) & 0xFFFF, direction)


def advance_unsupported_pushable_y(y: int, supported: bool) -> int:
    _validate_byte(y, "pushable Y")
    if supported or y >= VISIBLE_Y_LIMIT:
        return y
    return (y + PUSHABLE_STEP) & 0xFF


def can_crush_support(collision: int, previous_collision: int) -> bool:
    _validate_byte(collision, "support collision")
    _validate_byte(previous_collision, "previous support collision")
    return (
        CRUSHABLE_RUNTIME_TYPE_FIRST <= collision < CRUSHABLE_RUNTIME_TYPE_END
        and previous_collision in (collision, EMPTY_ROOM_CELL)
    )


def lift_tick_due(room_frame_counter: int) -> bool:
    _validate_byte(room_frame_counter, "room frame counter")
    return room_frame_counter & LIFT_TICK_MASK == LIFT_TICK_PHASE


def lift_width(runtime_type: int) -> int:
    _validate_byte(runtime_type, "runtime type")
    widths = {
        SMALL_LIFT_TYPE: SMALL_LIFT_WIDTH,
        LARGE_LIFT_TYPE: LARGE_LIFT_WIDTH,
    }
    try:
        return widths[runtime_type]
    except KeyError as exc:
        raise RuntimeObjectDispatchError(
            f"runtime type ${runtime_type:02X} is not a lift"
        ) from exc


def runtime_object_slot_index(record_offset: int) -> int:
    if not 0 <= record_offset < RECORD_BYTES or record_offset % RECORD_SIZE:
        raise RuntimeObjectDispatchError(
            f"invalid runtime-object record offset: {record_offset}"
        )
    return record_offset // RECORD_SIZE


def rising_lift_occupant_y(y: int) -> int | None:
    _validate_byte(y, "lift occupant Y")
    if y < LIFT_CELL_STEP:
        return None
    return (y - 1) & LIFT_RISE_ALIGNMENT_MASK


def flying_block_probe_in_bounds(x: int, y: int) -> bool:
    _validate_word(x, "flying-block probe X")
    _validate_byte(y, "flying-block probe Y")
    return x < FLYING_BLOCK_WORLD_X_END and y < FLYING_BLOCK_WORLD_Y_END


def move_flying_block_x(x: int, direction: int) -> int:
    _validate_word(x, "flying-block X")
    if direction == FLYING_BLOCK_DIRECTION_RIGHT:
        return (x + FLYING_BLOCK_STEP) & 0xFFFF
    if direction == FLYING_BLOCK_DIRECTION_LEFT:
        return (x - FLYING_BLOCK_STEP) & 0xFFFF
    raise RuntimeObjectDispatchError(
        f"invalid flying-block direction: ${direction:02X}"
    )


def read_prg(image_path: Path) -> bytes:
    image = image_path.read_bytes()
    expected_size = INES_HEADER_SIZE + PRG_SIZE
    if len(image) < expected_size:
        raise RuntimeObjectDispatchError(
            f"image too short for 32 KiB PRG: {len(image)} bytes"
        )
    return image[INES_HEADER_SIZE:expected_size]


def decode_handler_pointers(prg: bytes) -> tuple[int, ...]:
    if len(prg) != PRG_SIZE:
        raise RuntimeObjectDispatchError(f"PRG must contain {PRG_SIZE} bytes")
    offset = HANDLER_TABLE_ADDRESS - PRG_START
    raw = prg[offset : offset + HANDLER_COUNT * 2]
    if len(raw) != HANDLER_COUNT * 2:
        raise RuntimeObjectDispatchError("truncated runtime-object handler table")
    return tuple(raw[index] | (raw[index + 1] << 8) for index in range(0, len(raw), 2))


def dispatch_handler(
    runtime_type: int,
    y: int,
    pointers: tuple[int, ...] = EXPECTED_HANDLER_POINTERS,
) -> tuple[int, int] | None:
    _validate_byte(runtime_type, "runtime type")
    _validate_byte(y, "runtime Y")
    if len(pointers) != HANDLER_COUNT:
        raise RuntimeObjectDispatchError(
            f"handler table must contain {HANDLER_COUNT} pointers"
        )
    type_index = runtime_type & TYPE_INDEX_MASK
    if type_index == 0 or y >= VISIBLE_Y_LIMIT:
        return None
    if type_index >= len(pointers):
        raise RuntimeObjectDispatchError(
            f"runtime type index ${type_index:02X} exceeds the handler table"
        )
    return type_index, pointers[type_index]


def schedule_runtime_objects(
    records: tuple[RuntimeObject, ...],
    pointers: tuple[int, ...] = EXPECTED_HANDLER_POINTERS,
) -> tuple[ScheduledObjectUpdate, ...]:
    if len(records) != RECORD_COUNT:
        raise RuntimeObjectDispatchError(
            f"runtime pool must contain {RECORD_COUNT} records"
        )
    scheduled: list[ScheduledObjectUpdate] = []
    for index, record in enumerate(records):
        selection = dispatch_handler(record.runtime_type, record.y, pointers)
        if selection is None:
            continue
        type_index, handler = selection
        scheduled.append(ScheduledObjectUpdate(index * RECORD_SIZE, type_index, handler))
    return tuple(scheduled)


def validate_runtime_object_dispatch(image_path: Path) -> dict[str, object]:
    prg = read_prg(image_path)
    pointers = decode_handler_pointers(prg)
    if pointers != EXPECTED_HANDLER_POINTERS:
        raise RuntimeObjectDispatchError("runtime-object handler table differs")
    dispatch_cases = 0
    skipped_cases = 0
    for type_index in range(HANDLER_COUNT):
        for high_bit in (0x00, 0x80):
            runtime_type = type_index | high_bit
            for y in (0x00, VISIBLE_Y_LIMIT - 1, VISIBLE_Y_LIMIT, 0xFF):
                selection = dispatch_handler(runtime_type, y, pointers)
                if type_index and y < VISIBLE_Y_LIMIT:
                    dispatch_cases += 1
                    if selection != (type_index, pointers[type_index]):
                        raise RuntimeObjectDispatchError("handler selection mismatch")
                else:
                    skipped_cases += 1
                    if selection is not None:
                        raise RuntimeObjectDispatchError("inactive object was dispatched")
    records = tuple(RuntimeObject(0x81 + index, index) for index in range(RECORD_COUNT))
    scheduled = schedule_runtime_objects(records, pointers)
    expected_offsets = tuple(range(0, RECORD_BYTES, RECORD_SIZE))
    if tuple(update.record_offset for update in scheduled) != expected_offsets:
        raise RuntimeObjectDispatchError("dispatcher did not walk all six-byte records")
    pushable_start = PUSHABLE_UPDATE_ADDRESS - PRG_START
    pushable = prg[pushable_start:pushable_start + PUSHABLE_UPDATE_END - PUSHABLE_UPDATE_ADDRESS]
    if hashlib.sha256(pushable).hexdigest() != PUSHABLE_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("pushable-object update range changed")
    pushable_handlers = tuple(
        pointers[runtime_type & TYPE_INDEX_MASK] for runtime_type in PUSHABLE_UPDATE_TYPES
    )
    if pushable_handlers != (
        PUSHABLE_COMMON_HANDLER,
        PUSHABLE_COMMON_HANDLER,
        PUSHABLE_COMMON_HANDLER,
        PUSHABLE_COMMON_HANDLER,
        LIFT_CONTROL_HANDLER,
        PUSHABLE_COMMON_HANDLER,
    ):
        raise RuntimeObjectDispatchError("pushable-object handler topology changed")
    sample_opcode = bytes(
        (0x20, COLLISION_SAMPLE_ADDRESS & 0xFF, COLLISION_SAMPLE_ADDRESS >> 8)
    )
    sample_calls = tuple(
        PUSHABLE_UPDATE_ADDRESS + offset
        for offset in range(len(pushable) - 2)
        if pushable[offset:offset + 3] == sample_opcode
    )
    if sample_calls != EXPECTED_PUSHABLE_SAMPLE_CALLS:
        raise RuntimeObjectDispatchError("pushable collision-sample calls changed")
    lift_start = LIFT_UPDATE_ADDRESS - PRG_START
    lift = prg[lift_start:lift_start + LIFT_UPDATE_END - LIFT_UPDATE_ADDRESS]
    if hashlib.sha256(lift).hexdigest() != LIFT_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("lift update range changed")
    if pointers[SMALL_LIFT_TYPE & TYPE_INDEX_MASK] != SMALL_LIFT_HANDLER:
        raise RuntimeObjectDispatchError("small-lift handler pointer changed")
    if pointers[LARGE_LIFT_TYPE & TYPE_INDEX_MASK] != LARGE_LIFT_HANDLER:
        raise RuntimeObjectDispatchError("large-lift handler pointer changed")

    def call_sites(target: int) -> tuple[int, ...]:
        opcode = bytes((0x20, target & 0xFF, target >> 8))
        return tuple(
            LIFT_UPDATE_ADDRESS + offset
            for offset in range(len(lift) - 2)
            if lift[offset:offset + 3] == opcode
        )

    player_span_calls = call_sites(PLAYER_SPAN_TEST_ADDRESS)
    if player_span_calls != EXPECTED_LIFT_PLAYER_SPAN_CALLS:
        raise RuntimeObjectDispatchError("lift player-span calls changed")
    overlap_calls = call_sites(RUNTIME_OVERLAP_SCAN_ADDRESS)
    if overlap_calls != EXPECTED_LIFT_OVERLAP_CALLS:
        raise RuntimeObjectDispatchError("lift runtime-overlap calls changed")
    flying_start = FLYING_BLOCK_UPDATE_ADDRESS - PRG_START
    flying_block = prg[
        flying_start:flying_start + FLYING_BLOCK_UPDATE_END - FLYING_BLOCK_UPDATE_ADDRESS
    ]
    if hashlib.sha256(flying_block).hexdigest() != FLYING_BLOCK_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("flying-block update range changed")
    if pointers[FLYING_BLOCK_TYPE & TYPE_INDEX_MASK] != FLYING_BLOCK_HANDLER:
        raise RuntimeObjectDispatchError("flying-block handler pointer changed")
    collision_jump = bytes(
        (
            0x4C,
            NORMALIZED_ROOM_COLLISION_ADDRESS & 0xFF,
            NORMALIZED_ROOM_COLLISION_ADDRESS >> 8,
        )
    )
    collision_jumps = tuple(
        FLYING_BLOCK_UPDATE_ADDRESS + offset
        for offset in range(len(flying_block) - 2)
        if flying_block[offset:offset + 3] == collision_jump
    )
    if collision_jumps != EXPECTED_FLYING_BLOCK_COLLISION_JUMPS:
        raise RuntimeObjectDispatchError("flying-block collision jumps changed")
    return {
        "handler_table_address": HANDLER_TABLE_ADDRESS,
        "handler_count": len(pointers),
        "unique_handlers": len(set(pointers)),
        "record_count": RECORD_COUNT,
        "record_size": RECORD_SIZE,
        "record_offsets": list(expected_offsets),
        "dispatch_cases_checked": dispatch_cases,
        "skipped_cases_checked": skipped_cases,
        "pushable_update_range": [PUSHABLE_UPDATE_ADDRESS, PUSHABLE_UPDATE_END - 1],
        "pushable_update_bytes": len(pushable),
        "pushable_types": list(PUSHABLE_UPDATE_TYPES),
        "pushable_sample_calls": list(sample_calls),
        "lift_update_range": [LIFT_UPDATE_ADDRESS, LIFT_UPDATE_END - 1],
        "lift_update_bytes": len(lift),
        "lift_types": [SMALL_LIFT_TYPE, LARGE_LIFT_TYPE],
        "lift_player_span_calls": list(player_span_calls),
        "lift_overlap_calls": list(overlap_calls),
        "flying_block_update_range": [
            FLYING_BLOCK_UPDATE_ADDRESS,
            FLYING_BLOCK_UPDATE_END - 1,
        ],
        "flying_block_update_bytes": len(flying_block),
        "flying_block_collision_jumps": list(collision_jumps),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    try:
        document = validate_runtime_object_dispatch(args.image)
    except (OSError, RuntimeObjectDispatchError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if args.pretty:
        print(json.dumps(document, indent=2))
    else:
        print(
            "[OK] validated 24-record runtime-object dispatch and "
            f"{document['handler_count']} handler pointers, including the "
            f"{document['pushable_update_bytes']}-byte pushable/lift-control and "
            f"{document['lift_update_bytes']}-byte lift and "
            f"{document['flying_block_update_bytes']}-byte flying-block slices"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
