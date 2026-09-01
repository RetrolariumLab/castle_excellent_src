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
| Source layout | platform/startup/NMI/rendering/UI and room/object/state pipeline, 46 semantic and 10 preservation modules | all ranges owned by semantic or typed-data modules |
| Control flow | all direct branches, jumps, and calls symbolic | semantic routine and local labels throughout |
| RAM/I/O | first global and scoped operand registry | complete evidence-backed RAM map and constants |
| Data formats | room decode and audio validation | lossless decode/encode and authoring contracts |
| Runtime evidence | boot, attract, gameplay, timeout CDL suite | title, transitions, death, ending, save/load, object and physics scenarios |
| Revisions | Japanese HSP-05 baseline | Castlequest profile with explicit shared/different source |
| Relocation | not yet established | source-reference relocation probes after semantic modularization |

## Promotion rule

A preservation range may move into a semantic module only when:

1. its start and end are backed by instruction/data evidence;
2. the source layout still covers `$8000-$FFFF` exactly once;
3. no boundary splits an instruction or typed table;
4. RAM and routine names separate proof from inference;
5. deterministic regeneration produces the tracked source;
6. ca65/ld65 reproduces the complete reference image;
7. relevant format or runtime checks cover the subsystem claim.

The promoted ranges currently cover 16,694 PRG bytes (50.95%): `$E45D-$E8DE`
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
