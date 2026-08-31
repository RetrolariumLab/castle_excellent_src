# PRG subsystem landmarks

The canonical reconstruction remains one address-ordered translation unit.
Subsystems begin as landmarks in preservation regions and are promoted to
physical source modules only when their boundaries and contracts are proven.
The room decoder is the first promoted module.

## Platform I/O (`$8000-$8224`)

This area combines Famicom expansion-port/tape signaling, controller polling,
PPU state helpers, and CNROM selection. The controller routines strobe `$4016`
and shift eight serial bits from `$4016` or `$4017`. `DisableNmi`, `EnableNmi`,
`DisableRendering`, and `WaitForVblankAndEnableRendering` are named directly
from their PPU register writes. `SelectChrBank` writes one of four values to the
CNROM bank latch.

The earlier tape routines are intentionally still address-named. They toggle
and sample bit 1 of `$4016`, but the complete save/load protocol and its
Japanese peripheral contract have not yet been proven.

## Main loop and game/object logic (`$8225-$B7AC`)

`Reset` initializes persistent markers, then enters a frame loop synchronized
by an NMI-owned countdown. `LoadRoom` at `$A35C` is the strongest high-level
landmark in this region: it clears the 24 six-byte runtime object records,
calls `DecodeRoom`, loads static and tile-derived objects, builds attribute
tables, and finishes PPU setup.

The indirect object dispatcher uses `ObjectHandlerTable` at `$AD93`. Most
individual handlers remain generically named until object-specific traces
prove their state transitions.

## Audio interpreter (`$B906-$C43C`)

The audio core owns three four-byte stream states beginning at `$DB` and walks
textual commands. `UpdateAudioStreams` calls `UpdateAudioStream` with X equal to
0, 4, and 8; `AdvanceAudioStream` increments the selected 16-bit stream pointer.
`AudioTrackTable` selects three streams plus two channel parameters from each
eight-byte record. `MusicMmlData` is a gap-free sequence of 21 streams using
octave, tempo, default-length, volume, note, rest, accidental, explicit-length,
and dotted-length tokens. A zero terminator is followed by a restart pointer or
`$0000`. `StopAudioStreams` disables `$4015` and clears the three pointers.
Seven small entry points select record offsets 0-5 and 7 before joining
`LoadAudioTrackSetByOffset`; record 6 has no statically established selector.

The stream bytes and interpreter tables are now independently validated, while
the broad subsystem end remains provisional because sound-effect helpers and
data tables are interleaved.

## NMI, sprites, and PPU transfers (`$C43D-$E45C`)

`Nmi` preserves A/X/Y and dispatches through a frame-task table before entering
`NmiFrame`. The latter performs OAM DMA, scroll updates, controller polling,
timers, audio work, and the NMI epilogue. `BuildDmaOam` copies the staging OAM
at `$0300` into DMA OAM at `$0200` in a frame-rotated order. `ReverseDmaOam`
reverses hardware sprite entries in place.

The large execution-proven area from roughly `$C804` through `$E45C` contains
many unrolled `$2007` writes. Runtime CDL was essential here: vanilla recursive
analysis missed several indirect entries even though every observed byte was
executed as code.

## Room and object data pipeline (`$E45D-$F8FB`)

The proven decoder subrange `$E45D-$E8DE` lives in
`src/game/rooms/decoder.asm`. Its codebook, pointer table, masks, PPU bit reader,
16-byte lookahead, and 400-cell output loop form one closed source module.
The immediately following `$E8DF-$EA35` range lives in
`src/rendering/room_attributes.asm`; it builds both nametable attribute tables
and requests their NMI uploads. The closed `$EB8F-$EC62` static-object range
lives in `src/game/objects/room_loader.asm`. The intervening room UI and later
transition/persistence logic remain preservation code until their mixed
boundaries are resolved.

`RoomCodebook`, `RoomPointerTable`, `ReadRoomBit`, `RefillRoomBitWindow`, and
`DecodeRoom` recover 400 cells from CHR banks 2 or 3. `BuildRoomAttributeTables`
uses the lower stack page as two 64-byte nametable attribute buffers.
`LoadRoomObjects` expands terminated triples into the six-byte runtime pool;
`SeekRoomObjectStream` locates a room in `RoomObjectStream`.

The independent parser proves 100 terminators and the exact `$EF6B-$F8FB`
object-stream boundary. The loader's type lookup logically spans 61 bytes from
`$EB8F`, while its state lookup starts at `$EBC0`; their views intentionally
overlap. Physical typed-data ranges remain non-overlapping. Address ordering
alone must not be used to classify any other unobserved byte.

## Tail tables and vectors (`$F8FC-$FFFF`)

This region mixes additional game/UI routines with lookup tables. The final
known tables map each logical room cell to its left and right background tile,
followed by the NMI, reset, and IRQ vectors. It should remain mixed until more
static consumers and runtime scenarios establish tighter boundaries.
