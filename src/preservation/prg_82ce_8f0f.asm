; Preservation PRG after the main loop
; CPU range $82CE-$8F0F
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdatePlayerInputAndMovement:
    LDA a:$0772
    BEQ Label_82D4
    RTS

Label_82D4:
    LDA PlayerY
    BNE Label_82DB
    JMP Label_867A

Label_82DB:
    JSR Func_A64D
    AND #$03
    BNE Label_82FA
    LDA Controller1Buttons
    AND #$01
    BNE Label_82FA
    STA $3C
    LDA $EC
    CMP #$01
    BNE Label_82FA
    LDA #$0E
    STA APU_STATUS
    LDA #$00
    STA $EC

Label_82FA:
    LDA Controller1Buttons
    AND #$02
    BNE Label_8309
    STA a:$0779
    STA a:$077A
    BEQ Label_8320

Label_8309:
    LDA a:$077A
    BNE Label_8318
    LDA #$0A
    STA a:$0779
    STA a:$077A
    BNE Label_8320

Label_8318:
    LDA a:$0779
    BEQ Label_8320
    DEC a:$0779

Label_8320:
    LDA $3C
    CMP #$21
    BCC Label_8331
    LDA PlayerXLo
    AND #$07
    BNE Label_8331
    DEC $3C
    JSR Func_C20D

Label_8331:
    JSR Func_A64D
    BNE Label_8339
    JMP Label_83A4

Label_8339:
    DEC $3C
    BNE Label_8341
    LDA #$FF
    STA $3E

Label_8341:
    LDA $3C
    CMP #$10
    BCS Label_834A
    JMP Label_8478

Label_834A:
    LDY PlayerY
    DEY
    DEY
    STY $1A
    CPY #$10
    BCS Label_8357
    JMP Label_8478

Label_8357:
    JSR GetPlayerXPlus7
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    LDA PlayerXHi
    LDX PlayerXLo
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    JSR GetPlayerXPlus15
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    DEC PlayerY
    DEC PlayerY
    JMP Label_8478

Label_837D:
    ASL A
    TAX
    BCS Label_838E
    LDA a:$903F,X
    STA $31
    LDA a:$9040,X
    STA $32
    JMP Label_8398

Label_838E:
    LDA a:$9107,X
    STA $31
    LDA a:$9108,X
    STA $32

Label_8398:
    LDA #$83
    PHA
    LDA #$A0
    PHA
    JMP ($0031)
    JMP Label_8478

Label_83A4:
    LDA #$11
    STA $1F

Label_83A8:
    LDA #$00
    STA $1E
    STA $2F
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    JSR GetPlayerXPlus7
    JSR Func_8DD3
    BCC Label_83C5
    STA $30
    JSR Func_A044
    BCS Label_840F
    INC $1E

Label_83C5:
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR Func_8DD3
    BCC Label_83DD
    STA $2F
    JSR Func_A044
    BCS Label_840F
    INC $1E

Label_83DD:
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    JSR GetPlayerXPlus15
    JSR Func_8DD3
    BCS Label_840F
    LDA $1E
    BEQ Label_83F8
    LDA $2F
    BNE Label_83F5
    LDA $30

Label_83F5:
    JMP Label_840F

Label_83F8:
    LDA #$FF
    STA $3E
    LDA $1F
    CMP #$11
    BNE Label_8404
    INC PlayerY

Label_8404:
    INC PlayerY
    LDA PlayerY
    CMP #$A0
    BCC Label_8478
    JMP Label_86A0

Label_840F:
    LDX #$10
    CPX $1F
    BEQ Label_841A
    STX $1F
    JMP Label_83A8

Label_841A:
    ASL A
    TAX
    BCS Label_842B
    LDA a:$8F29,X
    STA $31
    LDA a:$8F2A,X
    STA $32
    JMP Label_8435

Label_842B:
    LDA a:$8FF1,X
    STA $31
    LDA a:$8FF2,X
    STA $32

