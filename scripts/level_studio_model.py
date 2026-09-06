#!/usr/bin/env python3
"""Display model shared by the Castle Excellent level studio and its tests."""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Any, Sequence

import room_data
import frame_sprites
import metasprites


NES_RGB = (
    "#626262", "#001fb2", "#2404c8", "#5200b2", "#730076", "#800024", "#730b00", "#522800",
    "#244400", "#005700", "#005c00", "#005324", "#003c76", "#000000", "#000000", "#000000",
    "#ababab", "#0d57ff", "#4b30ff", "#8a13ff", "#bc08d6", "#d21269", "#c72e00", "#9d5400",
    "#607b00", "#209800", "#00a300", "#009942", "#007db4", "#000000", "#000000", "#000000",
    "#ffffff", "#53aeff", "#9085ff", "#d365ff", "#ff57ff", "#ff5dcf", "#ff7757", "#fa9e00",
    "#bdc700", "#7ae700", "#43f611", "#26ef7e", "#2cd5f6", "#4e4e4e", "#000000", "#000000",
    "#ffffff", "#b6e1ff", "#ced1ff", "#e9c3ff", "#ffbcff", "#ffbdf4", "#ffc6c3", "#ffd59a",
    "#e9e681", "#cef481", "#b6fb9a", "#a9fac3", "#a9f0f4", "#b8b8b8", "#000000", "#000000",
)

LEFT_TILE_CPU = 0xFF30
RIGHT_TILE_CPU = 0xFF94
ROOM_PALETTE_CPU = 0xC53D
TILE_BYTES = 16
PATTERN_TABLE_TILES = 256
TILES_PER_BANK = 512
BACKGROUND_PATTERN_TABLE = 1
ROOM_PALETTE_BYTES = 32

OBJECT_RENDER_X_OFFSETS = {
    "object_one": (0,),
    "object_two": (0, 8),
    "object_four": (0, 8, 16, 24),
    "object_two_compact": (0, 4),
}


class LevelStudioModelError(ValueError):
    """The visual model cannot be derived from the reconstructed data."""


@dataclass(frozen=True)
class CellVisual:
    cell_type: int
    left_tile: int
    right_tile: int
    palette_index: int


@dataclass(frozen=True)
class ObjectVisual:
    index: int
    encoded_type: int
    runtime_type: int
    x: int
    y: int
    sprites: tuple["SpriteVisual", ...]


@dataclass(frozen=True)
class SpriteVisual:
    tile: int
    attributes: int
    x: int
    y: int


def read_cpu(prg: bytes, address: int, size: int) -> bytes:
    start = room_data.cpu_offset(address)
    payload = prg[start:start + size]
    if len(payload) != size:
        raise LevelStudioModelError(f"truncated PRG data at ${address:04X}")
    return payload


def decode_chr_bank(chr_data: bytes, bank: int = 0) -> tuple[tuple[tuple[int, ...], ...], ...]:
    start = bank * room_data.CHR_BANK_SIZE
    payload = chr_data[start:start + room_data.CHR_BANK_SIZE]
    if len(payload) != room_data.CHR_BANK_SIZE:
        raise LevelStudioModelError(f"CHR bank {bank} is unavailable")
    tiles = []
    for tile_index in range(TILES_PER_BANK):
        tile = payload[tile_index * TILE_BYTES:(tile_index + 1) * TILE_BYTES]
        rows = []
        for row in range(8):
            low = tile[row]
            high = tile[row + 8]
            rows.append(tuple(
                ((low >> (7 - column)) & 1) | (((high >> (7 - column)) & 1) << 1)
                for column in range(8)
            ))
        tiles.append(tuple(rows))
    return tuple(tiles)


def room_palettes(prg: bytes) -> tuple[tuple[int, ...], ...]:
    payload = read_cpu(prg, ROOM_PALETTE_CPU, ROOM_PALETTE_BYTES)
    return tuple(tuple(payload[index:index + 4]) for index in range(0, 32, 4))


