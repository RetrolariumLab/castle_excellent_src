# Data formats

All CPU addresses below refer to the Japanese PRG mapped at `$8000-$FFFF`.
The descriptions began with the published trace and were checked against the
exact Japanese reference image identified in `assets/manifest.json`.

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
`scripts/controller_input.py` exhaustively reconstructs every mask on both data
lines and is part of `make release-check`.

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
compares candidates in table order. `scripts/room_data.py` first proves that
the recovered table is prefix-free, then uses an equivalent direct lookup.

The independent decoder reaches exactly 400 output cells for all 100 rooms
without exhausting a CHR bank.

## Logical cell rendering

The decoded cell value indexes two PRG tables near `$FF30` and `$FF94`. They
select the left and right 8x8 background tile for a 16x8 logical cell.

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
the copy. `scripts/room_screen_data.py` checks the four exact boundaries, all
five immediate pointer loads, 45 tile bytes, and the 16-byte attribute tail.

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

Loading writes runtime type at record `+0`, scales X by 16 into the 16-bit
field at `+1/+2`, and scales Y by 8 into `+3`. Runtime types `$90-$95` receive
an additional four-pixel X offset. Record `+4` is initialized to zero except
for encoded types `$12-$29`, where the overlapping state table supplies its
initial value. The meaning of record `+5` and the later state transitions of
`+4` remain open.

## Music track sets and textual streams

Eight records beginning at `$B8C6` are selected by the audio setup code. Each
record contains three little-endian stream pointers followed by two channel
parameters:

```text
pulse 1 pointer, pulse 2 pointer, triangle pointer, parameter 1, parameter 2
```

A zero pointer disables that stream. Nonzero pointers address textual music
streams in `$BBE7-$C20C`. The interpreter recognizes octave (`o`), tempo (`t`),
default length (`l`), and volume (`v`) commands, notes `a-g`, rest `r`, `+`/`-`
accidentals, explicit lengths `@/1/2/4/8`, and dotted lengths. Each stream ends
with `$00`, then a little-endian restart pointer; `$0000` stops the channel.

There are 21 consecutive streams containing 1,511 command bytes. Twenty stream
starts are referenced by the track table; `$BE17` is structurally valid but is
not selected by those eight records. `scripts/audio_data.py` checks the grammar,
all pointers and terminators, restart targets, and gap-free coverage of the
complete range.

Seven selector entry points at `$B875-$B88D` load record offsets 0-5 and 7;
no static selector for record 6 is currently known. Their shared body at
`$B895` copies the three pointers and two channel parameters to zero-page audio
state and primes each duration counter to one tick.

## Round-trip status

The static object format has a lossless decoder and encoder. All 100 lists
re-encode to the original 2,449 bytes, and the packed-state offset table is
checked against every list's object count. The mutable-cell offset table is
also checked against all 40,000 decoded cells and its final-room exception.
Independent models apply both bitmap classes and reproduce the cell-marker
conversion, coordinate scaling, object initialization, and pool-capacity
contract.

Before compressed room data becomes editable source, the project still requires:

1. decode every room without overrun;
2. encode it back to the original bitstream or to an explicitly relocated
   equivalent format;
3. verify all pointer boundaries and CHR-bank capacity;
4. compare rendered rooms and runtime behavior.
