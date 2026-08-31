; Preservation PRG before room loading
; CPU range $9583-$A35B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateRuntimeObjects:
    LDX #$00
    STX $43

Label_9587:
    LDA #$00
    STA a:$07C6
    LDX $43
    LDA RuntimeObjectRecords,X
    AND #$7F
    BEQ Label_95B3
    LDA RuntimeObjectY,X
    CMP #$A0
    BCS Label_95B3
    LDA RuntimeObjectRecords,X
    ASL A
    TAX
    LDA a:$95BF,X
    STA $31
    LDA a:$95C0,X
    STA $32
    LDA #$95
    PHA
    LDA #$B2
    PHA
    LDX $43
    JMP ($0031)

Label_95B3:
    LDA $43
    CLC
    ADC #$06
    STA $43
    CMP #$90
    BCC Label_9587
    RTS
    .byte $A9, $A2, $C6, $9C, $A9, $A2, $A9, $A2, $D8, $9C, $00, $9B, $A9, $A2, $3B, $9C
    .byte $CB, $9E, $65, $9D, $74, $96, $74, $96, $74, $96, $74, $96, $5C, $96, $74, $96
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $F3, $9F, $96, $97, $69, $98, $37, $9A, $A9, $A2, $A9, $A2, $74, $9F, $A9, $A2
    .byte $1C, $A0, $33, $A0

Func_9613:
    .byte $A5, $46, $18, $69, $10, $38, $E5, $3A, $90, $3D, $E9, $10, $B0, $39, $A5, $44
    .byte $38, $E9, $0F, $85, $48, $A5, $45, $E9, $00, $85, $49, $A5, $49, $10, $06, $A9
    .byte $00, $85, $49, $85, $48, $A5, $38, $C5, $48, $A5, $39, $E5, $49, $90, $18, $A5
    .byte $44, $18, $65, $47, $85, $48, $A5, $45, $69, $00, $85, $49, $A5, $38, $C5, $48
    .byte $A5, $39, $E5, $49, $B0, $01, $60, $38, $60, $A9, $00, $8D, $73, $07, $20, $74
    .byte $96, $A6, $43, $AD, $73, $07, $F0, $08, $10, $03, $4C, $C4, $8A, $4C, $F6, $89
    .byte $60, $86, $41, $A9, $53, $85, $1E, $A9, $00, $85, $1F, $B5, $4B, $85, $21, $B5
    .byte $4C, $85, $22, $B5, $4D, $18, $69, $11, $85, $16, $A8, $A5, $22, $A6, $21, $20
    .byte $5D, $95, $90, $09, $85, $1E, $E6, $1F, $20, $44, $A0, $B0, $3E, $A4, $16, $A5
    .byte $21, $18, $69, $07, $AA, $A5, $22, $69, $00, $20, $5D, $95, $90, $09, $85, $1E
    .byte $E6, $1F, $20, $44, $A0, $B0, $24, $A4, $16, $A5, $21, $18, $69, $0F, $AA, $A5
    .byte $22, $69, $00, $20, $5D, $95, $B0, $13, $A5, $1E, $A4, $1F, $D0, $0D, $A6, $43
    .byte $B5, $4D, $C9, $A0, $B0, $04, $69, $02, $95, $4D, $60, $85, $16, $86, $17, $20
    .byte $44, $A0, $B0, $03, $4C, $6F, $97, $30, $44, $A9, $02, $18, $65, $21, $85, $21
    .byte $A5, $22, $69, $00, $85, $22, $A5, $21, $18, $69, $0F, $85, $23, $A5, $22, $69
    .byte $00, $85, $24, $A6, $43, $B4, $4D, $A6, $23, $A5, $24, $20, $5D, $95, $B0, $5B
    .byte $30, $59, $A6, $43, $B5, $4D, $18, $69, $0F, $A8, $A6, $23, $A5, $24, $20, $5D
    .byte $95, $B0, $48, $30, $46, $A9, $7F, $8D, $73, $07, $4C, $64, $97, $A5, $21, $38
    .byte $E9, $02, $85, $21, $A5, $22, $E9, $00, $85, $22, $A6, $43, $B4, $4D, $A6, $21
    .byte $A5, $22, $20, $5D, $95, $B0, $24, $30, $22, $A6, $43, $B5, $4D, $18, $69, $0F
    .byte $A8, $A6, $21, $A5, $22, $20, $5D, $95, $B0, $11, $30, $0F, $A9, $FF, $8D, $73
    .byte $07, $A6, $43, $A5, $21, $95, $4B, $A5, $22, $95, $4C, $60, $A5, $16, $20, $5E
    .byte $A0, $F0, $01, $60, $A5, $1E, $C5, $16, $F0, $07, $A5, $1E, $C9, $53, $F0, $01
    .byte $60, $A6, $42

