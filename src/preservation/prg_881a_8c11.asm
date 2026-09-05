; Preservation PRG before collectible collision handlers
; CPU range $881A-$8C11
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_881A:
    JSR GetActivePlayerMotionState
    ORA $3E
    BEQ Label_8822
    RTS

Label_8822:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    BCS Label_8853
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleNormalizedRoomCollisionCell
    BCS Label_8853
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    BCS Label_8853
    RTS

Label_8853:
    LDX CurrentObjectOffset
    STX $1C
    LDA $3B
    BMI Label_88BD
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerXLo
    CLC
    ADC #$11
    TAX
    LDA PlayerXHi
    ADC #$00
    LDY PlayerY
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_8878
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_8878
    SEC
    RTS

Label_8878:
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    LDA PlayerXLo
    CLC
    ADC #$10
    TAX
    LDA PlayerXHi
    ADC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_8899
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_8899
    SEC
    RTS

Label_8899:
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    LDA PlayerXLo
    CLC
    ADC #$10
    TAX
    LDA PlayerXHi
    ADC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_88BA
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_88BA
    SEC
    RTS

Label_88BA:
    JMP Label_891C

Label_88BD:
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerXLo
    SEC
    SBC #$02
    TAX
    LDA PlayerXHi
    SBC #$00
    LDY PlayerY
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_88DA
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_88DA
    SEC
    RTS

Label_88DA:
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    LDA PlayerXLo
    SEC
    SBC #$01
    TAX
    LDA PlayerXHi
    SBC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_88FB
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_88FB
    SEC
    RTS

Label_88FB:
    LDA #$FF
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    LDA PlayerXLo
    SEC
    SBC #$01
    TAX
    LDA PlayerXHi
    SBC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_891C
    LDA CurrentObjectOffset
    CMP $1C
    BEQ Label_891C
    SEC
    RTS

Label_891C:
    LDX $1C
    LDA $3B
    BMI Label_893A
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$10
    STA $25
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $26
    LDA $25
    CMP #$40
    LDA $26
    SBC #$01
    BCC Label_8954

Label_8939:
    RTS

Label_893A:
    LDA RuntimeObjectXLo,X
    STA $25
    LDA RuntimeObjectXHi,X
    STA $26
    LDA $25
    BNE Label_8948
    DEC $26

Label_8948:
    DEC $25
    LDA $25
    CMP #$40
    LDA $26
    SBC #$01
    BCS Label_8939

Label_8954:
    LDY RuntimeObjectY,X
    LDA $26
    LDX $25
    JSR SampleNormalizedRoomCollisionCell
    BCS Label_8985
    BMI Label_8985
    LDX $1C
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    LDA $26
    LDX $25
    JSR SampleNormalizedRoomCollisionCell
    BCS Label_8985
    BMI Label_8985
    LDX $1C
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    LDA $26
    LDX $25
    JSR SampleNormalizedRoomCollisionCell
    BCC Label_89A0

Label_8985:
    CMP #$80
    BCC Label_899E
    JSR GetRuntimeObjectType84To89Filter
    BNE Label_899E
    LDX $42
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JSR Func_C233
    JMP Label_89A0

Label_899E:
    SEC
    RTS

Label_89A0:
    LDX $1C
    LDA $3B
    BMI Label_89C4
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_89B1
    INC RuntimeObjectXHi,X

Label_89B1:
    LDA PlayerXLo
    CLC
    ADC #$02
    STA PlayerXLo
    BCC Label_89BC
    INC PlayerXHi

Label_89BC:
    LDA #$7F
    STA a:$0773
    JMP Label_89DF

Label_89C4:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    BCS Label_89CF
    DEC RuntimeObjectXHi,X

Label_89CF:
    LDA PlayerXLo
    SEC
    SBC #$02
    STA PlayerXLo
    BCS Label_89DA
    DEC PlayerXHi

Label_89DA:
    LDA #$FF
    STA a:$0773

Label_89DF:
    CLC

Label_89E0:
    RTS

HandleRuntimeType8EHorizontalCollision:
    LDA #$00
    STA a:$0773
    JSR Func_881A
    LDA a:$0773
    BNE Label_89EF
    RTS

Label_89EF:
    BPL Label_89F4
    JMP Func_8AC2

Label_89F4:
    LDX CurrentObjectOffset
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR PrepareRoomCellSampleAddress
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
    JSR PrepareRoomCellSampleAddress
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
    JSR PrepareRoomCellSampleAddress
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
    LDA RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA $47
    LDX #$00

Label_8B8F:
    JSR FindRuntimeObjectOverlappingSpan
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
    JSR SampleRoomCollisionAtPixel
    BCS Label_8BEB
    BMI Label_8BEB
    LDX $16
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus15
    JSR SampleRoomCollisionAtPixel
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
