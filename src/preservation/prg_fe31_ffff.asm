; Preservation PRG after persistent-state saving
; CPU range $FE31-$FFFF
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_FE31:
    JSR Func_FED5
    JSR ClearRoomNametablesAndSprites
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$EC
    STA PPU_ADDR
    LDA #$FE
    STA $22
    LDA #$84
    STA $21
    JSR ShowBackgroundOnlyMessage
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JSR LoadAudioTrackSet2
    LDA #$0A
    STA PPU_MASK
    SEI
    LDA #$30
    STA PPU_CTRL

Label_FE69:
    LDA PPU_STATUS
    BPL Label_FE69
    JSR UpdateAudioStreams
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE Label_FE69
    LDX #$3C

Label_FE79:
    LDA PPU_STATUS
    BPL Label_FE79
    DEX
    BNE Label_FE79
    JMP Reset
    .byte $77, $71, $7D, $75, $FF, $7F, $86, $75, $82, $00, $20, $D5, $FE, $A9, $14, $20
    .byte $73, $F9, $A9, $C4, $85, $22, $A9, $FD, $85, $21, $20, $CD
    CPY $A0
    BRK
    .byte $20, $75, $81, $20, $58, $81, $20, $06, $B9, $20, $18, $B9, $20, $85, $B8, $AD
    .byte $02, $20, $10, $FB, $20, $6A, $81, $A9, $0A, $8D, $01, $20, $78, $A9, $30, $8D
    .byte $00, $20, $AD, $02, $20, $10, $FB, $20, $23, $B9, $A5, $DB, $05, $DC, $D0, $F2
    .byte $F0, $FE

Func_FED5:
    LDA $0B
    CMP HighScoreLo
    LDA $0C
    SBC HighScoreHi
    BCC Label_FEE7
    LDA $0B
    STA HighScoreLo
    LDA $0C
    STA HighScoreHi

Label_FEE7:
    RTS
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

LeftTileByCell:
    .byte $02, $02, $05, $05, $05, $05, $FF, $02, $00, $02, $06, $FF, $02, $07, $25, $27
    .byte $27, $29, $14, $17, $17, $FF, $18, $1A, $02, $5B, $5D, $02, $53, $55, $02, $57
    .byte $59, $02, $57, $59, $02, $5B, $5D, $02, $02, $53, $55, $02, $02, $02, $02, $0A
    .byte $0C, $0E, $0F, $10, $11, $2B, $2F, $49, $32, $4D, $4F, $2C, $4B, $4D, $4F, $2C
    .byte $4B, $3E, $3F, $3F, $41, $1B, $21, $1D, $1F, $FF, $FF, $FF, $12, $FF, $FF, $FF
    .byte $24, $FF, $43, $FF, $FF, $FF, $2B, $2F, $49, $32, $4D, $4F, $2C, $4B, $4D, $4F
    .byte $2C, $4B, $18, $18

RightTileByCell:
    .byte $02, $02, $05, $05, $05, $05, $02, $FF, $01, $02, $02, $06, $07, $FF, $26, $28
    .byte $28, $2A, $15, $17, $19, $16, $18, $FF, $02, $5C, $5E, $02, $54, $56, $02, $58
    .byte $5A, $02, $58, $5A, $02, $5C, $5E, $02, $02, $54, $56, $02, $02, $02, $02, $0B
    .byte $0D, $0E, $0F, $10, $11, $4C, $4E, $2D, $30, $2E, $31, $4A, $33, $4C, $4E, $2D
    .byte $30, $3F, $40, $3F, $42, $1C, $22, $1E, $20, $FF, $FF, $FF, $13, $FF, $FF, $23
    .byte $FF, $FF, $44, $FF, $FF, $FF, $4C, $4E, $2D, $30, $2E, $31, $4A, $33, $4C, $4E
    .byte $2D, $30, $18, $18, $FF, $FF

NmiVector:
    .addr Nmi

ResetVector:
    .addr Reset

IrqVector:
    .addr Irq
