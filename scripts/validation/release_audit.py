#!/usr/bin/env python3
"""Audit the Castle Excellent Source Reconstruction 1.0 contract."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Any

from scripts.runtime.runtime_coverage import (
    CoverageError,
    read_metadata,
    validate_runtime_metadata,
)
from scripts.validation.source_reconstruction import (
    ReconstructionError,
    audit_layout,
    audit_symbol_maps,
)
from scripts.validation import release_history


ROOT = Path(__file__).resolve().parents[2]
UNKNOWN_ID_RE = re.compile(r"^### ([A-Z]+-[0-9]+) - ", re.MULTILINE)
MANIFEST_SCHEMA_VERSION = 1
RELEASE_STATUSES = {"development", "tag-ready", "tagged"}
REQUIREMENT_STATUSES = {
    "satisfied",
    "not_applicable",
    "partial",
    "unsupported",
    "planned",
}


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


def digest(path: Path, algorithm: str = "sha256") -> str:
    checksum = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def make_targets(makefile: str) -> set[str]:
    return {
        match.group(1)
        for match in re.finditer(r"^([A-Za-z0-9][A-Za-z0-9_.-]*)\s*:", makefile, re.MULTILINE)
    }


def phony_targets(make_database: str) -> set[str]:
    targets: set[str] = set()
    for match in re.finditer(r"^\.PHONY:\s*(.*)$", make_database, re.MULTILINE):
        targets.update(match.group(1).split())
    return targets


def project_make_targets(project_root: Path) -> set[str]:
    result = subprocess.run(
        ["make", "-qp"],
        cwd=project_root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode not in (0, 1):
        raise ReleaseAuditError(f"cannot inspect Make targets: {result.stderr.strip()}")
    targets = phony_targets(result.stdout)
    if not targets:
        raise ReleaseAuditError("Make database contains no phony targets")
    return targets


def validate_reference_contract(
    release: dict[str, Any], assets: dict[str, Any]
) -> list[str]:
    expected = release["reference"]
    actual = assets["reference_rom"]
    comparisons = {
        "ROM SHA-256": (expected["rom_sha256"], actual["file_sha256"]),
        "ROM SHA-1": (expected["rom_sha1"], actual["file_sha1"]),
        "header SHA-256": (expected["header_sha256"], actual["header_sha256"]),
        "PRG SHA-256": (expected["prg_sha256"], actual["prg_sha256"]),
        "PRG SHA-1": (expected["prg_sha1"], actual["prg_sha1"]),
        "CHR SHA-256": (expected["chr_sha256"], actual["chr_sha256"]),
        "CHR SHA-1": (expected["chr_sha1"], actual["chr_sha1"]),
        "mapper": (expected["mapper"], actual["mapper"]),
        "mirroring": (expected["mirroring"], actual["mirroring"]),
    }
    return [
        f"{name} contract mismatch: release={left}, assets={right}"
        for name, (left, right) in comparisons.items()
        if left != right
    ]


def validate_manifest_contract(
    project_root: Path, release: dict[str, Any], targets: set[str]
) -> list[str]:
    errors: list[str] = []
    if release.get("schema_version") != MANIFEST_SCHEMA_VERSION:
        errors.append(f"schema_version must be {MANIFEST_SCHEMA_VERSION!r}")
    if release.get("release_line") != "1.0":
        errors.append("release_line must be '1.0'")

    release_identity = release.get("release", {})
    if release_identity != {"name": "Source Reconstruction 1.0", "version": "1.0"}:
        errors.append("release identity must name Source Reconstruction 1.0 version 1.0")
    if release.get("release_kind") != "preservation":
        errors.append("release_kind must be preservation")
    if release.get("tag") != "source-reconstruction-1.0":
        errors.append("release tag must be source-reconstruction-1.0")
    if release.get("status") not in RELEASE_STATUSES:
        errors.append("release status is invalid")

    predecessor = release.get("predecessor", {})
    if any(predecessor.get(key) is not None for key in ("manifest", "tag", "commit")):
        errors.append("the first Source 1.0 release must not claim a predecessor")
    if not predecessor.get("reason"):
        errors.append("the absent predecessor requires a reason")

    if not release.get("included_scope"):
        errors.append("included_scope is empty")
    excluded = release.get("excluded_scope", [])
    excluded_ids = {item.get("id") for item in excluded if isinstance(item, dict)}
    if "castlequest-and-regional-profiles" not in excluded_ids:
        errors.append("regional profiles are not explicitly excluded")
    if not release.get("delta"):
        errors.append("first-release delta is empty")

    artifact_ids = {
        item.get("id") for item in release.get("artifacts", []) if isinstance(item, dict)
    }
    coverage = release.get("runtime_coverage", [])
    scenario_ids = {
        scenario
        for item in coverage
        if isinstance(item, dict)
        for scenario in item.get("scenarios", [])
    }
    requirements = release.get("requirements", {})
    if not requirements:
        errors.append("requirements registry is empty")
    for requirement_id, requirement in requirements.items():
        status = requirement.get("status")
        if status not in REQUIREMENT_STATUSES:
            errors.append(f"requirement {requirement_id} has invalid status {status!r}")
        evidence = requirement.get("evidence", {})
        if status == "satisfied" and not any(evidence.get(kind) for kind in ("targets", "files", "scenarios", "artifacts")):
            errors.append(f"requirement {requirement_id} has no evidence")
        for target in evidence.get("targets", []):
            if target not in targets:
                errors.append(f"requirement {requirement_id} names missing target: {target}")
        for relative in evidence.get("files", []):
            if not (project_root / relative).is_file():
                errors.append(f"requirement {requirement_id} names missing file: {relative}")
        for scenario in evidence.get("scenarios", []):
            if scenario not in scenario_ids:
                errors.append(f"requirement {requirement_id} names unknown scenario: {scenario}")
        for artifact in evidence.get("artifacts", []):
            if artifact not in artifact_ids:
                errors.append(f"requirement {requirement_id} names unknown artifact: {artifact}")

    supported = {
        item.get("id")
        for item in release.get("profiles", [])
        if isinstance(item, dict) and item.get("status") == "supported"
    }
    covered = {
        item.get("profile_id")
        for item in coverage
        if isinstance(item, dict) and item.get("mode") in {"direct", "runtime_equivalent_to"}
    }
    if not supported:
        errors.append("no supported release profile is declared")
    if supported - covered:
        errors.append(f"supported profiles lack runtime coverage: {sorted(supported - covered)}")
    for item in coverage:
        if item.get("mode") != "direct":
            errors.append(f"Source 1.0 profile {item.get('profile_id')} must use direct runtime coverage")

    gates = release.get("aggregate_gates", {})
    for phase in ("pre_tag", "post_tag"):
        commands = gates.get(phase, [])
        if not commands:
            errors.append(f"aggregate_gates.{phase} is empty")
        for command in commands:
            parts = command.split()
            if len(parts) != 2 or parts[0] != "make" or parts[1] not in targets:
                errors.append(f"aggregate_gates.{phase} has invalid command: {command}")

    for deviation in release.get("layout_deviations", []):
        for field in ("rule_id", "actual_path", "reason", "equivalent_control"):
            if not deviation.get(field):
                errors.append(f"layout deviation is missing {field}")
    categories = {
        item.get("category")
        for item in release.get("licensing", [])
        if isinstance(item, dict)
    }
    required_categories = {
        "project_authored_material",
        "reconstructed_game_source",
        "bundled_external_tools",
        "external_tools",
        "private_user_supplied_inputs",
    }
    if categories != required_categories:
        errors.append("licensing does not classify every required component category")
    if release.get("provenance", {}).get("private_inputs_tracked") is not False:
        errors.append("provenance must declare private_inputs_tracked false")
    errors.extend(validate_release_commands(release, targets))
    return errors


def validate_release_commands(
    release: dict[str, Any], targets: set[str]
) -> list[str]:
    return [
        f"release command has no Make target: {target}"
        for target in release.get("release_commands", [])
        if target not in targets
    ]


def validate_scenario_document(
    project_root: Path, relative: str, declared: dict[str, Any]
) -> list[str]:
    errors: list[str] = []
    path = project_root / relative
    document = load_json(path)
    scenarios = document.get("scenarios", [])
    if document.get("profile_id") != declared["profile_id"]:
        errors.append("scenario manifest profile does not match runtime coverage")
    ids = [item.get("id") for item in scenarios if isinstance(item, dict)]
    if len(ids) != len(set(ids)):
        errors.append("scenario manifest contains duplicate IDs")
    if ids != declared["scenarios"]:
        errors.append("scenario manifest IDs/order do not match runtime coverage")
    for scenario in scenarios:
        scenario_id = scenario.get("id", "<missing>")
        for field in ("capture", "maximum_frames", "start_condition", "expected_result", "required_hooks", "controlled_patches"):
            if field not in scenario:
                errors.append(f"scenario {scenario_id} is missing {field}")
        capture = scenario.get("capture")
        if capture and not (project_root / capture).is_file():
            errors.append(f"scenario {scenario_id} capture is missing: {capture}")
        if int(scenario.get("maximum_frames", 0)) <= 0:
            errors.append(f"scenario {scenario_id} has no positive frame budget")
    return errors


def validate_scenario_manifest(project_root: Path, release: dict[str, Any]) -> list[str]:
    return validate_scenario_document(
        project_root,
        release["runtime"]["scenarios_manifest"],
        release["runtime_coverage"][0],
    )


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


def resolve_selected_executable(project_root: Path, selected: str | Path) -> Path:
    path = Path(selected)
    if path.is_absolute():
        return path.resolve()
    project_path = (project_root / path).resolve()
    if project_path.is_file():
        return project_path
    located = shutil.which(str(selected))
    return Path(located).resolve() if located else project_path


def validate_build_toolchain(
    project_root: Path,
    release: dict[str, Any],
    selected_executables: dict[str, str | Path] | None = None,
) -> list[str]:
    errors: list[str] = []
    components = release["toolchain"].get("components", [])
    by_id = {item["id"]: item for item in components}
    selected_executables = selected_executables or {}
    for component_id in ("ca65", "ld65"):
        component = by_id.get(component_id)
        if component is None:
            errors.append(f"build toolchain component is missing: {component_id}")
            continue
        selected = selected_executables.get(component_id) or component["binary"]
        path = resolve_selected_executable(project_root, selected)
        if not path.is_file():
            errors.append(f"selected {component_id} executable is missing: {selected}")
            continue
        valid_identity = True
        if path.stat().st_size != component["binary_size"]:
            errors.append(f"selected toolchain binary size mismatch: {component_id}")
            valid_identity = False
        if digest(path) != component["binary_sha256"]:
            errors.append(f"selected toolchain binary SHA-256 mismatch: {component_id}")
            valid_identity = False
        if not valid_identity:
            continue
        actual = tool_version(path)
        if component["version"] not in actual:
            errors.append(f"unexpected {component_id} version: {actual!r}")
    return errors


def validate_toolchain(project_root: Path, release: dict[str, Any]) -> list[str]:
    errors = validate_build_toolchain(project_root, release)
    components = release["toolchain"].get("components", [])
    ids = [item.get("id") for item in components]
    if set(ids) != {"ca65", "ld65", "ghidra", "ghidranes", "fceux"}:
        errors.append("toolchain component set is incomplete")
    for component in components:
        component_id = component["id"]
        if not component.get("version") or not component.get("source"):
            errors.append(f"toolchain component {component_id} lacks version/source")
        binary = component.get("binary")
        if binary and component_id not in {"ca65", "ld65"}:
            path = project_root / binary
            if not path.is_file():
                errors.append(f"toolchain binary is missing: {binary}")
                continue
            if path.stat().st_size != component["binary_size"]:
                errors.append(f"toolchain binary size mismatch: {component_id}")
            if digest(path) != component["binary_sha256"]:
                errors.append(f"toolchain binary SHA-256 mismatch: {component_id}")
    hosts = release["toolchain"].get("hosts", [])
    if not hosts or not any(host.get("supported_status") == "supported" for host in hosts):
        errors.append("toolchain has no supported host contract")

    by_id = {item["id"]: item for item in components}
    disassembly_lock = load_json(project_root / "tools" / "disassembly.lock.json")
    lock_pairs = (("ghidra", "ghidra"), ("ghidranes", "nes_loader"))
    for component_id, lock_id in lock_pairs:
        component = by_id.get(component_id, {})
        locked = disassembly_lock.get(lock_id, {})
        if component.get("version") != locked.get("version"):
            errors.append(f"{component_id} version differs from disassembly lock")
        if component.get("archive_sha256") != locked.get("sha256"):
            errors.append(f"{component_id} archive SHA-256 differs from disassembly lock")
        if component.get("source_commit") != locked.get("commit"):
            errors.append(f"{component_id} source commit differs from disassembly lock")

    runtime_lock = load_json(project_root / "tools" / "runtime.lock.json")["fceux"]
    fceux = by_id.get("fceux", {})
    executable = next(
        (item for item in runtime_lock["files"] if item["install"] == "fceux64.exe"),
        {},
    )
    if fceux.get("source_commit") != runtime_lock.get("commit"):
        errors.append("FCEUX source commit differs from runtime lock")
    if fceux.get("binary_size") != executable.get("size"):
        errors.append("FCEUX binary size differs from runtime lock")
    if fceux.get("binary_sha256") != executable.get("sha256"):
        errors.append("FCEUX binary SHA-256 differs from runtime lock")
    return errors


def validate_commit_history(
    project_root: Path,
    release: dict[str, Any],
    terminal: str = "HEAD",
) -> list[str]:
    predecessor = release["predecessor"].get("commit")
    return release_history.validate_release_history(
        project_root, predecessor, terminal=terminal
    )


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
        remote = remotes[0]
        remote_tags = git_lines(
            project_root, "ls-remote", "--tags", remote, f"refs/tags/{tag}"
        )
        if remote_tags:
            errors.append(f"future release tag already exists on {remote}: {tag}")
    errors.extend(validate_commit_history(project_root, release))
    return errors


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
    project_root: Path,
    manifest_path: Path,
    require_tag: bool = False,
    pre_tag: bool = False,
    require_clean: bool = False,
) -> list[str]:
    release = load_json(manifest_path)
    assets = load_json(project_root / "assets" / "manifest.json")
    targets = project_make_targets(project_root)
    errors = validate_manifest_contract(project_root, release, targets)
    errors.extend(validate_reference_contract(release, assets))
    errors.extend(validate_scenario_manifest(project_root, release))
    errors.extend(validate_artifacts(project_root, release))
    errors.extend(validate_toolchain(project_root, release))

    try:
        module_count, semantic_bytes, total_bytes = audit_layout(
            project_root / "config" / "reconstruction" / "source_layout.json",
            project_root,
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
            project_root / "config" / "reconstruction" / "symbols.json",
            project_root / "config" / "reconstruction" / "memory_symbols.json",
            project_root / "config" / "reconstruction" / "source_layout.json",
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

    if require_clean and git_lines(project_root, "status", "--porcelain"):
        errors.append("release audit requires a clean worktree")

    if pre_tag:
        errors.extend(validate_pre_tag(project_root, release))

    if require_tag:
        if git_lines(project_root, "status", "--porcelain"):
            errors.append("release-tag audit requires a clean worktree")
        tag = release["tag"]
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
    parser.add_argument("--pre-tag", action="store_true")
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--build-tools-only", action="store_true")
    parser.add_argument("--ca65")
    parser.add_argument("--ld65")
    args = parser.parse_args()
    try:
        if args.build_tools_only:
            release = load_json(args.manifest.resolve())
            errors = validate_build_toolchain(
                args.project_root.resolve(),
                release,
                {"ca65": args.ca65, "ld65": args.ld65},
            )
        else:
            errors = validate_release(
                args.project_root.resolve(),
                args.manifest.resolve(),
                args.require_tag,
                args.pre_tag,
                args.require_clean,
            )
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        print(f"[FAIL] Source Reconstruction 1.0 audit found {len(errors)} error(s)")
        return 1
    if args.build_tools_only:
        print("[OK] pinned ca65 and ld65 binaries match the release manifest")
        return 0
    print(
        "[OK] Source Reconstruction 1.0 source, ROM, tools, debugger, "
        "runtime, docs, and repository policy agree"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
