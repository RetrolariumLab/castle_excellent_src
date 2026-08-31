# PRG subsystem landmarks

The canonical reconstruction remains one address-ordered translation unit.
Subsystems begin as landmarks in preservation regions and are promoted to
physical source modules only when their boundaries and contracts are proven.
The room decoder is the first promoted module.

## Platform I/O (`$8000-$8224`)

This area combines Famicom expansion-port/tape signaling, controller polling,
PPU state helpers, and CNROM selection. Controller code at `$80FF-$8157` now
lives in `src/input/controllers.asm`. Both pollers strobe `$4016`, read eight
serial samples from `$4016` or `$4017`, prefer D0 when it is set, otherwise use
D1, and rotate the result into `$20` in NES button order. The controller-2
poller additionally enables NMI before returning. Six bytes at `$8135-$813A`
encode a plausible unused wrapper but remain raw because no static or runtime
entry reaches them.

PPU/CNROM code at `$8158-$817F` lives in `src/system/ppu.asm`.
`DisableNmi` and `EnableNmi` write fixed gameplay PPUCTRL modes `$30/$B0`;
`DisableRendering` and `WaitForVblankAndEnableRendering` use PPUMASK `$00/$1E`.
`SelectChrBank` indexes `$00,$01,$02,$03` and writes the selected value back to
the same ROM-table address, a bus-conflict-safe CNROM latch pattern.

The surrounding tape routines are intentionally still address-named. They toggle
and sample bit 1 of `$4016`, but the complete save/load protocol and its
Japanese peripheral contract have not yet been proven.

## Main loop and game/object logic (`$8225-$B7AC`)

`Reset` and the main loop at `$8225-$82CD` now live in
`src/system/startup.asm`. Reset waits for two vblanks, establishes the stack,
checks the `POW` RAM sentinel against the `POWER` ROM text, clears score and
counter state only after a signature mismatch, and increments a persistent
16-bit reset counter. The main loop runs map and pause input first, then player,
object, collision, room-cell animation, scrolling, sprite, and sub-command
phases. NMI owns a saturating countdown initialized to two, so each main update
is separated by two NMI ticks.

`LoadRoom` at `$A35C` is the next strong high-level landmark in this region: it
clears the 24 six-byte runtime object records,
calls `DecodeRoom`, loads static and tile-derived objects, applies persistent
state, resets all 23 NMI task requests, initializes both nametables and sprite
buffers, writes the status area, builds and uploads both attribute tables,
clears per-room runtime state, and selects the room audio track. The routine is
now isolated in `src/game/rooms/load_room.asm` rather than preservation code.

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

`Nmi` and `NmiFrame` at `$C55D-$C6B8` now live in `src/system/nmi.asm`.
They preserve A/X/Y and dispatch through 23 high/low frame-task pointers before
performing OAM DMA, scroll-latch updates, request scheduling, controller/demo
polling, eight modular timers, audio work, and the shared epilogue. The handler
tables at `$C88E-$C8BB` are typed data and independently decoded.
`BuildDmaOam` and `ReverseDmaOam` at `$C6B9-$C803` now live in
`src/rendering/oam_dma.asm`. They transpose the staging OAM at `$0300` into DMA
OAM at `$0200` in an eight-frame rotated order and reverse all 64 hardware
sprite records in place. Fifteen rotation offsets at `$C79D-$C7AB` are
reachable; `$C7AC` is a separate unused data byte.

`UploadStatusTiles` and the handler tables at `$C804-$C8BB` live in
`src/rendering/status_upload.asm`. When the foreground formatter is idle, task
zero writes five score, six inventory, and two lives tiles to the HUD. A busy
formatter delegates to `UploadRoomCellRow00`, avoiding a partially formatted
display. The exact 23 pointers resolve to status, 20 room rows, and two
attribute-table tasks.

The 20 room-row tasks at `$C8BC-$E1F7` are semantic modules grouped five
rows per file. Each maps 20 decoded cells through the left/right tile tables,
writes 14 metatiles to the left nametable and 6 to the right, then rejoins
`NmiFrame`. `room_attribute_upload.asm` completes `$E1F8-$E45C`: the left task
writes 56 scratch bytes directly, while the right task expands 28 significant
bytes into 52 writes by repeating edge attributes and then balances its timing.
Runtime CDL was essential across these indirect entries because vanilla
recursive analysis missed code that was observed executing.

