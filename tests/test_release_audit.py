from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent

from scripts.validation import release_audit
class ReleaseAuditTests(unittest.TestCase):
    def test_project_scenario_captures_resolve_after_tool_reorganization(self) -> None:
        release = release_audit.load_json(
            ROOT / "config" / "source_reconstruction_1_0.json"
        )
        self.assertEqual(release_audit.validate_scenario_manifest(ROOT, release), [])

    def test_reference_contract_accepts_matching_identity(self) -> None:
        release = {
            "reference": {
                "rom_sha256": "rom256",
                "rom_sha1": "rom",
                "header_sha256": "header256",
                "prg_sha256": "prg256",
                "prg_sha1": "prg",
                "chr_sha256": "chr256",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "vertical",
            }
        }
        assets = {
            "reference_rom": {
                "file_sha256": "rom256",
                "file_sha1": "rom",
                "header_sha256": "header256",
                "prg_sha256": "prg256",
                "prg_sha1": "prg",
                "chr_sha256": "chr256",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "vertical",
            }
        }
        self.assertEqual(
            release_audit.validate_reference_contract(release, assets), []
        )

    def test_reference_contract_reports_each_mismatch(self) -> None:
        release = {
            "reference": {
                "rom_sha256": "rom256",
                "rom_sha1": "expected",
                "header_sha256": "header256",
                "prg_sha256": "prg256",
                "prg_sha1": "prg",
                "chr_sha256": "chr256",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "vertical",
            }
        }
        assets = {
            "reference_rom": {
                "file_sha256": "rom256",
                "file_sha1": "wrong",
                "header_sha256": "header256",
                "prg_sha256": "prg256",
                "prg_sha1": "prg",
                "chr_sha256": "chr256",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "horizontal",
            }
        }
        errors = release_audit.validate_reference_contract(release, assets)
        self.assertEqual(len(errors), 2)
        self.assertIn("ROM SHA-1", errors[0])
        self.assertIn("mirroring", errors[1])

    def test_make_targets_extracts_only_public_rules(self) -> None:
        makefile = "lint:\n\tpython lint.py\n\nfile.o: file.asm\n\n.PHONY: lint\n"
        self.assertEqual(release_audit.make_targets(makefile), {"lint", "file.o"})

    def test_scenario_manifest_matches_direct_profile_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scenarios").mkdir()
            (root / "scripts").mkdir()
            (root / "scripts" / "capture.lua").write_text("-- capture\n", encoding="utf-8")
            document = {
                "profile_id": "jp",
                "scenarios": [
                    {
                        "id": "boot",
                        "capture": "scripts/capture.lua",
                        "maximum_frames": 10,
                        "start_condition": "reset",
                        "expected_result": "main loop",
                        "required_hooks": [],
                        "controlled_patches": [],
                    }
                ],
            }
            (root / "scenarios" / "source_1.json").write_text(
                json.dumps(document), encoding="utf-8"
            )
            release = {
                "runtime": {"scenarios_manifest": "scenarios/source_1.json"},
                "runtime_coverage": [
                    {"profile_id": "jp", "mode": "direct", "scenarios": ["boot"]}
                ],
            }
            self.assertEqual(
                release_audit.validate_scenario_manifest(root, release), []
            )


if __name__ == "__main__":
    unittest.main()
