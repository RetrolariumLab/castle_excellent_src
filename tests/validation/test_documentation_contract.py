from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts.build.project import ProjectError
from scripts.validation import documentation_contract


class DocumentationContractTests(unittest.TestCase):
    def test_review_requires_exact_inventory_and_current_sizes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / "config/reconstruction").mkdir(parents=True)
            (root / "docs/index.md").write_text("# Index\n", encoding="utf-8")
            review = {
                "schema_version": 1,
                "release": "2.1",
                "documents": [
                    {
                        "path": "docs/index.md",
                        "lines": 2,
                        "disposition": "retained",
                        "audience": "all readers",
                        "reason": "canonical navigation",
                    }
                ],
                "removed_documents": [],
                "reader_journeys": [{"id": "start", "paths": ["docs/index.md"]}],
                "repeated_prefixes": [],
            }
            (root / documentation_contract.REVIEW_PATH).write_text(
                json.dumps(review), encoding="utf-8"
            )
            with self.assertRaisesRegex(ProjectError, "line count is stale"):
                documentation_contract.validate_documentation_review(root)

    def test_review_requires_repeated_prefix_decisions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / "config/reconstruction").mkdir(parents=True)
            paths = ("docs/topic_one.md", "docs/topic_two.md")
            for relative in paths:
                (root / relative).write_text("# Topic\n", encoding="utf-8")
            records = [
                {
                    "path": relative,
                    "lines": 1,
                    "disposition": "retained",
                    "audience": "reader",
                    "reason": "independent purpose",
                }
                for relative in paths
            ]
            review = {
                "schema_version": 1,
                "release": "2.1",
                "documents": records,
                "removed_documents": [],
                "reader_journeys": [{"id": "topic", "paths": list(paths)}],
                "repeated_prefixes": [],
            }
            (root / documentation_contract.REVIEW_PATH).write_text(
                json.dumps(review), encoding="utf-8"
            )
            with self.assertRaisesRegex(ProjectError, "prefix.*incomplete"):
                documentation_contract.validate_documentation_review(root)

    def test_label_mapping_uses_every_symbol_without_duplication(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            config = root / "config/reconstruction"
            config.mkdir(parents=True)
            (config / "symbols.json").write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "symbols": [
                            {"address": "0x8000", "name": "Reset"},
                            {"address": "0x8001", "name": "Loop"},
                        ],
                    }
                ),
                encoding="utf-8",
            )
            registry = {
                "schema_version": 1,
                "mapping": {
                    "scope": "all-symbols",
                    "join_key": "address",
                    "old_name_template": "PRG0:${address_hex}",
                    "address_conversion": "strip-0x-prefix-and-prefix-dollar",
                    "new_name_registry": "config/reconstruction/symbols.json",
                    "new_name_field": "name",
                    "expected_entries": 2,
                },
                "imported_aliases": [
                    {"address": "0x8000", "old_name": "reset"}
                ],
            }
            (config / "label_renames.json").write_text(
                json.dumps(registry), encoding="utf-8"
            )
            documentation_contract.validate_label_renames(root)
            registry["mapping"]["expected_entries"] = 1
            (config / "label_renames.json").write_text(
                json.dumps(registry), encoding="utf-8"
            )
            with self.assertRaisesRegex(ProjectError, "count is stale"):
                documentation_contract.validate_label_renames(root)

            (root / "docs/label_renames.json").write_text("{}", encoding="utf-8")
            with self.assertRaisesRegex(ProjectError, "must exist only"):
                documentation_contract.validate_label_renames(root)


if __name__ == "__main__":
    unittest.main()