Label_9786:
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JMP Func_C233

Func_9791:
    LDX $43
    JMP Label_9786

Label_9796:
    LDA RoomFrameCounter
    AND #$1F
    CMP #$1F
    BEQ Label_97A0
    RTS

Label_97A0:
    LDA RuntimeObjectState,X
    BPL Label_97A7
    JMP Label_980E

Label_97A7:
    LDA RuntimeObjectY,X
    CMP #$98
    BCS Label_97DE
    TAY
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDY #$14
    LDA ($2B),Y
    CMP #$4C
    BNE Label_97DE
    LDA #$53
    STA ($2B),Y
    LDA #$53
    LDY #$00
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$08
    STA RuntimeObjectY,X
    RTS

Label_97DE:
    LDX $43
    LDA #$FF
    STA RuntimeObjectState,X
    JMP Label_9796

Label_97E7:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDA #$53
    LDY #$00
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA #$00
    STA RuntimeObjectState,X
    JMP Label_9796

Label_980E:
    JSR Func_9A2C
    LDX $43
    LDA RuntimeObjectY,X
    BEQ Label_97E7
    SEC
    SBC #$08
    TAY
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y
    CMP #$53
    BNE Label_97E7
    LDA #$53
    STA ($2B),Y
    LDA #$4C
    LDY #$14
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA #$10
    STA $47
    JSR Func_9613
    BCC Label_985D
    JMP Label_9862

Label_985D:
    LDA #$FF
    STA a:$07C3

Label_9862:
    LDA #$10
    STA $47
    JMP Label_994E

Label_9869:
    LDA RoomFrameCounter
    AND #$1F
    CMP #$1F
    BEQ Label_9873
    RTS

Label_9873:
    LDA RuntimeObjectState,X
    BPL Label_987A
    JMP Label_98EC

Label_987A:
    LDA RuntimeObjectY,X
    CMP #$98
    BCS Label_98B9
    TAY
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDY #$14
    LDA ($2B),Y
    CMP #$4F
    BNE Label_98B9
    LDA #$53
    STA ($2B),Y
    LDA #$53
    INY
    STA ($2B),Y
    LDA #$53
    LDY #$00
    STA ($2B),Y
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$08
    STA RuntimeObjectY,X
    RTS

Label_98B9:
    LDX $43
    LDA #$FF
    STA RuntimeObjectState,X
    JMP Label_9869

Label_98C2:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDA #$53
    LDY #$00
    STA ($2B),Y
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA #$00
    STA RuntimeObjectState,X
    JMP Label_9869

Label_98EC:
    JSR Func_9A2C
    LDX $43
    LDA RuntimeObjectY,X
    BEQ Label_98C2
    SEC
    SBC #$08
    TAY
    JSR Func_94EA
    JSR ConvertPixelPositionToTileCoordinates
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y
    CMP #$53
    BNE Label_98C2
    LDA #$53
    STA ($2B),Y
    LDA #$53
    INY
    STA ($2B),Y
    LDA #$4F
    LDY #$14
    STA ($2B),Y
    LDA #$50
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA #$20
    STA $47
    JSR Func_9613
    BCC Label_9945
    JMP Label_994A

