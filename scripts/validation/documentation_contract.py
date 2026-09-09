#!/usr/bin/env python3
"""Validate documentation-corpus review and source-label provenance contracts."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
from typing import Any

from scripts.build.project import ProjectError


REVIEW_PATH = Path("config/reconstruction/documentation_review.json")
RENAME_PATH = Path("config/reconstruction/label_renames.json")
SYMBOL_PATH = "config/reconstruction/symbols.json"
DOCUMENT_DISPOSITIONS = {"retained", "revised"}


def _load_object(path: Path, description: str) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProjectError(f"cannot read {description}: {exc}") from exc
    if not isinstance(document, dict):
        raise ProjectError(f"{description} must be a JSON object")
    return document


def _documentation_prefixes(paths: set[str]) -> dict[str, list[str]]:
    grouped: dict[str, list[str]] = {}
    for relative in sorted(paths):
        stem = Path(relative).stem
        if "_" not in stem:
            continue
        prefix = stem.split("_", 1)[0]
        grouped.setdefault(prefix, []).append(relative)
    return {prefix: items for prefix, items in grouped.items() if len(items) > 1}


def validate_documentation_review(root: Path) -> None:
    """Require an exact, reasoned inventory of the reader-facing docs corpus."""
    review = _load_object(root / REVIEW_PATH, "documentation review")
    if review.get("schema_version") != 1:
        raise ProjectError("unsupported documentation review schema")
    if review.get("release") != "2.1":
        raise ProjectError("documentation review must identify release 2.1")

    actual_paths = {
        path.relative_to(root).as_posix()
        for path in (root / "docs").rglob("*.md")
        if path.is_file()
    }
    records = review.get("documents")
    if not isinstance(records, list):
        raise ProjectError("documentation review has no document inventory")
    declared: dict[str, dict[str, Any]] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("path"), str):
            raise ProjectError("documentation review contains an incomplete record")
        relative = record["path"]
        if relative in declared:
            raise ProjectError(f"documentation review duplicates {relative}")
        declared[relative] = record
        if record.get("disposition") not in DOCUMENT_DISPOSITIONS:
            raise ProjectError(f"documentation review has invalid disposition: {relative}")
        if not record.get("audience") or not record.get("reason"):
            raise ProjectError(f"documentation review lacks rationale: {relative}")
    if set(declared) != actual_paths:
        raise ProjectError(
            "documentation review inventory mismatch; "
            f"missing={sorted(actual_paths - set(declared))}, "
            f"stale={sorted(set(declared) - actual_paths)}"
        )
    for relative, record in declared.items():
        lines = len((root / relative).read_text(encoding="utf-8").splitlines())
        if record.get("lines") != lines:
            raise ProjectError(
                f"documentation review line count is stale for {relative}: "
                f"declared {record.get('lines')}, actual {lines}"
            )

    removed = review.get("removed_documents")
    if not isinstance(removed, list):
        raise ProjectError("documentation review has no removed-document record")
    for record in removed:
        if not isinstance(record, dict) or not record.get("path") or not record.get("reason"):
            raise ProjectError("documentation review has an incomplete removal record")
        if (root / record["path"]).exists():
            raise ProjectError(f"removed documentation still exists: {record['path']}")

    journeys = review.get("reader_journeys")
    if not isinstance(journeys, list) or not journeys:
        raise ProjectError("documentation review has no reader journeys")
    for journey in journeys:
        paths = journey.get("paths", []) if isinstance(journey, dict) else []
        if not journey.get("id") or not paths or any(path not in actual_paths for path in paths):
            raise ProjectError("documentation review has an invalid reader journey")

    actual_prefixes = _documentation_prefixes(actual_paths)
    clusters = review.get("repeated_prefixes")
    if not isinstance(clusters, list):
        raise ProjectError("documentation review has no repeated-prefix inventory")
    declared_prefixes: dict[str, dict[str, Any]] = {}
    for cluster in clusters:
        if not isinstance(cluster, dict) or not cluster.get("prefix"):
            raise ProjectError("documentation review has an incomplete prefix record")
        prefix = cluster["prefix"]
        if prefix in declared_prefixes:
            raise ProjectError(f"documentation review duplicates prefix {prefix}")
        declared_prefixes[prefix] = cluster
        if cluster.get("paths") != actual_prefixes.get(prefix):
            raise ProjectError(f"documentation review prefix paths are stale: {prefix}")
        if cluster.get("decision") not in {"retain", "consolidate"} or not cluster.get("reason"):
            raise ProjectError(f"documentation review prefix lacks a decision: {prefix}")
    if set(declared_prefixes) != set(actual_prefixes):
        raise ProjectError("documentation review repeated-prefix inventory is incomplete")


def validate_label_renames(root: Path) -> None:
    """Validate the sole address-keyed old-to-new label mapping definition."""
    tracked = subprocess.run(
        ["git", "ls-files"],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if tracked.returncode == 0:
        candidates = sorted(
            relative.replace("\\", "/")
            for relative in tracked.stdout.splitlines()
            if Path(relative).name == "label_renames.json"
        )
    else:
        candidates = sorted(
            path.relative_to(root).as_posix()
            for base in (root / "config", root / "docs")
            for path in base.rglob("label_renames.json")
            if path.is_file()
        )
    if candidates != [RENAME_PATH.as_posix()]:
        raise ProjectError(
            "label rename registry must exist only at "
            f"{RENAME_PATH.as_posix()}; found={candidates}"
        )
    registry = _load_object(root / RENAME_PATH, "label rename registry")
    if registry.get("schema_version") != 1:
        raise ProjectError("unsupported label rename registry schema")
    mapping = registry.get("mapping")
    if not isinstance(mapping, dict):
        raise ProjectError("label rename registry has no mapping definition")
    expected_mapping = {
        "scope": "all-symbols",
        "join_key": "address",
        "old_name_template": "PRG0:${address_hex}",
        "address_conversion": "strip-0x-prefix-and-prefix-dollar",
        "new_name_registry": SYMBOL_PATH,
        "new_name_field": "name",
    }
    for key, value in expected_mapping.items():
        if mapping.get(key) != value:
            raise ProjectError(f"label rename mapping has invalid {key}")
    symbols = _load_object(root / SYMBOL_PATH, "symbol registry").get("symbols")
    if not isinstance(symbols, list) or not symbols:
        raise ProjectError("symbol registry has no symbols for label renames")
    addresses = [record.get("address") for record in symbols if isinstance(record, dict)]
    names = [record.get("name") for record in symbols if isinstance(record, dict)]
    if (
        len(addresses) != len(symbols)
        or len(set(addresses)) != len(symbols)
        or len(set(names)) != len(symbols)
        or any(not address for address in addresses)
        or any(not name for name in names)
    ):
        raise ProjectError("symbol registry cannot provide a unique label mapping")
    if mapping.get("expected_entries") != len(symbols):
        raise ProjectError("label rename mapping count is stale")
    aliases = registry.get("imported_aliases")
    if not isinstance(aliases, list):
        raise ProjectError("label rename registry has no imported-alias inventory")
    address_set = set(addresses)
    seen: set[tuple[str, str]] = set()
    for alias in aliases:
        if not isinstance(alias, dict):
            raise ProjectError("label rename registry has an invalid imported alias")
        pair = (alias.get("address"), alias.get("old_name"))
        if pair[0] not in address_set or not pair[1] or pair in seen:
            raise ProjectError("label rename registry has an invalid imported alias")
        seen.add(pair)
