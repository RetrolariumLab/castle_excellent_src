from pathlib import Path
import unittest

from scripts import collision_point_sample
from scripts import unreferenced_runtime_only_sample as runtime_only


ROOT = Path(__file__).resolve().parent.parent


class UnreferencedRuntimeOnlySampleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = runtime_only.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        cls.empty = (collision_point_sample.RuntimeObject(),) * 24

    def test_vertical_guard_preserves_input_x_register(self) -> None:
        sample = runtime_only.sample_runtime_objects(self.empty, x=0x1234, y=0xA0)
        self.assertEqual((sample.accumulator, sample.x_register, sample.y_register), (0x53, 0x34, 0))
        self.assertFalse(sample.carry)

    def test_exhaustion_leaves_last_record_offset_in_x(self) -> None:
        sample = runtime_only.sample_runtime_objects(self.empty, x=0, y=0)
        self.assertEqual(sample.x_register, 0x8A)
        self.assertEqual(sample.source, "empty")

    def test_current_object_is_not_excluded(self) -> None:
        records = list(self.empty)
        records[0] = collision_point_sample.RuntimeObject(0x80, 100, 50)
        sample = runtime_only.sample_runtime_objects(tuple(records), x=100, y=50)
        self.assertEqual(sample.object_offset, 0)

    def test_first_matching_runtime_slot_wins(self) -> None:
        records = list(self.empty)
        records[4] = collision_point_sample.RuntimeObject(0x80, 100, 50)
        records[7] = collision_point_sample.RuntimeObject(0x80, 100, 50)
        sample = runtime_only.sample_runtime_objects(tuple(records), x=100, y=50)
        self.assertEqual(sample.object_offset, 4 * 6)

    def test_bounds_are_left_top_inclusive_and_right_bottom_exclusive(self) -> None:
        records = list(self.empty)
        records[0] = collision_point_sample.RuntimeObject(0x80, 100, 50)
        width = runtime_only.collision_tables.EXPECTED_WIDTHS[0]
        height = runtime_only.collision_tables.EXPECTED_HEIGHTS[0]
        self.assertEqual(runtime_only.sample_runtime_objects(tuple(records), x=100, y=50).object_offset, 0)
        self.assertIsNone(runtime_only.sample_runtime_objects(tuple(records), x=100 + width, y=50).object_offset)
        self.assertIsNone(runtime_only.sample_runtime_objects(tuple(records), x=100, y=50 + height).object_offset)

    def test_japanese_reference_contract(self) -> None:
        report = runtime_only.validate_contract(
            self.prg,
            runtime_only.load_instruction_starts(ROOT / "build/ghidra/instructions.tsv"),
            runtime_only.load_code_evidence(ROOT / "config/runtime_evidence.txt"),
        )
        self.assertEqual(report["bytes"], 115)
        self.assertEqual(report["dispatch_entries_checked"], 641)
        self.assertFalse(report["revision_match"])


if __name__ == "__main__":
    unittest.main()