Room-load screen initialization at `$B64C-$B7FC` is separately promoted.
`ClearRoomNametablesAndSprites` fills the two nametables, clears both 64-byte
attribute tables, fills both OAM buffers with `$F0`, waits for vblank, and
performs DMA. `InitializeRoomStatusDisplay` writes four terminated tile streams
and formatted score tiles, then seeds 16 attribute bytes.
`UploadRoomAttributeTables` copies the two 64-byte scratch tables to `$23C0`
and `$27C0`. `ResetNmiTaskRequests` at `$9578` fills `$0785-$079B` with `$FF`.

## Room and object data pipeline (`$E45D-$F8FB`)

The proven decoder subrange `$E45D-$E8DE` lives in
`src/game/rooms/decoder.asm`. Its codebook, pointer table, masks, PPU bit reader,
16-byte lookahead, and 400-cell output loop form one closed source module.
The immediately following `$E8DF-$EA35` range lives in
`src/rendering/room_attributes.asm`; it builds both nametable attribute tables
and requests their NMI uploads. The closed `$EB8F-$EC62` static-object range
lives in `src/game/objects/room_loader.asm`. The intervening room UI and later
transition logic remains preservation code until its mixed boundaries are
resolved.

`RoomCodebook`, `RoomPointerTable`, `ReadRoomBit`, `RefillRoomBitWindow`, and
`DecodeRoom` recover 400 cells from CHR banks 2 or 3. `BuildRoomAttributeTables`
uses the lower stack page as two 64-byte nametable attribute buffers.
`LoadRoomObjects` expands terminated triples into the six-byte runtime pool;
`SeekRoomObjectStream` locates a zero-based room list by counting `$FF`
terminators. Both routines now live in semantic object modules.

The adjacent `$EA36-$EB6B` UI module renders the 100-room castle map from
`RoomVisitedFlags`, and `$EB6C-$EB8E` finalizes a room screen by rebuilding its
palette/status state and requesting every NMI transfer task. This closes the
previous preservation gap between attribute construction and object data.

The independent parser proves 100 terminators, the exact `$EF6B-$F8FB`
object-stream boundary, and a byte-for-byte 2,449-byte encode round trip.
`RoomObjectStateOffsets` contains 101 cumulative offsets; each room width is
exactly `ceil(object count / 8)`, proving one persistent bit per static object
and 141 state bytes at `$0608-$0694`.

`RoomMutableCellStateOffsets` is a second 101-entry table. For rooms 1-99 its
width is `ceil(candidate cell count / 8)` for cells `$19,$1C,$1F,$22,$25,$29`
and `$54`; room 100 explicitly reserves three bytes. The resulting 108 bytes
live at `$0590-$05FB`. `LoadRoomPersistentState` expands both variable-width
bitmaps into a nine-byte current-room state, while `SaveRoomStateSnapshotB`
writes the corresponding snapshot back. Two nine-byte snapshot slots at
`$0724` and `$072D` support room and sub-command transitions.

`ApplyRoomPersistentState` consumes those active bitmaps after the static
objects have been loaded. A set static-object bit clears the corresponding
six-byte runtime record. Set mutable-cell bits select ordinals 1-39 in a
row-major scan and replace each selected cell with either `$54/$55` or
`$62/$63`, depending on its neighboring cell. The two candidate predicates
cover the left/top values `$19,$1C,$1F,$22,$25,$29` and the paired right values
`$1A,$1D,$20,$23,$26,$2A`.

`RoomObjectCounts` agrees with all 100 terminated static-object lists.
`RuntimeObjectOffsetByCount` maps counts 0-24 to six-byte record offsets, so
cell-derived objects begin immediately after each room's static records. Five
room-cell markers create runtime types `$A1-$A5`; the complete room set contains
176 such markers. Static and cell-derived objects together peak at 22 records,
within the 24-record pool.

`LoadRoomObjectsAndState` at `$EC63` rotates the nine-byte state and 14-byte
runtime snapshots before selecting the incoming room state. A matching room id
restores snapshot B; otherwise the persistent stores are loaded. The selected
state and 15 active runtime bytes are copied to load mirrors before execution
falls through to `ApplyRoomPersistentState`. `SelectAndApplyRoomState` at
`$EC8A` is also a standalone entry used after loading a saved game.

The loader's type lookup logically spans 61 bytes from
`$EB8F`, while its state lookup starts at `$EBC0`; their views intentionally
overlap. Physical typed-data ranges remain non-overlapping. Address ordering
alone must not be used to classify any other unobserved byte.

## Tail tables and vectors (`$F8FC-$FFFF`)

This region mixes additional game/UI routines with lookup tables. The final
known tables map each logical room cell to its left and right background tile,
followed by the NMI, reset, and IRQ vectors. It should remain mixed until more
static consumers and runtime scenarios establish tighter boundaries.
