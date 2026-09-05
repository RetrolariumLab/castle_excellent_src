from pathlib import Path
import unittest

from scripts import runtime_types81_82_collision as collision


ROOT = Path(__file__).resolve().parent.parent


class RuntimeTypes8182CollisionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.current = collision.RuntimeRecord(0x81, 0x0010, 0x40, 3, 4)
        self.clone = collision.RuntimeRecord(0xAA, 0x1234, 0x50, 5, 6)

    def test_type82_completion_discards_synthetic_return(self) -> None:
        result = collision.collide_runtime_type82(0, True)
        self.assertTrue(result.load_audio_track_set_4)
        self.assertEqual(result.discarded_stack_bytes, 2)
        self.assertEqual(result.completion_target, 0xFE8E)

    def test_type82_guards_game_over_and_distance(self) -> None:
        self.assertIsNone(collision.collide_runtime_type82(1, True).completion_target)
        self.assertIsNone(collision.collide_runtime_type82(0, False).completion_target)

    def test_type81_transforms_current_record(self) -> None:
        result = collision.collide_runtime_type81(0, True, self.current, self.clone)
        self.assertEqual(result.current, collision.RuntimeRecord(0x91, 0, 0x40, 3, 4))
        self.assertEqual(result.clone, self.clone)
        self.assertTrue(result.load_audio_track_set_7)

    def test_type81_room59_writes_final_record_fields_only(self) -> None:
        result = collision.collide_runtime_type81(0x59, True, self.current, self.clone)
        self.assertEqual(result.clone, collision.RuntimeRecord(0x91, 0xFFF0, 0x40, 5, 6))
        self.assertTrue(result.clone_written)

    def test_type81_distance_guard_preserves_both_records(self) -> None:
        result = collision.collide_runtime_type81(0x59, False, self.current, self.clone)
        self.assertEqual(result.current, self.current)
        self.assertEqual(result.clone, self.clone)
        self.assertFalse(result.load_audio_track_set_7)

    def test_rejects_values_outside_machine_width(self) -> None:
        with self.assertRaises(collision.RuntimeTypes8182Error):
            collision.collide_runtime_type82(0x100, True)

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = collision.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        report = collision.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 84)
        self.assertEqual(report["pointer_entries"], 8)
        exhaustive = collision.validate_exhaustive_contract()
        self.assertEqual(exhaustive["audio_pointer_pairs"], 65_536)
        self.assertEqual(exhaustive["x_values"], 65_536)


if __name__ == "__main__":
    unittest.main()
