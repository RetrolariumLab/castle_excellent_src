from __future__ import annotations

import unittest

from scripts.validation.collision import room_cell_sample_address as address


class RoomCellSampleAddressTests(unittest.TestCase):
    def test_top_left_starts_at_room_buffer(self) -> None:
        result = address.prepare_room_cell_sample_address(0, 0)
        self.assertEqual(result.cell_pointer, 0x0400)
        self.assertEqual(result.column, 0)

    def test_bottom_right_selects_last_room_cell(self) -> None:
        result = address.prepare_room_cell_sample_address(319, 159)
        self.assertEqual(result.cell_pointer + result.column, 0x058F)

    def test_y_selects_eight_pixel_rows(self) -> None:
        self.assertEqual(
            address.prepare_room_cell_sample_address(0, 7).cell_pointer, 0x0400
        )
        self.assertEqual(
            address.prepare_room_cell_sample_address(0, 8).cell_pointer, 0x0414
        )

    def test_full_sixteen_bit_x_is_shifted_into_column(self) -> None:
        result = address.prepare_room_cell_sample_address(0xFEDC, 0)
        self.assertEqual(result.column, 0x0FED)

    def test_final_carry_preserves_horizontal_half_bit(self) -> None:
        self.assertFalse(address.prepare_room_cell_sample_address(0, 0).carry)
        self.assertTrue(address.prepare_room_cell_sample_address(8, 0).carry)

    def test_return_registers_match_last_memory_rotation(self) -> None:
        result = address.prepare_room_cell_sample_address(319, 159)
        self.assertEqual(result.accumulator, 0x05)
        self.assertEqual(result.x_register, 0x3F)
        self.assertEqual(result.y_register, 159)
        self.assertFalse(result.negative)
        self.assertFalse(result.zero)


if __name__ == "__main__":
    unittest.main()
