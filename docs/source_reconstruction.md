# Source reconstruction contract

The target is the source-level standard demonstrated by the sibling
`smb1_src` and `pacman_src` repositories, not merely a matching assembler dump.
Castle Excellent is complete only when all executable PRG bytes are reviewable
source, subsystem ownership is explicit, names describe proven behavior,
formats round-trip, and static and runtime gates protect the claims.

## Benchmark dimensions

| Dimension | Current Castle state | Required end state |
| --- | --- | --- |
| Identity | complete byte-identical iNES build | permanent |
| Executable source | complete ca65 PRG, no PRG `.incbin` | permanent |
| Source layout | platform/startup/NMI/rendering/UI and room/object/state pipeline, 110 semantic and 4 preservation modules | all ranges owned by semantic or typed-data modules |
| Control flow | all direct branches, jumps, and calls symbolic | semantic routine and local labels throughout |
| RAM/I/O | first global and scoped operand registry | complete evidence-backed RAM map and constants |
| Data formats | room decode and audio validation | lossless decode/encode and authoring contracts |
| Runtime evidence | boot, attract, gameplay, timeout CDL suite | title, transitions, death, ending, save/load, object and physics scenarios |
| Revisions | Japanese HSP-05 baseline | Castlequest profile with explicit shared/different source |
| Relocation | not yet established | source-reference relocation probes after semantic modularization |

## Promotion rule

A preservation range may move into a semantic module only when:

1. its start and end are backed by runtime, static control-flow, or typed-data
   evidence with explicit provenance;
2. the source layout still covers `$8000-$FFFF` exactly once;
3. no boundary splits an instruction or typed table;
4. RAM and routine names separate proof from inference;
5. deterministic regeneration produces the tracked source;
6. ca65/ld65 reproduces the complete reference image;
7. relevant format or runtime checks cover the subsystem claim.

The promoted ranges currently cover 28,130 PRG bytes (85.85%): `$E45D-$E8DE`
contains the complete room prefix-code tables and decoder, while
`$E8DF-$EA35` maps all 400 cells into two 64-byte nametable attribute buffers.
`$EB8F-$EC62` expands terminated static-object triples into the 24-record
runtime pool; `$EDD2-$EDEE` selects one of the 100 terminated lists; and
`$EF06-$F8FB` owns the object data and packed-state offsets. Mutable-cell
offsets at `$ABAE-$AC12`, snapshot restore/load at `$EE56-$EF05`, and the save
path at `$FDC5-$FE30` are joined by cell predicates, state application, room
object counts, and cell-derived object creation. These claims are independently
covered by all-100-room decoding, attribute construction, exact object-stream
round trips, both offset/bitmap-width checks, marker/capacity checks, typed PRG
ranges, Ghidra facts, and the byte-identical build.

The title/sub-command slice promotes `$F8FC-$FBFD` into six semantic modules.
The title path uploads its overlapping palette, copies four CHR-ROM pages into
the nametable, edge-detects Start, and enters attract mode after the 16-bit
timeout. The controller-2 sub-command path gates on game-over/demo state,
renders six typed strings, wraps a five-entry selection, dispatches
reset/back/load/save/exit, and restores current or previous room state through
the established snapshot pipeline. Its independent model pins all six range
hashes, transfer topology, eight strings, the 768-frame timeout, all three
four-page copy call sites, 327,680 menu-input cases, 262,144 entry-gating
cases, and both guarded room-restoration actions.

Audio track selection at `$B875-$B905` is split into semantic selector and
record-table modules. Seven entry points select sets 0-5 and 7; all but title
set 5 honor the demo-playback guard. The independent model pins both hashes,
all external callers, eight records, 24 pointer slots, the exact 11 RAM writes,
and 1,792 selector/demo-state cases.

The title-demo playback at `$B7FD-$B874` is semantic code and typed input data.
Its 72 commands suppress Select/Start, repeat the first command 11 times and
later commands 12 times, return 863 controller samples, then reset on read 864.
The model also proves pointer carry and NMI separation of scripted, second-pad,
and physical-controller input.

The music-data slice promotes `$BB16-$C20C` into four semantic modules: seven
note semitone offsets, 56 tempo-indexed duration bytes, 73 little-endian APU
periods, and 21 gap-free textual MML streams. The existing audio validator
checks all track pointers, command grammar, terminators, restart pointers, the
one unreferenced stream, and all 1,511 command bytes.

