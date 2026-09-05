from pathlib import Path
import unittest

from scripts import collectible_collision_handlers


ROOT = Path(__file__).resolve().parent.parent


class CollectibleCollisionHandlerTests(unittest.TestCase):
    def test_far_player_leaves_every_state_unchanged(self) -> None:
        result = collectible_collision_handlers.collect_runtime_object(
            0x83, False, 7, 8, 9
        )
        self.assertFalse(result.collected)
        self.assertEqual((result.screen_state, result.protection_countdown), (7, 8))
        self.assertEqual(result.effect_latch, 9)

    def test_runtime_type_83_increments_screen_and_installs_protection(self) -> None:
        result = collectible_collision_handlers.collect_runtime_object(
            0x83, True, 0xFF, 0, 0x55
        )
        self.assertEqual(result.screen_state, 0)
        self.assertEqual(result.protection_countdown, 0x28)
        self.assertTrue(result.load_audio_track_set_1)
        self.assertEqual((result.score_award, result.collected_state), (100, 9))

    def test_runtime_type_83_reuses_active_audio_without_reloading(self) -> None:
        result = collectible_collision_handlers.collect_runtime_object(
            0x83, True, 1, 1, 0
        )
        self.assertFalse(result.load_audio_track_set_1)
        self.assertEqual(result.protection_countdown, 0x28)

    def test_runtime_type_96_sets_effect_latch(self) -> None:
        result = collectible_collision_handlers.collect_runtime_object(
            0x96, True, 1, 2, 3
        )
        self.assertEqual(result.effect_latch, 0xFF)
        self.assertEqual((result.score_award, result.collected_state), (100, 9))

    def test_scored_collectible_specs_match_machine_values(self) -> None:
        expected = {0x98: (20, 6), 0x99: (40, 7), 0x9A: (80, 8), 0x9B: (100, 9)}
        for runtime_type, score_and_state in expected.items():
            with self.subTest(runtime_type=runtime_type):
                result = collectible_collision_handlers.collect_runtime_object(
                    runtime_type, True, 0, 0, 0
                )
                self.assertEqual(
                    (result.score_award, result.collected_state), score_and_state
                )

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = collectible_collision_handlers.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = collectible_collision_handlers.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 114)
        self.assertEqual(len(report["handler_targets"]), 6)
        self.assertEqual(
            collectible_collision_handlers.validate_exhaustive_contract(),
            {"runtime_types": 6, "state_cases": 786_432},
        )


if __name__ == "__main__":
    unittest.main()
