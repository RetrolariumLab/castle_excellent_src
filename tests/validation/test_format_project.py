from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts.validation import format_project


class FormatProjectInventoryTests(unittest.TestCase):
    def test_parent_build_directory_does_not_hide_repository_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "build" / "project"
            root.mkdir(parents=True)
            readme = root / "README.md"
            readme.write_text("# Project\n", encoding="utf-8")

            self.assertEqual(format_project.project_files(root), [readme])

    def test_source_build_packages_are_not_generated_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "project"
            source_tool = root / "scripts/build/tool.py"
            source_test = root / "tests/build/test_tool.py"
            generated = root / "build/generated.txt"
            private_workspace = root / "content/workspace/levels.json"
            for path in (source_tool, source_test, generated, private_workspace):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("content\n", encoding="utf-8")

            self.assertEqual(
                format_project.project_files(root),
                [source_tool, source_test],
            )


if __name__ == "__main__":
    unittest.main()