Label_9945:
    LDA #$FF
    STA a:$07C3

Label_994A:
    LDA #$20
    STA $47

Label_994E:
    LDX $43
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y

Label_9958:
    LDA #$00
    STA $16
    LDX #$00
    STX $17

Label_9960:
    LDX $17
    LDA a:$07AB,X
    BMI Label_9974

Label_9967:
    INX
    CPX #$18
    STX $17
    BCC Label_9960
    LDA $16
    BNE Label_9958
    BEQ Label_99C1

Label_9974:
    LDA #$7F
    STA a:$07AB,X
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #$08
    STA $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA RuntimeObjectRecords,X
    TAY
    LDA a:$AA6A,Y
    STA $47
    LDX #$00

Label_9996:
    JSR Func_A247
    BCS Label_99B0
    JSR Func_9A1F
    LDA a:$07AB,Y
    BNE Label_99A8
    LDA #$FF
    STA a:$07AB,Y

Label_99A8:
    TXA
    CLC
    ADC #$06
    TAX
    JMP Label_9996

Label_99B0:
    JSR Func_9613
    BCS Label_99BA
    LDA #$FF
    STA a:$07C3

Label_99BA:
    INC $16
    LDX $17
    JMP Label_9967

Label_99C1:
    LDX #$00
    STX $16

Label_99C5:
    LDX $16
    LDA a:$07AB,X
    BEQ Label_9A08
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    CMP #$08
    BCC Label_99FA
    SEC
    SBC #$01
    AND #$F8
    STA RuntimeObjectY,X
    TAY
    JSR Func_94EA
    JSR Func_A1A3
    BCS Label_99FA
    BMI Label_99FA
    LDX $16
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR Func_9508
    JSR Func_A1A3
    BMI Label_99FA
    BCC Label_9A08

Label_99FA:
    LDX $16
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X

Label_9A08:
    INC $16
    LDA $16
    CMP #$18
    BCC Label_99C5
    LDA a:$07C3
    BEQ Label_9A1E
    LDA $3A
    SEC
    SBC #$01
    AND #$F8
    STA $3A

Label_9A1E:
    RTS

Func_9A1F:
    LDY #$00
    TXA

Label_9A22:
    CMP #$06
    BCC Label_9A2B
    INY
    SBC #$06
    BCS Label_9A22

Label_9A2B:
    RTS

Func_9A2C:
    LDX #$18
    LDA #$00

Label_9A30:
    STA a:$07AB,X
    DEX
    BPL Label_9A30
    RTS
    STX CurrentObjectOffset
    LDA RuntimeObjectByte5,X
    BNE Label_9A65
    LDA RuntimeObjectState,X
    BMI Label_9A7E
    JSR Func_9AAD
    BCS Label_9A66
    JSR Func_9ABC
    BCS Label_9A66
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_9A58
    INC RuntimeObjectXHi,X

Label_9A58:
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$05
    STA $44
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $45

Label_9A65:
    RTS

Label_9A66:
    JSR Func_9ACF
    BCS Label_9A77
    JSR Func_9ADE
    BCS Label_9A77
    LDX $43
    LDA #$FF
    STA RuntimeObjectState,X
    RTS

Label_9A77:
    LDX $43
    LDA #$FF
    STA RuntimeObjectByte5,X
    RTS

Label_9A7E:
    JSR Func_9ACF
    BCS Label_9A9C
    JSR Func_9ADE
    BCS Label_9A9C
    LDX $43
    LDA RuntimeObjectXLo,X
    STA $44
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    STA $45
    SBC #$00
    STA RuntimeObjectXHi,X
    RTS

