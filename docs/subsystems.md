# PRG subsystem landmarks

The canonical reconstruction remains one address-ordered translation unit.
Subsystems begin as landmarks in preservation regions and are promoted to
physical source modules only when their boundaries and contracts are proven.
The room decoder is the first promoted module.

## Platform I/O (`$8000-$8224`)

This area combines Famicom expansion-port/data signaling, controller polling,
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

The two data transports now live in `src/input/famicom_data_pulse.asm` and
`src/input/famicom_data_io.asm`. A negative selector at `$1F` chooses the
pulse-width path; a nonnegative selector chooses the expansion serial path.
The pulse sender uses one long cycle for a zero bit and two short cycles for a
one bit, with an 8,448-cycle leader. Its receiver measures bit 1 of `$4016` and
returns carry set when a sample window contains four or more edges.

The expansion path strobes `$4016` with `$00,$02`, sends `00 AA 55`, and then
transfers bytes MSB-first. Output data remains on bit 0 while bit 2 falls;
input data is sampled from bit 2 of `$4017`. The receiver discards the first
preamble byte, verifies `$AA,$55`, and reports failure in carry. Common byte
wrappers preserve X. Higher code at `$FBFE-$FDC4` now lives in
`src/game/save_load.asm`. It saves or loads a fixed 394-byte payload containing
the one-based room number, runtime state, 120 mutable-region bytes, 150 object-region
bytes, 100 visited flags, and an eight-byte signature. The exact external accessory remains deliberately
unnamed until hardware evidence distinguishes the two Japanese interfaces.

## Main loop and game/object logic (`$8225-$B7AC`)

`Reset` and the main loop at `$8225-$82CD` now live in
`src/system/startup.asm`. Reset waits for two vblanks, establishes the stack,
checks the `POW` RAM sentinel against the `POWER` ROM text, clears high score and
counter state only after a signature mismatch, and increments a persistent
16-bit reset counter. The main loop runs map and pause input first, then player,
object, collision, room-cell animation, scrolling, sprite, and sub-command
phases. NMI owns a saturating countdown initialized to two, so each main update
is separated by two NMI ticks.

`HandlePauseInput` at `$A8E3-$A959` detects new A/B and Start presses against
the saved controller mask. Start enters pause and disables every APU channel;
Start or A/B resumes. Paused Left/Right adjust the pending horizontal scroll in
four-pixel steps, request NMI application, and keep simulation stopped while
the normal render tail continues. Left has priority and the valid scroll domain
saturates at `$00-$80`.

`LoadRoom` at `$A35C` is the next strong high-level landmark in this region: it
clears the 24 six-byte runtime object records,
calls `DecodeRoom`, loads static and tile-derived objects, applies persistent
state, resets all 23 NMI task requests, initializes both nametables and sprite
buffers, writes the status area, builds and uploads both attribute tables,
clears per-room runtime state, and selects the room audio track. The routine is
now isolated in `src/game/rooms/load_room.asm` rather than preservation code.

The coordinate and mutable-cell path is now semantic at `$A58A-$A5DC`,
`$A66D-$A6C9`, and `$A70A-$A7DA`. It maps 16-bit pixel positions through a
40x20 background-tile domain into the 20x20 logical room, recognizes both
halves of mutable two-row forms, derives a one-based row-major ordinal, and
restores the selected cell pair. The restore path records the same ordinal in
the five-byte active bitmap and requests row plus attribute rendering work.
The 14 bytes at `$A596-$A5A3` resemble an inverse conversion but remain typed
as unreferenced data because neither static nor runtime evidence enters them.
The related `$949C-$94DA` render helper destructively quarter-scales the cell
pointer and divides by five to recover row 0-19. It marks task `row + 1`, and
the paired entry also marks `row + 2`; all 400 pointers are covered by the
independent model. Two seven-byte code-shaped shims have no known entry or
pointer and remain explicitly typed as unreferenced data.

`$A7DB-$A834` now owns castle-room navigation. Rooms are one-based in a 10x10
row-major grid. Vertical transitions use a ten-room stride, while two exact
ten-byte tables identify the left and right edge of every row before changing
the room number horizontally. The standalone model checks the exact routine
bytes, both ROM tables, all four corners, and every direction from all 100
rooms.

`$A835-$A8A8` updates player protection and hazard contact once per simulation
frame. The two protection values use 32-frame countdown units and independently
call `SelectRoomAudio` on expiry. A bottom-center `(7,8)` probe rejects Y
outside `$10-$AF` and X outside the 320-pixel room, then classifies exactly
`$16,$62,$63` as hazardous. The preceding read of the old contact flag is dead:
the next load replaces A before any flag consumer. The ROM-backed model covers
all timer, X, Y, cell-value, and 400-cell-index domains.

