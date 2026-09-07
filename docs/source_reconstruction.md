# Source reconstruction contract

The project targets the source-level standard demonstrated by the sibling
`smb1_src` and `pacman_src` repositories, not merely a matching assembler
listing. A release is complete only when the rebuilt cartridge is exact, the
source is reviewable and editable, claims are tied to evidence, and one
reproducible gate protects the complete boundary.

Machine-readable acceptance criteria live in
`config/source_reconstruction_1_0.json` and
`config/source_reconstruction_2_0.json`. This document explains the enduring
quality model shared by those releases.

## Required guarantees

### Cartridge identity

The canonical ca65 entrypoint must rebuild every PRG byte from source. Private
CHR or revision data may be extracted from a user-supplied reference ROM only
through a declared asset contract. Verification compares the header, PRG, CHR,
headerless payload, and complete image independently.

Each supported revision has its own hashes, sizes, mapper geometry, extracted
assets, build directory, and runtime evidence. A shared engine must remain
shared source; revision differences cannot be hidden in copied source trees or
undeclared binary includes.

### Reviewable source

Every PRG byte belongs to exactly one semantic or typed-data source region.
Direct branches, jumps, and calls use labels. Modules follow proven subsystem
boundaries and the size policy in [source_layout.md](source_layout.md).

Routine, data, RAM, and I/O names state only evidence-backed behavior. Scoped
aliases are preferred when scratch storage has different meanings in different
consumers. Unresolved claims stay visible in [unknowns.md](unknowns.md); proven
answers retain their evidence in [resolved_unknowns.md](resolved_unknowns.md).

### Reproducible analysis

The Ghidra version, NES loader, emulator, and native build tools are pinned.
Headless analysis starts from the declared ROM and applies reviewed static
code evidence, runtime evidence, typed-data ranges, false-instruction
corrections, symbols, and operand overrides. Regeneration must reproduce every
tracked source module without manual post-processing.

Code/data boundaries need pointer, control-flow, format, or runtime evidence.
Code-shaped bytes are not promoted merely because a disassembler can decode
them, and short runtime coverage is never treated as proof that unobserved
bytes are data.

### Editable formats

Significant game data should have a documented model, strict validation, and a
zero-edit round trip. Visual editors are front ends to the same headless codecs
used by tests and release gates; a GUI cannot introduce a second serialization
path.

Fixed-capacity formats must reject overflow before modifying a ROM. Any
relocatable or expanded format requires an explicit memory-layout decision,
pointer proof, changed-byte allowlist, and runtime validation rather than an
implicit relaxation of the preservation contract.

### Runtime and debugger evidence

Static validation is complemented by deterministic emulator scenarios for
ordinary and rare paths. Generated debugger names must resolve against the
current linker output and be consumed successfully by a live emulator hook.
State injection is acceptable only when it is declared and the intended path
is reached after setup.

The complete model is documented in [verification.md](verification.md).

## Promotion rule

A reconstructed range or format may become part of a release contract only
when:

1. its boundaries and consumers have explicit provenance;
2. source ownership remains complete and non-overlapping;
3. no boundary splits an instruction or typed record;
4. names distinguish proof from inference;
5. deterministic regeneration remains clean;
6. every supported profile still rebuilds byte-identically;
7. focused static, format, or runtime checks cover the new claim.

## Current release state

| Dimension | Source 1.0 | Source 2.0 |
| --- | --- | --- |
| Profiles | Japanese HSP-05 | Japanese HSP-05 and Castlequest USA |
| PRG ownership | complete 32 KiB source | inherited unchanged |
| Source layout | 32 semantic/typed-data modules | inherited unchanged |
| Symbols | complete PRG and RAM/I/O ledgers | profile-aware build symbols |
| Runtime | seven Japanese scenarios | Japanese suite plus USA coverage |
| Authoring | format proofs | level, music, and graphics codecs and studios |
| Experimental edits | excluded | isolated fixed-layout demonstrator |
| Status | released predecessor | tag-ready development boundary |

The detailed engine behavior belongs in [architecture.md](architecture.md),
address ownership in [subsystems.md](subsystems.md), binary records in
[data_formats.md](data_formats.md), and release deltas in the two versioned
boundary documents. The resolved-findings ledger preserves investigation
history, so this contract does not repeat a chronological promotion diary.

## Release discipline

`make check` is the normal integration gate. Versioned pre-tag gates begin
from a clean build, validate private inputs before use, run all inherited and
new checks, regenerate runtime evidence, require a clean worktree, and audit
the candidate manifest. Tag creation and publishing remain explicit owner
actions after the gate succeeds.

A later release may strengthen this contract, but it must not silently weaken
identity, source ownership, reproducibility, or predecessor guarantees.
