from __future__ import annotations

import unittest

from scripts import run


class ScriptRunnerTests(unittest.TestCase):
    def test_discovers_every_categorized_python_tool(self) -> None:
        tools = run.available_tools()
        expected_paths = sorted(
            ".".join(path.relative_to(run.SCRIPT_ROOT).with_suffix("").parts)
            for category in run.PUBLIC_CATEGORIES
            for path in (run.SCRIPT_ROOT / category).rglob("*.py")
            if path.name != "__init__.py" and "__pycache__" not in path.parts
        )
        self.assertEqual(tools, expected_paths)
        self.assertEqual(len(tools), len(set(tools)))

    def test_exposes_each_responsibility(self) -> None:
        tools = run.available_tools()
        self.assertEqual(
            {tool.split(".", 1)[0] for tool in tools},
            run.PUBLIC_CATEGORIES,
        )

    def test_rejects_root_and_unknown_modules(self) -> None:
        for name in ("level_editor", "unknown.missing", "validation.__hidden"):
            with self.subTest(name=name), self.assertRaises(SystemExit):
                run.require_tool(name)


if __name__ == "__main__":
    unittest.main()
