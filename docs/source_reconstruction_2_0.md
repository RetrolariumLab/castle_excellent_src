# Source Reconstruction 2.0

Source Reconstruction 2.0 inherits the immutable
`source-reconstruction-1.0` release at commit
`ce382dc14ec83d3d0738da085000325531c82e42`. The default `src/main.asm`
entrypoint, Japanese HSP-05 hashes, and complete 1.0 gate remain unchanged.
The development manifest is `config/source_reconstruction_2_0.json`.

The 2.0 release turns the exact source into a safely editable, profile-aware
base. Its intended acceptance boundary contains seven additions:

1. A shared-source, byte-identical Castlequest USA profile with direct runtime
   coverage and isolated private CHR extraction.
2. A fixed-layout demonstrator with its own output, manifest, changed-byte
   allowlist, and focused runtime observation.
3. Headless, profile-aware room and object codecs with fixed capacities and an
   exact zero-edit container round trip, followed by equivalent authoring for
   music and the remaining significant binary formats.
4. Thin visual editors built on the same validated codecs, with levels taking
   priority over the other content studios.
5. A `source-2-check` gate that first runs the complete 1.0 contract and then
   validates every accepted profile, experimental build, codec, and document.
6. Runtime-faithful editor presentation, a navigable 100-room castle overview,
   and directly testable editor actions built on the canonical codecs.
7. Bounded source, tooling, test, configuration, documentation, and Make
   layouts with checked public entry points and release paths.

The initial USA survey found only 26 changed PRG bytes, all inside four existing
semantic modules. CHR banks 0 and 2 are identical, while localized graphics
occupy bounded suffixes of banks 1 and 3. This supports a revision define over
the common entrypoint; it does not justify a copied USA source tree.

Expanded ROMs, systematic relocation, GUI-only serialization paths,
additional regional profiles, and sibling engines are outside the planned 2.0
boundary. The visual studios included in 2.0 are deliberately thin front ends
to the same validated headless codecs used by the release gate.

## Delta history coverage

The machine-readable delta covers all 33 substantive commits after the Source
1.0 predecessor through `6f580866aa2229be06188dde27649b75514c89c3`. The audit
allows later commits to touch only this document and the Source 2.0 manifest;
any later source, tool, test, scenario, or general documentation change must
advance the boundary and update the delta before the release can pass.

The original twelve delta records cover the Source 2.0 boundary, Castlequest
profile, fixed-layout proof, three authoring pipelines, runtime evidence, and
aggregate gate developed from `a3f55fc` through `43bfcb0`. Later work is
assigned explicitly as follows:

- `editor-fidelity-and-castle-overview` covers authentic rendering, music
  lanes and previews, coordinate corrections, and the navigable full-castle
  view from `9d84bb4` through `4899c9f`;
- `editor-quality-contract` covers the two-profile editor gate and tested GUI
  runtime action in `587768b`;
- `semantic-source-hierarchy` covers bounded ASM modules and debugger source
  coverage from `97b5387` through `73a47f1`;
- `repository-responsibility-layout` covers the scripts, mirrored tests,
  configuration, and documentation reorganization from `ac833d5` through
  `096aa92`;
- `public-workflow-surface` covers the reduced README, modular Make rules,
  ROM-less scaffold gate, and categorized help from `d1f6366` through
  `43ba1da`;
- `release-path-hardening` covers the repaired inherited audit, relocated
  runtime manifests, declared release ref, and delta-history enforcement in
  `6f58086`.

## Development sequence

- [x] Pin the predecessor tag and commit.
- [x] Record complete Japanese and USA reference identities.
- [x] Map every USA PRG difference to current semantic ownership.
- [x] Build Castlequest from the shared source and a private profile asset.
- [x] Add direct Castlequest startup and menu runtime evidence.
- [x] Add an isolated fixed-layout variant and exact allowlist.
- [x] Add profile-aware room/object decode and encode workspaces.
- [x] Prove zero-edit full-container level round trips for both profiles.
- [x] Move revision-specific binary data into reproducible split assets.
- [x] Add the visual level editor on top of the validated headless codec.
- [x] Add direct selected-room playtesting through the normal room loader.
- [x] Add profile-aware textual music decode, validation, and fixed-arena
  rebuilds.
- [x] Add a visual music studio over the canonical headless codec.
- [x] Add fixed-layout graphics, palettes, cell visuals, metasprites, text, and
  sound-effect parameter authoring.
- [x] Add a visual graphics studio over the canonical headless codec.
- [x] Record why a separate world-routing studio is not applicable to this
  fixed 10 by 10 castle topology.
- [x] Make Studio checks and point-playtest evidence independent of ignored
  user workspaces.
- [x] Add the Source 2.0 manifest audit and aggregate pre-tag/post-tag gates.
- [x] Bring room, object, player, water, music, and graphics previews in line
  with reconstructed runtime data and add the navigable castle overview.
- [x] Reorganize source, tooling, tests, configuration, docs, and Make rules
  behind validated public entry points.
- [x] Re-run the release-contract review and protect relocated runtime paths
  plus complete delta history with regression tests.

Every implementation item passes through `make source-2-check`. The manifest
is `tag-ready` after the complete development gate and release-contract review;
the annotated `source-reconstruction-2.0` tag is created only after the clean
pre-tag gate and final release commit.
