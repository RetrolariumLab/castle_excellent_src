# Development guide

This document defines how the repository uses configuration, tools, tests, and
generated source. The [verification contract](verification.md) describes the
gates that prove a change is safe, while [source layout](source_layout.md)
describes the emitted ca65 modules.

## Everyday commands

The public interface is the root Makefile:

```bash
make format
make lint
make scaffold-check
make test
make quality-check
make check
```

`make format` normalizes tracked authored text. `make lint` checks formatting,
assembly style, repository boundaries, manifest schemas, source ownership,
debugger configuration, binary policy, and evidence registries. `make test`
regenerates pinned Ghidra facts before running the Python unit suite. `make
check` adds deterministic source regeneration, assembly, byte identity, and
the subsystem contracts.

Use `make scaffold-check` when private ROM assets are unavailable; it combines
the full lint policy with synthetic tests for repository structure, formats,
profiles, disassembly generation, and release audits. `make quality-check`
regenerates Ghidra facts from the Japanese reference ROM and runs the complete
Python suite. Release and profile gates are listed in
[verification.md](verification.md).

The root file owns shared variables, build/profile rules, tool bootstrap, and
release orchestration. Repetitive implementation rules are grouped in
`mk/authoring.mk`, `mk/runtime.mk`, and `mk/validation.mk`. These are internal
includes, not alternative command interfaces.

## Naming and evidence

Generated source has two explicit naming layers:

- evidence-backed PascalCase names such as `DecodeRoom` and
  `RoomPointerTable`, maintained in `config/reconstruction/symbols.json`;
- stable generic `Func_XXXX` and `Label_XXXX` names, allowed only for
  unresolved ranges during reconstruction.

An overlapping entry uses an address name defined as an offset from its
containing instruction. Renames belong in the symbol registry; do not edit
generated generic labels by hand.

RAM and I/O operands are defined in
`config/reconstruction/memory_symbols.json`. Global records describe stable
game-wide storage or hardware registers. Address-scoped records describe
scratch reuse only inside a proven routine range; their ca65 aliases live in
`src/memory/ram.inc`.

Relocatable expressions that cannot be derived from a plain address symbol are
stored in `config/reconstruction/operand_overrides.json`. Each override pins
the original operand and its evidence, so regeneration fails if its
precondition changes.

Do not turn a plausible interpretation into a fact. Record open questions in
[unknowns.md](unknowns.md); move the resolution and its evidence to
[resolved_unknowns.md](resolved_unknowns.md) once it is proven.

## Source and comment policy

The PRG is one address-ordered translation unit split only at boundaries
registered in `config/reconstruction/source_layout.json`. Semantic modules
normally contain 300-700 lines; each exception requires an explicit rationale
in that registry. The complete rules and current exceptions are documented in
[source_layout.md](source_layout.md).

Comments should explain behavior, constraints, or evidence. Pure address and
byte dumps such as `; $B173` or `; $82AD D0 01` duplicate an assembler listing
and are rejected as `machine-code-comment`. The formatter removes those
comments while retaining explanatory text.

## Configuration

The tracked `config/` tree contains only authored inputs and release contracts:

- `authoring/` defines level, audio, and graphics workspaces;
- `debugger/` defines symbol-resolved breakpoints and watches;
- `linker/` owns ca65/ld65 memory layouts;
- `reconstruction/` owns symbols, operands, source layout, analyzer
  corrections, typed-data ranges, and code evidence.

Four release-facing manifests remain directly under `config/`:

- `revision_profiles.json`;
- `fixed_layout_variants.json`;
- `source_reconstruction_1_0.json`;
- `source_reconstruction_2_0.json`.

Generated output, caches, and disposable analysis data never belong in
`config/`. `make lint-source` rejects unexpected files or responsibility
directories, so a new configuration family requires an explicit policy
change.

## Scripts and tests

Run Python tools through the repository runner so imports behave the same on
Windows, Linux, in tests, and from Make:

```text
python scripts/run.py --list
python scripts/run.py authoring.level_studio --help
python scripts/run.py build.revision_profiles --help
python scripts/run.py validation.player.player_input_movement --help
```

Tools are grouped by responsibility:

- `authoring/` contains level, graphics, and music editors, codecs, and
  presentation models;
- `build/` owns ROM splitting, assembly, revision profiles, fixed-layout
  variants, and byte comparison;
- `runtime/` owns emulator installation, deterministic capture, debugger
  validation, revision smoke tests, and level playtesting;
- `validation/` owns formatting, audits, source checks, and executable
  reconstruction contracts, with large families grouped by subsystem;
- `workflow/` owns Ghidra installation, headless analysis, and deterministic
  disassembly regeneration.

Only `scripts/run.py` and package metadata may live directly under `scripts/`.
The `tests/` tree mirrors the package layout. For example:

```text
scripts/validation/player/player_input_movement.py
tests/validation/player/test_player_input_movement.py
```

A focused test can be run by module name:

```text
python -m unittest tests.validation.player.test_player_input_movement
```
