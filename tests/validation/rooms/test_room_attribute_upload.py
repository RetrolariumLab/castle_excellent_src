from __future__ import annotations

import unittest

from scripts.validation.rooms import room_attribute_upload


class RoomAttributeUploadTests(unittest.TestCase):
    def test_left_upload_copies_offsets_08_through_3f(self) -> None:
        left, _ = room_attribute_upload.build_attribute_writes(range(0x80))
        self.assertEqual(left[0], 0x23C8)
        self.assertEqual(left[1], tuple(range(0x08, 0x40)))

    def test_right_upload_expands_six_rows_and_keeps_final_four(self) -> None:
        _, right = room_attribute_upload.build_attribute_writes(range(0x80))
        self.assertEqual(right[0], 0x27C8)
        self.assertEqual(right[1][:8], (0x48, 0x49, 0x4A, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B))
        self.assertEqual(right[1][-4:], (0x78, 0x79, 0x7A, 0x7B))
        self.assertEqual(len(right[1]), 52)

    def test_encoded_tasks_have_exact_contiguous_boundaries(self) -> None:
        left = room_attribute_upload.expected_left_task_bytes()
        right = room_attribute_upload.expected_right_task_bytes()
        self.assertEqual(0xE1F8 + len(left), 0xE358)
        self.assertEqual(0xE358 + len(right), 0xE45D)
        self.assertEqual(right[-8:], bytes.fromhex("A2 19 CA D0 FD 4C 88 C5"))

    def test_rejects_wrong_attribute_buffer(self) -> None:
        with self.assertRaisesRegex(room_attribute_upload.RoomAttributeUploadError, "expected 128"):
            room_attribute_upload.build_attribute_writes(range(127))


if __name__ == "__main__":
    unittest.main()
