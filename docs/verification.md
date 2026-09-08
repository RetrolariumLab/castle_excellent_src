# Verification

Verification is layered so a passing build does not depend on one kind of
evidence alone:

1. lint and unit tests protect authored contracts;
2. deterministic Ghidra regeneration protects the code/data classification;
3. assembly and byte comparison protect the original cartridge identity;
4. subsystem validators protect reconstructed behavior and data formats;
5. FCEUX scenarios and live symbols exercise the rebuilt ROM at runtime;
6. release audits reconcile all evidence with the versioned manifests.

## Binary identity

The preservation proof has three independent inputs:

1. `assets/manifest.json`, the immutable expected identity;
2. `Castle Excellent (J).nes`, the ignored original image;
3. `build/native/castle_excellent.nes`, assembled from tracked PRG source plus
   the ignored CHR extracted by `make split`.

`make verify` validates both complete images against the manifest, then
performs direct byte comparisons of the iNES header, PRG, CHR, headerless
payload, full image, and extracted CHR.

## Key targets

| Target | Contract |
| --- | --- |
| `verify-reference` | original image matches every manifest field |
| `verify-built` | built image matches every manifest field |
| `verify-header` | built and original iNES header/trainer regions match |
| `verify-prg` | built and original 32 KiB PRG match |
| `verify-chr` | CHR inside built and original images match |
| `verify-payload` | headerless PRG+CHR payloads match |
| `verify-rom` | complete headered files match |
| `verify-assets` | ignored extracted CHR matches original CHR |
| `check-assets` | alias for `verify-assets` |
| `verify` | aggregate of every target above |
| `rom-info` | print and validate identities for original and built images |
| `reconstruction-audit` | verify complete PRG ownership, naming, operands, and module policy |
| `validate-*` | run one focused subsystem or data-format contract |
| `symbols` | generate linker, Mesen, FCEUX, breakpoint, and watch artifacts |
| `validate-symbols` | prove symbol lookup and a named execution hook in FCEUX |
| `trace-source-1` | freshly capture and reconcile the seven accepted runtime scenarios |
| `check` | fast aggregate of lint, tests, deterministic source regeneration, byte identity, symbols, and all static subsystem/format validators |
| `release-check` | remove `build/`, verify private inputs and build tools before use, run `check`, validate live debugger symbols, freshly capture the seven declared runtime scenarios from the source-built image, and audit revision 3 release metadata on a clean tree |
| `source-1-check` | compatibility alias for `release-check` |
| `source-1-pre-tag-check` | full gate plus `tag-ready` status, clean tree, absent local/remote future tag, and release-history policy |
| `source-1-tag-check` | full gate plus clean tree and an annotated `source-reconstruction-1.0` tag peeled to `HEAD` |
| `source-2-audit` | reconcile the 2.0 manifest with its pinned predecessor, revision profiles, requirement evidence, artifacts, runtime declarations, and repository policy |
| `source-2-authoring-check-profile` | verify one revision and run deterministic level, music, and graphics round trips plus all three Studio model checks |
| `source-2-check` | run the complete 1.0 gate, Castlequest runtime, fixed-layout proof, authoring checks and baseline room playtests for both revisions, then audit the 2.0 manifest |
| `source-2-pre-tag-check` | full 2.0 gate plus `tag-ready` metadata, clean tree, absent local/remote future tag, and commit-history policy |
| `source-2-tag-check` | full 2.0 gate plus clean tree and an annotated `source-reconstruction-2.0` tag peeled to `HEAD` |
| `source-2-minor-audit` | reconcile the compatible 2.1 project manifest, immutable 2.0 predecessor, complete delta and inherited release evidence |
| `source-2-minor-check` | run the accepted complete 2.0 gate first, then the compatible 2.1 hardening and release audit |
| `source-2-minor-pre-tag-check` | full 2.1 gate plus clean-tree, history, branch and absent-tag requirements |
| `source-2-minor-tag-check` | full 2.1 gate plus an annotated `source-reconstruction-2.1` tag peeled to `HEAD` |

Focused region targets compare only their named output region. For example,
`verify-prg` can prove that the source-only PRG reconstruction is correct while
investigating an unrelated CHR issue. `verify` remains the release gate and
accepts no differences anywhere.

The exact focused-validator inventory belongs to `mk/validation.mk` and the
release manifests, with the root `Makefile` providing the public entrypoints.
This document describes their shared contract rather than repeating a list
that can drift from executable policy.

## Runtime evidence

Static analysis cannot by itself distinguish every code-shaped byte from data
in a 6502 image. The independent runtime layer uses the native FCEUX Code/Data
Logger (CDL). `tools/runtime.lock.json` pins the exact automation build by
source revision, artifact size, and SHA-256; `make fceux-bootstrap` verifies it
before use.

The baseline suite covers boot/gameplay, the idle title path, and a natural
timeout/death path. The Source 1.0 suite adds state-injected room transition,
final-life game over, ending, successful save, and expected no-device load
failure paths. The authoritative declarations live in
`scenarios/source_1.json`; each rare path must reach its declared symbols after
setup rather than receiving credit from initialization calls.

Every capture validates the reference image, runs a deterministic controller
script, saves a native 64 KiB CDL, compares its PRG half with Ghidra's
instruction facts, and records hit semantic routines. CHR bytes present in the
CDL format never enter generated assembly.

`make runtime-promote` converts ignored CDL observations into address ranges in
`config/reconstruction/runtime_evidence.txt`. Static evidence, runtime
evidence, and typed-data ranges remain separate, and lint rejects overlaps.
Execution of even one PRG byte outside the registered code classification is a
failure; unexecuted instructions are not automatically treated as data.

## Debugger symbols

`make symbols` derives all debugger artifacts from the same ca65/ld65 build
that reproduces the ROM. Outputs under `build/native/` include the Mesen
`.dbg`, linker map and labels, FCEUX ROM/RAM labels, and a resolved JSON summary
of `config/debugger/breakpoints.json` and `config/debugger/watches.json`.

The symbol validator checks segment file offsets, representative
source-file/line mappings, and every configured fixed address. `make
validate-symbols` then opens the rebuilt ROM in pinned FCEUX, resolves
representative ROM and RAM names through the live debugger API, and reaches
`MainFrameLoop` through a named execution hook.

For interactive work, keep `build/native/castle_excellent.dbg` beside the ROM
and open the rebuilt image in Mesen 2. Regenerate symbols after moving the
checkout or changing source lines.

## Failure diagnostics

The comparison script reports the first different byte. PRG failures include
both the PRG offset and mapped CPU address; CHR failures include the 8 KiB CNROM
bank and bank-relative offset. Length differences report `EOF` on the missing
side.

## Typical workflow

```bash
make split
make verify-prg
make verify
make release-check
make source-2-check
```

`make clean` removes only `build/`; it preserves the ignored extracted assets,
so a clean rebuild does not require repeating `make split`.
