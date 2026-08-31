from __future__ import annotations

from pathlib import Path
import unittest

from scripts.source_reconstruction import audit_module_text


class SemanticModuleAuditTests(unittest.TestCase):
    def test_named_source_passes(self) -> None:
        source = "DecodeRoom:\n    LDA RoomPointerTable,X\n    BNE DecodeRoom\n"
        self.assertEqual(audit_module_text(Path("src/game/rooms.asm"), source), [])

    def test_generic_label_is_rejected(self) -> None:
        source = "Label_E844:\n    RTS\n"
        issues = audit_module_text(Path("src/game/rooms.asm"), source)
        self.assertIn("generic label", issues[0])

    def test_raw_address_operand_is_rejected_but_immediate_is_allowed(self) -> None:
        source = "RoomLoop:\n    LDA $21\n    CMP #$43\n"
        issues = audit_module_text(Path("src/game/rooms.asm"), source)
        self.assertEqual(len(issues), 1)
        self.assertIn("raw address operand", issues[0])


if __name__ == "__main__":
    unittest.main()