`$A8A9-$A8E2` is the shared runtime-object/player proximity predicate used by
15 interaction handlers. It tests the point `(object X, object Y+16)` against
exclusive limits of five horizontal and four vertical pixels and returns the
result in carry. The independent model checks every Y pair, every negative
16-bit X delta, and every X pair across the 320-pixel room. It also records the
64 room-width cases where the original missing high-byte carry makes a
negative `$0100` delta appear near.

`$A5DD-$A66C` connects the six original persistent-cell families to all six
inventory counters. Both halves of each family share one handler. The common
guard requires a nonzero counter, inactive normalized motion, an empty motion
phase, and player Y remainder eight within a 16-pixel pair. Success decrements
only the selected counter, probes 16 pixels upward, opens/persists the mutable
cell, and plays its dedicated sound. Facing outward at X below `$0011` or at
or above `$0120` additionally installs a nine-frame movement delay.
The adjacent `$A6CA-$A6D7` helper classifies the doubled collision lookup index:
Y is zero exactly for `$8A-$91`, covering both index phases of cell types
`$45-$48`, and `$FF` otherwise. Callers branch directly on the resulting Z flag.

The adjacent `$94DB-$952C` module provides the common 16-bit X probes used by
player collision, object collision, and room-cell lookup. Player X lives at
`$38/$39`; runtime-object X occupies record bytes `+1/+2`. Every entry returns
A=high and X=low after applying its fixed signed offset. The standalone model
exhaustively checks all 65,536 positions against modular 16-bit arithmetic.

The next `$952D-$9577` range is split into semantic room-transition and
collision modules. Transition completion copies saved player X/Y into offsets
11-13 of the 15-byte runtime mirror, mirrors two scoped state bytes, restores
gameplay mode, resets scroll, enables NMI, and resumes rendering. The collision
module returns carry clear exactly for types `$90-$95`; its sampler wrapper
maps mutable forms `$54/$55/$62/$63` to `$53`, preserving every incoming status
bit except the deliberately cleared carry. Independent models cover every
input byte and every cell/status pair.

`$9583-$9612` now owns the frame-level runtime-object dispatcher. It visits all
24 records at six-byte offsets, clears the shared update flag for each, ignores
inactive type zero and Y positions at/after `$A0`, and indexes 42 handler
pointers with `type & $7F`. Its indirect call is a deliberate synthetic JSR:
the dispatcher pushes the byte before its advance label and jumps through the
zero-page pointer, letting every handler return into the next-record scan.
The exact pointer table and selection domain are independently validated.

At the other end of the object-handler preservation range, `$A2B1-$A35B` is
now split into new-game and palette modules. Initialization selects room `$47`,
sets three lives and player `(X,Y)=(0,$98)`, resets gameplay and all four SFX
busy flags, and clears the two physical save regions plus every visited flag.
It copies a zero 14-byte runtime image before updating active Y, preserves load
mirror byte 14, and invalidates snapshot B by clearing only its room id. The
fallthrough palette module passes typed table `$C53D` to the shared uploader.
The independent model checks the exact loop sizes, operand bytes, ordering, and
both preserved tails.

The following `$A3AC-$A3D1` module owns room-runtime reset and audio continuity.
It clears ten explicitly scoped runtime fields. Its audio helper restarts room
music only when `GameOverActive == 0` and both audio stream pointer bytes are
zero; otherwise it returns without changing the current audio state. The model
exhausts the complete 16-bit pointer domain and every nonzero game-over value.

`$A3D2-$A496` is now the semantic room-cell animation module. Both passes walk
exactly `$0400-$058F`. On odd room frames the fast pass rotates three
decrementing four-phase groups in `$35-$40` and three incrementing groups in
`$56-$61`; their leading groups queue the containing NMI row. The intermittent
pass rotates `$45-$48` every fourth odd frame during the nonnegative half of
its 8-bit counter. Three typed tables contain the exact 28 replacement bytes,
and the independent model checks their complete value and cadence domains.

`$A497-$A572` now owns foreground HUD formatting. `$0001-$0002` is the
cold-boot-preserved high score; `$000B-$000C` is the new-game-cleared current
score updated by point awards. Both entries join the same five-digit decimal
converter. The common tail formats three life scratch digits, clamps the six
inventory counters to nine, and clears `StatusTilesBusy` only when all output
tiles are ready. The next 23 code-shaped bytes have no static or runtime entry
and are explicitly typed in `src/data/unreferenced_bit_index_helper.asm`.

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

The save/load module at `$FBFE-$FDC4` is semantic. The adjacent title and
sub-command UI remains preservation source, as does the post-save tail. The
final known tables map each logical room cell to its left and right background
tile, followed by the NMI, reset, and IRQ vectors. Remaining mixed ranges stay
unpromoted until more static consumers and runtime scenarios establish tighter
boundaries.
