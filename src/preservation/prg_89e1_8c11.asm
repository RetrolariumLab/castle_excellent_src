; Unresolved type-$8E and linked-object mechanics
; CPU range $89E1-$8C11
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleRuntimeType8EHorizontalCollision:
    LDA #$00
    STA PlayerObjectPushDirectionLatch
    JSR PushPlayerAndRuntimeObject
    LDA PlayerObjectPushDirectionLatch
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
    BCC ReturnPlayerObjectPush
    CMP #$44
    BCS ReturnPlayerObjectPush
    LDA PlayerObjectPushDirectionLatch
    BEQ ReturnPlayerObjectPush
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
