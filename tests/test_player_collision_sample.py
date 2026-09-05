from __future__ import annotations

import unittest

from scripts import player_collision_sample as sample


class PlayerCollisionSampleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.empty_room = bytes([sample.EMPTY_ROOM_CELL]) * sample.ROOM_CELL_COUNT
        self.empty_records = (sample.RuntimeObject(),) * sample.RECORD_COUNT

    def test_screen_status_row_is_excluded_from_room_coordinates(self) -> None:
        self.assertIsNone(sample.room_cell_index(0, 15))
        self.assertEqual(sample.room_cell_index(0, 16), 0)
        self.assertEqual(sample.room_cell_index(319, 175), 399)
        self.assertIsNone(sample.room_cell_index(319, 176))

    def test_horizontal_domain_is_exactly_320_pixels(self) -> None:
        self.assertEqual(sample.room_cell_index(319, 16), 19)
        self.assertIsNone(sample.room_cell_index(320, 16))

    def test_out_of_range_sample_clears_filter_and_x(self) -> None:
        result = sample.sample_player_collision_at_screen_pixel(
            self.empty_room,
            self.empty_records,
            x=320,
            y=16,
            object_filter_active=0xFF,
        )
        self.assertEqual(result.source, "empty")
        self.assertEqual(result.x_register, 0)
        self.assertEqual(result.y_register, 16)
        self.assertEqual(result.object_filter_active, 0)
        self.assertTrue(result.zero)

    def test_player_room_flags_are_half_specific(self) -> None:
        room = bytes([0x06]) * sample.ROOM_CELL_COUNT
        left = sample.sample_player_collision_at_screen_pixel(
            room, self.empty_records, x=0, y=16
        )
        right = sample.sample_player_collision_at_screen_pixel(
            room, self.empty_records, x=8, y=16
        )
        self.assertEqual(left.source, "empty")
        self.assertEqual(right.source, "room-cell")
        self.assertTrue(right.carry)

    def test_negative_room_flag_is_returned_without_carry(self) -> None:
        room = bytes([0x2F]) * sample.ROOM_CELL_COUNT
        result = sample.sample_player_collision_at_screen_pixel(
            room, self.empty_records, x=0, y=16
        )
        self.assertEqual(result.source, "room-cell")
        self.assertFalse(result.carry)
        self.assertTrue(result.negative)

    def test_negative_animation_phase_suppresses_special_cell(self) -> None:
        room = bytes([0x45]) * sample.ROOM_CELL_COUNT
        result = sample.sample_player_collision_at_screen_pixel(
            room,
            self.empty_records,
            x=0,
            y=16,
            animation_counter=0x80,
        )
        self.assertEqual(result.source, "room-cell")
        self.assertFalse(result.carry)
        self.assertTrue(result.zero)

    def test_first_matching_runtime_record_wins(self) -> None:
        records = (
            sample.RuntimeObject(),
            sample.RuntimeObject(0x80, 100, 50),
            sample.RuntimeObject(0x80, 100, 50),
        ) + self.empty_records[3:]
        result = sample.sample_player_collision_at_screen_pixel(
            self.empty_room, records, x=100, y=66
        )
        self.assertEqual(result.object_offset, 6)
        self.assertEqual(result.current_object_offset, 6)

    def test_restricted_filter_accepts_only_types_90_through_95(self) -> None:
        rejected = (sample.RuntimeObject(0x80, 100, 50),) + self.empty_records[1:]
        accepted = (sample.RuntimeObject(0x90, 100, 50),) + self.empty_records[1:]
        self.assertEqual(
            sample.sample_player_collision_at_screen_pixel(
                self.empty_room,
                rejected,
                x=100,
                y=66,
                object_filter_active=0xFF,
            ).source,
            "empty",
        )
        self.assertEqual(
            sample.sample_player_collision_at_screen_pixel(
                self.empty_room,
                accepted,
                x=100,
                y=66,
                object_filter_active=0xFF,
            ).source,
            "runtime-object",
        )

    def test_types_84_through_89_are_pass_through(self) -> None:
        records = (sample.RuntimeObject(0x84, 100, 50),) + self.empty_records[1:]
        result = sample.sample_player_collision_at_screen_pixel(
            self.empty_room, records, x=100, y=66
        )
        self.assertEqual(result.source, "runtime-object")
        self.assertFalse(result.carry)

    def test_special_type_86_uses_phase_motion_and_bottom_half(self) -> None:
        records = (sample.RuntimeObject(0x86, 100, 50),) + self.empty_records[1:]
        top = sample.sample_player_collision_at_screen_pixel(
            self.empty_room, records, x=100, y=66, room_frame_counter=0
        )
        bottom = sample.sample_player_collision_at_screen_pixel(
            self.empty_room, records, x=100, y=74, room_frame_counter=0
        )
        moving = sample.sample_player_collision_at_screen_pixel(
            self.empty_room,
            records,
            x=100,
            y=74,
            room_frame_counter=0,
            player_motion_state=1,
        )
        late_phase = sample.sample_player_collision_at_screen_pixel(
            self.empty_room,
            records,
            x=100,
            y=66,
            room_frame_counter=0x80,
            player_motion_state=1,
        )
        self.assertEqual(top.source, "empty")
        self.assertEqual(bottom.source, "runtime-object")
        self.assertEqual(moving.source, "empty")
        self.assertEqual(late_phase.source, "runtime-object")

    def test_no_match_leaves_last_record_offset(self) -> None:
        result = sample.sample_player_collision_at_screen_pixel(
            self.empty_room, self.empty_records, x=0, y=16
        )
        self.assertEqual(result.current_object_offset, 0x8A)
        self.assertEqual(result.x_register, 0x8A)

    def test_rejects_active_type_without_runtime_marker(self) -> None:
        records = (sample.RuntimeObject(1, 0, 0),) + self.empty_records[1:]
        with self.assertRaises(sample.PlayerCollisionSampleError):
            sample.sample_player_collision_at_screen_pixel(
                self.empty_room, records, x=0, y=16
            )


if __name__ == "__main__":
    unittest.main()
