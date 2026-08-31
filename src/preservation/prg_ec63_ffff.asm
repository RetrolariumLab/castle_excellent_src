; Preservation PRG after room object loading
; CPU range $EC63-$FFFF
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_EC63:
    JSR LoadRoomObjects
    JSR Func_FDC5
    LDX #$08

Label_EC6B:
    LDA a:$0712,X
    STA a:$072D,X
    LDA a:$071B,X
    STA a:$0724,X
    DEX
    BPL Label_EC6B
    LDX #$0D

Label_EC7C:
    LDA $05,X
    STA a:$0754,X
    LDA a:$0736,X
    STA a:$0745,X
    DEX
    BPL Label_EC7C

Func_EC8A:
    LDX CurrentRoomIndex
    CPX a:$072D
    BNE Label_EC9A
    STX a:$0712
    JSR Func_EE56
    JMP Label_EC9D

Label_EC9A:
    JSR Func_EE8C

Label_EC9D:
    LDA CurrentRoomIndex
    STA a:$0712
    LDX #$08

Label_ECA4:
    LDA a:$0712,X
    STA a:$071B,X
    DEX
    BPL Label_ECA4
    LDX #$0E

Label_ECAF:
    LDA $05,X
    STA a:$0736,X
    DEX
    BPL Label_ECAF

Func_ECB7:
    LDX #$00

Label_ECB9:
    LSR $18
    ROR $17
    ROR $16
    BCC Label_ECCF
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA $4E,X
    STA $4F,X

Label_ECCF:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_ECB9
    LDX #$01
    STX $1E

Label_ECDC:
    LDX $1E
    LSR $1D
    ROR $1C
    ROR $1B
    ROR $1A
    ROR $19
    BCC Label_ECED
    JSR Func_EDEF

Label_ECED:
    INC $1E
    LDX $1E
    CPX #$28
    BCC Label_ECDC
    LDX CurrentRoomIndex
    LDA a:$AB49,X
    TAX
    LDA a:$8F10,X
    STA $16
    LDA #$04
    STA $22
    LDA #$00
    STA $21

Label_ED08:
    LDY #$00
    LDA ($21),Y
    CMP #$4B
    BNE Label_ED1C
    LDA #$53
    STA ($21),Y
    LDA #$A1
    JSR Func_ED6D
    JMP Label_ED5C

Label_ED1C:
    CMP #$4D
    BNE Label_ED2C
    LDA #$53
    STA ($21),Y
    LDA #$A2
    JSR Func_ED6D
    JMP Label_ED5C

Label_ED2C:
    CMP #$51
    BNE Label_ED3C
    LDA #$53
    STA ($21),Y
    LDA #$A3
    JSR Func_ED6D
    JMP Label_ED5C

Label_ED3C:
    CMP #$49
    BNE Label_ED4C
    LDA #$53
    STA ($21),Y
    LDA #$A4
    JSR Func_ED6D
    JMP Label_ED5C

Label_ED4C:
    CMP #$4A
    BNE Label_ED5C
    LDA #$53
    STA ($21),Y
    LDA #$A5
    JSR Func_ED6D
    JMP Label_ED5C

Label_ED5C:
    INC $21
    BNE Label_ED62
    INC $22

Label_ED62:
    LDA $21
    CMP #$90
    LDA $22
    SBC #$05
    BCC Label_ED08
    RTS

Func_ED6D:
    STA $17
    LDA $21
    STA $23
    LDA $22
    SEC
    SBC #$04
    STA $24
    LDA #$00
    STA $18

Label_ED7E:
    LDA $23
    CMP #$14
    LDA $24
    SBC #$00
    BCC Label_ED9A
    LDA $23
    SEC
    SBC #$14
    STA $23
    LDA $24
    SBC #$00
    STA $24
    INC $18
    JMP Label_ED7E

Label_ED9A:
    ASL $18
    ASL $18
    ASL $18
    ASL $23
    ROL $24
    ASL $23
    ROL $24
    ASL $23
    ROL $24
    ASL $23
    ROL $24
    LDX $16
    LDA $23
    STA RuntimeObjectXLo,X
    LDA $24
    STA RuntimeObjectXHi,X
    LDA $18
    STA RuntimeObjectY,X
    LDA $17
    STA RuntimeObjectRecords,X
    CMP #$A3
    BNE Label_EDCA
    LDA #$FF
    STA $4E,X

Label_EDCA:
    LDA $16
    CLC
    ADC #$06
    STA $16
    RTS

SeekRoomObjectStream:
    LDA #$6B
    STA $21
    LDA #$EF
    STA $22
    LDY #$00
    INX

Label_EDDD:
    DEX
    BEQ Label_EDEE

Label_EDE0:
    LDA ($21),Y
    INC $21
    BNE Label_EDE8
    INC $22

Label_EDE8:
    CMP #$FF
    BNE Label_EDE0
    BEQ Label_EDDD

Label_EDEE:
    RTS

Func_EDEF:
    LDA #$04
    STA $2A
    LDA #$00
    STA $29

Label_EDF7:
    LDY #$00
    LDA ($29),Y
    CMP #$54
    BEQ Label_EE04
    JSR Func_A6D8
    BNE Label_EE45

Label_EE04:
    DEX
    BNE Label_EE45
    LDA $29
    BNE Label_EE0D
    DEC $2A

Label_EE0D:
    DEC $29
    LDY #$00
    LDA ($29),Y
    CMP #$16
    BEQ Label_EE1F
    LDY #$02
    LDA ($29),Y
    CMP #$16
    BNE Label_EE32

