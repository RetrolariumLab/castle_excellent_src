#!/usr/bin/env python3
"""Correlate Castle Excellent room, runtime, update, sprite, and collision types."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys

from scripts.validation import frame_sprites, room_data
from scripts.validation.collision import collision_tables
from scripts.validation.objects import runtime_object_dispatch


RUNTIME_TYPE_FIRST = 0x80
RUNTIME_TYPE_COUNT = 42
RUNTIME_TYPE_END = RUNTIME_TYPE_FIRST + RUNTIME_TYPE_COUNT
PRG_SIZE = 0x8000
NO_OP_UPDATE_HANDLER = 0xA2A9
STATIC_OBJECT_COUNT = 783
CELL_DERIVED_OBJECT_COUNT = 176
EXPECTED_USED_ENCODED_TYPES = (
    0x0E, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x18, 0x1A, 0x1E,
    0x20, 0x22, 0x24, 0x27, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A,
    0x3C,
)
EXPECTED_CELL_TYPE_COUNTS = {0xA1: 73, 0xA2: 47, 0xA3: 40, 0xA4: 8, 0xA5: 8}
EXPECTED_UNSOURCED_RUNTIME_TYPES = (
    0x80, 0x9B, 0x9C, 0x9D, 0x9E, 0xA0, 0xA6, 0xA7, 0xA8, 0xA9,
)


class ObjectCatalogError(ValueError):
    pass


@dataclass(frozen=True)
class ObjectTypeEntry:
    runtime_type: int
    type_index: int
    encoded_types: tuple[int, ...]
    initial_states: tuple[int, ...]
    static_occurrences: int
    static_rooms: tuple[int, ...]
    cell_markers: tuple[int, ...]
    cell_occurrences: int
    cell_rooms: tuple[int, ...]
    update_handler: int
    sprite_selector: int
    collision_width: int
    collision_height: int


def read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = room_data.cpu_offset(address)
    result = prg[start:start + size]
    if len(result) != size:
        raise ObjectCatalogError(f"truncated PRG range at ${address:04X}")
    return result


def group_static_objects(
    rooms: list[dict[str, object]],
) -> tuple[Counter[int], dict[int, set[int]], Counter[int]]:
    occurrences: Counter[int] = Counter()
    room_numbers: dict[int, set[int]] = defaultdict(set)
    encoded_occurrences: Counter[int] = Counter()
    for room_number, room in enumerate(rooms, 1):
        objects = room.get("objects")
        if not isinstance(objects, list):
            raise ObjectCatalogError(f"room {room_number} has no object records")
        for record in objects:
            if not isinstance(record, dict):
                raise ObjectCatalogError(f"room {room_number} has an invalid object")
            runtime_type = record.get("runtime_type")
            encoded_type = record.get("encoded_type")
            if not isinstance(runtime_type, int) or not isinstance(encoded_type, int):
                raise ObjectCatalogError(f"room {room_number} has an invalid object type")
            occurrences[runtime_type] += 1
            encoded_occurrences[encoded_type] += 1
            room_numbers[runtime_type].add(room_number)
    return occurrences, room_numbers, encoded_occurrences


def group_cell_objects(
    prg: bytes, chr_data: bytes
) -> tuple[Counter[int], dict[int, set[int]], dict[int, tuple[int, ...]]]:
    occurrences: Counter[int] = Counter()
    room_numbers: dict[int, set[int]] = defaultdict(set)
    markers: dict[int, list[int]] = defaultdict(list)
    for marker, runtime_type in room_data.ROOM_CELL_OBJECT_TYPES.items():
        markers[runtime_type].append(marker)
    for room_index in range(room_data.ROOM_COUNT):
        room = room_data.decode_room(prg, chr_data, room_index)
        cells = bytes(cell for row in room["cells"] for cell in row)
        for marker, runtime_type in room_data.ROOM_CELL_OBJECT_TYPES.items():
            count = cells.count(marker)
            if count:
                occurrences[runtime_type] += count
                room_numbers[runtime_type].add(room_index + 1)
    return occurrences, room_numbers, {
        runtime_type: tuple(sorted(values)) for runtime_type, values in markers.items()
    }


def build_catalog(prg: bytes, chr_data: bytes) -> dict[str, object]:
    if len(prg) != PRG_SIZE:
        raise ObjectCatalogError("expected a complete 32 KiB PRG")
    runtime_type_by_encoded = read_cpu_range(
        prg, room_data.RUNTIME_OBJECT_TYPES_CPU, room_data.RUNTIME_OBJECT_TYPE_COUNT
    )
    initial_state_by_encoded = {
        encoded_type: read_cpu_range(
            prg, room_data.RUNTIME_OBJECT_STATES_CPU + encoded_type, 1
        )[0]
        for encoded_type in range(
            room_data.RUNTIME_OBJECT_STATE_FIRST_TYPE,
            room_data.RUNTIME_OBJECT_STATE_END_TYPE,
        )
    }
    update_handlers = runtime_object_dispatch.decode_handler_pointers(prg)
    sprite_selectors = frame_sprites.decode_object_sprite_pointers(prg)
    collision_widths = read_cpu_range(
        prg, collision_tables.OBJECT_WIDTHS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    )
    collision_heights = read_cpu_range(
        prg, collision_tables.OBJECT_HEIGHTS_CPU, collision_tables.OBJECT_DIMENSION_COUNT
    )
    if update_handlers != runtime_object_dispatch.EXPECTED_HANDLER_POINTERS:
        raise ObjectCatalogError("runtime update-handler table changed")
    if sprite_selectors != frame_sprites.EXPECTED_OBJECT_SPRITE_HANDLERS:
        raise ObjectCatalogError("object sprite-selector table changed")
    if collision_widths != collision_tables.EXPECTED_WIDTHS:
        raise ObjectCatalogError("runtime collision-width table changed")
    if collision_heights != collision_tables.EXPECTED_HEIGHTS:
        raise ObjectCatalogError("runtime collision-height table changed")

    rooms = room_data.parse_object_stream(prg)
    static_counts, static_rooms, encoded_counts = group_static_objects(rooms)
    cell_counts, cell_rooms, cell_markers = group_cell_objects(prg, chr_data)
    if sum(static_counts.values()) != STATIC_OBJECT_COUNT:
        raise ObjectCatalogError("static object occurrence count changed")
    if sum(cell_counts.values()) != CELL_DERIVED_OBJECT_COUNT:
        raise ObjectCatalogError("cell-derived object occurrence count changed")

    encoded_types: dict[int, list[int]] = defaultdict(list)
    initial_states: dict[int, set[int]] = defaultdict(set)
    for encoded_type, runtime_type in enumerate(runtime_type_by_encoded):
        encoded_types[runtime_type].append(encoded_type)
        state = initial_state_by_encoded.get(encoded_type, 0)
        initial_states[runtime_type].add(state)

    entries: list[ObjectTypeEntry] = []
    for type_index in range(RUNTIME_TYPE_COUNT):
        runtime_type = RUNTIME_TYPE_FIRST + type_index
        dimensions = collision_tables.collision_dimensions(
            collision_widths,
            collision_heights,
            runtime_type,
        )
        entries.append(
            ObjectTypeEntry(
                runtime_type=runtime_type,
                type_index=type_index,
                encoded_types=tuple(encoded_types[runtime_type]),
                initial_states=tuple(sorted(initial_states[runtime_type])),
                static_occurrences=static_counts[runtime_type],
                static_rooms=tuple(sorted(static_rooms[runtime_type])),
                cell_markers=cell_markers.get(runtime_type, ()),
                cell_occurrences=cell_counts[runtime_type],
                cell_rooms=tuple(sorted(cell_rooms[runtime_type])),
                update_handler=update_handlers[type_index],
                sprite_selector=sprite_selectors[type_index],
                collision_width=dimensions.width,
                collision_height=dimensions.height,
            )
        )

    used_encoded_types = tuple(sorted(encoded_counts))
    if used_encoded_types != EXPECTED_USED_ENCODED_TYPES:
        raise ObjectCatalogError("used encoded-type domain changed")
    if dict(sorted(cell_counts.items())) != EXPECTED_CELL_TYPE_COUNTS:
        raise ObjectCatalogError("cell-derived runtime-type counts changed")
    if any(runtime_type < RUNTIME_TYPE_FIRST or runtime_type >= RUNTIME_TYPE_END
           for runtime_type in static_counts | cell_counts):
        raise ObjectCatalogError("room data creates a runtime type outside $80-$A9")
    if entries[0].sprite_selector != 0x6003:
        raise ObjectCatalogError("overlapping type-zero sprite pointer changed")
    if entries[0].update_handler != NO_OP_UPDATE_HANDLER:
        raise ObjectCatalogError("type-zero update handler changed")

    static_runtime_types = [
        entry.runtime_type for entry in entries if entry.static_occurrences
    ]
    cell_runtime_types = [
        entry.runtime_type for entry in entries if entry.cell_occurrences
    ]
    sourced_runtime_types = set(static_runtime_types) | set(cell_runtime_types)
    unsourced_runtime_types = tuple(
        entry.runtime_type
        for entry in entries
        if entry.runtime_type not in sourced_runtime_types
    )
    if len(static_runtime_types) != 27 or len(cell_runtime_types) != 5:
        raise ObjectCatalogError("room-sourced runtime-type counts changed")
    if unsourced_runtime_types != EXPECTED_UNSOURCED_RUNTIME_TYPES:
        raise ObjectCatalogError("unsourced runtime-type domain changed")
    if len(set(update_handlers)) != 16:
        raise ObjectCatalogError("unique update-handler count changed")
    if sum(handler == NO_OP_UPDATE_HANDLER for handler in update_handlers) != 23:
        raise ObjectCatalogError("no-op update-handler usage changed")
    if len(set(sprite_selectors[1:])) != 40:
        raise ObjectCatalogError("unique sprite-selector count changed")
    return {
        "runtime_type_range": [RUNTIME_TYPE_FIRST, RUNTIME_TYPE_END - 1],
        "runtime_types": len(entries),
        "used_runtime_types": sum(
            bool(entry.static_occurrences or entry.cell_occurrences) for entry in entries
        ),
        "static_runtime_types": static_runtime_types,
        "cell_runtime_types": cell_runtime_types,
        "unsourced_runtime_types": list(unsourced_runtime_types),
        "encoded_type_range": [0, room_data.RUNTIME_OBJECT_TYPE_COUNT - 1],
        "used_encoded_types": list(used_encoded_types),
        "static_objects": sum(static_counts.values()),
        "cell_derived_objects": sum(cell_counts.values()),
        "unique_update_handlers": len(set(update_handlers)),
        "no_op_update_types": sum(
            handler == NO_OP_UPDATE_HANDLER for handler in update_handlers
        ),
        "active_update_runtime_types": [
            RUNTIME_TYPE_FIRST + index
            for index, handler in enumerate(update_handlers)
            if handler != NO_OP_UPDATE_HANDLER
        ],
        "unique_sprite_selectors": len(set(sprite_selectors[1:])),
        "entries": [asdict(entry) for entry in entries],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    try:
        prg, chr_data = room_data.extract_rom(args.image.read_bytes())
        report = build_catalog(prg, chr_data)
    except (OSError, ObjectCatalogError, room_data.RoomDataError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            f"[OK] correlated {report['runtime_types']} runtime types, "
            f"{report['static_objects']} static objects, and "
            f"{report['cell_derived_objects']} cell-derived objects"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
