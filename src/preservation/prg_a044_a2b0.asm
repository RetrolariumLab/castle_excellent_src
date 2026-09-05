; Preservation collision samplers before runtime overlap
; CPU range $A1D4-$A246
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

    .byte $C0, $A0, $90, $06, $18, $A9, $53, $A0, $00, $60, $85, $28, $86, $27, $84, $1B
    .byte $A0, $00, $84, $1D

Label_A1E8:
    LDY $1D
    LDX RuntimeObjectOffsetByCount,Y
    LDA RuntimeObjectRecords,X
    BEQ Label_A239
    CMP #$A8
    BCS Label_A239
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A239
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS Label_A239
    LDA $27
    STA $2B
    .byte $A5, $28
    STA $2C
    LDA $2B
    SEC
    SBC RuntimeObjectXLo,X
    STA $2B
    LDA $2C
    SBC RuntimeObjectXHi,X
    STA $2C
    BCC Label_A239
    LDA $2B
    SEC
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA $2B
    LDA $2C
    SBC #$00
    STA $2C
    BCS Label_A239
    STX $42
    LDA RuntimeObjectRecords,X
    JSR GetRuntimeObjectSolidFlag
    CLC
    BEQ Label_A234
    SEC

Label_A234:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

Label_A239:
    INC $1D
    LDA $1D
    CMP #$18
    BCC Label_A1E8
    CLC
    LDA #$53
    LDY #$00
    RTS
