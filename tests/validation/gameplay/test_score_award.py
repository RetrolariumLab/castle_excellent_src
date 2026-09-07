from pathlib import Path
import unittest

from scripts.validation.gameplay import score_award


ROOT = Path(__file__).resolve().parents[3]


class ScoreAwardTests(unittest.TestCase):
    def test_demo_suppresses_score_and_threshold_life(self) -> None:
        self.assertEqual(
            score_award.add_player_score(950, 3, 100, True),
            score_award.ScoreAwardResult(950, 3, False),
        )

    def test_score_add_without_threshold(self) -> None:
        self.assertEqual(
            score_award.add_player_score(100, 3, 100),
            score_award.ScoreAwardResult(200, 3, False),
        )

    def test_threshold_awards_one_life(self) -> None:
        self.assertEqual(
            score_award.add_player_score(950, 3, 100),
            score_award.ScoreAwardResult(1050, 4, True),
        )

    def test_threshold_life_saturates(self) -> None:
        self.assertEqual(score_award.add_player_score(950, 0xFF, 100).lives, 0xFF)

    def test_wrapped_score_changes_bucket_and_awards_life(self) -> None:
        self.assertEqual(
            score_award.add_player_score(0xFFF0, 3, 100),
            score_award.ScoreAwardResult(0x0054, 4, True),
        )

    def test_type97_orders_saturating_then_wrapping_life_awards(self) -> None:
        result = score_award.collect_runtime_type97(True, 950, 0xFE)
        self.assertEqual((result.score, result.lives), (1050, 0))
        self.assertEqual(result.collected_state, 9)
        self.assertTrue(result.score_life_awarded)
        demo = score_award.collect_runtime_type97(True, 950, 0xFF, True)
        self.assertEqual((demo.score, demo.lives), (950, 0))

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = score_award.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        report = score_award.validate_rom_contract(prg)
        self.assertEqual((report["type97_bytes"], report["score_bytes"]), (18, 57))
        exhaustive = score_award.validate_exhaustive_contract()
        self.assertEqual(exhaustive["score_domain"], 65_536)
        self.assertGreater(exhaustive["state_cases"], 350_000)


if __name__ == "__main__":
    unittest.main()
