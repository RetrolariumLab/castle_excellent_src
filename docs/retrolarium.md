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

## The game's names and tables

Retrolarium keeps nothing taken from the game; this repository gives it what it
needs. `config/names.json` holds the game's own names (its object types) in
English, and the lists that carry them (the player and object animations with
their frames). The studio and the kit read it when a project opens and show the
names as they are, untranslated; without it they show numbers instead. Its
`guard` list names what Retrolarium's own repositories must never contain.

`config/game_profile.json` is the game's Retrolarium profile: its revisions with
their hashes and, for each resource, where it lies in each revision's image and
which codec reads it. The kit reads it when it opens `castle_excellent.rlj` or a
project made from it; Retrolarium keeps no copy.

## Checking the repository

`make studio-check` runs `rltool studio check castle_excellent.rlj`. In a
throwaway copy of the repository it prepares both revisions, decodes and
validates each document and rebuilds each revision with no edits, requiring the
original ROM byte for byte. It needs the revisions' ROMs and the Retrolarium kit
(`rltool` on `PATH`, or `RLTOOL=...`), and never reads or writes `hack/` or
`.retrolarium/`.
