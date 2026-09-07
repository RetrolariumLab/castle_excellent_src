# Reproducible disassembly pipeline

## Contract

The pipeline turns the exact Japanese iNES reference into one tracked,
address-ordered PRG-only ca65 translation unit. It never exports CHR bytes into
source. The final ROM must remain byte-identical to the reference.

```text
tools/disassembly.lock.json
  -> verified local Ghidra 12.1.3
  -> verified GhidraNes v20260531
  -> validate exact Castle Excellent iNES image
  -> stage ignored build/ghidra/input.nes
  -> headless NES ROM import
  -> PRG0::$8000-$FFFF; CHR mapping skipped
  -> Ghidra recursive 6502 analysis
  -> config/reconstruction/false_instruction_starts.txt proven analyzer-overreach removals
  -> config/reconstruction/static_code_evidence.txt pointer/control-flow-proven code ranges
  -> config/reconstruction/runtime_evidence.txt code ranges from pinned FCEUX CDL
  -> clear conflicting auto-data and disassemble both evidence classes
  -> config/reconstruction/prg_data_ranges.txt evidence-backed typed data ranges
  -> clear false-positive instructions from proven data
  -> build/ghidra/instructions.tsv
  -> config/reconstruction/symbols.json naming overlay
  -> config/reconstruction/memory_symbols.json operand overlay
  -> config/reconstruction/operand_overrides.json checked relocatable expressions
  -> config/reconstruction/source_layout.json contiguous region ownership
  -> semantic src/**/*.asm modules (preservation paths only during promotion)
  -> ca65 + ld65
  -> byte-identical iNES verification
```

The safe staged filename avoids a Windows batch-parser failure caused by
parentheses in the conventional ROM filename. It is a verified byte-for-byte
copy under ignored `build/`.

Before each import, `scripts/workflow/run_ghidra.py` removes only the disposable
`build/ghidra/castle_excellent.gpr` marker and matching `.rep` directory. This
handles a Windows/Ghidra failure mode where `-deleteProject` removes the marker
but leaves the repository directory behind. Exported facts and reports in the
same build directory are preserved; unit tests enforce that cleanup boundary.

## Commands

```text
make ghidra-bootstrap  # download, SHA-256 check, install locally
make ghidra-status     # verify archives and installed entrypoints
make ghidra-inspect    # inspect memory blocks/functions without exporting ASM
make ghidra-analyze    # export instruction facts to ignored build/
make disassemble       # analyze and write canonical tracked PRG source
make disassembly-check # reproduce in memory and require an exact source match
make trace-boot        # capture CDL and require static/runtime code agreement
make format            # normalize repository text and JSON
make lint              # reject stale formatting or source-contract violations
make check             # fast static analysis, tests, identity, and subsystem gate
make release-check     # clean build plus live symbols, runtime, and release audit
```

## Output rules

- instruction addresses and bytes remain in the generated Ghidra TSV and ca65
  listing rather than duplicative source comments;
- undefined ranges are emitted as address-ordered `.byte` directives;
- direct `JSR`, `JMP`, and conditional branch targets inside PRG use labels;
- proven RAM and CPU-register operands use global or address-scoped aliases;
- source-region boundaries cover the complete PRG without gaps or overlaps and
  may not split an instruction;
- indirect jumps retain their pointer operand and do not create speculative
  labels from Ghidra's computed-flow candidates;
- three-byte absolute references below `$0100` are forced with ca65 `a:` so
  the assembler cannot shorten them to zero-page encoding;
- interrupt vectors use `.addr Nmi`, `.addr Reset`, and `.addr Irq`;
- overlapping control-flow entries use a symbol at an offset from the current
  location counter because a linear listing cannot emit both instruction
  interpretations simultaneously.

## Evidence boundary

Ghidra's code classification is a preservation starting point, not proof that
every emitted mnemonic is executable code. `config/reconstruction/static_code_evidence.txt`
records entry points proven by ROM-resident pointer tables or direct control
flow but not yet reached by the runtime suite. The tracked FCEUX evidence
independently repairs false negatives observed during deterministic scenarios.
`config/reconstruction/prg_data_ranges.txt` handles the opposite case: format proofs and
static consumers establish ranges that must be emitted as data even when
recursive or switch analysis mistakes them for instructions. Lint rejects an
overlap between typed data and either code-evidence class. Static and runtime
code ranges may overlap when independent evidence corroborates an entry.
Unclassified regions still require broader traces and byte-level proofs before
final types.

`config/reconstruction/false_instruction_starts.txt` handles the narrower case where an
analyzer-created entry lands inside a real instruction operand rather than in
typed data. The current entry removes `$A207`: Ghidra extrapolates object-sprite
switch case `$66` beyond the proven 42-entry table, but `$A207` is byte two of
the linear `LDA $28` at `$A206`. The false start is cleared before static and
runtime evidence are disassembled, so the exported fact stream retains the
real instruction boundary.
