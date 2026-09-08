# Castle Excellent NES source reconstruction

A byte-identical ca65 reconstruction and content-authoring workspace for
**Castle Excellent** (`HSP-05`) on Famicom and **Castlequest** on NES. The
repository rebuilds both supported revisions from shared PRG source, isolates
private ROM-derived assets, and validates reconstructed behavior with static,
format, debugger, and emulator evidence.

## Status

Source Reconstruction 1.0 is the released Japanese-only preservation
baseline. Source Reconstruction 2.0 is tag-ready and adds:

- a byte-identical Castlequest USA profile;
- complete semantic or typed-data ownership of the 32 KiB PRG;
- profile-aware level, object, music, and graphics round trips;
- visual Level, Sound, and Graphics studios backed by the same headless codecs;
- deterministic Ghidra regeneration, FCEUX scenarios, and debugger symbols;
- a bounded fixed-layout modification proof.

The game uses CNROM mapper 3: one fixed 32 KiB PRG at `$8000-$FFFF` and four
switchable 8 KiB CHR banks. CPU code is not bank-switched; CHR banks 2 and 3
also contain compressed room data.

## Quick start

Requirements are Python 3, GNU Make, and legally obtained reference ROMs. The
pinned ca65/ld65 binaries are included; Ghidra, GhidraNes, and the automation
emulator are installed or verified by their Make targets.

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

## Content editors

Open a studio for either supported revision:

```bash
make level-studio REVISION_PROFILE=castle-excellent-japan-hsp-05
make sound-studio REVISION_PROFILE=castle-excellent-japan-hsp-05
make graphics-studio REVISION_PROFILE=castle-excellent-japan-hsp-05
```

Use `REVISION_PROFILE=castlequest-usa` for the USA release. Each studio writes
an ignored workspace and delegates serialization to its validated headless
codec. Common non-GUI commands are:

```bash
make roundtrip-levels REVISION_PROFILE=castlequest-usa
make build-levels REVISION_PROFILE=castlequest-usa
make smoke-level-playtest REVISION_PROFILE=castlequest-usa

make roundtrip-music REVISION_PROFILE=castlequest-usa
make build-music REVISION_PROFILE=castlequest-usa

make roundtrip-graphics REVISION_PROFILE=castlequest-usa
make build-graphics REVISION_PROFILE=castlequest-usa
```

See [Content authoring](docs/content_authoring.md) for workspace formats,
capacity limits, preview behavior, and editor controls.

## Verification and release gates

```bash
make format           # normalize authored source, configuration, and docs
make lint             # validate style, layout, links, manifests, and policy
make scaffold-check   # lint and synthetic tests without private ROM assets
make test             # regenerate Ghidra facts and run the Python suite
make quality-check    # lint and the complete ROM-backed Python suite
make check            # build, prove byte identity, and run static contracts
make source-2-audit   # reconcile the Source 2.0 manifest and evidence
make source-2-check   # run the complete two-profile release candidate gate
```

`make source-2-pre-tag-check` adds clean-tree, history, and tag-readiness
requirements. The full gate model is documented in
[Verification](docs/verification.md).

## Repository map

```text
assets/                 reference manifests and ignored extracted assets
config/authoring/       level, music, and graphics contracts
config/debugger/        symbol-resolved breakpoints and watches
config/reconstruction/  symbols, operands, source layout, and code evidence
docs/                   architecture, formats, workflows, and release policy
content/workspace/      editable level, music, and graphics documents
mk/                     authoring, runtime, and validation Make rules
scripts/authoring/      headless codecs and visual studios
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