Label_EE1F:
    INC $29
    BNE Label_EE25
    INC $2A

Label_EE25:
    LDY #$00
    LDA #$62
    STA ($29),Y
    LDY #$14
    LDA #$63
    STA ($29),Y
    RTS

Label_EE32:
    INC $29
    BNE Label_EE38
    INC $2A

Label_EE38:
    LDY #$00
    LDA #$54
    STA ($29),Y
    LDA #$55
    LDY #$14
    STA ($29),Y
    RTS

Label_EE45:
    INC $29
    BNE Label_EE4B
    INC $2A

Label_EE4B:
    LDA $29
    CMP #$90
    LDA $2A
    SBC #$05
    BCC Label_EDF7
    RTS

Func_EE56:
    LDX #$03

Label_EE58:
    LDA a:$072D,X
    STA a:$0712,X
    STA $15,X
    DEX
    BNE Label_EE58
    LDX #$04

Label_EE65:
    LDA a:$0731,X
    STA a:$0716,X
    STA $19,X
    DEX
    BPL Label_EE65
    RTS

Func_EE71:
    LDX #$03

Label_EE73:
    LDA a:$0724,X
    STA a:$0712,X
    STA $15,X
    DEX
    BNE Label_EE73
    LDX #$04

Label_EE80:
    LDA a:$0728,X
    STA a:$0716,X
    STA $19,X
    DEX
    BPL Label_EE80
    RTS

Func_EE8C:
    LDA #$00
    LDX #$07

Label_EE90:
    STA $16,X
    DEX
    BPL Label_EE90
    LDX CurrentRoomIndex
    LDA RoomStateOffsetTable,X
    SEC
    SBC Label_EF05,X
    TAY
    LDA Label_EF05,X
    TAX
    LDA a:$0608,X
    STA $16
    STA a:$0713
    DEY
    BEQ Label_EEC1
    LDA a:$0609,X
    STA $17
    STA a:$0714
    DEY
    BEQ Label_EEC1
    LDA a:$060A,X
    STA $18
    STA a:$0715

Label_EEC1:
    LDX CurrentRoomIndex
    LDA a:$ABAE,X
    SEC
    SBC a:$ABAD,X
    TAY
    BEQ Label_EF05
    LDA a:$ABAD,X
    TAX
    LDA a:$0590,X
    STA $19
    STA a:$0716
    DEY
    BEQ Label_EF05
    LDA a:$0591,X
    STA $1A
    STA a:$0717
    DEY
    BEQ Label_EF05
    LDA a:$0592,X
    STA $1B
    STA a:$0718
    DEY
    BEQ Label_EF05
    LDA a:$0593,X
    STA $1C
    STA a:$0719
    DEY
    BEQ Label_EF05
    LDA a:$0594,X
    STA $1D
    STA a:$071A

Label_EF05:
    RTS

RoomStateOffsetTable:
    .byte $00, $01, $02, $03, $05, $06, $09, $0A, $0B, $0D, $0F, $10, $11, $12, $14, $15
    .byte $17, $18, $19, $1A, $1C, $1D, $1E, $1F, $20, $21, $24, $25, $26, $27, $28, $2A
    .byte $2C, $2D, $2F, $30, $31, $32, $33, $35, $36, $37, $3A, $3B, $3C, $3D, $3E, $40
    .byte $41, $42, $44, $46, $48, $49, $4A, $4B, $4C, $4E, $4F, $50, $51, $52, $54, $55
    .byte $57, $58, $5A, $5C, $5E, $5F, $60, $62, $63, $66, $67, $68, $6A, $6C, $6E, $70
    .byte $71, $72, $74, $75, $77, $78, $79, $7A, $7B, $7C, $7E, $80, $81, $82, $84, $86
    .byte $87, $88, $8A, $8C, $8D

