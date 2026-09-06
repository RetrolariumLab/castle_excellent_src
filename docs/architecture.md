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
`$82C9-$82CD`. A mismatch is a cold boot: the sentinel, two-byte high score,
and two-byte reset counter are initialized. Both cold and warm paths then
increment the counter before entering the title and room-loading sequence.

The main loop initializes `$FC` to two and waits for NMI to decrement it to
zero. NMI uses a saturating decrement, so the foreground executes one complete
game update per two NMI ticks. Castle-map mode skips all frame work; pause mode
keeps scrolling, sprite construction, and sub-command input active while
skipping player, object, collision, and room-cell simulation.

`HandlePauseInput` is edge-triggered against the saved controller-1 mask. Start
enters or leaves pause; entering writes zero to `APU_STATUS`. A or B can also
resume. While paused, Left/Right move the pending horizontal scroll by four,
clamped to `$00-$80`, and set the NMI latch request. Left wins if both are held.
Unpaused idle frames deliberately leave the saved edge mask unchanged.

During normal play `UpdateHorizontalScroll` maps player X to that same
`$00-$80` scroll range. Positions below the 64-pixel margin select zero;
positions at least 192 pixels beyond it select `$80`; the middle interval uses
`floor(2 * (playerX - 64) / 3)`. The helper delegates to the destructive
unsigned 16-bit divider at `$C47A`, whose quotient is returned in `$27-$28`
and whose dividend pair becomes the remainder. A zero divisor exits before
initializing those work fields.

`UploadPalette` waits for vblank, writes exactly 32 source bytes to PPU palette
address `$3F00`, and finally writes `$3F00` to the address latch once more.
Callers provide the source pointer in scoped zero-page `$21-$22`.

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

The foreground formatter at `$A497-$A572` acquires that interlock, clears the
eight-byte score buffer, and selects either high score `$0001-$0002` or current
player score `$000B-$000C`. Repeated 16-bit subtraction by
`10000,1000,100,10,1` produces five digit tiles with leading blank tiles. Its
shared tail stores lives as ones/tens/hundreds scratch digits (NMI uploads only
tens then ones), converts six inventory counts to single tiles saturated at
nine, and finally releases the interlock.

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

## Player input and movement

The main loop calls `UpdatePlayerInputAndMovement` once per simulation frame.
A enters the jump path and B owns a ten-frame action countdown with a separate
held latch, so holding B does not restart the action. Motion states below `$21`
are active; eight-pixel X alignment promotes preparatory state `$21` to active
ascent state `$20`.

Ascent samples left, center, and right two pixels above the player. Gravity
first samples 17 pixels below and can retry at 16 for animated cells. Horizontal
movement uses a two-pixel candidate and three Y probes. Collision values choose
room-cell or runtime-object handler tables; the controller emulates JSR by
pushing a named continuation minus one before each indirect jump.

An active facing-dependent action probes 22 pixels to the right or six to the
left and five pixels above player Y. It scans the 24 six-byte runtime records
in order; the first overlap terminates the search. Runtime types `$84,$87,$88`
become `$A8`, their state is cleared, and the shared sound effect is started.
The ROM-backed model exhausts action latches, all button masks, both directions
over every 16-bit X, and all 256 runtime types.

Horizontal collision handlers for runtime types `$8A-$8D/$8F` share
`PushPlayerAndRuntimeObject`. The controller acts only when player motion is
inactive and the object has support at one of three bottom points. It samples
the player-facing edge while allowing rediscovery of the pushed record itself,
then samples the object's new leading edge. World X remains below `$0140`.
Successful movement advances or subtracts two pixels from both 16-bit X
positions and records `$7F/$FF` in the direction latch. A leading collision
with runtime type `$84-$89` is transformed to `$A8` before movement continues;
all other collisions block the push.

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
two bytes are current room and player lives, followed by 14 runtime bytes.
The next blocks read RAM in descending address order: 120 bytes from
`$0607-$0590`, 150 from `$069D-$0608`, and 100 visited flags from
`$0701-$069E`. Eight bytes `BEDEUTUN` terminate the payload. ROM stores the
nine-byte reverse text `GNUTUEDEB` at `$FC99`; the loops use indexes 8 through
1, deliberately excluding the first physical `G`.

Load mirrors these traversals and validates the signature before rebuilding
the room, objects, attributes, scroll, and mutable cell beneath the restored
player position. Carry errors are checked for the room byte and every repeated
region byte. The single lives byte at payload offset 1 is stored without
a carry check, an original behavior retained by the reconstruction.

## Room pipeline

