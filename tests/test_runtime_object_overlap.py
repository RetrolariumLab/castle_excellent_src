from __future__ import annotations

import unittest

from scripts import runtime_object_overlap as overlap


class RuntimeObjectOverlapTests(unittest.TestCase):
    def test_skips_inactive_positive_type(self) -> None:
        result = overlap.candidate_overlaps(
            overlap.RuntimeObject(0x01, 100, 50),
            reference_x=100,
            reference_y=50,
            reference_width=16,
        )
        self.assertIsNone(result)

    def test_excludes_transient_types_at_or_above_a8(self) -> None:
        for runtime_type in (0xA8, 0xA9, 0xFF):
            self.assertIsNone(
                overlap.candidate_overlaps(
                    overlap.RuntimeObject(runtime_type, 100, 50),
                    reference_x=100,
                    reference_y=50,
                    reference_width=16,
                )
            )

    def test_vertical_bottom_boundary_is_exclusive(self) -> None:
        record = overlap.RuntimeObject(0x80, 100, 50)
        self.assertIsNotNone(
            overlap.candidate_overlaps(
                record, reference_x=100, reference_y=65, reference_width=16
            )
        )
        self.assertIsNone(
            overlap.candidate_overlaps(
                record, reference_x=100, reference_y=66, reference_width=16
            )
        )

    def test_horizontal_left_is_inclusive_and_right_is_exclusive(self) -> None:
        left = overlap.RuntimeObject(0x80, 85, 50)
        right = overlap.RuntimeObject(0x80, 116, 50)
        self.assertIsNotNone(
            overlap.candidate_overlaps(
                left, reference_x=100, reference_y=50, reference_width=16
            )
        )
        self.assertIsNone(
            overlap.candidate_overlaps(
                right, reference_x=100, reference_y=50, reference_width=16
            )
        )

    def test_left_boundary_saturates_at_zero(self) -> None:
        self.assertEqual(
            overlap.overlap_boundaries(
                reference_x=4, candidate_width=16, reference_width=16
            ),
            (0, 20),
        )

    def test_scan_returns_first_matching_record(self) -> None:
        empty = overlap.RuntimeObject()
        records = (
            empty,
            overlap.RuntimeObject(0x80, 100, 50),
            overlap.RuntimeObject(0x81, 100, 50),
        ) + (empty,) * 21
        match = overlap.find_runtime_object_overlap(
            records,
            start_offset=0,
            reference_x=100,
            reference_y=50,
            reference_width=16,
        )
        self.assertIsNotNone(match)
        self.assertEqual(match.record_offset, 6)

    def test_scan_can_resume_after_a_previous_match(self) -> None:
        empty = overlap.RuntimeObject()
        records = (
            empty,
            overlap.RuntimeObject(0x80, 100, 50),
            overlap.RuntimeObject(0x81, 100, 50),
        ) + (empty,) * 21
        match = overlap.find_runtime_object_overlap(
            records,
            start_offset=12,
            reference_x=100,
            reference_y=50,
            reference_width=16,
        )
        self.assertIsNotNone(match)
        self.assertEqual(match.record_offset, 12)

    def test_rejects_non_record_aligned_start_offset(self) -> None:
        with self.assertRaises(overlap.RuntimeObjectOverlapError):
            overlap.find_runtime_object_overlap(
                (overlap.RuntimeObject(),) * 24,
                start_offset=1,
                reference_x=0,
                reference_y=0,
                reference_width=0,
            )


if __name__ == "__main__":
    unittest.main()
