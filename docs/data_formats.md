# Data formats

The models that checked these formats during Source Reconstruction 1.0 to 3.0
remain at those tags; Retrolarium Kit's Castle codecs
(`games/castle_excellent/`) read and write the editable ones, and `make
studio-check` round-trips them against the ROMs.

All CPU addresses below refer to the Japanese PRG mapped at `$8000-$FFFF`.
The descriptions began with the published trace and were checked against the
exact Japanese reference image identified in `assets/manifest.json`.

## Save-data payload

The Japanese save/load code transfers a fixed 394-byte payload after its
transport-specific preamble:

| Offset | Size | Contents | RAM traversal |
| ---: | ---: | --- | --- |
| 0 | 1 | current one-based room number | `$0037` |
| 1 | 1 | player lives | `$0013` / mirror `$0744` |
| 2 | 14 | active runtime state | ascending `$0005-$0012` |
| 16 | 120 | mutable save region | descending `$0607-$0590` |
| 136 | 150 | object save region | descending `$069D-$0608` |
| 286 | 100 | visited-room flags | descending `$0701-$069E` |
| 386 | 8 | signature | ASCII `BEDEUTUN` |

The 120-byte mutable block contains the 108 proven persistent mutable-cell
bytes plus 12 adjacent bytes. The 150-byte object block contains the 141
proven persistent object bytes plus nine adjacent bytes. The format therefore
serializes physical RAM regions, not only the currently named logical arrays.

ROM `$FC99-$FCA1` contains ASCII `GNUTUEDEB`. Indexed reads from 8 down to 1
produce the eight wire bytes `BEDEUTUN`; byte zero, the leading physical `G`,
is not transferred.

The receiver checks carry after the room byte and every looped byte, but not
after payload byte 1. This unchecked status is part of the original binary
contract and remains unchanged.

New-game initialization clears the same physical 120-byte mutable and 150-byte
object regions that save/load transfers, plus all 100 visited flags. It clears
the current room state, load mirror, and snapshot A as one 27-byte span.
Snapshot B is not part of that span: only its room-id byte is zeroed, which
invalidates the record while preserving its eight payload bytes. Likewise,
only 14 of the 15 runtime load-mirror bytes are initialized. These partial
writes are modeled explicitly rather than treating adjacent storage as zero.

## Controller button byte

The serial pollers produce this one-byte layout at `$20`:

| Bit | Mask | Button |
| ---: | ---: | --- |
| 0 | `$01` | A |
| 1 | `$02` | B |
| 2 | `$04` | Select |
| 3 | `$08` | Start |
| 4 | `$10` | Up |
| 5 | `$20` | Down |
| 6 | `$40` | Left |
| 7 | `$80` | Right |

Each serial read chooses a set D0 bit first and otherwise falls back to D1.

## Room pointers and compressed streams

- 100 little-endian PPU pointers begin at `$E71C`.
- Rooms 1-67 read their bitstreams from CHR bank 2.
- Rooms 68-100 read their bitstreams from CHR bank 3.
- Each decoded room is exactly 400 bytes, arranged as 20 rows of 20 cells.

The codebook begins at `$E45D`. Each entry has this structural form:

```text
output byte, one or more ASCII $30/$31 code bytes, $00
```

An `$FF` entry marker terminates the candidate table. The original routine
compares candidates in table order. The table is prefix-free, so a decoder may
use an equivalent direct lookup.

The independent decoder reaches exactly 400 output cells for all 100 rooms.
Its encoder reproduces every physical stream byte-for-byte: the next pointer
always equals the preceding start plus `ceil(consumed_bits / 8)`, and unused
low bits in a final partial byte are one-filled.

The room-stream arenas and their current capacity are exact:

| CHR bank | Rooms | Arena | Used | Free `$FF` bytes |
| ---: | ---: | --- | ---: | ---: |
| 2 | 1-67 | `$0000-$1FFF` | 8,039 (`$0000-$1F66`) | 153 |
| 3 | 68-100 | `$0000-$13FF` | 4,449 (`$0000-$1160`) | 671 |

