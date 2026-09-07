from __future__ import annotations

import unittest

from scripts.validation.collision import collision_cells


class CollisionCellTests(unittest.TestCase):
    def test_cell_pair_index_filter_matches_exactly_8a_through_91(self) -> None:
        matches = [
            value
            for value in range(0x100)
            if collision_cells.collision_cell_pair_index_matches(value)
        ]
        self.assertEqual(matches, list(range(0x8A, 0x92)))

    def test_cell_pair_index_filter_rejects_non_bytes(self) -> None:
        for value in (-1, 0x100):
            with self.assertRaises(collision_cells.CollisionCellError):
                collision_cells.collision_cell_pair_index_matches(value)

    def test_runtime_type_filter_matches_exactly_90_through_95(self) -> None:
        matches = [
            value
            for value in range(0x100)
            if collision_cells.runtime_type_matches_90_to_95(value)
        ]
        self.assertEqual(matches, list(range(0x90, 0x96)))

    def test_mutable_visual_cells_normalize_to_53_and_clear_carry(self) -> None:
        for cell in collision_cells.MUTABLE_COLLISION_CELLS:
            result = collision_cells.normalize_collision_sample(cell, 0xFF)
            self.assertEqual(result.cell, 0x53)
            self.assertEqual(result.status, 0xFE)

    def test_mutable_normalization_preserves_every_non_carry_flag(self) -> None:
        for status in range(0x100):
            result = collision_cells.normalize_collision_sample(0x54, status)
            self.assertEqual(result.status, status & 0xFE)

    def test_ordinary_cell_preserves_value_and_complete_status(self) -> None:
        sample = collision_cells.normalize_collision_sample(0x16, 0xA5)
        self.assertEqual(sample, collision_cells.CollisionSample(0x16, 0xA5))


if __name__ == "__main__":
    unittest.main()
