# Roadmap

The roadmap records release-level direction. Completed reconstruction details
belong in [resolved_unknowns.md](resolved_unknowns.md), while exact acceptance
criteria live in the release manifests.

## Source Reconstruction 1.0 — released

The Japanese HSP-05 cartridge is reconstructed as a byte-identical,
address-ordered ca65 source. All 32 KiB of PRG have semantic or typed-data
ownership, direct control flow is symbolic, RAM and routine maps are
machine-readable, and deterministic Ghidra, debugger, runtime, and format
evidence are part of the release gate.

See [source_reconstruction_1_0.md](source_reconstruction_1_0.md) for the frozen
boundary.

## Source Reconstruction 2.0 — tag-ready

The current release candidate adds:

- a byte-identical Castlequest USA profile over shared source;
- isolated revision-specific binary assets;
- profile-aware level, object, music, and graphics round trips;
- visual Level, Sound, and Graphics studios backed by the headless codecs;
- a full-castle level overview and direct room playtesting;
- a bounded fixed-layout edit demonstrator;
- aggregate profile, authoring, runtime, and release audits.

The implementation checklist is complete. Remaining release work is procedural:
run the clean pre-tag gate, review the resulting commit, move it to `main`, and
create the annotated tag. See
[source_reconstruction_2_0.md](source_reconstruction_2_0.md).

## Deferred beyond 2.0

The following work is intentionally outside the current tag:

- relocatable or expanded room, object, graphics, and audio arenas;
- additional regional or platform profiles backed by verified reference ROMs;
- higher-level friendly identities for ambiguous objects and enemy states;
- modding workflows that change topology rather than fixed-capacity content;
- reconstruction of The Castle or another sibling engine;
- broader runtime scenarios where they support a new public claim.

Each item requires its own declared scope, evidence, and release gate. None is
implied by the Source 2.0 tag-ready status.