Bank 3 cannot extend past `$1400` without relocation: the four-page
CHR-to-nametable copier selects bank 3 and consumes pages `$14-$17` for the
completion screen. Repacked rooms therefore fit only within the two stated
arenas; using other CHR space needs relocated data, not implicit free
capacity.

## Logical cell rendering

The decoded cell value indexes two PRG tables near `$FF30` and `$FF94`. They
select the left and right 8x8 background tile for a 16x8 logical cell.

## Mutable-cell coordinates and ordinals

The 20x20 room matrix corresponds to a 40x20 background-tile domain. Pixel
coordinates become tiles by division by eight, then
`cell_offset = tile_y * 20 + floor(tile_x / 2)` selects `$0400-$058F`.

Mutable anchors are `$19,$1C,$1F,$22,$25,$29` or the restored forms `$54/$62`.
Queries on `$1A,$1D,$20,$23,$26,$2A` and restored lower forms `$55/$63` move
one row up before testing the anchor. Valid anchors receive one-based ordinals
by row-major scan. Restoration uses the same scan over original candidates,
writes `$62/$63` when either horizontal neighbor is `$16`, otherwise
`$54/$55`, and maps ordinal `n` to byte `(n-1)/8` and mask
`1 << ((n-1) & 7)`, with the byte division rounded down.

The collision handler table at `$9155` maps each original cell pair to an
inventory-backed action:

| Anchor/right cell | Handler | Inventory index |
| --- | ---: | ---: |
| `$19/$1A` | `$A5DD` | 4 |
| `$1C/$1D` | `$A5E7` | 3 |
| `$1F/$20` | `$A5F1` | 5 |
| `$22/$23` | `$A5FB` | 2 |
| `$25/$26` | `$A605` | 0 |
| `$29/$2A` | `$A60F` | 1 |

Each handler decrements its counter only after the shared motion/alignment
guard succeeds, then enters the ordinal-based persistent restoration path.

An absolute room-cell pointer is converted back to its row by shifting right
twice, masking with `$7F`, and dividing by five. This is equivalent to
`floor((address - $0400) / 20)` throughout the 400-byte room matrix. The NMI
request helper marks task `row + 1`; its paired form also marks `row + 2`.

## Nametable attributes

`RoomAttributeQuadrantMasks` at `$E913` contains `$03,$0C,$30,$C0`, one
two-bit mask for each quadrant of an NES attribute byte.
`RoomCellAttributeValues` at `$E9D2` contains 100 replicated palette values;
each entry is `$00`, `$55`, `$AA`, or `$FF`, so masking selects the same
two-bit palette in any quadrant. Thirteen cell types preserve the existing
quadrant.

The builder clears `$0100-$017F`, copies 16 border bytes from
`InitialRoomAttributes`, then visits all 20x20 cells. Columns crossing tile X
32 select the right 64-byte buffer. When complete, NMI requests `$079A/$079B`
upload attribute bytes to the left and right nametables. `room_data.py`
independently applies the same mapping and validates 200 attribute tables
across the 100 original rooms.

## Room status-screen tiles

Room-load UI data at `$B77C-$B7BC` contains four zero-terminated tile streams
followed immediately by 16 initial attribute bytes:

| PPU destination | PRG data | Tiles before terminator |
| ---: | ---: | ---: |
| `$208E` | `$B77C` | 14 |
| `$2062` | `$B78B` | 11 |
| `$20A2` | `$B797` | 6 |
| `$206E` | `$B79E` | 14 |

`WriteTerminatedPpuTiles` copies each stream through `$2007`. A fifth pointer
targets formatted score tiles at RAM `$079D`; `$07A2` is set to zero before
the copy. The streams hold 45 tile bytes and a 16-byte attribute tail.

Foreground HUD formatting uses paired high/low tables at `$A551-$A55A` for
16-bit place values `10000,1000,100,10,1`. Five raw decimal digits become tile
indexes `$60-$69`; leading zeroes become `$FF`. The eight-byte score buffer at
`$079D` retains three zero tail bytes so `$07A2` also serves as the terminated
room-load string boundary. Lives use three scratch bytes in ones/tens/hundreds
order, while inventory uses six single digits saturated at nine.

## Static object stream

