# Debugger workflow

The native ca65/ld65 build emits source mappings and semantic symbols from the
same source that reproduces the Japanese HSP-05 ROM. Generate and validate the
complete debugger artifact set with:

```bash
make symbols
```

The ignored outputs in `build/native/` are:

- `castle_excellent.nes`, the byte-identical complete iNES image;
- `castle_excellent.dbg`, ld65 symbols, files, lines, and spans for Mesen;
- `castle_excellent.map` and `castle_excellent.lbl`, linker map and VICE labels;
- `castle_excellent.nes.0.nl` and `.ram.nl`, automatically loaded FCEUX labels;
- `debug_symbols.json`, the resolved breakpoint/watch manifest.

`scripts/validation/debug_symbols.py` checks that the debug file maps HEADER, PRG, and CHR
to file offsets 0, 16, and 32784, follows representative semantic labels back
to their exact source files and current label lines, and resolves every entry
in `config/debugger_breakpoints.json` and `config/debugger_watches.json`.
Each configured fixed address must equal the current linker symbol, so a stale
manual breakpoint fails `make symbols` instead of drifting silently.

## Live validation

```bash
make validate-symbols
```

The pinned FCEUX automation build opens the rebuilt ROM beside its generated
`.nl` files. Lua resolves seven representative ROM/RAM symbols through the live
debugger API and installs an execution hook on `MainFrameLoop`; success requires
the
named breakpoint within 900 frames. This proves artifact generation, emulator
loading, symbol lookup, and execution hooks as one end-to-end contract.

Mesen 2 remains the preferred interactive source debugger: keep the `.dbg` and
`.nes` files together and open the rebuilt ROM. Source View then follows the
paths embedded by ca65. Regenerate symbols after moving the checkout or
changing source lines.

The current debugger configuration targets only Castle Excellent HSP-05.
Castlequest addresses belong to Source Reconstruction 2.0.
