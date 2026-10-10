from __future__ import annotations

import unittest

from scripts.validation import metasprites


class MetaspriteTests(unittest.TestCase):
    def test_projects_only_page_zero_after_scroll(self) -> None:
        self.assertEqual(metasprites.project_screen_x(0, 0, 0x20), 0x20)
        self.assertEqual(metasprites.project_screen_x(0x120, 0x80, 0x20), 0xC0)
        self.assertIsNone(metasprites.project_screen_x(0, 0x40, 0x20))
        self.assertIsNone(metasprites.project_screen_x(0x100, 0, 0x20))

    def test_object_renderer_uses_tile_attribute_pairs(self) -> None:
        sprites = metasprites.render_object_metasprite(
            world_x=0,
            object_y=1,
            scroll_x=0,
            descriptor=bytes.fromhex("10 01 12 41"),
            x_offsets=metasprites.STANDARD_TWO_OFFSETS,
        )
        self.assertEqual(
            sprites,
            (
                metasprites.HardwareSprite(0x38, 0x10, 0x01, 0x20),
                metasprites.HardwareSprite(0x38, 0x12, 0x41, 0x28),
            ),
        )

    def test_object_renderer_compacts_after_horizontal_clipping(self) -> None:
        sprites = metasprites.render_object_metasprite(
            world_x=0,
            object_y=0,
            scroll_x=0x24,
            descriptor=bytes.fromhex("10 00 12 00"),
            x_offsets=metasprites.STANDARD_TWO_OFFSETS,
        )
        self.assertEqual(sprites, (metasprites.HardwareSprite(0x37, 0x12, 0, 4),))

    def test_standard_compact_and_wide_spacing(self) -> None:
        descriptor = bytes.fromhex("10 00 12 00 14 00 16 00")
        cases = (
            (metasprites.ONE_SPRITE_OFFSETS, [0x20]),
            (metasprites.STANDARD_TWO_OFFSETS, [0x20, 0x28]),
            (metasprites.COMPACT_TWO_OFFSETS, [0x20, 0x24]),
            (metasprites.FOUR_SPRITE_OFFSETS, [0x20, 0x28, 0x30, 0x38]),
        )
        for offsets, expected_x in cases:
            sprites = metasprites.render_object_metasprite(
                world_x=0,
                object_y=0,
                scroll_x=0,
                descriptor=descriptor[: len(offsets) * 2],
                x_offsets=offsets,
            )
            self.assertEqual([sprite.x for sprite in sprites], expected_x)

    def test_object_y_bias_wraps_as_one_byte(self) -> None:
        sprite = metasprites.render_object_metasprite(
            world_x=0,
            object_y=0xFF,
            scroll_x=0,
            descriptor=bytes.fromhex("10 00"),
            x_offsets=metasprites.ONE_SPRITE_OFFSETS,
        )[0]
        self.assertEqual(sprite.y, 0x36)

    def test_player_uses_two_fixed_records(self) -> None:
        sprites = metasprites.render_player_metasprite(
            world_x=0,
            player_y=1,
            scroll_x=0,
            descriptor=bytes.fromhex("90 02 92 42"),
        )
        self.assertEqual(
            sprites,
            (
                metasprites.HardwareSprite(0x28, 0x90, 0x02, 0x20),
                metasprites.HardwareSprite(0x28, 0x92, 0x42, 0x28),
            ),
        )

    def test_player_hides_second_record_when_x_wraps(self) -> None:
        sprites = metasprites.render_player_metasprite(
            world_x=0xD8,
            player_y=0,
            scroll_x=0,
            descriptor=bytes.fromhex("90 02 92 02"),
        )
        self.assertEqual(sprites[0].x, 0xF8)
        self.assertEqual(sprites[1].x, 0)
        self.assertEqual(sprites[1].y, 0xF0)

    def test_rejects_invalid_values_and_descriptor_shapes(self) -> None:
        with self.assertRaises(metasprites.MetaspriteError):
            metasprites.project_screen_x(0x10000, 0, 0)
        with self.assertRaises(metasprites.MetaspriteError):
            metasprites.render_object_metasprite(
                world_x=0,
                object_y=0,
                scroll_x=0,
                descriptor=b"\x00",
                x_offsets=metasprites.ONE_SPRITE_OFFSETS,
            )
        with self.assertRaises(metasprites.MetaspriteError):
            metasprites.render_player_metasprite(
                world_x=0,
                player_y=0,
                scroll_x=0,
                descriptor=b"\x00\x00",
            )


if __name__ == "__main__":
    unittest.main()
