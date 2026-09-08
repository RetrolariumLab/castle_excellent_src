from __future__ import annotations

import json
from pathlib import Path
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