def room_palette(prg: bytes) -> tuple[tuple[int, ...], ...]:
    return room_palettes(prg)[:4]


def sprite_palette(prg: bytes) -> tuple[tuple[int, ...], ...]:
    return room_palettes(prg)[4:]


def cell_tile_pair(prg: bytes, cell_type: int) -> tuple[int, int]:
    if not 0 <= cell_type < 100:
        raise LevelStudioModelError(f"cell type outside 0-99: {cell_type}")
    return (
        read_cpu(prg, LEFT_TILE_CPU + cell_type, 1)[0],
        read_cpu(prg, RIGHT_TILE_CPU + cell_type, 1)[0],
    )


def room_cell_palettes(prg: bytes, cells: Sequence[int]) -> tuple[int, ...]:
    payload = bytes(cells)
    if len(payload) != room_data.ROOM_SIZE:
        raise LevelStudioModelError(
            f"room has {len(payload)} cells, expected {room_data.ROOM_SIZE}"
        )
    attributes = room_data.build_room_attributes(prg, payload)
    result = []
    for row in range(room_data.ROOM_HEIGHT):
        for column in range(room_data.ROOM_WIDTH):
            offset, quadrant = room_data.room_attribute_position(column, row)
            result.append((attributes[offset] >> (quadrant * 2)) & 3)
    return tuple(result)


def cell_catalog_palette(prg: bytes, cell_type: int) -> int:
    values = read_cpu(prg, room_data.ROOM_CELL_ATTRIBUTES_CPU, 100)
    if not 0 <= cell_type < len(values):
        raise LevelStudioModelError(f"cell type outside 0-99: {cell_type}")
    value = values[cell_type]
    if value not in (0x00, 0x55, 0xAA, 0xFF):
        raise LevelStudioModelError(f"cell ${cell_type:02X} has invalid palette byte")
    return value & 3


def room_visuals(prg: bytes, room: dict[str, Any]) -> tuple[tuple[CellVisual, ...], tuple[ObjectVisual, ...]]:
    rows = room.get("cells")
    if not isinstance(rows, list) or len(rows) != room_data.ROOM_HEIGHT:
        raise LevelStudioModelError("room has no complete cell grid")
    cells = [cell for row in rows if isinstance(row, list) for cell in row]
    if len(cells) != room_data.ROOM_SIZE:
        raise LevelStudioModelError("room has no complete cell grid")
    palettes = room_cell_palettes(prg, cells)
    cell_visuals = tuple(
        CellVisual(cell, *cell_tile_pair(prg, cell), palettes[index])
        for index, cell in enumerate(cells)
    )
    runtime_types = read_cpu(
        prg, room_data.RUNTIME_OBJECT_TYPES_CPU, room_data.RUNTIME_OBJECT_TYPE_COUNT
    )
    records = room.get("objects")
    if not isinstance(records, list):
        raise LevelStudioModelError("room has no object list")
    objects = tuple(
        ObjectVisual(
            index,
            int(record["encoded_type"]),
            runtime_types[int(record["encoded_type"])],
            int(record["x"]),
            int(record["y"]),
            representative_object_sprites(
                prg,
                runtime_types[int(record["encoded_type"])],
                int(record["x"]),
                int(record["y"]),
            ),
        )
        for index, record in enumerate(records)
    )
    return cell_visuals, objects


def logical_cell_pixels(
    tiles: Sequence[Sequence[Sequence[int]]], visual: CellVisual
) -> tuple[tuple[int, ...], ...]:
    left = BACKGROUND_PATTERN_TABLE * PATTERN_TABLE_TILES + visual.left_tile
    right = BACKGROUND_PATTERN_TABLE * PATTERN_TABLE_TILES + visual.right_tile
    if left >= len(tiles) or right >= len(tiles):
        raise LevelStudioModelError("room cell references a tile outside CHR")
    return tuple(
        tuple(tiles[left][row]) + tuple(tiles[right][row])
        for row in range(8)
    )


