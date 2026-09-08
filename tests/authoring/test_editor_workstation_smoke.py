from __future__ import annotations

from pathlib import Path
import unittest

from scripts.authoring import editor_workstation_smoke


ROOT = Path(__file__).resolve().parents[2]


class EditorWorkstationSmokeContractTests(unittest.TestCase):
    def test_required_actions_cover_each_public_editor_capability(self) -> None:
        self.assertEqual(
            editor_workstation_smoke.REQUIRED_ACTIONS,
            {
                "level": {"save", "build", "play", "preview", "dirty-close"},
                "sound": {"save", "build", "play", "preview", "dirty-close"},
                "graphics": {"save", "build", "preview", "dirty-close"},
            },
        )

    def test_make_uses_the_interaction_smoke_instead_of_widget_only_flags(self) -> None:
        make = (ROOT / "mk" / "authoring.mk").read_text(encoding="utf-8")
        recipe = make.split("editor-ui-smoke-profile:", 1)[1]
        self.assertIn("authoring.editor_workstation_smoke", recipe)
        self.assertNotIn("--smoke-ui", recipe)


if __name__ == "__main__":
    unittest.main()
