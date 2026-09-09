from __future__ import annotations

from pathlib import Path
import unittest

from scripts.validation import public_command_smoke


ROOT = Path(__file__).resolve().parents[2]


class PublicCommandSmokeTests(unittest.TestCase):
    def test_real_lint_target_passes_in_disposable_clone(self) -> None:
        output = public_command_smoke.run_disposable_make(ROOT, "lint")
        self.assertIn("340 text files satisfy the formatting contract", output)
        self.assertIn("project structure, manifest, source contract", output)

    def test_real_minor_audit_rejects_disposable_empty_commit(self) -> None:
        output = public_command_smoke.run_disposable_empty_commit_rejection(ROOT)
        self.assertIn("is empty relative to every parent", output)


if __name__ == "__main__":
    unittest.main()
