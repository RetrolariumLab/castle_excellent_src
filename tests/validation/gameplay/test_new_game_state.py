from __future__ import annotations

import unittest

from scripts.validation.gameplay import new_game_state


class NewGameStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.previous_runtime = bytes(range(15))
        self.previous_snapshot_b = bytes(range(0xA0, 0xA9))
        self.state = new_game_state.initialize_new_game(
            self.previous_runtime, self.previous_snapshot_b
        )

    def test_sets_starting_room_lives_and_player_position(self) -> None:
        self.assertEqual(self.state.current_room_state[0], 0x47)
        self.assertEqual(self.state.player_lives, 3)
        self.assertEqual((self.state.player_x, self.state.player_y), (0, 0x98))

    def test_copies_zero_runtime_before_setting_active_player_y(self) -> None:
        self.assertEqual(self.state.runtime_load_mirror[:14], bytes(14))
        self.assertEqual(self.state.runtime_snapshot_a, bytes(14))
        self.assertEqual(self.state.runtime_state[13], 0x98)

    def test_preserves_fields_the_original_does_not_clear(self) -> None:
        self.assertEqual(self.state.runtime_load_mirror[14], self.previous_runtime[14])
        self.assertEqual(self.state.room_state_snapshot_b[0], 0)
        self.assertEqual(
            self.state.room_state_snapshot_b[1:], self.previous_snapshot_b[1:]
        )

    def test_clears_persistent_regions_and_visited_flags(self) -> None:
        self.assertEqual(self.state.mutable_region, bytes(0x78))
        self.assertEqual(self.state.object_region, bytes(0x96))
        self.assertEqual(self.state.visited_rooms, bytes(100))

    def test_resets_modes_game_over_and_sound_effect_busy_flags(self) -> None:
        self.assertEqual(self.state.player_transition_countdown, 0)
        self.assertEqual(self.state.pause_mode, 0)
        self.assertEqual(self.state.castle_map_mode, 0)
        self.assertEqual(self.state.game_over_active, 0)
        self.assertEqual(self.state.sound_effect_busy, (0, 0, 0, 0))
        self.assertEqual(self.state.status_tiles_busy, 0xFF)

    def test_uses_room_palette_table_address(self) -> None:
        self.assertEqual(self.state.palette_address, 0xC53D)

    def test_rejects_wrong_snapshot_shapes(self) -> None:
        with self.assertRaises(new_game_state.NewGameStateError):
            new_game_state.initialize_new_game(bytes(14), self.previous_snapshot_b)
        with self.assertRaises(new_game_state.NewGameStateError):
            new_game_state.initialize_new_game(self.previous_runtime, bytes(8))


if __name__ == "__main__":
    unittest.main()
