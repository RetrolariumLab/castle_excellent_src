# Source layout

The source is one canonical address-ordered PRG translation unit:

| Module | Output | Responsibility |
| --- | --- | --- |
| `src/main.asm` | header + include order | canonical entrypoint |
| `src/preservation/prg.asm` | `$8000-$80FE` | unresolved Famicom tape signaling and ordered includes |
| `src/input/controllers.asm` | `$80FF-$8157` | controller wrappers and serial polling |
| `src/system/ppu.asm` | `$8158-$817F` | PPU state helpers and CNROM bank selection |
| `src/preservation/prg_8180_8224.asm` | `$8180-$8224` | unresolved Famicom tape/peripheral signaling |
| `src/system/startup.asm` | `$8225-$82CD` | reset, cold/warm boot state, and NMI-paced main loop |
| `src/preservation/prg_82ce_8f0f.asm` | `$82CE-$8F0F` | unresolved player movement and early gameplay logic |
| `src/game/objects/runtime_record_offsets.asm` | `$8F10-$8F28` | six-byte record offsets by object count |
| `src/preservation/prg_8f29_9577.asm` | `$8F29-$9577` | unresolved early object/game logic |
| `src/system/nmi_tasks.asm` | `$9578-$9582` | reset all 23 NMI task requests |
| `src/preservation/prg_9583_a35b.asm` | `$9583-$A35B` | unresolved object handlers and gameplay logic |
| `src/game/rooms/load_room.asm` | `$A35C-$A3AB` | top-level room loading and audio selection |
| `src/preservation/prg_a3ac_a6d7.asm` | `$A3AC-$A6D7` | unresolved room/gameplay helpers |
| `src/game/rooms/mutable_cell_predicates.asm` | `$A6D8-$A709` | persistent mutable-cell predicates |
| `src/preservation/prg_a70a_ab49.asm` | `$A70A-$AB49` | unresolved room manipulation helpers |
| `src/game/rooms/room_metadata.asm` | `$AB4A-$AC12` | object counts and mutable-state offsets |
| `src/preservation/prg_ac13_b64b.asm` | `$AC13-$B64B` | unresolved object handlers and sprite data |
| `src/rendering/room_screen.asm` | `$B64C-$B7FC` | room nametable, status, attribute, and OAM initialization |
| `src/preservation/prg_b7fd_c55c.asm` | `$B7FD-$C55C` | unresolved demo input, audio, and scroll helpers |
| `src/system/nmi.asm` | `$C55D-$C6B8` | NMI dispatch, OAM/scroll, input, scheduler, counters, and audio tick |
| `src/rendering/oam_dma.asm` | `$C6B9-$C803` | OAM staging transpose, frame rotation, and record reversal |
| `src/rendering/status_upload.asm` | `$C804-$C8BB` | NMI HUD upload and 23-task handler tables |
| `src/rendering/room_rows_00_04.asm` | `$C8BC-$CF0A` | NMI room-row upload tasks 00-04 |
| `src/rendering/room_rows_05_09.asm` | `$CF0B-$D559` | NMI room-row upload tasks 05-09 |
| `src/rendering/room_rows_10_14.asm` | `$D55A-$DBA8` | NMI room-row upload tasks 10-14 |
| `src/rendering/room_rows_15_19.asm` | `$DBA9-$E1F7` | NMI room-row upload tasks 15-19 |
| `src/rendering/room_attribute_upload.asm` | `$E1F8-$E45C` | final left/right NMI attribute upload tasks |
| `src/game/rooms/decoder.asm` | `$E45D-$E8DE` | codebook, pointers, bit reader, and room decoder |
| `src/rendering/room_attributes.asm` | `$E8DF-$EA35` | attribute addressing, builder, and cell palette table |
| `src/ui/castle_map.asm` | `$EA36-$EB6B` | castle-map input, visited-room tiles, and current-room marker |
| `src/game/rooms/finalize_room.asm` | `$EB6C-$EB8E` | room-screen finalization and all NMI requests |
| `src/game/objects/room_loader.asm` | `$EB8F-$EC62` | static-object lookup tables and runtime-record loader |
| `src/game/rooms/state_orchestration.asm` | `$EC63-$ECB6` | object loading, state selection, and snapshot rotation |
| `src/game/rooms/persistent_state_apply.asm` | `$ECB7-$EDD1` | bitmap application and cell-derived objects |
| `src/game/objects/stream_seek.asm` | `$EDD2-$EDEE` | terminated room-object list navigation |
| `src/game/rooms/mutable_cell_state_apply.asm` | `$EDEF-$EE55` | mutable-cell state-bit application |
| `src/game/rooms/persistent_state_load.asm` | `$EE56-$EF05` | snapshot restore and persistent-state loading |
| `src/game/objects/room_data.asm` | `$EF06-$F8FB` | packed-state offsets and 100 terminated object lists |
| `src/preservation/prg_f8fc_fdc4.asm` | `$F8FC-$FDC4` | unresolved UI, sub-command, and password code |
| `src/game/rooms/persistent_state_save.asm` | `$FDC5-$FE30` | snapshot persistence writer |
| `src/preservation/prg_fe31_ffff.asm` | `$FE31-$FFFF` | unresolved ending and tail tables |
| `src/graphics/chr.asm` | four 8 KiB banks | private CHR payload |
| `src/memory/hardware.inc` | no bytes | NES register aliases |
| `src/memory/ram.inc` | no bytes | evidence-backed RAM aliases |

The 40 PRG sources contain no CHR data and no `.incbin`. Their boundaries are
machine-checked from `config/source_layout.json`; the first file includes the
following 39 in CPU-address order. Ghidra-defined instructions are emitted
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