Label_9A9C:
    JSR Func_9AAD
    BCS Label_9A77
    JSR Func_9ABC
    BCS Label_9A77
    LDX $43
    LDA #$00
    STA RuntimeObjectState,X
    RTS

Func_9AAD:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9513
    JSR Func_9AF1
    BCS Label_9A65
    JMP Func_955D

Func_9ABC:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9513
    JSR Func_9AF1
    BCS Label_9A65
    JMP Func_955D

Func_9ACF:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9520
    JSR Func_9AF1
    BCS Label_9AFF
    JMP Func_955D

Func_9ADE:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9520
    JSR Func_9AF1
    BCS Label_9AFF
    JMP Func_955D

Func_9AF1:
    CPY #$A0
    BCS Label_9AFF
    CMP #$01
    BCC Label_9AFF
    CMP #$02
    BCS Label_9AFF
    CPX #$40

Label_9AFF:
    RTS

Func_9B00:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0E
    TAY
    JSR Func_94F2
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$16
    BNE Label_9B1B
    JMP Func_9791

Label_9B1B:
    LDX $43
    LDA a:$07C6
    BMI Label_9B8B
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_94EA
    JSR Func_A0C4
    BPL Label_9B33
    JMP Func_9791

Label_9B33:
    BCS Label_9B8B
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$07
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BPL Label_9B55
    JMP Func_9791

Label_9B55:
    BCS Label_9B8B
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BPL Label_9B77
    JMP Func_9791

Label_9B77:
    BCS Label_9B8B
    LDX $43
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    LDA RuntimeObjectY,X
    CMP #$A0
    BCS Label_9B8A
    LDA #$00
    STA a:$07C6

Label_9B8A:
    RTS

Label_9B8B:
    CMP #$8F
    BNE Label_9B92
    JMP Func_9791

Label_9B92:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BPL Label_9B9D
    JMP Label_9BED

Label_9B9D:
    JSR Func_9E7D
    BCS Label_9BE5
    LDA a:$07C6
    BNE Label_9BC4
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$11
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCC Label_9BE5

Label_9BC4:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP #$2F
    LDA RuntimeObjectXHi,X
    SBC #$01
    BCS Label_9BE5
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA RuntimeObjectXHi,X

Label_9BDF:
    LDA #$00
    STA a:$07C6
    RTS

Label_9BE5:
    LDX $43
    LDA #$FF
    STA RuntimeObjectState,X
    BNE Label_9BDF

Label_9BED:
    JSR Func_9E52
    BCS Label_9C31
    LDA a:$07C6
    BNE Label_9C14
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    TAX
    LDA $22
    SBC #$00
    JSR Func_A0C4
    BCC Label_9C31

Label_9C14:
    LDX $43
    LDA RuntimeObjectXHi,X
    BNE Label_9C20
    LDA RuntimeObjectXLo,X
    CMP #$02
    BCC Label_9C31

Label_9C20:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA RuntimeObjectXHi,X
    STA a:$07C6
    RTS

Label_9C31:
    LDX $43
    LDA #$00
    STA RuntimeObjectState,X
    STA a:$07C6
    RTS
    LDA RuntimeObjectByte5,X
    BEQ Label_9C42
    DEC RuntimeObjectByte5,X
    RTS

Label_9C42:
    JSR Func_9B00
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    CMP $3A
    BEQ Label_9C51
    RTS

Label_9C51:
    LDA RuntimeObjectXLo,X
    CMP $38
    LDA RuntimeObjectXHi,X
    SBC $39
    BCC Label_9C60
    LDA RuntimeObjectState,X
    BMI Label_9C65
    RTS

Label_9C60:
    LDA RuntimeObjectState,X
    BPL Label_9C65
    RTS

Label_9C65:
    LDA RoomFrameCounter
    AND #$3F
    BEQ Label_9C6D
    RTS

Label_9C6D:
    LDX CurrentRoomIndex
    LDA a:$AB49,X
    TAY
    LDX RuntimeObjectOffsetByCount,Y

