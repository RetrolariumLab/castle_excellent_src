from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]

from scripts.authoring import graphics_editor
from scripts.authoring import room_data
class GraphicsEditorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.image = (ROOT / "Castle Excellent (J).nes").read_bytes()
        cls.prg, cls.chr_data = room_data.extract_rom(cls.image)
        cls.workspace = graphics_editor.decode_workspace(
            "castle-excellent-japan-hsp-05", cls.prg, cls.chr_data
        )

    def compose(self, workspace: dict[str, object]) -> tuple[bytes, dict[str, object]]:
        validated = graphics_editor.validate_workspace(
            workspace, "castle-excellent-japan-hsp-05"
        )
        return graphics_editor.compose_graphics(
            self.image, self.prg, self.chr_data, validated
        )

    def test_zero_edit_workspace_rebuilds_the_complete_rom(self) -> None:
        output, report = self.compose(self.workspace)
        self.assertEqual(output, self.image)
        self.assertEqual(report["changed_bytes"], 0)

    def test_pixel_edit_changes_only_the_selected_chr_bank(self) -> None:
        workspace = deepcopy(self.workspace)
        pixel = workspace["chr_banks"][0]["tiles"][0][0][0]
        workspace["chr_banks"][0]["tiles"][0][0][0] = (pixel + 1) & 3
        output, report = self.compose(workspace)
        output_prg, output_chr = room_data.extract_rom(output)
        self.assertEqual(output_prg, self.prg)
        self.assertNotEqual(output_chr[:16], self.chr_data[:16])
        self.assertEqual(output_chr[16:], self.chr_data[16:])
        self.assertEqual(report["prg_changed_bytes"], 0)

    def test_room_cell_visual_rewrites_three_typed_fields(self) -> None:
        workspace = deepcopy(self.workspace)
        workspace["room_cells"][0] = {
            "index": 0,
            "left_tile": 1,
            "right_tile": 2,
            "palette": 3,
        }
        output, _report = self.compose(workspace)
        output_prg, output_chr = room_data.extract_rom(output)
        self.assertEqual(output_chr, self.chr_data)
        self.assertEqual(output_prg[0x7F30], 1)
        self.assertEqual(output_prg[0x7F94], 2)
        self.assertEqual(output_prg[0x69D2], 0xFF)

    def test_rejects_invalid_tile_and_palette_values(self) -> None:
        for path, value in (
            (("chr_banks", 0, "tiles", 0, 0, 0), 4),
            (("room_cells", 0, "palette"), 4),
            (("room_palette", 0), 0x40),
        ):
            workspace = deepcopy(self.workspace)
            target: object = workspace
            for key in path[:-1]:
                target = target[key]
            target[path[-1]] = value
            with self.assertRaises(graphics_editor.GraphicsEditorError):
                graphics_editor.validate_workspace(
                    workspace, "castle-excellent-japan-hsp-05"
                )


if __name__ == "__main__":
    unittest.main()