Label_8435:
    LDA #$84
    PHA
    LDA #$3D
    PHA
    JMP ($0031)
    LDA $3C
    CMP #$21
    BCS Label_846B
    LDA Controller1Buttons
    AND #$01
    BEQ Label_847B
    LDA PlayerXLo
    AND #$07
    BNE Label_8467
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_8467
    LDA a:$07CA
    BMI Label_8478
    INC a:$07CA
    JMP Label_8478

Label_8467:
    LDA #$21
    STA $3C

Label_846B:
    LDA PlayerXLo
    AND #$07
    BNE Label_8478
    LDA #$20
    STA $3C
    JSR Func_C20D

Label_8478:
    JMP Label_8490

Label_847B:
    LDA Controller1Buttons
    AND #$C0
    BNE Label_8490
    LDA PlayerXLo
    AND #$07
    BNE Label_8490
    LDA #$00
    STA a:$07C9
    STA a:$07CA

Label_8490:
    LDA a:$0779
    BEQ Label_849F
    JSR Func_A64D
    ORA $3E
    BNE Label_849F
    JMP Label_85CA

Label_849F:
    LDA $3F
    BEQ Label_84A8
    DEC $3F
    JMP Label_8512

Label_84A8:
    LDA a:$0774
    PHP
    LDA #$00
    STA a:$0774
    PLP
    BNE Label_84C8
    LDA $3B
    BEQ Label_84D9
    LDA PlayerXLo
    AND #$07
    BNE Label_8512
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    BNE Label_84D9

Label_84C8:
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    LDA PlayerXLo
    AND #$07
    BEQ Label_84D9
    JMP Label_85CA

Label_84D9:
    LDA #$00
    STA $3B
    LDA Controller1Buttons
    AND #$C0
    BNE Label_84E7
    JMP Label_85CA

Label_84E7:
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_84FD
    LDA a:$07C9
    BMI Label_84FA
    INC a:$07C9

Label_84FA:
    JMP Label_85CA

Label_84FD:
    LDA Controller1Buttons
    AND #$C0
    BEQ Label_8512
    CMP #$C0
    BEQ Label_8512
    LDX #$7F
    CMP #$40
    BNE Label_8510
    LDX #$FF

Label_8510:
    STX $3B

Label_8512:
    LDA $3B
    BNE Label_8519
    JMP Label_85CA

Label_8519:
    BMI Label_8538
    LDA PlayerXLo
    CLC
    ADC #$11
    STA $21
    LDA PlayerXHi
    ADC #$00
    STA $22
    LDA PlayerXLo
    CLC
    ADC #$02
    STA $23
    LDA PlayerXHi
    ADC #$00
    STA $24
    JMP Label_8549

Label_8538:
    LDA PlayerXLo
    SEC
    SBC #$02
    STA $21
    STA $23
    LDA PlayerXHi
    SBC #$00
    STA $22
    STA $24

Label_8549:
    LDA $24
    BEQ Label_855D
    CMP #$01
    BEQ Label_8554
    JMP Label_86C6

Label_8554:
    LDA $23
    CMP #$31
    BCC Label_855D
    JMP Label_870F

Label_855D:
    LDA #$FF
    STA a:$07CB
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR Func_8DD3
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR Func_8DD3
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA $22
    LDX $21
    LDY PlayerY
    STY $1E
    JSR Func_8DD3
    BCS Label_85A6
    LDA $24
    STA PlayerXHi
    LDA $23
    STA PlayerXLo
    JMP Label_85CA

Label_85A6:
    ASL A
    TAX
    BCS Label_85B7
    LDA a:$9155,X
    STA $31
    LDA a:$9156,X
    STA $32
    JMP Label_85C1

Label_85B7:
    LDA a:$921D,X
    STA $31
    LDA a:$921E,X
    STA $32

Label_85C1:
    LDA #$85
    PHA
    LDA #$C9
    PHA
    JMP ($0031)

Label_85CA:
    LDA a:$0779
    BNE Label_85D2
    JMP Label_8673

Label_85D2:
    LDA $3B
    BNE Label_85D9
    JMP Label_8673

