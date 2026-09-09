#!/usr/bin/env python3
"""Audit the compatible Castle Excellent Source Reconstruction 2.1 release."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
from typing import Any
import unicodedata

from scripts.validation import release_audit
from scripts.validation import release_history
from scripts.validation import source_2_release_audit as source_2


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_SCHEMA_VERSION = 1
RELEASE_STATUSES = {"development", "tag-ready", "tagged"}
PUBLIC_TEXT_SUFFIXES = {
    ".asm",
    ".cfg",
    ".inc",
    ".json",
    ".lua",
    ".md",
    ".mk",
    ".py",
    ".toml",
    ".txt",
    ".yaml",
    ".yml",
}
PUBLIC_TEXT_NAMES = {"Makefile"}
MINOR_METADATA_PATHS = {
    "config/source_reconstruction_2_1.json",
    "docs/source_reconstruction_2_1.md",
}


class Source2MinorAuditError(ValueError):
    """The Source Reconstruction 2.1 release contract is inconsistent."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Source2MinorAuditError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise Source2MinorAuditError(f"expected a JSON object in {path}")
    return document


def git_lines(project_root: Path, *arguments: str) -> list[str]:
    return source_2.git_lines(project_root, *arguments)


def release_terminal(project_root: Path, release: dict[str, Any]) -> str:
    tag = release.get("tag")
    if not tag:
        return "HEAD"
    result = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/tags/{tag}"],
        cwd=project_root,
        check=False,
    )
    if result.returncode != 0:
        return "HEAD"
    target = git_lines(project_root, "rev-parse", f"refs/tags/{tag}^{{commit}}")
    head = git_lines(project_root, "rev-parse", "HEAD")
    return target[0] if target == head else "HEAD"


