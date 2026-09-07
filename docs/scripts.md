# Project scripts

All Python tools are importable modules grouped by responsibility. Invoke them
through the repository runner so commands use the same package path on Windows,
Linux, in tests, and from Make targets:

```text
python scripts/run.py --list
python scripts/run.py authoring.level_studio --help
python scripts/run.py build.revision_profiles --help
python scripts/run.py validation.player.player_input_movement --help
```

The public Make targets remain the preferred interface for normal work. The
module runner is useful for focused inspection, development, and diagnostics.

## Responsibilities

- `authoring/` contains the level, graphics, and music editors together with
  the codecs and presentation models they share.
- `build/` owns ROM splitting, assembly, revision profiles, fixed-layout
  variants, and byte comparison.
- `runtime/` owns emulator installation, deterministic CDL capture, debugger
  validation, revision smoke tests, and level playtesting. Its Lua scripts are
  kept beside the Python processes that launch them.
- `validation/` owns formatting, release audits, source-layout checks, and the
  executable reconstruction contracts. Large contract families are grouped by
  subsystem: `audio`, `collision`, `gameplay`, `objects`, `player`, `rooms`,
  `system`, and `preservation`.
- `workflow/` owns the Ghidra bootstrap, headless analysis, and deterministic
  disassembly regeneration used while reconstructing the source.

Only `scripts/run.py` and package metadata may live directly under `scripts/`.
`make lint-source` enforces that boundary so new utilities cannot silently
recreate the former flat tool directory.

The `tests/` tree mirrors these package paths. For example,
`scripts/validation/player/player_input_movement.py` is covered by
`tests/validation/player/test_player_input_movement.py`. Focused tests can be
run by module name:

```text
python -m unittest tests.validation.player.test_player_input_movement
```