The audio-engine slice promotes `$B906-$BB15` into two semantic code modules
around an explicitly typed 11-byte orphan at `$BADE-$BAE8`. Its independent
model pins all 528 bytes and 16 external callers, proves stop/clear ownership,
walks all 21 MML streams, and exhaustively checks 16-bit pointer advance,
channel request routing, APU configuration, tick expiry, and channel gating.

The sound-effect slice promotes `$C20D-$C43C` into setup, per-frame update, and
typed-table modules. Five starters claim their exact channel/request/APU writes;
the NMI updater arbitrates pulse, triangle, and noise requests against live APU
length counters and advances the inventory, mutable-cell, and generic effects.
The focused model pins all 560 bytes, six entry points and their callers, table
bounds, request completion, step wraparound, and NMI music-before-effects order.

The adjacent `$C43D-$C4FC` slice now owns the player-following horizontal camera
curve, its destructive unsigned 16-bit divider, and the common 32-byte palette
upload. The model pins all 192 bytes and 15 callers, checks all 65,536 player X
positions, cross-checks quotient/remainder behavior, and verifies the exact PPU
write sequence including the final `$3F00` address/latch reset.

The room-loading vertical slice adds `$9578-$9582`, `$A35C-$A3AB`,
`$B64C-$B7FC`, and `$EC63-$ECB6`. It marks the one-based visited-room flag,
clears all 24 runtime records, decodes and applies room state, resets all 23 NMI
requests, initializes both nametables and OAM, writes the status area, builds
and uploads both attribute tables, then chooses room audio. Four packed status
tile streams, five pointer loads, and 16 initial attribute bytes are checked
independently against the reference PRG.

The platform slice covers both save-data transports at `$8000-$80FE` and
`$8180-$8224`, controller polling at `$80FF-$8157`, and PPU/CNROM helpers at
`$8158-$817F`. The pulse path emits one long cycle for zero and two short
cycles for one; the expansion path transfers eight bits MSB-first through
`$4016/$4017` after a `00 AA 55` preamble. An independent model exhaustively
checks all 256 expansion bytes, clock/data phases, preamble validation, pulse
symbols, and the 8,448-cycle pulse leader. A second exhaustive model checks all
256 controller masks on either D0 or the original D1 fallback. The four-byte
CHR selector table is typed data, and protocol and PPU literals are named
constants.

The save/load slice adds `$FBFE-$FDC4`. It serializes a fixed 394-byte payload:
room and runtime header bytes, 14 runtime bytes, 120 mutable-region bytes, 150
object-region bytes, all 100 visited flags, and the eight-byte `BEDEUTUN`
signature. The three RAM regions traverse descending addresses. A lossless
codec proves every field boundary, reversal, exact ROM signature source, and
encode/decode round trip. The load path checks carry for the preamble and every
field except payload byte one, preserving the original unchecked-status quirk.

The mutable-room-cell slice adds `$A58A-$A5DC`, `$A66D-$A6C9`, and
`$A70A-$A7DA`. It converts 16-bit pixel X and eight-bit pixel Y into tile
coordinates, maps two horizontal tiles onto each of the 400 room cells, finds
mutable anchors by one-based row-major ordinal, and restores `$54/$55` or
`$62/$63` according to neighboring cell `$16`. Restoration also sets the
matching persistent bitmap bit and requests the affected row and both room
attribute uploads. An independent model checks the full 40x20 tile domain,
both candidate families, ordinal-to-bit mapping, both restored forms, and the
`$949C-$94DA` pointer-to-row/NMI-request helpers across all 400 cell addresses.
The adjacent `$A6CA-$A6D7` classifier returns Y zero, and therefore Z set,
exactly for doubled cell indexes `$8A-$91`; these encode both lookup phases for
room-cell types `$45-$48`. Its full 256-byte input domain is checked independently.

