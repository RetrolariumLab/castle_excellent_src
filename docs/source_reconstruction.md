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
| Source layout | platform/startup/NMI/rendering/UI and room/object/state pipeline, 29 semantic and 11 preservation modules | all ranges owned by semantic or typed-data modules |
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

The promoted ranges currently cover 14,421 PRG bytes (44.01%): `$E45D-$E8DE`
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

The platform slice adds controller polling at `$80FF-$8157` and PPU/CNROM
helpers at `$8158-$817F`. An exhaustive independent model checks all 256 button
masks when serialized on either D0 or the original D1 fallback. The four-byte
CHR selector table is typed data, and the fixed PPUCTRL/PPUMASK modes are named
constants rather than unexplained literals.

The startup slice adds `$8225-$82CD`. `Reset` waits for two vblanks, establishes
the stack, compares the three-byte RAM sentinel `POW` with the five-byte ROM
signature `POWER`, clears score and reset-counter state only on a cold boot,
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
