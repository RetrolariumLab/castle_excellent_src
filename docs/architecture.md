# Architecture

The address-level subsystem inventory is maintained in
`docs/subsystems.md`. The PRG remains one address-ordered ca65 translation
unit, while proven ranges are gradually promoted from preservation regions to
semantic modules. The first promotion is the room decoder at `$E45D-$E8DE`.

## Cartridge layout

Castle Excellent is CNROM (mapper 3): one fixed 32 KiB PRG mapping at
`$8000-$FFFF` and four switchable 8 KiB CHR banks. CPU code is never PRG-bank
switched. Writing a bank-select value in the cartridge range changes the CHR
bank visible at PPU `$0000-$1FFF`.

The published routine at `$8175` selects CHR bank 0-3. The room loader selects
bank 2 for zero-based room indexes below `$43` and bank 3 for the remainder,
then restores bank 0 after decoding.

## Room pipeline

```text
room index
  -> pointer table at PRG $E71C
  -> CHR bank 2 or 3 bitstream
  -> buffered PPU reads through $2007
  -> 16-bit lookahead at RAM $0702-$0711
  -> prefix-code table near PRG $E45D
  -> 400 logical cells at RAM $0400-$058F
  -> cell attribute table at PRG $E9D2
  -> two 64-byte attribute buffers at RAM $0100-$017F
  -> two horizontal background tiles per logical cell
  -> two adjacent nametables plus attribute tables
```

At the top level, `LoadRoom` marks the one-based room as visited and clears the
entire 24-record object pool before decoding. It then invokes the object/state
pipeline, clears the 23 NMI task requests, initializes nametables and both OAM
buffers, writes the status area, builds and uploads attributes, resets room
runtime variables, and selects one of audio track sets 0, 1, or 3 unless room
flags suppress the change.

The logical room is 20x20 cells. One cell spans 16x8 pixels: X is doubled into
two background tiles, while Y advances by one tile. The rendered playfield is
therefore wider than one screen and uses two horizontal nametables.

The 16-byte RAM region is lookahead over future compressed bits, not an LZ
history window. Each byte contains ASCII `0` or `1` (`$30/$31`). The PRG table
stores an output cell value followed by its ASCII bit code and a zero
terminator. The decoder scans entries until one code matches the lookahead,
consumes that many CHR bits, and emits one cell.

## Objects and sprites

Static room objects form `(type, x, y)` triples terminated by `$FF`; the stream
occupies `$EF6B-$F8FB`. Loading expands each object into a six-byte record in
`$004A-$00D9`. The `$90`-byte pool therefore contains 24 records; the original
rooms use at most 18.

A 101-entry cumulative offset table assigns `ceil(object count / 8)` bytes to
each room. The resulting `$8D` bytes at `$0608-$0694` preserve one bit for each
static object across room transitions.

A parallel table assigns packed bits to seven mutable cell classes. Its
108-byte store at `$0590-$05FB`, the object-bit store, and a one-byte room id
form a nine-byte active record plus two transition snapshots. The load and save
paths use the same cumulative offsets, preventing one room from consuming a
neighbor's state bytes.

The state-application path treats a set object bit as removed and clears that
runtime record. Mutable-cell bits select candidates by one-based row-major
ordinal and restore one of two two-cell visual forms. Afterward five logical
cell markers become runtime types `$A1-$A5`; their records begin at the static
object count multiplied by six. Across the original rooms the combined count
peaks at 22 of the 24 available records.

The encoded type indexes a logical table beginning at `$EB8F`. Types through
`$3C` make that view overlap the state table beginning at `$EBC0`; the latter
is also indexed directly, but only for encoded types `$12-$29`. The loader
scales X by 16 and Y by 8 and initializes record byte `+4` from that state view.

Object type selects an indirect behavior handler through a table near `$AD93`.
The published analysis identifies 34 used types. Sprite helpers compose one,
two, or four hardware records in 8x16 sprite mode.

```text
room object stream
  + cell markers in decoded room
  + persistent object/cell bitmaps
  -> 24 x 6-byte runtime records at $004A
  -> indirect behavior dispatcher
  -> staging OAM at $0300
  -> reordered DMA OAM at $0200
  -> write $02 to $4014
```

The state orchestration before object-state application is:

```text
load static objects
  -> persist old snapshot B
  -> current state / load mirror become snapshots B / A
  -> live runtime / load mirror become runtime snapshots B / A
  -> restore snapshot B when its room id matches, else load persistent state
  -> refresh the nine-byte state and 15-byte runtime load mirrors
  -> apply object and mutable-cell bits and spawn cell-derived objects
```

## Attribute scratch in the stack page

Room attribute construction uses the lower half of page `$0100` as scratch.
This coexists with the hardware stack because active stack entries normally
occupy the upper part of the page. Runtime tracing must establish the exact
stack-depth invariant before this region receives a stronger contract.

`GetRoomAttributeMaskAndOffset` maps a logical cell to one of four NES
attribute quadrants and to the left or right 64-byte buffer. The builder copies
16 initial border bytes, walks all 400 cells, applies the 100-byte
`RoomCellAttributeValues` table, and raises NMI task requests 21 and 22. Their
handlers upload the left buffer to nametable `$23C8` and the right buffer to
`$27C8`.