The combined room-object stream occupies `$EF6B-$F8FB`. A room consists of:

```text
(type, x, y), (type, x, y), ... $FF
```

The stream contains exactly 100 terminated lists and 783 records. It uses 34
encoded types in `$0E-$3C`; room 26 has the largest list at 18 records, below
the 24-record runtime capacity.

`RoomObjectStateOffsets` at `$EF06-$EF6A` contains 101 cumulative byte offsets.
For every room, `offset[n+1] - offset[n]` equals
`ceil(static_object_count[n] / 8)`. The table begins at zero and ends at `$8D`,
so `$0608-$0694` stores 141 bytes with one persistent bit per static object.

`RoomMutableCellStateOffsets` at `$ABAE-$AC12` has the same cumulative form.
For rooms 1-99, its width is the ceiling of the count of persistent mutable
cells divided by eight. Candidate values are `$19,$1C,$1F,$22,$25,$29,$54`;
this set comes directly from the cell predicate used by the mutation code.
Room 100 is the only format exception and reserves three bytes. The table ends
at `$6C`, defining 108 bytes at `$0590-$05FB`.

The active state and both snapshots are nine-byte records:

```text
+0      one-based room id
+1..+3 packed static-object bits
+4..+8 packed mutable-cell bits
```

The loader clears unused bytes, copies only the width selected by each table,
and mirrors the result into the active record. The saver performs the inverse
operation from snapshot B.

During room construction, a set static-object bit means that the matching
six-byte runtime record is inactive and must be cleared. Mutable-cell bits use
one-based ordinals 1-39 in a row-major scan. A set bit replaces the selected
candidate with `$62` and the cell below with `$63` when its immediate paired
neighbor is `$16`; otherwise it writes `$54/$55`. The companion predicate
recognizes right-hand values `$1A,$1D,$20,$23,$26,$2A`.

The castle uses one-based row-major room numbers in a 10x10 grid.
`RightmostCastleRoomNumbers` at `$A821-$A82A` contains
`10,20,...,100`; `LeftmostCastleRoomNumbers` at `$A82B-$A834` contains
`1,11,...,91`. The descending lookup returns the matching zero-based row in X,
or `$FF` when the room is not on that edge.

Player hazard contact is a derived runtime view over the room grid rather than
an encoded room field. A bottom-center pixel probe classifies original cell
`$16` and both restored forms `$62/$63` as active (`$FF` at RAM `$077C`);
every other cell and every out-of-room coordinate clears the flag.

## Collision flag and runtime-object dimension tables

`PlayerCollisionFlagsByRoomCellHalf` at `$A95A` and
`ObjectCollisionFlagsByRoomCellHalf` at `$AA22` each contain 200 bytes:

```text
index = room cell type * 2 + horizontal half
horizontal half = 0 for left, 1 for right
```

The player table uses `$00,$01,$80`; the object table uses `$00,$01,$81`.
These values are not enumerated collision classes. They
encode the processor flags consumed by the collision paths: bit 7 supplies N
and bit 0 supplies C.

`RuntimeObjectCollisionWidths` at `$AAEA` and
`RuntimeObjectCollisionHeights` at `$AB1A` each contain 48 bytes for runtime
types `$80-$AF`. Since callers retain the high type bit, their operands use
the physical table address minus `$80` (`$AA6A` and `$AA9A`) and index directly
with the type byte. Those biased operands do not denote separate tables.

The last height byte at `$AB49` is also the byte immediately before
`RoomObjectCounts`. One-based room consumers therefore load
`RoomObjectCounts - 1,x`; the overlap is an address-expression alias, not a
fifth data structure; 18 code consumers read the four physical ranges.

Player collision results select one of two little-endian pointer tables.
`PlayerRoomCellCollisionHandlerPointers` at `$926C-$9333` has 100 entries
indexed directly by cell type. `PlayerRuntimeCollisionHandlerPointers` at
`$9334-$9385` has 41 physical entries indexed by the type's low seven bits;
the player sampler consumes `$80-$A7`, leaving the final `$A8` entry outside
that call path. The shared `$926B` target is a one-byte no-op `RTS`.

