from __future__ import annotations

import unittest

from scripts import room_navigation


class RoomNavigationTests(unittest.TestCase):
    def test_room_numbers_map_to_ten_by_ten_grid(self) -> None:
        self.assertEqual(room_navigation.room_position(1).row, 0)
        self.assertEqual(room_navigation.room_position(1).column, 0)
        self.assertEqual(room_navigation.room_position(100).row, 9)
        self.assertEqual(room_navigation.room_position(100).column, 9)

    def test_vertical_movement_stops_at_castle_edges(self) -> None:
        self.assertEqual(room_navigation.move_above(1), 1)
        self.assertEqual(room_navigation.move_above(11), 1)
        self.assertEqual(room_navigation.move_below(90), 100)
        self.assertEqual(room_navigation.move_below(100), 100)

    def test_horizontal_movement_stops_at_castle_edges(self) -> None:
        self.assertEqual(room_navigation.move_left(1), 1)
        self.assertEqual(room_navigation.move_left(2), 1)
        self.assertEqual(room_navigation.move_right(9), 10)
        self.assertEqual(room_navigation.move_right(10), 10)

    def test_edge_tables_cover_each_row(self) -> None:
        self.assertEqual(room_navigation.RIGHTMOST_ROOMS, tuple(range(10, 101, 10)))
        self.assertEqual(room_navigation.LEFTMOST_ROOMS, tuple(range(1, 100, 10)))

    def test_edge_search_returns_row_or_ff(self) -> None:
        self.assertEqual(
            room_navigation.descending_edge_search(
                100, room_navigation.RIGHTMOST_ROOMS
            ),
            9,
        )
        self.assertEqual(
            room_navigation.descending_edge_search(1, room_navigation.LEFTMOST_ROOMS),
            0,
        )
        self.assertEqual(
            room_navigation.descending_edge_search(55, room_navigation.LEFTMOST_ROOMS),
            0xFF,
        )

    def test_corner_neighbors_match_one_based_layout(self) -> None:
        self.assertEqual(
            room_navigation.room_neighbors(1),
            room_navigation.RoomNeighbors(above=1, below=11, left=1, right=2),
        )
        self.assertEqual(
            room_navigation.room_neighbors(100),
            room_navigation.RoomNeighbors(above=90, below=100, left=99, right=100),
        )

    def test_rejects_rooms_outside_one_based_domain(self) -> None:
        for room_number in (0, 101):
            with self.assertRaises(room_navigation.RoomNavigationError):
                room_navigation.room_neighbors(room_number)

    def test_exhaustive_navigation_contract(self) -> None:
        document = room_navigation.validate_exhaustive_contract()
        self.assertEqual(document["rooms"], 100)
        self.assertEqual(document["edge_search_values"], 256)


if __name__ == "__main__":
    unittest.main()
