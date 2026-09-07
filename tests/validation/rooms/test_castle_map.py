from __future__ import annotations

import unittest

from scripts.validation.rooms import castle_map


class CastleMapTests(unittest.TestCase):
    def test_room_coordinates_cover_ten_by_ten_grid(self) -> None:
        self.assertEqual(castle_map.room_coordinates(0), (0, 0))
        self.assertEqual(castle_map.room_coordinates(47), (4, 7))
        self.assertEqual(castle_map.room_coordinates(99), (9, 9))

    def test_visited_markers_use_two_by_two_tiles(self) -> None:
        self.assertEqual(castle_map.visited_room_marker(0), (0x20C6, 0x20E6, (7, 8, 9, 10)))
        self.assertEqual(castle_map.visited_room_marker(99)[:2], (0x2318, 0x2338))

    def test_current_room_sprite_uses_one_based_room_number(self) -> None:
        self.assertEqual(castle_map.current_room_sprite(1), (0x33, 0xF0, 0, 0x34))
        self.assertEqual(castle_map.current_room_sprite(100), (0xC3, 0xF0, 0, 0xC4))

    def test_rejects_rooms_outside_domain(self) -> None:
        with self.assertRaises(castle_map.CastleMapError):
            castle_map.room_coordinates(100)
        with self.assertRaises(castle_map.CastleMapError):
            castle_map.current_room_sprite(0)


if __name__ == "__main__":
    unittest.main()
