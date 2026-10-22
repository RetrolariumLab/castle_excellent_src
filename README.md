# Castle Excellent NES source reconstruction

A byte-identical ca65 reconstruction of **Castle Excellent** (`HSP-05`) on
Famicom and **Castlequest** on NES, edited in Retrolarium Studio. Both
revisions build from shared PRG source; the ROM-derived assets stay private.

## Status

Source Reconstruction 3.1. Editing happens in Retrolarium Studio:
`castle_excellent.rlj` opens both revisions
([`docs/retrolarium.md`](docs/retrolarium.md)).

3.1 keeps only what builds and checks the source. The earlier releases' Ghidra
regeneration pipeline and its ledgers, audits, runtime evidence, FCEUX
scenarios and debugger exports remain in the history (tags
`source-reconstruction-1.0` to `3.0`); the source is now edited directly.

## Quick start

You need Python 3.11 or later, GNU Make and Retrolarium Kit (`rltool` on
`PATH`, or `RLTOOL=...`); the kit supplies ca65 and ld65 and checks them. Copy
your `Castle Excellent (J).nes` into the repository root, then:

```bash
make           # the targets
make split     # cut the private assets out of the ROMs (once)
make verify    # build and compare byte for byte
```

For Castlequest, add `Castlequest (U) [!].nes`, run `make split` again and
`make verify REVISION=castlequest-usa`. `assets/manifest.json` names both ROMs
and the assets cut out of them (`rltool assets`, Retrolarium Kit). ROMs,
extracted assets and build products are ignored by Git.

## Targets

```bash
make build / verify [REVISION=<id>]     # one revision (Japanese unless given), in build/revisions/<id>/
make verify-revisions                   # every revision whose ROM is here
make build-relocated [REVISION=<id>]    # every module moved (code and data), in build/relocated/<id>/
make studio-check                       # open and rebuild the revisions here
make test / test-full / golden          # the checks
make play [MOVIE=attract]               # watch a movie in MAME
make lint / format / hooks / clean
```

Each revision builds from its entry file, `src/revisions/<id>.asm`, which sets
`CASTLEQUEST_USA` and includes `src/main.asm`.

## Tests

`make test` (about fifteen seconds) runs the unit tests, verifies every ROM
that is here byte for byte, builds each relocated and runs the studio check.

`make test-full` adds the attract mode played in MAME on each relocated build
(`scripts/build/relocate.py`: a byte at the start of PRG and after every
module, so each moves further than the one before, absorbed by the padding
before the fixed tile tables). With no input the game shows its title and
plays its one demo (72 commands in the title room), which resets to the title;
3,000 frames cover that once. At ten checkpoints the room, lives, score, demo
flag, inventory and player position must equal what the original ROM gives
(`movies/attract.check.json`, `movies/attract-castlequest.check.json`). The
player position may trail by up to a cell (16 pixels across, 8 down): a moved
routine can cross a page boundary and cost the odd lag frame. The movie reaches
the demo's paths only: no room change, death, lift or Witch runs. Name MAME
once with `rltool movie mame <path>` (or `MAME=<path>`); `make golden` records
the reference values again. Name MAME once with `rltool movie mame <path>`
(or `MAME=<path>`); `make golden` records
the reference values again.

`make play MOVIE=attract` shows a movie in a MAME window at the game's
speed, on the relocated build (or on `ROM=<image>`), and compares its cells
with the original's once the window is closed; in MAME, F10 lifts the speed
limit and Insert fast-forwards. `FRAMES=<frame>` closes MAME at that frame, `CLOSE=1`
when the movie ends. `make play` alone plays `attract`.

## Repository map

```text
src/           ca65 source (main.asm includes the PRG modules in CPU order)
src/revisions/ one entry file per revision, and the revisions' constants
config/        linker layout, lint, names, profile
assets/        manifest.json (the extracted assets are ignored)
scripts/build/ relocate.py, the relocated build's source rewrite
tests/         its unit tests
movies/        the attract-mode checks
docs/          architecture, subsystems, RAM map, data formats
castle_excellent.rlj   the Retrolarium project
```

## Research and rights

The reconstruction builds on the published Castle Excellent room-data
analysis and extractor:

- <https://habr.com/ru/articles/991848/>
- <https://github.com/wizzard2010/cex>

The upstream extractor had no explicit license when inspected and is not
bundled. Original game code, graphics, music, and room data remain property of
their respective rights holders. Users must supply their own lawful ROMs.

## Trademarks

This is an unofficial reconstruction, made for study and preservation. The game,
its title and its characters are trademarks of their owners, who have not made,
licensed or endorsed this project. It contains no part of the game: you need
your own copy of Castle Excellent to build anything.
