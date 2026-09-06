#!/usr/bin/env python3
"""Audit the Castle Excellent Source Reconstruction 2.0 release contract."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from typing import Any

import release_audit


ROOT = Path(__file__).resolve().parent.parent
CONTRACT_SCHEMA = "retrolarium.source_reconstruction_release_contract"
CONTRACT_VERSION = 3
CONTRACT_SHA256 = "d07f16f12e09c6ea2691e736088f09da5eace82c6a014c774c8a33e52804086d"
RELEASE_STATUSES = {"development", "tag-ready", "tagged"}
REQUIREMENT_STATUSES = {
    "satisfied",
    "not_applicable",
    "partial",
    "unsupported",
    "planned",
}


class Source2AuditError(ValueError):
    """The Source Reconstruction 2.0 release contract is inconsistent."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Source2AuditError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise Source2AuditError(f"expected a JSON object in {path}")
    return document


def digest(path: Path, algorithm: str = "sha256") -> str:
    checksum = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


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


def validate_requirements(
    project_root: Path,
    release: dict[str, Any],
    targets: set[str],
) -> list[str]:
    errors: list[str] = []
    requirements = release.get("requirements")
    if not isinstance(requirements, dict) or not requirements:
        return ["requirements registry is empty"]
    excluded_ids = {
        item.get("id")
        for item in release.get("excluded_scope", [])
        if isinstance(item, dict)
    }
    artifact_ids = {
        item.get("id")
        for item in release.get("artifacts", [])
        if isinstance(item, dict)
    }
    for identifier, requirement in requirements.items():
        if not isinstance(requirement, dict):
            errors.append(f"requirement {identifier} is not an object")
            continue
        status = requirement.get("status")
        if status not in REQUIREMENT_STATUSES:
            errors.append(f"requirement {identifier} has invalid status {status!r}")
        evidence = requirement.get("evidence")
        if not isinstance(evidence, dict):
            errors.append(f"requirement {identifier} has no evidence object")
            continue
        if status == "satisfied" and not any(evidence.get(field) for field in evidence):
            errors.append(f"requirement {identifier} has no evidence")
        if status == "not_applicable":
            if not requirement.get("reason"):
                errors.append(f"requirement {identifier} has no not-applicable reason")
            if requirement.get("excluded_scope") not in excluded_ids:
                errors.append(f"requirement {identifier} has no matching excluded scope")
        for target in evidence.get("targets", []):
            if target not in targets:
                errors.append(f"requirement {identifier} names missing target: {target}")
        for relative in evidence.get("files", []):
            if not (project_root / relative).is_file():
                errors.append(f"requirement {identifier} names missing file: {relative}")
        for relative in evidence.get("scenarios", []):
            if not (project_root / relative).is_file():
                errors.append(f"requirement {identifier} names missing scenario: {relative}")
        for artifact in evidence.get("artifacts", []):
            if artifact not in artifact_ids:
                errors.append(f"requirement {identifier} names unknown artifact: {artifact}")
    if release.get("status") in {"tag-ready", "tagged"}:
        unfinished = [
            identifier
            for identifier, requirement in requirements.items()
            if requirement.get("status") not in {"satisfied", "not_applicable"}
        ]
        if unfinished:
            errors.append(f"tag-ready release has unfinished requirements: {unfinished}")
    return errors


