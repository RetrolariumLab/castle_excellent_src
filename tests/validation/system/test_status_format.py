from __future__ import annotations

import unittest

from scripts.validation.system import status_format


class StatusFormatTests(unittest.TestCase):
    def test_zero_score_is_five_blank_tiles(self) -> None:
        self.assertEqual(
            status_format.format_score_tiles(0),
            bytes((status_format.BLANK_TILE,) * status_format.SCORE_DIGIT_COUNT),
        )

    def test_score_uses_five_decimal_tiles_and_blanks_leading_zeroes(self) -> None:
        self.assertEqual(
            status_format.format_score_tiles(42),
            bytes((0xFF, 0xFF, 0xFF, 0x64, 0x62)),
        )
        self.assertEqual(
            status_format.format_score_tiles(65_535),
            bytes((0x66, 0x65, 0x65, 0x63, 0x65)),
        )

    def test_life_scratch_is_ones_tens_hundreds(self) -> None:
        self.assertEqual(
            status_format.format_life_scratch_tiles(7),
            bytes((0x67, 0xFF, 0xFF)),
        )
        self.assertEqual(
            status_format.format_life_scratch_tiles(105),
            bytes((0x65, 0x60, 0x61)),
        )

    def test_nmi_upload_uses_only_tens_then_ones(self) -> None:
        result = status_format.format_status_tiles(1, 255, bytes(6))
        self.assertEqual(result.life_scratch_tiles, bytes((0x65, 0x65, 0x62)))
        self.assertEqual(result.uploaded_life_tiles, bytes((0x65, 0x65)))

    def test_inventory_values_saturate_at_nine(self) -> None:
        self.assertEqual(
            status_format.format_inventory_tiles(bytes((0, 1, 8, 9, 10, 255))),
            bytes((0x60, 0x61, 0x68, 0x69, 0x69, 0x69)),
        )

    def test_begin_locks_and_clears_all_eight_score_bytes(self) -> None:
        busy, buffer = status_format.begin_status_tile_formatting(bytes((0xA5,) * 8))
        self.assertEqual(busy, status_format.STATUS_TILES_LOCKED)
        self.assertEqual(buffer, bytes(8))

    def test_complete_format_releases_interlock_and_preserves_zero_tail(self) -> None:
        result = status_format.format_status_tiles(12_345, 3, bytes((1, 2, 3, 4, 5, 6)))
        self.assertEqual(result.busy, status_format.STATUS_TILES_READY)
        self.assertEqual(result.score_buffer[5:], bytes(3))
        self.assertEqual(result.inventory_tiles, bytes((0x61, 0x62, 0x63, 0x64, 0x65, 0x66)))

    def test_rejects_invalid_shapes_and_values(self) -> None:
        with self.assertRaises(status_format.StatusFormatError):
            status_format.format_score_tiles(0x10000)
        with self.assertRaises(status_format.StatusFormatError):
            status_format.format_life_scratch_tiles(-1)
        with self.assertRaises(status_format.StatusFormatError):
            status_format.format_inventory_tiles(bytes(5))
        with self.assertRaises(status_format.StatusFormatError):
            status_format.begin_status_tile_formatting(bytes(7))


if __name__ == "__main__":
    unittest.main()
