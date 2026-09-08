#!/usr/bin/env python3
"""Model Castle Excellent's 24-record runtime-object frame dispatcher."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import sys


from scripts.validation.objects.runtime_object_dispatch_contract import (
    INES_HEADER_SIZE, PRG_START, PRG_SIZE, HANDLER_TABLE_ADDRESS, HANDLER_COUNT,
    RECORD_SIZE, RECORD_COUNT, RECORD_BYTES, TYPE_INDEX_MASK, VISIBLE_Y_LIMIT,
    LINKED_LIFT_CONTROL_ADDRESS, LINKED_LIFT_CONTROL_END, LINKED_LIFT_CONTROL_SHA256,
    LINKED_LIFT_PLAYER_PUSH_ADDRESS, LINKED_LIFT_ROOM_UPDATE_ADDRESS,
    LINKED_LIFT_NORMALIZED_COLLISION_ADDRESS, LINKED_LIFT_RUNTIME_OVERLAP_ADDRESS,
    LINKED_LIFT_ROOM_COLLISION_ADDRESS, EXPECTED_LINKED_LIFT_PLAYER_PUSH_CALLS,
    EXPECTED_LINKED_LIFT_ROOM_UPDATE_CALLS,
    EXPECTED_LINKED_LIFT_NORMALIZED_COLLISION_CALLS, EXPECTED_LINKED_LIFT_OVERLAP_CALLS,
    EXPECTED_LINKED_LIFT_ROOM_COLLISION_CALLS, PUSHABLE_UPDATE_ADDRESS,
    PUSHABLE_UPDATE_END, PUSHABLE_UPDATE_SHA256, PUSHABLE_UPDATE_TYPES,
    PUSHABLE_COMMON_HANDLER, LIFT_CONTROL_HANDLER, COLLISION_SAMPLE_ADDRESS,
    EXPECTED_PUSHABLE_SAMPLE_CALLS, LIFT_UPDATE_ADDRESS, LIFT_UPDATE_END,
    LIFT_UPDATE_SHA256, SMALL_LIFT_TYPE, LARGE_LIFT_TYPE, SMALL_LIFT_HANDLER,
    LARGE_LIFT_HANDLER, SMALL_LIFT_WIDTH, LARGE_LIFT_WIDTH, LIFT_TICK_MASK,
    LIFT_TICK_PHASE, LIFT_CELL_STEP, LIFT_RISE_ALIGNMENT_MASK, PLAYER_SPAN_TEST_ADDRESS,
    RUNTIME_OVERLAP_SCAN_ADDRESS, EXPECTED_LIFT_PLAYER_SPAN_CALLS,
    EXPECTED_LIFT_OVERLAP_CALLS, FLYING_BLOCK_UPDATE_ADDRESS, FLYING_BLOCK_UPDATE_END,
    FLYING_BLOCK_UPDATE_SHA256, FLYING_BLOCK_TYPE, FLYING_BLOCK_HANDLER, FLYING_BLOCK_STEP,
    FLYING_BLOCK_DIRECTION_RIGHT, FLYING_BLOCK_DIRECTION_LEFT, FLYING_BLOCK_WORLD_X_END,
    FLYING_BLOCK_WORLD_Y_END, NORMALIZED_ROOM_COLLISION_ADDRESS,
    EXPECTED_FLYING_BLOCK_COLLISION_JUMPS, WALKING_ENEMY_UPDATE_ADDRESS,
    WALKING_ENEMY_UPDATE_END, WALKING_ENEMY_UPDATE_SHA256, BISHOP_TYPE, BISHOP_HANDLER,
    COLLISION_POINT_SAMPLE_ADDRESS, DESTROY_OBJECT_WITH_SOUND_ADDRESS,
    EXPECTED_WALKING_ENEMY_COLLISION_CALLS, EXPECTED_WALKING_ENEMY_DESTROY_JUMPS,
    KNIGHT_UPDATE_ADDRESS, KNIGHT_UPDATE_END, KNIGHT_UPDATE_SHA256, KNIGHT_TYPE,
    KNIGHT_HANDLER, ARROW_TYPE, ARROW_HANDLER, EXPECTED_KNIGHT_WALKING_PHYSICS_CALLS,
    FAIRY_FIGHTER_UPDATE_ADDRESS, FAIRY_FIGHTER_UPDATE_END, FAIRY_FIGHTER_UPDATE_SHA256,
    FAIRY_TYPE, FAIRY_HANDLER, FIGHTER_TYPE, FIGHTER_HANDLER,
    EXPECTED_FIGHTER_COLLISION_CALLS, EXPECTED_FIGHTER_WALKING_PHYSICS_TRANSFERS,
    FLAME_HELPERS_ADDRESS, FLAME_HELPERS_END, FLAME_HELPERS_SHA256, FLAME_TYPE,
    FLAME_HANDLER, START_FLAME_SOUND_ADDRESS, EXPECTED_FLAME_COLLISION_CALLS,
    EXPECTED_FLAME_SOUND_CALLS, WITCH_UPDATE_ADDRESS, WITCH_UPDATE_END,
    WITCH_UPDATE_SHA256, WITCH_TYPE, WITCH_HANDLER, WITCH_SUMMON_TYPE,
    WITCH_SUMMON_HANDLER, EXPECTED_WITCH_COLLISION_CALLS,
    EXPECTED_WITCH_WALKING_PHYSICS_CALLS, KNIGHT_ARROW_UPDATE_ADDRESS,
    KNIGHT_ARROW_UPDATE_END, KNIGHT_ARROW_UPDATE_SHA256,
    CLEAR_CURRENT_RUNTIME_OBJECT_ADDRESS, EXPECTED_KNIGHT_ARROW_COLLISION_CALLS,
    EXPECTED_KNIGHT_ARROW_CLEAR_JUMPS, DECREMENTING_ANIMATED_CELL_FIRST,
    DECREMENTING_ANIMATED_CELL_END, INCREMENTING_ANIMATED_CELL_FIRST,
    INCREMENTING_ANIMATED_CELL_END, PUSHABLE_STEP, PUSHABLE_MOTION_RIGHT,
    PUSHABLE_MOTION_LEFT, EMPTY_ROOM_CELL, CRUSHABLE_RUNTIME_TYPE_FIRST,
    CRUSHABLE_RUNTIME_TYPE_END, EXPECTED_HANDLER_POINTERS,
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
    linked_lift_start = LINKED_LIFT_CONTROL_ADDRESS - PRG_START
    linked_lift = prg[
        linked_lift_start:
        linked_lift_start + LINKED_LIFT_CONTROL_END - LINKED_LIFT_CONTROL_ADDRESS
    ]
    if hashlib.sha256(linked_lift).hexdigest() != LINKED_LIFT_CONTROL_SHA256:
        raise RuntimeObjectDispatchError("linked-lift control range changed")

    def linked_lift_call_sites(target: int) -> tuple[int, ...]:
        opcode = bytes((0x20, target & 0xFF, target >> 8))
        return tuple(
            LINKED_LIFT_CONTROL_ADDRESS + offset
            for offset in range(len(linked_lift) - 2)
            if linked_lift[offset:offset + 3] == opcode
        )

    linked_lift_player_push_calls = linked_lift_call_sites(
        LINKED_LIFT_PLAYER_PUSH_ADDRESS
    )
    if linked_lift_player_push_calls != EXPECTED_LINKED_LIFT_PLAYER_PUSH_CALLS:
        raise RuntimeObjectDispatchError("linked-lift player-push call changed")
    linked_lift_room_update_calls = linked_lift_call_sites(
        LINKED_LIFT_ROOM_UPDATE_ADDRESS
    )
    if linked_lift_room_update_calls != EXPECTED_LINKED_LIFT_ROOM_UPDATE_CALLS:
        raise RuntimeObjectDispatchError("linked-lift room-update calls changed")
    linked_lift_collision_calls = linked_lift_call_sites(
        LINKED_LIFT_NORMALIZED_COLLISION_ADDRESS
    )
    if (
        linked_lift_collision_calls
        != EXPECTED_LINKED_LIFT_NORMALIZED_COLLISION_CALLS
    ):
        raise RuntimeObjectDispatchError("linked-lift clearance calls changed")
    linked_lift_overlap_calls = linked_lift_call_sites(
        LINKED_LIFT_RUNTIME_OVERLAP_ADDRESS
    )
    if linked_lift_overlap_calls != EXPECTED_LINKED_LIFT_OVERLAP_CALLS:
        raise RuntimeObjectDispatchError("linked-lift overlap call changed")
    linked_lift_room_collision_calls = linked_lift_call_sites(
        LINKED_LIFT_ROOM_COLLISION_ADDRESS
    )
    if (
        linked_lift_room_collision_calls
        != EXPECTED_LINKED_LIFT_ROOM_COLLISION_CALLS
    ):
        raise RuntimeObjectDispatchError("linked-lift ceiling calls changed")
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
    walking_start = WALKING_ENEMY_UPDATE_ADDRESS - PRG_START
    walking_enemy = prg[
        walking_start:walking_start + WALKING_ENEMY_UPDATE_END - WALKING_ENEMY_UPDATE_ADDRESS
    ]
    if hashlib.sha256(walking_enemy).hexdigest() != WALKING_ENEMY_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("walking-enemy update range changed")
    if pointers[BISHOP_TYPE & TYPE_INDEX_MASK] != BISHOP_HANDLER:
        raise RuntimeObjectDispatchError("Bishop handler pointer changed")
    collision_call = bytes(
        (
            0x20,
            COLLISION_POINT_SAMPLE_ADDRESS & 0xFF,
            COLLISION_POINT_SAMPLE_ADDRESS >> 8,
        )
    )
    walking_collision_calls = tuple(
        WALKING_ENEMY_UPDATE_ADDRESS + offset
        for offset in range(len(walking_enemy) - 2)
        if walking_enemy[offset:offset + 3] == collision_call
    )
    if walking_collision_calls != EXPECTED_WALKING_ENEMY_COLLISION_CALLS:
        raise RuntimeObjectDispatchError("walking-enemy collision calls changed")
    destroy_jump = bytes(
        (
            0x4C,
            DESTROY_OBJECT_WITH_SOUND_ADDRESS & 0xFF,
            DESTROY_OBJECT_WITH_SOUND_ADDRESS >> 8,
        )
    )
    walking_destroy_jumps = tuple(
        WALKING_ENEMY_UPDATE_ADDRESS + offset
        for offset in range(len(walking_enemy) - 2)
        if walking_enemy[offset:offset + 3] == destroy_jump
    )
    if walking_destroy_jumps != EXPECTED_WALKING_ENEMY_DESTROY_JUMPS:
        raise RuntimeObjectDispatchError("walking-enemy destruction jumps changed")
    knight_start = KNIGHT_UPDATE_ADDRESS - PRG_START
    knight = prg[knight_start:knight_start + KNIGHT_UPDATE_END - KNIGHT_UPDATE_ADDRESS]
    if hashlib.sha256(knight).hexdigest() != KNIGHT_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("Knight update range changed")
    if pointers[KNIGHT_TYPE & TYPE_INDEX_MASK] != KNIGHT_HANDLER:
        raise RuntimeObjectDispatchError("Knight handler pointer changed")
    if pointers[ARROW_TYPE & TYPE_INDEX_MASK] != ARROW_HANDLER:
        raise RuntimeObjectDispatchError("arrow handler pointer changed")
    walking_physics_call = bytes(
        (
            0x20,
            WALKING_ENEMY_UPDATE_ADDRESS & 0xFF,
            WALKING_ENEMY_UPDATE_ADDRESS >> 8,
        )
    )
    knight_walking_physics_calls = tuple(
        KNIGHT_UPDATE_ADDRESS + offset
        for offset in range(len(knight) - 2)
        if knight[offset:offset + 3] == walking_physics_call
    )
    if knight_walking_physics_calls != EXPECTED_KNIGHT_WALKING_PHYSICS_CALLS:
        raise RuntimeObjectDispatchError("Knight walking-physics calls changed")
    fairy_fighter_start = FAIRY_FIGHTER_UPDATE_ADDRESS - PRG_START
    fairy_fighter = prg[
        fairy_fighter_start:
        fairy_fighter_start + FAIRY_FIGHTER_UPDATE_END - FAIRY_FIGHTER_UPDATE_ADDRESS
    ]
    if hashlib.sha256(fairy_fighter).hexdigest() != FAIRY_FIGHTER_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("Fairy/Fighter update range changed")
    if pointers[FAIRY_TYPE & TYPE_INDEX_MASK] != FAIRY_HANDLER:
        raise RuntimeObjectDispatchError("Fairy handler pointer changed")
    if pointers[FIGHTER_TYPE & TYPE_INDEX_MASK] != FIGHTER_HANDLER:
        raise RuntimeObjectDispatchError("Fighter handler pointer changed")
    fighter_collision_calls = tuple(
        FAIRY_FIGHTER_UPDATE_ADDRESS + offset
        for offset in range(len(fairy_fighter) - 2)
        if fairy_fighter[offset:offset + 3] == collision_call
    )
    if fighter_collision_calls != EXPECTED_FIGHTER_COLLISION_CALLS:
        raise RuntimeObjectDispatchError("Fighter collision calls changed")
    walking_physics_target = bytes(
        (WALKING_ENEMY_UPDATE_ADDRESS & 0xFF, WALKING_ENEMY_UPDATE_ADDRESS >> 8)
    )
    fighter_walking_physics_transfers = tuple(
        FAIRY_FIGHTER_UPDATE_ADDRESS + offset
        for offset in range(len(fairy_fighter) - 2)
        if fairy_fighter[offset] in (0x20, 0x4C)
        and fairy_fighter[offset + 1:offset + 3] == walking_physics_target
    )
    if fighter_walking_physics_transfers != EXPECTED_FIGHTER_WALKING_PHYSICS_TRANSFERS:
        raise RuntimeObjectDispatchError("Fighter walking-physics transfers changed")
    flame_start = FLAME_HELPERS_ADDRESS - PRG_START
    flame_helpers = prg[
        flame_start:flame_start + FLAME_HELPERS_END - FLAME_HELPERS_ADDRESS
    ]
    if hashlib.sha256(flame_helpers).hexdigest() != FLAME_HELPERS_SHA256:
        raise RuntimeObjectDispatchError("Flame/helper update range changed")
    if pointers[FLAME_TYPE & TYPE_INDEX_MASK] != FLAME_HANDLER:
        raise RuntimeObjectDispatchError("Flame handler pointer changed")
    flame_collision_calls = tuple(
        FLAME_HELPERS_ADDRESS + offset
        for offset in range(len(flame_helpers) - 2)
        if flame_helpers[offset:offset + 3] == collision_call
    )
    if flame_collision_calls != EXPECTED_FLAME_COLLISION_CALLS:
        raise RuntimeObjectDispatchError("Flame/helper collision calls changed")
    flame_sound_call = bytes(
        (0x20, START_FLAME_SOUND_ADDRESS & 0xFF, START_FLAME_SOUND_ADDRESS >> 8)
    )
    flame_sound_calls = tuple(
        FLAME_HELPERS_ADDRESS + offset
        for offset in range(len(flame_helpers) - 2)
        if flame_helpers[offset:offset + 3] == flame_sound_call
    )
    if flame_sound_calls != EXPECTED_FLAME_SOUND_CALLS:
        raise RuntimeObjectDispatchError("Flame sound call changed")
    witch_start = WITCH_UPDATE_ADDRESS - PRG_START
    witch = prg[witch_start:witch_start + WITCH_UPDATE_END - WITCH_UPDATE_ADDRESS]
    if hashlib.sha256(witch).hexdigest() != WITCH_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("Witch update range changed")
    if pointers[WITCH_TYPE & TYPE_INDEX_MASK] != WITCH_HANDLER:
        raise RuntimeObjectDispatchError("Witch handler pointer changed")
    if pointers[WITCH_SUMMON_TYPE & TYPE_INDEX_MASK] != WITCH_SUMMON_HANDLER:
        raise RuntimeObjectDispatchError("Witch summon handler pointer changed")
    witch_collision_calls = tuple(
        WITCH_UPDATE_ADDRESS + offset
        for offset in range(len(witch) - 2)
        if witch[offset:offset + 3] == collision_call
    )
    if witch_collision_calls != EXPECTED_WITCH_COLLISION_CALLS:
        raise RuntimeObjectDispatchError("Witch summon collision calls changed")
    witch_walking_physics_calls = tuple(
        WITCH_UPDATE_ADDRESS + offset
        for offset in range(len(witch) - 2)
        if witch[offset:offset + 3] == walking_physics_call
    )
    if witch_walking_physics_calls != EXPECTED_WITCH_WALKING_PHYSICS_CALLS:
        raise RuntimeObjectDispatchError("Witch walking-physics calls changed")
    arrow_start = KNIGHT_ARROW_UPDATE_ADDRESS - PRG_START
    knight_arrow = prg[
        arrow_start:arrow_start + KNIGHT_ARROW_UPDATE_END - KNIGHT_ARROW_UPDATE_ADDRESS
    ]
    if hashlib.sha256(knight_arrow).hexdigest() != KNIGHT_ARROW_UPDATE_SHA256:
        raise RuntimeObjectDispatchError("Knight-arrow update range changed")
    knight_arrow_collision_calls = tuple(
        KNIGHT_ARROW_UPDATE_ADDRESS + offset
        for offset in range(len(knight_arrow) - 2)
        if knight_arrow[offset:offset + 3] == collision_call
    )
    if knight_arrow_collision_calls != EXPECTED_KNIGHT_ARROW_COLLISION_CALLS:
        raise RuntimeObjectDispatchError("Knight-arrow collision calls changed")
    clear_jump = bytes(
        (
            0x4C,
            CLEAR_CURRENT_RUNTIME_OBJECT_ADDRESS & 0xFF,
            CLEAR_CURRENT_RUNTIME_OBJECT_ADDRESS >> 8,
        )
    )
    knight_arrow_clear_jumps = tuple(
        KNIGHT_ARROW_UPDATE_ADDRESS + offset
        for offset in range(len(knight_arrow) - 2)
        if knight_arrow[offset:offset + 3] == clear_jump
    )
    if knight_arrow_clear_jumps != EXPECTED_KNIGHT_ARROW_CLEAR_JUMPS:
        raise RuntimeObjectDispatchError("Knight-arrow cleanup jump changed")
    return {
        "handler_table_address": HANDLER_TABLE_ADDRESS,
        "handler_count": len(pointers),
        "unique_handlers": len(set(pointers)),
        "record_count": RECORD_COUNT,
        "record_size": RECORD_SIZE,
        "record_offsets": list(expected_offsets),
        "dispatch_cases_checked": dispatch_cases,
        "skipped_cases_checked": skipped_cases,
        "linked_lift_control_range": [
            LINKED_LIFT_CONTROL_ADDRESS,
            LINKED_LIFT_CONTROL_END - 1,
        ],
        "linked_lift_control_bytes": len(linked_lift),
        "linked_lift_player_push_calls": list(linked_lift_player_push_calls),
        "linked_lift_room_update_calls": list(linked_lift_room_update_calls),
        "linked_lift_collision_calls": list(linked_lift_collision_calls),
        "linked_lift_overlap_calls": list(linked_lift_overlap_calls),
        "linked_lift_room_collision_calls": list(
            linked_lift_room_collision_calls
        ),
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
        "walking_enemy_update_range": [
            WALKING_ENEMY_UPDATE_ADDRESS,
            WALKING_ENEMY_UPDATE_END - 1,
        ],
        "walking_enemy_update_bytes": len(walking_enemy),
        "walking_enemy_collision_calls": list(walking_collision_calls),
        "walking_enemy_destroy_jumps": list(walking_destroy_jumps),
        "knight_update_range": [KNIGHT_UPDATE_ADDRESS, KNIGHT_UPDATE_END - 1],
        "knight_update_bytes": len(knight),
        "knight_walking_physics_calls": list(knight_walking_physics_calls),
        "fairy_fighter_update_range": [
            FAIRY_FIGHTER_UPDATE_ADDRESS,
            FAIRY_FIGHTER_UPDATE_END - 1,
        ],
        "fairy_fighter_update_bytes": len(fairy_fighter),
        "fighter_collision_calls": list(fighter_collision_calls),
        "fighter_walking_physics_transfers": list(fighter_walking_physics_transfers),
        "flame_helpers_range": [FLAME_HELPERS_ADDRESS, FLAME_HELPERS_END - 1],
        "flame_helpers_bytes": len(flame_helpers),
        "flame_collision_calls": list(flame_collision_calls),
        "flame_sound_calls": list(flame_sound_calls),
        "witch_update_range": [WITCH_UPDATE_ADDRESS, WITCH_UPDATE_END - 1],
        "witch_update_bytes": len(witch),
        "witch_collision_calls": list(witch_collision_calls),
        "witch_walking_physics_calls": list(witch_walking_physics_calls),
        "knight_arrow_update_range": [
            KNIGHT_ARROW_UPDATE_ADDRESS,
            KNIGHT_ARROW_UPDATE_END - 1,
        ],
        "knight_arrow_update_bytes": len(knight_arrow),
        "knight_arrow_collision_calls": list(knight_arrow_collision_calls),
        "knight_arrow_clear_jumps": list(knight_arrow_clear_jumps),
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
            f"{document['linked_lift_control_bytes']}-byte linked-lift and "
            f"{document['pushable_update_bytes']}-byte pushable/lift-control and "
            f"{document['lift_update_bytes']}-byte lift and "
            f"{document['flying_block_update_bytes']}-byte flying-block and "
            f"{document['walking_enemy_update_bytes']}-byte walking-enemy and "
            f"{document['knight_update_bytes']}-byte Knight and "
            f"{document['fairy_fighter_update_bytes']}-byte Fairy/Fighter and "
            f"{document['flame_helpers_bytes']}-byte Flame/helper and "
            f"{document['witch_update_bytes']}-byte Witch and "
            f"{document['knight_arrow_update_bytes']}-byte Knight-arrow slices"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
