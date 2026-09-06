#!/usr/bin/env python3
"""Display model shared by the Castle Excellent Graphics Studio and its tests."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Sequence

import graphics_editor
from level_studio_model import NES_RGB


PATTERN_TABLE_TILES = 256
BACKGROUND_PATTERN_TABLE = 1


class GraphicsStudioModelError(ValueError):
    """The visual model cannot be derived from the graphics workspace."""


@dataclass(frozen=True)
class StudioSummary:
    bank_count: int
    tile_count: int
    room_cell_count: int
    metasprite_descriptor_count: int
    text_block_count: int
    sound_effect_table_count: int


def parse_byte(text: str, field: str, maximum: int = 0xFF) -> int:
    value = text.strip()
    if value.startswith("$"):
        value = "0x" + value[1:]
    try:
        number = int(value, 0)
    except ValueError as exc:
        raise GraphicsStudioModelError(f"invalid {field}: {text!r}") from exc
    if not 0 <= number <= maximum:
        raise GraphicsStudioModelError(f"{field} must be between 0 and {maximum}")
    return number


def parse_byte_sequence(text: str, size: int, field: str) -> list[int]:
    parts = text.replace(",", " ").split()
    if len(parts) != size:
        raise GraphicsStudioModelError(f"{field} must contain exactly {size} bytes")
    return [parse_byte(part, field) for part in parts]


def format_byte_sequence(values: Sequence[int]) -> str:
    return " ".join(f"{value:02X}" for value in values)


def palette_groups(document: dict[str, Any], source: str) -> tuple[tuple[int, ...], ...]:
    field = "room_palette" if source == "room" else "screen_palette_storage"
    values = document.get(field)
    if not isinstance(values, list) or len(values) % 4:
        raise GraphicsStudioModelError(f"invalid {source} palette storage")
    return tuple(tuple(values[index : index + 4]) for index in range(0, len(values), 4))


def tile_colors(
    document: dict[str, Any], bank: int, tile: int, palette: Sequence[int]
) -> tuple[tuple[str, ...], ...]:
    try:
        rows = document["chr_banks"][bank]["tiles"][tile]
    except (IndexError, KeyError, TypeError) as exc:
        raise GraphicsStudioModelError("tile selection is outside the workspace") from exc
    if len(palette) != 4:
        raise GraphicsStudioModelError("tile preview palette must contain four entries")
    try:
        return tuple(
            tuple(NES_RGB[palette[pixel] & 0x3F] for pixel in row) for row in rows
        )
    except (IndexError, TypeError) as exc:
        raise GraphicsStudioModelError("tile pixels or palette values are invalid") from exc


def room_cell_colors(
    document: dict[str, Any], cell_index: int
) -> tuple[tuple[str, ...], ...]:
    try:
        record = document["room_cells"][cell_index]
        palette_index = int(record["palette"])
        palette = document["room_palette"][palette_index * 4 : palette_index * 4 + 4]
        left = int(record["left_tile"]) + BACKGROUND_PATTERN_TABLE * PATTERN_TABLE_TILES
        right = int(record["right_tile"]) + BACKGROUND_PATTERN_TABLE * PATTERN_TABLE_TILES
    except (IndexError, KeyError, TypeError, ValueError) as exc:
        raise GraphicsStudioModelError("room-cell preview record is invalid") from exc
    left_colors = tile_colors(document, 0, left, palette)
    right_colors = tile_colors(document, 0, right, palette)
    return tuple(left_colors[row] + right_colors[row] for row in range(8))


def hardware_sprite_pixels(
    document: dict[str, Any], chr_bank: int, tile: int, attributes: int
) -> tuple[tuple[int, ...], ...]:
    top = (tile & 1) * PATTERN_TABLE_TILES + (tile & 0xFE)
    try:
        tiles = document["chr_banks"][chr_bank]["tiles"]
        rows = [tuple(row) for index in (top, top + 1) for row in tiles[index]]
    except (IndexError, KeyError, TypeError) as exc:
        raise GraphicsStudioModelError("metasprite tile is outside editable CHR") from exc
    if attributes & 0x40:
        rows = [tuple(reversed(row)) for row in rows]
    if attributes & 0x80:
        rows.reverse()
    return tuple(rows)


def descriptor_colors(
    document: dict[str, Any], descriptor_index: int, chr_bank: int = 0
) -> tuple[tuple[str | None, ...], ...]:
    try:
        descriptor = document["metasprite_descriptors"][descriptor_index]
        tile = int(descriptor["tile"])
        attributes = int(descriptor["attributes"])
        palette_index = 4 + (attributes & 3)
        palette = document["room_palette"][palette_index * 4 : palette_index * 4 + 4]
    except (IndexError, KeyError, TypeError, ValueError) as exc:
        raise GraphicsStudioModelError("metasprite descriptor is invalid") from exc
    pixels = hardware_sprite_pixels(document, chr_bank, tile, attributes)
    return tuple(
        tuple(None if pixel == 0 else NES_RGB[palette[pixel] & 0x3F] for pixel in row)
        for row in pixels
    )


def summarize(document: dict[str, Any], profile_id: str) -> StudioSummary:
    graphics_editor.validate_workspace(document, profile_id)
    return StudioSummary(
        bank_count=len(document["chr_banks"]),
        tile_count=sum(len(bank["tiles"]) for bank in document["chr_banks"]),
        room_cell_count=len(document["room_cells"]),
        metasprite_descriptor_count=len(document["metasprite_descriptors"]),
        text_block_count=len(document["sub_command_text"]),
        sound_effect_table_count=len(document["sound_effect_tables"]),
    )
