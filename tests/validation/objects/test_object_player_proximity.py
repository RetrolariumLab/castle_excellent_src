from __future__ import annotations

import unittest

from scripts.validation.objects import object_player_proximity


class ObjectPlayerProximityTests(unittest.TestCase):
    def test_interaction_point_uses_object_y_plus_16(self) -> None:
        result = object_player_proximity.evaluate_proximity(
            object_x=20, object_y=30, player_x=20, player_y=46
        )
        self.assertEqual(result.object_anchor_y, 46)
        self.assertEqual(result.y_distance, 0)
        self.assertTrue(result.near)

    def test_y_anchor_wraps_at_machine_byte_width(self) -> None:
        result = object_player_proximity.evaluate_proximity(
            object_x=0, object_y=0xF8, player_x=0, player_y=8
        )
        self.assertEqual(result.object_anchor_y, 8)
        self.assertTrue(result.near)

    def test_thresholds_are_exclusive(self) -> None:
        self.assertTrue(
            object_player_proximity.evaluate_proximity(
                object_x=4, object_y=0, player_x=0, player_y=19
            ).near
        )
        self.assertFalse(
            object_player_proximity.evaluate_proximity(
                object_x=5, object_y=0, player_x=0, player_y=16
            ).near
        )
        self.assertFalse(
            object_player_proximity.evaluate_proximity(
                object_x=0, object_y=0, player_x=0, player_y=20
            ).near
        )

    def test_far_y_returns_before_x_is_sampled(self) -> None:
        result = object_player_proximity.evaluate_proximity(
            object_x=0, object_y=0, player_x=0xFFFF, player_y=0
        )
        self.assertIsNone(result.x_distance)
        self.assertFalse(result.near)

    def test_negative_x_normalization_matches_legacy_arithmetic(self) -> None:
        self.assertEqual(object_player_proximity.normalize_x_delta(10, 14), 4)
        self.assertEqual(object_player_proximity.normalize_x_delta(0, 0x101), 0x101)

    def test_negative_one_page_delta_preserves_original_alias(self) -> None:
        result = object_player_proximity.evaluate_proximity(
            object_x=0, object_y=0, player_x=0x100, player_y=16
        )
        self.assertEqual(result.x_distance, 0)
        self.assertTrue(result.near)

    def test_rejects_values_outside_machine_widths(self) -> None:
        with self.assertRaises(object_player_proximity.ObjectPlayerProximityError):
            object_player_proximity.evaluate_proximity(
                object_x=0x10000, object_y=0, player_x=0, player_y=0
            )


if __name__ == "__main__":
    unittest.main()
