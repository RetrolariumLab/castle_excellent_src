from pathlib import Path
import unittest

from scripts import player_object_push as push


ROOT = Path(__file__).resolve().parent.parent


class PlayerObjectPushTests(unittest.TestCase):
    def arguments(self, direction: int = push.DIRECTION_RIGHT) -> dict[str, object]:
        return push._base_arguments(direction)

    def test_right_push_moves_player_and_object_two_pixels(self) -> None:
        result = push.push_player_and_object(**self.arguments())
        self.assertTrue(result.moved)
        self.assertEqual((result.player_x, result.object_x), (0x82, 0x92))
        self.assertEqual(result.direction_latch, 0x7F)
        self.assertEqual(result.object_probes, ((0xA0, 0x40), (0xA0, 0x47), (0xA0, 0x4F)))

    def test_left_push_uses_asymmetric_player_edges(self) -> None:
        result = push.push_player_and_object(**self.arguments(push.DIRECTION_LEFT))
        self.assertTrue(result.moved)
        self.assertEqual((result.player_x, result.object_x), (0x7E, 0x8E))
        self.assertEqual(
            result.player_probes,
            ((0x7E, 0x40), (0x7F, 0x47), (0x7F, 0x4F)),
        )

    def test_object_must_be_supported(self) -> None:
        arguments = self.arguments()
        arguments["support_collisions"] = (False, False, False)
        result = push.push_player_and_object(**arguments)
        self.assertFalse(result.moved)
        self.assertEqual(result.blocked_by, "object unsupported")
        self.assertEqual(len(result.support_probes), 3)

    def test_collision_with_pushed_object_does_not_block_player(self) -> None:
        arguments = self.arguments()
        arguments["player_collisions"] = (0x18, 0x18, 0x18)
        self.assertTrue(push.push_player_and_object(**arguments).moved)
        arguments["player_collisions"] = (0x18, 0x24, None)
        result = push.push_player_and_object(**arguments)
        self.assertFalse(result.moved)
        self.assertEqual(result.blocked_by, "player obstruction")
        self.assertEqual(len(result.player_probes), 2)

    def test_types_84_through_89_are_destroyed_and_push_continues(self) -> None:
        for runtime_type in range(0x84, 0x8A):
            arguments = self.arguments()
            arguments["object_collisions"] = (
                push.CollisionSample(runtime_type, True, 0x30),
                push.CollisionSample(0x53, False),
                push.CollisionSample(0x53, False),
            )
            result = push.push_player_and_object(**arguments)
            self.assertTrue(result.moved)
            self.assertEqual(result.destroyed_object_offset, 0x30)
            self.assertEqual(len(result.object_probes), 1)

    def test_room_and_object_boundaries_are_exact(self) -> None:
        right = self.arguments()
        right["object_x"] = 0x0130
        self.assertFalse(push.push_player_and_object(**right).moved)
        right["object_x"] = 0x012F
        self.assertTrue(push.push_player_and_object(**right).moved)
        left = self.arguments(push.DIRECTION_LEFT)
        left["object_x"] = 0
        self.assertFalse(push.push_player_and_object(**left).moved)
        left["object_x"] = 1
        self.assertTrue(push.push_player_and_object(**left).moved)

    def test_motion_state_or_phase_prevents_push(self) -> None:
        for field, value in (("motion_state", 1), ("motion_phase", 0xFF)):
            arguments = self.arguments()
            arguments[field] = value
            self.assertEqual(
                push.push_player_and_object(**arguments).blocked_by,
                "player motion",
            )

    def test_reference_rom_and_exhaustive_model(self) -> None:
        prg = push.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        report = push.validate_rom_contract(prg)
        self.assertEqual(report["bytes"], 455)
        self.assertEqual(len(report["horizontal_handlers"]), 6)
        self.assertEqual(push.validate_model_contract()["horizontal_cases"], 262_144)


if __name__ == "__main__":
    unittest.main()
