; Famicom pulse-width data transport
; CPU range $8000-$80FE
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

.segment "PRG"

DelayLongPulseHalf:
    LDX #$91

WaitLongPulseHalf:
    DEX
    BNE WaitLongPulseHalf
    RTS

DelayShortPulseHalf:
    LDX #$47

WaitShortPulseHalf:
    DEX
    BNE WaitShortPulseHalf
    RTS

WaitForPulseEdge:
    LDY #$00

MeasurePulseEdgeDelay:
    INY
    BEQ ReturnPulseEdgeTimeout
    LDA JOYPAD1
    AND #PulseInputMask
    EOR PulseInputLevel
    BEQ MeasurePulseEdgeDelay
    EOR PulseInputLevel
    STA PulseInputLevel
    RTS

ReturnPulseEdgeTimeout:
    DEY
    RTS

CountPulseEdgesInWindow:
    LDX #PulseSampleCount
    LDY #$00

SamplePulseWindow:
    LDA JOYPAD1
    AND #PulseInputMask
    EOR PulseInputLevel
    BEQ PadUnchangedPulseSample
    EOR PulseInputLevel
    STA PulseInputLevel
    INY
    DEX
    BNE SamplePulseWindow
    RTS

PadUnchangedPulseSample:
    LDA PulseInputLevel
    LDA PulseInputLevel
    LDA PulseInputLevel
    DEX
    BNE SamplePulseWindow
    RTS

EmitLongPulseCycle:
    LDA #$00
    STA JOYPAD1
    JSR DelayLongPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayLongPulseHalf
    LDA #$00
    STA JOYPAD1
    RTS

EmitPulseBitFromCarry:
    BCC EmitLongPulseCycle

EmitShortPulsePair:
    LDA #$00
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$00
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$00
    STA JOYPAD1
    RTS

ReceivePulsePreamble:
    LDA #PulseReceiveMode
    STA JOYPAD1
    LDX #$00
    STX PulseInputLevel

ReadNextPulsePreambleEdge:
    JSR WaitForPulseEdge
    CPY #PulsePreambleMinEdgeDelay
    BCC ReceivePulsePreamble
    CPY #PulsePreambleMaxEdgeDelayExclusive
    BCS ReceivePulsePreamble
    INX
    BNE ReadNextPulsePreambleEdge
    RTS

SendPulsePreamble:
    LDA #PulsePreamblePageTotal
    STA PulsePreamblePageCount
    LDY #$00

SendPulsePreambleCycles:
    JSR EmitShortPulsePair
    DEY
    BNE SendPulsePreambleCycles
    DEC PulsePreamblePageCount
    BNE SendPulsePreambleCycles
    CLC
    RTS

SendPulseByte:
    JSR EmitLongPulseCycle
    LDY #DataIoBitCount

SendNextPulseBit:
    ASL DataIoByte
    JSR EmitPulseBitFromCarry
    DEY
    BNE SendNextPulseBit
    JSR EmitShortPulsePair
    JMP EmitShortPulsePair

ReceivePulseByte:
    LDA JOYPAD1
    AND #PulseInputMask
    BEQ ReceivePulseByte

WaitForPulseStartLow:
    LDA JOYPAD1
    AND #PulseInputMask
    BNE WaitForPulseStartLow
    STA PulseInputLevel
    JSR WaitForPulseEdge

MeasurePulseStartWidth:
    STY PulseAccumulatedWidth
    JSR WaitForPulseEdge
    TYA
    CLC
    ADC PulseAccumulatedWidth
    BCS MeasurePulseStartWidth
    CMP #PulseStartMinWidth
    BCC MeasurePulseStartWidth
    LDA #DataIoBitCount
    STA PulseBitsRemaining

DecodeNextPulseBit:
    JSR CountPulseEdgesInWindow
    CPY #PulseInvalidEdgeCount
    BCS ReturnPulseByteStatus
    CPY #PulseOneEdgeCount
    ROL DataIoByte
    TYA
    LSR A
    BCS WaitForPulseBitTail
    JSR WaitForPulseEdge

WaitForPulseBitTail:
    JSR WaitForPulseEdge
    DEC PulseBitsRemaining
    BNE DecodeNextPulseBit
    LDA PulseAccumulatedWidth
    CLC

ReturnPulseByteStatus:
    RTS

