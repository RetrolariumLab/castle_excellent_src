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

`SelectChrBank` loads one of the bytes `$00,$01,$02,$03` from its ROM table and
writes it back to the same indexed ROM address. The data driven onto the CPU
bus therefore matches the selected latch value, preserving CNROM operation on
boards with bus conflicts.

## Reset and frame pacing

Reset waits for two PPU vblanks before setting the stack pointer. It compares
RAM `$077E-$0780` with the first three bytes, `POW`, of the ROM text `POWER` at
`$82C9-$82CD`. A mismatch is a cold boot: the sentinel, two-byte player score,
and two-byte reset counter are initialized. Both cold and warm paths then
increment the counter before entering the title and room-loading sequence.

The main loop initializes `$FC` to two and waits for NMI to decrement it to
zero. NMI uses a saturating decrement, so the foreground executes one complete
game update per two NMI ticks. Castle-map mode skips all frame work; pause mode
keeps scrolling, sprite construction, and sub-command input active while
skipping player, object, collision, and room-cell simulation.

NMI dispatches one of 23 PPU tasks through separate high- and low-byte tables.
After the selected task reaches the common frame handler, it performs OAM DMA,
rebuilds the DMA buffer when the staging buffer is free, applies a pending
horizontal-scroll latch, clears the completed request, and scans forward for
the next nonzero request. Reaching the end wraps directly to task zero.

The same handler polls both controllers during play or obtains controller 1
from the demo stream during attract mode; a second unconditional physical poll
allows Start to leave the demo. It also advances counters modulo
`3,5,6,7,3,10,11,30` and updates music and sound effects only while unpaused.

The OAM builder views the 64 staging records as an 8x8 matrix. For each of eight
32-byte output blocks it selects a column from the staging matrix and writes
those eight sprites contiguously. The selected column advances with the low
three bits of the global frame counter, distributing sprite priority across
frames. A separate routine reverses all 64 records without reversing bytes
inside a record. The rotation table contains 16 physical bytes, although the
sum of frame 0-7 and block 0-7 can reach only index 14.

NMI task zero uploads live HUD tiles only when `StatusTilesBusy` is clear. It
writes five score tiles at `$2096`, six inventory-counter tiles at `$2087` in
source order `0,1,5,4,3,2`, and two lives tiles at `$20A8` in source order
`1,0`. When the foreground formatter owns those buffers, the handler delegates
to task one's first 20-cell room-row upload instead of reading partial data.

Tasks 1-20 upload one decoded room row each. Every fixed-size handler reads 20
consecutive values from the 400-byte `RoomCells` matrix and maps each through
`LeftTileByCell` and `RightTileByCell`. Columns 0-13 produce 28 tiles in the
left nametable; columns 14-19 produce 12 tiles in the right nametable. The first
destinations are `$20E4/$24E0`, each later task advances both by one 32-byte
nametable row, and the last pair is `$2344/$2740`.

Tasks 21 and 22 finish the room transfer with nametable attributes. The left
task copies scratch offsets `$08-$3F` directly to `$23C8`. The right task reads
four meaningful bytes from each eight-byte scratch row, repeats the fourth byte
across the unused right edge for the first six rows, keeps four bytes in the
last row, and writes 52 bytes at `$27C8`. Its short delay balances the smaller
right-side workload before both paths rejoin `NmiFrame`.

The castle map is a 10x10 projection of the 100 room flags. A visited room
writes tiles `$07-$0A` as a 2x2 marker whose top-left address is
`$20C6 + row*$40 + column*2`. The current one-based room selects an 8x16 OAM
marker at `Y=$33+row*$10`, `X=$34+column*$10`. Select opens the map when the map
item is available; A, B, or Select returns through normal room finalization.

## Controller input

Both controller pollers pulse `$4016` high then low and consume eight serial
samples. Each sample uses D0 when set; if D0 is clear, a second shift selects
D1. Eight rotations place A, B, Select, Start, Up, Down, Left, and Right in bits
0-7 of `$20`. The NMI-safe wrappers return that byte in A. Controller 1 also
has a wrapper for callers that already control NMI; controller 2's poller
itself enables NMI before returning.

## Famicom data I/O

The Japanese save/load path supports two transports selected by the sign bit
of contextual zero-page `$1F`. Negative selects pulse-width signaling through
bit 1 of `$4016`; nonnegative selects an expansion serial protocol that writes
clock/data phases to `$4016` and samples D2 from `$4017`. Both byte paths are
MSB-first and share `$17` as their shift buffer. The common wrappers preserve
X in `$1A`; pulse receive and preamble validation return carry set on failure.

Pulse bytes begin with one long framing cycle. Each zero is one long cycle;
each one is two short cycles; four short stop cycles follow the eight data
bits. The transmitted leader is 33 groups of 256 short pairs. Expansion
transactions strobe `$00,$02`, send `00 AA 55`, and transfer each bit with
clock-high then clock-low writes while holding the data bit stable. The
receiver ignores the first byte and validates the following `AA 55` pair.

The caller serializes the current room and all mutable/persistent room state.
This proves the software protocol but not the exact external accessory, so
module and symbol names remain peripheral-neutral.

The wire payload after the transport preamble is exactly 394 bytes. Its first
two bytes are current room and runtime-tail state, followed by 14 runtime bytes.
The next blocks read RAM in descending address order: 120 bytes from
`$0607-$0590`, 150 from `$069D-$0608`, and 100 visited flags from
`$0701-$069E`. Eight bytes `BEDEUTUN` terminate the payload. ROM stores the
nine-byte reverse text `GNUTUEDEB` at `$FC99`; the loops use indexes 8 through
1, deliberately excluding the first physical `G`.

Load mirrors these traversals and validates the signature before rebuilding
the room, objects, attributes, scroll, and mutable cell beneath the restored
player position. Carry errors are checked for the room byte and every repeated
region byte. The single runtime-tail byte at payload offset 1 is stored without
a carry check, an original behavior retained by the reconstruction.

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