The inventory-backed mutable-cell slice adds `$A5DD-$A66C`. The collision
table maps both halves of six persistent cell pairs to six entry points, which
consume inventory indexes `4,3,5,2,0,1` for anchors
`$19,$1C,$1F,$22,$25,$29`. A shared stack-unwind guard rejects a zero count,
active motion, or player Y not congruent to eight modulo 16. Success moves the
collision probe 16 pixels upward, restores and persists the selected cell,
plays the dedicated triangle/noise effect, and installs a nine-frame movement
delay only when facing outward beyond X `$0011/$0120`. Static pointer proof,
exact handler templates, and independent readiness/boundary models cover the
complete range.

The castle-navigation slice adds `$A7DB-$A834`. It establishes `$0037` as a
one-based room number over a 10x10 row-major grid. Up/down movement uses a
ten-room stride and saturates in the first/last row. Left/right movement uses
two exact ten-entry edge tables so it cannot wrap between neighboring rows.
The ROM-backed model checks the routine bytes, table contents, helper return
indexes, and all four directions from every room 1-100.

The player-hazard slice adds `$A835-$A8A8`. Two nonzero protection countdowns
decrement once per 32 room frames; each independently reselects room audio on
expiry. The bottom-center probe adds `(7,8)`, rejects wrapped coordinates
outside the 320x160-pixel room, rebases Y by 16, and marks contact only for
cells `$16,$62,$63`. The prior `$077C` load is proven dead because player Y
immediately replaces A. The independent model covers both complete timer byte
domains, all 65,536 player X values, all 256 Y and cell values, and all 400
room-cell indexes.

The runtime-object/player proximity slice adds `$A8A9-$A8E2`. It offsets the
current object's Y by 16 and returns carry clear only for vertical distance
below four and normalized 16-bit horizontal distance below five. All 15 direct
call sites use that carry contract. The original negative-X normalization does
not propagate the low-byte carry into the high byte, so `-$0100` aliases to
zero; the independent model preserves and proves all 64 such pairs within the
320-pixel room instead of silently correcting them.

The pause-input slice adds `$A8E3-$A959`. A new Start edge toggles pause; entry
disables all APU channels, while a new A/B edge also resumes. During pause,
Left takes priority and subtracts four with a zero floor; Right adds four and
saturates at `$80` in the valid scroll domain. Either direction sets the NMI
scroll-latch request. The exact model covers 131,072 current/previous button
pairs, every pause-mode byte, every scroll byte, and the original out-of-domain
Right wrap at `$FC-$FF`.

The collision-table slice adds `$A95A-$AB49`. Two 200-byte tables describe all
100 room-cell types at their left and right horizontal halves. The player view
uses flag bytes `$00,$01,$80`; the runtime-object view adds `$81`, with bit 7
feeding N and bit 0 feeding C after `BIT`/shift consumers. Two 48-byte tables
provide collision widths and heights for runtime types `$80-$AF`. Direct type
indexing deliberately uses table bases minus `$80`. The independent validator
checks every table byte and index, both exact flag-value domains, and the exact 18
machine-code consumers, including three one-based `RoomObjectCounts - 1`
accesses that share the final height-table address.

The frame-sprite slice adds `$AC13-$ADE6`. `BuildFrameSprites` locks and fills
all 256 staging bytes with `$F0`, draws the two-record player metasprite and an
optional action overlay, then reserves offsets `$00-$0B` and scans all 24
runtime-object records from offset `$0C`. Player selection distinguishes four
transition phases, neutral and directional motion, action countdown, and two
mirrored four-phase walk cycles. The 42-entry object render table begins at
the overlapping address `$AD93`: unused entry zero is `$6003`, formed by the
final `STA $030A` operand and `RTS`, while entries 1-41 occupy `$AD95-$ADE6`.
The model checks the exact 468-byte range, full player state partitions,
action-overlay direction/X domains, all type/Y dispatch inputs, and every
six-byte record offset.

The object-selector slice adds `$ADE7-$B1D5`. All 41 render-table indexes enter
named type-specific selectors; indexes 29 and 30 intentionally share one body.
Selectors use fixed descriptors, mirrored sign-bit families, `0,1,2,1` phase
cycles, modulo-three and room-frame phases, and state-dependent renderer widths.
Pointer-table provenance recovers the previously untraced first four handlers.
Seven bytes at `$AFCC-$AFD2` resemble a missing type-09 frame branch but follow
an unconditional jump and have no known entry, so they remain explicitly typed
unreferenced data rather than speculative code.