Label_85D9:
    BMI Label_85F5
    LDA PlayerXLo
    CLC
    ADC #$16
    STA $21
    LDA PlayerXHi
    ADC #$00
    STA $22
    LDA $21
    CMP #$40
    LDA $22
    SBC #$01
    BCC Label_8604
    JMP Label_8673

Label_85F5:
    LDA PlayerXLo
    SEC
    SBC #$06
    STA $21
    LDA PlayerXHi
    SBC #$00
    STA $22
    BMI Label_8673

Label_8604:
    LDA PlayerY
    SEC
    SBC #$05
    STA $16
    LDX #$00

Label_860D:
    LDA RuntimeObjectRecords,X
    BPL Label_866A
    CMP #$A8
    BCS Label_866A
    TAY
    LDA $16
    SEC
    SBC RuntimeObjectY,X
    BCC Label_866A
    SBC a:$AA9A,Y
    BCS Label_866A
    LDA $21
    STA $23
    LDA $22
    STA $24
    LDA $23
    SEC
    SBC RuntimeObjectXLo,X
    STA $23
    LDA $24
    SBC RuntimeObjectXHi,X
    BCC Label_866A
    STA $24
    LDA $23
    SBC a:$AA6A,Y
    BCS Label_866A
    LDA $24
    BNE Label_866A
    LDA RuntimeObjectRecords,X
    CMP #$85
    BEQ Label_8673
    CMP #$89
    BEQ Label_8673
    CMP #$86
    BEQ Label_8673
    STX $16
    TYA
    JSR Func_A05E
    BNE Label_8673
    LDA #$A8
    LDX $16
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JSR Func_C233
    JMP Label_8673

Label_866A:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_860D

Label_8673:
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

Label_867A:
    LDA #$98
    STA PlayerY
    STA $12
    LDA PlayerXHi
    STA $11
    LDA PlayerXLo
    AND #$F8
    STA PlayerXLo
    STA $10
    JSR Func_8758
    JSR Func_A7DB
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

Label_86A0:
    LDA #$10
    STA PlayerY
    STA $12
    LDA PlayerXHi
    STA $11
    LDA PlayerXLo
    AND #$F8
    STA PlayerXLo
    STA $10
    JSR Func_8758
    JSR Func_A7E6
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

Label_86C6:
    LDA CurrentRoomIndex
    JSR Func_A816
    BNE Label_86D6
    LDA #$00
    STA PlayerXLo
    STA PlayerXHi
    JMP UpdateHorizontalScroll

Label_86D6:
    LDA #$30
    STA PlayerXLo
    STA $10
    LDA #$01
    STA PlayerXHi
    STA $11
    LDA PlayerY
    STA $12
    JSR Func_8758
    JSR Func_A7FE
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #$10
    TAY
    LDA #$01
    LDX #$30
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS Label_870C
    JSR RestoreMutableCellByOrdinal

Label_870C:
    JMP FinishRoomTransition

Label_870F:
    LDA CurrentRoomIndex
    JSR Func_A80B
    BNE Label_8721
    LDA #$01
    STA PlayerXHi
    LDA #$30
    STA PlayerXLo
    JMP UpdateHorizontalScroll

Label_8721:
    LDA #$00
    STA PlayerXLo
    STA PlayerXHi
    STA $10
    STA $11
    LDA PlayerY
    STA $12
    JSR Func_8758
    JSR Func_A7F1
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #$10
    TAY
    LDA #$00
    LDX #$00
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS Label_8755
    JSR RestoreMutableCellByOrdinal

Label_8755:
    JMP FinishRoomTransition

Func_8758:
    LDX #$00

Label_875A:
    SEC
    LDA RuntimeObjectRecords,X
    BPL Label_8761
    CMP #$A8

