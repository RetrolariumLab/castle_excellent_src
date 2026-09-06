# Content authoring

Source Reconstruction 2.0 introduces profile-aware, fixed-layout content
authoring. The first supported studio is the level pipeline because rooms are
the central editable game resource. It owns all 100 compressed 20 by 20 cell
maps, their static object lists, room pointers, object counts, and persistent
state offsets.

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

The current interface is intentionally headless. A visual editor will use this
same codec and validation model rather than introducing a second serializer.