def validate_profiles(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    profile_path = project_root / release.get("profile_manifest", "")
    profiles = load_json(profile_path)
    declared = {
        item["id"]: item
        for item in release.get("profiles", [])
        if isinstance(item, dict) and item.get("status") == "supported"
    }
    actual = {
        item["id"]: item
        for item in profiles.get("profiles", [])
        if isinstance(item, dict) and item.get("status") == "supported"
    }
    if set(declared) != set(actual):
        errors.append(
            f"supported release profiles {sorted(declared)} disagree with revision profiles {sorted(actual)}"
        )
    artifacts = {
        item.get("id"): item
        for item in release.get("artifacts", [])
        if isinstance(item, dict)
    }
    for identifier, profile in declared.items():
        if profile.get("identity") != "byte-identical":
            errors.append(f"profile {identifier} is not byte-identical")
        artifact = artifacts.get(profile.get("artifact"))
        actual_profile = actual.get(identifier)
        if artifact is None or actual_profile is None:
            continue
        comparisons = {
            "path": actual_profile.get("output_rom"),
            "size": actual_profile.get("rom_size"),
            "sha1": actual_profile.get("rom_sha1"),
            "sha256": actual_profile.get("rom_sha256"),
        }
        for field, expected in comparisons.items():
            if artifact.get(field) != expected:
                errors.append(f"profile {identifier} artifact {field} disagrees")
    covered = {
        item.get("profile_id")
        for item in release.get("runtime_coverage", [])
        if isinstance(item, dict)
        and item.get("mode") in {"direct", "runtime_equivalent_to"}
    }
    if set(declared) - covered:
        errors.append(f"profiles lack runtime coverage: {sorted(set(declared) - covered)}")
    for coverage in release.get("runtime_coverage", []):
        manifest = coverage.get("manifest")
        if not manifest or not (project_root / manifest).is_file():
            errors.append(f"runtime manifest is missing for {coverage.get('profile_id')}")
    return errors


def validate_artifacts(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for artifact in release.get("artifacts", []):
        path = project_root / artifact["path"]
        if not path.is_file():
            errors.append(f"release artifact is missing: {artifact['path']}")
            continue
        if path.stat().st_size != artifact["size"]:
            errors.append(f"release artifact size mismatch: {artifact['id']}")
        for algorithm in ("sha1", "sha256"):
            if digest(path, algorithm) != artifact[algorithm]:
                errors.append(f"release artifact {algorithm} mismatch: {artifact['id']}")
    return errors


def validate_manifest(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    expected_contract = {
        "schema": CONTRACT_SCHEMA,
        "version": CONTRACT_VERSION,
        "release_line": "2.0",
        "source_document_sha256": CONTRACT_SHA256,
    }
    contract = release.get("contract", {})
    for field, expected in expected_contract.items():
        if contract.get(field) != expected:
            errors.append(f"contract {field} must be {expected!r}")
    if release.get("release") != {
        "name": "Source Reconstruction 2.0",
        "version": "2.0",
    }:
        errors.append("release identity must name Source Reconstruction 2.0 version 2.0")
    if release.get("release_kind") != "baseline":
        errors.append("release_kind must be baseline")
    if release.get("tag") != "source-reconstruction-2.0":
        errors.append("release tag must be source-reconstruction-2.0")
    if release.get("status") not in RELEASE_STATUSES:
        errors.append("release status is invalid")
    predecessor = release.get("predecessor", {})
    if predecessor.get("manifest") != "config/source_reconstruction_1_0.json":
        errors.append("predecessor manifest must identify Source 1.0")
    if predecessor.get("tag") != "source-reconstruction-1.0":
        errors.append("predecessor tag must identify Source 1.0")
    if not (project_root / str(predecessor.get("manifest", ""))).is_file():
        errors.append("predecessor manifest is missing")
    try:
        peeled = git_lines(project_root, "rev-parse", f"{predecessor.get('tag')}^{{commit}}")
    except subprocess.CalledProcessError:
        errors.append("predecessor tag cannot be resolved")
    else:
        if peeled != [predecessor.get("commit")]:
            errors.append("predecessor tag and commit disagree")
    if not release.get("included_scope"):
        errors.append("included_scope is empty")
    if not release.get("excluded_scope"):
        errors.append("excluded_scope is empty")
    delta = release.get("delta", [])
    delta_ids = [item.get("id") for item in delta if isinstance(item, dict)]
    if not delta_ids or len(delta_ids) != len(set(delta_ids)):
        errors.append("delta IDs are empty or duplicated")
    makefile = (project_root / "Makefile").read_text(encoding="utf-8")
    targets = release_audit.make_targets(makefile)
    for item in delta:
        if not item.get("summary") or not item.get("kind") or not item.get("evidence"):
            errors.append(f"delta {item.get('id')} is incomplete")
        for evidence in item.get("evidence", []):
            if evidence not in targets and not (project_root / evidence).is_file():
                errors.append(f"delta {item.get('id')} names missing evidence: {evidence}")
    for relative in release.get("required_documents", []):
        if not (project_root / relative).is_file():
            errors.append(f"required release document is missing: {relative}")
    gates = release.get("aggregate_gates", release.get("planned_aggregate_gates", {}))
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
    errors.extend(validate_requirements(project_root, release, targets))
    errors.extend(validate_profiles(project_root, release))
    return errors


def validate_repository_policy(project_root: Path) -> list[str]:
    errors: list[str] = []
    prohibited_suffixes = {".nes", ".fds", ".rom", ".bin", ".chr"}
    for relative in git_lines(project_root, "ls-files"):
        normalized = relative.replace("\\", "/")
        if Path(relative).suffix.lower() in prohibited_suffixes:
            errors.append(f"private or generated binary is tracked: {relative}")
        if normalized.startswith(("assets/generated/", "build/", "content/workspace/")):
            errors.append(f"generated or local artifact is tracked: {relative}")
    return errors


def validate_pre_tag(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if release.get("status") != "tag-ready":
        errors.append("pre-tag audit requires manifest status tag-ready")
    if git_lines(project_root, "status", "--porcelain"):
        errors.append("pre-tag audit requires a clean worktree")
    tag = release["tag"]
    local = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/tags/{tag}"],
        cwd=project_root,
        check=False,
    )
    if local.returncode == 0:
        errors.append(f"future release tag already exists locally: {tag}")
    remotes = git_lines(project_root, "remote")
    if remotes:
        remote_tags = git_lines(
            project_root, "ls-remote", "--tags", remotes[0], f"refs/tags/{tag}"
        )
        if remote_tags:
            errors.append(f"future release tag already exists on {remotes[0]}: {tag}")
    errors.extend(release_audit.validate_commit_history(project_root, release))
    return errors


def validate_tag(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if git_lines(project_root, "status", "--porcelain"):
        errors.append("post-tag audit requires a clean worktree")
    tag = release["tag"]
    try:
        tag_type = git_lines(project_root, "cat-file", "-t", f"refs/tags/{tag}")
        target = git_lines(project_root, "rev-parse", f"{tag}^{{commit}}")
        head = git_lines(project_root, "rev-parse", "HEAD")
    except subprocess.CalledProcessError:
        return [f"required annotated release tag is missing: {tag}"]
    if tag_type != ["tag"]:
        errors.append(f"release tag is not annotated: {tag}")
    if target != head:
        errors.append(f"release tag does not point to HEAD: {tag}")
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
    errors.extend(validate_artifacts(project_root, release))
    errors.extend(validate_repository_policy(project_root))
    if require_clean and git_lines(project_root, "status", "--porcelain"):
        errors.append("release audit requires a clean worktree")
    if pre_tag:
        errors.extend(validate_pre_tag(project_root, release))
    if require_tag:
        errors.extend(validate_tag(project_root, release))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=ROOT)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=ROOT / "config" / "source_reconstruction_2_0.json",
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
        print(f"[FAIL] Source Reconstruction 2.0 audit found {len(errors)} error(s)")
        return 1
    print(
        "[OK] Source Reconstruction 2.0 predecessor, profiles, artifacts, "
        "authoring, runtime, docs, history, and repository policy agree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
