from pathlib import Path
import unittest

from scripts.validation.audio import audio_track_selection as selection


ROOT = Path(__file__).resolve().parent.parent


class AudioTrackSelectionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.prg = selection.extract_prg(
            (ROOT / "Castle Excellent (J).nes").read_bytes()
        )
        cls.records = selection.parse_track_records(cls.prg)

    def test_seven_selectors_use_record_offsets_and_omit_set_six(self) -> None:
        self.assertEqual(
            selection.SELECTOR_RECORD_OFFSETS,
            {0: 0x00, 1: 0x08, 2: 0x10, 3: 0x18, 4: 0x20, 5: 0x28, 7: 0x38},
        )
        with self.assertRaisesRegex(
            selection.AudioTrackSelectionError, "has no selector"
        ):
            selection.selector_record_offset(6, 0)

    def test_track_five_bypasses_demo_guard(self) -> None:
        self.assertIsNotNone(selection.select_track_set(self.records, 5, 0xFF))
        for track_set in selection.DEMO_GUARDED_TRACK_SETS:
            self.assertIsNone(
                selection.select_track_set(self.records, track_set, 0xFF)
            )

    def test_record_six_has_exact_ram_copy_with_null_pulse_one(self) -> None:
        self.assertEqual(
            selection.track_record_ram_writes(self.records[6]),
            {
                0xDB: 0x00,
                0xDC: 0x00,
                0xDD: 0x01,
                0xDF: 0x58,
                0xE0: 0xC1,
                0xE1: 0x01,
                0xE3: 0x58,
                0xE4: 0xC1,
                0xE5: 0x01,
                0xE7: 0x02,
                0xE8: 0x02,
            },
        )

    def test_reference_rom_has_eight_records_and_23_valid_pointers(self) -> None:
        report = selection.validate_rom_contract(self.prg)
        self.assertEqual(report["selector_bytes"], 81)
        self.assertEqual(report["track_records"], 8)
        self.assertEqual(report["pointer_slots"], 24)
        self.assertEqual(report["valid_nonzero_pointers"], 23)
        self.assertEqual(report["call_sites"], 11)

    def test_exhaustive_demo_gate_and_ram_copy_contract(self) -> None:
        report = selection.validate_exhaustive_contract(self.records)
        self.assertEqual(report["demo_gate_cases"], 1_792)
        self.assertEqual(report["loaded_cases"], 262)
        self.assertEqual(report["suppressed_cases"], 1_530)
        self.assertEqual(report["record_copies"], 8)


if __name__ == "__main__":
    unittest.main()