Player movement uses an earlier directional dispatch block at `$8F29-$926A`.
It consists of three `$116`-byte physical matrices. Each matrix has a 200-byte
room-cell table for identities `$00-$63`, followed by 78 bytes for runtime
types `$80-$A6`:

| Direction | Room cells | Runtime types |
| --- | --- | --- |
| downward | `$8F29-$8FF0` | `$8FF1-$903E` |
| upward | `$903F-$9106` | `$9107-$9154` |
| horizontal | `$9155-$921C` | `$921D-$926A` |

Downward animated cells `$35-$40` and `$56-$61` select the two forced-player
displacement handlers. All upward room cells are no-ops. Horizontal mutable
cell pairs select the six inventory-backed action handlers. Runtime targets
mostly share one common map, with direction-specific behavior for `$8A-$8F`.

The `ASL A` dispatch permits a logical `$A7` index. Downward and upward reads
overlap the first pointer of the following room table, which is `$926B` and is
safe. The physical horizontal runtime table ends at `$A6`; a hypothetical
`$A7` read crosses `$926B-$926C` and forms `$B060`. No static room object,
cell-derived object or dynamic state machine creates runtime type `$A7` (they
create `$A0`, `$A1-$A6`, `$A8` and `$A9`), so the horizontal path never reads it;
a hack that creates one must extend the horizontal table first.

`RoomObjectCounts` at `$AB4A-$ABAD` exactly matches the 100 decoded static
lists. `RuntimeObjectOffsetByCount` at `$8F10-$8F28` is the sequence
`0,6,...,144`, allowing cell-derived objects to follow the static records.
Five logical cell markers are converted as follows:

| Cell | Runtime type | Initial state |
| ---: | ---: | ---: |
| `$4B` | `$A1` | `$00` |
| `$4D` | `$A2` | `$00` |
| `$51` | `$A3` | `$FF` |
| `$49` | `$A4` | `$00` |
| `$4A` | `$A5` | `$00` |

Each marker cell becomes `$53`; its column and row are scaled to pixel X and Y
by 16 and 8. The 100 rooms contain 176 markers. No room exceeds 22 combined
static and cell-derived records, leaving two spare records in the runtime pool.

`RuntimeObjectTypeByEncodedType` starts at `$EB8F` and is indexed directly by
the encoded type. The logical 61-byte view therefore continues through
`$EBCB`. `RuntimeObjectStateByEncodedType` begins at `$EBC0` and is read only
for encoded types `$12-$29`, so the two logical views intentionally share
bytes. The typed-data registry represents this as two non-overlapping physical
ranges rather than pretending the logical tables are disjoint.

For runtime types `$80-$A9` the cross-table relation gives, for each index,
all encoded sources, loader initial-state values, occurrence count and room set, update handler, sprite
selector, and collision width/height. Of 61 legal encoded values, 34 occur in
the original 783-record stream and map to 27 runtime types. Cell markers
`$4B,$4D,$51,$49,$4A` respectively create `$A1-$A5` with occurrence counts
73, 47, 40, 8, and 8. Thus room data directly sources 32 of the 42 dispatch
indexes. The update table has 16 distinct targets and 23 indexes use the shared
no-op `$A2A9`; the nonzero sprite domain has 40 distinct selectors because
indexes 29 and 30 share `$B089`.

`WitchSummonedEnemyTypes` at `$A00D-$A01B` contains 15 replacement bytes for
Witch summon type `$A0`. `FrameCounterModulo30 >> 1` indexes it, so each entry
owns two of the counter's 30 phases. Its values are restricted to Fighter
`$84`, Bishop `$85`, and Knight `$87`.

The filter tables at `$A06B-$A090` and `$A09E-$A0C3` each store 38 physical
bytes for runtime types `$80-$A5`. Their indexed operands subtract `$80` from
the table address. Callers admit types through `$A7`, so the logical final two
entries are the first two opcode bytes of the following routine: `$A8,$08` for
the type-84-to-89 filter and `$C0,$A0` for solidity. All four values are
nonzero; the overlap is therefore behaviorally meaningful and tested.

The 24-entry runtime pool at `$004A-$00D9` has this six-byte ABI:

