from pathlib import Path
import unittest

from scripts import unreferenced_nmi_task_index_bytes as unreferenced


ROOT = Path(__file__).resolve().parent.parent


class UnreferencedNmiTaskIndexBytesTests(unittest.TestCase):
    def test_hypothetical_shift_groups_every_eight_y_values(self) -> None:
        self.assertEqual(unreferenced.hypothetical_nmi_task_index(0), 0)
        self.assertEqual(unreferenced.hypothetical_nmi_task_index(7), 0)
        self.assertEqual(unreferenced.hypothetical_nmi_task_index(8), 1)
        self.assertEqual(unreferenced.hypothetical_nmi_task_index(0xFF), 31)

    def test_hypothetical_shift_rejects_non_byte_y(self) -> None:
        with self.assertRaises(unreferenced.UnreferencedNmiTaskBytesError):
            unreferenced.hypothetical_nmi_task_index(0x100)

    def test_reference_rom_has_no_pointer_to_sequence_start(self) -> None:
        prg = unreferenced.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        self.assertNotIn(b"\xAA\xA2", prg)

    def test_reference_contract_has_no_instruction_or_dispatch_entry(self) -> None:
        report = unreferenced.validate_contract(
            unreferenced.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes()),
            unreferenced.load_instruction_starts(ROOT / "build/ghidra/instructions.tsv"),
            unreferenced.load_code_evidence(ROOT / "config/runtime_evidence.txt"),
        )
        self.assertEqual(report["bytes"], 7)
        self.assertEqual(report["instruction_starts"], 0)
        self.assertEqual(report["hypothetical_y_values"], 256)


if __name__ == "__main__":
    unittest.main()
