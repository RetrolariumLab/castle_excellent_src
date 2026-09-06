from __future__ import annotations

import unittest

from scripts import runtime_object_dispatch


class RuntimeObjectDispatchTests(unittest.TestCase):
    def test_table_has_one_pointer_for_each_masked_type_index(self) -> None:
        self.assertEqual(
            len(runtime_object_dispatch.EXPECTED_HANDLER_POINTERS),
            runtime_object_dispatch.HANDLER_COUNT,
        )
        self.assertTrue(
            all(
                0x8000 <= pointer <= 0xFFFF
                for pointer in runtime_object_dispatch.EXPECTED_HANDLER_POINTERS
            )
        )

    def test_high_bit_is_removed_before_handler_lookup(self) -> None:
        plain = runtime_object_dispatch.dispatch_handler(0x21, 0)
        active = runtime_object_dispatch.dispatch_handler(0xA1, 0)
        self.assertEqual(plain, active)
        self.assertEqual(active, (0x21, 0x9796))

    def test_inactive_and_offscreen_records_are_skipped(self) -> None:
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x00, 0))
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x80, 0))
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x81, 0xA0))

    def test_scheduler_visits_every_six_byte_record(self) -> None:
        records = tuple(
            runtime_object_dispatch.RuntimeObject(0x81, 0)
            for _ in range(runtime_object_dispatch.RECORD_COUNT)
        )
        scheduled = runtime_object_dispatch.schedule_runtime_objects(records)
        self.assertEqual(
            [update.record_offset for update in scheduled],
            list(range(0, 0x90, 6)),
        )

    def test_rejects_type_index_past_the_42_entry_table(self) -> None:
        with self.assertRaises(runtime_object_dispatch.RuntimeObjectDispatchError):
            runtime_object_dispatch.dispatch_handler(0xAA, 0)

    def test_pushable_types_share_physics_except_lift_control_block(self) -> None:
        handlers = {
            runtime_type: runtime_object_dispatch.dispatch_handler(runtime_type, 0)[1]
            for runtime_type in runtime_object_dispatch.PUSHABLE_UPDATE_TYPES
        }
        self.assertEqual(handlers[0x8E], runtime_object_dispatch.LIFT_CONTROL_HANDLER)
        self.assertEqual(
            {handler for runtime_type, handler in handlers.items() if runtime_type != 0x8E},
            {runtime_object_dispatch.PUSHABLE_COMMON_HANDLER},
        )

    def test_animated_cell_families_move_pushables_in_opposite_directions(self) -> None:
        self.assertEqual(runtime_object_dispatch.pushable_conveyor_delta(0x35), 2)
        self.assertEqual(runtime_object_dispatch.pushable_conveyor_delta(0x40), 2)
        self.assertEqual(runtime_object_dispatch.pushable_conveyor_delta(0x56), -2)
        self.assertEqual(runtime_object_dispatch.pushable_conveyor_delta(0x61), -2)
        self.assertEqual(runtime_object_dispatch.pushable_conveyor_delta(0x53), 0)

    def test_blocked_conveyor_motion_preserves_position_and_latch(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.move_pushable_on_conveyor(0x1234, 0x35, False),
            runtime_object_dispatch.PushableMotion(0x1234, 0),
        )
        self.assertEqual(
            runtime_object_dispatch.move_pushable_on_conveyor(0xFFFF, 0x35, True),
            runtime_object_dispatch.PushableMotion(0x0001, 0x7F),
        )
        self.assertEqual(
            runtime_object_dispatch.move_pushable_on_conveyor(0x0000, 0x56, True),
            runtime_object_dispatch.PushableMotion(0xFFFE, 0xFF),
        )

    def test_unsupported_pushables_fall_until_the_visibility_limit(self) -> None:
        self.assertEqual(runtime_object_dispatch.advance_unsupported_pushable_y(0x9F, False), 0xA1)
        self.assertEqual(runtime_object_dispatch.advance_unsupported_pushable_y(0xA0, False), 0xA0)
        self.assertEqual(runtime_object_dispatch.advance_unsupported_pushable_y(0x40, True), 0x40)

    def test_crushing_requires_a_consistent_destroyable_support(self) -> None:
        self.assertTrue(runtime_object_dispatch.can_crush_support(0x84, 0x53))
        self.assertTrue(runtime_object_dispatch.can_crush_support(0x89, 0x89))
        self.assertFalse(runtime_object_dispatch.can_crush_support(0x8A, 0x53))
        self.assertFalse(runtime_object_dispatch.can_crush_support(0x84, 0x85))

    def test_lifts_tick_once_per_32_room_frames(self) -> None:
        self.assertFalse(runtime_object_dispatch.lift_tick_due(0x1E))
        self.assertTrue(runtime_object_dispatch.lift_tick_due(0x1F))
        self.assertTrue(runtime_object_dispatch.lift_tick_due(0x3F))

    def test_lift_types_select_their_handler_and_width(self) -> None:
        self.assertEqual(runtime_object_dispatch.lift_width(0xA1), 0x10)
        self.assertEqual(runtime_object_dispatch.lift_width(0xA2), 0x20)
        self.assertEqual(runtime_object_dispatch.dispatch_handler(0xA1, 0)[1], 0x9796)
        self.assertEqual(runtime_object_dispatch.dispatch_handler(0xA2, 0)[1], 0x9869)
        with self.assertRaises(runtime_object_dispatch.RuntimeObjectDispatchError):
            runtime_object_dispatch.lift_width(0xA3)

    def test_runtime_record_offsets_map_to_lift_occupant_slots(self) -> None:
        self.assertEqual(runtime_object_dispatch.runtime_object_slot_index(0), 0)
        self.assertEqual(runtime_object_dispatch.runtime_object_slot_index(0x8A), 23)
        for offset in (-1, 1, 0x90):
            with self.assertRaises(runtime_object_dispatch.RuntimeObjectDispatchError):
                runtime_object_dispatch.runtime_object_slot_index(offset)

    def test_rising_lift_occupants_snap_to_previous_cell_boundary(self) -> None:
        self.assertIsNone(runtime_object_dispatch.rising_lift_occupant_y(7))
        self.assertEqual(runtime_object_dispatch.rising_lift_occupant_y(8), 0)
        self.assertEqual(runtime_object_dispatch.rising_lift_occupant_y(0x31), 0x30)
        self.assertEqual(runtime_object_dispatch.rising_lift_occupant_y(0x38), 0x30)

    def test_flying_block_type_uses_the_cell_derived_handler(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0xA3, 0),
            (0x23, 0x9A37),
        )

    def test_bishop_type_uses_shared_walking_enemy_physics(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x85, 0),
            (0x05, 0x9B00),
        )

    def test_knight_and_arrow_types_use_their_projectile_handlers(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x87, 0),
            (0x07, 0x9C3B),
        )
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0xA6, 0),
            (0x26, 0x9F74),
        )

    def test_fairy_and_fighter_types_use_adjacent_handlers(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x81, 0),
            (0x01, 0x9CC6),
        )
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x84, 0),
            (0x04, 0x9CD8),
        )

    def test_flame_type_uses_axis_tracking_handler(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x89, 0),
            (0x09, 0x9D65),
        )

    def test_witch_and_summon_types_use_their_lifecycle_handlers(self) -> None:
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0x88, 0),
            (0x08, 0x9ECB),
        )
        self.assertEqual(
            runtime_object_dispatch.dispatch_handler(0xA0, 0),
            (0x20, 0x9FF3),
        )

    def test_flying_block_motion_and_probe_bounds_match_the_playfield(self) -> None:
        self.assertEqual(runtime_object_dispatch.move_flying_block_x(0x013D, 0), 0x013F)
        self.assertEqual(runtime_object_dispatch.move_flying_block_x(2, 0xFF), 0)
        self.assertTrue(runtime_object_dispatch.flying_block_probe_in_bounds(0x013F, 0x9F))
        self.assertFalse(runtime_object_dispatch.flying_block_probe_in_bounds(0x0140, 0x9F))
        self.assertFalse(runtime_object_dispatch.flying_block_probe_in_bounds(0x013F, 0xA0))


if __name__ == "__main__":
    unittest.main()