RoomObjectStream:
    .byte $35, $0A, $0E, $35, $0B, $0E, $35, $0B, $10, $34, $0F, $10, $34, $0F, $0E, $34
    .byte $10, $10, $35, $08, $0A, $34, $08, $0C, $FF, $3C, $02, $05, $30, $08, $08, $2C
    .byte $09, $09, $2C, $0E, $09, $14, $05, $09, $30, $11, $0E, $FF, $2C, $0A, $0A, $3A
    .byte $10, $01, $3A, $11, $01, $FF, $2D, $05, $02, $2D, $07, $02, $2D, $09, $02, $2D
    .byte $0B, $03, $2D, $0E, $03, $2D, $10, $03, $2A, $05, $06, $2A, $0C, $07, $2A, $05
    .byte $0B, $2A, $08, $0B, $2F, $01, $02, $2F, $03, $02, $2F, $0D, $00, $2F, $0A, $0B
    .byte $2B, $0A, $0E, $FF, $2C, $0D, $04, $2C, $06, $06, $FF, $2C, $0C, $10, $35, $09
    .byte $01, $34, $0A, $01, $33, $0B, $01, $33, $0C, $01, $35, $09, $05, $34, $0A, $05
    .byte $34, $0B, $05, $33, $0C, $05, $35, $09, $0A, $35, $0A, $0A, $34, $0B, $0A, $33
    .byte $0C, $0A, $35, $08, $0F, $35, $09, $0F, $34, $0A, $0F, $34, $0B, $0F, $FF, $32
    .byte $01, $08, $32, $02, $08, $35, $10, $0E, $35, $11, $0E, $35, $12, $0E, $FF, $2A
    .byte $11, $11, $2C, $03, $0B, $2C, $10, $0B, $15, $10, $09, $13, $03, $09, $10, $09
    .byte $0A, $FF, $24, $0F, $11, $14, $09, $04, $3A, $0F, $02, $3A, $0D, $04, $31, $06
    .byte $0A, $30, $04, $0A, $31, $02, $0A, $38, $10, $0B, $38, $10, $07, $38, $10, $0F
    .byte $2B, $0D, $09, $FF, $13, $09, $03, $15, $0F, $03, $12, $08, $09, $30, $08, $01
    .byte $33, $06, $01, $32, $0F, $01, $34, $11, $0C, $2F, $11, $11, $39, $0B, $0D, $39
    .byte $0A, $0D, $38, $05, $0D, $38, $04, $0D, $FF, $35, $0B, $0E, $35, $0C, $0F, $2A
    .byte $08, $07, $FF, $37, $01, $08, $3A, $0F, $0A, $3A, $0E, $0A, $FF, $35, $07, $0A
    .byte $34, $08, $0A, $39, $0A, $0E, $39, $0A, $10, $3C, $05, $0E, $37, $0A, $0A, $FF
    .byte $2A, $0F, $02, $2A, $11, $03, $2A, $0F, $04, $2A, $11, $08, $2A, $0F, $0F, $2A
    .byte $11, $11, $2A, $0F, $11, $2A, $0A, $08, $2B, $0A, $11, $33, $07, $09, $31, $04
    .byte $02, $31, $03, $02, $38, $03, $0A, $39, $02, $0A, $3A, $01, $0A, $FF, $2D, $07
    .byte $11, $18, $09, $11, $18, $10, $02, $34, $10, $05, $34, $11, $05, $FF, $32, $01
    .byte $00, $31, $02, $00, $35, $01, $02, $34, $02, $02, $1E, $05, $11, $20, $0E, $11
    .byte $1A, $09, $0C, $1A, $0A, $0C, $1A, $0A, $07, $1A, $09, $07, $FF, $38, $05, $02
    .byte $38, $0E, $02, $38, $05, $06, $38, $0E, $06, $35, $02, $04, $35, $03, $04, $33
    .byte $10, $00, $33, $11, $00, $FF, $2B, $04, $10, $2B, $05, $10, $2B, $06, $10, $2E
    .byte $0C, $06, $32, $06, $00, $31, $07, $00, $30, $08, $00, $FF, $1E, $05, $02, $18
    .byte $0A, $11, $FF, $35, $01, $00, $38, $06, $00, $38, $07, $00, $34, $11, $00, $12
    .byte $0F, $01, $12, $0B, $01, $12, $08, $03, $1A, $08, $08, $33, $06, $0C, $11, $0D
    .byte $0C, $FF, $37, $0D, $0B, $3A, $0C, $0B, $3A, $0B, $0B, $3A, $0A, $0B, $FF, $39
    .byte $03, $02, $39, $04, $02, $39, $05, $02, $FF, $11, $05, $07, $32, $11, $11, $32
    .byte $12, $11, $37, $0B, $04, $FF, $35, $0F, $0E, $34, $0F, $10, $33, $0F, $12, $14
    .byte $07, $0E, $FF, $16, $10, $0D, $1A, $10, $11, $1A, $0D, $11, $FF, $37, $02, $0C
    .byte $37, $04, $0C, $2D, $0A, $0C, $2F, $0C, $0C, $2D, $0E, $0C, $2D, $10, $0C, $3A
    .byte $02, $05, $2A, $0A, $07, $2F, $0C, $07, $2F, $0E, $07, $2A, $10, $07, $2A, $12
    .byte $07, $2A, $06, $00, $2A, $08, $00, $2F, $0A, $00, $2D, $0C, $00, $2D, $0E, $00
    .byte $2E, $10, $00, $FF, $16, $0D, $11, $18, $0E, $11, $27, $08, $09, $29, $0B, $09
    .byte $1A, $09, $0C, $1A, $0A, $0C, $FF, $33, $0D, $11, $3A, $09, $0A, $37, $01, $04
    .byte $1A, $02, $04, $2C, $0A, $0D, $3A, $0C, $0A, $38, $08, $11, $FF, $37, $0F, $0D
    .byte $12, $0B, $06, $14, $08, $01, $3A, $12, $00, $1A, $04, $09, $39, $10, $00, $38
    .byte $0E, $00, $FF, $3A, $0E, $00, $33, $05, $00, $33, $08, $00, $38, $0F, $06, $39
    .byte $10, $04, $FF, $30, $12, $01, $38, $11, $01, $38, $10, $01, $1A, $0C, $02, $2C
    .byte $08, $07, $2A, $0E, $0C, $37, $0F, $10, $2B, $0B, $11, $16, $07, $11, $FF, $2C
    .byte $11, $02, $2C, $0A, $03, $2E, $0D, $01, $2C, $0E, $07, $2C, $0D, $0D, $2C, $11
    .byte $0E, $2C, $09, $0D, $2C, $08, $11, $2C, $06, $11, $FF, $34, $01, $0F, $35, $02
    .byte $0F, $1A, $01, $0A, $24, $10, $11, $FF, $32, $12, $10, $2A, $0C, $11, $2A, $0C
    .byte $0F, $2A, $0C, $0D, $2A, $0C, $0B, $2A, $0C, $09, $24, $0E, $0B, $24, $0E, $11
    .byte $39, $05, $06, $39, $06, $06, $32, $05, $0D, $35, $05, $0F, $FF, $24, $0A, $10
    .byte $2C, $0A, $08, $2E, $0A, $05, $34, $0A, $0B, $FF, $2C, $0F, $01, $2C, $0C, $01
    .byte $2B, $09, $01, $2B, $06, $01, $2F, $03, $01, $32, $12, $0D, $30, $0A, $0D, $32
    .byte $04, $0D, $FF, $2A, $03, $03, $2A, $03, $05, $2A, $03, $07, $2A, $05, $07, $2A
    .byte $06, $01, $2A, $09, $01, $2A, $10, $01, $1A, $07, $07, $FF, $2B, $09, $0C, $2E
    .byte $0B, $05, $FF, $30, $07, $0C, $30, $05, $0C, $2B, $12, $0D, $2B, $12, $0B, $1A
    .byte $02, $06, $14, $08, $11, $31, $02, $00, $34, $03, $00, $1A, $07, $06, $FF, $3A
    .byte $0A, $01, $14, $06, $05, $32, $06, $08, $3A, $02, $01, $3A, $08, $11, $37, $09
    .byte $11, $3A, $0A, $11, $2C, $0F, $0C, $FF, $34, $06, $07, $1E, $0D, $11, $22, $07
    .byte $10, $1E, $05, $03, $35, $04, $01, $2C, $0D, $09, $22, $08, $0A, $22, $09, $0D
    .byte $FF, $34, $12, $0C, $34, $10, $0B, $33, $10, $10, $33, $0E, $0F, $33, $0A, $03
    .byte $34, $09, $00, $33, $08, $09, $32, $06, $09, $33, $04, $09, $35, $02, $00, $2C
    .byte $03, $00, $2C, $0A, $00, $2C, $09, $06, $2C, $08, $0F, $2C, $0F, $00, $2C, $10
    .byte $03, $2C, $0F, $0B, $FF, $38, $08, $0F, $30, $0C, $0F, $30, $0D, $0F, $35, $07
    .byte $0F, $1E, $04, $11, $27, $02, $01, $27, $02, $06, $FF, $3A, $05, $01, $3A, $03
    .byte $01, $3A, $01, $01, $2E, $0B, $07, $2C, $11, $11, $18, $0A, $11, $16, $09, $11
    .byte $34, $06, $11, $FF, $39, $12, $01, $38, $0F, $01, $38, $09, $01, $39, $06, $01
    .byte $37, $06, $0D, $35, $04, $0D, $35, $01, $0D, $FF, $39, $11, $01, $37, $0A, $01
    .byte $37, $09, $01, $39, $02, $01, $35, $12, $0E, $33, $0F, $0E, $FF, $2B, $04, $0B
    .byte $2B, $05, $0B, $2B, $04, $0D, $2B, $05, $0D, $2B, $04, $0F, $2B, $05, $0F, $2B
    .byte $0A, $04, $2B, $0D, $01, $34, $01, $0C, $FF, $33, $12, $09, $16, $03, $11, $18
    .byte $06, $11, $1E, $03, $0C, $20, $10, $0C, $FF, $37, $12, $04, $3A, $12, $06, $3A
    .byte $12, $08, $3A, $12, $0A, $2D, $08, $03, $2D, $03, $0B, $2E, $04, $02, $2D, $08
    .byte $0A, $FF, $2C, $0A, $0F, $2C, $0A, $0D, $2C, $0A, $0B, $2C, $0A, $09, $2C, $0A
    .byte $07, $2C, $0A, $05, $2C, $08, $05, $2C, $0A, $03, $2C, $08, $03, $2C, $0A, $01
    .byte $2C, $08, $01, $35, $03, $0B, $35, $04, $0B, $32, $0D, $0D, $35, $0E, $0D, $FF
    .byte $37, $02, $02, $2C, $09, $06, $2C, $07, $08, $2C, $09, $08, $2C, $05, $0B, $2C
    .byte $0B, $0B, $33, $03, $0E, $33, $05, $11, $33, $0B, $11, $FF, $37, $05, $01, $33
    .byte $08, $01, $33, $0B, $01, $16, $06, $07, $18, $0D, $07, $20, $09, $0B, $33, $05
    .byte $0E, $33, $06, $0E, $38, $0D, $0E, $38, $0E, $0E, $FF, $2A, $06, $05, $0E, $0B
    .byte $0A, $30, $0C, $0F, $FF, $37, $07, $07, $35, $07, $09, $35, $07, $0B, $2B, $05
    .byte $01, $1E, $02, $0D, $FF, $14, $08, $09, $14, $0A, $05, $14, $0C, $09, $14, $0E
    .byte $05, $14, $10, $09, $2A, $0A, $11, $FF, $32, $12, $0D, $37, $0F, $0D, $12, $01
    .byte $06, $12, $08, $06, $2D, $0B, $11, $14, $05, $0B, $FF, $31, $01, $01, $31, $02
    .byte $01, $31, $03, $01, $3A, $01, $05, $3A, $02, $05, $3A, $01, $09, $3A, $02, $09
    .byte $37, $01, $0D, $37, $07, $10, $18, $08, $11, $20, $0F, $11, $27, $0B, $06, $FF
    .byte $34, $02, $00, $34, $0D, $00, $2D, $04, $01, $2D, $0B, $01, $2B, $08, $04, $2B
    .byte $0F, $04, $FF, $39, $08, $05, $39, $0A, $05, $39, $10, $05, $39, $12, $05, $37
    .byte $06, $0D, $14, $0D, $0D, $FF, $34, $0B, $00, $39, $04, $07, $39, $01, $07, $FF
    .byte $39, $10, $07, $39, $11, $07, $38, $05, $01, $38, $06, $01, $38, $07, $01, $37
    .byte $07, $06, $37, $08, $09, $18, $0E, $0D, $FF, $35, $08, $00, $34, $0C, $00, $35
    .byte $12, $07, $35, $08, $0E, $34, $0C, $0E, $24, $0A, $0B, $20, $10, $11, $2C, $06
    .byte $11, $2C, $0E, $11, $FF, $37, $02, $07, $3A, $01, $0C, $3A, $02, $0C, $3A, $03
    .byte $0C, $3A, $04, $0C, $18, $0E, $0D, $2D, $0E, $10, $34, $0F, $10, $FF, $39, $0B
    .byte $02, $39, $08, $02, $39, $07, $05, $39, $0D, $05, $39, $0A, $05, $39, $0F, $08
    .byte $39, $0C, $08, $39, $06, $0A, $39, $0C, $0C, $33, $0A, $0A, $33, $06, $07, $32
    .byte $01, $05, $2C, $04, $0C, $32, $09, $07, $FF, $2B, $0F, $01, $2B, $09, $0C, $2B
    .byte $07, $0E, $2B, $05, $0E, $2B, $07, $11, $32, $0A, $0B, $37, $07, $07, $FF, $3A
    .byte $0B, $04, $37, $11, $04, $39, $0B, $09, $37, $11, $09, $34, $0F, $10, $33, $08
    .byte $11, $2B, $08, $09, $2B, $08, $0B, $2B, $08, $0D, $FF, $39, $0B, $05, $3A, $0B
    .byte $03, $32, $0B, $01, $35, $04, $0B, $38, $02, $10, $39, $05, $10, $38, $08, $10
    .byte $38, $0E, $10, $39, $11, $10, $FF, $3A, $02, $09, $2F, $04, $08, $39, $06, $06
    .byte $14, $08, $03, $14, $0B, $03, $37, $0D, $06, $38, $0F, $08, $27, $11, $09, $34
    .byte $10, $10, $38, $0E, $10, $33, $0C, $10, $38, $0A, $10, $39, $03, $10, $38, $01
    .byte $10, $FF, $27, $10, $05, $27, $10, $09, $34, $06, $0F, $3A, $11, $0F, $FF, $2B
    .byte $0C, $11, $2B, $06, $10, $38, $03, $01, $38, $04, $01, $FF, $3A, $05, $01, $3A
    .byte $06, $01, $39, $11, $01, $39, $12, $01, $33, $05, $06, $35, $06, $06, $36, $11
    .byte $06, $34, $05, $0A, $38, $10, $0A, $35, $03, $0F, $20, $09, $03, $18, $09, $07
    .byte $20, $09, $0C, $FF, $38, $08, $02, $38, $0A, $02, $38, $0C, $02, $35, $12, $06
    .byte $37, $12, $0A, $2B, $0A, $0C, $18, $0A, $11, $FF, $35, $02, $02, $32, $08, $01
    .byte $32, $0C, $01, $37, $10, $01, $35, $02, $06, $32, $09, $0B, $34, $01, $0D, $12
    .byte $03, $03, $2B, $06, $0A, $3A, $12, $0B, $3A, $11, $0A, $3A, $10, $09, $3A, $0F
    .byte $08, $3A, $0E, $07, $3A, $0D, $06, $3A, $0C, $05, $3A, $0B, $04, $FF, $27, $0E
    .byte $0D, $27, $0B, $0D, $37, $0B, $09, $35, $0E, $08, $2F, $0B, $06, $2B, $0E, $05
    .byte $FF, $35, $0C, $04, $2B, $0E, $0E, $2B, $10, $0E, $2B, $0D, $0F, $FF, $14, $09
    .byte $02, $39, $02, $09, $37, $01, $09, $38, $04, $0A, $38, $05, $0A, $38, $11, $0A
    .byte $39, $12, $0A, $38, $01, $0E, $32, $12, $10, $FF, $2C, $0B, $02, $34, $12, $01
    .byte $3A, $01, $06, $3A, $02, $06, $30, $01, $0B, $32, $02, $0B, $34, $11, $0A, $34
    .byte $12, $0A, $35, $01, $0F, $2B, $0F, $11, $24, $09, $05, $16, $06, $0C, $18, $09
    .byte $0C, $FF, $2B, $10, $0D, $2B, $03, $02, $2F, $0A, $0B, $37, $12, $01, $39, $11
    .byte $03, $38, $10, $04, $38, $0A, $04, $39, $09, $03, $3A, $08, $01, $FF, $33, $0F
    .byte $01, $34, $10, $01, $32, $0F, $03, $35, $01, $07, $37, $0D, $06, $39, $03, $11
    .byte $39, $04, $11, $20, $09, $11, $3C, $0C, $11, $FF, $37, $05, $02, $22, $04, $07
    .byte $37, $01, $0A, $22, $04, $0C, $3A, $01, $0F, $FF, $35, $03, $01, $2A, $06, $02
    .byte $18, $0D, $06, $2B, $0C, $0C, $2B, $07, $11, $2B, $05, $11, $FF, $34, $01, $01
    .byte $34, $02, $01, $37, $09, $02, $35, $07, $0B, $35, $12, $01, $1A, $05, $08, $1A
    .byte $0F, $08, $37, $06, $0B, $37, $05, $0B, $37, $0B, $02, $FF, $34, $11, $0E, $37
    .byte $01, $03, $2B, $0A, $01, $2B, $08, $08, $2B, $0A, $0D, $2B, $0D, $0D, $35, $06
    .byte $09, $FF, $30, $01, $02, $16, $06, $03, $37, $09, $01, $33, $12, $02, $34, $01
    .byte $06, $1E, $06, $08, $2D, $09, $08, $34, $04, $11, $32, $09, $11, $FF, $32, $12
    .byte $04, $32, $01, $04, $11, $01, $0B, $1A, $02, $01, $37, $01, $01, $2F, $11, $01
    .byte $FF, $2B, $08, $11, $32, $12, $0E, $3A, $06, $02, $3A, $04, $02, $3A, $03, $02
    .byte $3A, $01, $02, $37, $08, $0D, $FF, $32, $03, $0E, $2B, $02, $06, $2B, $04, $06
    .byte $14, $12, $0E, $37, $12, $0C, $37, $11, $0C, $37, $10, $0C, $FF, $2D, $0F, $11
    .byte $1A, $10, $0C, $37, $12, $0C, $38, $11, $0C, $3A, $11, $0A, $3A, $10, $0A, $3A
    .byte $0F, $0A, $39, $01, $03, $FF, $2C, $09, $03, $2C, $07, $03, $2C, $0C, $02, $11
    .byte $0C, $05, $2B, $11, $04, $2B, $11, $08, $30, $11, $0E, $0E, $0A, $08, $FF, $37
    .byte $01, $01, $2D, $06, $07, $37, $01, $0F, $3A, $0F, $01, $3A, $12, $01, $3A, $0F
    .byte $03, $3A, $12, $03, $39, $0F, $08, $39, $12, $08, $39, $0F, $0A, $39, $12, $0A
    .byte $FF, $30, $01, $0F, $3A, $02, $0E, $3A, $02, $0C, $3A, $01, $0C, $34, $06, $05
    .byte $2C, $08, $07, $2C, $0D, $07, $2C, $11, $07, $11, $12, $05, $FF, $38, $07, $03
    .byte $38, $0A, $03, $38, $0E, $02, $39, $0D, $05, $39, $0F, $05, $33, $04, $06, $33
    .byte $0E, $08, $FF, $2A, $0E, $02, $2A, $08, $06, $11, $01, $05, $FF, $35, $01, $01
    .byte $39, $01, $05, $39, $02, $05, $39, $03, $05, $3A, $01, $09, $3A, $02, $09, $3A
    .byte $03, $09, $37, $01, $0D, $35, $02, $0D, $37, $03, $0D, $2B, $0F, $0C, $12, $06
    .byte $06, $16, $0C, $11, $18, $0F, $11, $FF, $35, $01, $01, $35, $12, $01, $34, $12
    .byte $05, $33, $01, $05, $3A, $01, $09, $37, $02, $09, $37, $11, $09, $30, $12, $09
    .byte $30, $12, $0B, $11, $0B, $09, $1A, $09, $0E, $1A, $0A, $0E, $FF, $3A, $09, $01
    .byte $33, $01, $05, $35, $05, $05, $1E, $05, $08, $16, $07, $11, $18, $0A, $11, $FF
    .byte $2A, $02, $0C, $37, $0B, $01, $18, $0F, $02, $2C, $11, $05, $37, $11, $08, $12
    .byte $0E, $11, $FF, $2E, $07, $02, $2C, $01, $08, $2C, $03, $08, $2C, $05, $08, $2C
    .byte $0A, $0C, $35, $0B, $0F, $35, $0C, $0F, $34, $0D, $0F, $2C, $10, $0F, $FF, $2A
    .byte $01, $03, $33, $01, $07, $32, $01, $0A, $35, $02, $07, $11, $05, $07, $35, $0A
    .byte $07, $32, $12, $0A, $20, $0F, $03, $3A, $12, $01, $3A, $0E, $01, $3A, $07, $01
    .byte $3A, $0B, $01, $FF, $33, $08, $03, $32, $09, $05, $34, $0B, $03, $35, $0B, $01
    .byte $FF

