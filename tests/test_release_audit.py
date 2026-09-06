from __future__ import annotations

from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import release_audit


class ReleaseAuditTests(unittest.TestCase):
    def test_reference_contract_accepts_matching_identity(self) -> None:
        release = {
            "reference": {
                "rom_sha1": "rom",
                "prg_sha1": "prg",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "vertical",
            }
        }
        assets = {
            "reference_rom": {
                "file_sha1": "rom",
                "prg_sha1": "prg",
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
                "rom_sha1": "expected",
                "prg_sha1": "prg",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "vertical",
            }
        }
        assets = {
            "reference_rom": {
                "file_sha1": "wrong",
                "prg_sha1": "prg",
                "chr_sha1": "chr",
                "mapper": 3,
                "mirroring": "horizontal",
            }
        }
        errors = release_audit.validate_reference_contract(release, assets)
        self.assertEqual(len(errors), 2)
        self.assertIn("ROM SHA-1", errors[0])
        self.assertIn("mirroring", errors[1])


if __name__ == "__main__":
    unittest.main()