The accompanying object catalog closes the index relation across otherwise
separate semantic modules. It validates every legal encoded type, all 783
static occurrences and room memberships, 176 cell-derived objects, 42 update
pointers, 42 sprite pointers, loader initial states, and collision dimensions.
This identifies 32 directly sourced runtime types while leaving ten
runtime-created or unused indexes deliberately numeric pending behavior proof.

The common metasprite slice adds `$B1D6-$B64B`. Four object paths compose one,
two, two with four-pixel spacing, or four 8x16 hardware sprites, while the
player path always owns two fixed staging records. Object components project a
16-bit world X through the pending scroll and emit only page-zero results;
clipped components do not consume a staging slot. The player instead hides its
second component at Y `$F0` when adding eight wraps X. The adjacent data range
is exactly 203 `(tile, attributes)` pairs. An independent model verifies the
five machine-code paths, modular wrap behavior, all 107 descriptor selections
from `$AC60-$B1D5`, 98 unique pointers, their renderer-specific lengths, the
nine-value attribute domain, and the five intentionally unreferenced gaps.

The coordinate slice adds `$94DB-$952C`. Two player entries add 7 or 15 to the
16-bit position at `$38/$39`; six runtime-object entries return X, X plus
7/8/15/17, or X minus 2 from each six-byte record. All return A=high and
X=low. The independent 6502 arithmetic model exhaustively checks all 65,536
input positions, every helper offset, low-byte carry and borrow, and 16-bit
wraparound.

The shared room-address slice adds `$8ECB-$8F0F`. Seven collision and hazard
callers pass 16-bit X in A:X and byte Y in Y. The helper preserves those inputs
in scoped scratch, computes a row pointer as `$0400 + (Y >> 3) * 20`, shifts
the full X right four places into a 12-bit cell column, and leaves original X
bit 3 in carry for half-cell selection. Its model verifies the exact 69 bytes,
all seven call sites, every 16-bit X value, and every byte-wide Y value.

The player collision slice adds `$8DD3-$8ECA`. Twenty-eight call sites provide
screen X in A:X and screen Y in Y; the routine rejects pixels outside the
320x160 gameplay field below the 16-pixel status row. Player-specific cell-half
flags take priority, while empty or passable halves scan all 24 runtime records.
A nonzero request flag restricts that scan to types `$90-$95`; type `$86` also
has phase-, motion-, and vertical-half-dependent geometry. The independent
model verifies the exact 248 bytes and 176,888 boundary, cell, type, geometry,
special-state, and slot-order cases.

The player collision dispatch slice adds `$926B-$9385` and `$9477-$949B`.
Seven frame-level samples use the collision identity's high bit to select a
100-entry room-cell table or a 41-entry runtime-type table at `$926C/$9334`.
The doubled low seven bits select an interleaved pointer. The dispatcher pushes
`ReturnFromPlayerCollisionDispatch - 1` before its indirect jump, turning the
handler's `RTS` into a synthetic call and returning through the final local
`RTS`. Both exact tables, all 140 consumed identities, seven call sites, and
the 37-byte dispatcher are independently checked; the tables and their shared
no-op target now own a separate semantic data module.

The player death-transition slice adds `$8DAB-$8DD2`. Four animated room-cell
types first use the shared animation counter sign to select harmless or lethal
phase. Fifty-seven further room-cell/runtime-object entries plus the direct
hazard-contact jump converge on the death entry. Nonzero invulnerability or an
existing transition makes the handler a no-op; otherwise it installs a
128-frame transition, clears the action countdown, consumes one reserve life
or latches game over at zero, and selects audio track set 2. The independent
model checks all 65,536 guard pairs, all animation/life byte values, the exact
40 bytes, and every pointer source.

The current-room object-state save slice adds `$8758-$8784`. Before a room
transition or death reload, it scans all 24 six-byte runtime records and rotates
one bit per slot into a three-byte little-endian bitmap. Active persistent types
`$80-$A7` produce zero bits; empty, removed, and transient values produce one
bits so the later apply pass can suppress those records. It then snapshots the
one-based room number and bitmap. Five direct calls prove the complete routine;
the independent model checks the exact 45 bytes, all 256 type values, and every
slot-to-bit mapping.