def validate_release_schema(release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if release.get("schema_version") != MANIFEST_SCHEMA_VERSION:
        errors.append(f"schema_version must be {MANIFEST_SCHEMA_VERSION!r}")
    if release.get("release_line") != "2.x":
        errors.append("release_line must be '2.x'")
    return errors


def validate_public_english_text(project_root: Path) -> list[str]:
    errors: list[str] = []
    for relative in git_lines(project_root, "ls-files"):
        path = project_root / relative
        if (
            path.name not in PUBLIC_TEXT_NAMES
            and path.suffix.lower() not in PUBLIC_TEXT_SUFFIXES
        ):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            errors.append(f"tracked public text is not UTF-8: {relative}")
            continue
        for line_number, line in enumerate(text.splitlines(), start=1):
            non_latin = next(
                (
                    character
                    for character in line
                    if character.isalpha()
                    and "LATIN" not in unicodedata.name(character, "")
                ),
                None,
            )
            if non_latin is not None:
                errors.append(
                    f"non-English public text at {relative}:{line_number} "
                    f"({unicodedata.name(non_latin, 'unknown character')})"
                )
                break
    return errors


def validate_predecessor(
    project_root: Path, release: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    predecessor = release.get("predecessor", {})
    manifest = predecessor.get("manifest")
    tag = predecessor.get("tag")
    commit = predecessor.get("commit")
    if manifest != "config/source_reconstruction_2_0.json":
        errors.append("predecessor manifest must identify Source 2.0")
    path = project_root / str(manifest or "")
    if not path.is_file():
        return errors + ["predecessor manifest is missing"]
    predecessor_release = load_json(path)
    if predecessor_release.get("release") != {
        "name": "Source Reconstruction 2.0",
        "version": "2.0",
    }:
        errors.append("predecessor manifest does not identify Source 2.0")
    if tag != predecessor_release.get("tag"):
        errors.append("predecessor tag disagrees with its manifest")
    try:
        tag_type = git_lines(project_root, "cat-file", "-t", f"refs/tags/{tag}")
        peeled = git_lines(project_root, "rev-parse", f"{tag}^{{commit}}")
        tagged_manifest = subprocess.run(
            ["git", "show", f"{tag}:{manifest}"],
            cwd=project_root,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        ).stdout
    except subprocess.CalledProcessError:
        return errors + ["accepted Source 2.0 annotated tag cannot be resolved"]
    if tag_type != ["tag"]:
        errors.append("accepted Source 2.0 tag is not annotated")
    if peeled != [commit]:
        errors.append("predecessor tag and commit disagree")
    try:
        tagged_document = json.loads(tagged_manifest)
    except json.JSONDecodeError:
        errors.append("predecessor manifest in the accepted tag is invalid JSON")
    else:
        for field in (
            "release",
            "release_kind",
            "tag",
            "profiles",
            "runtime_coverage",
            "artifacts",
        ):
            if tagged_document.get(field) != predecessor_release.get(field):
                errors.append(
                    f"working predecessor {field} differs from the accepted tag"
                )
    return errors


def validate_delta_history(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    predecessor = release.get("predecessor", {}).get("commit")
    history = release.get("delta_history")
    if not isinstance(history, dict):
        return ["delta_history is missing"]
    if history.get("from_exclusive") != predecessor:
        errors.append("delta_history does not start at the predecessor commit")
    through = history.get("through_inclusive")
    count = history.get("commit_count")
    if release.get("status") == "development" and through is None and count == 0:
        return errors
    if not isinstance(through, str) or not through:
        return errors + ["delta_history has no terminal commit"]
    if not isinstance(count, int) or count <= 0:
        return errors + ["delta_history has no positive commit count"]
    commits = git_lines(
        project_root, "rev-list", "--reverse", f"{predecessor}..{through}"
    )
    if not commits or commits[-1] != through:
        errors.append("delta_history terminal commit is not reachable from predecessor")
    if len(commits) != count:
        errors.append(f"delta_history covers {len(commits)} commits, expected {count}")
    boundary = release_terminal(project_root, release)
    trailing = git_lines(project_root, "rev-list", "--reverse", f"{through}..{boundary}")
    for commit in trailing:
        changed = set(
            git_lines(
                project_root,
                "diff-tree",
                "--no-commit-id",
                "--name-only",
                "-r",
                commit,
            )
        )
        if not changed or not changed.issubset(MINOR_METADATA_PATHS):
            errors.append(f"delta_history does not cover substantive commit {commit[:12]}")
    return errors


def validate_candidate_history(
    project_root: Path, release: dict[str, Any]
) -> list[str]:
    """Validate every commit after the predecessor through the candidate tip."""
    predecessor = release.get("predecessor", {}).get("commit")
    if not isinstance(predecessor, str) or not predecessor:
        return ["candidate history has no predecessor commit"]
    return release_history.validate_release_history(
        project_root,
        predecessor,
        terminal=release_terminal(project_root, release),
    )


def validate_inheritance(
    project_root: Path, release: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    predecessor_path = project_root / release["predecessor"]["manifest"]
    predecessor = load_json(predecessor_path)
    for field in ("toolchain", "artifacts", "licensing", "profiles", "runtime_coverage"):
        if release.get(field) != predecessor.get(field):
            errors.append(f"compatible minor must explicitly inherit Source 2.0 {field}")
    if release.get("profile_manifest") != predecessor.get("profile_manifest"):
        errors.append("compatible minor profile manifest differs from Source 2.0")
    inherited_documents = set(predecessor.get("required_documents", []))
    current_documents = set(release.get("required_documents", []))
    if not inherited_documents.issubset(current_documents):
        errors.append("compatible minor omits required Source 2.0 documents")
    inherited_deviations = {
        item.get("rule_id")
        for field in ("layout_deviations", "resolved_layout_deviations")
        for item in predecessor.get(field, [])
        if isinstance(item, dict)
    }
    current_deviations = {
        item.get("rule_id")
        for field in ("layout_deviations", "resolved_layout_deviations")
        for item in release.get(field, [])
        if isinstance(item, dict)
    }
    if not inherited_deviations.issubset(current_deviations):
        errors.append("compatible minor does not account for every inherited deviation")
    return errors


def validate_manifest(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors = validate_release_schema(release)
    if release.get("release") != {
        "name": "Source Reconstruction 2.1",
        "version": "2.1",
    }:
        errors.append("release identity must name Source Reconstruction 2.1 version 2.1")
    if release.get("release_kind") != "compatible_minor":
        errors.append("release_kind must be compatible_minor")
    if release.get("tag") != "source-reconstruction-2.1":
        errors.append("release tag must be source-reconstruction-2.1")
    if release.get("status") not in RELEASE_STATUSES:
        errors.append("release status is invalid")
    errors.extend(validate_predecessor(project_root, release))
    if not release.get("included_scope") or not release.get("excluded_scope"):
        errors.append("included_scope and excluded_scope must both be non-empty")
    delta = release.get("delta", [])
    delta_ids = [item.get("id") for item in delta if isinstance(item, dict)]
    if not delta_ids or len(delta_ids) != len(set(delta_ids)):
        errors.append("delta IDs are empty or duplicated")
    targets = release_audit.project_make_targets(project_root)
    for item in delta:
        if not isinstance(item, dict) or not all(
            item.get(field) for field in ("id", "kind", "summary", "evidence")
        ):
            errors.append(f"delta {item.get('id') if isinstance(item, dict) else None} is incomplete")
            continue
        for evidence in item["evidence"]:
            if evidence not in targets and not (project_root / evidence).is_file():
                errors.append(f"delta {item['id']} names missing evidence: {evidence}")
    for relative in release.get("required_documents", []):
        if not (project_root / relative).is_file():
            errors.append(f"required release document is missing: {relative}")
    for target in release.get("release_commands", []):
        if target not in targets:
            errors.append(f"release command names missing target: {target}")
    required_commands = {
        "format",
        "lint",
        "test",
        "verify",
        "trace",
        "release-check",
        "source-1-check",
        "source-2-check",
        "source-2-minor-check",
        "source-2-minor-pre-tag-check",
        "source-2-minor-tag-check",
    }
    if not required_commands.issubset(set(release.get("release_commands", []))):
        errors.append("release_commands does not cover the stable Source 2.x interface")
    gates = release.get("aggregate_gates", {})
    for phase in ("pre_tag", "post_tag"):
        commands = gates.get(phase, [])
        if not commands:
            errors.append(f"aggregate gate {phase} is empty")
        for command in commands:
            words = command.split()
            if len(words) != 2 or words[0] != "make" or words[1] not in targets:
                errors.append(f"aggregate gate {phase} is invalid: {command}")
    if release.get("provenance", {}).get("private_inputs_tracked") is not False:
        errors.append("provenance must declare private_inputs_tracked false")
    errors.extend(source_2.validate_requirements(project_root, release, targets))
    errors.extend(source_2.validate_profiles(project_root, release))
    errors.extend(source_2.validate_runtime_manifests(project_root, release))
    errors.extend(validate_delta_history(project_root, release))
    errors.extend(validate_inheritance(project_root, release))
    return errors


def validate_release(
    project_root: Path,
    manifest_path: Path,
    *,
    require_clean: bool = False,
    pre_tag: bool = False,
    require_tag: bool = False,
) -> list[str]:
    release = load_json(manifest_path)
    errors = validate_manifest(project_root, release)
    errors.extend(release_audit.validate_toolchain(project_root, release))
    errors.extend(source_2.validate_artifacts(project_root, release))
    errors.extend(source_2.validate_repository_policy(project_root))
    errors.extend(validate_public_english_text(project_root))
    errors.extend(validate_candidate_history(project_root, release))
    if require_clean and git_lines(project_root, "status", "--porcelain"):
        errors.append("release audit requires a clean worktree")
    if pre_tag:
        errors.extend(source_2.validate_pre_tag(project_root, release))
    if require_tag:
        errors.extend(source_2.validate_tag(project_root, release))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=ROOT)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=ROOT / "config" / "source_reconstruction_2_1.json",
    )
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--pre-tag", action="store_true")
    parser.add_argument("--require-tag", action="store_true")
    args = parser.parse_args()
    try:
        errors = validate_release(
            args.project_root.resolve(),
            args.manifest.resolve(),
            require_clean=args.require_clean,
            pre_tag=args.pre_tag,
            require_tag=args.require_tag,
        )
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        print(f"[FAIL] Source Reconstruction 2.1 audit found {len(errors)} error(s)")
        return 1
    print(
        "[OK] Source Reconstruction 2.1 contract, predecessor, delta, profiles, "
        "artifacts, runtime, history, and repository policy agree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
