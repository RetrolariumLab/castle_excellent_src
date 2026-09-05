#!/usr/bin/env python3
"""Decode Castle Excellent metasprite references and model OAM composition."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys


PRG_BASE = 0x8000
PRG_SIZE = 0x8000
REFERENCE_SCAN_START = 0xAC60
REFERENCE_SCAN_END = 0xB1D6
SELECTORS_CPU = 0xADE7
SELECTORS_END_CPU = 0xB1D6
RENDERERS_CPU = 0xB1D6
RENDERERS_END_CPU = 0xB4B6
METASPRITE_DATA_CPU = 0xB4B6
METASPRITE_DATA_END_CPU = 0xB64C
EXPECTED_RENDERERS_SHA256 = "75090d4e2c70671ff2764e72afa378550421be71db11e9c4860d59def6109fed"
EXPECTED_SELECTORS_SHA256 = "ba39271667dc694fe5c89668aa1ea1c089838f3fbe13d338d275355afa69dc72"
EXPECTED_DATA_SHA256 = "867cb17d500f4035df09eb0c649eb7b6393ed442e118735c5b70f9836ab9de2c"
EXPECTED_REFERENCE_COUNT = 107
EXPECTED_UNIQUE_POINTER_COUNT = 98
EXPECTED_ATTRIBUTE_DOMAIN = {0x00, 0x01, 0x02, 0x03, 0x40, 0x41, 0x42, 0x43, 0xC1}
EXPECTED_UNREFERENCED_RANGES = (
    (0xB568, 0xB56B),
    (0xB578, 0xB57B),
    (0xB5A0, 0xB5AB),
    (0xB5F8, 0xB5FB),
    (0xB61C, 0xB61F),
)
OBJECT_SPRITE_Y_BIAS = 0x37
PLAYER_SPRITE_Y_BIAS = 0x27
OAM_HIDDEN_Y = 0xF0

STANDARD_TWO_OFFSETS = (0x20, 0x28)
ONE_SPRITE_OFFSETS = (0x20,)
FOUR_SPRITE_OFFSETS = (0x20, 0x28, 0x30, 0x38)
COMPACT_TWO_OFFSETS = (0x20, 0x24)


@dataclass(frozen=True)
class RendererSpec:
    name: str
    x_offsets: tuple[int, ...]
    player: bool = False


REFERENCE_TAILS = {
    bytes.fromhex("20 57 B4"): RendererSpec("player_two", (0, 8), True),
    bytes.fromhex("4C 0C AE"): RendererSpec("object_two", STANDARD_TWO_OFFSETS),
    bytes.fromhex("20 D6 B1"): RendererSpec("object_two", STANDARD_TWO_OFFSETS),
    bytes.fromhex("20 65 B2"): RendererSpec("object_one", ONE_SPRITE_OFFSETS),
    bytes.fromhex("4C 2F B0"): RendererSpec("object_one", ONE_SPRITE_OFFSETS),
    bytes.fromhex("20 AF B2"): RendererSpec("object_four", FOUR_SPRITE_OFFSETS),
    bytes.fromhex("20 C8 B3"): RendererSpec("object_two_compact", COMPACT_TWO_OFFSETS),
}


class MetaspriteError(ValueError):
    pass


@dataclass(frozen=True)
class HardwareSprite:
    y: int
    tile: int
    attributes: int
    x: int


@dataclass(frozen=True)
class DescriptorReference:
    instruction: int
    pointer: int
    renderer: str
    sprite_count: int


def _validate_byte(value: int, name: str) -> None:
    if not 0 <= value <= 0xFF:
        raise MetaspriteError(f"{name} outside 0-255: {value}")


def _validate_word(value: int, name: str) -> None:
    if not 0 <= value <= 0xFFFF:
        raise MetaspriteError(f"{name} outside 0-65535: {value}")


def project_screen_x(world_x: int, scroll_x: int, offset: int) -> int | None:
    _validate_word(world_x, "world X")
    _validate_byte(scroll_x, "scroll X")
    _validate_byte(offset, "sprite X offset")
    biased = (world_x + offset) & 0xFFFF
    if biased < scroll_x:
        return None
    projected = biased - scroll_x
    if projected > 0xFF:
        return None
    return projected


def render_object_metasprite(
    *,
    world_x: int,
    object_y: int,
    scroll_x: int,
    descriptor: bytes,
    x_offsets: tuple[int, ...],
) -> tuple[HardwareSprite, ...]:
    _validate_word(world_x, "world X")
    _validate_byte(object_y, "object Y")
    _validate_byte(scroll_x, "scroll X")
    if len(descriptor) != len(x_offsets) * 2:
        raise MetaspriteError("descriptor size does not match renderer width")
    sprites: list[HardwareSprite] = []
    y = (object_y + OBJECT_SPRITE_Y_BIAS) & 0xFF
    for index, offset in enumerate(x_offsets):
        x = project_screen_x(world_x, scroll_x, offset)
        if x is None:
            continue
        sprites.append(HardwareSprite(y, descriptor[index * 2], descriptor[index * 2 + 1], x))
    return tuple(sprites)


def render_player_metasprite(
    *, world_x: int, player_y: int, scroll_x: int, descriptor: bytes
) -> tuple[HardwareSprite, ...]:
    _validate_word(world_x, "player X")
    _validate_byte(player_y, "player Y")
    _validate_byte(scroll_x, "scroll X")
    if len(descriptor) != 4:
        raise MetaspriteError("player descriptor must contain two tile/attribute pairs")
    first_x = project_screen_x(world_x, scroll_x, 0x20)
    if first_x is None:
        return tuple()
    y = (player_y + PLAYER_SPRITE_Y_BIAS) & 0xFF
    second_x = (first_x + 8) & 0xFF
    second_y = y if first_x <= 0xF7 else OAM_HIDDEN_Y
    return (
        HardwareSprite(y, descriptor[0], descriptor[1], first_x),
        HardwareSprite(second_y, descriptor[2], descriptor[3], second_x),
    )


def extract_prg(image: bytes) -> bytes:
    if len(image) < 16 or image[:4] != b"NES\x1a":
        raise MetaspriteError("expected an iNES image")
    trainer_size = 512 if image[6] & 0x04 else 0
    prg_size = image[4] * 16_384
    start = 16 + trainer_size
    end = start + prg_size
    if prg_size != PRG_SIZE or end > len(image):
        raise MetaspriteError("expected a complete 32 KiB PRG region")
    return image[start:end]


def read_cpu_range(prg: bytes, address: int, size: int) -> bytes:
    start = address - PRG_BASE
    return prg[start : start + size]


def decode_descriptor_references(prg: bytes) -> tuple[DescriptorReference, ...]:
    references: list[DescriptorReference] = []
    for address in range(REFERENCE_SCAN_START, REFERENCE_SCAN_END - 6):
        raw = read_cpu_range(prg, address, 7)
        if raw[0] != 0xA2 or raw[2] != 0xA0:
            continue
        renderer = REFERENCE_TAILS.get(raw[4:7])
        if renderer is None:
            continue
        pointer = raw[1] << 8 | raw[3]
        references.append(
            DescriptorReference(address, pointer, renderer.name, len(renderer.x_offsets))
        )
    return tuple(references)


def unreferenced_data_ranges(
    references: tuple[DescriptorReference, ...],
) -> tuple[tuple[int, int], ...]:
    covered = [False] * (METASPRITE_DATA_END_CPU - METASPRITE_DATA_CPU)
    for reference in references:
        start = reference.pointer - METASPRITE_DATA_CPU
        end = start + reference.sprite_count * 2
        if start < 0 or end > len(covered):
            raise MetaspriteError(
                f"descriptor ${reference.pointer:04X} escapes metasprite data"
            )
        for index in range(start, end):
            covered[index] = True
    ranges: list[tuple[int, int]] = []
    index = 0
    while index < len(covered):
        if covered[index]:
            index += 1
            continue
        start = index
        while index + 1 < len(covered) and not covered[index + 1]:
            index += 1
        ranges.append((METASPRITE_DATA_CPU + start, METASPRITE_DATA_CPU + index))
        index += 1
    return tuple(ranges)


def validate_rom_contract(prg: bytes) -> dict[str, object]:
    selector_bytes = read_cpu_range(
        prg, SELECTORS_CPU, SELECTORS_END_CPU - SELECTORS_CPU
    )
    renderer_bytes = read_cpu_range(
        prg, RENDERERS_CPU, RENDERERS_END_CPU - RENDERERS_CPU
    )
    data = read_cpu_range(
        prg, METASPRITE_DATA_CPU, METASPRITE_DATA_END_CPU - METASPRITE_DATA_CPU
    )
    if hashlib.sha256(selector_bytes).hexdigest() != EXPECTED_SELECTORS_SHA256:
        raise MetaspriteError("object sprite selector code changed")
    if hashlib.sha256(renderer_bytes).hexdigest() != EXPECTED_RENDERERS_SHA256:
        raise MetaspriteError("common sprite renderer code changed")
    if hashlib.sha256(data).hexdigest() != EXPECTED_DATA_SHA256:
        raise MetaspriteError("metasprite tile/attribute data changed")
    references = decode_descriptor_references(prg)
    if len(references) != EXPECTED_REFERENCE_COUNT:
        raise MetaspriteError(f"found {len(references)} descriptor references")
    unique_pointers = {reference.pointer for reference in references}
    if len(unique_pointers) != EXPECTED_UNIQUE_POINTER_COUNT:
        raise MetaspriteError(f"found {len(unique_pointers)} unique descriptors")
    if any(pointer & 1 for pointer in unique_pointers):
        raise MetaspriteError("metasprite descriptor is not pair-aligned")
    gaps = unreferenced_data_ranges(references)
    if gaps != EXPECTED_UNREFERENCED_RANGES:
        raise MetaspriteError("metasprite reference coverage changed")
    attributes = set(data[1::2])
    if attributes != EXPECTED_ATTRIBUTE_DOMAIN:
        raise MetaspriteError("metasprite attribute domain changed")
    return {
        "selector_range": [SELECTORS_CPU, SELECTORS_END_CPU - 1],
        "selector_bytes": len(selector_bytes),
        "renderer_range": [RENDERERS_CPU, RENDERERS_END_CPU - 1],
        "renderer_bytes": len(renderer_bytes),
        "data_range": [METASPRITE_DATA_CPU, METASPRITE_DATA_END_CPU - 1],
        "data_bytes": len(data),
        "tile_attribute_pairs": len(data) // 2,
        "references": len(references),
        "unique_descriptors": len(unique_pointers),
        "unreferenced_ranges": [list(item) for item in gaps],
        "attribute_values": sorted(attributes),
    }


def validate_model_contract() -> dict[str, object]:
    projection_cases = 0
    for offset in (0x20, 0x24, 0x28, 0x30, 0x38):
        for world_x in range(0x10000):
            projected = project_screen_x(world_x, 0, offset)
            biased = (world_x + offset) & 0xFFFF
            expected = biased if biased <= 0xFF else None
            if projected != expected:
                raise MetaspriteError("screen-X projection mismatch")
            projection_cases += 1
    for world_x in range(0x140):
        for scroll_x in range(0x100):
            projected = project_screen_x(world_x, scroll_x, 0x20)
            biased = world_x + 0x20
            expected = biased - scroll_x
            if expected < 0 or expected > 0xFF:
                expected = None
            if projected != expected:
                raise MetaspriteError("scrolled screen-X projection mismatch")
            projection_cases += 1

    sample = bytes.fromhex("10 00 12 40 14 01 16 41")
    standard = render_object_metasprite(
        world_x=0,
        object_y=0,
        scroll_x=0,
        descriptor=sample[:4],
        x_offsets=STANDARD_TWO_OFFSETS,
    )
    compact = render_object_metasprite(
        world_x=0,
        object_y=0,
        scroll_x=0,
        descriptor=sample[:4],
        x_offsets=COMPACT_TWO_OFFSETS,
    )
    wide = render_object_metasprite(
        world_x=0,
        object_y=0,
        scroll_x=0,
        descriptor=sample,
        x_offsets=FOUR_SPRITE_OFFSETS,
    )
    if [sprite.x for sprite in standard] != [0x20, 0x28]:
        raise MetaspriteError("standard two-sprite spacing changed")
    if [sprite.x for sprite in compact] != [0x20, 0x24]:
        raise MetaspriteError("compact two-sprite spacing changed")
    if [sprite.x for sprite in wide] != [0x20, 0x28, 0x30, 0x38]:
        raise MetaspriteError("four-sprite spacing changed")

    for first_x in range(0x100):
        world_x = (first_x - 0x20) & 0xFFFF
        player = render_player_metasprite(
            world_x=world_x,
            player_y=0,
            scroll_x=0,
            descriptor=sample[:4],
        )
        expected_second_y = 0x27 if first_x <= 0xF7 else OAM_HIDDEN_Y
        if player[0].x != first_x or player[1].y != expected_second_y:
            raise MetaspriteError("player right-edge clipping changed")

    return {
        "projection_cases": projection_cases,
        "object_renderer_widths": [1, 2, 2, 4],
        "standard_two_x": [sprite.x for sprite in standard],
        "compact_two_x": [sprite.x for sprite in compact],
        "four_x": [sprite.x for sprite in wide],
    }


def build_report(image_path: Path) -> dict[str, object]:
    prg = extract_prg(image_path.read_bytes())
    return {
        "rom": validate_rom_contract(prg),
        "model": validate_model_contract(),
        "sample_player": [
            asdict(sprite)
            for sprite in render_player_metasprite(
                world_x=0,
                player_y=0,
                scroll_x=0,
                descriptor=bytes.fromhex("90 02 92 02"),
            )
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
    except (OSError, MetaspriteError) as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1
    if args.validate:
        print(
            "[OK] validated 41 object selector indexes, five sprite render "
            "paths, 203 tile/attribute pairs, and 107 descriptor references"
        )
    else:
        print(json.dumps(report, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
