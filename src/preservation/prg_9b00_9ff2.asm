; Remaining preservation runtime-object handlers before transient lifecycles
; CPU range $9B00-$9FF2
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_9B00:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0E
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR PrepareRoomCellSampleAddress
    LDY $29
    LDA ($2B),Y
    CMP #$16
    BNE Label_9B1B
    JMP DestroyCurrentRuntimeObjectWithSound

Label_9B1B:
    LDX CurrentRuntimeObjectOffset
    LDA a:$07C6
    BMI Label_9B8B
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BPL Label_9B33
    JMP DestroyCurrentRuntimeObjectWithSound

Label_9B33:
    BCS Label_9B8B
    LDX CurrentRuntimeObjectOffset
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
    JSR SampleCollisionAtPixel
    BPL Label_9B55
    JMP DestroyCurrentRuntimeObjectWithSound

Label_9B55:
    BCS Label_9B8B
    LDX CurrentRuntimeObjectOffset
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
    JSR SampleCollisionAtPixel
    BPL Label_9B77
    JMP DestroyCurrentRuntimeObjectWithSound

Label_9B77:
    BCS Label_9B8B
    LDX CurrentRuntimeObjectOffset
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
    JMP DestroyCurrentRuntimeObjectWithSound

Label_9B92:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BPL Label_9B9D
    JMP Label_9BED

Label_9B9D:
    JSR Func_9E7D
    BCS Label_9BE5
    LDA a:$07C6
    BNE Label_9BC4
    LDX CurrentRuntimeObjectOffset
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
    JSR SampleCollisionAtPixel
    BCC Label_9BE5

Label_9BC4:
    LDX CurrentRuntimeObjectOffset
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
    LDX CurrentRuntimeObjectOffset
    LDA #$FF
    STA RuntimeObjectState,X
    BNE Label_9BDF

Label_9BED:
    JSR Func_9E52
    BCS Label_9C31
    LDA a:$07C6
    BNE Label_9C14
    LDX CurrentRuntimeObjectOffset
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
    JSR SampleCollisionAtPixel
    BCC Label_9C31

Label_9C14:
    LDX CurrentRuntimeObjectOffset
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
    LDX CurrentRuntimeObjectOffset
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
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    CMP PlayerY
    BEQ Label_9C51
    RTS

Label_9C51:
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
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
    LDX CurrentRoomNumber
    LDA RoomObjectCounts - 1,X
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
    LDY CurrentRuntimeObjectOffset
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
    LDX CurrentRuntimeObjectOffset
    LDA PlayerY
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BCC Label_9CF5
    LDA #$7F
    STA a:$07C6

Label_9CF5:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectByte5,X
    BNE Label_9D1E
    JSR GetActivePlayerMotionState
    CMP #$14
    BCS Label_9D07
    JMP Func_9B00

Label_9D07:
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS Label_9D18
    JMP Func_9B00

Label_9D18:
    LDX CurrentRuntimeObjectOffset
    LDA #$0C
    STA RuntimeObjectByte5,X

Label_9D1E:
    DEC RuntimeObjectByte5,X
    LDA #$FF
    STA a:$07C6
    JSR Func_9B00
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS Label_9D64
    BMI Label_9D64
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS Label_9D64
    BMI Label_9D64
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel
    BCS Label_9D64
    BMI Label_9D64
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    CPY #$02
    BCC Label_9D64
    DEY
    DEY
    STY RuntimeObjectY,X

Label_9D64:
    RTS
    LDA NoiseSoundEffectRequest
    BNE Label_9D6C
    JSR StartNoiseSoundEffect4

Label_9D6C:
    LDX CurrentRuntimeObjectOffset
    LDA RoomFrameCounter
    AND #$01
    BEQ Label_9D76
    RTS

Label_9D76:
    LDA RuntimeObjectByte5,X
    BPL Label_9D7D
    JMP Label_9DC0

Label_9D7D:
    LDA PlayerXLo
    CMP RuntimeObjectXLo,X
    BNE Label_9D8F
    LDA PlayerXHi
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
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_9DA5
    INC RuntimeObjectXHi,X

Label_9DA5:
    RTS

Label_9DA6:
    LDX CurrentRuntimeObjectOffset
    LDA #$FF
    STA RuntimeObjectByte5,X
    RTS

Label_9DAD:
    JSR Func_9E52
    BCS Label_9DA6
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    BCS Label_9DBF
    DEC RuntimeObjectXHi,X

Label_9DBF:
    RTS

Label_9DC0:
    LDA PlayerY
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BEQ Label_9DD9

Label_9DC9:
    LDA RuntimeObjectState,X
    BMI Label_9DE6
    JSR Func_9DF2
    BCS Label_9DD9
    LDX CurrentRuntimeObjectOffset
    DEC RuntimeObjectY,X
    DEC RuntimeObjectY,X
    RTS

Label_9DD9:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectState,X
    EOR #$FF
    STA RuntimeObjectState,X
    LDA #$00
    STA RuntimeObjectByte5,X
    RTS

Label_9DE6:
    JSR Func_9E1F
    BCS Label_9DD9
    LDX CurrentRuntimeObjectOffset
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    RTS

Func_9DF2:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    CPY #$A0
    BCS Label_9E1E
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS Label_9E1E
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS Label_9E1E
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel

Label_9E1E:
    RTS

Func_9E1F:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    CMP #$A0
    BCS Label_9E51
    TAY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS Label_9E51
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS Label_9E51
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel

Label_9E51:
    RTS

Func_9E52:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel
    BCS Label_9E7C
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel
    BCS Label_9E7C
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel

Label_9E7C:
    RTS

Func_9E7D:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel
    BCS Label_9EA7
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel
    BCS Label_9EA7
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel

Label_9EA7:
    RTS

Func_9EA8:
    LDA PlayerXLo
    CLC
    SBC RuntimeObjectXLo,X
    STA $21
    LDA PlayerXHi
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
    LDX CurrentRuntimeObjectOffset
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
    JSR SampleCollisionAtPixel
    BCS Label_9F73
    LDY $16
    LDA $21
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR SampleCollisionAtPixel
    BCS Label_9F73
    LDA $16
    CLC
    ADC #$0F
    TAY
    LDX $21
    LDA $22
    JSR SampleCollisionAtPixel
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
    JSR SampleCollisionAtPixel
    BCS Label_9F73
    LDY CurrentRoomNumber
    LDX RoomObjectCounts - 1,Y
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
    JSR GetRuntimeObjectXPlus7
    BEQ Label_9F89
    CMP #$01
    BNE Label_9FB5
    CPX #$40
    BCS Label_9FB5

Label_9F89:
    STX $21
    STA $22
    STY $16
    JSR SampleCollisionAtPixel
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR SampleCollisionAtPixel
    BCS Label_9FB5
    BMI Label_9FB5
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$03
    STA RuntimeObjectXLo,X
    BCC Label_9FB4
    INC RuntimeObjectXHi,X

Label_9FB4:
    RTS

Label_9FB5:
    LDX CurrentRuntimeObjectOffset
    JMP ClearCurrentRuntimeObject

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
    JSR SampleCollisionAtPixel
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR SampleCollisionAtPixel
    BCS Label_9FB5
    BMI Label_9FB5
    LDX CurrentRuntimeObjectOffset
    LDA $21
    STA RuntimeObjectXLo,X
    LDA $22
    STA RuntimeObjectXHi,X
    RTS
