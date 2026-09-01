from __future__ import annotations

import unittest

from scripts import room_cell_animation


class RoomCellAnimationTests(unittest.TestCase):
    def test_fast_families_rotate_in_opposite_directions(self) -> None:
        for group in range(0, len(room_cell_animation.DECREMENTING_FRAMES), 4):
            first = room_cell_animation.DECREMENTING_FIRST + group
            values = list(range(first, first + 4))
            advanced = [room_cell_animation.advance_fast_cell(value)[0] for value in values]
            self.assertEqual(advanced, values[-1:] + values[:-1])
        for group in range(0, len(room_cell_animation.INCREMENTING_FRAMES), 4):
            first = room_cell_animation.INCREMENTING_FIRST + group
            values = list(range(first, first + 4))
            advanced = [room_cell_animation.advance_fast_cell(value)[0] for value in values]
            self.assertEqual(advanced, values[1:] + values[:1])

    def test_slow_family_rotates_forward(self) -> None:
        advanced = [
            room_cell_animation.advance_slow_cell(value)[0]
            for value in range(
                room_cell_animation.SLOW_FIRST,
                room_cell_animation.SLOW_FIRST + len(room_cell_animation.SLOW_FRAMES),
            )
        ]
        self.assertEqual(advanced, [0x46, 0x47, 0x48, 0x45])

    def test_even_room_frame_changes_nothing(self) -> None:
        room = bytearray(room_cell_animation.ROOM_CELL_COUNT)
        room[0:3] = bytes((0x35, 0x45, 0x56))
        result = room_cell_animation.animate_room_cells(room, 2, 0x7F)
        self.assertEqual(result.cells, bytes(room))
        self.assertEqual(result.slow_counter, 0x7F)
        self.assertEqual(result.requested_rows, ())

    def test_odd_room_frame_always_runs_fast_scan(self) -> None:
        room = bytearray(room_cell_animation.ROOM_CELL_COUNT)
        room[0:3] = bytes((0x35, 0x39, 0x56))
        result = room_cell_animation.animate_room_cells(room, 1, 0)
        self.assertEqual(result.cells[0:3], bytes((0x38, 0x3C, 0x57)))
        self.assertEqual(result.slow_counter, 1)
        self.assertEqual(result.requested_rows, (0,))

    def test_slow_scan_uses_incremented_counter_and_signed_pause(self) -> None:
        room = bytearray(room_cell_animation.ROOM_CELL_COUNT)
        room[20] = room_cell_animation.SLOW_FIRST
        active = room_cell_animation.animate_room_cells(room, 1, 3)
        self.assertEqual(active.cells[20], 0x46)
        self.assertEqual(active.slow_counter, 4)
        self.assertEqual(active.requested_rows, (1,))

        paused = room_cell_animation.animate_room_cells(room, 1, 0x7F)
        self.assertEqual(paused.cells[20], room_cell_animation.SLOW_FIRST)
        self.assertEqual(paused.slow_counter, 0x80)

        wrapped = room_cell_animation.animate_room_cells(room, 1, 0xFF)
        self.assertEqual(wrapped.cells[20], 0x46)
        self.assertEqual(wrapped.slow_counter, 0)

    def test_only_anchor_groups_request_fast_row_uploads(self) -> None:
        room = bytearray(room_cell_animation.ROOM_CELL_COUNT)
        for row, value in enumerate((0x35, 0x39, 0x3D, 0x56, 0x5A, 0x5E)):
            room[row * room_cell_animation.ROOM_WIDTH] = value
        result = room_cell_animation.animate_room_cells(room, 1, 0)
        self.assertEqual(result.requested_rows, (0, 3))

    def test_rejects_wrong_room_or_non_byte_counters(self) -> None:
        with self.assertRaises(room_cell_animation.RoomCellAnimationError):
            room_cell_animation.animate_room_cells(bytes(399), 1, 0)
        with self.assertRaises(room_cell_animation.RoomCellAnimationError):
            room_cell_animation.animate_room_cells(bytes(400), 0x100, 0)
        with self.assertRaises(room_cell_animation.RoomCellAnimationError):
            room_cell_animation.advance_fast_cell(-1)


if __name__ == "__main__":
    unittest.main()
