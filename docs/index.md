# Documentation

The sections below provide one canonical entry for every maintained document.
New pages must be added here, and obsolete pages must be removed rather than
left as disconnected notes.

## Release contracts

- [Source Reconstruction 2.1](source_reconstruction_2_1.md) — compatible
  hardening scope under active development.
- [Source Reconstruction contract](source_reconstruction.md) — enduring
  definition of a reconstructed source release.
- [Source Reconstruction 2.0](source_reconstruction_2_0.md) — current
  tag-ready scope and acceptance boundary.
- [Source Reconstruction 1.0](source_reconstruction_1_0.md) — preserved
  Japanese-only release boundary.
- [Revision profiles](revision_profiles.md) — Japanese and USA identities and
  their shared-source strategy.
- [Fixed-layout variants](fixed_layout_variants.md) — bounded experimental
  edits and their byte allowlists.
- [Disassembly pipeline](disassembly_pipeline.md) — reproducible Ghidra inputs
  and source regeneration.
- [Verification](verification.md) — identity, runtime, debugger, and release
  gates.
## Engine reference

- [Architecture](architecture.md) — conceptual runtime design.
- [Subsystem landmarks](subsystems.md) — address-ordered PRG inventory.
- [Source layout and symbols](source_layout.md) — modules, naming ledgers, and
  original-name provenance.
- [RAM map](ram_map.md) — storage lifetimes and shared scratch contracts.
- [Data formats](data_formats.md) — binary formats and round-trip status.
- [Content authoring](content_authoring.md) — headless codecs and visual
  studios.

## Project policy and evidence

- [Development guide](development.md) — commands, naming, configuration,
  scripts, tests, and source policy.
- [Provenance](provenance.md) — cartridge, research, and toolchain origins.
- [Open questions](unknowns.md) — unresolved claims that can affect public
  contracts.
- [Resolved findings](resolved_unknowns.md) — evidence-backed investigation
  ledger.
- [Roadmap](roadmap.md) — release history and deferred work.

Machine-readable release ownership lives in
`config/source_reconstruction_1_0.json` and
`config/source_reconstruction_2_0.json`. Active compatible-minor development is
declared by `config/source_reconstruction_2_1.json`; prose documents explain
those contracts but do not replace them.
