#!/usr/bin/env python3
"""Model Castle Excellent's frame sprite selection and render dispatch."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
FRAME_SPRITES_CPU = 0xAC13
FRAME_SPRITES_END_CPU = 0xADE7
OBJECT_SPRITE_POINTERS_CPU = 0xAD93
OBJECT_SPRITE_HANDLER_COUNT = 42
OBJECT_RECORD_COUNT = 24
OBJECT_RECORD_SIZE = 6
OBJECT_VISIBLE_Y_LIMIT = 0xA0
OBJECT_TYPE_INDEX_MASK = 0x7F
OAM_BUFFER_SIZE = 0x100
OAM_HIDDEN_Y = 0xF0
FIRST_OBJECT_OAM_OFFSET = 0x0C
PLAYER_ACTION_TILE = 0xCA
PLAYER_ACTION_RIGHT_ATTRIBUTE = 0x03
PLAYER_ACTION_LEFT_ATTRIBUTE = 0x43

PLAYER_RIGHT_WALK_FRAMES = (0xB4B6, 0xB4BA, 0xB4BE, 0xB4BA)
PLAYER_LEFT_WALK_FRAMES = (0xB4CA, 0xB4CE, 0xB4D2, 0xB4CE)
PLAYER_TRANSITION_FRAMES = (0xB4E6, 0xB4EA, 0xB4EE, 0xB4F2)
PLAYER_NEUTRAL_METASPRITE = 0xB4C2
PLAYER_RIGHT_MOTION_METASPRITE = 0xB4C6
PLAYER_LEFT_MOTION_METASPRITE = 0xB4DA
PLAYER_NEUTRAL_MOTION_METASPRITE = 0xB4D6
PLAYER_RIGHT_ACTION_METASPRITE = 0xB4DE
PLAYER_LEFT_ACTION_METASPRITE = 0xB4E2

EXPECTED_RANGE_SHA256 = "5b100fd85a9c894e8ad6248235d9ded938d8936e6f8e55db13e2738dd4f26f0b"
EXPECTED_FRAME_BUILDER_BYTES = bytes.fromhex(
    "a9 ff 85 fb a2 00 a9 f0 9d 00 03 e8 d0 fa 20 60 ac 20 54 ad "
    "a2 0c 86 16 a0 00 84 41 a4 41 b9 4d 00 c9 a0 b0 18 b9 4a 00 "
    "f0 13 29 7f 0a a8 b9 93 ad 85 31 b9 94 ad 85 32 a6 41 6c 31 00 "
    "a5 41 18 69 06 85 41 c9 90 90 d4 a9 00 85 fb 60"
)
EXPECTED_ACTION_OVERLAY_BYTES = bytes.fromhex(
    "ad 79 07 d0 01 60 a5 3b d0 01 60 30 1a ad 00 03 8d 08 03 "
    "ad 03 03 18 69 0f 8d 0b 03 a9 ca 8d 09 03 a9 03 8d 0a 03 60 "
    "ad 00 03 8d 08 03 ad 03 03 38 e9 07 8d 0b 03 a9 ca 8d 09 03 "
    "a9 43 8d 0a 03 60"
)
EXPECTED_OBJECT_SPRITE_HANDLERS = (
    0x6003,
    0xADE7,
    0xAE08,
    0xAE12,
    0xAE19,
    0xAE75,
    0xAEBB,
    0xAF1E,
    0xAF6A,
    0xAFB0,
    0xAFF4,
    0xAFFB,
    0xB002,
    0xB009,
    0xB010,
    0xB017,
    0xB02B,
    0xB035,
    0xB03C,
    0xB043,
    0xB04A,
    0xB051,
    0xB058,
    0xB05F,
    0xB066,
    0xB06D,
    0xB074,
    0xB07B,
    0xB082,
    0xB089,
    0xB089,
    0xB090,
    0xB0AC,
    0xB0C9,
    0xB0D0,
    0xB0DA,
    0xB0E1,
    0xB0E8,
    0xB0EF,
    0xB114,
    0xB117,
    0xB135,
)


class FrameSpriteError(ValueError):
    pass


@dataclass(frozen=True)
class HardwareSprite:
    y: int
    tile: int
    attributes: int
    x: int


@dataclass(frozen=True)
class RuntimeObjectSprite:
    runtime_type: int
    y: int


@dataclass(frozen=True)
class ScheduledObjectSprite:
    record_offset: int
    type_index: int
    handler: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise FrameSpriteError(f"{name} outside 0-255: {value}")


def select_player_metasprite(
    *,
    transition_countdown: int,
    room_frame: int,
    direction: int,
    motion_state: int,
    motion_phase: int,
    action_countdown: int,
    frame_counter: int,
) -> int:
    for value, name in (
        (transition_countdown, "transition countdown"),
        (room_frame, "room frame"),
        (direction, "direction"),
        (motion_state, "motion state"),
        (motion_phase, "motion phase"),
        (action_countdown, "action countdown"),
        (frame_counter, "frame counter"),
    ):
        _validate_byte(value, name)
    if transition_countdown:
        return PLAYER_TRANSITION_FRAMES[(room_frame >> 2) & 0x03]
    moving = bool(motion_state | motion_phase)
    if direction == 0:
        return (
            PLAYER_NEUTRAL_MOTION_METASPRITE
            if moving
            else PLAYER_NEUTRAL_METASPRITE
        )
    if direction < 0x80:
        if moving:
            return PLAYER_RIGHT_MOTION_METASPRITE
        if action_countdown:
            return PLAYER_RIGHT_ACTION_METASPRITE
        return PLAYER_RIGHT_WALK_FRAMES[(frame_counter >> 3) & 0x03]
    if moving:
        return PLAYER_LEFT_MOTION_METASPRITE
    if action_countdown:
        return PLAYER_LEFT_ACTION_METASPRITE
    return PLAYER_LEFT_WALK_FRAMES[(frame_counter >> 3) & 0x03]


def build_player_action_sprite(
    *, first_sprite_y: int, first_sprite_x: int, direction: int, action_countdown: int
) -> HardwareSprite | None:
    for value, name in (
        (first_sprite_y, "first sprite Y"),
        (first_sprite_x, "first sprite X"),
        (direction, "direction"),
        (action_countdown, "action countdown"),
    ):
        _validate_byte(value, name)
    if action_countdown == 0 or direction == 0:
        return None
    if direction < 0x80:
        return HardwareSprite(
            first_sprite_y,
            PLAYER_ACTION_TILE,
            PLAYER_ACTION_RIGHT_ATTRIBUTE,
            (first_sprite_x + 15) & 0xFF,
        )
    return HardwareSprite(
        first_sprite_y,
        PLAYER_ACTION_TILE,
        PLAYER_ACTION_LEFT_ATTRIBUTE,
        (first_sprite_x - 7) & 0xFF,
    )


def clear_oam_staging() -> bytes:
    return bytes([OAM_HIDDEN_Y]) * OAM_BUFFER_SIZE


def select_object_sprite_handler(
    runtime_type: int,
    y: int,
    pointers: tuple[int, ...] = EXPECTED_OBJECT_SPRITE_HANDLERS,
) -> tuple[int, int] | None:
    _validate_byte(runtime_type, "runtime type")
    _validate_byte(y, "runtime Y")
    if len(pointers) != OBJECT_SPRITE_HANDLER_COUNT:
        raise FrameSpriteError("object sprite table must contain 42 pointers")
    if y >= OBJECT_VISIBLE_Y_LIMIT or runtime_type == 0:
        return None
    type_index = runtime_type & OBJECT_TYPE_INDEX_MASK
    if type_index >= len(pointers):
        raise FrameSpriteError(
            f"runtime type index ${type_index:02X} exceeds the sprite table"
        )
    return type_index, pointers[type_index]


def schedule_object_sprites(
    records: tuple[RuntimeObjectSprite, ...],
    pointers: tuple[int, ...] = EXPECTED_OBJECT_SPRITE_HANDLERS,
) -> tuple[ScheduledObjectSprite, ...]:
    if len(records) != OBJECT_RECORD_COUNT:
        raise FrameSpriteError("runtime sprite scan requires 24 records")
    scheduled: list[ScheduledObjectSprite] = []
    for index, record in enumerate(records):
        selection = select_object_sprite_handler(record.runtime_type, record.y, pointers)
        if selection is None:
            continue
        type_index, handler = selection
        scheduled.append(
            ScheduledObjectSprite(index * OBJECT_RECORD_SIZE, type_index, handler)
        )
    return tuple(scheduled)


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise FrameSpriteError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise FrameSpriteError("expected a complete 32 KiB PRG region")
    return image[start:end]


def read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start : start + size]


def decode_object_sprite_pointers(prg: bytes) -> tuple[int, ...]:
    raw = read_cpu_range(
        prg, OBJECT_SPRITE_POINTERS_CPU, OBJECT_SPRITE_HANDLER_COUNT * 2
    )
    if len(raw) != OBJECT_SPRITE_HANDLER_COUNT * 2:
        raise FrameSpriteError("truncated object sprite handler table")
    return tuple(raw[index] | raw[index + 1] << 8 for index in range(0, len(raw), 2))


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    region = read_cpu_range(
        prg, FRAME_SPRITES_CPU, FRAME_SPRITES_END_CPU - FRAME_SPRITES_CPU
    )
    if hashlib.sha256(region).hexdigest() != EXPECTED_RANGE_SHA256:
        raise FrameSpriteError("frame sprite source range changed")
    if region[: len(EXPECTED_FRAME_BUILDER_BYTES)] != EXPECTED_FRAME_BUILDER_BYTES:
        raise FrameSpriteError("frame sprite dispatcher bytes changed")
    action_offset = 0xAD54 - FRAME_SPRITES_CPU
    if (
        region[action_offset : action_offset + len(EXPECTED_ACTION_OVERLAY_BYTES)]
        != EXPECTED_ACTION_OVERLAY_BYTES
    ):
        raise FrameSpriteError("player action sprite bytes changed")
    pointers = decode_object_sprite_pointers(prg)
    if pointers != EXPECTED_OBJECT_SPRITE_HANDLERS:
        raise FrameSpriteError("object sprite handler pointers changed")
    if pointers[0] != 0x6003:
        raise FrameSpriteError("overlapping unused type-zero pointer changed")
    return {
        "range": [FRAME_SPRITES_CPU, FRAME_SPRITES_END_CPU - 1],
        "bytes": len(region),
        "handler_table": OBJECT_SPRITE_POINTERS_CPU,
        "handler_count": len(pointers),
        "unique_handler_count": len(set(pointers[1:])),
        "unused_type_zero_pointer": pointers[0],
    }


def validate_model_contract() -> dict[str, object]:
    if clear_oam_staging() != bytes([0xF0]) * 0x100:
        raise FrameSpriteError("OAM clear pattern changed")

    transition_cases = 0
    for countdown in range(1, 0x100):
        for room_frame in range(0x100):
            expected = PLAYER_TRANSITION_FRAMES[(room_frame >> 2) & 3]
            actual = select_player_metasprite(
                transition_countdown=countdown,
                room_frame=room_frame,
                direction=0,
                motion_state=0,
                motion_phase=0,
                action_countdown=0,
                frame_counter=0,
            )
            if actual != expected:
                raise FrameSpriteError("transition frame selection mismatch")
            transition_cases += 1

    normal_cases = 0
    for direction in range(0x100):
        for frame_counter in range(0x100):
            for motion_state in (0, 1):
                for motion_phase in (0, 1):
                    for action_countdown in (0, 1):
                        select_player_metasprite(
                            transition_countdown=0,
                            room_frame=0,
                            direction=direction,
                            motion_state=motion_state,
                            motion_phase=motion_phase,
                            action_countdown=action_countdown,
                            frame_counter=frame_counter,
                        )
                        normal_cases += 1

    overlay_cases = 0
    for direction in range(0x100):
        for first_x in range(0x100):
            for action_countdown in (0, 1):
                sprite = build_player_action_sprite(
                    first_sprite_y=0x55,
                    first_sprite_x=first_x,
                    direction=direction,
                    action_countdown=action_countdown,
                )
                should_draw = bool(direction and action_countdown)
                if (sprite is not None) != should_draw:
                    raise FrameSpriteError("player action visibility mismatch")
                overlay_cases += 1

    dispatch_cases = 0
    for runtime_type in range(0x100):
        for y in range(0x100):
            try:
                selection = select_object_sprite_handler(runtime_type, y)
            except FrameSpriteError:
                if y < OBJECT_VISIBLE_Y_LIMIT and runtime_type != 0:
                    type_index = runtime_type & OBJECT_TYPE_INDEX_MASK
                    if type_index >= OBJECT_SPRITE_HANDLER_COUNT:
                        dispatch_cases += 1
                        continue
                raise
            if y >= OBJECT_VISIBLE_Y_LIMIT or runtime_type == 0:
                if selection is not None:
                    raise FrameSpriteError("hidden object selected a sprite handler")
            dispatch_cases += 1

    records = tuple(RuntimeObjectSprite(index + 1, index) for index in range(24))
    scheduled = schedule_object_sprites(records)
    if tuple(item.record_offset for item in scheduled) != tuple(range(0, 0x90, 6)):
        raise FrameSpriteError("frame sprite dispatcher did not scan 24 records")

    return {
        "oam_clear_bytes": OAM_BUFFER_SIZE,
        "first_object_oam_offset": FIRST_OBJECT_OAM_OFFSET,
        "transition_cases": transition_cases,
        "normal_player_cases": normal_cases,
        "action_overlay_cases": overlay_cases,
        "object_dispatch_cases": dispatch_cases,
        "runtime_record_offsets": [item.record_offset for item in scheduled],
    }


def build_report(image_path: Path) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    return {
        "rom": validate_rom_contract(prg),
        "model": validate_model_contract(),
        "player_frames": {
            "right_walk": list(PLAYER_RIGHT_WALK_FRAMES),
            "left_walk": list(PLAYER_LEFT_WALK_FRAMES),
            "transition": list(PLAYER_TRANSITION_FRAMES),
        },
        "action_sprites": [
            asdict(
                build_player_action_sprite(
                    first_sprite_y=0x40,
                    first_sprite_x=0x80,
                    direction=direction,
                    action_countdown=1,
                )
            )
            for direction in (1, 0xFF)
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        report = build_report(args.image)
    except (OSError, FrameSpriteError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated player/action sprites, 24-record rendering scan, "
            "and 42 object render pointers"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
