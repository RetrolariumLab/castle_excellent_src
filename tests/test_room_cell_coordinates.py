from __future__ import annotations

import unittest

from scripts import room_cell_coordinates as cells


class RoomCellCoordinateTests(unittest.TestCase):
    def test_pixel_to_tile_reproduces_sixteen_bit_x_shift(self) -> None:
        self.assertEqual(cells.pixel_to_tile(0x013F, 0x9F), (0x27, 0x13))
        self.assertEqual(cells.pixel_to_tile(0x07FF, 0xFF), (0xFF, 0x1F))
        self.assertEqual(cells.pixel_to_tile(0x0800, 0), (0, 0))

    def test_two_horizontal_tiles_share_each_room_cell(self) -> None:
        self.assertEqual(cells.room_cell_offset(0, 0), 0)
        self.assertEqual(cells.room_cell_offset(1, 0), 0)
        self.assertEqual(cells.room_cell_offset(2, 0), 1)
        self.assertEqual(cells.room_cell_offset(39, 19), 399)

    def test_pointer_helper_recovers_every_room_row(self) -> None:
        for offset in range(cells.ROOM_CELL_COUNT):
            address = cells.ROOM_CELLS_BASE + offset
            self.assertEqual(cells.room_cell_row_from_address(address), offset // 20)

    def test_row_update_helpers_select_current_and_successor_tasks(self) -> None:
        self.assertEqual(
            cells.room_cell_update_tasks(0x0400, include_next_row=False), (1,)
        )
        self.assertEqual(
            cells.room_cell_update_tasks(0x04A0, include_next_row=True), (9, 10)
        )
        self.assertEqual(
            cells.room_cell_update_tasks(0x058F, include_next_row=True), (20, 21)
        )

    def test_lookup_returns_one_based_anchor_ordinal(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        room[3] = 0x19
        room[24] = 0x54
        room[87] = 0x25
        self.assertEqual(cells.find_mutable_ordinal(room, 8, 1), 2)
        self.assertEqual(cells.find_mutable_ordinal(room, 14, 4), 3)

    def test_lookup_moves_from_lower_and_right_cells_to_row_above(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        room[22] = 0x62
        room[42] = 0x63
        self.assertEqual(cells.find_mutable_ordinal(room, 4, 2), 1)
        room[42] = 0x1A
        self.assertEqual(cells.find_mutable_ordinal(room, 4, 2), 1)

    def test_lookup_rejects_non_mutable_cells(self) -> None:
        room = bytes(cells.ROOM_CELL_COUNT)
        self.assertIsNone(cells.find_mutable_ordinal(room, 0, 0))

    def test_standard_restoration_writes_anchor_and_lower_cell(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        room[42] = 0x1F
        restored_room, result = cells.restore_mutable_cell(room, 1)
        self.assertIsNotNone(result)
        assert result is not None
        self.assertEqual(restored_room[42], 0x54)
        self.assertEqual(restored_room[62], 0x55)
        self.assertEqual((result.state_byte_index, result.state_bit_mask), (0, 1))

    def test_type_16_neighbor_selects_alternate_restoration(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        room[41] = 0x16
        room[42] = 0x22
        restored_room, result = cells.restore_mutable_cell(room, 1)
        self.assertIsNotNone(result)
        assert result is not None
        self.assertEqual(restored_room[42], 0x62)
        self.assertEqual(restored_room[62], 0x63)
        self.assertEqual((result.anchor_cell, result.lower_cell), (0x62, 0x63))

    def test_restoration_uses_original_one_based_ordinal_for_state_bit(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        for offset in range(21, 31):
            room[offset] = 0x19
        _, result = cells.restore_mutable_cell(room, 10)
        self.assertIsNotNone(result)
        assert result is not None
        self.assertEqual(result.offset, 30)
        self.assertEqual((result.state_byte_index, result.state_bit_mask), (1, 2))

    def test_restoration_returns_none_when_ordinal_is_absent(self) -> None:
        room = bytearray(cells.ROOM_CELL_COUNT)
        room[42] = 0x19
        unchanged, result = cells.restore_mutable_cell(room, 2)
        self.assertEqual(unchanged, bytes(room))
        self.assertIsNone(result)

    def test_rejects_coordinates_and_room_shapes_outside_contract(self) -> None:
        with self.assertRaises(cells.RoomCellError):
            cells.room_cell_offset(40, 0)
        with self.assertRaises(cells.RoomCellError):
            cells.find_mutable_ordinal(bytes(399), 0, 0)
        with self.assertRaises(cells.RoomCellError):
            cells.restore_mutable_cell(bytes(400), 0)
        with self.assertRaises(cells.RoomCellError):
            cells.room_cell_row_from_address(0x03FF)


if __name__ == "__main__":
    unittest.main()
