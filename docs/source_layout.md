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
| `src/preservation/prg_82ce_8f0f.asm` | `$82CE-$8DAA` | unresolved player movement and early gameplay logic |
| `src/game/player/death_transition.asm` | `$8DAB-$8DD2` | animated hazard phase, guarded death, reserve lives, game over, and audio |
| `src/game/collision/player_sample.asm` | `$8DD3-$8ECA` | player room-cell and runtime-object collision sampler |
| `src/game/rooms/sample_address.asm` | `$8ECB-$8F0F` | room-row pointer and 16-bit collision-sample column preparation |
| `src/game/objects/runtime_record_offsets.asm` | `$8F10-$8F28` | six-byte record offsets by object count |
| `src/preservation/prg_8f29_949b.asm` | `$8F29-$926A` | unresolved early object/game logic before collision tables |
| `src/game/collision/player_handler_tables.asm` | `$926B-$9385` | shared no-op plus 100 room and 41 runtime collision handlers |
| `src/game/collision/player_update.asm` | `$9386-$93F5` | seven frame-level probes and protected-hazard death dispatch |
| `src/game/player/transition_reload.asm` | `$93F6-$9476` | transition countdown, protection, game over, and current-room reload |
| `src/game/collision/player_dispatch.asm` | `$9477-$949B` | room-cell/runtime-object collision-result handler dispatch |
| `src/rendering/room_cell_updates.asm` | `$949C-$94DA` | room-cell row calculation and NMI update requests |
| `src/game/x_coordinates.asm` | `$94DB-$952C` | player and runtime-object 16-bit X-coordinate helpers |
| `src/game/rooms/finish_transition.asm` | `$952D-$9551` | room-transition state mirroring and rendering resume |
| `src/game/collision/cell_samples.asm` | `$9552-$9577` | runtime-type filtering and mutable-cell collision normalization |
| `src/system/nmi_tasks.asm` | `$9578-$9582` | reset all 23 NMI task requests |
| `src/game/objects/update_dispatch.asm` | `$9583-$9612` | 24-record update dispatcher and 42 handler pointers |
| `src/game/objects/player_span_overlap.asm` | `$9613-$965B` | player and object-span overlap test |
| `src/preservation/prg_9613_a2b0.asm` | `$965C-$9FF2` | unresolved object handlers before transient lifecycles |
| `src/game/objects/transient_lifecycle.asm` | `$9FF3-$A043` | transient type 32/40/41 lifecycles and replacement table |
| `src/game/collision/object_filters.asm` | `$A044-$A0C3` | animated-cell and runtime-object collision filters |
| `src/game/collision/point_sample.asm` | `$A0C4-$A1A2` | room-cell and runtime-object point collision sample |
| `src/game/collision/room_sample.asm` | `$A1A3-$A1D3` | room-cell-only collision sample |
| `src/preservation/prg_a044_a2b0.asm` | `$A1D4-$A246` | unresolved collision sampler before runtime overlap |
| `src/game/collision/runtime_overlap.asm` | `$A247-$A2A9` | runtime-object overlap scan and shared no-op return |
| `src/preservation/prg_a2aa_a2b0.asm` | `$A2AA-$A2B0` | unresolved helper before new-game initialization |
| `src/game/new_game.asm` | `$A2B1-$A350` | new-game state and persistent-region initialization |
| `src/rendering/room_palette.asm` | `$A351-$A35B` | room palette pointer setup and upload |
| `src/game/rooms/load_room.asm` | `$A35C-$A3AB` | top-level room loading and audio selection |
| `src/game/rooms/runtime_reset.asm` | `$A3AC-$A3D1` | room-runtime reset and conditional room-audio restart |
| `src/game/rooms/cell_animation.asm` | `$A3D2-$A496` | full-room animation scans, cadence, and phase tables |
| `src/rendering/status_format.asm` | `$A497-$A572` | score, lives, inventory, and HUD interlock formatting |
| `src/data/unreferenced_bit_index_helper.asm` | `$A573-$A589` | typed code-shaped bytes with no proven entry |
| `src/game/rooms/cell_coordinates.asm` | `$A58A-$A5DC` | pixel/tile conversion and 20x20 room-cell addressing |
| `src/game/rooms/mutable_cell_actions.asm` | `$A5DD-$A66C` | six inventory-backed persistent-cell action handlers |
| `src/game/rooms/mutable_cell_lookup.asm` | `$A66D-$A6C9` | mutable-cell anchor lookup and one-based ordinal calculation |
| `src/game/collision/cell_pair_index.asm` | `$A6CA-$A6D7` | doubled cell-index classifier for cell types `$45-$48` |
| `src/game/rooms/mutable_cell_predicates.asm` | `$A6D8-$A709` | persistent mutable-cell predicates |
| `src/game/rooms/mutable_cell_restore.asm` | `$A70A-$A7DA` | ordinal restoration, persistence bit, and render requests |
| `src/game/rooms/navigation.asm` | `$A7DB-$A834` | one-based 10x10 castle navigation and edge tables |
| `src/game/player/hazard_state.asm` | `$A835-$A8A8` | protection countdowns and player hazard-cell contact |
| `src/game/objects/player_proximity.asm` | `$A8A9-$A8E2` | runtime-object/player interaction proximity predicate |
| `src/input/pause.asm` | `$A8E3-$A959` | pause/resume edges and paused horizontal-scroll input |
| `src/game/collision/tables.asm` | `$A95A-$AB49` | room-cell collision flags and runtime-object dimensions |
| `src/game/rooms/room_metadata.asm` | `$AB4A-$AC12` | object counts and mutable-state offsets |
| `src/rendering/frame_sprites.asm` | `$AC13-$ADE6` | staging clear, player/action selection, object render dispatch and pointers |
| `src/rendering/object_sprite_selectors.asm` | `$ADE7-$B1D5` | per-type descriptor, animation phase, and renderer selection |
| `src/rendering/object_metasprites.asm` | `$B1D6-$B4B5` | common object/player metasprite composition and clipping |
| `src/rendering/metasprite_data.asm` | `$B4B6-$B64B` | 203 tile/attribute descriptor pairs |
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

The 63 PRG sources contain no CHR data and no `.incbin`. Their boundaries are
machine-checked from `config/source_layout.json`; the first file includes the
following 62 in CPU-address order. Ghidra-defined instructions are emitted
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
