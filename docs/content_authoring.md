# Content authoring

Source Reconstruction 2.0 introduces profile-aware, fixed-layout content
authoring. The first supported studio is the level pipeline because rooms are
the central editable game resource. It owns all 100 compressed 20 by 20 cell
maps, their static object lists, room pointers, object counts, and persistent
state offsets. The second headless pipeline owns the eight music track records
and 21 textual MML streams.

The machine-readable layout and capacity contract is
`config/level_authoring.json`. Local JSON workspaces live below the ignored
`content/workspace/` directory. Generated ROMs and reports live below the
ignored `build/authoring/` directory. Neither original ROMs nor decoded local
workspaces are committed.

## Commands

Select a revision through `REVISION_PROFILE`. The default is currently
`castlequest-usa`:

```console
make init-levels REVISION_PROFILE=castle-excellent-japan-hsp-05
make validate-levels REVISION_PROFILE=castle-excellent-japan-hsp-05
make build-levels REVISION_PROFILE=castle-excellent-japan-hsp-05
make roundtrip-levels REVISION_PROFILE=castle-excellent-japan-hsp-05
```

`init-levels` creates a workspace only when one does not already exist.
`export-levels` deliberately replaces it from the selected baseline.
`validate-levels` checks the complete model and reports how many ROM bytes the
current workspace changes. `build-levels` writes an isolated playable iNES
image. `roundtrip-levels` performs an in-memory decode and encode and requires
the complete output container to match the selected revision byte for byte.

Music uses an equivalent profile-aware command set:

```console
make init-music REVISION_PROFILE=castle-excellent-japan-hsp-05
make validate-music REVISION_PROFILE=castle-excellent-japan-hsp-05
make build-music REVISION_PROFILE=castle-excellent-japan-hsp-05
make roundtrip-music REVISION_PROFILE=castle-excellent-japan-hsp-05
```

`init-music` preserves an existing ignored workspace and `export-music`
replaces it from the selected baseline. `validate-music` checks the MML grammar,
all stream references, track records, and fixed arena capacity. `build-music`
writes an isolated playable ROM and a JSON report below `build/authoring/`.
`roundtrip-music` requires a zero-edit decode and encode to reproduce the
complete selected ROM byte for byte.

## Workspace model

Each room contains a 20-row by 20-column `cells` grid and an `objects` list.
Object records expose the three physical fields used by the game:
`encoded_type`, `x`, and `y`. Derived runtime types, handlers, screen
coordinates, attributes, pointers, counts, and state offsets are rebuilt and
validated rather than stored as independently editable duplicates.

The encoder uses the original prefix codebook. Rooms 1 through 67 share the
8,192-byte arena in CHR bank 2; rooms 68 through 100 use the first 5,120 bytes
of CHR bank 3. Streams are repacked within their original bank and the pointer
table is regenerated. A room cannot use a cell without a codebook entry or
overflow its bank arena.

The terminated object stream has a fixed 2,449-byte PRG capacity. Each room
may use at most 24 runtime records, including objects spawned from room-cell
markers. Object persistent state has 141 bytes and mutable-cell state has 108
bytes. Edits that exceed any physical or RAM capacity fail before a ROM is
written.

The headless commands remain the canonical serialization and release-gate
interface. The visual editor uses this same codec and validation model rather
than introducing a second serializer.

## Visual Level Studio

`make level-studio` (or the `level-editor` alias) opens the dependency-free
Tkinter editor for the selected `REVISION_PROFILE`. It renders all 100 rooms
from CHR bank 0, the reconstructed left/right tile tables, and the room palette
and attribute rules. The cell palette offers exactly the 63 symbols accepted by
the original prefix codebook.

Left-click or drag to paint cells, right-click to sample a cell, and use the
Objects tab to place, edit, or delete static object records. Object markers show
both their stored encoded type and their derived runtime type. Every edit is
checked against room compression arenas, the 24-record runtime pool, the fixed
object-stream range, and both persistent-state capacities before it enters the
undo history.

Place player selects a room-local point, and Play builds the current workspace
before launching the pinned FCEUX runtime. A short Lua bootstrap presses Start,
selects the current room immediately after the game's own new-game store, lets
the normal room loader run, and places the player at the selected 320 by 160
pixel coordinate. The bootstrap then ends so physical controller input returns
to the user. It does not patch the authored ROM or bypass its room loader.

Save writes only the ignored JSON workspace. Build ROM writes the isolated
authoring image and capacity report declared by `config/level_authoring.json`;
it never replaces a reference ROM or the normal profile build. The Studio uses
the same `validate_workspace` and `compose_levels` functions as the headless
commands. `make check-level-studio` validates the complete display model without
opening a window, so it is suitable for release gates and headless CI.
`make smoke-level-playtest REVISION_PROFILE=castlequest-usa` additionally runs
FCEUX to prove the selected room and player coordinates are observed live.

## Music workspace

The machine-readable music layout is `config/audio_authoring.json`. Each JSON
workspace exposes eight track sets. A track set selects up to three stream IDs
and retains its two channel parameters. The 21 streams contain ASCII MML text
and an optional restart stream ID; no raw pointer is editable.

The encoder repacks every text stream into the original `$BBE7-$C20D` PRG
arena, recalculates all track and restart pointers, and rejects content larger
than the fixed 1,574-byte capacity. It then writes the original eight-record
table at `$B8C6`. Header and CHR data are copied unchanged. Both supported
profiles share this format and independently pass full-container zero-edit
round trips.

The JSON format intentionally preserves the engine's textual command language
instead of translating it into a lossy note grid.

## Visual Sound Studio

`make sound-studio` (or the `music-editor` alias) opens the dependency-free
Tkinter editor for the selected profile. Its stream navigator exposes the 21
MML texts and their restart destinations. Its track-set panel maps the three
NES music channels to stream IDs and edits both raw channel parameters using
decimal, `0x`-prefixed, or `$`-prefixed byte notation.

Apply stream and Apply track validate the entire workspace and compose a full
ROM in memory before accepting an edit. Undo retains the previous 40 accepted
states. Save and Build ROM use `music_editor.validate_workspace` and
`music_editor.compose_music`, the same functions as the headless commands.
Thus the GUI cannot silently accept a grammar, pointer, or arena overflow that
the release pipeline would reject.

`make check-sound-studio` loads every stream and track through the display
model and composes the selected profile without opening a window. This is the
GUI-independent release-gate target; normal visual editing does not require a
third-party toolkit beyond Python's Tkinter.
