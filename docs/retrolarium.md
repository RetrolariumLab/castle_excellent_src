# Editing in Retrolarium

Castle Excellent and Castlequest are edited in Retrolarium Studio, not by tools
in this repository. Open `castle_excellent.rlj` at the repository root in the
studio. It asks which revision to edit, takes that revision's ROM (copied next
to `castle_excellent.rlj` and never committed) and keeps the edits in
`hack/<revision>/`. Builds go to `.retrolarium/`. Neither folder is tracked;
delete `hack/<revision>/` to start over from the original.

## Revisions

| Revision                        | ROM                        |
| ------------------------------- | -------------------------- |
| `castle-excellent-japan-hsp-05` | `Castle Excellent (J).nes` |
| `castlequest-usa`               | `Castlequest (U) [!].nes`  |

## What is edited

The kit's Castle Excellent profile defines every view; this repository only
names the revisions and the asset split. The studio offers:

- the 100 rooms with their objects, the castle map and the player start, with
  playtest from any room;
- the room cells, graphics, palettes, animations and sprite mappings;
- the screens and text;
- the music track sets and sequences, the sound effects and their parameter
  table;
- the title demo.

Capacities stay those of the original layout: each table keeps its place and
size, and the studio refuses an edit that would not fit.

## Checking the repository

`make studio-check` runs `rltool studio check castle_excellent.rlj`. In a
throwaway copy of the repository it prepares both revisions, decodes and
validates each document and rebuilds each revision with no edits, requiring the
original ROM byte for byte. It needs the revisions' ROMs and the Retrolarium kit
(`rltool` on `PATH`, or `RLTOOL=...`), and never reads or writes `hack/` or
`.retrolarium/`.

## Source Reconstruction 3.0

`config/source_reconstruction_3_0.json` is the 3.0 release manifest. It names
the descriptor, the profile and the revisions, the kit and studio versions the
release is checked with, and every removed editor with the view that replaced
it. `make source-3-audit` runs studio-check with `--release`, which also checks
that section against the descriptor and the running kit; `make source-3-check`
runs the Source 2.1 gate first. The manifest stays in `development` with the kit unpinned
until Retrolarium publishes its first tags.
