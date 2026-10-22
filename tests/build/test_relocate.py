from __future__ import annotations

from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "build"))

import relocate  # noqa: E402

MAIN = """.segment "HEADER"
.include "memory/ram.inc"
.segment "PRG"

PrgStart:
.include "system/famicom_platform.asm"
.include "game/a.asm"
.include "system/prg_tail.asm"

.include "graphics/chr.asm"
"""


class RelocateTests(unittest.TestCase):
    def relocated(self, main: str) -> tuple[list[str], int]:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "main.asm"
            source.write_text(main, encoding="utf-8")
            return relocate.relocated_main(source, Path(directory) / "out" / "main.asm")

    def test_origin_and_every_module_but_the_tail_get_a_byte(self) -> None:
        lines, inserted = self.relocated(MAIN)
        self.assertEqual(3, inserted)
        probes = [lines[i - 1] for i, line in enumerate(lines) if line == relocate.EA_DIRECTIVE]
        self.assertEqual(["PrgStart:"], probes[:1])
        self.assertTrue(probes[1].endswith('famicom_platform.asm"'))
        self.assertTrue(probes[2].endswith('game/a.asm"'))
        # Nothing between the tail and the CHR, and nothing in the header.
        tail = next(i for i, line in enumerate(lines) if line.endswith('prg_tail.asm"'))
        self.assertNotIn(relocate.EA_DIRECTIVE, lines[tail:])
        self.assertNotIn(relocate.EA_DIRECTIVE, lines[:lines.index("PrgStart:")])

    def test_a_main_of_another_shape_is_refused(self) -> None:
        for broken in (MAIN.replace("PrgStart:\n", ""),
                       MAIN.replace('.include "system/famicom_platform.asm"\n', ""),
                       MAIN.replace('.include "graphics/chr.asm"\n', ""),
                       MAIN + '.include "game/b.asm"\n'):
            with self.assertRaises(relocate.RelocationError):
                self.relocated(broken)

    def test_the_relocated_entry_includes_the_relocated_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "castlequest-usa"
            inserted = relocate.relocate(ROOT / "src" / "revisions" / "castlequest-usa.asm", output)
            entry = (output / "castlequest-usa.asm").read_text(encoding="utf-8")
            main = (output / "main.asm").read_text(encoding="utf-8")
            self.assertIn('.include "main.asm"', entry)
            self.assertIn("CASTLEQUEST_USA = 1", entry)
            self.assertEqual(inserted, main.count(relocate.EA_DIRECTIVE))
            for path in re.findall(r'\.include "([^"]+)"', main):
                self.assertTrue((output / path).is_file(), path)


if __name__ == "__main__":
    unittest.main()
