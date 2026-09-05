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
| `src/preservation/prg_82ce_8f0f.asm` | `$82CE-$8757` | unresolved player movement and room-transition logic |
| `src/game/rooms/object_state_save.asm` | `$8758-$8784` | current-room runtime object-state bitmap save |
| `src/game/player/animated_cell_displacement.asm` | `$8785-$8819` | forced horizontal movement from animated room cells |
| `src/preservation/prg_881a_8c11.asm` | `$881A-$8C11` | unresolved player movement and early gameplay logic |
| `src/game/objects/inventory_collectible_handlers.asm` | `$8C12-$8C7A` | six inventory pickups and shared collected-object transform |
| `src/preservation/prg_8c7b_8c7f.asm` | `$8C7B-$8C7F` | unreferenced runtime-object clear tail |
| `src/game/objects/collectible_collision_handlers.asm` | `$8C80-$8CF1` | six runtime collectible collision handlers |
| `src/game/objects/collectible_type97.asm` | `$8CF2-$8D03` | type `$97` score-and-life collectible handler |
| `src/game/scoring/add_score.asm` | `$8D04-$8D3C` | score awards and 1000-point extra-life threshold |
| `src/game/collision/runtime_type9f.asm` | `$8D3D-$8D56` | phase/X guarded type `$9F` invulnerability effect |
| `src/game/collision/runtime_types81_82.asm` | `$8D57-$8DAA` | type `$82` completion trigger and type `$81` transform/clone handlers |
| `src/game/player/death_transition.asm` | `$8DAB-$8DD2` | animated hazard phase, guarded death, reserve lives, game over, and audio |
| `src/game/collision/player_sample.asm` | `$8DD3-$8ECA` | player room-cell and runtime-object collision sampler |
| `src/game/rooms/sample_address.asm` | `$8ECB-$8F0F` | room-row pointer and 16-bit collision-sample column preparation |
| `src/game/objects/runtime_record_offsets.asm` | `$8F10-$8F28` | six-byte record offsets by object count |
| `src/game/collision/player_movement_handler_tables.asm` | `$8F29-$926A` | downward, upward, and horizontal collision-handler pointer matrices |
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
| `src/game/collision/unreferenced_runtime_only_sample.asm` | `$A1D4-$A246` | unreferenced runtime-object-only point sampler |
| `src/game/collision/runtime_overlap.asm` | `$A247-$A2A9` | runtime-object overlap scan and shared no-op return |
| `src/data/unreferenced_nmi_task_index_bytes.asm` | `$A2AA-$A2B0` | unreferenced code-shaped bytes resembling `Y >> 3` |
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
| `src/input/demo_playback.asm` | `$B7FD-$B82B` | title-demo controller script playback |
| `src/data/title_demo_input.asm` | `$B82C-$B874` | 72-command title-demo input script and terminator |
| `src/audio/track_selection.asm` | `$B875-$B8C5` | track-set selection and channel initialization |
| `src/audio/track_table.asm` | `$B8C6-$B905` | eight track-set records |
| `src/audio/stream_engine.asm` | `$B906-$BADD` | textual MML stream interpreter and scheduler |
| `src/data/unreferenced_lowercase_hex_digit_decode_bytes.asm` | `$BADE-$BAE8` | typed orphan bytes shaped like a lowercase-hex decoder |
| `src/audio/channel_configuration.asm` | `$BAE9-$BB15` | streamed-note APU channel configuration |
| `src/audio/note_semitone_offsets.asm` | `$BB16-$BB1C` | MML note-to-semitone offsets |
| `src/audio/note_length_table.asm` | `$BB1D-$BB54` | tempo-indexed note durations |
| `src/audio/apu_period_table.asm` | `$BB55-$BBE6` | little-endian APU note periods |
| `src/audio/music_mml_data.asm` | `$BBE7-$C20C` | 21 terminated textual music streams |
| `src/audio/sound_effect_starters.asm` | `$C20D-$C2F8` | five sound-effect channel setup routines |
| `src/audio/sound_effect_update.asm` | `$C2F9-$C428` | per-frame sound-effect request updater |
| `src/audio/sound_effect_tables.asm` | `$C429-$C43C` | period and envelope tables |
| `src/preservation/prg_c43d_c4fc.asm` | `$C43D-$C4FC` | unresolved scroll, division, and palette helpers |
| `src/rendering/screen_palette_data.asm` | `$C4FD-$C53C` | overlapping completion, title, and castle-map palettes |
| `src/rendering/room_palette_data.asm` | `$C53D-$C55C` | gameplay room background and sprite palette |
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
| `src/ui/title_screen.asm` | `$F8FC-$F972` | title screen, Start edge, and attract timeout |
| `src/rendering/chr_nametable_copy.asm` | `$F973-$F9AC` | four-page CHR-ROM to nametable copy |
| `src/ui/sub_command_input.asm` | `$F9AD-$F9CB` | menu entry gating and controller-2 edge detection |
| `src/ui/sub_command_menu.asm` | `$F9CC-$FB76` | menu rendering, selection, and dispatch |
| `src/data/sub_command_text.asm` | `$FB77-$FBAB` | menu and transfer-status tile text |
| `src/ui/sub_command_room_actions.asm` | `$FBAC-$FBFD` | current/previous-room restoration actions |
| `src/game/save_load.asm` | `$FBFE-$FDC4` | save/load payload, validation, messages, and room restoration |
| `src/game/rooms/persistent_state_save.asm` | `$FDC5-$FE30` | snapshot persistence writer |
| `src/game/end_sequences.asm` | `$FE31-$FEE7` | game over, type `$82` completion, and high-score update |
| `src/data/prg_tail_padding.asm` | `$FEE8-$FF2F` | 72-byte erased-ROM padding |
| `src/rendering/room_cell_tile_tables.asm` | `$FF30-$FFF7` | left/right tile index for every room-cell type |
| `src/system/interrupt_vectors.asm` | `$FFF8-$FFFF` | vector padding and NMI/reset/IRQ addresses |
| `src/graphics/chr.asm` | four 8 KiB banks | private CHR payload |
| `src/memory/hardware.inc` | no bytes | NES register aliases |
| `src/memory/ram.inc` | no bytes | evidence-backed RAM aliases |

The 112 PRG sources contain no CHR data and no `.incbin`. Their boundaries are
machine-checked from `config/source_layout.json`; the first file includes the
following 111 in CPU-address order. Ghidra-defined instructions are emitted
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
