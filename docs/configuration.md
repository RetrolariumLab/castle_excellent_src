# Configuration layout

The tracked `config/` tree contains authored inputs and release contracts. It
does not contain generated build output, caches, or disposable analysis data.
Every file is consumed by the build, authoring, debugger, reconstruction, or
release audit pipeline.

## Responsibility directories

- `authoring/` defines the editable level, audio, and graphics formats used by
  the command-line codecs and graphical studios.
- `debugger/` contains symbol-resolved breakpoints and RAM watches shared by
  Mesen and FCEUX validation.
- `linker/` owns ca65/ld65 memory layouts.
- `reconstruction/` owns the deterministic disassembly inputs: PRG and RAM
  symbols, operand overrides, source ownership, analyzer corrections, typed
  data ranges, and static/runtime code evidence.

Four public manifests remain directly under `config/`:

- `revision_profiles.json` selects supported ROM revisions;
- `fixed_layout_variants.json` defines bounded test variants;
- `source_reconstruction_1_0.json` preserves the accepted 1.0 contract;
- `source_reconstruction_2_0.json` defines the current release boundary.

`make lint-source` rejects unregistered files or responsibility directories at
the config root. Adding a new configuration family therefore requires an
explicit policy change rather than silently returning to a flat directory.
