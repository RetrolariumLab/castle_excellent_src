from pathlib import Path
import unittest

from scripts import palette_data


ROOT = Path(__file__).resolve().parent.parent


class PaletteDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = palette_data.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_screen_palettes_are_overlapping_32_byte_views(self) -> None:
        completion = palette_data.palette_view(self.prg, "completion")
        title = palette_data.palette_view(self.prg, "title")
        castle_map = palette_data.palette_view(self.prg, "castle_map")
        self.assertEqual(len(completion), palette_data.PALETTE_BYTES)
        self.assertEqual(completion[16:], title[:16])
        self.assertEqual(title[16:], castle_map[:16])

    def test_unknown_palette_view_is_rejected(self) -> None:
        with self.assertRaises(palette_data.PaletteDataError):
            palette_data.palette_view(self.prg, "unknown")

    def test_uploader_references_are_exhaustive(self) -> None:
        self.assertEqual(
            palette_data.find_opcode_target(self.prg, 0x20, palette_data.UPLOADER_CPU),
            [0xEA93, 0xF909, 0xFE9E],
        )
        self.assertEqual(
            palette_data.find_opcode_target(self.prg, 0x4C, palette_data.UPLOADER_CPU),
            [0xA359],
        )

    def test_reference_contract(self) -> None:
        report = palette_data.validate_contract(self.prg)
        self.assertEqual(report["screen_storage_bytes"], 64)
        self.assertEqual(report["palette_bytes"], 32)
        self.assertEqual(report["room_palette"], 0xC53D)


if __name__ == "__main__":
    unittest.main()
