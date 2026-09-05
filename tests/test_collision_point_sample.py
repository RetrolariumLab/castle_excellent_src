from __future__ import annotations

import unittest

from scripts import collision_point_sample as sample


class CollisionPointSampleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.empty_room = bytes([sample.EMPTY_ROOM_CELL]) * sample.ROOM_CELL_COUNT
        self.empty_records = (sample.RuntimeObject(),) * sample.RECORD_COUNT

    def test_maps_room_pixel_extents_to_first_and_last_cells(self) -> None:
        self.assertEqual(sample.room_cell_index(0, 0), 0)
        self.assertEqual(sample.room_cell_index(319, 159), 399)

    def test_vertical_samples_below_gameplay_area_return_empty(self) -> None:
        result = sample.sample_collision_at_pixel(
            self.empty_room, self.empty_records, x=123, y=160
        )
        self.assertEqual(result.source, "empty")
        self.assertTrue(result.zero)
        self.assertFalse(result.carry)

    def test_room_cell_returns_half_specific_processor_flags(self) -> None:
        room = bytes([0x2F]) * sample.ROOM_CELL_COUNT
        result = sample.sample_collision_at_pixel(
            room, self.empty_records, x=0, y=0
        )
        self.assertEqual(result.source, "room-cell")
        self.assertEqual(result.accumulator, 0x2F)
        self.assertEqual(result.x_register, 0x5E)
        self.assertEqual(result.raw_collision_flags, 0x81)
        self.assertTrue(result.carry)
        self.assertTrue(result.negative)

    def test_negative_animation_phase_suppresses_special_cell_flags(self) -> None:
        room = bytes([0x45]) * sample.ROOM_CELL_COUNT
        result = sample.sample_collision_at_pixel(
            room,
            self.empty_records,
            x=0,
            y=0,
            animation_counter=0x80,
        )
        self.assertEqual(result.source, "room-cell")
        self.assertEqual(result.accumulator, 0x45)
        self.assertEqual(result.y_register, 0x80)
        self.assertFalse(result.carry)
        self.assertTrue(result.zero)

    def test_passable_room_half_falls_through_to_runtime_object(self) -> None:
        room = bytes([0x06]) * sample.ROOM_CELL_COUNT
        records = (sample.RuntimeObject(0x80, 0, 0),) + self.empty_records[1:]
        result = sample.sample_collision_at_pixel(room, records, x=0, y=0)
        self.assertEqual(result.source, "runtime-object")
        self.assertEqual(result.object_offset, 0)

    def test_solid_room_cell_takes_priority_over_runtime_object(self) -> None:
        room = bytes([0x00]) * sample.ROOM_CELL_COUNT
        records = (sample.RuntimeObject(0x80, 0, 0),) + self.empty_records[1:]
        result = sample.sample_collision_at_pixel(room, records, x=0, y=0)
        self.assertEqual(result.source, "room-cell")

    def test_runtime_object_bounds_are_left_top_inclusive(self) -> None:
        records = (sample.RuntimeObject(0x80, 100, 50),) + self.empty_records[1:]
        self.assertEqual(
            sample.sample_collision_at_pixel(
                self.empty_room, records, x=100, y=50
            ).source,
            "runtime-object",
        )
        self.assertEqual(
            sample.sample_collision_at_pixel(
                self.empty_room, records, x=115, y=65
            ).source,
            "runtime-object",
        )

    def test_runtime_object_bounds_are_right_bottom_exclusive(self) -> None:
        records = (sample.RuntimeObject(0x80, 100, 50),) + self.empty_records[1:]
        self.assertEqual(
            sample.sample_collision_at_pixel(
                self.empty_room, records, x=116, y=50
            ).source,
            "empty",
        )
        self.assertEqual(
            sample.sample_collision_at_pixel(
                self.empty_room, records, x=100, y=66
            ).source,
            "empty",
        )

    def test_current_runtime_object_is_excluded(self) -> None:
        records = (sample.RuntimeObject(0x80, 100, 50),) + self.empty_records[1:]
        result = sample.sample_collision_at_pixel(
            self.empty_room,
            records,
            x=100,
            y=50,
            current_object_offset=0,
        )
        self.assertEqual(result.source, "empty")

    def test_first_matching_runtime_slot_wins(self) -> None:
        records = (
            sample.RuntimeObject(),
            sample.RuntimeObject(0x81, 100, 50),
            sample.RuntimeObject(0x80, 100, 50),
        ) + self.empty_records[3:]
        result = sample.sample_collision_at_pixel(
            self.empty_room, records, x=100, y=50
        )
        self.assertEqual(result.object_offset, 6)
        self.assertFalse(result.carry)

    def test_rejects_active_type_without_runtime_high_bit(self) -> None:
        records = (sample.RuntimeObject(1, 0, 0),) + self.empty_records[1:]
        with self.assertRaises(sample.CollisionPointSampleError):
            sample.sample_collision_at_pixel(self.empty_room, records, x=0, y=0)


if __name__ == "__main__":
    unittest.main()
