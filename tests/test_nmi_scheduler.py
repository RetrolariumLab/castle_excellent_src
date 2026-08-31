from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts import nmi_scheduler


class NmiSchedulerTests(unittest.TestCase):
    def test_clears_current_request_and_selects_next_pending_task(self) -> None:
        requests = [0] * nmi_scheduler.NMI_TASK_COUNT
        requests[3] = 0xFF
        requests[9] = 1
        updated, selected = nmi_scheduler.advance_task_scheduler(requests, 3)
        self.assertEqual(updated[3], 0)
        self.assertEqual(selected, 9)

    def test_wraps_to_task_zero_when_no_later_request_is_pending(self) -> None:
        requests = [0] * nmi_scheduler.NMI_TASK_COUNT
        self.assertEqual(nmi_scheduler.advance_task_scheduler(requests, 8)[1], 0)
        self.assertEqual(nmi_scheduler.advance_task_scheduler(requests, 22)[1], 0)

    def test_modular_frame_counters_wrap_at_their_individual_periods(self) -> None:
        before_wrap = tuple(period - 1 for period in nmi_scheduler.FRAME_COUNTER_PERIODS)
        self.assertEqual(nmi_scheduler.tick_frame_counters(before_wrap), (0,) * 8)
        self.assertEqual(nmi_scheduler.tick_frame_counters((0,) * 8), (1,) * 8)

    def test_rejects_invalid_request_and_counter_shapes(self) -> None:
        with self.assertRaisesRegex(nmi_scheduler.NmiSchedulerError, "expected 23"):
            nmi_scheduler.advance_task_scheduler([0] * 22, 0)
        with self.assertRaisesRegex(nmi_scheduler.NmiSchedulerError, "expected 8"):
            nmi_scheduler.tick_frame_counters((0,) * 7)

    def test_reads_high_then_low_handler_tables(self) -> None:
        image = bytearray(16 + 0x8000)
        image[:4] = b"NES\x1a"
        image[4] = 2
        high_offset = 16 + nmi_scheduler.NMI_HANDLER_HIGH_ADDRESS - 0x8000
        low_offset = 16 + nmi_scheduler.NMI_HANDLER_LOW_ADDRESS - 0x8000
        image[high_offset : high_offset + 23] = bytes([0xC8] * 23)
        image[low_offset : low_offset + 23] = bytes(range(23))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.nes"
            path.write_bytes(image)
            handlers = nmi_scheduler.read_handler_table(path)
        self.assertEqual(handlers[0], 0xC800)
        self.assertEqual(handlers[-1], 0xC816)

    def test_expected_handlers_cover_status_room_rows_and_attributes(self) -> None:
        handlers = nmi_scheduler.EXPECTED_TASK_HANDLERS
        self.assertEqual(len(handlers), 23)
        self.assertEqual(handlers[0], 0xC804)
        self.assertEqual(handlers[1:21], tuple(0xC8BC + row * 0x143 for row in range(20)))
        self.assertEqual(handlers[21:], (0xE1F8, 0xE358))


if __name__ == "__main__":
    unittest.main()