.include "controllers.asm"
.include "../system/ppu.asm"
.include "famicom_data_io.asm"
.include "../system/startup.asm"
.include "../game/player/input_and_movement.asm"
.include "../game/rooms/boundary_transitions.asm"
.include "../game/rooms/object_state_save.asm"
.include "../game/player/animated_cell_displacement.asm"
.include "../game/player/object_push.asm"
.include "../game/objects/linked_lift_control.asm"
.include "../game/objects/inventory_collectible_handlers.asm"
.include "../data/unreferenced_runtime_object_clear_tail.asm"
.include "../game/objects/collectible_collision_handlers.asm"
.include "../game/objects/collectible_type97.asm"
.include "../game/scoring/add_score.asm"
.include "../game/collision/runtime_type9f.asm"
.include "../game/collision/runtime_types81_82.asm"
.include "../game/player/death_transition.asm"
.include "../game/collision/player_sample.asm"
.include "../game/rooms/sample_address.asm"
.include "../game/objects/runtime_record_offsets.asm"
.include "../game/collision/player_movement_handler_tables.asm"
.include "../game/collision/player_handler_tables.asm"
.include "../game/collision/player_update.asm"
.include "../game/player/transition_reload.asm"
.include "../game/collision/player_dispatch.asm"
.include "../rendering/room_cell_updates.asm"
.include "../game/x_coordinates.asm"
.include "../game/rooms/finish_transition.asm"
.include "../game/collision/cell_samples.asm"
.include "../system/nmi_tasks.asm"
.include "../game/objects/update_dispatch.asm"
.include "../game/objects/player_span_overlap.asm"
.include "../game/objects/pushable_update.asm"
.include "../game/objects/lift_update.asm"
.include "../game/objects/flying_block_update.asm"
.include "../game/objects/walking_enemy_physics.asm"
.include "../game/objects/knight_update.asm"
.include "../game/objects/fairy_fighter_update.asm"
.include "../game/objects/flame_and_movement_helpers.asm"
.include "../game/objects/witch_summoning.asm"
.include "../game/objects/knight_arrow_update.asm"
.include "../game/objects/transient_lifecycle.asm"
.include "../game/collision/object_filters.asm"
.include "../game/collision/point_sample.asm"
.include "../game/collision/room_sample.asm"
.include "../game/collision/unreferenced_runtime_only_sample.asm"
.include "../game/collision/runtime_overlap.asm"
.include "../data/unreferenced_nmi_task_index_bytes.asm"
.include "../game/new_game.asm"
.include "../rendering/room_palette.asm"
.include "../game/rooms/load_room.asm"
.include "../game/rooms/runtime_reset.asm"
.include "../game/rooms/cell_animation.asm"
.include "../rendering/status_format.asm"
.include "../data/unreferenced_bit_index_helper.asm"
.include "../game/rooms/cell_coordinates.asm"
.include "../game/rooms/mutable_cell_actions.asm"
.include "../game/rooms/mutable_cell_lookup.asm"
.include "../game/collision/cell_pair_index.asm"
.include "../game/rooms/mutable_cell_predicates.asm"
.include "../game/rooms/mutable_cell_restore.asm"
.include "../game/rooms/navigation.asm"
.include "../game/player/hazard_state.asm"
.include "../game/objects/player_proximity.asm"
.include "pause.asm"
.include "../game/collision/tables.asm"
.include "../game/rooms/room_metadata.asm"
.include "../rendering/frame_sprites.asm"
.include "../rendering/object_sprite_selectors.asm"
.include "../rendering/object_metasprites.asm"
.include "../rendering/metasprite_data.asm"
.include "../rendering/room_screen.asm"
.include "../input/demo_playback.asm"
.include "../data/title_demo_input.asm"
.include "../audio/track_selection.asm"
.include "../audio/track_table.asm"
.include "../audio/stream_engine.asm"
.include "../data/unreferenced_lowercase_hex_digit_decode_bytes.asm"
.include "../audio/channel_configuration.asm"
.include "../audio/note_semitone_offsets.asm"
.include "../audio/note_length_table.asm"
.include "../audio/apu_period_table.asm"
.include "../audio/music_mml_data.asm"
.include "../audio/sound_effect_starters.asm"
.include "../audio/sound_effect_update.asm"
.include "../audio/sound_effect_tables.asm"
.include "../rendering/horizontal_scroll.asm"
.include "../math/divide_unsigned16.asm"
.include "../rendering/palette_upload.asm"
.include "../rendering/screen_palette_data.asm"
.include "../rendering/room_palette_data.asm"
.include "../system/nmi.asm"
.include "../rendering/oam_dma.asm"
.include "../rendering/status_upload.asm"
.include "../rendering/room_rows_00_04.asm"
.include "../rendering/room_rows_05_09.asm"
.include "../rendering/room_rows_10_14.asm"
.include "../rendering/room_rows_15_19.asm"
.include "../rendering/room_attribute_upload.asm"
.include "../game/rooms/decoder.asm"
.include "../rendering/room_attributes.asm"
.include "../ui/castle_map.asm"
.include "../game/rooms/finalize_room.asm"
.include "../game/objects/room_loader.asm"
.include "../game/rooms/state_orchestration.asm"
.include "../game/rooms/persistent_state_apply.asm"
.include "../game/objects/stream_seek.asm"
.include "../game/rooms/mutable_cell_state_apply.asm"
.include "../game/rooms/persistent_state_load.asm"
.include "../game/objects/room_data.asm"
.include "../ui/title_screen.asm"
.include "../rendering/chr_nametable_copy.asm"
.include "../ui/sub_command_input.asm"
.include "../ui/sub_command_menu.asm"
.include "../data/sub_command_text.asm"
.include "../ui/sub_command_room_actions.asm"
.include "../game/save_load.asm"
.include "../game/rooms/persistent_state_save.asm"
.include "../game/end_sequences.asm"
.include "../data/prg_tail_padding.asm"
.include "../rendering/room_cell_tile_tables.asm"
.include "../system/interrupt_vectors.asm"
