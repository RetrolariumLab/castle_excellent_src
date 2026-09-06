#!/usr/bin/env python3
"""Audit the Castle Excellent Source Reconstruction 1.0 contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any

if __package__:
    from .runtime_coverage import CoverageError, read_metadata, validate_runtime_metadata
    from .source_reconstruction import (
        ReconstructionError,
        audit_layout,
        audit_symbol_maps,
    )
else:
    from runtime_coverage import CoverageError, read_metadata, validate_runtime_metadata
    from source_reconstruction import ReconstructionError, audit_layout, audit_symbol_maps


ROOT = Path(__file__).resolve().parent.parent
UNKNOWN_ID_RE = re.compile(r"^### ([A-Z]+-[0-9]+) - ", re.MULTILINE)


class ReleaseAuditError(ValueError):
    pass


def load_json(path: Path) -> dict[str, Any]:
    document = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        raise ReleaseAuditError(f"expected JSON object in {path}")
    return document


def git_lines(project_root: Path, *arguments: str) -> list[str]:
    result = subprocess.run(
        ["git", *arguments],
        cwd=project_root,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return [line for line in result.stdout.splitlines() if line]


def tool_version(path: Path) -> str:
    result = subprocess.run(
        [str(path), "--version"],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return (result.stdout + result.stderr).strip()


def validate_reference_contract(
    release: dict[str, Any], assets: dict[str, Any]
) -> list[str]:
    expected = release["reference"]
    actual = assets["reference_rom"]
    comparisons = {
        "ROM SHA-1": (expected["rom_sha1"], actual["file_sha1"]),
        "PRG SHA-1": (expected["prg_sha1"], actual["prg_sha1"]),
        "CHR SHA-1": (expected["chr_sha1"], actual["chr_sha1"]),
        "mapper": (expected["mapper"], actual["mapper"]),
        "mirroring": (expected["mirroring"], actual["mirroring"]),
    }
    return [
        f"{name} contract mismatch: release={left}, assets={right}"
        for name, (left, right) in comparisons.items()
        if left != right
    ]


def validate_runtime_contract(
    project_root: Path, release: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    expected_sha1 = release["reference"]["rom_sha1"]
    runtime = release["runtime"]
    for scenario in runtime["scenarios"]:
        name = scenario["name"]
        metadata_path = project_root / scenario["metadata"]
        report_path = project_root / scenario["report"]
        try:
            if scenario.get("required_hooks"):
                validate_runtime_metadata(
                    metadata_path, name, list(scenario["required_hooks"])
                )
            else:
                metadata = read_metadata(metadata_path)
                if metadata.get("scenario") != [name]:
                    errors.append(f"runtime metadata scenario mismatch: {name}")
            report = load_json(report_path)
        except (CoverageError, OSError, json.JSONDecodeError, ReleaseAuditError) as exc:
            errors.append(f"runtime scenario {name}: {exc}")
            continue
        if report.get("scenario") != name:
            errors.append(f"runtime report scenario mismatch: {name}")
        if report.get("rom_sha1") != expected_sha1:
            errors.append(f"runtime ROM identity mismatch: {name}")
        if report.get("executed_bytes_outside_ghidra_code") != 0:
            errors.append(f"runtime/static disagreement: {name}")

    try:
        suite = load_json(project_root / runtime["suite_report"])
    except (OSError, json.JSONDecodeError, ReleaseAuditError) as exc:
        errors.append(f"Source 1.0 runtime suite: {exc}")
        return errors
    if suite.get("scenario") != "source-1-suite":
        errors.append("Source 1.0 suite has the wrong scenario name")
    if suite.get("rom_sha1") != expected_sha1:
        errors.append("Source 1.0 suite ROM identity mismatch")
    if suite.get("executed_bytes_outside_ghidra_code") != 0:
        errors.append("Source 1.0 suite executed bytes outside Ghidra code")
    if int(suite.get("runtime_code_bytes", 0)) < runtime["minimum_code_bytes"]:
        errors.append("Source 1.0 runtime code coverage regressed")
    if int(suite.get("executed_instruction_starts", 0)) < runtime["minimum_instruction_starts"]:
        errors.append("Source 1.0 executed-instruction coverage regressed")
    return errors


def validate_release(
    project_root: Path, manifest_path: Path, require_tag: bool = False
) -> list[str]:
    release = load_json(manifest_path)
    assets = load_json(project_root / "assets" / "manifest.json")
    errors = validate_reference_contract(release, assets)

    try:
        module_count, semantic_bytes, total_bytes = audit_layout(
            project_root / "config" / "source_layout.json", project_root
        )
    except (OSError, ReconstructionError) as exc:
        errors.append(f"semantic source audit: {exc}")
    else:
        source = release["source"]
        if semantic_bytes != source["semantic_prg_bytes"] or total_bytes != semantic_bytes:
            errors.append(
                f"semantic ownership is {semantic_bytes}/{total_bytes}, "
                f"expected {source['semantic_prg_bytes']} complete bytes"
            )
        if module_count < source["minimum_semantic_modules"]:
            errors.append(
                f"semantic module count is {module_count}, "
                f"expected at least {source['minimum_semantic_modules']}"
            )

    try:
        symbol_counts = audit_symbol_maps(
            project_root / "config" / "symbols.json",
            project_root / "config" / "memory_symbols.json",
            project_root / "config" / "source_layout.json",
        )
    except (OSError, ReconstructionError) as exc:
        errors.append(f"symbol map audit: {exc}")
    else:
        observed = dict(
            zip(
                (
                    "prg_symbols",
                    "routines",
                    "memory_symbols",
                    "scoped_memory_symbols",
                ),
                symbol_counts,
            )
        )
        for key, expected in release["source"]["symbol_map"].items():
            if observed[key] != expected:
                errors.append(
                    f"symbol map {key} is {observed[key]}, expected {expected}"
                )

    unknown_text = (project_root / "docs" / "unknowns.md").read_text(encoding="utf-8")
    unknowns = UNKNOWN_ID_RE.findall(unknown_text)
    if len(unknowns) > release["source"]["maximum_open_unknowns"]:
        errors.append(
            f"active unknown registry has {len(unknowns)} entries, "
            f"maximum is {release['source']['maximum_open_unknowns']}"
        )
    if "Status: resolved" in unknown_text:
        errors.append("resolved entry remains in the active unknown registry")

    errors.extend(validate_runtime_contract(project_root, release))

    try:
        debugger = load_json(project_root / "build" / "native" / "debug_symbols.json")
        live_result = (
            project_root / "build" / "native" / "debug_symbols_runtime.txt"
        ).read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError, ReleaseAuditError) as exc:
        errors.append(f"debugger evidence: {exc}")
    else:
        minimum = release["debugger"]
        observed = {
            "minimum_symbols": debugger["record_counts"]["sym"],
            "minimum_source_line_mappings": debugger["record_counts"]["line"],
            "minimum_rom_labels": debugger["rom_label_count"],
            "minimum_ram_labels": debugger["ram_label_count"],
        }
        for key, actual in observed.items():
            if actual < minimum[key]:
                errors.append(f"debugger evidence {key} regressed: {actual}")
        if not live_result.rstrip().endswith("OK"):
            errors.append("live debugger symbol validation did not finish with OK")

    for relative in release["required_documents"]:
        if not (project_root / relative).is_file():
            errors.append(f"required release document is missing: {relative}")

    tracked = git_lines(project_root, "ls-files")
    prohibited = {suffix.lower() for suffix in release["prohibited_tracked_extensions"]}
    for relative in tracked:
        normalized = relative.replace("\\", "/")
        if Path(relative).suffix.lower() in prohibited:
            errors.append(f"private/build payload is tracked: {relative}")
        if normalized.startswith(("assets/generated/", "build/", "tools/ghidra/")):
            errors.append(f"generated artifact is tracked: {relative}")
        if normalized.startswith("src/preservation/"):
            errors.append(f"preservation source remains tracked: {relative}")

    makefile = (project_root / "Makefile").read_text(encoding="utf-8")
    for target in release["release_commands"]:
        if re.search(rf"^{re.escape(target)}\s*:", makefile, re.MULTILINE) is None:
            errors.append(f"release command has no Make target: {target}")

    for tool in ("ca65", "ld65"):
        actual = tool_version(project_root / "bin" / f"{tool}.exe")
        if release["toolchain"][tool] not in actual:
            errors.append(f"unexpected {tool} version: {actual!r}")

    if require_tag:
        if git_lines(project_root, "status", "--porcelain"):
            errors.append("release-tag audit requires a clean worktree")
        branch = git_lines(project_root, "branch", "--show-current")
        if branch != ["main"]:
            errors.append("release-tag audit must run on main")
        tag = release["local_tag"]
        try:
            tag_type = git_lines(project_root, "cat-file", "-t", f"refs/tags/{tag}")
            tag_commit = git_lines(project_root, "rev-parse", f"{tag}^{{commit}}")
            head = git_lines(project_root, "rev-parse", "HEAD")
        except subprocess.CalledProcessError:
            errors.append(f"required annotated release tag is missing: {tag}")
        else:
            if tag_type != ["tag"]:
                errors.append(f"release tag is not annotated: {tag}")
            if tag_commit != head:
                errors.append(f"release tag does not point to HEAD: {tag}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=ROOT)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=ROOT / "config" / "source_reconstruction_1_0.json",
    )
    parser.add_argument("--require-tag", action="store_true")
    args = parser.parse_args()
    try:
        errors = validate_release(
            args.project_root.resolve(), args.manifest.resolve(), args.require_tag
        )
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        print(f"[FAIL] Source Reconstruction 1.0 audit found {len(errors)} error(s)")
        return 1
    print(
        "[OK] Source Reconstruction 1.0 source, ROM, tools, debugger, "
        "runtime, docs, and repository policy agree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