Label_9C76:
    LDA RuntimeObjectRecords,X
    BEQ Label_9C84
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_9C76
    RTS

Label_9C84:
    LDY $43
    LDA #$03
    STA a:RuntimeObjectByte5,Y
    LDA #$A6
    STA RuntimeObjectRecords,X
    LDA a:RuntimeObjectY,Y
    CLC
    ADC #$07
    STA RuntimeObjectY,X
    LDA a:RuntimeObjectState,Y
    BMI Label_9CB2
    LDA a:RuntimeObjectXLo,Y
    CLC
    ADC #$12
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    ADC #$00
    STA RuntimeObjectXHi,X
    LDA #$00
    STA RuntimeObjectState,X
    JMP Label_9CC5

Label_9CB2:
    LDA a:RuntimeObjectXLo,Y
    SEC
    SBC #$06
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    SBC #$00
    STA RuntimeObjectXHi,X
    LDA #$FF
    STA RuntimeObjectState,X

Label_9CC5:
    RTS
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$01
    STA $16
    LDA RuntimeObjectY,X
    AND #$FE
    ORA $16
    STA RuntimeObjectY,X
    RTS
    JSR Func_9EA8
    LDA $22
    BNE Label_9CF5
    LDA $21
    CMP #$50
    BCS Label_9CF5
    LDX $43
    LDA $3A
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BCC Label_9CF5
    LDA #$7F
    STA a:$07C6

Label_9CF5:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectByte5,X
    BNE Label_9D1E
    JSR Func_A64D
    CMP #$14
    BCS Label_9D07
    JMP Func_9B00

Label_9D07:
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    TAY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9D18
    JMP Func_9B00

Label_9D18:
    LDX $43
    LDA #$0C
    STA RuntimeObjectByte5,X

Label_9D1E:
    DEC RuntimeObjectByte5,X
    LDA #$FF
    STA a:$07C6
    JSR Func_9B00
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_9508
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    CPY #$02
    BCC Label_9D64
    DEY
    DEY
    STY RuntimeObjectY,X

Label_9D64:
    RTS
    LDA $F5
    BNE Label_9D6C
    JSR Func_C29A

Label_9D6C:
    LDX $43
    LDA RoomFrameCounter
    AND #$01
    BEQ Label_9D76
    RTS

Label_9D76:
    LDA RuntimeObjectByte5,X
    BPL Label_9D7D
    JMP Label_9DC0

Label_9D7D:
    LDA $38
    CMP RuntimeObjectXLo,X
    BNE Label_9D8F
    LDA $39
    CMP RuntimeObjectXHi,X
    BNE Label_9D8F
    LDA #$FF
    STA RuntimeObjectByte5,X
    BNE Label_9DC9

Label_9D8F:
    LDA RuntimeObjectState,X
    BMI Label_9DAD
    JSR Func_9E7D
    BCS Label_9DA6
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_9DA5
    INC RuntimeObjectXHi,X

Label_9DA5:
    RTS

Label_9DA6:
    LDX $43
    LDA #$FF
    STA RuntimeObjectByte5,X
    RTS

Label_9DAD:
    JSR Func_9E52
    BCS Label_9DA6
    LDX $43
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    BCS Label_9DBF
    DEC RuntimeObjectXHi,X

Label_9DBF:
    RTS

Label_9DC0:
    LDA $3A
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BEQ Label_9DD9

Label_9DC9:
    LDA RuntimeObjectState,X
    BMI Label_9DE6
    JSR Func_9DF2
    BCS Label_9DD9
    LDX $43
    DEC RuntimeObjectY,X
    DEC RuntimeObjectY,X
    RTS

Label_9DD9:
    LDX $43
    LDA RuntimeObjectState,X
    EOR #$FF
    STA RuntimeObjectState,X
    LDA #$00
    STA RuntimeObjectByte5,X
    RTS

