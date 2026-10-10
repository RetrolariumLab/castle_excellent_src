from __future__ import annotations

from pathlib import Path
import unittest

from scripts.validation import public_command_smoke


ROOT = Path(__file__).resolve().parents[2]


class PublicCommandSmokeTests(unittest.TestCase):
    def test_real_lint_target_passes_in_disposable_clone(self) -> None:
        output = public_command_smoke.run_disposable_make(ROOT, "lint")
        self.assertIn("317 text files satisfy the formatting contract", output)
        self.assertIn("project structure, manifest, source contract", output)

    def test_real_minor_audit_needs_its_tag(self) -> None:
        # The 2.1 audit runs at its tag, whose own audit checks the history.
        output = public_command_smoke.run_disposable_missing_tag_rejection(ROOT)
        self.assertIn("cannot check out source-reconstruction-2.1", output)

    def test_unpinned_toolchain_override_is_rejected_before_execution(self) -> None:
        output = public_command_smoke.run_unpinned_toolchain_rejection(ROOT)
        self.assertIn("selected toolchain binary SHA-256 mismatch: ca65", output)


if __name__ == "__main__":
    unittest.main()
