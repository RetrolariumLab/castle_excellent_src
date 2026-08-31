; Preservation PRG before controller input
; CPU range $8000-$80FE
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

.segment "PRG"

Func_8000:
    LDX #$91

Label_8002:
    DEX
    BNE Label_8002
    RTS

Func_8006:
    LDX #$47

Label_8008:
    DEX
    BNE Label_8008
    RTS

Func_800C:
    LDY #$00

Label_800E:
    INY
    BEQ Label_801F
    LDA JOYPAD1
    AND #$02
    EOR $30
    BEQ Label_800E
    EOR $30
    STA $30
    RTS

Label_801F:
    DEY
    RTS

Func_8021:
    LDX #$28
    LDY #$00

Label_8025:
    LDA JOYPAD1
    AND #$02
    EOR $30
    BEQ Label_8037
    EOR $30
    STA $30
    INY
    DEX
    BNE Label_8025
    RTS

Label_8037:
    LDA $30
    LDA $30
    LDA $30
    DEX
    BNE Label_8025
    RTS

Func_8041:
    LDA #$00
    STA JOYPAD1
    JSR Func_8000
    LDA #$01
    STA JOYPAD1
    JSR Func_8000
    LDA #$00
    STA JOYPAD1
    RTS

Func_8057:
    BCC Func_8041

Func_8059:
    LDA #$00
    STA JOYPAD1
    JSR Func_8006
    LDA #$01
    STA JOYPAD1
    JSR Func_8006
    LDA #$00
    STA JOYPAD1
    JSR Func_8006
    LDA #$01
    STA JOYPAD1
    JSR Func_8006
    LDA #$00
    STA JOYPAD1
    RTS

Func_807F:
    LDA #$04
    STA JOYPAD1
    LDX #$00
    STX $30

Label_8088:
    JSR Func_800C
    CPY #$12
    BCC Func_807F
    CPY #$1A
    BCS Func_807F
    INX
    BNE Label_8088
    RTS

Func_8097:
    LDA #$21
    STA $2F
    LDY #$00

Label_809D:
    JSR Func_8059
    DEY
    BNE Label_809D
    DEC $2F
    BNE Label_809D
    CLC
    RTS

Func_80A9:
    JSR Func_8041
    LDY #$08

Label_80AE:
    ASL $17
    JSR Func_8057
    DEY
    BNE Label_80AE
    JSR Func_8059
    JMP Func_8059

Func_80BC:
    LDA JOYPAD1
    AND #$02
    BEQ Func_80BC

Label_80C3:
    LDA JOYPAD1
    AND #$02
    BNE Label_80C3
    STA $30
    JSR Func_800C

Label_80CF:
    STY $2D
    JSR Func_800C
    TYA
    CLC
    ADC $2D
    BCS Label_80CF
    CMP #$50
    BCC Label_80CF
    LDA #$08
    STA $2E

Label_80E2:
    JSR Func_8021
    CPY #$04
    BCS Label_80FE
    CPY #$02
    ROL $17
    TYA
    LSR A
    BCS Label_80F4
    JSR Func_800C

Label_80F4:
    JSR Func_800C
    DEC $2E
    BNE Label_80E2
    LDA $2D
    CLC

Label_80FE:
    RTS

.include "../input/controllers.asm"
.include "../system/ppu.asm"
.include "prg_8180_8224.asm"
.include "../system/startup.asm"
.include "prg_82ce_8f0f.asm"
.include "../game/objects/runtime_record_offsets.asm"
.include "prg_8f29_9577.asm"
.include "../system/nmi_tasks.asm"
.include "prg_9583_a35b.asm"
.include "../game/rooms/load_room.asm"
.include "prg_a3ac_a6d7.asm"
.include "../game/rooms/mutable_cell_predicates.asm"
.include "prg_a70a_ab49.asm"
.include "../game/rooms/room_metadata.asm"
.include "prg_ac13_b64b.asm"
.include "../rendering/room_screen.asm"
.include "prg_b7fd_c55c.asm"
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
.include "prg_f8fc_fdc4.asm"
.include "../game/rooms/persistent_state_save.asm"
.include "prg_fe31_ffff.asm"
