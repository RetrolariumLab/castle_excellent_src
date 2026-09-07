from __future__ import annotations

import unittest

from scripts.validation.rooms import room_row_upload


class RoomRowUploadTests(unittest.TestCase):
    def test_handlers_are_twenty_fixed_size_consecutive_tasks(self) -> None:
        addresses = tuple(
            room_row_upload.handler_address(row)
            for row in range(room_row_upload.ROOM_HEIGHT)
        )
        self.assertEqual(addresses[0], 0xC8BC)
        self.assertEqual(addresses[-1], 0xE0B5)
        self.assertEqual(
            tuple(right - left for left, right in zip(addresses, addresses[1:])),
            (0x143,) * 19,
        )
        self.assertEqual(room_row_upload.HANDLERS_END_ADDRESS, 0xE1F8)

    def test_ppu_destinations_advance_one_nametable_row(self) -> None:
        self.assertEqual(room_row_upload.row_ppu_addresses(0), (0x20E4, 0x24E0))
        self.assertEqual(room_row_upload.row_ppu_addresses(19), (0x2344, 0x2740))

    def test_row_write_splits_fourteen_and_six_cells(self) -> None:
        cells = tuple(range(20)) * 20
        left_tiles = tuple(range(100))
        right_tiles = tuple(value + 100 for value in range(100))
        writes = room_row_upload.build_row_writes(cells, left_tiles, right_tiles, 3)
        self.assertEqual(writes[0][0], 0x2144)
        self.assertEqual(writes[1][0], 0x2540)
        self.assertEqual(writes[0][1][:4], (0, 100, 1, 101))
        self.assertEqual(writes[0][1][-2:], (13, 113))
        self.assertEqual(writes[1][1][:2], (14, 114))
        self.assertEqual(writes[1][1][-2:], (19, 119))

    def test_expected_machine_template_has_exact_boundaries(self) -> None:
        first = room_row_upload.expected_handler_bytes(0)
        last = room_row_upload.expected_handler_bytes(19)
        self.assertEqual(len(first), 0x143)
        self.assertEqual(first[:10], bytes.fromhex("A9 20 8D 06 20 A9 E4 8D 06 20"))
        self.assertEqual(last[:10], bytes.fromhex("A9 23 8D 06 20 A9 44 8D 06 20"))
        self.assertEqual(first[-3:], bytes.fromhex("4C 88 C5"))

    def test_rejects_invalid_rows_cells_and_table_shapes(self) -> None:
        cells = (0,) * 400
        table = tuple(range(100))
        with self.assertRaisesRegex(room_row_upload.RoomRowUploadError, "outside 0-19"):
            room_row_upload.handler_address(20)
        with self.assertRaisesRegex(room_row_upload.RoomRowUploadError, "expected 400"):
            room_row_upload.build_row_writes(cells[:-1], table, table, 0)
        invalid_cells = (100,) + cells[1:]
        with self.assertRaisesRegex(room_row_upload.RoomRowUploadError, "outside tile"):
            room_row_upload.build_row_writes(invalid_cells, table, table, 0)


if __name__ == "__main__":
    unittest.main()
