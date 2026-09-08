#!/usr/bin/env python3
"""Decode, validate, and rebuild all Castle Excellent rooms and objects."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
from typing import Any

from scripts.authoring import room_data
from scripts.build import revision_profiles
from scripts.build import atomic_io
from scripts.build.project import ProjectError, safe_asset_path


ROOT = Path(__file__).resolve().parents[2]


class LevelEditorError(ValueError):
    """Invalid editor configuration, workspace, or fixed-layout content."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise LevelEditorError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise LevelEditorError(f"expected a JSON object in {path}")
    return document


def project_path(relative: str) -> Path:
    try:
        return safe_asset_path(ROOT, relative)
    except ProjectError as exc:
        raise LevelEditorError(str(exc)) from exc


def load_authoring(path: Path, profile_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
    document = load_json(path)
    if document.get("schema_version") != 1:
        raise LevelEditorError("unsupported level-authoring schema")
    if document.get("format") != "castle-excellent-levels":
        raise LevelEditorError("unexpected level-authoring format")
    profiles = document.get("profiles")
    if not isinstance(profiles, list):
        raise LevelEditorError("level-authoring profiles are missing")
    matches = [item for item in profiles if item.get("id") == profile_id]
    if len(matches) != 1:
        raise LevelEditorError(f"unknown or duplicate authoring profile: {profile_id}")
    profile = matches[0]
    if profile.get("status") != "supported":
        raise LevelEditorError(f"level authoring is not supported for {profile_id}")
    for field in ("workspace", "output_rom", "report"):
        if not isinstance(profile.get(field), str) or not profile[field]:
            raise LevelEditorError(f"authoring profile {profile_id} has no {field}")
    validate_configuration(document)
    return document, profile


def parse_config_number(value: object, field: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise LevelEditorError(f"invalid integer for {field}: {value!r}")


def validate_configuration(config: dict[str, Any]) -> None:
    expected = {
        "room_count": room_data.ROOM_COUNT,
        "room_width": room_data.ROOM_WIDTH,
        "room_height": room_data.ROOM_HEIGHT,
    }
    for field, value in expected.items():
        if config.get(field) != value:
            raise LevelEditorError(f"{field} must be {value}")
    streams = config.get("room_streams", {})
    objects = config.get("objects", {})
    mutable = config.get("mutable_cells", {})
    address_contracts = {
        "room_streams.codebook_cpu": (streams.get("codebook_cpu"), room_data.CODEBOOK_CPU),
        "room_streams.pointer_table_cpu": (
            streams.get("pointer_table_cpu"),
            room_data.ROOM_POINTERS_CPU,
        ),
        "objects.stream_cpu": (objects.get("stream_cpu"), room_data.OBJECT_STREAM_CPU),
        "objects.stream_end_cpu": (
            objects.get("stream_end_cpu"),
            room_data.OBJECT_STREAM_END_CPU,
        ),
        "objects.count_table_cpu": (
            objects.get("count_table_cpu"),
            room_data.ROOM_OBJECT_COUNTS_CPU,
        ),
        "objects.state_offsets_cpu": (
            objects.get("state_offsets_cpu"),
            room_data.ROOM_OBJECT_STATE_OFFSETS_CPU,
        ),
        "mutable_cells.state_offsets_cpu": (
            mutable.get("state_offsets_cpu"),
            room_data.ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU,
        ),
    }
    for field, (declared, expected_value) in address_contracts.items():
        if parse_config_number(declared, field) != expected_value:
            raise LevelEditorError(f"{field} disagrees with the reconstructed source")
    stream_capacity = room_data.cpu_offset(room_data.OBJECT_STREAM_END_CPU) - room_data.cpu_offset(
        room_data.OBJECT_STREAM_CPU
    )
    if objects.get("stream_capacity") != stream_capacity:
        raise LevelEditorError("object stream capacity disagrees with its fixed range")
    if objects.get("state_capacity") != 141 or mutable.get("state_capacity") != 108:
        raise LevelEditorError("persistent-state capacities disagree with the RAM contract")
    banks = streams.get("banks")
    if not isinstance(banks, list) or len(banks) != 2:
        raise LevelEditorError("exactly two room-stream bank arenas are required")
    expected_banks = ((2, 1, 67, 0, 0x2000), (3, 68, 100, 0, 0x1400))
    for entry, expected_bank in zip(banks, expected_banks):
        actual = (
            entry.get("bank"),
            entry.get("first_room"),
            entry.get("last_room"),
            parse_config_number(entry.get("arena_start"), "arena_start"),
            parse_config_number(entry.get("arena_end"), "arena_end"),
        )
        if actual != expected_bank:
            raise LevelEditorError("room-stream bank arena disagrees with the ROM layout")


def load_base_image(
    revision_manifest: Path, profile_id: str
) -> tuple[dict[str, Any], bytes, bytes, bytes]:
    profiles = revision_profiles.load_profiles(revision_manifest)
    profile = revision_profiles.select_profile(profiles, profile_id)
    image_path = project_path(str(profile["output_rom"]))
    if not image_path.is_file():
        raise LevelEditorError(f"built profile image not found: {image_path}")
    image = image_path.read_bytes()
    revision_profiles.validate_reference(image, profile)
    prg, chr_data = room_data.extract_rom(image)
    return profile, image, prg, chr_data


def editable_object(record: dict[str, Any]) -> dict[str, int]:
    return {
        field: int(record[field])
        for field in ("encoded_type", "x", "y")
    }


def decode_workspace(profile_id: str, prg: bytes, chr_data: bytes) -> dict[str, Any]:
    object_rooms = room_data.parse_object_stream(prg)
    rooms = []
    for index in range(room_data.ROOM_COUNT):
        decoded = room_data.decode_room(prg, chr_data, index)
        rooms.append({
            "number": index + 1,
            "cells": decoded["cells"],
            "objects": [editable_object(record) for record in object_rooms[index]["objects"]],
        })
    return {
        "schema_version": 1,
        "format": "castle-excellent-levels",
        "profile": profile_id,
        "width": room_data.ROOM_WIDTH,
        "height": room_data.ROOM_HEIGHT,
        "rooms": rooms,
    }


def byte_value(value: object, field: str) -> int:
    if not isinstance(value, int) or not 0 <= value <= 0xFF:
        raise LevelEditorError(f"{field} must be a byte")
    return value


def validate_workspace(
    document: dict[str, Any], profile_id: str, prg: bytes
) -> list[dict[str, Any]]:
    header = {
        "schema_version": 1,
        "format": "castle-excellent-levels",
        "profile": profile_id,
        "width": room_data.ROOM_WIDTH,
        "height": room_data.ROOM_HEIGHT,
    }
    for field, expected in header.items():
        if document.get(field) != expected:
            raise LevelEditorError(f"workspace {field} must be {expected!r}")
    rooms = document.get("rooms")
    if not isinstance(rooms, list) or len(rooms) != room_data.ROOM_COUNT:
        raise LevelEditorError(f"workspace must contain {room_data.ROOM_COUNT} rooms")
    codebook = dict(room_data.parse_codebook(prg))
    validated: list[dict[str, Any]] = []
    for index, room in enumerate(rooms):
        if not isinstance(room, dict) or room.get("number") != index + 1:
            raise LevelEditorError(f"room {index + 1} has an invalid identity")
        rows = room.get("cells")
        if not isinstance(rows, list) or len(rows) != room_data.ROOM_HEIGHT:
            raise LevelEditorError(f"room {index + 1} must have 20 cell rows")
        cells = bytearray()
        for row_index, row in enumerate(rows):
            if not isinstance(row, list) or len(row) != room_data.ROOM_WIDTH:
                raise LevelEditorError(
                    f"room {index + 1} row {row_index + 1} must have 20 cells"
                )
            for column, value in enumerate(row):
                cell = byte_value(
                    value,
                    f"room {index + 1} cell {column + 1},{row_index + 1}",
                )
                if cell not in codebook:
                    raise LevelEditorError(
                        f"room {index + 1} cell ${cell:02X} has no compression code"
                    )
                cells.append(cell)
        objects = room.get("objects")
        if not isinstance(objects, list) or len(objects) > room_data.RUNTIME_OBJECT_RECORD_COUNT:
            raise LevelEditorError(f"room {index + 1} has too many static objects")
        validated_objects = []
        for object_index, record in enumerate(objects):
            if not isinstance(record, dict) or set(record) != {"encoded_type", "x", "y"}:
                raise LevelEditorError(
                    f"room {index + 1} object {object_index + 1} has invalid fields"
                )
            encoded_type = byte_value(record["encoded_type"], "encoded_type")
            x = byte_value(record["x"], "x")
            y = byte_value(record["y"], "y")
            if encoded_type >= room_data.RUNTIME_OBJECT_TYPE_COUNT:
                raise LevelEditorError(f"room {index + 1} has an invalid object type")
            if x >= room_data.ROOM_WIDTH or y >= room_data.ROOM_HEIGHT:
                raise LevelEditorError(f"room {index + 1} object is outside the room grid")
            validated_objects.append({"encoded_type": encoded_type, "x": x, "y": y})
        _converted, spawned = room_data.spawn_room_cell_objects(
            bytes(cells), len(validated_objects)
        )
        if len(validated_objects) + len(spawned) > room_data.RUNTIME_OBJECT_RECORD_COUNT:
            raise LevelEditorError(f"room {index + 1} overflows the runtime object pool")
        validated.append({
            "number": index + 1,
            "cells": bytes(cells),
            "objects": validated_objects,
        })
    return validated


def cumulative_state_offsets(
    rooms: list[dict[str, Any]], *, mutable: bool, capacity: int
) -> bytes:
    offsets = [0]
    for index, room in enumerate(rooms):
        if mutable:
            count = sum(
                cell in room_data.PERSISTENT_MUTABLE_CELL_VALUES
                for cell in room["cells"]
            )
            width = (count + 7) // 8
            if index == room_data.ROOM_COUNT - 1:
                width = max(width, room_data.FINAL_ROOM_MUTABLE_STATE_BYTES)
        else:
            width = (len(room["objects"]) + 7) // 8
        offsets.append(offsets[-1] + width)
    if offsets[-1] > capacity:
        kind = "mutable-cell" if mutable else "object"
        raise LevelEditorError(
            f"{kind} persistent state needs {offsets[-1]} bytes, capacity is {capacity}"
        )
    return bytes(offsets)


def write_cpu(prg: bytearray, address: int, payload: bytes) -> None:
    start = room_data.cpu_offset(address)
    end = start + len(payload)
    if end > len(prg):
        raise LevelEditorError(f"write at CPU ${address:04X} exceeds PRG")
    prg[start:end] = payload


def compose_levels(
    image: bytes,
    prg: bytes,
    chr_data: bytes,
    rooms: list[dict[str, Any]],
    config: dict[str, Any],
) -> tuple[bytes, dict[str, Any]]:
    output_prg = bytearray(prg)
    output_chr = bytearray(chr_data)
    codebook = room_data.parse_codebook(prg)
    pointers = bytearray(room_data.ROOM_COUNT * 2)
    bank_reports = []
    for bank_entry in config["room_streams"]["banks"]:
        bank = int(bank_entry["bank"])
        first = int(bank_entry["first_room"]) - 1
        last = int(bank_entry["last_room"])
        arena_start = parse_config_number(bank_entry["arena_start"], "arena_start")
        arena_end = parse_config_number(bank_entry["arena_end"], "arena_end")
        cursor = arena_start
        for room_index in range(first, last):
            encoded, _padding = room_data.encode_prefix_stream(
                rooms[room_index]["cells"], codebook
            )
            if cursor + len(encoded) > arena_end:
                raise LevelEditorError(
                    f"room {room_index + 1} overflows CHR bank {bank} room capacity"
                )
            pointers[room_index * 2:room_index * 2 + 2] = cursor.to_bytes(2, "little")
            start = bank * room_data.CHR_BANK_SIZE + cursor
            output_chr[start:start + len(encoded)] = encoded
            cursor += len(encoded)
        fill_start = bank * room_data.CHR_BANK_SIZE + cursor
        fill_end = bank * room_data.CHR_BANK_SIZE + arena_end
        output_chr[fill_start:fill_end] = bytes([0xFF]) * (fill_end - fill_start)
        bank_reports.append({
            "bank": bank,
            "used_bytes": cursor - arena_start,
            "capacity_bytes": arena_end - arena_start,
            "free_bytes": arena_end - cursor,
        })
    write_cpu(output_prg, room_data.ROOM_POINTERS_CPU, bytes(pointers))

    object_rooms = [{"objects": room["objects"]} for room in rooms]
    object_stream = room_data.encode_object_stream(object_rooms)
    object_capacity = int(config["objects"]["stream_capacity"])
    if len(object_stream) > object_capacity:
        raise LevelEditorError(
            f"object stream needs {len(object_stream)} bytes, capacity is {object_capacity}"
        )
    object_payload = object_stream + bytes([0xFF]) * (object_capacity - len(object_stream))
    write_cpu(output_prg, room_data.OBJECT_STREAM_CPU, object_payload)
    write_cpu(
        output_prg,
        room_data.ROOM_OBJECT_COUNTS_CPU,
        bytes(len(room["objects"]) for room in rooms),
    )
    object_offsets = cumulative_state_offsets(
        rooms,
        mutable=False,
        capacity=int(config["objects"]["state_capacity"]),
    )
    mutable_offsets = cumulative_state_offsets(
        rooms,
        mutable=True,
        capacity=int(config["mutable_cells"]["state_capacity"]),
    )
    write_cpu(output_prg, room_data.ROOM_OBJECT_STATE_OFFSETS_CPU, object_offsets)
    write_cpu(output_prg, room_data.ROOM_MUTABLE_CELL_STATE_OFFSETS_CPU, mutable_offsets)

    header_size = len(image) - len(prg) - len(chr_data)
    output = image[:header_size] + bytes(output_prg) + bytes(output_chr)
    report = {
        "schema_version": 1,
        "format": "castle-excellent-level-build",
        "rom_size": len(output),
        "rom_sha256": hashlib.sha256(output).hexdigest(),
        "changed_bytes": sum(left != right for left, right in zip(image, output)),
        "room_banks": bank_reports,
        "object_stream": {
            "used_bytes": len(object_stream),
            "capacity_bytes": object_capacity,
            "free_bytes": object_capacity - len(object_stream),
        },
        "object_state_bytes": object_offsets[-1],
        "mutable_cell_state_bytes": mutable_offsets[-1],
    }
    return output, report


def atomic_write(path: Path, payload: bytes) -> None:
    atomic_io.atomic_write_bytes(path, payload)


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    atomic_io.atomic_write_json(path, document)


def run(args: argparse.Namespace) -> None:
    config, authoring_profile = load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = load_base_image(
        Path(args.revisions), args.profile
    )
    workspace_path = project_path(authoring_profile["workspace"])
    if args.command in {"init", "export"}:
        document = decode_workspace(args.profile, prg, chr_data)
        if args.command == "init" and workspace_path.exists():
            validate_workspace(load_json(workspace_path), args.profile, prg)
            print(f"[OK] existing level workspace: {workspace_path}")
            return
        atomic_write_json(workspace_path, document)
        print(f"[WRITE] {workspace_path} ({room_data.ROOM_COUNT} rooms)")
        return
    if args.command == "roundtrip":
        document = decode_workspace(args.profile, prg, chr_data)
    else:
        if not workspace_path.is_file():
            raise LevelEditorError(
                f"level workspace not found: {workspace_path}; run init-levels first"
            )
        document = load_json(workspace_path)
    rooms = validate_workspace(document, args.profile, prg)
    output, report = compose_levels(image, prg, chr_data, rooms, config)
    if args.command == "roundtrip":
        if output != image:
            difference = revision_profiles.first_difference(output, image)
            raise LevelEditorError(
                f"zero-edit level round trip differs at file offset ${difference:04X}"
            )
        print(
            f"[OK] zero-edit level round trip: {len(rooms)} rooms, "
            f"{report['object_stream']['used_bytes']} object bytes"
        )
        return
    if args.command == "validate":
        print(
            f"[OK] valid level workspace: {len(rooms)} rooms, "
            f"{report['changed_bytes']} changed ROM bytes"
        )
        return
    output_path = project_path(authoring_profile["output_rom"])
    report_path = project_path(authoring_profile["report"])
    atomic_write(output_path, output)
    report["profile"] = args.profile
    report["workspace"] = authoring_profile["workspace"]
    atomic_write_json(report_path, report)
    print(
        f"[WRITE] {output_path}: {report['changed_bytes']} changed bytes, "
        f"SHA-256 {report['rom_sha256']}"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "export", "validate", "build", "roundtrip"))
    parser.add_argument("--authoring", default="config/authoring/levels.json")
    parser.add_argument("--revisions", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        run(args)
    except (OSError, ProjectError, LevelEditorError, room_data.RoomDataError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
