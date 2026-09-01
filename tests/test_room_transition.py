from __future__ import annotations

import unittest

from scripts import room_transition


class RoomTransitionTests(unittest.TestCase):
    def test_mirrors_player_position_into_runtime_offsets_11_to_13(self) -> None:
        result = room_transition.finish_room_transition(
            bytes(15), player_x=0x01F8, player_y=0x98, state_byte0=4, state_byte1=5
        )
        self.assertEqual(result.runtime_mirror[11:14], bytes((0xF8, 0x01, 0x98)))

    def test_preserves_unrelated_runtime_mirror_bytes(self) -> None:
        original = bytes(range(15))
        result = room_transition.finish_room_transition(
            original, player_x=0x1234, player_y=0x56, state_byte0=7, state_byte1=8
        )
        self.assertEqual(result.runtime_mirror[:11], original[:11])
        self.assertEqual(result.runtime_mirror[14], original[14])

    def test_restores_state_bytes_and_render_call_order(self) -> None:
        result = room_transition.finish_room_transition(
            bytes(15), player_x=0, player_y=0, state_byte0=0x28, state_byte1=9
        )
        self.assertEqual(result.state_mirror, (0x28, 9))
        self.assertEqual(result.pause_mode, 0xFF)
        self.assertEqual(result.render_calls, room_transition.RENDER_RESUME_CALLS)

    def test_rejects_invalid_transition_state(self) -> None:
        with self.assertRaises(room_transition.RoomTransitionError):
            room_transition.finish_room_transition(
                bytes(14), player_x=0, player_y=0, state_byte0=0, state_byte1=0
            )


if __name__ == "__main__":
    unittest.main()
