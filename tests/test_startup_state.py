from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts.validation.gameplay import startup_state


class StartupStateTests(unittest.TestCase):
    def test_cold_boot_replaces_signature_and_clears_persistent_fields(self) -> None:
        state = startup_state.ResetState(b"BAD", 0x12, 0x34, 0x56, 0x78)
        result = startup_state.apply_reset(state)
        self.assertTrue(result.cold_boot)
        self.assertEqual(
            result.state, startup_state.ResetState(b"POW", 0, 0, 1, 0)
        )

    def test_warm_reset_preserves_high_score_and_increments_counter(self) -> None:
        state = startup_state.ResetState(b"POW", 0x12, 0x34, 0x56, 0x78)
        result = startup_state.apply_reset(state)
        self.assertFalse(result.cold_boot)
        self.assertEqual(
            result.state,
            startup_state.ResetState(b"POW", 0x12, 0x34, 0x57, 0x78),
        )

    def test_reset_counter_carries_and_wraps(self) -> None:
        carried = startup_state.apply_reset(
            startup_state.ResetState(b"POW", 0, 0, 0xFF, 0x7A)
        )
        wrapped = startup_state.apply_reset(
            startup_state.ResetState(b"POW", 0, 0, 0xFF, 0xFF)
        )
        self.assertEqual((carried.state.counter_lo, carried.state.counter_hi), (0, 0x7B))
        self.assertEqual((wrapped.state.counter_lo, wrapped.state.counter_hi), (0, 0))

    def test_nmi_countdown_saturates_at_zero(self) -> None:
        self.assertEqual(startup_state.nmi_tick_frame_countdown(2), 1)
        self.assertEqual(startup_state.nmi_tick_frame_countdown(1), 0)
        self.assertEqual(startup_state.nmi_tick_frame_countdown(0), 0)
        self.assertEqual(startup_state.nmis_until_main_update(2), 2)

    def test_rejects_invalid_reset_state_widths(self) -> None:
        with self.assertRaisesRegex(startup_state.StartupStateError, "exactly 3"):
            startup_state.ResetState(b"PO", 0, 0, 0, 0)
        with self.assertRaisesRegex(startup_state.StartupStateError, "not a byte"):
            startup_state.ResetState(b"POW", 0x100, 0, 0, 0)

    def test_reads_power_signature_from_prg_address(self) -> None:
        image = bytearray(16 + 0x8000)
        image[:4] = b"NES\x1a"
        image[4] = 2
        offset = 16 + startup_state.POWER_ON_SIGNATURE_ADDRESS - 0x8000
        image[offset : offset + 5] = b"POWER"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.nes"
            path.write_bytes(image)
            self.assertEqual(startup_state.read_power_on_signature(path), b"POWER")


if __name__ == "__main__":
    unittest.main()
