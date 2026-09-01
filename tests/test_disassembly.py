from __future__ import annotations

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import format_project
import generate_disassembly as disasm


class FormattingTests(unittest.TestCase):
    def test_normalizes_line_endings_and_trailing_space(self) -> None:
        self.assertEqual(format_project.normalize_text("one  \r\ntwo\t \r\n"), "one\ntwo\n")

    def test_normalization_is_idempotent(self) -> None:
        text = "one\n\ntwo\n"
        self.assertEqual(format_project.normalize_text(text), text)


class InstructionFormattingTests(unittest.TestCase):
    def fact(
        self,
        address: int,
        raw: bytes,
        mnemonic: str,
        operands: str = "",
        flows: tuple[int, ...] = (),
    ) -> disasm.InstructionFact:
        return disasm.InstructionFact(
            address=address,
            length=len(raw),
            raw=raw,
            mnemonic=mnemonic,
            operands=operands,
            flows=flows,
            flow_type="",
            symbol="",
            function="",
        )

    def test_direct_control_transfer_uses_label(self) -> None:
        fact = self.fact(0x8000, b"\x20\x23\x81", "JSR", "0x8123", (0x8123,))
        line = disasm.format_instruction(fact, {0x8123: "Func_8123"})
        self.assertIn("JSR Func_8123", line)
        self.assertNotIn("$8123", line)

    def test_absolute_low_address_is_forced(self) -> None:
        fact = self.fact(0x8000, b"\xAD\x16\x40", "LDA", "0x4016")
        self.assertIn("LDA a:$4016", disasm.format_instruction(fact, {}))

    def test_memory_operand_uses_global_symbol(self) -> None:
        fact = self.fact(0xE7EC, b"\xAD\x02\x20", "LDA", "0x2002")
        symbols = [disasm.MemorySymbol(0x2002, "PPU_STATUS", 0x8000, 0x10000)]
        self.assertEqual(
            disasm.format_instruction(fact, {}, symbols),
            "    LDA PPU_STATUS",
        )

    def test_program_data_operand_uses_label(self) -> None:
        fact = self.fact(0xE7FE, b"\x3D\xE4\xE7", "AND", "0xE7E4,X")
        self.assertEqual(
            disasm.format_instruction(fact, {0xE7E4: "RoomBitMasks"}),
            "    AND RoomBitMasks,X",
        )

    def test_operand_override_requires_expected_original(self) -> None:
        fact = self.fact(0xE85E, b"\xA9\xE4", "LDA", "#0xE4")
        overrides = {
            0xE85E: disasm.OperandOverride("#$E4", "#>RoomCodebook", "pointer high")
        }
        self.assertEqual(
            disasm.format_instruction(fact, {}, [], overrides),
            "    LDA #>RoomCodebook",
        )
        bad = {
            0xE85E: disasm.OperandOverride("#$00", "#>RoomCodebook", "pointer high")
        }
        with self.assertRaisesRegex(disasm.DisassemblyError, "expected"):
            disasm.format_instruction(fact, {}, [], bad)

    def test_memory_operand_uses_named_absolute_address(self) -> None:
        fact = self.fact(0xE876, b"\xBD\x02\x07", "LDA", "0x0702,X")
        symbols = [
            disasm.MemorySymbol(0x0702, "RoomBitLookahead", 0x8000, 0x10000)
        ]
        self.assertEqual(
            disasm.format_instruction(fact, {}, symbols),
            "    LDA RoomBitLookahead,X",
        )

    def test_memory_operand_uses_offset_within_named_array(self) -> None:
        fact = self.fact(0xC6D3, b"\xB9\x21\x03", "LDA", "0x0321,Y")
        symbols = [
            disasm.MemorySymbol(0x0300, "OamStagingBuffer", 0x8000, 0x10000, 0x100)
        ]
        self.assertEqual(
            disasm.format_instruction(fact, {}, symbols),
            "    LDA OamStagingBuffer + $21,Y",
        )

    def test_memory_operand_preserves_forced_low_absolute_addressing(self) -> None:
        fact = self.fact(0x9000, b"\xAD\x37\x00", "LDA", "0x0037")
        symbols = [
            disasm.MemorySymbol(0x0037, "CurrentRoomNumber", 0x8000, 0x10000)
        ]
        self.assertEqual(
            disasm.format_instruction(fact, {}, symbols),
            "    LDA a:CurrentRoomNumber",
        )

    def test_contextual_memory_symbol_is_scoped_by_instruction(self) -> None:
        symbols = [
            disasm.MemorySymbol(0x0016, "RoomDecoderBitIndex", 0xE7EC, 0xE8DF)
        ]
        inside = self.fact(0xE7FA, b"\xA6\x16", "LDX", "0x16")
        outside = self.fact(0x9000, b"\xA6\x16", "LDX", "0x16")
        self.assertEqual(
            disasm.format_instruction(inside, {}, symbols),
            "    LDX RoomDecoderBitIndex",
        )
        self.assertEqual(disasm.format_instruction(outside, {}, symbols), "    LDX $16")

    def test_indirect_jump_keeps_pointer_operand(self) -> None:
        fact = self.fact(0x8000, b"\x6C\x31\x00", "JMP", "(0x31)")
        self.assertIn("JMP ($0031)", disasm.format_instruction(fact, {}))

    def test_indirect_jump_does_not_create_speculative_target_labels(self) -> None:
        fact = self.fact(
            0x8000,
            b"\x6C\x31\x00",
            "JMP",
            "(0x31)",
            (0x8123, 0xE539),
        )
        self.assertEqual(disasm.make_labels({fact.address: fact}, {}), {})

    def test_overlapping_entry_is_emitted_as_offset_symbol(self) -> None:
        prg = bytearray([0xFF] * 32_768)
        prg[0:3] = b"\xAD\x16\x40"
        prg[-6:] = bytes((0x69, 0xC5, 0x25, 0x82, 0xB8, 0xC6))
        facts = {0x8000: self.fact(0x8000, b"\xAD\x16\x40", "LDA", "0x4016")}
        labels = {
            0x8001: "Overlap_8001",
            0x8225: "Reset",
            0xC569: "Nmi",
            0xC6B8: "Irq",
            0xFFFA: "NmiVector",
            0xFFFC: "ResetVector",
            0xFFFE: "IrqVector",
        }
        source = disasm.generate(bytes(prg), facts, labels)
        self.assertIn("Overlap_8001 = * + 1", source)


if __name__ == "__main__":
    unittest.main()
