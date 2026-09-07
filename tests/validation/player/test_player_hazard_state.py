from __future__ import annotations

import unittest

from scripts.validation.player import player_hazard_state


class PlayerHazardStateTests(unittest.TestCase):
    def test_countdown_ticks_only_every_32_room_frames(self) -> None:
        self.assertEqual(
            player_hazard_state.tick_protection_countdown(2, 0),
            player_hazard_state.CountdownResult(1, False),
        )
        self.assertEqual(
            player_hazard_state.tick_protection_countdown(2, 31),
            player_hazard_state.CountdownResult(2, False),
        )
        self.assertEqual(
            player_hazard_state.tick_protection_countdown(2, 32),
            player_hazard_state.CountdownResult(1, False),
        )

    def test_countdown_restarts_room_audio_exactly_on_expiry(self) -> None:
        self.assertEqual(
            player_hazard_state.tick_protection_countdown(1, 0),
            player_hazard_state.CountdownResult(0, True),
        )
        self.assertEqual(
            player_hazard_state.tick_protection_countdown(0, 0),
            player_hazard_state.CountdownResult(0, False),
        )

    def test_exact_three_cell_values_are_hazardous(self) -> None:
        matches = [
            cell
            for cell in range(0x100)
            if player_hazard_state.classify_hazard_cell(cell)
        ]
        self.assertEqual(matches, [0x16, 0x62, 0x63])

    def test_probe_maps_every_room_cell(self) -> None:
        room = bytearray(player_hazard_state.ROOM_CELL_COUNT)
        room[399] = 0x16
        result = player_hazard_state.sample_player_hazard_contact(
            bytes(room),
            player_x=19 * 16,
            player_y=19 * 8 + 8,
            previous_contact_flag=0,
        )
        self.assertEqual(result.cell_index, 399)
        self.assertEqual(result.contact_flag, 0xFF)

    def test_probe_uses_wrapped_16_bit_x_and_8_bit_y(self) -> None:
        room = bytearray(player_hazard_state.ROOM_CELL_COUNT)
        room[0] = 0x62
        result = player_hazard_state.sample_player_hazard_contact(
            bytes(room),
            player_x=0xFFF9,
            player_y=8,
            previous_contact_flag=0,
        )
        self.assertEqual(result.probe_x, 0)
        self.assertEqual(result.cell_index, 0)
        self.assertEqual(result.contact_flag, 0xFF)

    def test_out_of_room_probe_clears_contact(self) -> None:
        room = bytes([0x16]) * player_hazard_state.ROOM_CELL_COUNT
        for player_x, player_y in ((0x139, 8), (0, 7), (0, 168)):
            result = player_hazard_state.sample_player_hazard_contact(
                room,
                player_x=player_x,
                player_y=player_y,
                previous_contact_flag=0xFF,
            )
            self.assertFalse(result.sampled)
            self.assertEqual(result.contact_flag, 0)

    def test_previous_contact_dead_read_does_not_affect_result(self) -> None:
        room = bytes([0x16]) + bytes(player_hazard_state.ROOM_CELL_COUNT - 1)
        kwargs = {"player_x": 0, "player_y": 8}
        self.assertEqual(
            player_hazard_state.sample_player_hazard_contact(
                room, previous_contact_flag=0, **kwargs
            ),
            player_hazard_state.sample_player_hazard_contact(
                room, previous_contact_flag=0xFF, **kwargs
            ),
        )

    def test_dual_expiry_reselects_room_audio_twice_in_order(self) -> None:
        result = player_hazard_state.update_player_hazard_state(
            bytes(player_hazard_state.ROOM_CELL_COUNT),
            hazard_protection_countdown=1,
            invulnerability_countdown=1,
            room_frame=0,
            player_x=0,
            player_y=8,
            previous_contact_flag=0,
        )
        self.assertEqual(
            result.calls,
            (
                player_hazard_state.SELECT_ROOM_AUDIO,
                player_hazard_state.SELECT_ROOM_AUDIO,
            ),
        )

    def test_rejects_invalid_machine_widths_and_room_shape(self) -> None:
        with self.assertRaises(player_hazard_state.PlayerHazardStateError):
            player_hazard_state.tick_protection_countdown(0x100, 0)
        with self.assertRaises(player_hazard_state.PlayerHazardStateError):
            player_hazard_state.sample_player_hazard_contact(
                bytes(399), player_x=0, player_y=0, previous_contact_flag=0
            )


if __name__ == "__main__":
    unittest.main()
