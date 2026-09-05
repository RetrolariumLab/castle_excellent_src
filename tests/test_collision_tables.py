from __future__ import annotations

import unittest

from scripts import collision_tables


class CollisionTableTests(unittest.TestCase):
    def test_cell_half_index_covers_both_entries_of_all_100_cells(self) -> None:
        self.assertEqual(collision_tables.room_cell_half_index(0, 0), 0)
        self.assertEqual(collision_tables.room_cell_half_index(0, 1), 1)
        self.assertEqual(collision_tables.room_cell_half_index(99, 1), 199)

    def test_player_negative_flag_does_not_set_carry(self) -> None:
        flags = collision_tables.decode_collision_flags(
            collision_tables.EXPECTED_PLAYER_FLAGS, 0x2F, 0
        )
        self.assertEqual(flags.raw, 0x80)
        self.assertTrue(flags.negative)
        self.assertFalse(flags.carry)

    def test_object_negative_flag_also_sets_carry(self) -> None:
        flags = collision_tables.decode_collision_flags(
            collision_tables.EXPECTED_OBJECT_FLAGS, 0x2F, 1
        )
        self.assertEqual(flags.raw, 0x81)
        self.assertTrue(flags.negative)
        self.assertTrue(flags.carry)

    def test_player_and_object_tables_preserve_asymmetric_halves(self) -> None:
        player = [
            collision_tables.decode_collision_flags(
                collision_tables.EXPECTED_PLAYER_FLAGS, 0x0B, half
            ).raw
            for half in range(2)
        ]
        objects = [
            collision_tables.decode_collision_flags(
                collision_tables.EXPECTED_OBJECT_FLAGS, 0x0B, half
            ).raw
            for half in range(2)
        ]
        self.assertEqual(player, [0, 0])
        self.assertEqual(objects, [0, 1])

    def test_runtime_type_90_is_narrow_but_full_height(self) -> None:
        dimensions = collision_tables.collision_dimensions(
            collision_tables.EXPECTED_WIDTHS,
            collision_tables.EXPECTED_HEIGHTS,
            0x90,
        )
        self.assertEqual((dimensions.width, dimensions.height), (8, 16))

    def test_runtime_type_a2_is_wide_and_short(self) -> None:
        dimensions = collision_tables.collision_dimensions(
            collision_tables.EXPECTED_WIDTHS,
            collision_tables.EXPECTED_HEIGHTS,
            0xA2,
        )
        self.assertEqual((dimensions.width, dimensions.height), (32, 8))

    def test_dimension_tables_cover_types_80_through_af(self) -> None:
        self.assertEqual(len(collision_tables.EXPECTED_WIDTHS), 48)
        self.assertEqual(len(collision_tables.EXPECTED_HEIGHTS), 48)
        dimensions = collision_tables.collision_dimensions(
            collision_tables.EXPECTED_WIDTHS,
            collision_tables.EXPECTED_HEIGHTS,
            0xAF,
        )
        self.assertEqual((dimensions.width, dimensions.height), (16, 16))
        self.assertEqual(
            collision_tables.OBJECT_HEIGHTS_CPU
            + collision_tables.OBJECT_DIMENSION_COUNT,
            collision_tables.ROOM_OBJECT_COUNTS_CPU,
        )

    def test_rejects_invalid_cell_half_type_and_shapes(self) -> None:
        with self.assertRaises(collision_tables.CollisionTableError):
            collision_tables.room_cell_half_index(100, 0)
        with self.assertRaises(collision_tables.CollisionTableError):
            collision_tables.room_cell_half_index(0, 2)
        with self.assertRaises(collision_tables.CollisionTableError):
            collision_tables.collision_dimensions(bytes(47), bytes(48), 0x80)
        with self.assertRaises(collision_tables.CollisionTableError):
            collision_tables.collision_dimensions(bytes(48), bytes(48), 0xB0)


if __name__ == "__main__":
    unittest.main()