Label_9DE6:
    JSR Func_9E1F
    BCS Label_9DD9
    LDX $43
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    RTS

Func_9DF2:
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    CPY #$A0
    BCS Label_9E1E
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9E1E
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9E1E
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_9508
    JSR Func_A0C4

Label_9E1E:
    RTS

Func_9E1F:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    CMP #$A0
    BCS Label_9E51
    TAY
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9E51
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9E51
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_9508
    JSR Func_A0C4

Label_9E51:
    RTS

Func_9E52:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9520
    JSR Func_A0C4
    BCS Label_9E7C
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9520
    JSR Func_A0C4
    BCS Label_9E7C
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR Func_9520
    JSR Func_A0C4

Label_9E7C:
    RTS

Func_9E7D:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9513
    JSR Func_A0C4
    BCS Label_9EA7
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9513
    JSR Func_A0C4
    BCS Label_9EA7
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR Func_9513
    JSR Func_A0C4

Label_9EA7:
    RTS

Func_9EA8:
    LDA $38
    CLC
    SBC RuntimeObjectXLo,X
    STA $21
    LDA $39
    SBC RuntimeObjectXHi,X
    STA $22
    STA $24
    BPL Label_9ECA
    LDA $21
    EOR #$FF
    CLC
    ADC #$01
    STA $21
    LDA $22
    EOR #$FF
    ADC #$00
    STA $22

Label_9ECA:
    RTS
    JSR Func_9B00
    LDA RoomFrameCounter
    CMP #$E0
    BNE Label_9ECA
    LDX $43
    LDA RuntimeObjectState,X
    BMI Label_9EEB
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$10
    STA $21
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $22
    JMP Label_9EF8

Label_9EEB:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$10
    STA $21
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA $22

Label_9EF8:
    LDA $21
    CMP #$30
    LDA $22
    SBC #$01
    BCS Label_9F73
    LDY RuntimeObjectY,X
    STY $16
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9F73
    LDY $16
    LDA $21
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCS Label_9F73
    LDA $16
    CLC
    ADC #$0F
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9F73
    LDA $16
    CLC
    ADC #$0F
    TAY
    LDA $21
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCS Label_9F73
    LDY CurrentRoomIndex
    LDX a:$AB49,Y
    LDA RuntimeObjectOffsetByCount,X
    TAX

Label_9F4D:
    LDA RuntimeObjectRecords,X
    BEQ Label_9F5B
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_9F4D
    RTS

Label_9F5B:
    LDA #$A0
    STA RuntimeObjectRecords,X
    LDA $21
    STA RuntimeObjectXLo,X
    LDA $22
    STA RuntimeObjectXHi,X
    LDA $16
    STA RuntimeObjectY,X
    LDA #$10
    STA RuntimeObjectState,X
    LDA #$00
    STA RuntimeObjectByte5,X

Label_9F73:
    RTS
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BMI Label_9FBA
    LDY RuntimeObjectY,X
    JSR Func_94F2
    BEQ Label_9F89
    CMP #$01
    BNE Label_9FB5
    CPX #$40
    BCS Label_9FB5

Label_9F89:
    STX $21
    STA $22
    STY $16
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$03
    STA RuntimeObjectXLo,X
    BCC Label_9FB4
    INC RuntimeObjectXHi,X

Label_9FB4:
    RTS

Label_9FB5:
    LDX $43
    JMP Label_A024

Label_9FBA:
    LDY RuntimeObjectY,X
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$03
    TAX
    PLA
    SBC #$00
    BCC Label_9FB5
    STX $21
    STA $22
    STY $16
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDX $43
    LDA $21
    STA RuntimeObjectXLo,X
    LDA $22
    STA RuntimeObjectXHi,X
    RTS
    DEC RuntimeObjectState,X
    BEQ Label_9FF8
    RTS

