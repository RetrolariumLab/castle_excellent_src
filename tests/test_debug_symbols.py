from __future__ import annotations

import unittest
from pathlib import Path
import tempfile

from scripts import debug_symbols, validate_debug_runtime


class DebugSymbolsTests(unittest.TestCase):
    def test_parse_record_preserves_quoted_commas_and_quotes(self) -> None:
        kind, fields = debug_symbols.parse_record(
            'file\tid=2,name="src/a,b""c.asm"\n'
        )
        self.assertEqual(kind, "file")
        self.assertEqual(fields, {"id": "2", "name": 'src/a,b"c.asm'})

    def test_preferred_ram_symbol_wins_an_address_alias(self) -> None:
        selected = debug_symbols.choose_unique_addresses(
            [(0x000B, "AwardPlayerScoreLo"), (0x000B, "PlayerScoreLo")],
            {"PlayerScoreLo"},
        )
        self.assertEqual(selected, [(0x000B, "PlayerScoreLo")])

    def test_config_symbol_resolves_to_its_fixed_address(self) -> None:
        resolved = debug_symbols.resolve_config(
            [{"address": "0xC569", "name": "Nmi"}],
            {"Nmi": 0xC569},
            Path("breakpoints.json"),
        )
        self.assertEqual(resolved[0]["resolved_address"], 0xC569)
        self.assertEqual(resolved[0]["resolved_address_hex"], "$C569")

    def test_stale_config_address_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "stale debugger address"):
            debug_symbols.resolve_config(
                [{"address": "0xC568", "name": "Nmi"}],
                {"Nmi": 0xC569},
                Path("breakpoints.json"),
            )

    def test_debug_file_coverage_requires_a_line_for_every_module(self) -> None:
        records = [
            ("file", {"id": "0", "name": "src/game/rooms/load.asm"}),
            ("file", {"id": "1", "name": "src/audio/music.asm"}),
            ("line", {"id": "0", "file": "0", "line": "1"}),
            ("line", {"id": "1", "file": "1", "line": "1"}),
        ]
        debug_symbols.validate_debug_file_coverage(
            records, {"src/game/rooms/load.asm", "src/audio/music.asm"}
        )
        with self.assertRaisesRegex(ValueError, "src/system/startup.asm"):
            debug_symbols.validate_debug_file_coverage(
                records,
                {"src/game/rooms/load.asm", "src/system/startup.asm"},
            )

    def test_live_result_requires_all_symbols_and_named_breakpoint(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "debug-symbols.txt"
            lines = [
                f"symbol,{name},{address:04X},{address:04X}"
                for name, address in validate_debug_runtime.EXPECTED_SYMBOLS.items()
            ]
            lines.extend(("break,MainFrameLoop,8282,7", "OK"))
            result.write_text("\n".join(lines) + "\n", encoding="utf-8")
            self.assertEqual(validate_debug_runtime.validate_result(result), (7, 7))


if __name__ == "__main__":
    unittest.main()
