#!/usr/bin/env python3
"""Render the curated public Make interface."""

from __future__ import annotations


TARGET_GROUPS = (
    (
        "Getting started",
        (
            ("help", "show this command guide"),
            ("inspect", "inspect the Japanese reference ROM"),
            ("split", "extract ignored private assets"),
            ("build", "assemble the default reconstruction"),
            ("verify", "prove complete byte identity"),
            ("clean", "remove generated build output"),
        ),
    ),
    (
        "Quality",
        (
            ("format", "normalize authored source and metadata"),
            ("lint", "check style, layout, links, and policy"),
            ("scaffold-check", "run the ROM-less public gate"),
            ("quality-check", "run lint and the ROM-backed test suite"),
            ("check", "run the complete static reconstruction gate"),
        ),
    ),
    (
        "Revision profiles",
        (
            ("split-profile", "extract one profile's private assets"),
            ("build-profile", "assemble one revision profile"),
            ("verify-profile", "prove one revision profile"),
            ("castlequest-check", "split and verify the US revision"),
            ("check-fixed-layout", "validate one fixed-layout variant"),
        ),
    ),
    (
        "Content authoring",
        (
            ("level-studio", "open the room and castle-map editor"),
            ("sound-studio", "open the track editor and preview player"),
            ("graphics-studio", "open the CHR graphics editor"),
            ("editor-quality-check", "validate both authoring profiles"),
            ("editor-ui-smoke-profile", "smoke-test all visual editors"),
        ),
    ),
    (
        "Reconstruction workflow",
        (
            ("ghidra-status", "inspect the pinned Ghidra installation"),
            ("ghidra-analyze", "regenerate instruction facts"),
            ("disassemble", "regenerate address-ordered ca65 source"),
            ("disassembly-check", "verify deterministic regeneration"),
            ("symbols", "export emulator debugger symbols"),
            ("validate-symbols", "validate symbols in a live emulator"),
        ),
    ),
    (
        "Source 2.0 release",
        (
            ("source-2-audit", "reconcile release manifest and evidence"),
            ("source-2-check", "run the complete two-profile gate"),
            ("source-2-pre-tag-check", "add clean-tree and tag-readiness checks"),
            ("source-2-tag-check", "validate the checked-out release tag"),
        ),
    ),
    (
        "Source 2.1 compatible release",
        (
            ("source-2-minor-audit", "reconcile the 2.1 compatible delta"),
            ("source-2-minor-check", "run the accepted 2.0 gate and 2.1 delta"),
            ("source-2-minor-pre-tag-check", "validate the clean 2.1 candidate"),
            ("source-2-minor-tag-check", "validate the checked-out 2.1 tag"),
        ),
    ),
)


def documented_targets() -> set[str]:
    return {target for _heading, entries in TARGET_GROUPS for target, _help in entries}


def render_help() -> str:
    lines = ["Castle Excellent source reconstruction", ""]
    for heading, entries in TARGET_GROUPS:
        lines.append(f"{heading}:")
        lines.extend(f"  {target:<28} {description}" for target, description in entries)
        lines.append("")
    lines.extend(
        (
            "Common selectors:",
            "  REVISION_PROFILE=castle-excellent-japan-hsp-05|castlequest-usa",
            "  FIXED_LAYOUT_VARIANT=start-room-1",
            "",
            "Run 'python scripts/run.py --list' for the lower-level tool catalog.",
        )
    )
    return "\n".join(lines)


def main() -> int:
    print(render_help())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
