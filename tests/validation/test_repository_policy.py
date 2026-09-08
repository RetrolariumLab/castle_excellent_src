from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts.build.project import ProjectError
from scripts.validation import repository_policy


class ToolLayoutTests(unittest.TestCase):
    def make_contract(self, root: Path, exception: dict[str, object]) -> None:
        config = root / "config" / "reconstruction"
        config.mkdir(parents=True)
        (config / "tool_layout.json").write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "python_target_lines": {"minimum": 300, "maximum": 3},
                    "size_exceptions": [exception],
                }
            ),
            encoding="utf-8",
        )

    def test_declared_oversized_tool_is_bounded_and_explained(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / "scripts" / "authoring"
            scripts.mkdir(parents=True)
            source = scripts / "studio.py"
            source.write_text("one\ntwo\nthree\nfour\n", encoding="utf-8")
            self.make_contract(
                root,
                {
                    "path": "scripts/authoring/studio.py",
                    "lines": 4,
                    "maximum": 5,
                    "reason": "cohesive GUI controller",
                },
            )
            repository_policy.validate_tool_layout(root)

    def test_stale_line_count_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / "scripts" / "authoring"
            scripts.mkdir(parents=True)
            (scripts / "studio.py").write_text(
                "one\ntwo\nthree\nfour\n", encoding="utf-8"
            )
            self.make_contract(
                root,
                {
                    "path": "scripts/authoring/studio.py",
                    "lines": 5,
                    "maximum": 5,
                    "reason": "cohesive GUI controller",
                },
            )
            with self.assertRaisesRegex(ProjectError, "line count is stale"):
                repository_policy.validate_tool_layout(root)


if __name__ == "__main__":
    unittest.main()
