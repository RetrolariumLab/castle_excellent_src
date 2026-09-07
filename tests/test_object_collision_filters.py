from __future__ import annotations

import unittest

from scripts.validation.objects import object_collision_filters as filters


class ObjectCollisionFilterTests(unittest.TestCase):
    def test_decrementing_animation_family_returns_zero_direction(self) -> None:
        result = filters.classify_animated_collision_cell(0x35)
        self.assertTrue(result.matched)
        self.assertEqual(result.direction, 0)

    def test_incrementing_animation_family_returns_negative_direction(self) -> None:
        result = filters.classify_animated_collision_cell(0x61)
        self.assertTrue(result.matched)
        self.assertEqual(result.direction, 0xFF)

    def test_ordinary_cell_is_not_classified(self) -> None:
        self.assertEqual(
            filters.classify_animated_collision_cell(0x53),
            filters.AnimatedCellClassification(False, None),
        )

    def test_type_filter_is_zero_exactly_for_84_through_89(self) -> None:
        zero_types = [
            runtime_type
            for runtime_type in range(0xA8)
            if filters.get_type84_to89_filter(runtime_type) == 0
        ]
        self.assertEqual(zero_types, list(range(0x84, 0x8A)))

    def test_solid_filter_zero_domain_is_exact(self) -> None:
        non_solid = [
            runtime_type
            for runtime_type in range(0x80, 0xA8)
            if filters.get_runtime_object_solid_flag(runtime_type) == 0
        ]
        self.assertEqual(non_solid, [0x81, 0x82, 0x83, *range(0x90, 0x9D), 0x9F])

    def test_logical_tables_overlap_following_instruction_bytes(self) -> None:
        self.assertEqual(filters.get_type84_to89_filter(0xA6), 0xA8)
        self.assertEqual(filters.get_type84_to89_filter(0xA7), 0x08)
        self.assertEqual(filters.get_runtime_object_solid_flag(0xA6), 0xC0)
        self.assertEqual(filters.get_runtime_object_solid_flag(0xA7), 0xA0)

    def test_rejects_types_beyond_proven_consumer_domain(self) -> None:
        with self.assertRaises(filters.ObjectCollisionFilterError):
            filters.get_runtime_object_solid_flag(0xA8)


if __name__ == "__main__":
    unittest.main()