```text
one-based room number
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

The room graph is a regular 10x10 row-major grid numbered 1-100. Moving up or
down subtracts or adds ten except in the first or last row. Horizontal moves
change the number by one; `RightmostCastleRoomNumbers` and
`LeftmostCastleRoomNumbers` stop movement at each row edge, preventing a wrap
from room 10 to 11 or from room 11 to 10.

Each player frame also updates two protection countdowns. Nonzero values decay
once every 32 room frames, and expiry restores the room's normal audio choice.
The player hazard probe samples the bottom-center point `(X+7,Y+8)`, maps it
into the 20x20 logical grid after visible-bound checks, and stores `$FF` only
for cells `$16,$62,$63`. The collision path turns that flag into death unless
the hazard-protection countdown is active; the second countdown guards the
shared death entry more generally.

Object interaction handlers share `IsCurrentObjectNearPlayer`. It compares the
player with `(object X, object Y+16)` and returns carry clear only inside the
exclusive `<5` X and `<4` Y window. Its 16-bit negative-X normalization has an
original page-boundary quirk: a player exactly `$0100` pixels to the right can
alias to zero distance. The reconstruction retains that behavior explicitly.

The logical room is 20x20 cells. One cell spans 16x8 pixels: X is doubled into
two background tiles, while Y advances by one tile. The rendered playfield is
therefore wider than one screen and uses two horizontal nametables.

`ConvertPixelPositionToTileCoordinates` shifts the 16-bit A:X horizontal
position and eight-bit Y position right by three. `GetRoomCellPointer` then
computes `$0400 + tile_y * 20 + floor(tile_x / 2)`. Mutable-cell lookup accepts
the six persistent top/left values plus restored anchors `$54/$62`; lower
restored values and the six paired right values first move the lookup one row
up. The resulting anchor is numbered from one by scanning the room row-major.
Restoration scans the same candidate order, writes `$54/$55` or `$62/$63`,
sets the ordinal's packed bit, requests the affected room-row update, and
requests both attribute upload tasks.

The render helper derives a row directly from an absolute room-cell pointer:
it shifts the pointer right twice, masks the low seven bits, and divides by
five. Since each row is 20 cells, the result is exactly the original row for
every address `$0400-$058F`. The single-row entry marks NMI task `row + 1`;
the paired entry also marks its successor, matching mutations that write the
cell below.

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

The shared X-coordinate helpers at `$94DB-$952C` treat player and runtime-object
X as unsigned 16-bit values. They return the high byte in A and low byte in X,
which is the register order expected by collision and pixel-to-tile callers.
Player probes add 7 or 15; object probes use offsets 0, 7, 8, 15, 17, and -2.
Low-byte carry or borrow is propagated into the high byte, including natural
wrap at `$FFFF/$0000`.

The four boundary routes at `$867A` preserve the entry coordinates in scoped
`$10-$12` before saving outgoing object state. Vertical movement aligns X with
`$FFF8` and re-enters at Y `$98` from above or `$10` from below. Horizontal
movement clamps to X `$0000/$0130` at the outer castle edges. An actual left or
right room change reloads the destination and probes `(entryX, playerY-16)` so
a mutable two-cell structure at the doorway is restored before rendering
resumes.

`FinishRoomTransition` at `$952D` restores `PauseMode` to `$FF`, copies the
saved player X/Y bytes into runtime-mirror offsets 11-13, mirrors two additional
transition-state bytes, then calls `ResetPpuScroll`, `EnableNmi`, and tail-jumps
to `WaitForVblankAndEnableRendering` in that order. The contextual zero-page
names apply only to this routine; the destination runtime mirror is the same
15-byte record populated by room-state selection.

The adjacent collision helpers make two flag contracts explicit. The type
predicate returns carry clear only for runtime types `$90-$95`. The sampling
wrapper preserves the lower room-cell sampler's complete A/P result unless A
is `$54,$55,$62`, or `$63`; those four mutable visual forms return `$53` with
only carry forced clear. Thus visual restoration does not make the cell solid
to these callers.

A separate collision-table helper at `$A6CA` receives the doubled lookup index
in X. It returns Y=`$00` with Z set only for indexes `$8A-$91`, corresponding
to both index phases of room-cell types `$45-$48`; every other index returns
Y=`$FF` with Z clear. Its three callers consume the Z flag immediately.

The collision data at `$A95A-$AB49` is four physical tables. Player and object
cell classifiers each contain 100 pairs, selected by `cell * 2 + horizontal
half`; their bytes are processor-flag masks whose high and low bits become N
and C. Width and height tables cover runtime types `$80-$AF`. Callers index
those dimensions directly with the type byte by referring to each physical
table start minus `$80`, so the apparently earlier `$AA6A/$AA9A` operands are
biased bases rather than independent data. The final height byte at `$AB49`
also serves as `RoomObjectCounts - 1` for one-based room indexing.

`UpdateRuntimeObjects` then scans offsets `0,6,...,138` across the 24-record
pool. It clears the shared update flag before every slot, masks type byte bit 7,
and skips a zero result or Y at/after `$A0`. Valid indexes 1-41 select an
interleaved little-endian pointer from the 42-entry table at `$95BF`. The code
implements an indirect subroutine call by pushing `$95B2`, one byte before
`AdvanceRuntimeObjectUpdate`, and jumping through `$31/$32`; the handler's
`RTS` therefore lands at `$95B3` and continues with the next six-byte record.

Handler entries for runtime types `$8A-$8D/$8F` converge on
`UpdatePushableObjectPhysics`; type `$8E` enters through `UpdateLiftControlBlock`
and then calls the same routine. Three samples at Y+17 decide support. With no
support, the object falls two pixels until Y reaches `$A0`. The two animated
cell families carry a supported object two pixels in opposite directions after
its entering edge is clear. A matching runtime support in `$84-$89` becomes
transient type `$A8`. The lift-control wrapper consumes the same horizontal-
motion latch used by player pushing and routes it to the linked lift pair.

The linked pair is materialized by the unique cell-derived types `$A4/$A5` in
each of eight rooms. `$89E1-$8C11` accepts either player-driven or conveyor-
driven motion of the type-`$8E` control block, validates cells `$41-$43`, and
extends or removes track cell `$52` as both halves move by two pixels. Raising
uses the same 25-entry occupant bitmap and overlap scanner as the autonomous
lifts, seeded with both halves, so stacked objects move as a transitive set;
objects blocked by the ceiling become type `$A8`.

Handler entries 33 and 34 select the small and large lift state machines at
`$9796/$9869`. They edit one or two shaft cells while moving down or up by
eight pixels. The rising path seeds a 25-entry occupant set with the current
lift, repeatedly expands it through `FindRuntimeObjectOverlappingSpan`, adds
the player through `TestPlayerAgainstObjectSpan`, and then moves the resulting
transitive stack. This makes multi-object lift support an explicit closure
operation rather than an incidental order of the 24-record dispatcher.

Handler entry 35 selects the cell-derived Flying Block. Its sign-valued state
chooses left or right motion; paired top/bottom probes cover the eight-pixel
leading edge and reject coordinates beyond the 320x160 room. A clear path
moves two pixels, one blocked side reverses direction, and two blocked sides
set the byte-five stopped latch.

Handler entry 5 selects the Bishop and enters the shared walking-enemy physics
at `$9B00`. Fighter, Knight, and Witch call the same routine before their own
behavior. The common path centralizes support/fall handling and sign-directed
wall-and-ledge patrol; type-specific handlers remain separate state machines.

Knight type `$87` demonstrates that layering: `$9C3B-$9CC5` calls the common
physics, gates firing by player alignment/facing and frame cadence, then creates
arrow type `$A6` in the first free runtime record after the room's static set.

Fairy `$81` is a self-contained frame-derived bob. Fighter `$84` instead layers
player proximity and a three-point rising collision check over the shared
walking-enemy physics, keeping type behavior separate from common patrol code.

Flame `$89` is an axis-switching tracker over the same three-point side probes.
Its vertical probes and the biased 16-bit player-X separation helper are kept
with the shared enemy movement layer because later type handlers call them.

Witch `$88` adds an allocation layer: after shared patrol, four point samples
validate a 16x16 area and the first free dynamic record becomes summon type
`$A0`. Its countdown handler then selects Fighter, Bishop, or Knight from the
15-entry cadence table and assigns direction from global-frame parity.

Knight arrow `$A6` is the terminal projectile layer. Its sign-valued state
selects mirrored three-pixel movement, two leading-edge probes reuse the common
point sampler, and every blocked or out-of-world path clears the runtime record.

Three handlers call `TestPlayerAgainstObjectSpan` with a candidate object's
16-bit X in `$44/$45`, Y in `$46`, and width in `$47`. The shared predicate
accepts the 16-pixel vertical interval immediately below that Y origin and the
horizontal interval `[max(0, objectX-15), objectX+width)`. Carry clear denotes
overlap; every rejection explicitly returns carry set.

Three runtime-only types have short, self-contained lifecycle handlers. Type
index 32 is the Witch summon: after its state countdown, the paired modulo-30
phase selects type `$84`, `$85`, or `$87`, while global frame parity selects
replacement direction zero or `$FF`. Type index 40 is cleared when
its incremented state reaches 15. Type index 41 moves Y upward every odd room
frame until byte five expires. Both expiration paths clear all six record bytes.

`ClassifyAnimatedCollisionCell` recognizes both 12-cell animation families and
returns a direction discriminator in Y. Runtime-object collision then uses two
biased type lookups. `GetRuntimeObjectSolidFlag` marks `$81-$83`, `$90-$9C`,
and `$9F` non-solid; the adjacent filter returns zero exactly for `$84-$89`.
Both physical tables stop at type `$A5`, while legal consumer types `$A6/$A7`
deliberately read the first two opcode bytes of the following routine. Those
overlap values are nonzero and therefore preserve the filter semantics.

`SamplePlayerCollisionAtScreenPixel` is the player-specific front end. A:X is
screen X and Y is screen Y; only X 0-319 and Y 16-175 enter the room buffer,
with Y rebased past the status row. Nonzero player cell-half flags return first.
Otherwise the routine scans all 24 runtime records and returns the first point
match. Its one-shot filter mode admits only `$90-$95`; runtime types `$84-$89`
remain pass-through in carry, and type `$86` narrows to its lower eight pixels
during the early room-frame phase when player motion is idle.

`DispatchPlayerCollisionSample` consumes that result at seven frame-level
probe sites. `ASL` both doubles the identity and moves its runtime marker into
carry, selecting the 100-entry room-cell table or 41-entry runtime table. It
loads a zero-page handler pointer, pushes its local return address minus one,
and jumps indirectly; the selected handler's `RTS` therefore resumes at the
dispatcher's final `RTS`.

`SampleCollisionAtPixel` receives X high in A, X low in X, and pixel Y in Y.
It addresses `RoomCells[(Y >> 3) * 20 + (X >> 4)]` and selects the cell's
eight-pixel collision half with X bit 3. A colliding half returns its cell type
in A and preserves collision bits 0 and 7 as C and N. The `$45-$48` cell family
uses the sign of `RoomCellAnimationCounter` to suppress those flags during its
paused phase. Empty or passable halves scan all 24 runtime records, omit the
current record, and return the first point-containing type `$80-$A7`; Y=1
distinguishes that object result, `$42` receives its record offset, and carry
reports the type's solidity. No match returns `$53`, Y=0, and carry clear.

All room samplers share `PrepareRoomCellSampleAddress`. It converts A:X and Y
to a row pointer `$0400 + (Y >> 3) * 20` plus the full 16-bit X shifted right
four places. The final rotate intentionally leaves original X bit 3 in carry,
so callers can select the left or right eight-pixel collision half without a
second mask.

`SampleRoomCollisionAtPixel` is the room-only variant used by four paired-edge
movement probes. It calls the shared address builder, applies the same half
table and animation gate, and returns even a zero collision flag without
consulting runtime objects. Its out-of-range path differs slightly: X becomes
zero while the caller's Y is preserved.

`FindRuntimeObjectOverlappingSpan` scans the same pool in six-byte steps from
the caller-provided X offset. Only active types `$80-$A7` participate. The
supplied Y must lie in `[objectY, objectY+height)`, while object X must lie in
`[max(0, spanX-objectWidth+1), spanX+spanWidth)`. The first match returns its
record offset in X with carry clear. Exhaustion reaches `$90` and returns carry
set through `ReturnFromRuntimeObjectHandler`, which is also the shared no-op
target for 23 update-dispatch entries.

`BuildFrameSprites` at `$AC13` is the rendering-side counterpart. It marks the
staging buffer busy, fills all 256 bytes with hidden Y `$F0`, draws the player
into records 0-1 and an optional action tile into record 2, then begins object
output at byte offset `$0C`. The same 24 six-byte runtime records are filtered
by Y `<$A0` and a nonzero raw type before `type & $7F` selects the render table.
Unlike the update dispatcher, the raw-zero test occurs before masking; active
type `$80` would therefore select entry zero rather than being skipped.

Player rendering selects one of four transition descriptors from room frame
bits 2-3. Outside transition it distinguishes zero, positive, and negative
direction, active motion/phase, a ten-frame action countdown, and walk phase
from global frame bits 3-4. Both walk cycles reuse their middle descriptor in
phases one and three. The action overlay copies the first player sprite Y, uses
tile `$CA`, and appears at X+15 with attributes `$03` or X-7 with horizontally
flipped attributes `$43`.

`ObjectSpriteHandlerPointers` has 42 logical entries beginning at `$AD93`.
Entry zero is the overlapping word `$6003`, composed from the high operand byte
of the final `STA $030A` and the following `RTS`; it is not selected by raw type
zero. The 41 normal pointers occupy `$AD95-$ADE6`, name render handlers for type
indexes 1-41, and intentionally share one target for indexes 29 and 30.

`InitializeNewGame` at `$A2B1` establishes one-based room `$47`, three lives,
X zero, and Y `$98`. It resets pause/map/game-over and four sound-effect busy
flags, copies 14 zero runtime bytes into the load mirror and snapshot A, clears
120 mutable-state bytes, 150 object-state bytes, and all 100 visited flags, and
then falls through to `UploadRoomPalette`. Two original partial-write details
are preserved: load-mirror byte 14 is not touched, and snapshot B is invalidated
by clearing only its room id while its eight payload bytes remain unchanged.
The active runtime Y byte becomes `$98` only after the zero runtime image has
already been copied to both mirrors. Palette upload tail-jumps through pointer
`$C53D`, the typed `RoomPaletteData` table.

`ResetRoomRuntimeState` clears ten fields spanning player movement, the current
NMI task, both scroll bytes, the object-update shared flag, room frame count,
and room animation count. `EnsureRoomAudioPlaying` then leaves audio untouched
during game over or while either stream-pointer byte is nonzero; only the
all-zero pointer in normal play tail-calls `SelectRoomAudio`.

`AnimateRoomCells` then performs two address-ordered scans of the 400-byte room
matrix on odd simulation frames. `AnimateFastRoomCells` rotates twelve cell
values at `$35-$40` by decrementing each four-phase group and twelve values at
`$56-$61` by incrementing them. The outer scan rotates `$45-$48` only when the
incremented room-animation counter is nonnegative and divisible by four. Row
redraws are queued through `RequestRoomCellRowUpdate`; only the leading group
of each multi-cell fast family needs to queue the shared row.

A 101-entry cumulative offset table assigns `ceil(object count / 8)` bytes to
each room. The resulting `$8D` bytes at `$0608-$0694` preserve one bit for each
static object across room transitions.

A parallel table assigns packed bits to seven mutable cell classes. Its
108-byte store at `$0590-$05FB`, the object-bit store, and a one-byte room id
form a nine-byte active record plus two transition snapshots. The load and save
paths use the same cumulative offsets, preventing one room from consuming a
neighbor's state bytes.

During collision dispatch, cell families `$19/$1A`, `$1C/$1D`, `$1F/$20`,
`$22/$23`, `$25/$26`, and `$29/$2A` select six handlers at `$A5DD-$A60F`.
They consume inventory indexes `4,3,5,2,0,1` respectively. A shared guard uses
an intentional two-return-address stack unwind to abort the indirect collision
handler when the counter is zero, motion is active, or player Y is not aligned
to remainder eight. The success path opens the corresponding persistent cell
through the existing ordinal pipeline and preserves the mutation in snapshots.

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

Object type selects an indirect render handler through the table at `$AD93`.
The published analysis identifies 34 used types. Semantic object-specific
selectors in `$ADE7-$B1D5` choose descriptors, then five common paths at `$B1D6-$B4B5`
compose one, two, compact two, or four object records and the two-record player
in 8x16 sprite mode. Each object component adds a fixed world-X offset, applies
pending scroll with 16-bit page testing, and appends only visible components to
staging OAM. Thus clipping compacts later components into earlier free records.
The player owns fixed records zero and one; an X wrap hides only record one.

The contiguous `$B4B6-$B64B` descriptor block contains 203 `(tile,
attributes)` pairs. The 107 statically recognizable selections use 98 unique
pair-aligned pointers. Their renderer call tail determines lengths of one, two,
or four hardware sprites; five short gaps are not selected by this pattern.
Indexes 29 and 30 deliberately share `$B089`. The seven bytes at `$AFCC-$AFD2`
are unreachable after an unconditional type-09 jump and remain typed data.

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

The object identity joins are machine-checked rather than inferred from
matching indexes. Encoded room values `$00-$3C` first select a runtime byte at
`$EB8F`; its low seven bits independently index the 42-word update table at
`$95BF` and the 42-word sprite table at `$AD93`. The same runtime byte indexes
width/height tables based at `$AAEA/$AB1A`. Across the shipped room stream, 34
encoded values produce 27 runtime types; five decoded-cell markers add types
`$A1-$A5`, for 32 directly sourced runtime types in total. The remaining ten
indexes are reserved for runtime transformations or otherwise absent from room
sources and are not assigned identities without behavior evidence.

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