Func_F8FC:
    LDA #$18
    JSR Func_F973
    LDA #$C5
    STA $22
    LDA #$0D
    STA $21
    JSR Func_C4CD
    LDY #$01
    JSR SelectChrBank
    JSR ResetPpuScroll
    LDX #$00
    STX $21
    STX $22
    DEX
    STX a:$07C7
    JSR Func_B7FD
    JSR LoadAudioTrackSet5
    SEI

Label_F925:
    LDA PPU_STATUS
    BPL Label_F925
    LDA #$0A
    STA PPU_MASK
    LDA #$38
    STA PPU_CTRL
    JSR Func_810B
    EOR #$FF
    STA a:$0777

Label_F93C:
    LDA PPU_STATUS
    BPL Label_F93C
    JSR UpdateAudioStreams
    INC $21
    BNE Label_F94A
    INC $22

Label_F94A:
    LDA $22
    CMP #$03
    BCS Label_F968
    JSR Func_810B
    TAX
    AND a:$0777
    AND #$08
    PHA
    TXA
    EOR #$FF
    STA a:$0777
    PLA
    BEQ Label_F93C
    LDA #$00
    STA a:$07C7

Label_F968:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$00
    JMP SelectChrBank

Func_F973:
    STA $16
    LDA #$20
    STA $17
    JSR Func_B64C
    LDY #$03
    JSR SelectChrBank
    LDX #$00