Label_9FF8:
    LDA FrameCounter
    AND #$01
    BEQ Label_A000
    LDA #$FF

Label_A000:
    STA RuntimeObjectState,X
    LDA FrameCounterModulo30
    LSR A
    TAY
    LDA a:$A00D,Y
    STA RuntimeObjectRecords,X
    RTS
    .byte $84, $85, $85, $87, $87, $84, $84, $84, $84, $87, $84, $85, $84, $85, $84
    INC RuntimeObjectState,X
    LDA RuntimeObjectState,X
    CMP #$0F
    BCC Label_A032

Label_A024:
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA RuntimeObjectState,X
    STA RuntimeObjectByte5,X

Label_A032:
    RTS
    LDA RoomFrameCounter
    LSR A
    BCC Label_A03F
    LDA RuntimeObjectY,X
    BEQ Label_A03F
    DEC RuntimeObjectY,X

Label_A03F:
    DEC RuntimeObjectByte5,X
    BEQ Label_A024
    RTS

Func_A044:
    CMP #$35
    BCC Label_A050
    CMP #$41
    BCS Label_A050
    LDY #$00
    SEC
    RTS

Label_A050:
    CMP #$56
    BCC Label_A05C
    CMP #$62
    BCS Label_A05C
    LDY #$FF
    SEC
    RTS

Label_A05C:
    CLC
    RTS

Func_A05E:
    TAY
    PHP
    BPL Label_A067
    PLP
    LDA a:$9FEB,Y
    RTS

Label_A067:
    PLP
    LDA #$FF
    RTS
    .byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF

Func_A091:
    TAY
    PHP
    BPL Label_A09A
    PLP
    LDA a:$A01E,Y
    RTS

Label_A09A:
    PLP
    LDA #$FF
    RTS
    .byte $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $00, $00, $00, $00, $00, $00
    BRK
    BRK
    .byte $00, $00, $00, $00, $00, $FF, $FF, $00, $FF, $FF, $FF, $FF, $FF, $FF

Func_A0C4:
    CPY #$A0
    BCC Label_A0CE
    CLC
    LDA #$53
    LDY #$00
    RTS

Label_A0CE:
    STA $28
    STX $27
    STA $2A
    STX $29
    STY $1B
    LDA #$00
    STA $2C
    TYA
    LSR A
    LSR A
    LSR A
    STA $2B
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    CLC
    ADC $2B
    STA $2B
    BCC Label_A0F3
    INC $2C

Label_A0F3:
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    LDA #$04
    CLC
    ADC $2C
    STA $2C
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LDY $29
    LDA ($2B),Y
    CMP #$53
    BEQ Label_A13C
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$AA22,X
    BEQ Label_A13C
    JSR Func_A6CA
    BNE Label_A134
    LDY $40
    BPL Label_A134
    LDA #$00

Label_A134:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

Label_A13C:
    LDY #$00
    STY $1D

Label_A140:
    LDY $1D
    LDX RuntimeObjectOffsetByCount,Y
    CPX CurrentObjectOffset
    BEQ Label_A195
    LDA RuntimeObjectRecords,X
    BEQ Label_A195
    CMP #$A8
    BCS Label_A195
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A195
    SBC a:$AA9A,Y
    BCS Label_A195
    LDA $27
    STA $2B
    LDA $28
    STA $2C
    LDA $2B
    SEC
    SBC RuntimeObjectXLo,X
    STA $2B
    LDA $2C
    SBC RuntimeObjectXHi,X
    STA $2C
    BCC Label_A195
    LDA $2B
    SEC
    SBC a:$AA6A,Y
    STA $2B
    LDA $2C
    SBC #$00
    STA $2C
    BCS Label_A195
    STX $42
    LDA RuntimeObjectRecords,X
    JSR Func_A091
    CLC
    BEQ Label_A190
    SEC

Label_A190:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

Label_A195:
    INC $1D
    LDA $1D
    CMP #$18
    BCC Label_A140
    CLC
    LDA #$53
    LDY #$00
    RTS

