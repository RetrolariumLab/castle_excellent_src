#!/usr/bin/env python3
"""Decode, validate, and rebuild Castle Excellent graphics and display data."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
from typing import Any

from scripts.authoring import room_data
from scripts.build import revision_profiles
from scripts.build.project import ProjectError, safe_asset_path


ROOT = Path(__file__).resolve().parents[2]
TILE_BYTES = 16
TILE_COUNT = 512
EDITABLE_CHR_BANKS = (0, 1)
RANGES = {
    "metasprite_descriptors": (0xB4B6, 406),
    "sound_effect_tables": (0xC429, 20),
    "screen_palette_storage": (0xC4FD, 64),
    "room_palette": (0xC53D, 32),
    "room_cell_attributes": (0xE9D2, 100),
    "sub_command_text": (0xFB77, 53),
    "room_cell_tiles": (0xFF30, 200),
}
TEXT_BLOCKS = (
    ("title", 12),
    ("load", 5),
    ("save", 5),
    ("reset", 6),
    ("back", 5),
    ("game", 5),
    ("loading", 8),
    ("saving", 7),
)
SOUND_EFFECT_TABLES = (
    ("triangle_type_2_period_low", 4),
    ("inventory_period_low", 4),
    ("noise_type_4_volume", 4),
    ("noise_type_4_period", 4),
    ("noise_type_4_length", 4),
)


class GraphicsEditorError(ValueError):
    """Invalid graphics configuration, workspace, or fixed-layout encoding."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise GraphicsEditorError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise GraphicsEditorError(f"expected a JSON object in {path}")
    return document


def project_path(relative: str) -> Path:
    try:
        return safe_asset_path(ROOT, relative)
    except ProjectError as exc:
        raise GraphicsEditorError(str(exc)) from exc


def parse_number(value: object, field: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value, 0)
        except ValueError:
            pass
    raise GraphicsEditorError(f"invalid integer for {field}: {value!r}")


def load_authoring(path: Path, profile_id: str) -> tuple[dict[str, Any], dict[str, Any]]:
    document = load_json(path)
    if (
        document.get("schema_version") != 1
        or document.get("format") != "castle-excellent-graphics"
    ):
        raise GraphicsEditorError("unsupported graphics-authoring manifest")
    if tuple(document.get("editable_chr_banks", ())) != EDITABLE_CHR_BANKS:
        raise GraphicsEditorError("editable CHR bank contract changed")
    ranges = document.get("ranges")
    if not isinstance(ranges, dict) or set(ranges) != set(RANGES):
        raise GraphicsEditorError("graphics range contract is incomplete")
    for identifier, (address, size) in RANGES.items():
        record = ranges[identifier]
        if not isinstance(record, dict):
            raise GraphicsEditorError(f"range {identifier} is not an object")
        if parse_number(record.get("cpu"), f"{identifier} CPU") != address:
            raise GraphicsEditorError(f"range {identifier} CPU address changed")
        if parse_number(record.get("size"), f"{identifier} size") != size:
            raise GraphicsEditorError(f"range {identifier} size changed")
    profiles = document.get("profiles")
    if not isinstance(profiles, list):
        raise GraphicsEditorError("graphics-authoring profiles are missing")
    matches = [entry for entry in profiles if entry.get("id") == profile_id]
    if len(matches) != 1 or matches[0].get("status") != "supported":
        raise GraphicsEditorError(f"graphics authoring is not supported for {profile_id}")
    profile = matches[0]
    for field in ("workspace", "output_rom", "report"):
        if not isinstance(profile.get(field), str) or not profile[field]:
            raise GraphicsEditorError(f"authoring profile {profile_id} has no {field}")
    return document, profile


def load_base_image(
    revisions: Path, profile_id: str
) -> tuple[dict[str, Any], bytes, bytes, bytes]:
    manifest = revision_profiles.load_profiles(revisions)
    profile = revision_profiles.select_profile(manifest, profile_id)
    image_path = project_path(str(profile["output_rom"]))
    if not image_path.is_file():
        raise GraphicsEditorError(f"built profile image not found: {image_path}")
    image = image_path.read_bytes()
    revision_profiles.validate_reference(image, profile)
    prg, chr_data = room_data.extract_rom(image)
    return profile, image, prg, chr_data