Label_F983:
    LDA PPU_STATUS
    LDA $16
    STA PPU_ADDR
    STX PPU_ADDR
    LDA PPU_DATA
    LDY PPU_DATA
    LDA $17
    STA PPU_ADDR
    STX PPU_ADDR
    STY PPU_DATA
    INX
    BNE Label_F983
    INC $16
    INC $17
    LDA $17
    CMP #$24
    BCC Label_F983
    RTS

Func_F9AD:
    LDA a:$07CC
    BEQ Label_F9B3
    RTS

Label_F9B3:
    LDA a:$07C7
    BEQ Label_F9B9
    RTS

Label_F9B9:
    LDA a:$0778
    EOR #$FF
    AND Controller2Buttons
    AND #$03
    BNE Label_F9CC
    LDA Controller2Buttons
    STA a:$0778
    RTS

Label_F9CC:
    JSR Func_B64C
    LDA #$00
    STA JOYPAD1
    STA APU_STATUS

Label_F9D7:
    LDA PPU_STATUS
    BPL Label_F9D7
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0A
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$77
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$8D
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CD
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$93
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$83
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$88
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$98
    STA $21
    JSR Func_B76F
    LDA #$00
    STA $1D
    LDA #$FF
    STA $1C

Label_FA74:
    LDA PPU_STATUS
    BPL Label_FA74
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    LDX #$FF
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CB
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$00
    STA $22
    LDA $1D
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ROL $22
    CLC
    ADC #$8B
    STA $21
    LDA #$21
    ADC $22
    STA PPU_ADDR
    LDA $21
    STA PPU_ADDR
    LDA #$6B
    STA PPU_DATA
    JSR ResetPpuScroll

