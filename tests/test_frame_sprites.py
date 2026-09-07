from __future__ import annotations

import unittest

from scripts.authoring import frame_sprites


class FrameSpriteTests(unittest.TestCase):
    def test_transition_uses_four_room_frame_phases(self) -> None:
        frames = tuple(
            frame_sprites.select_player_metasprite(
                transition_countdown=1,
                room_frame=phase << 2,
                direction=0,
                motion_state=0,
                motion_phase=0,
                action_countdown=0,
                frame_counter=0,
            )
            for phase in range(4)
        )
        self.assertEqual(frames, frame_sprites.PLAYER_TRANSITION_FRAMES)

    def test_neutral_and_directional_motion_frames_are_distinct(self) -> None:
        common = {
            "transition_countdown": 0,
            "room_frame": 0,
            "motion_state": 1,
            "motion_phase": 0,
            "action_countdown": 0,
            "frame_counter": 0,
        }
        self.assertEqual(
            frame_sprites.select_player_metasprite(direction=0, **common),
            frame_sprites.PLAYER_NEUTRAL_MOTION_METASPRITE,
        )
        self.assertEqual(
            frame_sprites.select_player_metasprite(direction=1, **common),
            frame_sprites.PLAYER_RIGHT_MOTION_METASPRITE,
        )
        self.assertEqual(
            frame_sprites.select_player_metasprite(direction=0xFF, **common),
            frame_sprites.PLAYER_LEFT_MOTION_METASPRITE,
        )

    def test_walk_cycle_reuses_the_middle_frame(self) -> None:
        frames = tuple(
            frame_sprites.select_player_metasprite(
                transition_countdown=0,
                room_frame=0,
                direction=1,
                motion_state=0,
                motion_phase=0,
                action_countdown=0,
                frame_counter=phase << 3,
            )
            for phase in range(4)
        )
        self.assertEqual(frames, frame_sprites.PLAYER_RIGHT_WALK_FRAMES)
        self.assertEqual(frames[1], frames[3])

    def test_action_sprite_uses_directional_offset_and_flip(self) -> None:
        right = frame_sprites.build_player_action_sprite(
            first_sprite_y=0x40,
            first_sprite_x=0x80,
            direction=1,
            action_countdown=1,
        )
        left = frame_sprites.build_player_action_sprite(
            first_sprite_y=0x40,
            first_sprite_x=0x80,
            direction=0xFF,
            action_countdown=1,
        )
        self.assertEqual(right, frame_sprites.HardwareSprite(0x40, 0xCA, 0x03, 0x8F))
        self.assertEqual(left, frame_sprites.HardwareSprite(0x40, 0xCA, 0x43, 0x79))

    def test_action_sprite_requires_countdown_and_direction(self) -> None:
        for direction, countdown in ((0, 1), (1, 0), (0, 0)):
            self.assertIsNone(
                frame_sprites.build_player_action_sprite(
                    first_sprite_y=0,
                    first_sprite_x=0,
                    direction=direction,
                    action_countdown=countdown,
                )
            )

    def test_sprite_dispatch_preserves_type_80_overlap_behavior(self) -> None:
        self.assertEqual(
            frame_sprites.select_object_sprite_handler(0x80, 0),
            (0, 0x6003),
        )
        self.assertIsNone(frame_sprites.select_object_sprite_handler(0, 0))

    def test_sprite_dispatch_masks_high_type_bit_and_checks_y_first(self) -> None:
        self.assertEqual(
            frame_sprites.select_object_sprite_handler(0x81, 0),
            (1, 0xADE7),
        )
        self.assertIsNone(frame_sprites.select_object_sprite_handler(0x81, 0xA0))
        with self.assertRaises(frame_sprites.FrameSpriteError):
            frame_sprites.select_object_sprite_handler(0xAF, 0)

    def test_oam_clear_and_record_scan_cover_complete_buffers(self) -> None:
        self.assertEqual(frame_sprites.clear_oam_staging(), bytes([0xF0]) * 0x100)
        records = tuple(
            frame_sprites.RuntimeObjectSprite(index + 1, index) for index in range(24)
        )
        scheduled = frame_sprites.schedule_object_sprites(records)
        self.assertEqual(
            tuple(item.record_offset for item in scheduled), tuple(range(0, 0x90, 6))
        )

    def test_rejects_invalid_machine_values_and_shapes(self) -> None:
        with self.assertRaises(frame_sprites.FrameSpriteError):
            frame_sprites.select_player_metasprite(
                transition_countdown=0x100,
                room_frame=0,
                direction=0,
                motion_state=0,
                motion_phase=0,
                action_countdown=0,
                frame_counter=0,
            )
        with self.assertRaises(frame_sprites.FrameSpriteError):
            frame_sprites.schedule_object_sprites(tuple())


if __name__ == "__main__":
    unittest.main()
