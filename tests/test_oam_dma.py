from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts import oam_dma


def sprite_ids() -> bytes:
    return bytes(value for sprite in range(64) for value in (sprite,) * 4)


class OamDmaTests(unittest.TestCase):
    def test_frame_zero_transposes_eight_by_eight_sprite_groups(self) -> None:
        output = oam_dma.build_dma_oam(
            sprite_ids(), 0, oam_dma.EXPECTED_ROTATION_OFFSETS
        )
        expected = tuple(block + row * 8 for block in range(8) for row in range(8))
        self.assertEqual(tuple(output[::4]), expected)

    def test_frame_rotation_wraps_columns_across_eight_frames(self) -> None:
        frame_seven = oam_dma.build_dma_oam(
            sprite_ids(), 7, oam_dma.EXPECTED_ROTATION_OFFSETS
        )
        frame_fifteen = oam_dma.build_dma_oam(
            sprite_ids(), 15, oam_dma.EXPECTED_ROTATION_OFFSETS
        )
        self.assertEqual(frame_seven, frame_fifteen)
        self.assertEqual(tuple(frame_seven[::4])[:8], (7, 15, 23, 31, 39, 47, 55, 63))

    def test_reverse_operates_on_whole_four_byte_sprite_records(self) -> None:
        reversed_oam = oam_dma.reverse_dma_oam(sprite_ids())
        self.assertEqual(tuple(reversed_oam[::4]), tuple(reversed(range(64))))
        self.assertEqual(oam_dma.reverse_dma_oam(reversed_oam), sprite_ids())

    def test_rejects_invalid_buffers_and_rotation_offsets(self) -> None:
        with self.assertRaisesRegex(oam_dma.OamDmaError, "expected 256"):
            oam_dma.build_dma_oam(bytes(255), 0, oam_dma.EXPECTED_ROTATION_OFFSETS)
        invalid_offsets = (0,) * 14 + (2,)
        with self.assertRaisesRegex(oam_dma.OamDmaError, "invalid OAM rotation"):
            oam_dma.build_dma_oam(bytes(256), 7, invalid_offsets)

    def test_reads_all_sixteen_physical_table_bytes(self) -> None:
        image = bytearray(16 + 0x8000)
        image[:4] = b"NES\x1a"
        image[4] = 2
        offset = 16 + oam_dma.OAM_ROTATION_TABLE_ADDRESS - 0x8000
        image[offset : offset + 16] = bytes(oam_dma.EXPECTED_ROTATION_OFFSETS)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.nes"
            path.write_bytes(image)
            self.assertEqual(
                oam_dma.read_rotation_offsets(path), oam_dma.EXPECTED_ROTATION_OFFSETS
            )


if __name__ == "__main__":
    unittest.main()
