from pathlib import Path
import unittest

from scripts.validation.objects import runtime_type9f_collision


ROOT = Path(__file__).resolve().parent.parent


class RuntimeType9FCollisionTests(unittest.TestCase):
    def test_positive_frame_phase_is_inactive(self) -> None:
        result = runtime_type9f_collision.collide_runtime_type9f(0x7F, 1, 1, 0)
        self.assertFalse(result.refreshed)
        self.assertEqual(result.invulnerability_countdown, 0)

    def test_x_mismatch_is_inactive(self) -> None:
        result = runtime_type9f_collision.collide_runtime_type9f(0x80, 1, 2, 0)
        self.assertFalse(result.refreshed)

    def test_zero_countdown_starts_audio_and_refreshes(self) -> None:
        result = runtime_type9f_collision.collide_runtime_type9f(0x80, 7, 7, 0)
        self.assertEqual(result.invulnerability_countdown, 0x28)
        self.assertTrue(result.load_audio_track_set_3)

    def test_nonzero_countdown_only_refreshes(self) -> None:
        result = runtime_type9f_collision.collide_runtime_type9f(0xFF, 7, 7, 1)
        self.assertEqual(result.invulnerability_countdown, 0x28)
        self.assertFalse(result.load_audio_track_set_3)

    def test_rejects_values_outside_machine_width(self) -> None:
        with self.assertRaises(runtime_type9f_collision.RuntimeType9FError):
            runtime_type9f_collision.collide_runtime_type9f(0x100, 0, 0, 0)

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = runtime_type9f_collision.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = runtime_type9f_collision.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 26)
        self.assertEqual(
            runtime_type9f_collision.validate_exhaustive_contract()["state_cases"],
            66_048,
        )


if __name__ == "__main__":
    unittest.main()
