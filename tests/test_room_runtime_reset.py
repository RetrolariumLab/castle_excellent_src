from __future__ import annotations

import unittest

from scripts import room_runtime_reset


class RoomRuntimeResetTests(unittest.TestCase):
    def test_clears_all_ten_room_runtime_fields(self) -> None:
        state = {
            name: index + 1
            for index, name in enumerate(room_runtime_reset.RESET_FIELDS)
        }
        reset = room_runtime_reset.reset_room_runtime_state(state)
        self.assertTrue(all(reset[name] == 0 for name in room_runtime_reset.RESET_FIELDS))

    def test_preserves_unrelated_state(self) -> None:
        state = {name: 0xFF for name in room_runtime_reset.RESET_FIELDS}
        state["unrelated"] = 0x5A
        reset = room_runtime_reset.reset_room_runtime_state(state)
        self.assertEqual(reset["unrelated"], 0x5A)

    def test_restarts_room_audio_only_for_zero_pointer(self) -> None:
        self.assertEqual(
            room_runtime_reset.room_audio_action(0, 0, 0),
            room_runtime_reset.RESTART_ROOM_AUDIO,
        )
        self.assertEqual(
            room_runtime_reset.room_audio_action(0, 1, 0),
            room_runtime_reset.KEEP_AUDIO,
        )
        self.assertEqual(
            room_runtime_reset.room_audio_action(0, 0, 1),
            room_runtime_reset.KEEP_AUDIO,
        )

    def test_game_over_suppresses_room_audio_restart(self) -> None:
        self.assertEqual(
            room_runtime_reset.room_audio_action(0xFF, 0, 0),
            room_runtime_reset.KEEP_AUDIO,
        )

    def test_rejects_missing_or_non_byte_state(self) -> None:
        with self.assertRaises(room_runtime_reset.RoomRuntimeResetError):
            room_runtime_reset.reset_room_runtime_state({})
        with self.assertRaises(room_runtime_reset.RoomRuntimeResetError):
            room_runtime_reset.room_audio_action(0, 0x100, 0)


if __name__ == "__main__":
    unittest.main()
