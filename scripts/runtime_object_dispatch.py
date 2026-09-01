#!/usr/bin/env python3
"""Model Castle Excellent's 24-record runtime-object frame dispatcher."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
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


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise RuntimeObjectDispatchError(f"{name} outside 0-255: {value}")


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
    pointers = decode_handler_pointers(read_prg(image_path))
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
    return {
        "handler_table_address": HANDLER_TABLE_ADDRESS,
        "handler_count": len(pointers),
        "unique_handlers": len(set(pointers)),
        "record_count": RECORD_COUNT,
        "record_size": RECORD_SIZE,
        "record_offsets": list(expected_offsets),
        "dispatch_cases_checked": dispatch_cases,
        "skipped_cases_checked": skipped_cases,
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
            f"{document['handler_count']} handler pointers"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
