from pathlib import Path
import unittest

from scripts import player_input_movement as movement


ROOT = Path(__file__).resolve().parent.parent


class PlayerInputMovementTests(unittest.TestCase):
    def test_motion_state_21_and_above_is_inactive(self) -> None:
        self.assertEqual(movement.active_motion_state(0x20), 0x20)
        self.assertEqual(movement.active_motion_state(0x21), 0)
        self.assertEqual(movement.active_motion_state(0xFF), 0)

    def test_action_press_hold_and_release_contract(self) -> None:
        started = movement.update_action_state(movement.CONTROLLER_B, 0, 0)
        self.assertEqual(started, movement.ActionState(10, 10))
        self.assertEqual(
            movement.update_action_state(movement.CONTROLLER_B, 10, 10),
            movement.ActionState(9, 10),
        )
        self.assertEqual(movement.update_action_state(0, 9, 10), movement.ActionState(0, 0))

    def test_horizontal_button_priority_rejects_both(self) -> None:
        self.assertEqual(movement.select_horizontal_direction(0x40), 0xFF)
        self.assertEqual(movement.select_horizontal_direction(0x80), 0x7F)
        self.assertEqual(movement.select_horizontal_direction(0xC0), 0)

    def test_horizontal_step_and_room_boundaries(self) -> None:
        self.assertEqual(
            movement.horizontal_step(movement.DIRECTION_RIGHT, 0x012E),
            movement.HorizontalStep(0x013F, 0x0130, None),
        )
        self.assertEqual(
            movement.horizontal_step(movement.DIRECTION_RIGHT, 0x012F).boundary,
            "right",
        )
        self.assertEqual(
            movement.horizontal_step(movement.DIRECTION_LEFT, 1).boundary,
            "left",
        )

    def test_action_probe_obeys_directional_room_limits(self) -> None:
        self.assertEqual(movement.action_probe(0x7F, 0x0129, 4), (0x013F, 0xFF))
        self.assertIsNone(movement.action_probe(0x7F, 0x012A, 4))
        self.assertEqual(movement.action_probe(0xFF, 6, 5), (0, 0))
        self.assertIsNone(movement.action_probe(0xFF, 5, 5))

    def test_action_destroys_only_types_84_87_88(self) -> None:
        blank = movement.RuntimeObject(0, 0, 0, 1, 1)
        for runtime_type in (0x84, 0x87, 0x88):
            target = movement.RuntimeObject(runtime_type, 10, 20, 8, 8, 0x55)
            result = movement.apply_action_hit((target,) + (blank,) * 23, 10, 20)
            self.assertTrue(result.destroyed)
            self.assertEqual(result.objects[0].runtime_type, 0xA8)
            self.assertEqual(result.objects[0].state, 0)
        blocking = movement.RuntimeObject(0x85, 10, 20, 8, 8, 0x55)
        result = movement.apply_action_hit((blocking,) + (blank,) * 23, 10, 20)
        self.assertFalse(result.destroyed)
        self.assertEqual(result.matched_index, 0)

    def test_first_overlapping_object_stops_scan(self) -> None:
        blank = movement.RuntimeObject(0, 0, 0, 1, 1)
        blocker = movement.RuntimeObject(0x85, 10, 20, 8, 8)
        target = movement.RuntimeObject(0x84, 10, 20, 8, 8)
        result = movement.apply_action_hit((blocker, target) + (blank,) * 22, 10, 20)
        self.assertEqual(result.matched_index, 0)
        self.assertFalse(result.destroyed)

    def test_reference_rom_and_exhaustive_model(self) -> None:
        prg = movement.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        self.assertEqual(movement.validate_rom_contract(prg)["bytes"], 940)
        report = movement.validate_model_contract()
        self.assertEqual(report["action_cases"], 196_608)
        self.assertEqual(report["movement_cases"], 131_072)


if __name__ == "__main__":
    unittest.main()