Func_A1A3:
    CPY #$A0
    BCC Label_A1AD
    CLC
    LDA #$53
    LDX #$00
    RTS

Label_A1AD:
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$AA22,X
    JSR Func_A6CA
    BNE Label_A1CC
    LDA $40
    BPL Label_A1CC
    LDA #$00

Label_A1CC:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS
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
    SBC a:$AA9A,Y
    BCS Label_A239
    LDA $27
    STA $2B
    .byte $A5
    PLP
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
    SBC a:$AA6A,Y
    STA $2B
    LDA $2C
    SBC #$00
    STA $2C
    BCS Label_A239
    STX $42
    LDA RuntimeObjectRecords,X
    JSR Func_A091
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

Func_A247:
    CPX #$90
    BCS Label_A2A9
    LDA RuntimeObjectRecords,X
    BPL Label_A2A0
    CMP #$A8
    BCS Label_A2A0
    TAY
    LDA $46
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A2A0
    SBC a:$AA9A,Y
    BCS Label_A2A0
    LDA $44
    SEC
    SBC a:$AA6A,Y
    STA $48
    LDA $45
    SBC #$00
    STA $49
    INC $48
    BNE Label_A274
    INC $49

Label_A274:
    LDA $49
    BPL Label_A27E
    LDA #$00
    STA $49
    STA $48

Label_A27E:
    LDA RuntimeObjectXLo,X
    CMP $48
    LDA RuntimeObjectXHi,X
    SBC $49
    BCC Label_A2A0
    LDA $44
    CLC
    ADC $47
    STA $48
    LDA $45
    ADC #$00
    STA $49
    LDA RuntimeObjectXLo,X
    CMP $48
    LDA RuntimeObjectXHi,X
    SBC $49
    BCS Label_A2A0
    RTS

Label_A2A0:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Func_A247

Label_A2A9:
    RTS
    .byte $98, $4A
    LSR A
    LSR A
    STA NmiTaskIndex
    RTS

InitializeNewGame:
    LDA #$47
    STA CurrentRoomIndex
    LDA #$03
    STA $13
    LDA #$00
    STA a:$07CC
    STA a:$07CB
    STA CurrentRoomState
    STA RoomStateLoadMirror
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    STA $0B
    STA $0C
    STA a:$0772
    STA PauseMode
    STA CastleMapMode
    STA $0F
    STA $0D
    STA $0E
    STA a:$077C
    STA $3C
    STA a:$07C9
    STA a:$07CA
    STA a:$07CD
    STA a:$07D0
    STA a:$07D1
    STA a:$07D2
    STA a:$07D3
    LDA #$FF
    STA StatusTilesBusy
    LDA #$00
    STA $05
    STA $06
    STA $07
    STA $08
    STA $0A
    STA $09
    LDA #$00
    STA $39
    STA $11
    STA $38
    STA $10
    STA $14
    LDX #$0D

Label_A31B:
    LDA $05,X
    STA RoomRuntimeLoadMirror,X
    STA RoomRuntimeStateSnapshotA,X
    DEX
    BPL Label_A31B
    LDX #$78

Label_A328:
    STA RoomCells + $18F,X
    DEX
    BNE Label_A328
    LDX #$96

Label_A330:
    STA a:$0607,X
    DEX
    BNE Label_A330
    LDX #$1B

Label_A338:
    STA a:$0711,X
    DEX
    BNE Label_A338
    LDX #RoomVisitedFlagCount

Label_A340:
    STA RoomVisitedFlags - 1,X
    DEX
    BNE Label_A340
    LDA CurrentRoomIndex
    STA CurrentRoomState
    LDA #$98
    STA $3A
    STA $12

UploadRoomPalette:
    LDA #$C5
    STA $22
    LDA #$3D
    STA $21
    JMP UploadPaletteFromPointer