Label_8761:
    ROR $18
    ROR $17
    ROR $16
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_875A
    LDA CurrentRoomIndex
    STA CurrentRoomState
    LDA $16
    STA CurrentRoomObjectState
    LDA $17
    STA a:$0714
    LDA $18
    STA a:$0715
    RTS
    .byte $A5, $38, $38, $E9, $02, $85, $21, $A5, $39, $E9, $00, $85, $22, $30, $36, $A4
    .byte $3A, $A6, $21, $A5, $22, $20, $D3, $8D, $B0, $2B, $A5, $3A, $18, $69, $07, $A8
    .byte $A6, $21, $A5, $22, $20, $D3, $8D, $B0, $1C, $A5, $3A, $18, $69, $0F, $A8, $A6
    .byte $21, $A5, $22, $20, $D3, $8D, $B0, $0D, $A5, $21, $85, $38, $A5, $22, $85, $39
    .byte $A9, $FF, $8D, $74, $07, $60, $A5, $38, $18, $69, $02, $85, $21, $A5, $39, $69
    .byte $00, $85, $22, $A5, $38, $18, $69, $11, $85, $23, $A5, $39, $69, $00, $85, $24
    .byte $A5, $38, $C9, $3F, $A5, $39, $E9, $01, $B0, $DB, $A4, $3A, $A6, $23, $A5, $24
    .byte $20, $D3, $8D, $B0, $D0, $A5, $3A, $18, $69, $07, $A8, $A6, $23, $A5, $24, $20
    .byte $D3, $8D, $B0, $C1, $A5, $3A, $18, $69, $0F, $A8, $A6, $23, $A5, $24, $20, $D3
    .byte $8D, $B0, $B2, $90, $A3, $20, $4D, $A6, $05, $3E, $F0, $01, $60, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $EA, $94, $20, $5D, $95, $B0, $21, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $F2, $94, $20, $5D, $95, $B0, $11, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $08, $95, $20, $5D, $95, $B0, $01, $60, $A6, $41
    .byte $86, $1C, $A5, $3B, $30, $62, $A9, $FF, $85, $41, $A5, $38, $18, $69, $11, $AA
    .byte $A5, $39, $69, $00, $A4, $3A, $20, $D3, $8D, $90, $08, $A5, $41, $C5, $1C, $F0
    .byte $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $07, $A8, $A5, $38, $18
    .byte $69, $10, $AA, $A5, $39, $69, $00, $20, $D3, $8D, $90, $08, $A5, $41, $C5, $1C
    .byte $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $0F, $A8, $A5, $38
    .byte $18, $69, $10, $AA, $A5, $39, $69, $00, $20, $D3, $8D, $90, $08, $A5, $41, $C5
    .byte $1C, $F0, $02, $38, $60, $4C, $1C, $89, $A9, $FF, $85, $41, $A5, $38, $38, $E9
    .byte $02, $AA, $A5, $39, $E9, $00, $A4, $3A, $20, $D3, $8D, $90, $08, $A5, $41, $C5
    .byte $1C, $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $07, $A8, $A5
    .byte $38, $38, $E9, $01, $AA, $A5, $39, $E9, $00, $20, $D3, $8D, $90, $08, $A5, $41
    .byte $C5, $1C, $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $0F, $A8
    .byte $A5, $38, $38, $E9, $01, $AA, $A5, $39, $E9, $00, $20, $D3, $8D, $90, $08, $A5
    .byte $41, $C5, $1C, $F0, $02, $38, $60, $A6, $1C, $A5, $3B, $30, $18, $B5, $4B, $18
    .byte $69, $10, $85, $25, $B5, $4C, $69, $00, $85, $26, $A5, $25, $C9, $40, $A5, $26
    .byte $E9, $01, $90, $1B, $60, $B5, $4B, $85, $25, $B5, $4C, $85, $26, $A5, $25, $D0
    .byte $02, $C6, $26, $C6, $25, $A5, $25, $C9, $40, $A5, $26, $E9, $01, $B0, $E5, $B4
    .byte $4D, $A5, $26, $A6, $25, $20, $5D, $95, $B0, $26, $30, $24, $A6, $1C, $B5, $4D
    .byte $18, $69, $07, $A8, $A5, $26, $A6, $25, $20, $5D, $95, $B0, $13, $30, $11, $A6
    .byte $1C, $B5, $4D, $18, $69, $0F, $A8, $A5, $26, $A6, $25, $20, $5D, $95, $90, $1B
    .byte $C9, $80, $90, $15, $20, $5E, $A0, $D0, $10, $A6, $42, $A9, $A8, $95, $4A, $A9
    .byte $00, $95, $4E, $20, $33, $C2, $4C, $A0, $89, $38, $60, $A6, $1C, $A5, $3B, $30
    .byte $1E, $B5, $4B, $18, $69, $02, $95, $4B, $90, $02, $F6, $4C, $A5, $38, $18, $69
    .byte $02, $85, $38, $90, $02, $E6, $39, $A9, $7F, $8D, $73, $07, $4C, $DF, $89, $B5
    .byte $4B, $38, $E9, $02, $95, $4B, $B0, $02, $D6, $4C, $A5, $38, $38, $E9, $02, $85
    .byte $38, $B0, $02, $C6, $39, $A9, $FF, $8D, $73, $07, $18