The adjacent animated-cell displacement slice adds `$8785-$8819`. Twelve
incrementing cell identities `$56-$61` select the left handler and twelve
decrementing identities `$35-$40` select the right handler. Each computes a
two-pixel candidate, rejects the signed left edge or exact `$013F` right limit,
then probes the top, middle, and bottom of the entering player edge. Only three
clear results commit the 16-bit X coordinate and movement latch. The model
checks the exact 149 bytes, all 24 pointer entries, six sampler calls, every
16-bit X value, every byte Y value, and all collision-result patterns.

The collectible collision slice adds `$8C80-$8CF1`. Six runtime-type table
entries guard collection with the shared object/player proximity predicate,
award 20, 40, 80, or 100 score units, and select collected states 6-9. Type
`$83` also increments its screen state, conditionally starts audio track set 1,
and installs 40 protection ticks; type `$96` sets a dedicated effect latch.
The model checks the exact 114 bytes, six table targets, all call/jump topology,
and 786,432 proximity, screen-state, and protection combinations.

The adjacent type `$97` and score slice adds `$8CF2-$8D3C`. Collection awards
100 score units, then increments reserve lives directly and enters collected
state 9. `AddPlayerScore` suppresses all mutation during demo playback; in live
play it performs a wrapping 16-bit addition and compares the score divided by
1000 before and after the award. A changed quotient grants one life, saturating
at `$FF`, before type `$97` performs its separate wrapping increment. The model
checks the exact 75 bytes, all 13 score call sites, the runtime handler pointer,
the division-helper topology, and 378,880 score, award, and life cases.

The type `$9F` player-collision slice adds `$8D3D-$8D56`. It is active only
during the negative half of `RoomFrameCounter` and only when the runtime
object's low X byte equals the player's. A match starts audio track set 3 when
the prior invulnerability timer is zero, then always refreshes that timer to
40 ticks. The model checks the exact 26 bytes, current and next handler-table
entries, the audio call, and 66,048 frame, X-pair, and timer states.

The adjacent type `$81/$82` slice adds `$8D57-$8DAA`. Both handlers use the
shared proximity predicate and wait for the primary audio pointer to clear.
Type `$82` is disabled after game over; on contact it discards the synthetic
collision-dispatch return and jumps to the terminal completion sequence at
`$FE8E`. Type `$81` becomes `$91`, moves left 16 pixels, and in room `$59`
writes a second `$91` another 16 pixels left into the final runtime record.
The model checks all eight normal/directional pointers, exact handler hashes,
all 65,536 X values and audio-pointer pairs, and every room and Y byte.

The directional collision-table slice adds `$8F29-$926A`: three physical
matrices for downward, upward, and horizontal contact, each containing 100
room-cell pointers and 39 runtime pointers for types `$80-$A6`. Downward and
upward type `$A7` deliberately read the first pointer of the following room
table and obtain the shared no-op; horizontal `$A7` has no physical entry and
would cross into code as the invalid pointer `$B060`. The validator checks all
six table hashes and 417 physical entries, 420 logical selections, 12 indexed
consumers, three synthetic-call continuations, and every target against Ghidra
instruction starts. The tables also prove previously missing entries `$89E1`
and `$8D70`.

The frame-level player collision slice adds `$9386-$93F5`. With no active
transition it samples and dispatches seven ordered points: four player corners,
center, top-center, and a deliberate second top-right sample. An active
transition instead jumps directly to its countdown path. After all probes, a
nonzero hazard-contact flag starts death only when hazard protection is zero.
The model checks the exact 112 bytes and sole main-loop call, all 16-bit X and
byte Y wrap boundaries, the exact 14-call sequence, and transition/contact/
protection decisions.

The transition-reload slice adds `$93F6-$9476`. The byte countdown completes
only on `1 -> 0` and preserves the original `0 -> $FF` edge. Completion restores
saved player X/Y and either keeps protection unchanged, adds ten to the greater
of its current and mirrored values, or uses the screen-state override to set
`$32`. Zero reserve lives plus a nonzero game-over latch branches to the game-
over sequence; otherwise the current room is decoded, objects are loaded, both
persistent bitmaps are copied and applied, runtime/render state is rebuilt, and
NMI is resumed in the exact 13-call order. The model verifies all countdown
bytes, 131,072 protection combinations, exact bitmap widths, room indexing,
the 129 code bytes, and both terminal branches.

