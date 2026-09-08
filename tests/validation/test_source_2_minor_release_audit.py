from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from scripts.validation import source_2_minor_release_audit as audit


ROOT = Path(__file__).resolve().parents[2]


class Source2MinorReleaseAuditTests(unittest.TestCase):
    def test_project_release_schema_is_verified(self) -> None:
        release = {"schema_version": 1, "release_line": "2.x"}
        self.assertEqual(audit.validate_release_schema(release), [])
        release["release_line"] = "2.0"
        self.assertEqual(
            audit.validate_release_schema(release),
            ["release_line must be '2.x'"],
        )

    def test_non_english_public_text_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            document = root / "README.md"
            document.write_text(
                "English heading\n\u0420\u0443\u0441\u0441\u043a\u0438\u0439 "
                "\u0442\u0435\u043a\u0441\u0442\n",
                encoding="utf-8",
            )
            with mock.patch.object(audit, "git_lines", return_value=["README.md"]):
                errors = audit.validate_public_english_text(root)
        self.assertEqual(len(errors), 1)
        self.assertIn("README.md:2", errors[0])

    def test_unrelated_local_tag_does_not_replace_candidate_head(self) -> None:
        responses = [["old-tag-target"], ["candidate-head"]]
        with mock.patch("subprocess.run") as run, mock.patch.object(
            audit, "git_lines", side_effect=responses
        ):
            run.return_value.returncode = 0
            terminal = audit.release_terminal(ROOT, {"tag": "draft-tag"})
        self.assertEqual(terminal, "HEAD")

    def test_delta_history_rejects_uncovered_substantive_commit(self) -> None:
        release = {
            "tag": "future-tag",
            "predecessor": {"commit": "base"},
            "delta_history": {
                "from_exclusive": "base",
                "through_inclusive": "covered",
                "commit_count": 1,
            },
        }
        responses = [
            ["covered"],
            ["later"],
            ["scripts/build/project.py"],
        ]
        with mock.patch.object(audit, "git_lines", side_effect=responses), mock.patch(
            "subprocess.run"
        ) as run:
            run.return_value.returncode = 1
            errors = audit.validate_delta_history(ROOT, release)
        self.assertEqual(
            errors,
            ["delta_history does not cover substantive commit later"],
        )

    def test_project_manifest_uses_the_supported_schema(self) -> None:
        release = audit.load_json(ROOT / "config" / "source_reconstruction_2_1.json")
        self.assertEqual(audit.validate_release_schema(release), [])

    def test_predecessor_is_the_published_annotated_source_2_tag(self) -> None:
        release = audit.load_json(ROOT / "config" / "source_reconstruction_2_1.json")
        self.assertEqual(audit.validate_predecessor(ROOT, release), [])


if __name__ == "__main__":
    unittest.main()
