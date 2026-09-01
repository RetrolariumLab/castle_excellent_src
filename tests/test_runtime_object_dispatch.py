from __future__ import annotations

import unittest

from scripts import runtime_object_dispatch


class RuntimeObjectDispatchTests(unittest.TestCase):
    def test_table_has_one_pointer_for_each_masked_type_index(self) -> None:
        self.assertEqual(
            len(runtime_object_dispatch.EXPECTED_HANDLER_POINTERS),
            runtime_object_dispatch.HANDLER_COUNT,
        )
        self.assertTrue(
            all(
                0x8000 <= pointer <= 0xFFFF
                for pointer in runtime_object_dispatch.EXPECTED_HANDLER_POINTERS
            )
        )

    def test_high_bit_is_removed_before_handler_lookup(self) -> None:
        plain = runtime_object_dispatch.dispatch_handler(0x21, 0)
        active = runtime_object_dispatch.dispatch_handler(0xA1, 0)
        self.assertEqual(plain, active)
        self.assertEqual(active, (0x21, 0x9796))

    def test_inactive_and_offscreen_records_are_skipped(self) -> None:
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x00, 0))
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x80, 0))
        self.assertIsNone(runtime_object_dispatch.dispatch_handler(0x81, 0xA0))

    def test_scheduler_visits_every_six_byte_record(self) -> None:
        records = tuple(
            runtime_object_dispatch.RuntimeObject(0x81, 0)
            for _ in range(runtime_object_dispatch.RECORD_COUNT)
        )
        scheduled = runtime_object_dispatch.schedule_runtime_objects(records)
        self.assertEqual(
            [update.record_offset for update in scheduled],
            list(range(0, 0x90, 6)),
        )

    def test_rejects_type_index_past_the_42_entry_table(self) -> None:
        with self.assertRaises(runtime_object_dispatch.RuntimeObjectDispatchError):
            runtime_object_dispatch.dispatch_handler(0xAA, 0)


if __name__ == "__main__":
    unittest.main()
