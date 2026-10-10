# Castle Excellent NES source reconstruction

A byte-identical ca65 reconstruction of **Castle Excellent** (`HSP-05`) on
Famicom and **Castlequest** on NES, edited in Retrolarium Studio. The
repository rebuilds both supported revisions from shared PRG source, isolates
private ROM-derived assets, and validates reconstructed behavior with static,
format, debugger, and emulator evidence.

## Status

Source Reconstruction 1.0 is the released Japanese-only preservation
baseline. Source Reconstruction 2.0 is the released profile-aware baseline and
adds:

- a byte-identical Castlequest USA profile;
- complete semantic or typed-data ownership of the 32 KiB PRG;
- profile-aware level, object, music, and graphics round trips;
- visual Level, Sound, and Graphics studios backed by the same headless codecs;
- deterministic Ghidra regeneration, FCEUX scenarios, and debugger symbols;
- a bounded fixed-layout modification proof.

Source Reconstruction 2.1 is the active compatible release candidate. It
preserves the 2.0 ROM, profile, runtime, and editor contracts while adding
self-contained release metadata, object-level history auditing, disposable
public command smoke, Python source policy, atomic output writes, bounded tool
modules, and complete workstation editor interactions.

Source Reconstruction 3.0 moves editing to Retrolarium: `castle_excellent.rlj`
opens both revisions in the studio, the Level, Sound, and Graphics studios
are retired, and `make studio-check` proves each revision with the kit.

The game uses CNROM mapper 3: one fixed 32 KiB PRG at `$8000-$FFFF` and four
switchable 8 KiB CHR banks. CPU code is not bank-switched; CHR banks 2 and 3
also contain compressed room data.

## Quick start

The supported release host is Windows x64 with PowerShell; exact validated
versions are recorded in `config/source_reconstruction_2_0.json`. Requirements
are Python 3, GNU Make, and legally obtained reference ROMs. The pinned
ca65/ld65 binaries are included; Ghidra, GhidraNes, and the automation emulator
are installed or verified by their Make targets.

Place the Japanese ROM in the repository root, then run:

```bash
make inspect REFERENCE_ROM="Castle Excellent (J).nes"
make split REFERENCE_ROM="Castle Excellent (J).nes"
make check
```

The resulting byte-identical image and debugger outputs are written under
`build/native/`. ROM images, extracted private assets, editor workspaces, and
build products are ignored by Git.

To prepare and verify another supported profile:

```bash
make split-profile REVISION_PROFILE=castlequest-usa
make verify-profile REVISION_PROFILE=castlequest-usa
```

Profile identities and expected local inputs are declared in
`config/revision_profiles.json`.

## Editing

Open `castle_excellent.rlj` in Retrolarium Studio. It asks which revision to
edit, takes its ROM and keeps the edits in the ignored `hack/<revision>/`; see
[editing in Retrolarium](docs/retrolarium.md).

## Verification and release gates

```bash
make help             # show the curated command catalog
make format           # normalize authored source, configuration, and docs
make lint             # validate style, layout, links, manifests, and policy
make scaffold-check   # lint and synthetic tests without private ROM assets
make test             # regenerate Ghidra facts and run the Python suite
make quality-check    # lint and the complete ROM-backed Python suite
make check            # build, prove byte identity, and run static contracts
make source-2-audit   # reconcile the Source 2.0 manifest at its tag
make source-2-check   # run the complete two-profile release candidate gate
make source-2-minor-audit # reconcile the Source 2.1 delta at its tag
make studio-check     # open and rebuild every revision with the kit
make source-2-minor-check # run accepted 2.0 first, then the complete 2.1 delta
```

The ordinary Source 2.1 audit always validates every commit after the accepted
2.0 predecessor and rejects empty Git objects. `make source-2-minor-pre-tag-check`
adds clean-tree, branch, and tag-readiness requirements. The full gate model is
documented in [Verification](docs/verification.md).

## Repository map

```text
assets/                 reference manifests and ignored extracted assets
config/debugger/        symbol-resolved breakpoints and watches
config/reconstruction/  symbols, operands, source layout, and code evidence
docs/                   architecture, formats, workflows, and release policy
mk/                     runtime and validation Make rules
scripts/build/          assembly, profiles, variants, and byte comparison
scripts/runtime/        emulator capture, playtesting, and live validation
scripts/validation/     release and subsystem contracts
scripts/workflow/       Ghidra and deterministic disassembly workflow
src/                    address-ordered semantic ca65 source
tests/                  tests mirroring the script package layout
```

Start with the [documentation index](docs/index.md). In particular:

- [Architecture](docs/architecture.md) explains the runtime design;
- [Source layout and symbols](docs/source_layout.md) maps PRG ownership;
- [Data formats](docs/data_formats.md) defines binary records and round trips;
- [Development guide](docs/development.md) defines repository conventions;
- [Roadmap](docs/roadmap.md) separates released, tag-ready, and deferred work.

## Research and rights

The reconstruction builds on the published Castle Excellent room-data
analysis and extractor:

- <https://habr.com/ru/articles/991848/>
- <https://github.com/wizzard2010/cex>

The upstream extractor had no explicit license when inspected and is not
bundled. Original game code, graphics, music, and room data remain property of
their respective rights holders. Users must supply their own lawful ROMs.
