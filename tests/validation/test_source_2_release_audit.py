from __future__ import annotations

import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]

from scripts.validation import source_2_release_audit as audit
class Source2ReleaseAuditTests(unittest.TestCase):
    def test_published_release_uses_immutable_tag_as_history_terminal(self) -> None:
        release = {"tag": "source-reconstruction-2.0"}
        with mock.patch("subprocess.run") as run, mock.patch.object(
            audit, "git_lines", return_value=["release-commit"]
        ):
            run.return_value.returncode = 0
            self.assertEqual(audit.release_terminal(ROOT, release), "release-commit")

    def test_unpublished_release_uses_head_as_history_terminal(self) -> None:
        release = {"tag": "future-tag"}
        with mock.patch("subprocess.run") as run:
            run.return_value.returncode = 1
            self.assertEqual(audit.release_terminal(ROOT, release), "HEAD")

    def test_delta_history_allows_only_trailing_release_metadata(self) -> None:
        release = {
            "predecessor": {"commit": "base"},
            "delta_history": {
                "from_exclusive": "base",
                "through_inclusive": "covered",
                "commit_count": 2,
            },
        }
        responses = [
            ["feature", "covered"],
            ["metadata"],
            ["config/source_reconstruction_2_0.json"],
        ]
        with mock.patch.object(audit, "git_lines", side_effect=responses):
            self.assertEqual(audit.validate_delta_history(ROOT, release), [])

    def test_delta_history_rejects_a_trailing_substantive_commit(self) -> None:
        release = {
            "predecessor": {"commit": "base"},
            "delta_history": {
                "from_exclusive": "base",
                "through_inclusive": "covered",
                "commit_count": 1,
            },
        }
        responses = [["covered"], ["later"], ["scripts/build/project.py"]]
        with mock.patch.object(audit, "git_lines", side_effect=responses):
            errors = audit.validate_delta_history(ROOT, release)
        self.assertEqual(
            errors,
            ["delta_history does not cover substantive commit later"],
        )

    def test_project_runtime_manifests_and_captures_resolve(self) -> None:
        release = audit.load_json(ROOT / "config" / "source_reconstruction_2_0.json")
        self.assertEqual(audit.validate_runtime_manifests(ROOT, release), [])

    def test_development_branch_must_point_to_head(self) -> None:
        release = {
            "provenance": {
                "history_policy": {"development_branch": "source-reconstruction-2.0"}
            }
        }
        with mock.patch.object(audit, "git_lines", side_effect=[["candidate"], ["head"]]):
            self.assertEqual(
                audit.validate_development_branch(ROOT, release),
                [
                    "development branch does not point to HEAD: "
                    "source-reconstruction-2.0"
                ],
            )

    def test_development_branch_accepts_head(self) -> None:
        release = {
            "provenance": {
                "history_policy": {"development_branch": "source-reconstruction-2.0"}
            }
        }
        with mock.patch.object(
            audit, "git_lines", side_effect=[["candidate"], ["candidate"]]
        ):
            self.assertEqual(audit.validate_development_branch(ROOT, release), [])

    def test_not_applicable_requirement_needs_reason_and_excluded_scope(self) -> None:
        release = {
            "status": "development",
            "excluded_scope": [{"id": "world"}],
            "artifacts": [],
            "requirements": {
                "world": {
                    "status": "not_applicable",
                    "reason": "fixed topology",
                    "excluded_scope": "world",
                    "evidence": {"targets": [], "files": [], "scenarios": [], "artifacts": []},
                }
            },
        }
        self.assertEqual(audit.validate_requirements(ROOT, release, set()), [])
        release["requirements"]["world"]["reason"] = ""
        self.assertIn(
            "requirement world has no not-applicable reason",
            audit.validate_requirements(ROOT, release, set()),
        )

    def test_tag_ready_manifest_rejects_unfinished_requirement(self) -> None:
        release = {
            "status": "tag-ready",
            "excluded_scope": [],
            "artifacts": [],
            "requirements": {
                "gate": {
                    "status": "planned",
                    "evidence": {"targets": [], "files": [], "scenarios": [], "artifacts": []},
                }
            },
        }
        errors = audit.validate_requirements(ROOT, release, set())
        self.assertTrue(any("unfinished requirements" in error for error in errors))

    def test_artifact_audit_checks_size_and_both_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            payload = b"source-2-artifact"
            (root / "image.nes").write_bytes(payload)
            release = {
                "artifacts": [
                    {
                        "id": "image",
                        "path": "image.nes",
                        "size": len(payload),
                        "sha1": hashlib.sha1(payload).hexdigest(),
                        "sha256": hashlib.sha256(payload).hexdigest(),
                    }
                ]
            }
            self.assertEqual(audit.validate_artifacts(root, release), [])
            release["artifacts"][0]["sha256"] = "0" * 64
            self.assertEqual(
                audit.validate_artifacts(root, release),
                ["release artifact sha256 mismatch: image"],
            )

    def test_release_metadata_requires_complete_licensing(self) -> None:
        release = audit.load_json(ROOT / "config" / "source_reconstruction_2_0.json")
        licensing = release["licensing"]
        release["licensing"] = [
            item
            for item in licensing
            if item["category"] != "private_user_supplied_inputs"
        ]
        errors = audit.validate_release_metadata(ROOT, release)
        self.assertIn(
            "licensing does not classify every required component category",
            errors,
        )
        release["licensing"] = licensing
        self.assertEqual(audit.validate_release_metadata(ROOT, release), [])


if __name__ == "__main__":
    unittest.main()