Label_FAF5:
    LDA PPU_STATUS
    BPL Label_FAF5
    LDA #$08
    STA PPU_MASK
    JSR DisableNmi
    JSR Func_810B
    PHA
    AND $1C
    TAY
    PLA
    EOR #$FF
    STA $1C
    TYA
    AND #$24
    BEQ Label_FB27
    INC $1D
    LDA $1D
    CMP #$05
    BCS Label_FB1E
    JMP Label_FA74

Label_FB1E:
    LDA #$00
    STA $1D
    BNE Label_FB27
    JMP Label_FA74

Label_FB27:
    TYA
    AND #$08
    BEQ Label_FB32
    LDA #$00
    STA $1F
    BEQ Label_FB62

Label_FB32:
    TYA
    AND #$01
    BEQ Label_FB3D
    LDA #$FF
    STA $1F
    BNE Label_FB62

Label_FB3D:
    TYA
    AND #$10
    BEQ Label_FB4E
    DEC $1D
    LDA $1D
    CMP #$FF
    BNE Label_FB4E
    LDA #$04
    STA $1D

Label_FB4E:
    JMP Label_FA74

Func_FB51:
    LDA #$FF
    STA a:$07C4
    STA a:$0778
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JMP FinalizeRoomLoad

Label_FB62:
    LDX $1D
    BEQ Label_FBAC
    DEX
    BEQ Label_FBD6
    DEX
    BEQ Label_FB71
    DEX
    BEQ Label_FB74
    BNE Func_FB51

