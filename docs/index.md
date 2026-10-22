# Documentation

## Builds

- [Revision profiles](revision_profiles.md) — Japanese and USA identities and
  their shared-source strategy.
- [Editing in Retrolarium](retrolarium.md) — how the game is edited.

## Engine reference

- [Architecture](architecture.md) — conceptual runtime design.
- [Subsystem landmarks](subsystems.md) — address-ordered PRG inventory.
- [Source layout](source_layout.md) — modules and how the source is maintained.
- [RAM map](ram_map.md) — storage lifetimes and shared scratch contracts.
- [Data formats](data_formats.md) — binary formats and round-trip status.

## Findings

- [Open questions](unknowns.md) — unresolved claims that can affect public
  contracts. The resolved investigation ledger of 1.0 to 3.0 is at those tags
  (`docs/resolved_unknowns.md`).

The checks are in the README: `make test` after every change, `make test-full`
for the attract mode in MAME.