The adjacent transition/collision slice adds `$952D-$9577`.
`FinishRoomTransition` restores gameplay mode, mirrors player X/Y and two
transition bytes, then resumes rendering in the exact scroll-reset, NMI-enable,
vblank/render order. The collision module recognizes runtime types `$90-$95`
and maps room cells `$54,$55,$62,$63` to `$53`; it preserves the lower sampler's
complete processor status for ordinary cells and clears only carry for mapped
cells. Independent models check every type byte and all 65,536 cell/status
combinations.

The object-dispatch slice adds `$9583-$9612`. It walks all 24 six-byte runtime
records, clears the shared per-object update flag, strips the active high bit
from each type, and skips zero types or Y positions at/after `$A0`. The
remaining 1-41 type indexes select one of 42 interleaved little-endian handler
pointers. A manual indirect call pushes `AdvanceRuntimeObjectUpdate - 1` before
jumping through zero page, so each handler's `RTS` resumes the six-byte scan.
The independent model verifies the exact table, both possible high-bit forms,
the visibility boundary, and every record offset.

The adjacent overlap slice adds `$9613-$965B`. Three object handlers provide a
16-bit object X, an 8-bit Y, and a width. Carry returns clear only when player Y
lies from `objectY+1` through `objectY+16`, and player X lies in the half-open
interval from saturated `objectX-15` through `objectX+width`. The independent
model checks all byte-wide Y pairs and 921,600 room-width X/width cases.

The transient-object slice adds `$9FF3-$A043`. Type index 32 decrements state
until one, then replaces its type from a 15-byte table indexed by paired values
of the modulo-30 counter and chooses zero/negative state from frame parity.
Type index 40 increments state and clears its whole six-byte record at 15.
Type index 41 drifts upward on odd room frames and clears its record when byte
five counts down to zero. The model checks the exact table, all handler-pointer
entries, and 73,984 state/frame combinations.

The object-filter slice adds `$A044-$A0C3`. One routine recognizes the same
decrementing `$35-$40` and incrementing `$56-$61` cell families used by room
animation, returning direction values zero and `$FF`. Two runtime-type lookups
provide the exact type-84-to-89 zero filter and object-solidity flag. Each
physical table has 38 bytes for `$80-$A5`; the logical `$80-$A7` lookup also
consumes two nonzero opcode bytes from the following routine. The independent
model verifies all 256 cells, the proven `$00-$A7` type domain, seven aligned
call sites, five additional opcode matches, and both overlapping table views.

The point-sample slice adds `$A0C4-$A1A2`. It converts a 16-bit X and 8-bit Y
into one of 400 room cells, uses X bit 3 to select the cell's left or right
eight-pixel collision half, and returns the table byte's bit 0 and bit 7 as C
and N while restoring the cell type in A. Cell types `$45-$48` suppress their
flags during the negative half of `RoomCellAnimationCounter` but still return
as room-cell samples. Empty/passable halves scan all 24 runtime records in
ascending order, excluding `CurrentObjectOffset`; the first point-contained
type `$80-$A7` returns its record offset and solidity. The model verifies the
exact 223-byte routine, all 30 call sites, every cell/half/animation class,
every runtime type and slot, and 102,864 coordinate and geometry cases.

The room-only sample slice adds `$A1A3-$A1D3`. Its four callers probe paired
left/right edges while moving runtime objects. It shares the 20x20 addressing,
eight-pixel half selection, `$45-$48` animation gate, and C/N return contract
with the combined point sampler, but never scans runtime objects. A sample at
Y 160 or greater returns `$53` with X zero; valid samples always return the room
cell in A and doubled half index in X, including passable `$00` flags. The
independent model verifies the exact 49 bytes, four call sites, all 100 cell
types, both halves and animation signs, and all 51,200 room pixels.

The runtime-overlap slice adds `$A247-$A2A9`. Starting from any aligned pool
offset, it skips inactive types and types at/after `$A8`, tests the supplied Y
point against each candidate's height, and applies asymmetric horizontal bounds
using the candidate width on the left and supplied span width on the right.
It returns the first matching record offset with carry clear, while exhaustion
reaches the shared no-op handler return with carry set. The model verifies both
call sites, all 24 offsets, exact dimension tables, and 1,052,928 type/X/Y cases.

