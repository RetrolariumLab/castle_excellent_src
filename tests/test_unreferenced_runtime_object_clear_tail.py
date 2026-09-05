from pathlib import Path
import unittest

from scripts import unreferenced_runtime_object_clear_tail as unreferenced


ROOT = Path(__file__).resolve().parent.parent


class UnreferencedRuntimeObjectClearTailTests(unittest.TestCase):
    def test_hypothetical_decode_loads_current_offset_and_clears_object(self) -> None:
        decoded = unreferenced.hypothetical_decode(unreferenced.EXPECTED_BYTES)
        self.assertEqual(decoded["object_offset_address"], 0x41)
        self.assertEqual(decoded["jump_target"], 0xA024)

    def test_hypothetical_decode_rejects_changed_bytes(self) -> None:
        with self.assertRaises(unreferenced.UnreferencedRuntimeObjectClearTailError):
            unreferenced.hypothetical_decode(b"\xA6\x41\x4C\x25\xA0")

    def test_reference_rom_has_no_pointer_into_sequence(self) -> None:
        prg = unreferenced.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes())
        self.assertEqual(unreferenced._pointer_hits(prg), [])

    def test_reference_contract_has_no_code_or_pointer_entry(self) -> None:
        report = unreferenced.validate_contract(
            unreferenced.extract_prg((ROOT / "Castle Excellent (J).nes").read_bytes()),
            unreferenced.load_instruction_starts(ROOT / "build/ghidra/instructions.tsv"),
            unreferenced.load_code_evidence(ROOT / "config/runtime_evidence.txt"),
        )
        self.assertEqual(report["bytes"], 5)
        self.assertEqual(report["instruction_starts"], 0)
        self.assertEqual(report["pointer_hits"], 0)


if __name__ == "__main__":
    unittest.main()
