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
ROOM_OBJECT_STATE_OFFSETS_CPU = 0xEF06
ROOM_OBJECT_STATE_OFFSET_COUNT = ROOM_COUNT + 1
ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU = 0xABAE
ROOM_MUTABLE_CELL_STATE_OFFSET_COUNT = ROOM_COUNT + 1
FINAL_ROOM_MUTABLE_STATE_BYTES = 3
ROOM_OBJECT_COUNTS_CPU = 0xAB4A
RUNTIME_OBJECT_OFFSETS_CPU = 0x8F10
RUNTIME_OBJECT_OFFSET_COUNT = 25
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
PERSISTENT_MUTABLE_CELL_VALUES = frozenset((0x19, 0x1C, 0x1F, 0x22, 0x25, 0x29, 0x54))
PERSISTENT_MUTABLE_CELL_RIGHT_VALUES = frozenset((0x1A, 0x1D, 0x20, 0x23, 0x26, 0x2A))
ROOM_CELL_OBJECT_TYPES = {
    0x4B: 0xA1,
    0x4D: 0xA2,
    0x51: 0xA3,
    0x49: 0xA4,
    0x4A: 0xA5,
}


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


def encode_object_stream(rooms: list[dict[str, object]]) -> bytes:
    """Encode parsed room objects back to terminated (type, x, y) triples."""
    if len(rooms) != ROOM_COUNT:
        raise RoomDataError(f"object stream has {len(rooms)} rooms, expected {ROOM_COUNT}")
    output = bytearray()
    for room_index, room in enumerate(rooms):
        objects = room.get("objects")
        if not isinstance(objects, list):
            raise RoomDataError(f"room {room_index + 1} has no object list")
        if len(objects) > RUNTIME_OBJECT_RECORD_COUNT:
            raise RoomDataError(
                f"room {room_index + 1} exceeds {RUNTIME_OBJECT_RECORD_COUNT} runtime records"
            )
        for record in objects:
            if not isinstance(record, dict):
                raise RoomDataError(f"room {room_index + 1} has an invalid object record")
            values = tuple(record.get(field) for field in ("encoded_type", "x", "y"))
            if not all(isinstance(value, int) and 0 <= value <= 0xFF for value in values):
                raise RoomDataError(f"room {room_index + 1} has a non-byte object field")
            encoded_type, x, y = values
            if encoded_type >= RUNTIME_OBJECT_TYPE_COUNT:
                raise RoomDataError(f"object type offset ${encoded_type:02X} is invalid")
            output.extend((encoded_type, x, y))
        output.append(0xFF)
    return bytes(output)


def parse_room_object_state_offsets(
    prg: bytes, rooms: list[dict[str, object]]
) -> list[int]:
    """Validate cumulative byte offsets for each room's packed object bitmap."""
    start = cpu_offset(ROOM_OBJECT_STATE_OFFSETS_CPU)
    end = start + ROOM_OBJECT_STATE_OFFSET_COUNT
    offsets = list(prg[start:end])
    if len(offsets) != ROOM_OBJECT_STATE_OFFSET_COUNT:
        raise RoomDataError("truncated room object state offset table")
    if len(rooms) != ROOM_COUNT or offsets[0] != 0:
        raise RoomDataError("invalid room object state offset table origin")
    for room_index, room in enumerate(rooms):
        objects = room.get("objects")
        if not isinstance(objects, list):
            raise RoomDataError(f"room {room_index + 1} has no object list")
        width = offsets[room_index + 1] - offsets[room_index]
        expected = (len(objects) + 7) // 8
        if width != expected:
            raise RoomDataError(
                f"room {room_index + 1} object state uses {width} bytes, "
                f"expected {expected} for {len(objects)} objects"
            )
    return offsets


def parse_room_mutable_cell_state_offsets(
    prg: bytes, rooms: list[dict[str, object]]
) -> list[int]:
    """Validate packed state allocation for persistent mutable room cells."""
    start = cpu_offset(ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU)
    end = start + ROOM_MUTABLE_CELL_STATE_OFFSET_COUNT
    offsets = list(prg[start:end])
    if len(offsets) != ROOM_MUTABLE_CELL_STATE_OFFSET_COUNT:
        raise RoomDataError("truncated room mutable-cell state offset table")
    if len(rooms) != ROOM_COUNT or offsets[0] != 0:
        raise RoomDataError("invalid room mutable-cell state offset table origin")
    for room_index, room in enumerate(rooms):
        rows = room.get("cells")
        if not isinstance(rows, list) or len(rows) != ROOM_HEIGHT:
            raise RoomDataError(f"room {room_index + 1} has no decoded cell grid")
        cells = [cell for row in rows if isinstance(row, list) for cell in row]
        if len(cells) != ROOM_SIZE:
            raise RoomDataError(f"room {room_index + 1} has an invalid cell grid")
        mutable_count = sum(cell in PERSISTENT_MUTABLE_CELL_VALUES for cell in cells)
        expected = (mutable_count + 7) // 8
        if room_index == ROOM_COUNT - 1:
            expected = max(expected, FINAL_ROOM_MUTABLE_STATE_BYTES)
        width = offsets[room_index + 1] - offsets[room_index]
        if width != expected:
            raise RoomDataError(
                f"room {room_index + 1} mutable-cell state uses {width} bytes, "
                f"expected {expected} for {mutable_count} cells"
            )
    return offsets