Label_FB71:
    JMP Func_FD06

Label_FB74:
    JMP Label_FBFE
    .byte $83, $85, $72, $FF, $73, $7F, $7D, $7D, $71, $7E, $74, $00, $7C, $7F, $71, $74
    .byte $00, $83, $71, $86, $75, $00, $82, $75, $83, $75, $84, $00, $72, $71, $73, $7B
    .byte $00, $77, $71, $7D, $75, $00, $7C, $7F, $71, $74, $79, $7E, $77, $00, $83, $71
    .byte $86, $79, $7E, $77, $00

Label_FBAC:
    LDA $13
    BNE Label_FBB3
    JMP Label_FA74

Label_FBB3:
    JSR Func_EE8C
    LDX #$0D

Label_FBB8:
    LDA a:$0736,X
    STA $05,X
    DEX
    BPL Label_FBB8

Label_FBC0:
    LDA $10
    STA $38
    LDA $11
    STA $39
    LDA $12
    STA $3A
    DEC $13
    LDA #$00
    STA a:$07CD
    JMP Label_FD96

Label_FBD6:
    LDA $13
    BNE Label_FBDD
    JMP Label_FA74

Label_FBDD:
    LDA a:$0724
    BNE Label_FBE5
    JMP Label_FA74

Label_FBE5:
    STA CurrentRoomIndex
    JSR Func_EE71
    LDX #$0D

Label_FBEC:
    LDA a:$0745,X
    STA $05,X
    DEX
    BPL Label_FBEC
    LDA #$00
    STA a:$0724
    STA a:$072D
    BEQ Label_FBC0

Label_FBFE:
    JSR DisableNmi
    LDA $13
    BNE Label_FC08
    JMP Label_FA74

Label_FC08:
    LDA a:$071B
    BNE Label_FC10
    JMP Label_FA74

Label_FC10:
    DEC $13
    JSR Func_B64C
    LDA #$FB
    STA $22
    LDA #$A5
    STA $21
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR Func_FCEA
    JSR Func_8180
    LDA CurrentRoomIndex
    JSR Func_81C2
    LDA a:$0744
    JSR Func_81C2
    LDX #$00