def read_cpu(prg: bytes, address: int, size: int) -> bytes:
    start = room_data.cpu_offset(address)
    payload = prg[start : start + size]
    if len(payload) != size:
        raise GraphicsEditorError(f"truncated PRG range at ${address:04X}")
    return payload


def decode_tile(payload: bytes) -> list[list[int]]:
    if len(payload) != TILE_BYTES:
        raise GraphicsEditorError("NES tile must contain 16 bytes")
    return [
        [
            ((payload[row] >> (7 - column)) & 1)
            | (((payload[row + 8] >> (7 - column)) & 1) << 1)
            for column in range(8)
        ]
        for row in range(8)
    ]


def encode_tile(rows: object, field: str) -> bytes:
    if not isinstance(rows, list) or len(rows) != 8:
        raise GraphicsEditorError(f"{field} must contain eight rows")
    low = bytearray(8)
    high = bytearray(8)
    for row_index, row in enumerate(rows):
        if not isinstance(row, list) or len(row) != 8:
            raise GraphicsEditorError(f"{field} row {row_index} must contain eight pixels")
        for column, pixel in enumerate(row):
            if not isinstance(pixel, int) or not 0 <= pixel <= 3:
                raise GraphicsEditorError(f"{field} pixels must be between 0 and 3")
            low[row_index] |= (pixel & 1) << (7 - column)
            high[row_index] |= ((pixel >> 1) & 1) << (7 - column)
    return bytes(low + high)


def split_records(payload: bytes, definitions: tuple[tuple[str, int], ...]) -> list[dict[str, Any]]:
    cursor = 0
    records = []
    for identifier, size in definitions:
        records.append({"id": identifier, "values": list(payload[cursor : cursor + size])})
        cursor += size
    if cursor != len(payload):
        raise GraphicsEditorError("fixed record definitions do not cover their payload")
    return records


