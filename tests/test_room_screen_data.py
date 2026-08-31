from __future__ import annotations

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import room_screen_data


def make_screen_prg() -> bytes:
    prg = bytearray(room_screen_data.PRG_SIZE)
    for _name, _ppu, start, limit in room_screen_data.STATUS_TILE_STREAMS:
        offset = room_screen_data.cpu_offset(start)
        size = limit - start
        prg[offset:offset + size - 1] = bytes([0xFF]) * (size - 1)
        prg[offset + size - 1] = 0
    for high_instruction, low_instruction, target in room_screen_data.STATUS_POINTER_LOADS:
        high = room_screen_data.cpu_offset(high_instruction)
        low = room_screen_data.cpu_offset(low_instruction)
        prg[high:high + 2] = bytes((0xA9, target >> 8))
        prg[low:low + 2] = bytes((0xA9, target & 0xFF))
    return bytes(prg)


class RoomScreenDataTests(unittest.TestCase):
    def test_analyzes_contiguous_status_data(self) -> None:
        result = room_screen_data.analyze_room_screen(make_screen_prg())
        self.assertEqual(len(result["status_streams"]), 4)
        self.assertEqual(result["status_tile_count"], 45)
        self.assertEqual(len(result["initial_attributes"]), 16)

    def test_rejects_bytes_after_stream_terminator(self) -> None:
        prg = bytearray(make_screen_prg())
        offset = room_screen_data.cpu_offset(0xB77D)
        prg[offset] = 0
        with self.assertRaisesRegex(
            room_screen_data.RoomScreenDataError, "leave bytes after"
        ):
            room_screen_data.analyze_room_screen(bytes(prg))

    def test_rejects_pointer_load_mismatch(self) -> None:
        prg = bytearray(make_screen_prg())
        operand = room_screen_data.cpu_offset(0xB6DC) + 1
        prg[operand] ^= 1
        with self.assertRaisesRegex(
            room_screen_data.RoomScreenDataError, r"expected \$B77C"
        ):
            room_screen_data.analyze_room_screen(bytes(prg))


if __name__ == "__main__":
    unittest.main()
