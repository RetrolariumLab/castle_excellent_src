# Source Reconstruction 2.0

Source Reconstruction 2.0 inherits the immutable
`source-reconstruction-1.0` release at commit
`6ae3cc3505c30cc77941703e025c46aab88e7d2a`. The default `src/main.asm`
entrypoint, Japanese HSP-05 hashes, and complete 1.0 gate remain unchanged.
The development manifest is `config/source_reconstruction_2_0.json`.

The 2.0 release turns the exact source into a safely editable, profile-aware
base. Its intended acceptance boundary contains five additions:

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

The initial USA survey found only 26 changed PRG bytes, all inside four existing
semantic modules. CHR banks 0 and 2 are identical, while localized graphics
occupy bounded suffixes of banks 1 and 3. This supports a revision define over
the common entrypoint; it does not justify a copied USA source tree.

Expanded ROMs, systematic relocation, GUI-only authoring, additional regional
profiles, and sibling engines are outside the planned 2.0 boundary. These
capabilities remain explicit rather than being inferred from the version
number.

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
- [ ] Add the remaining significant content authoring formats.
- [ ] Add the Source 2.0 manifest audit and aggregate pre-tag/post-tag gates.

Until every unchecked item passes, the manifest remains `development` and no
`source-reconstruction-2.0` tag is created.
