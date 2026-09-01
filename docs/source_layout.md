# Source layout

The source is one canonical address-ordered PRG translation unit:

| Module | Output | Responsibility |
| --- | --- | --- |
| `src/main.asm` | header + include order | canonical entrypoint |
| `src/input/famicom_data_pulse.asm` | `$8000-$80FE` | pulse-width data transport and ordered includes |
| `src/input/controllers.asm` | `$80FF-$8157` | controller wrappers and serial polling |
| `src/system/ppu.asm` | `$8158-$817F` | PPU state helpers and CNROM bank selection |
| `src/input/famicom_data_io.asm` | `$8180-$8224` | transport selection and expansion-port serial I/O |
| `src/system/startup.asm` | `$8225-$82CD` | reset, cold/warm boot state, and NMI-paced main loop |
| `src/preservation/prg_82ce_8f0f.asm` | `$82CE-$8F0F` | unresolved player movement and early gameplay logic |
| `src/game/objects/runtime_record_offsets.asm` | `$8F10-$8F28` | six-byte record offsets by object count |
| `src/preservation/prg_8f29_949b.asm` | `$8F29-$949B` | unresolved early object/game logic before row updates |
| `src/rendering/room_cell_updates.asm` | `$949C-$94DA` | room-cell row calculation and NMI update requests |
| `src/game/x_coordinates.asm` | `$94DB-$952C` | player and runtime-object 16-bit X-coordinate helpers |
| `src/game/rooms/finish_transition.asm` | `$952D-$9551` | room-transition state mirroring and rendering resume |
| `src/game/collision/cell_samples.asm` | `$9552-$9577` | runtime-type filtering and mutable-cell collision normalization |
| `src/system/nmi_tasks.asm` | `$9578-$9582` | reset all 23 NMI task requests |
| `src/game/objects/update_dispatch.asm` | `$9583-$9612` | 24-record update dispatcher and 42 handler pointers |
| `src/preservation/prg_9613_a2b0.asm` | `$9613-$A2B0` | unresolved object handlers and gameplay logic |
| `src/game/new_game.asm` | `$A2B1-$A350` | new-game state and persistent-region initialization |
| `src/rendering/room_palette.asm` | `$A351-$A35B` | room palette pointer setup and upload |
| `src/game/rooms/load_room.asm` | `$A35C-$A3AB` | top-level room loading and audio selection |
| `src/game/rooms/runtime_reset.asm` | `$A3AC-$A3D1` | room-runtime reset and conditional room-audio restart |
| `src/game/rooms/cell_animation.asm` | `$A3D2-$A496` | full-room animation scans, cadence, and phase tables |
| `src/rendering/status_format.asm` | `$A497-$A572` | score, lives, inventory, and HUD interlock formatting |
| `src/data/unreferenced_bit_index_helper.asm` | `$A573-$A589` | typed code-shaped bytes with no proven entry |
| `src/game/rooms/cell_coordinates.asm` | `$A58A-$A5DC` | pixel/tile conversion and 20x20 room-cell addressing |
| `src/preservation/prg_a5dd_a66c.asm` | `$A5DD-$A66C` | unresolved gameplay helpers before mutable-cell lookup |
| `src/game/rooms/mutable_cell_lookup.asm` | `$A66D-$A6C9` | mutable-cell anchor lookup and one-based ordinal calculation |
| `src/preservation/prg_a6ca_a6d7.asm` | `$A6CA-$A6D7` | unresolved helper between lookup and predicates |
| `src/game/rooms/mutable_cell_predicates.asm` | `$A6D8-$A709` | persistent mutable-cell predicates |
| `src/game/rooms/mutable_cell_restore.asm` | `$A70A-$A7DA` | ordinal restoration, persistence bit, and render requests |
| `src/preservation/prg_a7db_ab49.asm` | `$A7DB-$AB49` | unresolved room manipulation helpers |
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
| `src/preservation/prg_f8fc_fbfd.asm` | `$F8FC-$FBFD` | unresolved title and sub-command UI |
| `src/game/save_load.asm` | `$FBFE-$FDC4` | save/load payload, validation, messages, and room restoration |
| `src/game/rooms/persistent_state_save.asm` | `$FDC5-$FE30` | snapshot persistence writer |
| `src/preservation/prg_fe31_ffff.asm` | `$FE31-$FFFF` | unresolved ending and tail tables |
| `src/graphics/chr.asm` | four 8 KiB banks | private CHR payload |
| `src/memory/hardware.inc` | no bytes | NES register aliases |
| `src/memory/ram.inc` | no bytes | evidence-backed RAM aliases |

The 56 PRG sources contain no CHR data and no `.incbin`. Their boundaries are
machine-checked from `config/source_layout.json`; the first file includes the
following 55 in CPU-address order. Ghidra-defined instructions are emitted
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
