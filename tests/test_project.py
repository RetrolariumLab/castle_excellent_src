from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import project


def sample_ines() -> bytes:
    header = b"NES\x1a" + bytes((2, 4, 0x31, 0)) + bytes(8)
    return header + bytes(32_768) + bytes([0xFF]) * 32_768


def sample_manifest(image: bytes, complete: bool = True) -> dict[str, object]:
    parsed, facts = project.image_facts(image)
    reference = {
        "file_size": len(image),
        "payload_crc32": facts["payload_crc32"],
        "prg_size": 32_768,
        "prg_crc32": facts["prg_crc32"],
        "chr_size": 32_768,
        "chr_crc32": facts["chr_crc32"],
        "trainer_size": 0,
        "mapper": 3,
        "mirroring": "vertical",
    }
    if complete:
        reference.update({
            "file_sha1": facts["file_sha1"],
            "file_md5": facts["file_md5"],
            "file_crc32": facts["file_crc32"],
            "payload_sha1": facts["payload_sha1"],
            "header_sha1": facts["header_sha1"],
            "prg_sha1": facts["prg_sha1"],
            "chr_sha1": facts["chr_sha1"],
        })
    return {"schema_version": 1, "reference_rom": reference}


class InesTests(unittest.TestCase):
    def test_parse_castle_excellent_shape(self) -> None:
        parsed = project.parse_ines(sample_ines())
        self.assertEqual(parsed["mapper"], 3)
        self.assertEqual(parsed["mirroring"], "vertical")
        self.assertEqual(len(parsed["prg"]), 32_768)
        self.assertEqual(len(parsed["chr"]), 32_768)

    def test_rejects_trailing_data(self) -> None:
        with self.assertRaisesRegex(project.ProjectError, "expected exactly"):
            project.parse_ines(sample_ines() + b"trailing")

    def test_complete_manifest_verifies_every_region(self) -> None:
        image = sample_ines()
        project.validate_image(image, sample_manifest(image))

    def test_partial_public_crc_manifest_is_supported(self) -> None:
        image = sample_ines()
        project.validate_image(image, sample_manifest(image, complete=False))

    def test_region_change_is_detected(self) -> None:
        image = sample_ines()
        changed = image[:-1] + b"\x00"
        with self.assertRaisesRegex(project.ProjectError, "mismatch"):
            project.validate_image(changed, sample_manifest(image))


class AssetTests(unittest.TestCase):
    def test_safe_asset_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(
                project.safe_asset_path(root, "chr/game.chr"),
                root / "chr" / "game.chr",
            )

    def test_rejects_parent_asset_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(project.ProjectError, "unsafe"):
                project.safe_asset_path(Path(directory), "../game.chr")

    def test_load_manifest_rejects_unknown_schema(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps({"schema_version": 2}), encoding="utf-8")
            with self.assertRaisesRegex(project.ProjectError, "schema"):
                project.load_manifest(path)

    def test_split_checks_optional_crc_and_writes_selected_asset(self) -> None:
        image = sample_ines()
        manifest = sample_manifest(image, complete=False)
        parsed = project.parse_ines(image)
        manifest["extracted_assets"] = [{
            "path": "chr/game.chr",
            "region": "chr",
            "size": len(parsed["chr"]),
            "crc32": project.crc32(parsed["chr"]),
        }]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image_path = root / "game.nes"
            manifest_path = root / "manifest.json"
            output = root / "generated"
            image_path.write_bytes(image)
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            args = type("Args", (), {
                "image": str(image_path),
                "manifest": str(manifest_path),
                "output_dir": str(output),
            })()
            project.command_split(args)
            self.assertEqual((output / "chr" / "game.chr").read_bytes(), parsed["chr"])


class PrgDataRangeTests(unittest.TestCase):
    def test_loads_sorted_typed_ranges(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ranges.txt"
            path.write_text(
                "table 8000 800F FirstTable\ntext 8100 811F TextData\n",
                encoding="utf-8",
            )
            self.assertEqual(
                project.load_prg_data_ranges(path),
                [
                    ("table", 0x8000, 0x800F, "FirstTable"),
                    ("text", 0x8100, 0x811F, "TextData"),
                ],
            )

    def test_rejects_overlapping_typed_ranges(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ranges.txt"
            path.write_text(
                "table 8000 8010 FirstTable\ndata 8010 8020 OtherData\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(project.ProjectError, "overlap"):
                project.load_prg_data_ranges(path)

    def test_rejects_runtime_code_in_typed_data(self) -> None:
        ranges = [("table", 0x9000, 0x90FF, "LookupTable")]
        with tempfile.TemporaryDirectory() as directory:
            evidence = Path(directory) / "runtime.txt"
            evidence.write_text("code 9080 9090\n", encoding="utf-8")
            with self.assertRaisesRegex(project.ProjectError, "overlaps typed data"):
                project.validate_runtime_data_separation(ranges, evidence)

    def test_loads_sorted_static_code_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            evidence = Path(directory) / "static.txt"
            evidence.write_text(
                "# pointer-table provenance\ncode A000 A00F\ncode A100 A10F\n",
                encoding="utf-8",
            )
            self.assertEqual(
                project.load_code_evidence(evidence, "static"),
                [(0xA000, 0xA00F), (0xA100, 0xA10F)],
            )

    def test_rejects_unsorted_static_code_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            evidence = Path(directory) / "static.txt"
            evidence.write_text(
                "code A100 A10F\ncode A000 A00F\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(project.ProjectError, "unsorted"):
                project.load_code_evidence(evidence, "static")

    def test_rejects_static_code_in_typed_data(self) -> None:
        ranges = [("table", 0xA000, 0xA0FF, "LookupTable")]
        with tempfile.TemporaryDirectory() as directory:
            evidence = Path(directory) / "static.txt"
            evidence.write_text("code A080 A090\n", encoding="utf-8")
            with self.assertRaisesRegex(project.ProjectError, "static code"):
                project.validate_code_data_separation(ranges, evidence, "static")


if __name__ == "__main__":
    unittest.main()