def decode_workspace(profile_id: str, prg: bytes, chr_data: bytes) -> dict[str, Any]:
    banks = []
    for bank_index in EDITABLE_CHR_BANKS:
        start = bank_index * room_data.CHR_BANK_SIZE
        payload = chr_data[start : start + room_data.CHR_BANK_SIZE]
        if len(payload) != room_data.CHR_BANK_SIZE:
            raise GraphicsEditorError(f"CHR bank {bank_index} is unavailable")
        banks.append(
            {
                "index": bank_index,
                "tiles": [
                    decode_tile(payload[index * TILE_BYTES : (index + 1) * TILE_BYTES])
                    for index in range(TILE_COUNT)
                ],
            }
        )
    left_right = read_cpu(prg, *RANGES["room_cell_tiles"])
    attributes = read_cpu(prg, *RANGES["room_cell_attributes"])
    cells = []
    for index in range(100):
        value = attributes[index]
        if value not in (0x00, 0x55, 0xAA, 0xFF):
            raise GraphicsEditorError(f"cell {index} has non-replicated palette bits")
        cells.append(
            {
                "index": index,
                "left_tile": left_right[index],
                "right_tile": left_right[100 + index],
                "palette": value & 3,
            }
        )
    metasprites = read_cpu(prg, *RANGES["metasprite_descriptors"])
    return {
        "schema_version": 1,
        "format": "castle-excellent-graphics",
        "profile": profile_id,
        "chr_banks": banks,
        "room_cells": cells,
        "screen_palette_storage": list(
            read_cpu(prg, *RANGES["screen_palette_storage"])
        ),
        "room_palette": list(read_cpu(prg, *RANGES["room_palette"])),
        "metasprite_descriptors": [
            {"index": index, "tile": metasprites[index * 2], "attributes": metasprites[index * 2 + 1]}
            for index in range(len(metasprites) // 2)
        ],
        "sub_command_text": split_records(
            read_cpu(prg, *RANGES["sub_command_text"]), TEXT_BLOCKS
        ),
        "sound_effect_tables": split_records(
            read_cpu(prg, *RANGES["sound_effect_tables"]), SOUND_EFFECT_TABLES
        ),
    }


def byte_value(value: object, field: str, maximum: int = 0xFF) -> int:
    if not isinstance(value, int) or not 0 <= value <= maximum:
        raise GraphicsEditorError(f"{field} must be between 0 and {maximum}")
    return value


def validate_byte_list(value: object, size: int, field: str, maximum: int = 0xFF) -> bytes:
    if not isinstance(value, list) or len(value) != size:
        raise GraphicsEditorError(f"{field} must contain exactly {size} bytes")
    return bytes(byte_value(item, field, maximum) for item in value)


def join_records(
    value: object, definitions: tuple[tuple[str, int], ...], field: str
) -> bytes:
    if not isinstance(value, list) or len(value) != len(definitions):
        raise GraphicsEditorError(f"{field} record count changed")
    payload = bytearray()
    for index, (identifier, size) in enumerate(definitions):
        record = value[index]
        if not isinstance(record, dict) or set(record) != {"id", "values"}:
            raise GraphicsEditorError(f"{field} record {index} has invalid fields")
        if record["id"] != identifier:
            raise GraphicsEditorError(f"{field} record {index} must be {identifier}")
        payload.extend(validate_byte_list(record["values"], size, identifier))
    return bytes(payload)


def validate_workspace(document: dict[str, Any], profile_id: str) -> dict[str, bytes]:
    expected = {
        "schema_version": 1,
        "format": "castle-excellent-graphics",
        "profile": profile_id,
    }
    for field, value in expected.items():
        if document.get(field) != value:
            raise GraphicsEditorError(f"workspace {field} must be {value!r}")
    raw_banks = document.get("chr_banks")
    if not isinstance(raw_banks, list) or len(raw_banks) != len(EDITABLE_CHR_BANKS):
        raise GraphicsEditorError("workspace must contain two editable CHR banks")
    chr_payload = bytearray()
    for position, bank_index in enumerate(EDITABLE_CHR_BANKS):
        bank = raw_banks[position]
        if not isinstance(bank, dict) or set(bank) != {"index", "tiles"}:
            raise GraphicsEditorError(f"CHR bank {bank_index} has invalid fields")
        if bank["index"] != bank_index:
            raise GraphicsEditorError(f"CHR bank position {position} must be bank {bank_index}")
        tiles = bank["tiles"]
        if not isinstance(tiles, list) or len(tiles) != TILE_COUNT:
            raise GraphicsEditorError(
                f"CHR bank {bank_index} must contain {TILE_COUNT} tiles"
            )
        for tile_index, tile in enumerate(tiles):
            chr_payload.extend(encode_tile(tile, f"bank {bank_index} tile {tile_index}"))
    raw_cells = document.get("room_cells")
    if not isinstance(raw_cells, list) or len(raw_cells) != 100:
        raise GraphicsEditorError("workspace must contain 100 room-cell visuals")
    left = bytearray()
    right = bytearray()
    attributes = bytearray()
    for index, cell in enumerate(raw_cells):
        if not isinstance(cell, dict) or set(cell) != {
            "index",
            "left_tile",
            "right_tile",
            "palette",
        }:
            raise GraphicsEditorError(f"room cell {index} has invalid fields")
        if cell["index"] != index:
            raise GraphicsEditorError(f"room cell position {index} has wrong index")
        left.append(byte_value(cell["left_tile"], f"cell {index} left tile"))
        right.append(byte_value(cell["right_tile"], f"cell {index} right tile"))
        palette = byte_value(cell["palette"], f"cell {index} palette", 3)
        attributes.append(palette * 0x55)
    descriptors = document.get("metasprite_descriptors")
    if not isinstance(descriptors, list) or len(descriptors) != 203:
        raise GraphicsEditorError("workspace must contain 203 metasprite descriptors")
    metasprites = bytearray()
    for index, descriptor in enumerate(descriptors):
        if not isinstance(descriptor, dict) or set(descriptor) != {
            "index",
            "tile",
            "attributes",
        }:
            raise GraphicsEditorError(f"metasprite descriptor {index} has invalid fields")
        if descriptor["index"] != index:
            raise GraphicsEditorError(f"metasprite descriptor {index} has wrong index")
        metasprites.append(byte_value(descriptor["tile"], f"descriptor {index} tile"))
        metasprites.append(
            byte_value(descriptor["attributes"], f"descriptor {index} attributes")
        )
    return {
        "chr_banks": bytes(chr_payload),
        "room_cell_tiles": bytes(left + right),
        "room_cell_attributes": bytes(attributes),
        "screen_palette_storage": validate_byte_list(
            document.get("screen_palette_storage"), 64, "screen palette", 0x3F
        ),
        "room_palette": validate_byte_list(
            document.get("room_palette"), 32, "room palette", 0x3F
        ),
        "metasprite_descriptors": bytes(metasprites),
        "sub_command_text": join_records(
            document.get("sub_command_text"), TEXT_BLOCKS, "sub-command text"
        ),
        "sound_effect_tables": join_records(
            document.get("sound_effect_tables"), SOUND_EFFECT_TABLES, "sound-effect tables"
        ),
    }


def write_cpu(prg: bytearray, identifier: str, payload: bytes) -> None:
    address, expected_size = RANGES[identifier]
    if len(payload) != expected_size:
        raise GraphicsEditorError(f"{identifier} encoded size changed")
    start = room_data.cpu_offset(address)
    prg[start : start + expected_size] = payload


def compose_graphics(
    image: bytes, prg: bytes, chr_data: bytes, validated: dict[str, bytes]
) -> tuple[bytes, dict[str, Any]]:
    output_prg = bytearray(prg)
    for identifier in RANGES:
        write_cpu(output_prg, identifier, validated[identifier])
    output_chr = bytearray(chr_data)
    editable_size = len(EDITABLE_CHR_BANKS) * room_data.CHR_BANK_SIZE
    output_chr[:editable_size] = validated["chr_banks"]
    header_size = len(image) - len(prg) - len(chr_data)
    output = image[:header_size] + bytes(output_prg) + bytes(output_chr)
    prg_changes = sum(left != right for left, right in zip(prg, output_prg))
    chr_changes = sum(left != right for left, right in zip(chr_data, output_chr))
    return output, {
        "schema_version": 1,
        "format": "castle-excellent-graphics-build",
        "rom_size": len(output),
        "rom_sha256": hashlib.sha256(output).hexdigest(),
        "changed_bytes": prg_changes + chr_changes,
        "prg_changed_bytes": prg_changes,
        "chr_changed_bytes": chr_changes,
        "editable_chr_banks": list(EDITABLE_CHR_BANKS),
        "room_cell_count": 100,
        "metasprite_descriptor_count": 203,
    }


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(payload)
    os.replace(temporary, path)


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    atomic_write(path, (json.dumps(document, indent=2) + "\n").encode("utf-8"))


def run(args: argparse.Namespace) -> None:
    _config, authoring_profile = load_authoring(Path(args.authoring), args.profile)
    _revision, image, prg, chr_data = load_base_image(Path(args.revisions), args.profile)
    workspace_path = project_path(authoring_profile["workspace"])
    if args.command in {"init", "export"}:
        document = decode_workspace(args.profile, prg, chr_data)
        if args.command == "init" and workspace_path.exists():
            validate_workspace(load_json(workspace_path), args.profile)
            print(f"[OK] existing graphics workspace: {workspace_path}")
            return
        atomic_write_json(workspace_path, document)
        print(f"[WRITE] {workspace_path} (1024 tiles, 100 room-cell visuals)")
        return
    document = (
        decode_workspace(args.profile, prg, chr_data)
        if args.command == "roundtrip"
        else load_json(workspace_path)
    )
    validated = validate_workspace(document, args.profile)
    output, report = compose_graphics(image, prg, chr_data, validated)
    if args.command == "roundtrip":
        if output != image:
            difference = revision_profiles.first_difference(output, image)
            raise GraphicsEditorError(
                f"zero-edit graphics round trip differs at file offset ${difference:04X}"
            )
        print("[OK] zero-edit graphics round trip: 1024 tiles, 100 cells, 203 descriptors")
        return
    if args.command == "validate":
        print(f"[OK] valid graphics workspace: {report['changed_bytes']} changed ROM bytes")
        return
    output_path = project_path(authoring_profile["output_rom"])
    report_path = project_path(authoring_profile["report"])
    atomic_write(output_path, output)
    report["profile"] = args.profile
    report["workspace"] = authoring_profile["workspace"]
    atomic_write_json(report_path, report)
    print(f"[WRITE] {output_path}: {report['changed_bytes']} changed bytes")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "export", "validate", "build", "roundtrip"))
    parser.add_argument("--authoring", default="config/graphics_authoring.json")
    parser.add_argument("--revisions", default="config/revision_profiles.json")
    parser.add_argument("--profile", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        run(args)
    except (
        OSError,
        ProjectError,
        GraphicsEditorError,
        room_data.RoomDataError,
    ) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