def sprite_pixels(
    tiles: Sequence[Sequence[Sequence[int]]], tile: int, attributes: int
) -> tuple[tuple[int, ...], ...]:
    """Decode one NES 8x16 hardware sprite, including pattern-table selection."""
    top = (tile & 1) * PATTERN_TABLE_TILES + (tile & 0xFE)
    if top + 1 >= len(tiles):
        raise LevelStudioModelError("hardware sprite references a tile outside CHR")
    rows = [tuple(row) for index in (top, top + 1) for row in tiles[index]]
    if attributes & 0x40:
        rows = [tuple(reversed(row)) for row in rows]
    if attributes & 0x80:
        rows.reverse()
    return tuple(rows)


def representative_object_sprites(
    prg: bytes, runtime_type: int, column: int, row: int
) -> tuple[SpriteVisual, ...]:
    """Select the first reachable frame in an object's reconstructed renderer."""
    descriptor, offsets = _representative_object_descriptor(prg, runtime_type)
    x = column * 16 + (4 if 0x90 <= runtime_type <= 0x95 else 0)
    y = object_preview_y(runtime_type, row)
    return tuple(
        SpriteVisual(
            descriptor[index * 2],
            descriptor[index * 2 + 1],
            x + offset,
            y,
        )
        for index, offset in enumerate(offsets)
    )


def object_preview_y(_runtime_type: int, row: int) -> int:
    """Translate room-object rows into the editor's room-local coordinate space."""
    return row * 8


@lru_cache(maxsize=84)
def _representative_object_descriptor(
    prg: bytes, runtime_type: int
) -> tuple[bytes, tuple[int, ...]]:
    type_index = runtime_type & frame_sprites.OBJECT_TYPE_INDEX_MASK
    pointers = frame_sprites.decode_object_sprite_pointers(prg)
    if type_index == 0 or type_index >= len(pointers):
        return b"", tuple()
    handler = pointers[type_index]
    later_handlers = [pointer for pointer in pointers if pointer > handler]
    end = min(later_handlers, default=metasprites.SELECTORS_END_CPU)
    reference = next(
        (
            item
            for item in metasprites.decode_descriptor_references(prg)
            if handler <= item.instruction < end and item.renderer in OBJECT_RENDER_X_OFFSETS
        ),
        None,
    )
    if reference is None:
        return b"", tuple()
    descriptor = read_cpu(prg, reference.pointer, reference.sprite_count * 2)
    return descriptor, OBJECT_RENDER_X_OFFSETS[reference.renderer]


def player_sprites(prg: bytes, player_x: int, player_y: int) -> tuple[SpriteVisual, ...]:
    descriptor = read_cpu(prg, frame_sprites.PLAYER_NEUTRAL_METASPRITE, 4)
    return tuple(
        SpriteVisual(
            descriptor[index * 2],
            descriptor[index * 2 + 1],
            player_x + index * 8,
            player_y - 16,
        )
        for index in range(2)
    )


def pixel_colors(
    pixels: Sequence[Sequence[int]], palette: Sequence[int]
) -> tuple[tuple[str, ...], ...]:
    if len(palette) != 4:
        raise LevelStudioModelError("a background palette must contain four colors")
    return tuple(
        tuple(NES_RGB[palette[value] & 0x3F] for value in row)
        for row in pixels
    )


def compression_symbols(prg: bytes) -> tuple[int, ...]:
    return tuple(symbol for symbol, _code in room_data.parse_codebook(prg))


def validate_playtest_position(room_number: int, player_x: int, player_y: int) -> None:
    if not 1 <= room_number <= room_data.ROOM_COUNT:
        raise LevelStudioModelError("playtest room must be between 1 and 100")
    if not 0 <= player_x < room_data.ROOM_WIDTH * 16:
        raise LevelStudioModelError("playtest X must be between 0 and 319")
    if not 0 <= player_y < room_data.ROOM_HEIGHT * 8:
        raise LevelStudioModelError("playtest Y must be between 0 and 159")
