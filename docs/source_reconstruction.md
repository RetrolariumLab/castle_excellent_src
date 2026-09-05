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
| Source layout | platform/startup/NMI/rendering/UI and room/object/state pipeline, 54 semantic and 7 preservation modules | all ranges owned by semantic or typed-data modules |
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

The promoted ranges currently cover 20,348 PRG bytes (62.10%): `$E45D-$E8DE`
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