The adjacent `$A1D4-$A246` routine is now explicit unreferenced code. It accepts
a 16-bit X in A:X and Y pixel coordinate, rejects Y at or below the 160-pixel
playfield boundary, then scans all 24 runtime records without excluding the
current object. No direct call, pointer table, fallthrough, or captured runtime
path enters it; the former `$A207` flow was an invalid sprite-table overrun into
an operand byte. Validation binds all 115 bytes, checks 641 dispatch pointers,
proves zero live entries, models slot order and bounds, and confirms that the
Japanese and USA revisions contain the same routine.

The inventory-collectible slice promotes `$8C12-$8C7A`. Collision-table entries
for runtime types `$90-$95` select six handlers, which map bijectively onto the
six inventory counters in order `1,0,4,3,5,2`. A nearby player increments only
the selected byte, receives 10 score units, triggers the shared pickup sound,
and transforms the object into type `$A9`, state 5, with lifetime 20. A distant
player leaves all state unchanged. Validation pins all 105 bytes, six pointers,
call topology, wraparound increments, and 3,072 exhaustive state cases.

The seven bytes at `$A2AA-$A2B0` are now typed unreferenced data rather than a
speculative helper. They resemble `NmiTaskIndex = Y >> 3`, but no direct,
indirect, table, fallthrough, or runtime entry reaches them. Typed-data clearing
removes four false Ghidra instructions; validation checks the exact hash, all
known dispatch tables, runtime evidence, and all 256 hypothetical Y values.

The ending slice adds `$FE31-$FEE7`. Game over clears the playfield, writes the
typed `GAME OVER` tile string, starts track set 2, waits for audio, delays another
60 vblanks, and resets. Runtime type `$82` copies its completion nametable and
palette, starts track set 4, waits for audio, then freezes permanently. Both
paths first update the persistent high score with the unsigned maximum of it
and the player score. Validation checks all 183 bytes, 19 calls, both external
jumps, the terminal loop, decoded text, and 655,360 score comparisons.

The palette-data slice promotes `$C4FD-$C55C`. The first 64 bytes are three
overlapping 32-byte uploads: completion at `$C4FD`, title at `$C50D`, and the
castle map at `$C51D`; each later view reuses the preceding view's final 16
bytes. The adjacent 32-byte room palette at `$C53D` remains a separate table.
An independent validator checks all four data views, the fixed 32-byte uploader,
and its three calls plus the room-loader tail jump.

The final 280 PRG bytes are now three explicit typed modules: 72 erased bytes,
two 100-entry left/right tile tables, and two more erased bytes followed by the
NMI, reset, and IRQ vectors. The tile validator proves exactly 400 indexed
reads from each table across the 20 unrolled room-row tasks and checks all 100
cell pairs; vector checks bind `$C569`, `$8225`, and `$C6B8` to their platform
entry points.

The new-game slice adds `$A2B1-$A35B`. It selects one-based room `$47`, sets
three lives and player position `(0,$98)`, resets gameplay, transition,
game-over, collision, and sound-effect state, and clears the 120-byte mutable,
150-byte object, and 100-byte visited-room stores. It invalidates snapshot B by
clearing only its room id, preserving the remaining eight bytes. The 14-byte
runtime state is copied to the load mirror and snapshot A before active Y is
changed to `$98`; load-mirror byte 14 is likewise untouched. Fallthrough then
uploads the typed room palette at `$C53D`. An independent model preserves and
tests these non-obvious ordering and partial-clear contracts.

The room-runtime reset slice adds `$A3AC-$A3D1`. It clears ten movement,
scroll, scheduler, object-update, frame, and animation fields. The adjacent
audio guard tail-calls `SelectRoomAudio` only when game-over is zero and the
16-bit audio stream pointer is null. Its model checks all 65,536 pointer values,
all 255 nonzero game-over values, exact reset ownership, and preservation of
unrelated state.

The room-cell animation slice adds `$A3D2-$A496`. On odd room simulation
frames it scans all 400 cells and rotates three four-phase groups in
`$35-$40` backward while rotating three groups in `$56-$61` forward. Only the
first group of each family requests its row because the remaining grouped
cells share that row upload. A second scan rotates `$45-$48` after each fourth
odd frame while the incremented 8-bit animation counter is nonnegative; the
negative half-cycle deliberately pauses that family. The model verifies all
256 cell values, the exact 28 ROM table bytes, all 65,536 frame/counter pairs,
and request coverage for rows 0-19.

