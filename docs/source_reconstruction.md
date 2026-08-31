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
| Source layout | room loading/object/state pipeline, 16 semantic and ten preservation modules | all ranges owned by semantic or typed-data modules |
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

The promoted ranges currently cover 5,842 PRG bytes (17.83%): `$E45D-$E8DE`
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

## Release gates

`make reconstruction-audit` reports semantic PRG ownership and rejects generic
address labels, raw address operands, and oversized files inside promoted
modules. Preservation regions remain explicitly outside that semantic claim.
`make release-check` runs this audit before deterministic regeneration and
byte-identical verification. Later milestones will extend the audit to
undocumented RAM fields, missing data round trips, and runtime scenarios absent
from the active reconstruction manifest.
