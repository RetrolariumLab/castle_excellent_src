from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "build"))

import relocate  # noqa: E402


class RelocateTests(unittest.TestCase):
    def test_every_module_moves_and_the_tail_stays_last(self) -> None:
        # Beside the repository: the copy names the sources by relative paths.
        (ROOT / "build").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / "build") as directory:
            output = Path(directory) / "source" / "main.asm"
            inserted = relocate.relocate(ROOT / "src" / "main.asm", output)
            platform = (output.parent / "famicom_platform.asm").read_text(encoding="utf-8").splitlines()
        includes = [line for line in platform if line.lstrip().startswith(".include")]
        # One byte at PrgStart and one after every module but the tail, which
        # the tile-table padding must still follow.
        self.assertEqual(len(includes), inserted)
        self.assertTrue(includes[-1].endswith('prg_tail.asm"'))
        self.assertEqual(relocate.EA_DIRECTIVE, platform[platform.index("PrgStart:") + 1])

    def test_a_platform_without_its_origin_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "system").mkdir()
            (root / "main.asm").write_text('.include "system/famicom_platform.asm"\n', encoding="utf-8")
            (root / "system" / "famicom_platform.asm").write_text("; no origin\n", encoding="utf-8")
            with self.assertRaises(relocate.RelocationError):
                relocate.relocate(root / "main.asm", root / "out" / "main.asm")


if __name__ == "__main__":
    unittest.main()