Label_89E0:
    RTS
    .byte $A9, $00, $8D, $73, $07, $20, $1A, $88, $AD, $73, $07, $D0, $01, $60, $10, $03
    .byte $4C, $C2, $8A, $A6, $41
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$41
    BCC Label_89E0
    CMP #$44
    BCS Label_89E0
    LDA a:$0773
    BEQ Label_89E0
    BPL Label_8A15
    JMP Func_8AC2

Label_8A15:
    LDX #$00

Label_8A17:
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8A27
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8A17
    RTS

Label_8A27:
    STX $1E
    LDX #$00

Label_8A2B:
    LDA RuntimeObjectRecords,X
    CMP #$A5
    BEQ Label_8A3B
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8A2B
    RTS

Label_8A3B:
    STX $1F
    LDA RuntimeObjectY,X
    CLC
    ADC #$09
    TAY
    STY $1C
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #$53
    BEQ Label_8A52
    JMP Label_8AC1

Label_8A52:
    LDY $1C
    LDX $1F
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #$53
    BEQ Label_8A63
    JMP Label_8AC1

Label_8A63:
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$0A
    TAY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #$53
    BNE Label_8AC1
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$0A
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #$53
    BNE Label_8AC1
    LDY $1C
    LDX $1F
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #$53
    BNE Label_8AC1
    LDX $1E
    LDY RuntimeObjectY,X
    INY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #$00
    LDA #$52
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR RequestRoomCellRowUpdate
    LDX $1E
    JSR Func_8ABB
    LDX $1F

Func_8ABB:
    LDY RuntimeObjectY,X
    INY
    INY
    STY RuntimeObjectY,X

Label_8AC1:
    RTS

Func_8AC2:
    LDX CurrentObjectOffset
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus8
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$41
    BCC Label_8AC1
    CMP #$44
    BCS Label_8AC1
    LDX #$00

Label_8ADB:
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8AEB
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8ADB
    RTS

Label_8AEB:
    STX $1E
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectX
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$52
    BEQ Label_8B00
    RTS

Label_8B00:
    LDX #$00

Label_8B02:
    LDA RuntimeObjectRecords,X
    CMP #$A5
    BEQ Label_8B12
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8B02
    RTS

Label_8B12:
    STX $1F
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$06
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #$00
    LDA #$53
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR RequestRoomCellRowUpdate
    JSR Func_9A2C
    LDX $1E
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y
    LDX $1F
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y
    LDA #$10
    STA $47

Label_8B51:
    LDA #$00
    STA $16
    LDX #$00
    STX $17

Label_8B59:
    LDX $17
    LDA a:$07AB,X
    BMI Label_8B6D

Label_8B60:
    INX
    CPX #$18
    STX $17
    BCC Label_8B59
    LDA $16
    BNE Label_8B51
    BEQ Label_8BB0

Label_8B6D:
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

Label_8B8F:
    JSR Func_A247
    BCS Label_8BA9
    JSR Func_9A1F
    LDA a:$07AB,Y
    BNE Label_8BA1
    LDA #$FF
    STA a:$07AB,Y

