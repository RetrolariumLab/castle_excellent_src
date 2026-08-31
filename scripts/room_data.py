#!/usr/bin/env python3
"""Decode Castle Excellent's 100 compressed rooms and object streams."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys


ROOM_COUNT = 100
ROOM_WIDTH = 20
ROOM_HEIGHT = 20
ROOM_SIZE = ROOM_WIDTH * ROOM_HEIGHT
CHR_BANK_SIZE = 8_192
ROOM_BANK_SPLIT = 0x43  # zero-based rooms 0..66 use bank 2

CODEBOOK_CPU = 0xE45D
ROOM_POINTERS_CPU = 0xE71C
OBJECT_STREAM_CPU = 0xEF6B
OBJECT_STREAM_END_CPU = 0xF8FC  # exclusive; follows the 100th $FF terminator
RUNTIME_OBJECT_TYPES_CPU = 0xEB8F
RUNTIME_OBJECT_TYPE_COUNT = 0x3D
RUNTIME_OBJECT_STATES_CPU = 0xEBC0
RUNTIME_OBJECT_STATE_FIRST_TYPE = 0x12
RUNTIME_OBJECT_STATE_END_TYPE = 0x2A
RUNTIME_OBJECT_RECORD_COUNT = 24
OBJECT_HANDLER_TABLE_CPU = 0xAD93
INITIAL_ROOM_ATTRIBUTES_CPU = 0xB7AD
ROOM_ATTRIBUTE_MASKS_CPU = 0xE913
ROOM_CELL_ATTRIBUTES_CPU = 0xE9D2
ROOM_ATTRIBUTE_TABLE_SIZE = 64
ROOM_ATTRIBUTE_BUFFER_SIZE = 2 * ROOM_ATTRIBUTE_TABLE_SIZE
ATTRIBUTE_PRESERVING_CELLS = frozenset(
    (0x09, 0x18, 0x1B, 0x1E, 0x21, 0x24, 0x27, 0x28, 0x2B, 0x2C, 0x2D, 0x2E, 0x53)
)


class RoomDataError(ValueError):
    pass


def cpu_offset(address: int) -> int:
    if not 0x8000 <= address <= 0xFFFF:
        raise RoomDataError(f"CPU address outside fixed PRG: ${address:04X}")
    return address - 0x8000


def extract_rom(image: bytes) -> tuple[bytes, bytes]:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise RoomDataError("expected an iNES image")
    trainer = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    chr_size = image[5] * CHR_BANK_SIZE
    prg_start = 16 + trainer
    chr_start = prg_start + prg_size
    end = chr_start + chr_size
    if len(image) != end:
        raise RoomDataError(f"image size is {len(image)}, expected exactly {end}")
    if prg_size != 32_768 or chr_size < 4 * CHR_BANK_SIZE:
        raise RoomDataError("expected 32 KiB PRG and at least four 8 KiB CHR banks")
    return image[prg_start:chr_start], image[chr_start:end]


def parse_codebook(prg: bytes) -> list[tuple[int, str]]:
    """Read entries encoded as [symbol]['0'/'1'...][00], ending at symbol FF."""
    cursor = cpu_offset(CODEBOOK_CPU)
    entries: list[tuple[int, str]] = []
    while cursor < len(prg):
        symbol = prg[cursor]
        cursor += 1
        if symbol == 0xFF:
            break
        start = cursor
        while cursor < len(prg) and prg[cursor] != 0:
            if prg[cursor] not in (0x30, 0x31):
                raise RoomDataError(
                    f"invalid code byte ${prg[cursor]:02X} at PRG ${cursor:04X}"
                )
            cursor += 1
        if cursor >= len(prg):
            raise RoomDataError("unterminated room codebook entry")
        code = bytes(prg[start:cursor]).decode("ascii")
        cursor += 1
        if not code:
            raise RoomDataError(f"empty code for symbol ${symbol:02X}")
        entries.append((symbol, code))
    else:
        raise RoomDataError("room codebook sentinel not found")
    if not entries:
        raise RoomDataError("empty room codebook")
    validate_codebook(entries)
    return entries


def validate_codebook(entries: list[tuple[int, str]]) -> None:
    seen: set[str] = set()
    for _symbol, code in entries:
        if code in seen:
            raise RoomDataError(f"duplicate room code {code!r}")
        if any(code.startswith(other) or other.startswith(code) for other in seen):
            raise RoomDataError(f"room codebook is not prefix-free at {code!r}")
        seen.add(code)


def room_stream(prg: bytes, chr_data: bytes, room_index: int) -> tuple[bytes, int, int]:
    if not 0 <= room_index < ROOM_COUNT:
        raise RoomDataError(f"room index outside 0..{ROOM_COUNT - 1}: {room_index}")
    pointer_at = cpu_offset(ROOM_POINTERS_CPU) + room_index * 2
    if pointer_at + 2 > len(prg):
        raise RoomDataError("truncated room pointer table")
    offset = prg[pointer_at] | (prg[pointer_at + 1] << 8)
    bank = 2 if room_index < ROOM_BANK_SPLIT else 3
    bank_start = bank * CHR_BANK_SIZE
    bank_end = bank_start + CHR_BANK_SIZE
    if offset >= CHR_BANK_SIZE or bank_end > len(chr_data):
        raise RoomDataError(
            f"room {room_index + 1} has invalid CHR bank/offset {bank}:${offset:04X}"
        )
    return chr_data[bank_start + offset:bank_end], bank, offset


def decode_prefix_stream(
    stream: bytes,
    entries: list[tuple[int, str]],
    output_size: int = ROOM_SIZE,
) -> tuple[bytes, int]:
    lookup = {code: symbol for symbol, code in entries}
    prefixes = {code[:length] for code in lookup for length in range(1, len(code) + 1)}
    output = bytearray()
    code = ""
    bit_count = 0
    for value in stream:
        for shift in range(7, -1, -1):
            bit_count += 1
            code += "1" if value & (1 << shift) else "0"
            symbol = lookup.get(code)
            if symbol is not None:
                output.append(symbol)
                code = ""
                if len(output) == output_size:
                    return bytes(output), bit_count
            elif code not in prefixes:
                raise RoomDataError(
                    f"compressed room has no code matching bit {bit_count} ({code!r})"
                )
    raise RoomDataError(f"truncated room stream after {len(output)} of {output_size} cells")


def room_attribute_position(column: int, row: int) -> tuple[int, int]:
    if not 0 <= column < ROOM_WIDTH or not 0 <= row < ROOM_HEIGHT:
        raise RoomDataError(f"room attribute coordinate is out of bounds: {column},{row}")
    tile_x = column * 2 + 4
    tile_y = row + 7
    table_offset = 0
    if tile_x >= 0x20:
        table_offset = ROOM_ATTRIBUTE_TABLE_SIZE
        tile_x -= 0x20
    byte_offset = table_offset + ((tile_y * 2) & 0xF8) + (tile_x >> 2)
    quadrant = (tile_y & 0x02) | ((tile_x >> 1) & 0x01)
    return byte_offset, quadrant


def build_room_attributes(prg: bytes, cells: bytes) -> bytes:
    if len(cells) != ROOM_SIZE:
        raise RoomDataError(f"room has {len(cells)} cells, expected {ROOM_SIZE}")
    initial_at = cpu_offset(INITIAL_ROOM_ATTRIBUTES_CPU)
    masks_at = cpu_offset(ROOM_ATTRIBUTE_MASKS_CPU)
    values_at = cpu_offset(ROOM_CELL_ATTRIBUTES_CPU)
    initial = prg[initial_at:initial_at + 16]
    masks = prg[masks_at:masks_at + 4]
    values = prg[values_at:values_at + 100]
    if len(initial) != 16 or len(masks) != 4 or len(values) != 100:
        raise RoomDataError("truncated room attribute tables")
    if masks != bytes((0x03, 0x0C, 0x30, 0xC0)):
        raise RoomDataError(f"unexpected room attribute masks: {masks.hex()}")
    if set(values) - {0x00, 0x55, 0xAA, 0xFF}:
        raise RoomDataError("room cell attribute table contains a non-replicated palette value")
    attributes = bytearray(ROOM_ATTRIBUTE_BUFFER_SIZE)
    attributes[:len(initial)] = initial
    for row in range(ROOM_HEIGHT):
        for column in range(ROOM_WIDTH):
            cell = cells[row * ROOM_WIDTH + column]
            if cell in ATTRIBUTE_PRESERVING_CELLS:
                continue
            if cell >= len(values):
                raise RoomDataError(f"room cell ${cell:02X} exceeds attribute table")
            offset, quadrant = room_attribute_position(column, row)
            mask = masks[quadrant]
            attributes[offset] = (attributes[offset] & (mask ^ 0xFF)) | (values[cell] & mask)
    return bytes(attributes)


def decode_object_list(
    prg: bytes, cursor: int, limit: int | None = None
) -> tuple[dict[str, object], int]:
    if limit is None:
        limit = len(prg)
    if not 0 <= cursor < limit <= len(prg):
        raise RoomDataError("invalid room object stream bounds")
    start = cursor
    objects: list[dict[str, int]] = []
    while cursor < limit and prg[cursor] != 0xFF:
        if len(objects) >= RUNTIME_OBJECT_RECORD_COUNT:
            raise RoomDataError(
                f"room object list exceeds {RUNTIME_OBJECT_RECORD_COUNT} runtime records"
            )
        if cursor + 3 > limit:
            raise RoomDataError("truncated room object record")
        encoded_type, x, y = prg[cursor:cursor + 3]
        if encoded_type >= RUNTIME_OBJECT_TYPE_COUNT:
            raise RoomDataError(f"object type offset ${encoded_type:02X} is invalid")
        type_at = cpu_offset(RUNTIME_OBJECT_TYPES_CPU) + encoded_type
        runtime_type = prg[type_at]
        handler_at = cpu_offset(OBJECT_HANDLER_TABLE_CPU) + ((runtime_type & 0x7F) * 2)
        if handler_at + 2 > len(prg):
            raise RoomDataError(f"object handler index ${runtime_type:02X} is invalid")
        record = {
            "encoded_type": encoded_type,
            "runtime_type": runtime_type,
            "x": x,
            "y": y,
            "pixel_x": x * 16 + (4 if 0x90 <= runtime_type <= 0x95 else 0),
            "pixel_y": y * 8,
            "handler": prg[handler_at] | (prg[handler_at + 1] << 8),
        }
        if RUNTIME_OBJECT_STATE_FIRST_TYPE <= encoded_type < RUNTIME_OBJECT_STATE_END_TYPE:
            state_at = cpu_offset(RUNTIME_OBJECT_STATES_CPU) + encoded_type
            record["initial_state"] = prg[state_at]
        objects.append(record)
        cursor += 3
    if cursor >= limit:
        raise RoomDataError("unterminated room object stream")
    return {"prg_cpu_address": start + 0x8000, "objects": objects}, cursor + 1


def parse_object_stream(prg: bytes) -> list[dict[str, object]]:
    """Decode the complete, exactly bounded sequence of 100 room object lists."""
    cursor = cpu_offset(OBJECT_STREAM_CPU)
    limit = cpu_offset(OBJECT_STREAM_END_CPU)
    rooms: list[dict[str, object]] = []
    for _ in range(ROOM_COUNT):
        room, cursor = decode_object_list(prg, cursor, limit)
        rooms.append(room)
    if cursor != limit:
        raise RoomDataError(
            f"room object stream ends at CPU ${cursor + 0x8000:04X}, "
            f"expected ${OBJECT_STREAM_END_CPU:04X}"
        )
    return rooms


def decode_objects(prg: bytes, room_index: int) -> dict[str, object]:
    if not 0 <= room_index < ROOM_COUNT:
        raise RoomDataError(f"room index outside 0..{ROOM_COUNT - 1}: {room_index}")
    cursor = cpu_offset(OBJECT_STREAM_CPU)
    for _ in range(room_index):
        _room, cursor = decode_object_list(prg, cursor)
    room, _next = decode_object_list(prg, cursor)
    return room


def decode_room(prg: bytes, chr_data: bytes, room_index: int) -> dict[str, object]:
    entries = parse_codebook(prg)
    stream, bank, offset = room_stream(prg, chr_data, room_index)
    cells, bits = decode_prefix_stream(stream, entries)
    attributes = build_room_attributes(prg, cells)
    rows = [list(cells[y * ROOM_WIDTH:(y + 1) * ROOM_WIDTH]) for y in range(ROOM_HEIGHT)]
    return {
        "room": room_index + 1,
        "index": room_index,
        "chr_bank": bank,
        "chr_bank_offset": offset,
        "compressed_bits_consumed": bits,
        "width": ROOM_WIDTH,
        "height": ROOM_HEIGHT,
        "cells": rows,
        "attribute_tables": {
            "left": list(attributes[:ROOM_ATTRIBUTE_TABLE_SIZE]),
            "right": list(attributes[ROOM_ATTRIBUTE_TABLE_SIZE:]),
        },
        "object_stream": decode_objects(prg, room_index),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True, help="Castle Excellent iNES image")
    parser.add_argument("--room", type=int, help="one-based room number (default: all)")
    parser.add_argument("--pretty", action="store_true")
    parser.add_argument(
        "--validate",
        action="store_true",
        help="decode every room and print only a structural summary",
    )
    args = parser.parse_args()
    try:
        prg, chr_data = extract_rom(Path(args.image).read_bytes())
        if args.validate:
            object_rooms = parse_object_stream(prg)
            rooms = [decode_room(prg, chr_data, index) for index in range(ROOM_COUNT)]
            objects = sum(len(room["objects"]) for room in object_rooms)
            print(
                f"[OK] decoded {len(rooms)} rooms, 40,000 cells, "
                f"{2 * len(rooms)} attribute tables, and {objects} objects"
            )
            return 0
        if args.room is None:
            result: object = [decode_room(prg, chr_data, index) for index in range(ROOM_COUNT)]
        else:
            result = decode_room(prg, chr_data, args.room - 1)
    except (OSError, RoomDataError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
