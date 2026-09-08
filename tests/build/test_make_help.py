from __future__ import annotations

from pathlib import Path
import unittest

from scripts.build import make_help
from scripts.validation import release_audit


ROOT = Path(__file__).resolve().parents[2]


class MakeHelpTests(unittest.TestCase):
    def test_documents_existing_public_targets(self) -> None:
        documented = make_help.documented_targets()
        entry_count = sum(len(entries) for _, entries in make_help.TARGET_GROUPS)
        self.assertEqual(len(documented), entry_count)
        self.assertLessEqual(documented, release_audit.project_make_targets(ROOT))

    def test_rendering_exposes_each_category_and_selector(self) -> None:
        rendered = make_help.render_help()
        for heading, _entries in make_help.TARGET_GROUPS:
            self.assertIn(f"{heading}:", rendered)
        self.assertIn("REVISION_PROFILE=", rendered)
        self.assertIn("scripts/run.py --list", rendered)


if __name__ == "__main__":
    unittest.main()
