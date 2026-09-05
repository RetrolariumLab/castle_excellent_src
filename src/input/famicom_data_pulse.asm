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
.include "../preservation/prg_82ce_8f0f.asm"
.include "../game/objects/runtime_record_offsets.asm"
.include "../preservation/prg_8f29_949b.asm"
.include "../rendering/room_cell_updates.asm"
.include "../game/x_coordinates.asm"
.include "../game/rooms/finish_transition.asm"
.include "../game/collision/cell_samples.asm"
.include "../system/nmi_tasks.asm"
.include "../game/objects/update_dispatch.asm"
.include "../preservation/prg_9613_a2b0.asm"
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
.include "../preservation/prg_b7fd_c55c.asm"
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
.include "../preservation/prg_f8fc_fbfd.asm"
.include "../game/save_load.asm"
.include "../game/rooms/persistent_state_save.asm"
.include "../preservation/prg_fe31_ffff.asm"
