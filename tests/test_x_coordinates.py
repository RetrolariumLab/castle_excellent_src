from __future__ import annotations

import unittest

from scripts.validation.player import x_coordinates


class XCoordinateTests(unittest.TestCase):
    def test_returns_high_byte_in_a_and_low_byte_in_x(self) -> None:
        result = x_coordinates.offset_x_6502(0x1234, 0)
        self.assertEqual((result.accumulator_high, result.index_low), (0x12, 0x34))
        self.assertEqual(result.value, 0x1234)

    def test_addition_propagates_low_byte_carry(self) -> None:
        self.assertEqual(x_coordinates.offset_x_6502(0x00F8, 15).value, 0x0107)
        self.assertEqual(x_coordinates.offset_x_6502(0xFFF8, 15).value, 0x0007)

    def test_subtract_two_propagates_low_byte_borrow(self) -> None:
        self.assertEqual(x_coordinates.offset_x_6502(0x0101, -2).value, 0x00FF)
        self.assertEqual(x_coordinates.offset_x_6502(0x0001, -2).value, 0xFFFF)

    def test_helper_offset_sets_match_assembly_entries(self) -> None:
        self.assertEqual(x_coordinates.PLAYER_X_OFFSETS, (7, 15))
        self.assertEqual(
            x_coordinates.RUNTIME_OBJECT_X_OFFSETS, (0, 7, 8, 15, 17, -2)
        )

    def test_rejects_positions_outside_sixteen_bits(self) -> None:
        with self.assertRaises(x_coordinates.XCoordinateError):
            x_coordinates.offset_x_6502(-1, 7)
        with self.assertRaises(x_coordinates.XCoordinateError):
            x_coordinates.offset_x_6502(0x10000, 7)


if __name__ == "__main__":
    unittest.main()
