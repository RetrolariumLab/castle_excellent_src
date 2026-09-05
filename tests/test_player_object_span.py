from __future__ import annotations

import unittest

from scripts import player_object_span


class PlayerObjectSpanTests(unittest.TestCase):
    def test_vertical_span_includes_object_y_plus_one_through_plus_16(self) -> None:
        accepted = [
            player_y
            for player_y in range(0x100)
            if player_object_span.test_player_against_object_span(
                object_x=32,
                object_y=40,
                width=16,
                player_x=32,
                player_y=player_y,
            ).overlaps
        ]
        self.assertEqual(accepted, list(range(41, 57)))

    def test_vertical_addition_wraps_at_byte_width(self) -> None:
        result = player_object_span.test_player_against_object_span(
            object_x=32, object_y=0xF8, width=16, player_x=32, player_y=8
        )
        self.assertEqual(result.adjusted_bottom, 8)
        self.assertTrue(result.overlaps)

    def test_left_boundary_saturates_at_zero(self) -> None:
        result = player_object_span.test_player_against_object_span(
            object_x=7, object_y=0, width=16, player_x=0, player_y=16
        )
        self.assertEqual(result.left, 0)
        self.assertTrue(result.overlaps)

    def test_right_boundary_is_exclusive(self) -> None:
        inside = player_object_span.test_player_against_object_span(
            object_x=100, object_y=0, width=16, player_x=115, player_y=16
        )
        outside = player_object_span.test_player_against_object_span(
            object_x=100, object_y=0, width=16, player_x=116, player_y=16
        )
        self.assertTrue(inside.overlaps)
        self.assertFalse(outside.overlaps)

    def test_horizontal_comparison_uses_both_coordinate_bytes(self) -> None:
        result = player_object_span.test_player_against_object_span(
            object_x=0x110, object_y=0, width=16, player_x=0x100, player_y=16
        )
        self.assertFalse(result.overlaps)

    def test_rejects_values_outside_machine_widths(self) -> None:
        with self.assertRaises(player_object_span.PlayerObjectSpanError):
            player_object_span.test_player_against_object_span(
                object_x=0x10000,
                object_y=0,
                width=16,
                player_x=0,
                player_y=0,
            )


if __name__ == "__main__":
    unittest.main()
