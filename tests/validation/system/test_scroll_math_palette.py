from pathlib import Path
import unittest

from scripts.validation.system import scroll_math_palette as helpers


ROOT = Path(__file__).resolve().parents[3]


class ScrollMathPaletteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = helpers.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )

    def test_pause_preserves_scroll_without_updating(self) -> None:
        for pause_mode in (1, 0x7F, 0xFF):
            result = helpers.update_horizontal_scroll(
                player_x=0x0100, pause_mode=pause_mode, current_scroll_x=0x5A
            )
            self.assertEqual(result, helpers.ScrollResult(0x5A, False))

    def test_scroll_clamps_below_left_edge_and_at_right_edge(self) -> None:
        self.assertEqual(
            helpers.update_horizontal_scroll(
                player_x=0x003F, pause_mode=0, current_scroll_x=0x5A
            ).scroll_x,
            0,
        )
        self.assertEqual(
            helpers.update_horizontal_scroll(
                player_x=0x0100, pause_mode=0, current_scroll_x=0x5A
            ).scroll_x,
            0x80,
        )

    def test_scroll_scales_middle_range_by_two_thirds(self) -> None:
        cases = {0x0040: 0, 0x0041: 0, 0x0042: 1, 0x00FF: 0x7F}
        for player_x, expected in cases.items():
            with self.subTest(player_x=player_x):
                result = helpers.update_horizontal_scroll(
                    player_x=player_x, pause_mode=0, current_scroll_x=0x5A
                )
                self.assertEqual(result, helpers.ScrollResult(expected, True))

    def test_scroll_preserves_original_low_byte_high_page_quirk(self) -> None:
        self.assertEqual(
            helpers.update_horizontal_scroll(
                player_x=0x0140, pause_mode=0, current_scroll_x=0x5A
            ).scroll_x,
            0,
        )

    def test_divide_matches_unsigned_quotient_and_remainder_vectors(self) -> None:
        for dividend, divisor in (
            (0, 1),
            (1, 1),
            (0x017E, 3),
            (0xFFFF, 3),
            (0xFFFF, 0x8000),
            (0xFFFF, 0xFFFF),
            (0x1234, 0x0100),
        ):
            with self.subTest(dividend=dividend, divisor=divisor):
                result = helpers.divide_unsigned16(dividend, divisor)
                quotient, remainder = divmod(dividend, divisor)
                self.assertEqual(result.quotient, quotient)
                self.assertEqual(result.remainder, remainder)
                self.assertTrue(result.carry_set)
                self.assertTrue(result.divided)

    def test_zero_divisor_sets_carry_and_preserves_quotient_and_dividend(self) -> None:
        result = helpers.divide_unsigned16(
            0x1234, 0, quotient_initial=0xBEEF
        )
        self.assertEqual(result.quotient, 0xBEEF)
        self.assertEqual(result.remainder, 0x1234)
        self.assertTrue(result.carry_set)
        self.assertFalse(result.divided)

    def test_palette_upload_writes_exact_32_byte_sequence(self) -> None:
        palette = bytes(range(32))
        result = helpers.upload_palette(palette)
        self.assertTrue(result.nmi_disabled)
        self.assertTrue(result.rendering_disabled)
        self.assertEqual(result.bytes_uploaded, 32)
        self.assertEqual(len(result.ppu_writes), 38)
        self.assertEqual(result.ppu_writes[:2], ((0x2006, 0x3F), (0x2006, 0)))
        self.assertEqual(
            result.ppu_writes[2:34], tuple((0x2007, value) for value in palette)
        )
        self.assertEqual(
            result.ppu_writes[34:],
            ((0x2006, 0x3F), (0x2006, 0), (0x2006, 0), (0x2006, 0)),
        )

    def test_palette_upload_rejects_non_32_byte_payloads(self) -> None:
        for size in (0, 31, 33, 256):
            with self.subTest(size=size):
                with self.assertRaisesRegex(
                    helpers.ScrollMathPaletteError, "expected 32"
                ):
                    helpers.upload_palette(bytes(size))

    def test_reference_rom_pins_hashes_entrypoints_and_palette_setup(self) -> None:
        report = helpers.validate_rom_contract(self.prg)
        self.assertEqual(report["bytes"], 192)
        self.assertEqual(report["scroll_bytes"], 61)
        self.assertEqual(report["divide_bytes"], 83)
        self.assertEqual(report["palette_bytes"], 48)
        self.assertEqual(report["entrypoints"], 3)
        self.assertEqual(report["callers"], 15)
        self.assertEqual(report["palette_upload_bytes"], 32)

    def test_exhaustive_scroll_pause_and_divide_by_three_domains(self) -> None:
        self.assertEqual(
            helpers.validate_exhaustive_contract(),
            {"scroll_cases": 65_536, "pause_cases": 256, "divide_cases": 65_536},
        )


if __name__ == "__main__":
    unittest.main()
