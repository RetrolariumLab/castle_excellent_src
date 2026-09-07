from __future__ import annotations

from pathlib import Path
import json
import tempfile
import unittest

from scripts.validation.source_reconstruction import (
    ReconstructionError,
    audit_module_text,
    audit_symbol_maps,
)


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

    def test_named_array_offset_is_allowed(self) -> None:
        source = "CopyOam:\n    LDA OamStagingBuffer + $21,Y\n"
        self.assertEqual(audit_module_text(Path("src/rendering/oam.asm"), source), [])

    def test_symbol_maps_require_metadata_and_source_ownership(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            symbols = root / "symbols.json"
            memory = root / "memory.json"
            layout = root / "layout.json"
            symbols.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "symbols": [
                            {
                                "address": "0x8000",
                                "name": "Reset",
                                "kind": "routine",
                                "confidence": "confirmed",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            memory.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "symbols": [
                            {"address": "0x0000", "name": "FrameCounter"}
                        ],
                    }
                ),
                encoding="utf-8",
            )
            layout.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "files": [
                            {
                                "path": "src/main.asm",
                                "start": "0x8000",
                                "end": "0x10000",
                                "title": "test",
                                "segment": "PRG",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            self.assertEqual(
                audit_symbol_maps(symbols, memory, layout),
                (1, 1, 1, 0),
            )
            document = json.loads(symbols.read_text(encoding="utf-8"))
            document["symbols"][0]["kind"] = "unknown"
            symbols.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaises(ReconstructionError):
                audit_symbol_maps(symbols, memory, layout)


if __name__ == "__main__":
    unittest.main()