The HUD-format slice adds `$A497-$A572`. Cold-boot-cleared `$0001-$0002` is
now proven as the persistent high score, while new-game-cleared and
point-awarded `$000B-$000C` is the current player score. Either entry converts
its 16-bit value through the typed `10000,1000,100,10,1` table into five digit
tiles and blanks leading zeroes. The shared tail formats the 8-bit life count
in ones/tens/hundreds scratch order, saturates all six inventory counters at
nine, and releases the NMI interlock only after every buffer write. The model
exhausts 65,536 scores, 256 life counts, and 1,536 inventory cases. The
unreferenced code-shaped `$A573-$A589` tail is separately typed as data because
neither static nor runtime evidence reaches it.

The startup slice adds `$8225-$82CD`. `Reset` waits for two vblanks, establishes
the stack, compares the three-byte RAM sentinel `POW` with the five-byte ROM
signature `POWER`, clears high-score and reset-counter state only on a cold boot,
then increments the 16-bit reset counter. The main loop names its map, pause,
simulation, scroll, sprite, and sub-command phases. It loads a countdown of two;
NMI decrements that byte to zero before the next main update. The independent
startup model checks cold boot, warm reset, carry/wrap behavior, the exact ROM
text, and the saturating NMI gate.

The NMI slice adds `$C55D-$C6B8`. It dispatches through 23 high/low handler
tables, performs OAM DMA, coordinates the staging-buffer lock and scroll latch,
clears the completed task request, scans forward to the next pending task,
polls real or demo input, advances eight modular frame counters, and updates
audio while unpaused. A separate model validates every handler as a PRG address,
the exact forward-scan/wrap rule, and all counter periods.

The OAM slice adds `$C6B9-$C803`. `BuildDmaOam` treats staging OAM as eight
32-byte bands, selects one of eight sprite columns with a frame-rotated table,
and transposes eight four-byte records into each contiguous DMA block.
`ReverseDmaOam` swaps complete records from the ends inward. The independent
model proves all eight rotations, all 64 output records, reversal involution,
15 reachable table indexes, and the physically present but unreachable final
table byte. Sized memory symbols now render array offsets as relocatable ca65
expressions throughout generated source.

The NMI status slice adds `$C804-$C8BB`, including both handler-pointer tables.
`UploadStatusTiles` uses `$07C8` as a foreground/NMI interlock, uploads score,
inventory, and lives buffers to three fixed nametable destinations, and
delegates to the first room-row task when the buffers are busy. The independent
model proves the 13 source reads and their non-linear order, while the scheduler
model now verifies the exact status, 20 room-row, and two attribute handlers.

The four room-row modules cover `$C8BC-$E1F7`. They preserve the original
fully unrolled timing while naming all 20 task entry points and every offset in
the 400-byte room matrix. An independent encoder reproduces each `$143`-byte
handler from its row number, PPU destinations, cell addresses, tile lookup
tables, and return jump. Validation compares all 6,460 generated bytes against
the ROM and separately proves the 14-left/6-right cell split.

The attribute-task module completes `$E1F8-$E45C`. Its independent encoder
reproduces both handlers through their exact contiguous boundary: 56 direct
left writes, a 28-source-byte to 52-output-byte right-edge expansion, and the
right-path timing loop. Together with the scheduler, status, OAM, and room-row
modules, the full NMI pipeline at `$C55D-$E45C` is now semantic source.

`$EA36-$EB8E` now joins the room-data path without a preservation gap. The map
module names its input state, 100-room visited scan, PPU address arithmetic,
and OAM marker. The finalizer rebuilds the room display, requests all 23 NMI
tasks, restores rendering, and returns to CHR bank zero. A separate model proves
unique tile and sprite positions for the entire 10x10 room domain.

## Release gates

`make reconstruction-audit` reports semantic PRG ownership and rejects generic
address labels, raw address operands, and oversized files inside promoted
modules. Preservation regions remain explicitly outside that semantic claim.
`make release-check` runs this audit before deterministic regeneration and
byte-identical verification. Later milestones will extend the audit to
undocumented RAM fields, missing data round trips, and runtime scenarios absent
from the active reconstruction manifest.
