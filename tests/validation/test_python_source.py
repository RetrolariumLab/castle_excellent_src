from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts.validation import python_source


class PythonSourceTests(unittest.TestCase):
    def test_valid_scripts_and_tests_pass_without_writing_bytecode(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            (root / "tests").mkdir()
            (root / "scripts" / "tool.py").write_text(
                '"""Tool."""\n\nfrom __future__ import annotations\n',
                encoding="utf-8",
            )
            (root / "tests" / "test_tool.py").write_text(
                "from __future__ import annotations\n",
                encoding="utf-8",
            )
            self.assertEqual(python_source.validate_python_sources(root), [])
            self.assertFalse(list(root.rglob("*.pyc")))

    def test_syntax_docstring_and_wildcard_failures_are_reported(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / "scripts"
            scripts.mkdir()
            (root / "tests").mkdir()
            (scripts / "broken.py").write_text("if True print('x')\n", encoding="utf-8")
            (scripts / "undocumented.py").write_text(
                "from package import *\n", encoding="utf-8"
            )
            errors = python_source.validate_python_sources(root)
            self.assertTrue(any("invalid syntax" in error for error in errors))
            self.assertTrue(any("has no docstring" in error for error in errors))
            self.assertTrue(any("wildcard import" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