| Offset | Global field | Proven contract |
| ---: | --- | --- |
| `+0` | `RuntimeObjectRecords` | zero for an inactive slot; otherwise runtime type `$80-$A9` |
| `+1` | `RuntimeObjectXLo` | low byte of world X in pixels |
| `+2` | `RuntimeObjectXHi` | high byte of world X in pixels |
| `+3` | `RuntimeObjectY` | world Y in pixels |
| `+4` | `RuntimeObjectState` | type-specific primary state, direction, phase, or countdown |
| `+5` | `RuntimeObjectAux` | type-specific auxiliary state; zero when unused |

Loading scales static X by 16 into `+1/+2` and Y by 8 into `+3`; runtime types
`$90-$95` receive an additional four-pixel X offset. The loader clears the
entire pool first. It initializes `+4` to zero except for encoded types
`$12-$29`, where the overlapping state table supplies the value, and leaves
`+5` zero.

The `+4` consumers use it as signed direction/orientation for walking enemies,
Flame, lifts, Flying Block, and Knight Arrow; as the Witch-summon countdown
before that slot becomes a walking enemy; as the incrementing type-`$A8`
animation state; and as type-`$A9`'s collected-appearance selector. The same
byte intentionally changes interpretation when type `$A0` is replaced.

Only five behaviors consume `+5`: Fighter uses a jump countdown, Knight an
arrow cooldown and render-phase offset, Flame a horizontal/vertical mode,
Flying Block a stopped latch, and collected type `$A9` a lifetime countdown.
Those accesses use explicit contextual aliases in source. Generic creation,
replacement, persistence, and clear paths use `RuntimeObjectAux` and preserve
the contract that an otherwise unused auxiliary byte is zero.

Collision callers read record `+1/+2` through shared helpers returning
A=high/X=low. The fixed probe offsets are 0, +7, +8, +15, +17, and -2; all use
16-bit modular carry/borrow. Player probes use the same register contract with
offsets +7 and +15.

The collision wrapper at `$955D` treats restored mutable visual forms
`$54,$55,$62,$63` as logical `$53`. For any other cell it returns the lower
sampler's A and complete processor status unchanged. For the four mapped cells
it restores the sampler status first and then clears carry, so no other status
flag is lost. The adjacent predicate's carry-clear set is exactly runtime types
`$90-$95`.

The 84 bytes at `$95BF-$9612` are 42 little-endian runtime-handler pointers.
The dispatcher masks a record type with `$7F`, doubles the resulting index, and
reads the low byte at the even address and high byte at the following odd
address. Index zero is inactive; valid dispatched indexes are 1-41. Multiple
indexes deliberately share the no-op `$A2A9` handler or common behavior at
`$9674`.

## Frame sprite selection and render-handler pointers

`BuildFrameSprites` first writes `$F0` to every byte of the 256-byte staging
OAM. Player output owns records 0-1, the optional action overlay owns record 2,
and runtime-object output starts at byte offset `$0C`. The object scan visits
all 24 records with a six-byte stride, rejects Y at/after `$A0` and raw type
zero, then indexes the render table by `(type & $7F) * 2`.

The player descriptor pointer is passed high byte in X and low byte in Y. Four
transition descriptors use `(RoomFrameCounter >> 2) & 3`. Normal rendering
partitions zero/positive/negative direction, motion state or phase, action
countdown, and `(FrameCounter >> 3) & 3`; walk phases 1 and 3 reuse the same
middle descriptor. Every referenced player descriptor contains two
`(tile, attributes)` pairs for adjacent 8x16 hardware sprites.

`ObjectSpriteHandlerPointers` is a 42-word logical view beginning at `$AD93`.
Its first word intentionally overlaps executable bytes:

```text
$AD91  STA $030A  ; high operand byte at $AD93 is $03
$AD94  RTS        ; opcode byte is $60
logical entry 0 = $6003
```

The usable physical tail at `$AD95-$ADE6` stores entries 1-41. Indexes 29 and
30 both point to `$B089`; every other nonzero entry has its own target. The raw
type check precedes masking, so type `$80` preserves the original entry-zero
edge case instead of behaving like inactive type `$00`.

