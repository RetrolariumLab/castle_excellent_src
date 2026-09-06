from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import source_2_release_audit as audit


class Source2ReleaseAuditTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
