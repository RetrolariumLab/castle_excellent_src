#!/usr/bin/env python3
"""Run a real public Make command from a disposable tracked-only clone."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]


class PublicCommandSmokeError(RuntimeError):
    """A disposable public command did not complete successfully."""


VALID_EMPTY_COMMIT_MESSAGE = """Exercise empty-commit rejection

Create a synthetic release-history boundary without changing its tracked tree.

Verify that the public audit propagates the object-level validation failure.

Co-Authored-By: Codex <noreply@openai.com>
"""


def _resolve_make(make_executable: str | None) -> str:
    make = make_executable or shutil.which("make")
    if not make:
        raise PublicCommandSmokeError("make executable not found")
    return make


def _clone_repository(project_root: Path, clone: Path) -> None:
    clone.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            "git",
            "clone",
            "--quiet",
            "--shared",
            "--no-local",
            str(project_root.resolve()),
            str(clone),
        ],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        raise PublicCommandSmokeError(
            f"cannot create disposable clone: {result.stderr.strip()}"
        )


def _run_make(
    project_root: Path,
    make: str,
    target: str,
    *arguments: str,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [make, target, *arguments],
        cwd=project_root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def run_disposable_make(
    project_root: Path,
    target: str = "lint",
    *,
    make_executable: str | None = None,
) -> str:
    make = _resolve_make(make_executable)
    with tempfile.TemporaryDirectory(prefix="castle-public-command-") as directory:
        clone = Path(directory) / "build" / "repository"
        _clone_repository(project_root, clone)
        result = _run_make(clone, make, target)
        if result.returncode != 0:
            details = (result.stdout + result.stderr).strip()
            raise PublicCommandSmokeError(
                f"public command 'make {target}' failed in disposable clone:\n{details}"
            )
        status = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=clone,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        ).stdout.strip()
        if status:
            raise PublicCommandSmokeError(
                f"public command 'make {target}' changed the disposable worktree"
            )
        return result.stdout


def run_disposable_empty_commit_rejection(
    project_root: Path,
    target: str = "source-2-minor-audit",
    *,
    make_executable: str | None = None,
) -> str:
    """Require the public release audit to reject a real empty Git commit."""
    make = _resolve_make(make_executable)
    with tempfile.TemporaryDirectory(prefix="castle-empty-history-") as directory:
        clone = Path(directory) / "build" / "repository"
        _clone_repository(project_root, clone)
        commit = subprocess.run(
            [
                "git",
                "-c",
                "user.name=Daniel Oranguthang",
                "-c",
                "user.email=75395800+oranguthang@users.noreply.github.com",
                "commit",
                "--quiet",
                "--allow-empty",
                "--message",
                VALID_EMPTY_COMMIT_MESSAGE,
            ],
            cwd=clone,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if commit.returncode != 0:
            raise PublicCommandSmokeError(
                f"cannot create synthetic empty commit: {commit.stderr.strip()}"
            )
        result = _run_make(clone, make, target)
        output = result.stdout + result.stderr
        if result.returncode == 0:
            raise PublicCommandSmokeError(
                f"public command 'make {target}' accepted an empty commit"
            )
        if "is empty relative to every parent" not in output:
            raise PublicCommandSmokeError(
                f"public command 'make {target}' failed without the empty-commit "
                f"diagnostic:\n{output.strip()}"
            )
        return output


def run_unpinned_toolchain_rejection(
    project_root: Path,
    *,
    make_executable: str | None = None,
) -> str:
    """Require the public toolchain gate to reject an override before execution."""
    make = _resolve_make(make_executable)
    with tempfile.TemporaryDirectory(prefix="castle-toolchain-probe-") as directory:
        root = Path(directory)
        marker = root / "executed.txt"
        if os.name == "nt":
            probe = root / "unverified-ca65.cmd"
            probe.write_text(
                f'@echo off\r\necho executed>"{marker}"\r\necho ca65 V2.19\r\n',
                encoding="utf-8",
            )
        else:
            probe = root / "unverified-ca65"
            probe.write_text(
                f'#!/bin/sh\nprintf executed > "{marker}"\nprintf "ca65 V2.19\\n"\n',
                encoding="utf-8",
            )
            probe.chmod(0o755)
        result = _run_make(
            project_root,
            make,
            "build-toolchain-status",
            f"CA65={probe}",
            "LD65=bin/ld65.exe",
        )
        output = result.stdout + result.stderr
        if result.returncode == 0:
            raise PublicCommandSmokeError(
                "public toolchain gate accepted an unpinned assembler override"
            )
        if marker.exists():
            raise PublicCommandSmokeError(
                "public toolchain gate executed an unpinned assembler override"
            )
        if "selected toolchain binary SHA-256 mismatch: ca65" not in output:
            raise PublicCommandSmokeError(
                "public toolchain gate failed without the selected-binary diagnostic:\n"
                + output.strip()
            )
        return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=ROOT)
    parser.add_argument("--target", default="lint")
    args = parser.parse_args()
    try:
        output = run_disposable_make(args.project_root, args.target)
    except (OSError, subprocess.SubprocessError, PublicCommandSmokeError) as exc:
        print(f"[ERROR] {exc}")
        return 1
    summary = next(
        (line for line in reversed(output.splitlines()) if line.startswith("[OK]")),
        "completed",
    )
    print(f"[OK] disposable 'make {args.target}': {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
