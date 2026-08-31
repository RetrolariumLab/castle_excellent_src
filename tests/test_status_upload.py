from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts import status_upload


class StatusUploadTests(unittest.TestCase):
    def test_builds_all_three_ppu_writes_in_handler_order(self) -> None:
        writes = status_upload.build_status_writes(range(5), range(6), range(3))
        self.assertEqual(
            writes,
            (
                (0x2096, (0, 1, 2, 3, 4)),
                (0x2087, (0, 1, 5, 4, 3, 2)),
                (0x20A8, (1, 0)),
            ),
        )

    def test_rejects_wrong_buffer_shapes_and_non_bytes(self) -> None:
        with self.assertRaisesRegex(status_upload.StatusUploadError, "expected 5"):
            status_upload.build_status_writes(range(4), range(6), range(3))
        with self.assertRaisesRegex(status_upload.StatusUploadError, "outside byte"):
            status_upload.build_status_writes(range(5), (0, 1, 2, 3, 4, 256), range(3))

    def test_reads_status_and_fallback_handlers_from_split_tables(self) -> None:
        image = bytearray(16 + 0x8000)
        image[:4] = b"NES\x1a"
        image[4] = 2
        high_offset = 16 + status_upload.NMI_HANDLER_HIGH_ADDRESS - 0x8000
        low_offset = 16 + status_upload.NMI_HANDLER_LOW_ADDRESS - 0x8000
        image[high_offset : high_offset + 23] = bytes([0xC8] * 23)
        image[low_offset : low_offset + 23] = bytes([0x04, 0xBC] + [0] * 21)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.nes"
            path.write_bytes(image)
            self.assertEqual(status_upload.read_first_handler_pair(path), (0xC804, 0xC8BC))


if __name__ == "__main__":
    unittest.main()
