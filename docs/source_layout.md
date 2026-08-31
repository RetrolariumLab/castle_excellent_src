# Source layout

The source is one canonical address-ordered PRG translation unit:

| Module | Output | Responsibility |
| --- | --- | --- |
| `src/main.asm` | header + include order | canonical entrypoint |
| `src/preservation/prg.asm` | `$8000-$E45C` | unresolved leading PRG and ordered includes |
| `src/game/rooms/decoder.asm` | `$E45D-$E8DE` | codebook, pointers, bit reader, and room decoder |
| `src/rendering/room_attributes.asm` | `$E8DF-$EA35` | attribute addressing, builder, and cell palette table |
| `src/preservation/prg_ea36_eb8e.asm` | `$EA36-$EB8E` | unresolved room-load completion and PPU work |
| `src/game/objects/room_loader.asm` | `$EB8F-$EC62` | static-object lookup tables and runtime-record loader |
| `src/preservation/prg_ec63_ffff.asm` | `$EC63-$FFFF` | unresolved trailing PRG |
| `src/graphics/chr.asm` | four 8 KiB banks | private CHR payload |
| `src/memory/hardware.inc` | no bytes | NES register aliases |
| `src/memory/ram.inc` | no bytes | evidence-backed RAM aliases |

The six PRG sources contain no CHR data and no `.incbin`. Their boundaries
are machine-checked from `config/source_layout.json`; the first file includes
the following five in CPU-address order. Ghidra-defined instructions are emitted
mnemonically and all other ranges use `.byte`. Static direct branch, jump, and
call operands are labels. Because Ghidra cannot represent overlapping
instructions, 38 entry points inside an existing instruction are preserved as
ca65 offset symbols such as `Label_E5A1 = * + 1`.

`config/memory_symbols.json` makes operand naming deterministic. A global entry
is used everywhere its address appears; an address-scoped entry is used only
inside the proven subsystem range. This lets shared zero-page scratch bytes
receive honest contextual names without claiming global ownership.
`config/operand_overrides.json` records instruction-addressed replacements for
relocatable ca65 expressions, together with the exact original operand and an
evidence note; regeneration fails if the underlying instruction changes.

Future module splits must occur only at proven procedure or data boundaries and
must keep address order. Aim for coherent modules of roughly 200-500 lines,
with 700 lines as a soft upper bound.

CHR banks 2 and 3 are not purely graphics. Their room bitstreams must remain
address-stable until the decoder and future encoder prove every pointer and
boundary.
