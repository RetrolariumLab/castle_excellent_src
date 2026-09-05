from __future__ import annotations

from pathlib import Path
import unittest

from scripts import player_collision_update


ROOT = Path(__file__).resolve().parent.parent


class PlayerCollisionUpdateTests(unittest.TestCase):
    def test_probe_order_covers_corners_center_and_extra_top_samples(self) -> None:
        probes = player_collision_update.build_collision_probes(100, 50)
        self.assertEqual(
            probes,
            tuple(
                player_collision_update.CollisionProbe(x, y)
                for x, y in (
                    (100, 50),
                    (115, 50),
                    (100, 65),
                    (115, 65),
                    (107, 57),
                    (107, 50),
                    (115, 50),
                )
            ),
        )

    def test_probe_coordinates_wrap_at_machine_width(self) -> None:
        probes = player_collision_update.build_collision_probes(0xFFF9, 0xF9)
        self.assertEqual(probes[3], player_collision_update.CollisionProbe(8, 8))

    def test_each_probe_is_sampled_then_dispatched(self) -> None:
        result = player_collision_update.plan_player_collision_update(
            transition_countdown=0,
            player_x=0,
            player_y=0,
            hazard_cell_contact=0,
            hazard_protection_countdown=0,
        )
        self.assertEqual(len(result.probes), 7)
        self.assertEqual(
            result.calls,
            (
                player_collision_update.SAMPLE_CALL,
                player_collision_update.DISPATCH_CALL,
            ) * 7,
        )

    def test_active_transition_skips_collision_probes(self) -> None:
        result = player_collision_update.plan_player_collision_update(
            transition_countdown=1,
            player_x=0,
            player_y=0,
            hazard_cell_contact=0xFF,
            hazard_protection_countdown=0,
        )
        self.assertEqual(result.probes, ())
        self.assertEqual(result.calls, (player_collision_update.ADVANCE_TRANSITION_CALL,))
        self.assertFalse(result.starts_death_transition)

    def test_unprotected_hazard_contact_starts_death_after_probes(self) -> None:
        result = player_collision_update.plan_player_collision_update(
            transition_countdown=0,
            player_x=0,
            player_y=0,
            hazard_cell_contact=0xFF,
            hazard_protection_countdown=0,
        )
        self.assertTrue(result.starts_death_transition)
        self.assertEqual(result.calls[-1], player_collision_update.START_DEATH_CALL)

    def test_protection_suppresses_hazard_death(self) -> None:
        result = player_collision_update.plan_player_collision_update(
            transition_countdown=0,
            player_x=0,
            player_y=0,
            hazard_cell_contact=0xFF,
            hazard_protection_countdown=1,
        )
        self.assertFalse(result.starts_death_transition)
        self.assertNotIn(player_collision_update.START_DEATH_CALL, result.calls)

    def test_reference_rom_and_exhaustive_contracts(self) -> None:
        prg = player_collision_update.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        self.assertEqual(player_collision_update.validate_rom_contract(prg)["routine_bytes"], 112)
        self.assertEqual(
            player_collision_update.validate_exhaustive_contract(),
            {"player_x_cases": 65_536, "player_y_cases": 256, "state_cases": 1024},
        )


if __name__ == "__main__":
    unittest.main()