def parse_room_object_counts(
    prg: bytes, rooms: list[dict[str, object]]
) -> list[int]:
    start = cpu_offset(ROOM_OBJECT_COUNTS_CPU)
    counts = list(prg[start:start + ROOM_COUNT])
    if len(counts) != ROOM_COUNT or len(rooms) != ROOM_COUNT:
        raise RoomDataError("truncated room object count table")
    expected = []
    for room_index, room in enumerate(rooms):
        objects = room.get("objects")
        if not isinstance(objects, list):
            raise RoomDataError(f"room {room_index + 1} has no object list")
        expected.append(len(objects))
    if counts != expected:
        mismatch = next(index for index in range(ROOM_COUNT) if counts[index] != expected[index])
        raise RoomDataError(
            f"room {mismatch + 1} object count is {counts[mismatch]}, "
            f"expected {expected[mismatch]}"
        )
    return counts


def parse_runtime_object_offsets(prg: bytes) -> list[int]:
    start = cpu_offset(RUNTIME_OBJECT_OFFSETS_CPU)
    offsets = list(prg[start:start + RUNTIME_OBJECT_OFFSET_COUNT])
    expected = [count * 6 for count in range(RUNTIME_OBJECT_OFFSET_COUNT)]
    if offsets != expected:
        raise RoomDataError("runtime object offset table is not count * 6")
    return offsets


def apply_room_object_state(
    objects: list[dict[str, int]], state: bytes
) -> list[dict[str, int]]:
    required = (len(objects) + 7) // 8
    if len(state) != required:
        raise RoomDataError(
            f"object state has {len(state)} bytes, expected {required}"
        )
    return [
        record
        for index, record in enumerate(objects)
        if not state[index // 8] & (1 << (index & 7))
    ]


def apply_room_mutable_cell_state(cells: bytes, state: bytes) -> bytes:
    """Apply the original 39-bit, one-based mutable-cell restoration loop."""
    if len(cells) != ROOM_SIZE or len(state) > 5:
        raise RoomDataError("invalid mutable-cell state input")
    output = bytearray(cells)
    padded_state = state + bytes(5 - len(state))
    for ordinal in range(1, 0x28):
        if not padded_state[(ordinal - 1) // 8] & (1 << ((ordinal - 1) & 7)):
            continue
        remaining = ordinal
        target = None
        for index, cell in enumerate(output):
            if cell in PERSISTENT_MUTABLE_CELL_VALUES:
                remaining -= 1
                if remaining == 0:
                    target = index
                    break
        if target is None:
            continue
        if target == 0 or target + ROOM_WIDTH >= ROOM_SIZE:
            raise RoomDataError("mutable-cell target is outside its two-row neighborhood")
        beside_type_16 = output[target - 1] == 0x16 or (
            target + 1 < ROOM_SIZE and output[target + 1] == 0x16
        )
        output[target] = 0x62 if beside_type_16 else 0x54
        output[target + ROOM_WIDTH] = 0x63 if beside_type_16 else 0x55
    return bytes(output)


def spawn_room_cell_objects(
    cells: bytes, static_object_count: int
) -> tuple[bytes, list[dict[str, int]]]:
    """Convert five room-cell markers into runtime object records."""
    if len(cells) != ROOM_SIZE or not 0 <= static_object_count <= RUNTIME_OBJECT_RECORD_COUNT:
        raise RoomDataError("invalid room-cell object input")
    output = bytearray(cells)
    runtime_offset = static_object_count * 6
    records: list[dict[str, int]] = []
    for index, cell in enumerate(output):
        runtime_type = ROOM_CELL_OBJECT_TYPES.get(cell)
        if runtime_type is None:
            continue
        if runtime_offset >= RUNTIME_OBJECT_RECORD_COUNT * 6:
            raise RoomDataError("cell-derived objects overflow the runtime object pool")
        output[index] = 0x53
        records.append(
            {
                "runtime_offset": runtime_offset,
                "runtime_type": runtime_type,
                "pixel_x": (index % ROOM_WIDTH) * 16,
                "pixel_y": (index // ROOM_WIDTH) * 8,
                "initial_state": 0xFF if runtime_type == 0xA3 else 0,
            }
        )
        runtime_offset += 6
    return bytes(output), records


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
            object_counts = parse_room_object_counts(prg, object_rooms)
            parse_runtime_object_offsets(prg)
            encoded_objects = encode_object_stream(object_rooms)
            original_objects = prg[
                cpu_offset(OBJECT_STREAM_CPU):cpu_offset(OBJECT_STREAM_END_CPU)
            ]
            if encoded_objects != original_objects:
                raise RoomDataError("room object stream does not round-trip exactly")
            state_offsets = parse_room_object_state_offsets(prg, object_rooms)
            rooms = [decode_room(prg, chr_data, index) for index in range(ROOM_COUNT)]
            mutable_offsets = parse_room_mutable_cell_state_offsets(prg, rooms)
            objects = sum(len(room["objects"]) for room in object_rooms)
            cell_objects = 0
            for room_index, room in enumerate(rooms):
                flat_cells = bytes(cell for row in room["cells"] for cell in row)
                _cells, spawned = spawn_room_cell_objects(
                    flat_cells, object_counts[room_index]
                )
                cell_objects += len(spawned)
            print(
                f"[OK] decoded {len(rooms)} rooms, 40,000 cells, "
                f"{2 * len(rooms)} attribute tables, {objects} objects, "
                f"{len(encoded_objects)} round-tripped object bytes, "
                f"{state_offsets[-1]} object-state + "
                f"{mutable_offsets[-1]} mutable-cell-state bytes, "
                f"and {cell_objects} cell-derived objects"
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
