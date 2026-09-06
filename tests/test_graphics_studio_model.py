from __future__ import annotations

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import graphics_editor
import graphics_studio_model as model
import room_data


class GraphicsStudioModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        prg, chr_data = room_data.extract_rom(image)
        cls.workspace = graphics_editor.decode_workspace(
            "castle-excellent-japan-hsp-05", prg, chr_data
        )

    def test_summary_covers_every_editable_record(self) -> None:
        summary = model.summarize(
            self.workspace, "castle-excellent-japan-hsp-05"
        )
        self.assertEqual(summary.bank_count, 2)
        self.assertEqual(summary.tile_count, 1024)
        self.assertEqual(summary.room_cell_count, 100)
        self.assertEqual(summary.metasprite_descriptor_count, 203)
        self.assertEqual(summary.text_block_count, 8)
        self.assertEqual(summary.sound_effect_table_count, 5)

    def test_tile_colors_use_selected_nes_palette(self) -> None:
        palette = (0x0F, 0x12, 0x21, 0x30)
        colors = model.tile_colors(self.workspace, 0, 0, palette)
        self.assertEqual(len(colors), 8)
        self.assertEqual(len(colors[0]), 8)
        self.assertTrue(set(colors[0]).issubset({model.NES_RGB[value] for value in palette}))

    def test_editor_byte_sequences_accept_common_notation(self) -> None:
        self.assertEqual(model.parse_byte("$2A", "value"), 0x2A)
        self.assertEqual(
            model.parse_byte_sequence("00, $10 0x20 30", 4, "record"),
            [0, 0x10, 0x20, 30],
        )
        with self.assertRaises(model.GraphicsStudioModelError):
            model.parse_byte_sequence("00 01", 4, "record")

    def test_room_cells_use_the_background_pattern_table(self) -> None:
        colors = model.room_cell_colors(self.workspace, 0x53)
        self.assertEqual(len(colors), 8)
        self.assertEqual(len(colors[0]), 16)
        self.assertEqual({color for row in colors for color in row}, {"#000000"})

    def test_descriptor_preview_decodes_8x16_sprite_and_transparency(self) -> None:
        colors = model.descriptor_colors(self.workspace, 0)
        self.assertEqual(len(colors), 16)
        self.assertEqual(len(colors[0]), 8)
        self.assertIn(None, {color for row in colors for color in row})
        self.assertTrue(any(color is not None for row in colors for color in row))

    def test_hardware_sprite_flips_both_tiles_as_one_image(self) -> None:
        workspace = {
            "chr_banks": [
                {
                    "tiles": [
                        [[0] * 8 for _ in range(8)] for _ in range(512)
                    ]
                }
            ]
        }
        workspace["chr_banks"][0]["tiles"][8][0][0] = 1
        workspace["chr_banks"][0]["tiles"][9][7][0] = 2
        pixels = model.hardware_sprite_pixels(workspace, 0, 8, 0xC0)
        self.assertEqual(pixels[0][-1], 2)
        self.assertEqual(pixels[-1][-1], 1)


if __name__ == "__main__":
    unittest.main()