Label_FC3D:
    LDA a:$0736,X
    JSR Func_81C2
    INX
    CPX #$0E
    BCC Label_FC3D
    JSR Func_FDC5
    LDA #$00
    STA a:$0724
    STA a:$072D
    LDX #$78

Label_FC55:
    LDA a:$058F,X
    JSR Func_81C2
    DEX
    BNE Label_FC55
    LDX #$96

Label_FC60:
    LDA a:$0607,X
    JSR Func_81C2
    DEX
    BNE Label_FC60
    LDX #$64

Label_FC6B:
    LDA a:$069D,X
    JSR Func_81C2
    DEX
    BNE Label_FC6B
    LDX #$08

Label_FC76:
    LDA a:$FC99,X
    JSR Func_81C2
    DEX
    BNE Label_FC76
    JMP Func_FB51
    .byte $7C, $7F, $71, $74, $FF, $75, $82, $82, $7F, $82, $00, $80, $85, $83, $78, $FF
    .byte $71, $FF, $7F, $82, $FF, $72, $00, $47, $4E, $55, $54, $55, $45, $44, $45, $42

Func_FCA2:
    JSR Func_B64C
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    LDA #$FC
    STA $22
    LDA #$82
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$4A
    STA PPU_ADDR
    LDA #$FC
    STA $22
    LDA #$8D
    STA $21
    JSR Func_FCEA

Label_FCD5:
    JSR Func_810B
    AND #$03
    BEQ Label_FCD5
    JSR Func_A2B1
    LDA #$00
    STA APU_STATUS
    STA a:$07CD
    JMP Label_F9CC

Func_FCEA:
    JSR Func_B76F
    LDA PPU_STATUS
    JSR ResetPpuScroll
    STA APU_STATUS

Label_FCF6:
    LDA PPU_STATUS
    BPL Label_FCF6
    LDA #$08
    STA PPU_MASK
    JMP DisableNmi

Label_FD03:
    JMP Func_FCA2

Func_FD06:
    JSR DisableNmi
    JSR Func_819F
    BCS Label_FD03
    JSR Func_B64C
    LDA #$FB
    STA $22
    LDA #$9D
    STA $21
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR Func_FCEA
    JSR Func_81D6
    BCS Label_FD03
    STA CurrentRoomIndex
    STA a:$0712
    JSR Func_81D6
    STA $13
    LDX #$00

Label_FD3A:
    JSR Func_81D6
    BCS Label_FD03
    STA $05,X
    INX
    CPX #$0E
    BCC Label_FD3A
    LDX #$78

Label_FD48:
    JSR Func_81D6
    BCS Label_FD03
    STA a:$058F,X
    DEX
    BNE Label_FD48
    LDX #$96

Label_FD55:
    JSR Func_81D6
    BCS Label_FD03
    STA a:$0607,X
    DEX
    BNE Label_FD55
    LDX #$64

Label_FD62:
    JSR Func_81D6
    BCS Label_FD03
    STA a:$069D,X
    DEX
    BNE Label_FD62
    LDX #$08

Label_FD6F:
    JSR Func_81D6
    BCS Label_FD03
    CMP a:$FC99,X
    BNE Label_FD03
    DEX
    BNE Label_FD6F
    LDA #$00
    STA JOYPAD1
    STA a:$071B
    STA a:$0724
    STA a:$072D
    LDA $10
    STA $38
    LDA $11
    STA $39
    LDA $12
    STA $3A

Label_FD96:
    LDA #$00
    STA a:$0772
    LDX CurrentRoomIndex
    DEX
    JSR DecodeRoom
    JSR BuildRoomAttributeTables
    JSR LoadRoomObjects
    JSR Func_EC8A
    JSR Func_C43D
    LDA $3A
    SEC
    SBC #$10
    TAY
    LDA $39
    LDX $38
    JSR Func_A58A
    JSR Func_A66D
    BCS Label_FDC2
    JSR Func_A70A

Label_FDC2:
    JMP Func_FB51

Func_FDC5:
    LDA a:$072D
    BEQ Label_FE30
    TAY
    LDA RoomStateOffsetTable,Y
    SEC
    SBC Label_EF05,Y
    TAY
    LDX a:$072D
    LDA Label_EF05,X
    TAX
    LDA a:$072E
    STA a:$0608,X
    DEY
    BEQ Label_FDF2
    LDA a:$072F
    STA a:$0609,X
    DEY
    BEQ Label_FDF2
    LDA a:$0730
    STA a:$060A,X

Label_FDF2:
    LDY a:$072D
    LDA a:$ABAE,Y
    SEC
    SBC a:$ABAD,Y
    TAY
    BEQ Label_FE30
    LDX a:$072D
    LDA a:$ABAD,X
    TAX
    LDA a:$0731
    STA a:$0590,X
    DEY
    BEQ Label_FE30
    LDA a:$0732
    STA a:$0591,X
    DEY
    BEQ Label_FE30
    LDA a:$0733
    STA a:$0592,X
    DEY
    BEQ Label_FE30
    LDA a:$0734
    STA a:$0593,X
    DEY
    BEQ Label_FE30
    LDA a:$0735
    STA a:$0594,X

Label_FE30:
    RTS

Func_FE31:
    JSR Func_FED5
    JSR Func_B64C
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
    JSR Func_FCEA
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
    CMP $01
    LDA $0C
    SBC $02
    BCC Label_FEE7
    LDA $0B
    STA $01
    LDA $0C
    STA $02

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
