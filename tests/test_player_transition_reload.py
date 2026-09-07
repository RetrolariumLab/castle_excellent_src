from __future__ import annotations

from pathlib import Path
import unittest

from scripts.validation.player import player_transition_reload


ROOT = Path(__file__).resolve().parent.parent
BASE_ARGS = {
    "current_player_x": 0x1234,
    "current_player_y": 0x56,
    "saved_player_x": 0x0130,
    "saved_player_y": 0x98,
    "hazard_protection_countdown": 0,
    "transition_protection_mirror": 0,
    "transition_screen_state": 0,
    "reserve_lives": 2,
    "game_over_active": 0,
    "current_room": 71,
    "current_object_state": b"\x01\x02\x03",
    "current_mutable_state": b"\x04\x05\x06\x07\x08",
    "pause_mode": 0,
}


class PlayerTransitionReloadTests(unittest.TestCase):
    def test_nonfinal_countdown_only_decrements(self) -> None:
        result = player_transition_reload.advance_player_transition(
            transition_countdown=2, **BASE_ARGS
        )
        self.assertFalse(result.completed)
        self.assertEqual(result.transition_countdown, 1)
        self.assertEqual(result.player_x, BASE_ARGS["current_player_x"])
        self.assertEqual(result.calls, ())

    def test_zero_countdown_preserves_original_wraparound(self) -> None:
        result = player_transition_reload.advance_player_transition(
            transition_countdown=0, **BASE_ARGS
        )
        self.assertFalse(result.completed)
        self.assertEqual(result.transition_countdown, 0xFF)

    def test_final_tick_restores_player_and_copies_persistent_state(self) -> None:
        result = player_transition_reload.advance_player_transition(
            transition_countdown=1, **BASE_ARGS
        )
        self.assertTrue(result.completed)
        self.assertEqual(result.player_x, BASE_ARGS["saved_player_x"])
        self.assertEqual(result.player_y, BASE_ARGS["saved_player_y"])
        self.assertEqual(result.decoded_room_index, 70)
        self.assertEqual(result.reload_object_state, b"\x01\x02\x03")
        self.assertEqual(result.reload_mutable_state, b"\x04\x05\x06\x07\x08")
        self.assertEqual(result.pause_mode, 0xFF)
        self.assertEqual(result.calls, player_transition_reload.RELOAD_CALLS)

    def test_protection_uses_maximum_plus_ten_with_byte_wrap(self) -> None:
        self.assertEqual(player_transition_reload.extend_hazard_protection(5, 10, 0), 20)
        self.assertEqual(player_transition_reload.extend_hazard_protection(20, 10, 0), 30)
        self.assertEqual(player_transition_reload.extend_hazard_protection(0xFA, 1, 0), 4)

    def test_screen_state_forces_fifty_protection_units(self) -> None:
        for current, mirror in ((0, 0), (0xFF, 0xFF)):
            self.assertEqual(
                player_transition_reload.extend_hazard_protection(current, mirror, 1),
                0x32,
            )

    def test_game_over_branch_skips_room_reload(self) -> None:
        args = dict(BASE_ARGS)
        args.update(reserve_lives=0, game_over_active=0xFF)
        result = player_transition_reload.advance_player_transition(
            transition_countdown=1, **args
        )
        self.assertEqual(result.calls, (player_transition_reload.GAME_OVER_CALL,))
        self.assertIsNone(result.decoded_room_index)

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = player_transition_reload.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        self.assertEqual(
            player_transition_reload.validate_rom_contract(prg)["routine_bytes"], 129
        )
        self.assertEqual(
            player_transition_reload.validate_exhaustive_contract(),
            {"countdown_cases": 256, "protection_cases": 131_072},
        )


if __name__ == "__main__":
    unittest.main()