Label_8BA1:
    TXA
    CLC
    ADC #$06
    TAX
    JMP Label_8B8F

Label_8BA9:
    INC $16
    LDX $17
    JMP Label_8B60

Label_8BB0:
    LDX #$00
    STX $16

Label_8BB4:
    LDX $16
    LDA a:$07AB,X
    BEQ Label_8BF9
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #$02
    BCC Label_8BEB
    STA RuntimeObjectY,X
    TAY
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8BF9
    JSR GetRuntimeObjectX
    JSR Func_A1A3
    BCS Label_8BEB
    BMI Label_8BEB
    LDX $16
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus15
    JSR Func_A1A3
    BMI Label_8BEB
    BCC Label_8BF9

Label_8BEB:
    LDX $16
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X

Label_8BF9:
    INC $16
    LDA $16
    CMP #$18
    BCC Label_8BB4
    LDA a:$07C3
    BEQ Label_8C11
    LDA PlayerY
    SEC
    SBC #$02
    BCS Label_8C0F
    LDA #$00

Label_8C0F:
    STA PlayerY

Label_8C11:
    RTS
    .byte $20, $A9, $A8, $B0, $63, $E6, $06, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20
    .byte $A9, $A8, $B0, $54, $E6, $05, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20, $A9
    .byte $A8, $B0, $45, $E6, $09, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20, $A9, $A8
    .byte $B0, $36, $E6, $08, $A9, $0A, $20, $04, $8D, $4C, $69, $8C
    JSR Func_A8A9
    BCS Label_8C7A
    INC $0A
    LDA #$0A
    JSR Func_8D04
    JMP Label_8C69
    JSR Func_A8A9
    BCS Label_8C7A
    INC $07
    LDA #$0A
    JSR Func_8D04

Label_8C69:
    JSR Func_C272
    LDA #$05
    LDX CurrentObjectOffset
    STA RuntimeObjectState,X
    LDA #$A9
    STA RuntimeObjectRecords,X
    LDA #$14
    STA RuntimeObjectByte5,X

Label_8C7A:
    RTS
    .byte $A6, $41, $4C, $24, $A0, $20, $A9, $A8, $90, $01, $60, $EE, $CD, $07, $A9, $64
    .byte $20, $04, $8D, $A5, $0D, $D0, $03, $20, $79, $B8, $A9, $28, $85, $0D, $A9, $09
    .byte $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $FF, $85, $0F, $A9, $64, $20
    .byte $04, $8D, $A9, $09, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $14, $20
    .byte $04, $8D, $A9, $06, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $28, $20
    .byte $04, $8D, $A9, $07, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $50, $20
    .byte $04, $8D, $A9, $08, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $64, $20
    .byte $04, $8D, $A9, $09, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $64, $20
    .byte $04, $8D, $E6, $13, $A9
    ORA #$4C

Func_8D04 = * + 2  ; overlapping entry $8D04
    ROR a:$488C
    LDA DemoPlaybackActive
    BNE Label_8D28
    JSR Func_8D2A
    LDY $27
    PLA
    CLC
    ADC $0B
    STA $0B
    BCC Label_8D19
    INC $0C

Label_8D19:
    JSR Func_8D2A
    TYA
    EOR $27
    BEQ Label_8D27
    INC $13
    BNE Label_8D27
    DEC $13

Label_8D27:
    RTS

Label_8D28:
    PLA
    RTS

