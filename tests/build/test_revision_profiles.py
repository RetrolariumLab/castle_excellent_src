from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]

from scripts.build import project
from scripts.build import revision_profiles
def sample_ines() -> bytes:
    header = b"NES\x1a" + bytes((2, 4, 0x31, 0)) + bytes(8)
    return header + bytes(32_768) + bytes([0xFF]) * 32_768


def sample_profile(image: bytes) -> dict[str, object]:
    regions = revision_profiles.profile_regions(image)
    profile: dict[str, object] = {
        "id": "sample",
        "reference_rom": "sample.nes",
        "defines": ["SAMPLE=1"],
        "entrypoint": "src/main.asm",
        "linker_config": "config/linker/cnrom.cfg",
        "output_rom": "build/revisions/sample/sample.nes",
        "chr_asset": "assets/generated/revisions/sample/chr/sample.chr",
    }
    for name, data in regions.items():
        profile[f"{name}_size"] = len(data)
        profile[f"{name}_sha1"] = hashlib.sha1(data).hexdigest()
        profile[f"{name}_sha256"] = hashlib.sha256(data).hexdigest()
    return profile


class RevisionProfileTests(unittest.TestCase):
    def test_project_manifest_owns_both_build_profiles(self) -> None:
        manifest = revision_profiles.load_profiles(ROOT / "config/revision_profiles.json")
        self.assertEqual(
            manifest["default_profile"],
            "castle-excellent-japan-hsp-05",
        )
        castlequest = revision_profiles.select_profile(manifest, "castlequest-usa")
        self.assertEqual(castlequest["defines"], ["CASTLEQUEST_USA=1"])
        self.assertEqual(
            castlequest["output_rom"],
            "build/revisions/castlequest-usa/castlequest.nes",
        )

    def test_manifest_selects_one_profile(self) -> None:
        manifest = {"schema_version": 1, "profiles": [sample_profile(sample_ines())]}
        self.assertEqual(
            revision_profiles.select_profile(manifest, "sample")["defines"],
            ["SAMPLE=1"],
        )

    def test_reference_validation_covers_all_regions(self) -> None:
        image = sample_ines()
        revision_profiles.validate_reference(image, sample_profile(image))
        changed = image[:-1] + b"\x00"
        with self.assertRaisesRegex(project.ProjectError, "sha1 mismatch"):
            revision_profiles.validate_reference(changed, sample_profile(image))

    def test_split_writes_only_the_private_chr_asset(self) -> None:
        image = sample_ines()
        profile = sample_profile(image)
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            workspace = Path(directory)
            profile["reference_rom"] = str(workspace.relative_to(ROOT) / "sample.nes")
            profile["chr_asset"] = str(workspace.relative_to(ROOT) / "sample.chr")
            manifest_path = workspace / "profiles.json"
            (workspace / "sample.nes").write_bytes(image)
            manifest_path.write_text(
                json.dumps({"schema_version": 1, "profiles": [profile]}),
                encoding="utf-8",
            )
            args = type(
                "Args",
                (),
                {"manifest": str(manifest_path), "profile": "sample"},
            )()
            revision_profiles.command_split(args)
            self.assertEqual((workspace / "sample.chr").read_bytes(), image[-32_768:])
            self.assertFalse((workspace / "sample.prg").exists())

    def test_split_extracts_declared_hashed_binary_asset(self) -> None:
        image = sample_ines()
        profile = sample_profile(image)
        payload = revision_profiles.profile_regions(image)["prg"][4:7]
        with tempfile.TemporaryDirectory(dir=ROOT) as directory:
            workspace = Path(directory)
            relative_workspace = workspace.relative_to(ROOT)
            profile["reference_rom"] = str(relative_workspace / "sample.nes")
            profile["chr_asset"] = str(relative_workspace / "sample.chr")
            profile["binary_assets"] = [
                {
                    "id": "sample-data",
                    "region": "prg",
                    "offset": "0x4",
                    "size": len(payload),
                    "path": str(relative_workspace / "sample-data.bin"),
                    "sha1": hashlib.sha1(payload).hexdigest(),
                    "sha256": hashlib.sha256(payload).hexdigest(),
                }
            ]
            manifest_path = workspace / "profiles.json"
            (workspace / "sample.nes").write_bytes(image)
            manifest_path.write_text(
                json.dumps({"schema_version": 1, "profiles": [profile]}),
                encoding="utf-8",
            )
            args = type(
                "Args",
                (),
                {"manifest": str(manifest_path), "profile": "sample"},
            )()
            revision_profiles.command_split(args)
            self.assertEqual((workspace / "sample-data.bin").read_bytes(), payload)

    def test_binary_asset_validation_rejects_changed_bytes(self) -> None:
        payload = b"abc"
        entry = {
            "id": "sample-data",
            "size": len(payload),
            "sha1": hashlib.sha1(payload).hexdigest(),
            "sha256": hashlib.sha256(payload).hexdigest(),
        }
        with self.assertRaisesRegex(project.ProjectError, "sha1 mismatch"):
            revision_profiles.validate_asset_bytes(entry, b"abd")

    def test_first_difference_handles_content_and_length(self) -> None:
        self.assertIsNone(revision_profiles.first_difference(b"abc", b"abc"))
        self.assertEqual(revision_profiles.first_difference(b"abc", b"axc"), 1)
        self.assertEqual(revision_profiles.first_difference(b"abc", b"abcd"), 3)


if __name__ == "__main__":
    unittest.main()
