from __future__ import annotations

from dataclasses import replace
import unittest

from scripts.validation.objects import transient_object_lifecycle as lifecycle


class TransientObjectLifecycleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.record = lifecycle.RuntimeObject(0xA0, 0x34, 0x01, 0x60, 5, 9)

    def test_type32_waits_for_state_countdown_to_reach_zero(self) -> None:
        result = lifecycle.update_type32(
            self.record, frame_counter=0, frame_modulo30=0
        )
        self.assertEqual(result, replace(self.record, state=4))

    def test_type32_replacement_uses_counter_pair_and_frame_parity(self) -> None:
        even = lifecycle.update_type32(
            replace(self.record, state=1), frame_counter=2, frame_modulo30=7
        )
        odd = lifecycle.update_type32(
            replace(self.record, state=1), frame_counter=3, frame_modulo30=7
        )
        self.assertEqual(even.runtime_type, lifecycle.EXPECTED_REPLACEMENT_TYPES[3])
        self.assertEqual(even.state, 0)
        self.assertEqual(odd.state, 0xFF)

    def test_type40_clears_all_six_fields_at_state_limit(self) -> None:
        result = lifecycle.update_type40(replace(self.record, state=14))
        self.assertEqual(result, lifecycle.clear_runtime_object())

    def test_type40_state_wrap_does_not_clear_the_record(self) -> None:
        result = lifecycle.update_type40(replace(self.record, state=0xFF))
        self.assertEqual(result, replace(self.record, state=0))

    def test_type41_moves_up_only_on_odd_room_frames(self) -> None:
        even = lifecycle.update_type41(self.record, room_frame_counter=2)
        odd = lifecycle.update_type41(self.record, room_frame_counter=3)
        self.assertEqual(even.y, self.record.y)
        self.assertEqual(odd.y, self.record.y - 1)

    def test_type41_lifetime_one_clears_after_motion(self) -> None:
        result = lifecycle.update_type41(
            replace(self.record, byte5=1), room_frame_counter=3
        )
        self.assertEqual(result, lifecycle.clear_runtime_object())

    def test_type41_zero_lifetime_wraps_to_255(self) -> None:
        result = lifecycle.update_type41(
            replace(self.record, byte5=0), room_frame_counter=0
        )
        self.assertEqual(result.byte5, 0xFF)
        self.assertEqual(result.runtime_type, self.record.runtime_type)

    def test_rejects_values_outside_machine_widths(self) -> None:
        with self.assertRaises(lifecycle.TransientObjectLifecycleError):
            lifecycle.update_type40(replace(self.record, state=0x100))


if __name__ == "__main__":
    unittest.main()