Func_8D2A:
    LDA $0B
    STA $2B
    LDA $0C
    STA $2C
    LDA #$03
    STA $2A
    LDA #$E8
    STA $29
    JMP Func_C47A
    .byte $AD, $6B, $07, $10, $14, $A6, $41, $B5, $4B, $C5, $38, $F0, $01, $60, $A5, $0E
    .byte $D0, $03, $20, $81, $B8, $A9, $28, $85, $0E, $60, $AD, $CC, $07, $D0, $13, $20
    .byte $A9, $A8, $B0, $0E, $20, $85, $B8, $A5, $DB, $05, $DC, $D0, $FA, $68, $68, $4C
    .byte $8E, $FE, $60, $20, $A9, $A8, $B0, $FA, $20, $8D, $B8, $A5, $DB, $05, $DC, $D0
    .byte $FA, $A6, $41, $A9, $91, $95, $4A, $B5, $4B, $38, $E9, $10, $95, $4B, $B0, $02
    .byte $D6, $4C, $A5, $37, $C9, $59, $D0, $15, $A9, $91, $85, $D4, $B5, $4B, $38, $E9
    .byte $10, $85, $D5, $B5, $4C, $E9, $00, $85, $D6, $B5, $4D, $85, $D7, $60, $A5, $40
    .byte $10, $01, $60

Label_8DB0:
    LDA $0E
    ORA a:$0772
    BEQ Label_8DB8
    RTS

Label_8DB8:
    LDA #$80
    STA a:$0772
    LDA #$00
    STA a:$0779
    LDA $13
    BEQ Label_8DCB
    DEC $13
    JMP Label_8DD0

Label_8DCB:
    LDA #$FF
    STA a:$07CC

Label_8DD0:
    JMP LoadAudioTrackSet2

Func_8DD3:
    CPY #$10
    BCC Label_8DE7
    CPY #$B0
    BCS Label_8DE7
    CMP #$00
    BEQ Label_8DF0
    CMP #$01
    BNE Label_8DE7
    CPX #$40
    BCC Label_8DF0

Label_8DE7:
    CLC
    LDA #$53
    LDX #$00
    STX a:$07CB
    RTS

Label_8DF0:
    PHA
    TYA
    SEC
    SBC #$10
    TAY
    PLA
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$53
    BEQ Label_8E2B
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$A95A,X
    BEQ Label_8E2B
    JSR Func_A6CA
    BNE Label_8E1C
    LDY $40
    BPL Label_8E1C
    LDA #$00

Label_8E1C:
    PHA
    LDA #$00
    STA a:$07CB
    PLA
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

Label_8E2B:
    LDY #$00
    STY $1D

Label_8E2F:
    LDY $1D
    LDX RuntimeObjectOffsetByCount,Y
    STX CurrentObjectOffset
    LDA RuntimeObjectRecords,X
    BEQ Label_8EB7
    CMP #$A8
    BCS Label_8EB7
    DEC a:$07CB
    INC a:$07CB
    BEQ Label_8E4D
    LDA RuntimeObjectRecords,X
    JSR IsRuntimeObjectType90To95
    BCC Label_8EB7

Label_8E4D:
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_8EB7
    SBC a:$AA9A,Y
    BCS Label_8EB7
    CPY #$86
    BNE Label_8E7A
    PHA
    LDA RoomFrameCounter
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #$08
    BCS Label_8E79
    PLA
    CMP #$F8
    BCC Label_8EB7
    LDA $3C
    BEQ Label_8E7A
    BNE Label_8EB7
    PLA
    JMP Label_8EB7

Label_8E79:
    PLA

Label_8E7A:
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
    BCC Label_8EB7
    STA $2C
    LDA $2B
    SBC a:$AA6A,Y
    BCS Label_8EB7
    LDA $2C
    BNE Label_8EB7
    LDA RuntimeObjectRecords,X
    JSR Func_A091
    CLC
    BEQ Label_8EA5
    SEC

Label_8EA5:
    LDA RuntimeObjectRecords,X
    JSR Func_A05E
    BNE Label_8EAD
    CLC

Label_8EAD:
    LDA RuntimeObjectRecords,X
    LDY #$00
    STY a:$07CB
    LDY #$01
    RTS

Label_8EB7:
    INC $1D
    LDA $1D
    CMP #$18
    BCS Label_8EC2
    JMP Label_8E2F

Label_8EC2:
    CLC
    LDA #$53
    LDY #$00
    STY a:$07CB
    RTS

Func_8ECB:
    STA $28
    STA $2A
    STX $27
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
    BCC Label_8EF0
    INC $2C

Label_8EF0:
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
    RTS
