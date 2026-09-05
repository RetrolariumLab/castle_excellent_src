#!/usr/bin/env python3
"""Run the pinned GhidraNes headless import and project scripts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

import project


ROOT = Path(__file__).resolve().parent.parent
HEADLESS = ROOT / "tools" / "ghidra" / "support" / "analyzeHeadless.bat"
SCRIPT_DIR = ROOT / "tools" / "ghidra_scripts"
PROJECT_DIR = ROOT / "build" / "ghidra"


class PipelineError(ValueError):
    pass


def clear_project_state(project_dir: Path, project_name: str) -> None:
    """Remove only Ghidra's disposable project pair, preserving exported facts."""
    marker = project_dir / f"{project_name}.gpr"
    repository = project_dir / f"{project_name}.rep"
    if marker.exists():
        if not marker.is_file():
            raise PipelineError(f"Ghidra project marker is not a file: {marker}")
        marker.unlink()
    if repository.exists():
        if not repository.is_dir():
            raise PipelineError(f"Ghidra project repository is not a directory: {repository}")
        shutil.rmtree(repository)


def validate_reference(path: Path) -> None:
    manifest = project.load_manifest(ROOT / "assets" / "manifest.json")
    project.validate_image(path.read_bytes(), manifest)


def run_headless(image: Path, scripts: list[tuple[str, list[str]]]) -> None:
    if not HEADLESS.is_file():
        raise PipelineError("local Ghidra is missing; run make ghidra-bootstrap")
    if not image.is_file():
        raise PipelineError(f"reference ROM not found: {image}")
    validate_reference(image)
    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    clear_project_state(PROJECT_DIR, "castle_excellent")
    staged_image = PROJECT_DIR / "input.nes"
    shutil.copyfile(image, staged_image)
    command = [
        str(HEADLESS),
        str(PROJECT_DIR),
        "castle_excellent",
        "-import",
        str(staged_image.resolve()),
        "-overwrite",
        "-analysisTimeoutPerFile",
        "600",
        "-scriptPath",
        str(SCRIPT_DIR.resolve()),
    ]
    for script, arguments in scripts:
        command.extend(("-postScript", script, *arguments))
    command.append("-deleteProject")
    result = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        errors="replace",
    )
    log = PROJECT_DIR / "headless.log"
    log.write_text(result.stdout + result.stderr, encoding="utf-8", newline="\n")
    for line in (result.stdout + result.stderr).splitlines():
        if "[OK]" in line:
            print(line.strip())
    if result.returncode:
        print("\n".join((result.stdout + result.stderr).splitlines()[-80:]))
        raise PipelineError(f"Ghidra headless analysis failed with {result.returncode}")


def command_inspect(args: argparse.Namespace) -> None:
    output = Path(args.output).resolve()
    run_headless(Path(args.image), [("InspectNesProgram.java", [str(output)])])
    try:
        report = json.loads(output.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PipelineError(f"cannot read Ghidra report {output}: {exc}") from exc
    print(
        f"[OK] {report['language']}: {report['instruction_count']} instructions, "
        f"{len(report['functions'])} functions, {len(report['blocks'])} memory blocks"
    )


def command_export_facts(args: argparse.Namespace) -> None:
    output = Path(args.output).resolve()
    scripts: list[tuple[str, list[str]]] = []
    if args.false_instructions:
        false_instructions = Path(args.false_instructions).resolve()
        if not false_instructions.is_file():
            raise PipelineError(
                f"false-instruction registry not found: {false_instructions}"
            )
        scripts.append(
            ("ClearFalseInstructions.java", [str(false_instructions)])
        )
    if args.static_evidence:
        evidence = Path(args.static_evidence).resolve()
        if not evidence.is_file():
            raise PipelineError(f"static code evidence not found: {evidence}")
        scripts.append(("ApplyCodeEvidence.java", [str(evidence), "static"]))
    if args.runtime_evidence:
        evidence = Path(args.runtime_evidence).resolve()
        if not evidence.is_file():
            raise PipelineError(f"runtime evidence not found: {evidence}")
        scripts.append(("ApplyCodeEvidence.java", [str(evidence), "runtime"]))
    if args.data_ranges:
        data_ranges = Path(args.data_ranges).resolve()
        if not data_ranges.is_file():
            raise PipelineError(f"typed data ranges not found: {data_ranges}")
        scripts.append(("ClearKnownData.java", [str(data_ranges)]))
    scripts.append(("ExportInstructionFacts.java", [str(output)]))
    run_headless(Path(args.image), scripts)
    if not output.is_file():
        raise PipelineError(f"Ghidra facts file was not created: {output}")
    instruction_count = max(0, len(output.read_text(encoding="utf-8").splitlines()) - 1)
    print(f"[OK] exported {instruction_count} analyzed PRG instructions to {output}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    inspect = subparsers.add_parser("inspect")
    inspect.add_argument("--image", required=True)
    inspect.add_argument("--output", default="build/ghidra/program.json")
    inspect.set_defaults(handler=command_inspect)
    facts = subparsers.add_parser("export-facts")
    facts.add_argument("--image", required=True)
    facts.add_argument("--output", default="build/ghidra/instructions.tsv")
    facts.add_argument("--static-evidence")
    facts.add_argument("--runtime-evidence")
    facts.add_argument("--data-ranges")
    facts.add_argument("--false-instructions")
    facts.set_defaults(handler=command_export_facts)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (OSError, PipelineError, project.ProjectError) as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
