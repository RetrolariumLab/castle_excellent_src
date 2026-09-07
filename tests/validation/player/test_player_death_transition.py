from __future__ import annotations

from pathlib import Path
import unittest

from scripts.validation.player import player_death_transition


ROOT = Path(__file__).resolve().parents[3]


class PlayerDeathTransitionTests(unittest.TestCase):
    def test_invulnerability_blocks_death_without_mutation(self) -> None:
        result = player_death_transition.start_player_death_transition(
            invulnerability_countdown=1,
            transition_countdown=0,
            action_countdown=7,
            reserve_lives=3,
            game_over_active=0,
        )
        self.assertEqual(
            result,
            player_death_transition.PlayerDeathTransitionResult(
                False, 0, 7, 3, 0, None
            ),
        )

    def test_active_transition_blocks_death_without_mutation(self) -> None:
        result = player_death_transition.start_player_death_transition(
            invulnerability_countdown=0,
            transition_countdown=0x40,
            action_countdown=9,
            reserve_lives=2,
            game_over_active=0xA5,
        )
        self.assertEqual(
            result,
            player_death_transition.PlayerDeathTransitionResult(
                False, 0x40, 9, 2, 0xA5, None
            ),
        )

    def test_death_starts_transition_and_consumes_reserve_life(self) -> None:
        result = player_death_transition.start_player_death_transition(
            invulnerability_countdown=0,
            transition_countdown=0,
            action_countdown=0xFF,
            reserve_lives=3,
            game_over_active=0,
        )
        self.assertEqual(
            result,
            player_death_transition.PlayerDeathTransitionResult(
                True, 0x80, 0, 2, 0, 2
            ),
        )

    def test_zero_reserve_lives_sets_game_over(self) -> None:
        result = player_death_transition.start_player_death_transition(
            invulnerability_countdown=0,
            transition_countdown=0,
            action_countdown=4,
            reserve_lives=0,
            game_over_active=0,
        )
        self.assertEqual(result.reserve_lives, 0)
        self.assertEqual(result.game_over_active, 0xFF)
        self.assertEqual(result.audio_track_set, 2)

    def test_animated_hazard_is_active_during_nonnegative_phase(self) -> None:
        for animation_counter in (0x00, 0x7F):
            result = player_death_transition.handle_animated_player_hazard(
                animation_counter=animation_counter,
                invulnerability_countdown=0,
                transition_countdown=0,
                action_countdown=4,
                reserve_lives=3,
                game_over_active=0,
            )
            self.assertTrue(result.started)

    def test_animated_hazard_is_inactive_during_negative_phase(self) -> None:
        for animation_counter in (0x80, 0xFF):
            result = player_death_transition.handle_animated_player_hazard(
                animation_counter=animation_counter,
                invulnerability_countdown=0,
                transition_countdown=0,
                action_countdown=4,
                reserve_lives=3,
                game_over_active=0,
            )
            self.assertEqual(
                result,
                player_death_transition.PlayerDeathTransitionResult(
                    False, 0, 4, 3, 0, None
                ),
            )

    def test_nonzero_lives_preserve_existing_game_over_byte(self) -> None:
        result = player_death_transition.start_player_death_transition(
            invulnerability_countdown=0,
            transition_countdown=0,
            action_countdown=0,
            reserve_lives=1,
            game_over_active=0x55,
        )
        self.assertEqual(result.reserve_lives, 0)
        self.assertEqual(result.game_over_active, 0x55)

    def test_exhaustive_guard_and_life_domains(self) -> None:
        self.assertEqual(
            player_death_transition.validate_exhaustive_contract(),
            {
                "guard_cases": 65_536,
                "reserve_life_cases": 256,
                "animation_cases": 256,
            },
        )

    def test_reference_rom_contract_and_pointer_provenance(self) -> None:
        prg = player_death_transition.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        report = player_death_transition.validate_rom_contract(prg)
        self.assertEqual(report["routine_bytes"], 40)
        self.assertEqual(report["animated_room_handler_types"], [0x45, 0x46, 0x47, 0x48])
        self.assertEqual(len(report["room_handler_types"]), 39)
        self.assertEqual(len(report["runtime_handler_types"]), 18)

    def test_rejects_values_outside_machine_width(self) -> None:
        with self.assertRaises(player_death_transition.PlayerDeathTransitionError):
            player_death_transition.start_player_death_transition(
                invulnerability_countdown=0x100,
                transition_countdown=0,
                action_countdown=0,
                reserve_lives=0,
                game_over_active=0,
            )


if __name__ == "__main__":
    unittest.main()
