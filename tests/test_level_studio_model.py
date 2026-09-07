from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent.parent

from scripts.authoring import level_studio_model as model
from scripts.authoring import room_data
def put_cpu(prg: bytearray, address: int, payload: bytes) -> None:
    start = room_data.cpu_offset(address)
    prg[start:start + len(payload)] = payload


class LevelStudioModelTests(unittest.TestCase):
    def test_play_action_uses_the_runtime_script(self) -> None:
        self.assertEqual(
            model.LEVEL_PLAYTEST_SCRIPT.relative_to(ROOT).as_posix(),
            "scripts/runtime/level_playtest.lua",
        )
        self.assertTrue(model.LEVEL_PLAYTEST_SCRIPT.is_file())

    def test_decodes_both_nes_bitplanes(self) -> None:
        chr_data = bytearray(room_data.CHR_BANK_SIZE)
        chr_data[0] = 0b10000000
        chr_data[8] = 0b01000000
        tiles = model.decode_chr_bank(bytes(chr_data))
        self.assertEqual(tiles[0][0][:3], (1, 2, 0))
        self.assertEqual(len(tiles), 512)

    def test_cell_visual_uses_reconstructed_tile_and_palette_tables(self) -> None:
        prg = bytearray(32_768)
        put_cpu(prg, model.LEFT_TILE_CPU, bytes(range(100)))
        put_cpu(prg, model.RIGHT_TILE_CPU, bytes(range(1, 101)))
        put_cpu(prg, room_data.INITIAL_ROOM_ATTRIBUTES_CPU, bytes(16))
        put_cpu(prg, room_data.ROOM_ATTRIBUTE_MASKS_CPU, bytes((3, 12, 48, 192)))
        put_cpu(prg, room_data.ROOM_CELL_ATTRIBUTES_CPU, bytes([0x55]) * 100)
        cells = bytes([7]) * room_data.ROOM_SIZE
        palettes = model.room_cell_palettes(bytes(prg), cells)
        self.assertEqual(model.cell_tile_pair(bytes(prg), 7), (7, 8))
        self.assertEqual(set(palettes), {1})

    def test_logical_cell_combines_left_and_right_tiles(self) -> None:
        blank = tuple(tuple([0] * 8) for _ in range(8))
        filled = tuple(tuple([3] * 8) for _ in range(8))
        tiles = (blank,) * 256 + (blank, filled)
        pixels = model.logical_cell_pixels(tiles, model.CellVisual(0, 0, 1, 0))
        self.assertEqual(pixels[0], (0,) * 8 + (3,) * 8)
        self.assertEqual(len(pixels), 8)

    def test_background_and_sprites_use_the_runtime_pattern_tables(self) -> None:
        blank = tuple(tuple([0] * 8) for _ in range(8))
        lower = tuple(tuple([1] * 8) for _ in range(8))
        upper = tuple(tuple([2] * 8) for _ in range(8))
        tiles = list((blank,) * 512)
        tiles[4] = lower
        tiles[5] = upper
        tiles[256 + 4] = upper
        cell = model.logical_cell_pixels(tuple(tiles), model.CellVisual(0, 4, 4, 0))
        sprite = model.sprite_pixels(tuple(tiles), 4, 0)
        self.assertEqual(set(cell[0]), {2})
        self.assertEqual(set(sprite[0]), {1})
        self.assertEqual(set(sprite[8]), {2})

    def test_sprite_flip_applies_to_the_complete_8x16_sprite(self) -> None:
        blank = tuple(tuple([0] * 8) for _ in range(8))
        top = tuple((1,) + (0,) * 7 for _ in range(8))
        bottom = tuple((2,) + (0,) * 7 for _ in range(8))
        tiles = list((blank,) * 512)
        tiles[8] = top
        tiles[9] = bottom
        pixels = model.sprite_pixels(tuple(tiles), 8, 0xC0)
        self.assertEqual(pixels[0][-1], 2)
        self.assertEqual(pixels[-1][-1], 1)

    def test_reference_room_has_true_object_and_player_metasprites(self) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, chr_data = room_data.extract_rom(image)
        room = room_data.decode_room(prg, chr_data, 0)
        room["objects"] = room["object_stream"]["objects"]
        _cells, objects = model.room_visuals(prg, room)
        self.assertTrue(objects)
        self.assertTrue(all(visual.sprites for visual in objects))
        tiles = model.decode_chr_bank(chr_data)
        self.assertTrue(
            all(
                len(model.sprite_pixels(tiles, sprite.tile, sprite.attributes)) == 16
                for visual in objects
                for sprite in visual.sprites
            )
        )
        self.assertEqual(len(model.player_sprites(prg, 16, 152)), 2)

    def test_reference_palette_renders_black_empty_space_and_blue_water(self) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, chr_data = room_data.extract_rom(image)
        tiles = model.decode_chr_bank(chr_data)
        palettes = model.room_palette(prg)

        empty = model.CellVisual(0x53, *model.cell_tile_pair(prg, 0x53), 0)
        water = model.CellVisual(0x16, *model.cell_tile_pair(prg, 0x16), 0)
        empty_colors = model.pixel_colors(model.logical_cell_pixels(tiles, empty), palettes[0])
        water_colors = model.pixel_colors(model.logical_cell_pixels(tiles, water), palettes[0])

        self.assertEqual({color for row in empty_colors for color in row}, {"#000000"})
        self.assertEqual({color for row in water_colors for color in row}, {"#4b30ff"})

    def test_every_static_object_has_a_reconstructed_preview_frame(self) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, chr_data = room_data.extract_rom(image)
        count = 0
        for room_index in range(room_data.ROOM_COUNT):
            room = room_data.decode_room(prg, chr_data, room_index)
            for record in room["object_stream"]["objects"]:
                count += 1
                self.assertTrue(
                    model.representative_object_sprites(
                        prg,
                        record["runtime_type"],
                        record["x"],
                        record["y"],
                    )
                )
        self.assertEqual(count, 783)

    def test_room_local_y_origin_includes_all_six_inventory_collectibles(self) -> None:
        self.assertEqual(model.object_preview_y(0x8F, 7), 56)
        for runtime_type in range(0x90, 0x96):
            self.assertEqual(model.object_preview_y(runtime_type, 7), 56)
        self.assertEqual(model.object_preview_y(0x96, 7), 56)

    def test_castle_overview_uses_the_runtime_ten_by_ten_room_grid(self) -> None:
        self.assertEqual(model.castle_room_position(1), (0, 0))
        self.assertEqual(model.castle_room_position(10), (9, 0))
        self.assertEqual(model.castle_room_position(91), (0, 9))
        self.assertEqual(model.castle_room_position(100), (9, 9))
        for room_number in (0, 101):
            with self.assertRaises(model.LevelStudioModelError):
                model.castle_room_position(room_number)

    def test_castle_overview_thumbnail_contains_room_cells_and_objects(self) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, chr_data = room_data.extract_rom(image)
        room = room_data.decode_room(prg, chr_data, 0)
        room["objects"] = room["object_stream"]["objects"]
        colors = model.room_thumbnail_colors(
            prg,
            model.decode_chr_bank(chr_data),
            model.room_palette(prg),
            model.sprite_palette(prg),
            room,
            4,
        )
        self.assertEqual(len(colors), 40)
        self.assertTrue(all(len(row) == 80 for row in colors))
        self.assertGreater(len({color for row in colors for color in row}), 2)
        with self.assertRaises(model.LevelStudioModelError):
            model.room_thumbnail_colors(
                prg,
                model.decode_chr_bank(chr_data),
                model.room_palette(prg),
                model.sprite_palette(prg),
                room,
                3,
            )

    def test_player_preview_uses_the_room_local_sprite_origin(self) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, _chr_data = room_data.extract_rom(image)
        sprites = model.player_sprites(prg, 16, 152)
        self.assertEqual({sprite.y for sprite in sprites}, {136})

    def test_playtest_position_covers_the_complete_room(self) -> None:
        model.validate_playtest_position(1, 0, 0)
        model.validate_playtest_position(100, 319, 159)
        for values in ((0, 0, 0), (101, 0, 0), (1, 320, 0), (1, 0, 160)):
            with self.assertRaises(model.LevelStudioModelError):
                model.validate_playtest_position(*values)


if __name__ == "__main__":
    unittest.main()
