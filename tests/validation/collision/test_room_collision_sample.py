from __future__ import annotations

import unittest

from scripts.validation.collision import room_collision_sample as sample


class RoomCollisionSampleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.empty_room = bytes([sample.EMPTY_ROOM_CELL]) * sample.ROOM_CELL_COUNT

    def test_maps_first_and_last_room_pixels(self) -> None:
        self.assertEqual(sample.room_cell_index(0, 0), 0)
        self.assertEqual(sample.room_cell_index(319, 159), 399)

    def test_out_of_bounds_y_returns_empty_and_preserves_y(self) -> None:
        result = sample.sample_room_collision_at_pixel(
            self.empty_room, x=100, y=160
        )
        self.assertEqual(result.accumulator, sample.EMPTY_ROOM_CELL)
        self.assertEqual(result.x_register, 0)
        self.assertEqual(result.y_register, 160)
        self.assertFalse(result.carry)
        self.assertTrue(result.zero)

    def test_empty_room_cell_returns_zero_flags(self) -> None:
        result = sample.sample_room_collision_at_pixel(self.empty_room, x=0, y=0)
        self.assertEqual(result.accumulator, sample.EMPTY_ROOM_CELL)
        self.assertEqual(result.collision_flags, 0)
        self.assertEqual(result.y_register, 0xFF)

    def test_half_bit_selects_asymmetric_collision_entries(self) -> None:
        room = bytes([0x06]) * sample.ROOM_CELL_COUNT
        left = sample.sample_room_collision_at_pixel(room, x=0, y=0)
        right = sample.sample_room_collision_at_pixel(room, x=8, y=0)
        self.assertFalse(left.carry)
        self.assertTrue(right.carry)
        self.assertEqual((left.x_register, right.x_register), (0x0C, 0x0D))

    def test_negative_table_flag_is_returned_in_n_and_c(self) -> None:
        room = bytes([0x2F]) * sample.ROOM_CELL_COUNT
        result = sample.sample_room_collision_at_pixel(room, x=0, y=0)
        self.assertEqual(result.collision_flags, 0x81)
        self.assertTrue(result.negative)
        self.assertTrue(result.carry)

    def test_special_cells_clear_flags_only_during_negative_phase(self) -> None:
        room = bytes([0x45]) * sample.ROOM_CELL_COUNT
        active = sample.sample_room_collision_at_pixel(
            room, x=0, y=0, animation_counter=0
        )
        paused = sample.sample_room_collision_at_pixel(
            room, x=0, y=0, animation_counter=0x80
        )
        self.assertEqual(active.y_register, 0)
        self.assertTrue(active.carry)
        self.assertEqual(paused.accumulator, 0x45)
        self.assertEqual(paused.collision_flags, 0)
        self.assertTrue(paused.zero)

    def test_rejects_coordinates_outside_room_x_domain(self) -> None:
        with self.assertRaises(sample.RoomCollisionSampleError):
            sample.sample_room_collision_at_pixel(self.empty_room, x=320, y=0)


if __name__ == "__main__":
    unittest.main()