## Metasprite descriptors

`$B4B6-$B64B` is a flat sequence of 203 two-byte records:

```text
tile, attributes
```

There is no stored count. The selected renderer supplies the shape: one sprite
reads two bytes, the standard/compact/player paths read four, and the wide path
reads eight. A static scan of the preceding selectors recognizes 107 exact
high/low pointer loads followed by one of those renderer call tails. These use
98 unique, pair-aligned pointers and leave only `$B568-$B56B`, `$B578-$B57B`,
`$B5A0-$B5AB`, `$B5F8-$B5FB`, and `$B61C-$B61F` uncovered. The complete
attribute domain is `$00,$01,$02,$03,$40,$41,$42,$43,$C1`.

Object renderer geometry is encoded by code rather than the descriptor:
standard components use world-X offsets `$20,$28`; wide components add
`$30,$38`; the compact second component uses `$24`. All object components add
Y bias `$37`. The fixed two-record player path uses X offsets `$20,$28` and Y
bias `$27`.

The 41 nonzero render-table indexes enter selectors at `$ADE7-$B1D5`; indexes
29 and 30 share the same entry. Most selectors load a descriptor directly or
choose among phase/state variants before calling a renderer. The seven bytes
at `$AFCC-$AFD2` encode a plausible extra type-09 descriptor load, but execution
has already passed an unconditional jump and no entry points there, so the
bytes are classified as unreferenced data.

## Music track sets and textual streams

Eight records beginning at `$B8C6` are selected by the audio setup code. Each
record contains three little-endian stream pointers followed by two channel
parameters:

```text
pulse 1 pointer, pulse 2 pointer, triangle pointer, pulse 1 $4000, pulse 2 $4004
```

The two parameters are the duty, envelope and volume bytes written to the
pulse channels' `$4000`/`$4004` registers before each note; the triangle always
gets linear counter `$FF`. A zero pointer disables that stream. Nonzero
pointers address textual (MML) music streams in `$BBE7-$C20C`, which
`src/audio/music_engine.asm` writes as strings. Every command is one ASCII
character, and the ones that take an argument read exactly one more:

| Text | Meaning |
| --- | --- |
| `o`*d* | Octave: notes after it use period-table octave *d* − 2. |
| `t`*d* | Tempo: selects row *d* (0-6) of the note-length table, shared by all three channels. |
| `l`*c* | Default length: `@` sixteenth, `8` eighth, `4` quarter, `2` half, anything else whole. |
| `v`*c* | Reads and ignores *c*; the volume comes from the record's parameters. |
| `a`-`g` | Note, optionally followed by `+` (sharp) or `-` (flat). |
| `r` | Rest (period 0). |

A note or rest may be followed by an explicit length (`@`, `1`, `2`, `4` or
`8`, as for `l`; the other digits are consumed but give a wrong length) and
then by `.`, which adds half the length. At tempo 0 the lengths are 5, 10, 20,
40 and 80 audio ticks. Three ticks before a note ends the channel is muted,
which separates repeated notes. The triangle reads its periods one octave
higher in the table, so the same text sounds at the same pitch on all channels.
While a sound effect holds a channel, its stream keeps time without writing the
period.

A stream ends with `$00` and a little-endian restart pointer; any other
character that is not a command acts the same. Restart pointer `$0000` stops
the channel.

There are 21 consecutive streams containing 1,511 command bytes. Twenty stream
starts are referenced by the track table; `$BE17` is structurally valid but is
not selected by those eight records. Every pointer, terminator and restart
target lies inside the range, and the streams cover it without gaps.

Seven selector entry points at `$B875-$B88D` load record offsets 0-5 and 7;
no static selector for record 6 is currently known. Their shared body at
`$B895` copies the three pointers and two channel parameters to zero-page audio
state and primes each duration counter to one tick.

## Round-trip status

The rooms, their objects and the music round-trip through the kit's codecs
(`castle-excellent.prefix-rooms.v1` and the others of
`config/game_profile.json`): all 100 object lists re-encode to the original
2,449 bytes, and the packed-state and mutable-cell offset tables follow the
lists. The Studio edits them within the capacities above.
