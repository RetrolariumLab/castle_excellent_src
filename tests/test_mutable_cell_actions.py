from __future__ import annotations

import unittest

from scripts import mutable_cell_actions


class MutableCellActionTests(unittest.TestCase):
    def test_cell_pairs_select_all_six_inventory_slots(self) -> None:
        entries = mutable_cell_actions.ACTION_ENTRIES
        self.assertEqual(
            [(entry.anchor_cell, entry.paired_cell) for entry in entries],
            [(0x19, 0x1A), (0x1C, 0x1D), (0x1F, 0x20),
             (0x22, 0x23), (0x25, 0x26), (0x29, 0x2A)],
        )
        self.assertEqual([entry.inventory_index for entry in entries], [4, 3, 5, 2, 0, 1])

    def test_static_ranges_cover_each_handler_exactly(self) -> None:
        self.assertEqual(
            mutable_cell_actions.STATIC_CODE_RANGES,
            ((0xA5DD, 0xA5E6), (0xA5E7, 0xA5F0), (0xA5F1, 0xA5FA),
             (0xA5FB, 0xA604), (0xA605, 0xA60E), (0xA60F, 0xA615)),
        )

    def test_static_range_check_ignores_other_provenance(self) -> None:
        combined = mutable_cell_actions.STATIC_CODE_RANGES + ((0xADE7, 0xAE74),)
        self.assertEqual(
            mutable_cell_actions.mutable_action_static_ranges(combined),
            mutable_cell_actions.STATIC_CODE_RANGES,
        )

    def test_zero_inventory_aborts_without_side_effects(self) -> None:
        result = mutable_cell_actions.apply_mutable_cell_action(
            inventory_count=0, motion_state=0, motion_phase=0, player_y=8,
            probe_y=0x48, direction=0, player_x=0x100, movement_delay=5,
        )
        self.assertEqual(
            result,
            mutable_cell_actions.MutableCellActionResult(False, 0, 0x48, 5, ()),
        )

    def test_motion_state_21_and_above_normalizes_to_idle(self) -> None:
        for motion_state in range(0x21, 0x100):
            self.assertEqual(
                mutable_cell_actions.normalize_player_motion_state(motion_state), 0
            )
            self.assertTrue(
                mutable_cell_actions.mutable_cell_action_ready(1, motion_state, 0, 8)
            )

    def test_active_motion_or_phase_aborts_action(self) -> None:
        self.assertFalse(mutable_cell_actions.mutable_cell_action_ready(1, 1, 0, 8))
        self.assertFalse(mutable_cell_actions.mutable_cell_action_ready(1, 0, 1, 8))

    def test_player_requires_vertical_remainder_eight(self) -> None:
        matches = [
            player_y
            for player_y in range(0x100)
            if mutable_cell_actions.mutable_cell_action_ready(1, 0, 0, player_y)
        ]
        self.assertEqual(matches, list(range(8, 0x100, 16)))

    def test_success_decrements_inventory_and_moves_probe_up(self) -> None:
        result = mutable_cell_actions.apply_mutable_cell_action(
            inventory_count=3, motion_state=0, motion_phase=0, player_y=0x38,
            probe_y=0x40, direction=0, player_x=0x100, movement_delay=4,
        )
        self.assertTrue(result.applied)
        self.assertEqual(result.inventory_count, 2)
        self.assertEqual(result.probe_y, 0x30)
        self.assertEqual(result.movement_delay, 4)
        self.assertEqual(result.calls, mutable_cell_actions.ACTION_CALL_ORDER)

    def test_boundary_delay_uses_direction_sign_and_16_bit_x(self) -> None:
        self.assertTrue(mutable_cell_actions.needs_boundary_movement_delay(0x80, 0x10))
        self.assertFalse(mutable_cell_actions.needs_boundary_movement_delay(0x80, 0x11))
        self.assertFalse(mutable_cell_actions.needs_boundary_movement_delay(0x00, 0x011F))
        self.assertTrue(mutable_cell_actions.needs_boundary_movement_delay(0x00, 0x0120))

    def test_rejects_values_outside_machine_widths(self) -> None:
        with self.assertRaises(mutable_cell_actions.MutableCellActionError):
            mutable_cell_actions.mutable_cell_action_ready(0x100, 0, 0, 8)
        with self.assertRaises(mutable_cell_actions.MutableCellActionError):
            mutable_cell_actions.needs_boundary_movement_delay(0, 0x10000)


if __name__ == "__main__":
    unittest.main()
