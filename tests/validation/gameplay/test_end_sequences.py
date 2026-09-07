from pathlib import Path
import unittest

from scripts.validation.gameplay import end_sequences


ROOT = Path(__file__).resolve().parents[3]


class EndSequenceTests(unittest.TestCase):
    def test_game_over_message_decodes_from_tiles(self) -> None:
        self.assertEqual(end_sequences.decode_message(end_sequences.EXPECTED_MESSAGE), "GAME OVER")

    def test_high_score_keeps_unsigned_maximum(self) -> None:
        self.assertEqual(end_sequences.update_high_score(0x8000, 0x7FFF), 0x8000)
        self.assertEqual(end_sequences.update_high_score(0x1234, 0x4321), 0x4321)
        self.assertEqual(end_sequences.update_high_score(0x4321, 0x4321), 0x4321)

    def test_high_score_rejects_non_words(self) -> None:
        with self.assertRaises(end_sequences.EndSequenceError):
            end_sequences.update_high_score(0x10000, 0)

    def test_game_over_waits_then_resets(self) -> None:
        route = end_sequences.game_over_route()
        self.assertEqual(route.audio_track_set, 2)
        self.assertEqual(route.reset_delay_vblanks, 60)
        self.assertEqual(route.terminal_target, 0x8225)
        self.assertFalse(route.freezes_after_audio)

    def test_type82_completion_freezes_after_audio(self) -> None:
        route = end_sequences.type82_completion_route()
        self.assertEqual(route.audio_track_set, 4)
        self.assertTrue(route.freezes_after_audio)
        self.assertIsNone(route.terminal_target)

    def test_reference_rom_and_exhaustive_score_contracts(self) -> None:
        prg = end_sequences.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        report = end_sequences.validate_rom_contract(prg)
        self.assertEqual(report["bytes"], 183)
        self.assertEqual(report["message"], "GAME OVER")
        self.assertEqual(report["calls"], 19)
        self.assertEqual(end_sequences.validate_score_contract()["score_cases"], 655_360)


if __name__ == "__main__":
    unittest.main()
