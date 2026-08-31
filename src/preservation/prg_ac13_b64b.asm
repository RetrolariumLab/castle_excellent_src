; Preservation PRG before room-screen initialization
; CPU range $AC13-$B64B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

BuildFrameSprites:
    LDA #$FF
    STA OamStagingBusy
    LDX #$00
    LDA #$F0

Label_AC1B:
    STA OamStagingBuffer,X
    INX
    BNE Label_AC1B
    JSR Func_AC60
    JSR Func_AD54
    LDX #$0C
    STX $16
    LDY #$00
    STY CurrentObjectOffset

Label_AC2F:
    LDY CurrentObjectOffset
    LDA a:RuntimeObjectY,Y
    CMP #$A0
    BCS Func_AC50
    LDA a:RuntimeObjectRecords,Y
    BEQ Func_AC50
    AND #$7F
    ASL A
    TAY
    LDA ObjectHandlerTable,Y
    STA $31
    LDA a:$AD94,Y
    STA $32
    LDX CurrentObjectOffset
    JMP ($0031)

Func_AC50:
    LDA CurrentObjectOffset
    CLC
    ADC #$06
    STA CurrentObjectOffset
    CMP #$90
    BCC Label_AC2F
    LDA #$00
    STA OamStagingBusy
    RTS

Func_AC60:
    LDA a:$0772
    BEQ Label_AC9E
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AC78
    LDX #$B4
    LDY #$E6
    JSR Func_B457
    JMP Label_AD4F

Label_AC78:
    CMP #$01
    BNE Label_AC86
    LDX #$B4
    LDY #$EA
    JSR Func_B457
    JMP Label_AD4F

Label_AC86:
    CMP #$02
    BNE Label_AC94
    LDX #$B4
    LDY #$EE
    JSR Func_B457
    JMP Label_AD4F

Label_AC94:
    LDX #$B4
    LDY #$F2
    JSR Func_B457
    JMP Label_AD4F

Label_AC9E:
    LDA $3B
    BNE Label_ACBC
    LDA $3C
    ORA $3E
    BNE Label_ACB2
    LDX #$B4
    LDY #$C2
    JSR Func_B457
    JMP Label_AD4F

Label_ACB2:
    LDX #$B4
    LDY #$D6
    JSR Func_B457
    JMP Label_AD4F

Label_ACBC:
    BMI Label_AD08
    LDA $3C
    ORA $3E
    BEQ Label_ACCE
    LDX #$B4
    LDY #$C6
    JSR Func_B457
    JMP Label_AD4F

Label_ACCE:
    LDA a:$0779
    BEQ Label_ACDD
    LDX #$B4
    LDY #$DE
    JSR Func_B457
    JMP Label_AD4F

Label_ACDD:
    LDA FrameCounter
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE Label_ACF0
    LDX #$B4
    LDY #$B6
    JSR Func_B457
    JMP Label_AD4F

Label_ACF0:
    CMP #$02
    BNE Label_ACFE
    LDX #$B4
    LDY #$BE
    JSR Func_B457
    JMP Label_AD4F

Label_ACFE:
    LDX #$B4
    LDY #$BA
    JSR Func_B457
    JMP Label_AD4F

Label_AD08:
    LDA $3C
    ORA $3E
    BEQ Label_AD18
    LDX #$B4
    LDY #$DA
    JSR Func_B457
    JMP Label_AD4F

Label_AD18:
    LDA a:$0779
    BEQ Label_AD27
    LDX #$B4
    LDY #$E2
    JSR Func_B457
    JMP Label_AD4F

Label_AD27:
    LDA FrameCounter
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE Label_AD3A
    LDX #$B4
    LDY #$CA
    JSR Func_B457
    JMP Label_AD4F

Label_AD3A:
    CMP #$02
    BNE Label_AD48
    LDX #$B4
    LDY #$D2
    JSR Func_B457
    JMP Label_AD4F

Label_AD48:
    LDX #$B4
    LDY #$CE
    JSR Func_B457

Label_AD4F:
    LDA #$00
    STA $3E
    RTS

Func_AD54:
    LDA a:$0779
    BNE Label_AD5A
    RTS

Label_AD5A:
    LDA $3B
    BNE Label_AD5F
    RTS

Label_AD5F:
    BMI Label_AD7B
    LDA OamStagingBuffer
    STA OamStagingBuffer + $08
    LDA OamStagingBuffer + $03
    CLC
    ADC #$0F
    STA OamStagingBuffer + $0B
    LDA #$CA
    STA OamStagingBuffer + $09
    LDA #$03
    STA OamStagingBuffer + $0A
    RTS

Label_AD7B:
    LDA OamStagingBuffer
    STA OamStagingBuffer + $08
    LDA OamStagingBuffer + $03
    SEC
    SBC #$07
    STA OamStagingBuffer + $0B
    LDA #$CA
    STA OamStagingBuffer + $09
    LDA #$43

ObjectHandlerTable = * + 2  ; overlapping entry $AD93
    STA OamStagingBuffer + $0A
    RTS
    .byte $E7, $AD, $08, $AE, $12, $AE, $19, $AE, $75, $AE, $BB, $AE, $1E, $AF, $6A, $AF
    .byte $B0, $AF, $F4, $AF, $FB, $AF, $02, $B0, $09, $B0, $10, $B0, $17, $B0, $2B, $B0
    .byte $35, $B0, $3C, $B0, $43, $B0, $4A, $B0, $51, $B0, $58, $B0, $5F, $B0, $66, $B0
    .byte $6D, $B0, $74, $B0, $7B, $B0, $82, $B0, $89, $B0, $89, $B0, $90, $B0, $AC, $B0
    .byte $C9, $B0, $D0, $B0, $DA, $B0, $E1, $B0, $E8, $B0, $EF, $B0, $14, $B1, $17, $B1
    .byte $35, $B1, $AD, $6B, $07, $4A, $29, $03, $D0, $07, $A2, $B5, $A0, $94, $4C, $0C
    .byte $AE, $C9, $02, $D0, $07, $A2, $B5, $A0, $9C, $4C, $0C, $AE, $A2, $B5, $A0, $98
    .byte $4C, $0C, $AE, $A2, $B5, $A0, $AC

Label_AE0C:
    JSR Func_B1D6
    JMP Func_AC50
    .byte $A2, $B5, $A0, $BC, $4C, $0C, $AE, $B5, $4E, $30, $2C, $B5, $4F, $F0, $07, $A2
    .byte $B5, $A0, $0E, $4C, $0C, $AE, $A5, $00, $4A, $4A, $29, $03, $D0, $07, $A2, $B4
    .byte $A0, $F6, $4C, $0C, $AE, $C9, $02, $D0, $07, $A2, $B4, $A0, $FE, $4C, $0C, $AE
    .byte $A2, $B4, $A0, $FA, $4C, $0C, $AE, $B5, $4F, $F0, $07, $A2, $B5, $A0, $12, $4C
    .byte $0C, $AE, $A5, $00, $4A, $4A, $29, $03, $D0, $07, $A2, $B5, $A0, $02, $4C, $0C
    .byte $AE, $C9, $02, $D0, $07, $A2, $B5, $A0, $0A, $4C, $0C, $AE, $A2, $B5, $A0, $06
    .byte $4C, $0C, $AE
    LDA RuntimeObjectState,X
    BMI Label_AE9A
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AE88
    LDX #$B5
    LDY #$16
    JMP Label_AE0C

Label_AE88:
    CMP #$02
    BNE Label_AE93
    LDX #$B5
    LDY #$1E
    JMP Label_AE0C

Label_AE93:
    LDX #$B5
    LDY #$1A
    JMP Label_AE0C

Label_AE9A:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AEA9
    LDX #$B5
    LDY #$22
    JMP Label_AE0C

Label_AEA9:
    CMP #$02
    BNE Label_AEB4
    LDX #$B5
    LDY #$2A
    JMP Label_AE0C

Label_AEB4:
    LDX #$B5
    LDY #$26
    JMP Label_AE0C
    LDA RoomFrameCounter
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #$08
    BCS Label_AEDE
    LDA RuntimeObjectXLo,X
    ORA #$04
    STA RuntimeObjectXLo,X
    LDX #$B5
    LDY #$2E
    JSR Func_B265
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    AND #$F8
    STA RuntimeObjectXLo,X
    JMP Func_AC50

Label_AEDE:
    CMP #$08
    BEQ Label_AEE6
    CMP #$0F
    BNE Label_AEED

Label_AEE6:
    LDX #$B5
    LDY #$30
    JMP Label_AE0C

Label_AEED:
    CMP #$09
    BEQ Label_AEF5
    CMP #$0E
    BNE Label_AEFC

Label_AEF5:
    LDX #$B5
    LDY #$34
    JMP Label_AE0C

Label_AEFC:
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AF0C
    LDX #$B5
    LDY #$38
    JMP Label_AE0C

Label_AF0C:
    AND #$01
    BEQ Label_AF17
    LDX #$B5
    LDY #$3C
    JMP Label_AE0C

Label_AF17:
    LDX #$B5
    LDY #$40
    JMP Label_AE0C
    LDA RuntimeObjectState,X
    BMI Label_AF46
    LDA FrameCounter
    CLC
    ADC RuntimeObjectByte5,X
    LSR A
    LSR A
    AND #$03
    BNE Label_AF34
    LDX #$B5
    LDY #$44
    JMP Label_AE0C

Label_AF34:
    CMP #$02
    BNE Label_AF3F
    LDX #$B5
    LDY #$4C
    JMP Label_AE0C

Label_AF3F:
    LDX #$B5
    LDY #$48
    JMP Label_AE0C

Label_AF46:
    LDA FrameCounter
    CLC
    ADC RuntimeObjectByte5,X
    LSR A
    LSR A
    AND #$03
    BNE Label_AF58
    LDX #$B5
    LDY #$50
    JMP Label_AE0C

Label_AF58:
    CMP #$02
    BNE Label_AF63
    LDX #$B5
    LDY #$58
    JMP Label_AE0C

Label_AF63:
    LDX #$B5
    LDY #$54
    JMP Label_AE0C
    LDA RuntimeObjectState,X
    BMI Label_AF8F
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AF7D
    LDX #$B5
    LDY #$5C
    JMP Label_AE0C

Label_AF7D:
    CMP #$02
    BNE Label_AF88
    LDX #$B5
    LDY #$64
    JMP Label_AE0C

Label_AF88:
    LDX #$B5
    LDY #$60
    JMP Label_AE0C

Label_AF8F:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AF9E
    LDX #$B5
    LDY #$6C
    JMP Label_AE0C

Label_AF9E:
    CMP #$02
    BNE Label_AFA9
    LDX #$B5
    LDY #$74
    JMP Label_AE0C

Label_AFA9:
    LDX #$B5
    LDY #$70
    JMP Label_AE0C
    LDA RuntimeObjectState,X
    BPL Label_AFD3
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AFC3
    LDX #$B5
    LDY #$88
    JMP Label_AE0C

Label_AFC3:
    CMP #$02
    LDX #$B5
    LDY #$90
    JMP Label_AE0C
    .byte $A2, $B5, $A0, $8C, $4C, $0C, $AE

Label_AFD3:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE Label_AFE2
    LDX #$B5
    LDY #$7C
    JMP Label_AE0C

Label_AFE2:
    CMP #$02
    BNE Label_AFED
    LDX #$B5
    LDY #$84
    JMP Label_AE0C

Label_AFED:
    LDX #$B5
    LDY #$80
    JMP Label_AE0C
    LDX #$B5
    LDY #$C0
    JMP Label_AE0C
    LDX #$B5
    LDY #$C4
    JMP Label_AE0C
    LDX #$B5
    LDY #$C8
    JMP Label_AE0C
    LDX #$B5
    LDY #$CC
    JMP Label_AE0C
    LDX #$B5
    LDY #$D0
    JMP Label_AE0C
    LDA FrameCounter
    AND #$08
    BNE Label_B024
    LDX #$B5
    LDY #$D4
    JMP Label_AE0C

Label_B024:
    LDX #$B5
    LDY #$D8
    JMP Label_AE0C
    LDX #$B5
    LDY #$B0

Label_B02F:
    JSR Func_B265
    JMP Func_AC50
    LDX #$B5
    LDY #$B2
    JMP Label_B02F
    LDX #$B5
    LDY #$B4
    JMP Label_B02F
    LDX #$B5
    LDY #$B6
    JMP Label_B02F
    LDX #$B5
    LDY #$B8
    JMP Label_B02F
    LDX #$B5
    LDY #$BA
    JMP Label_B02F
    LDX #$B5
    LDY #$DC
    JMP Label_AE0C
    LDX #$B5
    LDY #$E0
    JMP Label_AE0C
    LDX #$B5
    LDY #$E4
    JMP Label_AE0C
    LDX #$B5
    LDY #$E8
    JMP Label_AE0C
    LDX #$B5
    LDY #$EC
    JMP Label_AE0C
    LDX #$B5
    LDY #$F0
    JMP Label_AE0C
    LDX #$B5
    LDY #$F4
    JMP Label_AE0C
    LDX #$B5
    LDY #$FC
    JMP Label_AE0C
    LDA RoomFrameCounter
    BMI Label_B098
    JMP Func_AC50

Label_B098:
    LDA RoomFrameCounter
    LSR A
    BCC Label_B0A5
    LDX #$B6
    LDY #$08
    JMP Label_AE0C

Label_B0A5:
    LDX #$B6
    LDY #$0C
    JMP Label_AE0C
    LDX FrameCounterModulo3A
    BNE Label_B0B8
    LDX #$B5
    LDY #$FC
    JMP Label_AE0C

Label_B0B8:
    DEX
    BNE Label_B0C2
    LDX #$B6
    LDY #$00
    JMP Label_AE0C

Label_B0C2:
    LDX #$B6
    LDY #$04
    JMP Label_AE0C
    LDX #$B6
    LDY #$18
    JMP Label_AE0C
    LDX #$B6
    LDY #$10
    JSR Func_B2AF
    JMP Func_AC50
    LDX #$B6
    LDY #$20
    JMP Label_AE0C
    LDX #$B6
    LDY #$24
    JMP Label_AE0C
    LDX #$B6
    LDY #$28
    JMP Label_AE0C
    LDA RuntimeObjectY,X
    SEC
    SBC #$0B
    STA RuntimeObjectY,X
    LDA RuntimeObjectState,X
    BMI Label_B104
    LDX #$B6
    LDY #$2E
    JSR Func_B265
    JMP Label_B10B

Label_B104:
    LDX #$B6
    LDY #$2C
    JSR Func_B265

Label_B10B:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0B
    STA RuntimeObjectY,X
    JMP Func_AC50
    LDA RuntimeObjectState,X
    LSR A
    BNE Label_B123
    LDX #$B6
    LDY #$30
    JMP Label_AE0C

Label_B123:
    CMP #$01
    BNE Label_B12E
    LDX #$B6
    LDY #$34
    JMP Label_AE0C

Label_B12E:
    LDX #$B6
    LDY #$38
    JMP Label_AE0C
    LDA RuntimeObjectState,X
    CMP #$01
    BNE Label_B145
    LDX #$B6
    LDY #$3C
    JSR Func_B265
    JMP Func_AC50

Label_B145:
    CMP #$02
    BNE Label_B153
    LDX #$B6
    LDY #$40
    JSR Func_B265
    JMP Func_AC50

Label_B153:
    CMP #$03
    BNE Label_B161
    LDX #$B6
    LDY #$44
    JSR Func_B265
    JMP Func_AC50

Label_B161:
    CMP #$04
    BNE Label_B16F
    LDX #$B6
    LDY #$48
    JSR Func_B265
    JMP Func_AC50

Label_B16F:
    CMP #$05
    BNE Label_B17D
    LDX #$B6
    LDY #$3C
    JSR Func_B3C8
    JMP Func_AC50

Label_B17D:
    CMP #$06
    BNE Label_B18B
    LDX #$B6
    LDY #$40
    JSR Func_B3C8
    JMP Func_AC50

Label_B18B:
    CMP #$07
    BNE Label_B199
    LDX #$B6
    LDY #$44
    JSR Func_B3C8
    JMP Func_AC50

Label_B199:
    CMP #$08
    BNE Label_B1A7
    LDX #$B6
    LDY #$48
    JSR Func_B3C8
    JMP Func_AC50

Label_B1A7:
    CMP #$09
    BNE Label_B1B2
    LDX #$B6
    LDY #$3C
    JMP Label_AE0C

Label_B1B2:
    CMP #$0A
    BNE Label_B1BD
    LDX #$B6
    LDY #$40
    JMP Label_AE0C

Label_B1BD:
    CMP #$0B
    BNE Label_B1C8
    LDX #$B6
    LDY #$44
    JMP Label_AE0C

Label_B1C8:
    CMP #$0C
    BNE Label_B1D3
    LDX #$B6
    LDY #$48
    JSR Func_B1D6

Label_B1D3:
    JMP Func_AC50

Func_B1D6:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B21F
    BNE Label_B21F
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B21F:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$28
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B264
    BNE Label_B264
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B264:
    RTS

Func_B265:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B2AE
    BNE Label_B2AE
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    INX
    INX
    INX
    INX
    STX $16

Label_B2AE:
    RTS

Func_B2AF:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B2F8
    BNE Label_B2F8
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B2F8:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$28
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B33D
    BNE Label_B33D
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B33D:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$30
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B382
    BNE Label_B382
    LDX $16
    LDY #$04
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$05
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B382:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$38
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B3C7
    BNE Label_B3C7
    LDX $16
    LDY #$06
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$07
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B3C7:
    RTS

Func_B3C8:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B411
    BNE Label_B411
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B411:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$24
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B456
    BNE Label_B456
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA ($21),Y
    STA OamStagingBuffer + $02,X
    LDA $1B
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B456:
    RTS

Func_B457:
    STX $22
    STY $21
    LDA $38
    CLC
    ADC #$20
    STA $2B
    LDA $39
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B4B5
    BNE Label_B4B5
    LDA $18
    ASL A
    ASL A
    TXA
    LDY #$00
    LDA ($21),Y
    STA OamStagingBuffer + $01
    LDY #$01
    LDA ($21),Y
    STA OamStagingBuffer + $02
    LDY #$02
    LDA ($21),Y
    STA OamStagingBuffer + $05
    LDY #$03
    LDA ($21),Y
    STA OamStagingBuffer + $06
    LDA $3A
    CLC
    ADC #$27
    STA OamStagingBuffer
    STA OamStagingBuffer + $04
    LDA $1B
    STA OamStagingBuffer + $03
    CLC
    ADC #$08
    STA OamStagingBuffer + $07
    BCC Label_B4B5
    LDA #$F0
    STA OamStagingBuffer + $04

Label_B4B5:
    RTS
    .byte $90, $02, $92, $02, $94, $02, $96, $02, $98, $02, $9A, $02, $A4, $02, $A6, $02
    .byte $9C, $02, $9E, $02, $92, $42, $90, $42, $96, $42, $94, $42, $9A, $42, $98, $42
    .byte $A0, $02, $A2, $02, $9E, $42, $9C, $42, $B0, $02, $B2, $02, $B2, $42, $B0, $42
    .byte $C0, $02, $C2, $02, $C4, $02, $C6, $02, $FA, $02, $FC, $02, $8A, $02, $8C, $02
    .byte $00, $01, $02, $01, $04, $01, $06, $01, $08, $01, $0A, $01, $02, $41, $00, $41
    .byte $06, $41, $04, $41, $0A, $41, $08, $41, $A8, $01, $AA, $01, $AA, $41, $A8, $41
    .byte $24, $02, $26, $02, $28, $02, $2A, $02, $2C, $02, $2E, $02
    ROL $42
    BIT $42
    ROL A
    .byte $42, $28, $42, $2E, $42, $2C, $42, $30, $02, $32, $02, $32, $42, $34, $02, $34
    .byte $42, $36, $02, $36, $42, $38, $02, $38, $42, $3A, $02, $3A, $42, $18, $03, $1A
    .byte $03, $1C, $03, $1E, $03, $20, $03, $22, $03, $1A, $43, $18, $43, $1E, $43, $1C
    .byte $43, $22, $43, $20, $43, $0C, $00, $0E, $00, $10, $00, $12, $00, $14, $00, $16
    .byte $00, $AC, $00, $AE, $00, $0E, $40, $0C, $40, $12, $40, $10, $40, $16, $40, $14
    .byte $40, $AE, $40, $AC, $40, $48, $01, $4A, $01, $4C, $01, $4E, $01, $50, $01, $52
    .byte $01, $4A, $41, $48, $41, $4E, $41, $4C, $41, $52, $41, $50, $41, $54, $02, $56
    .byte $02, $58, $02, $5A, $02, $5C, $02, $5E, $02, $56, $42, $54, $42, $5A, $42, $58
    .byte $42, $5E, $42, $5C, $42, $F6, $02, $F8, $02, $D8, $00, $D8, $01, $D8, $02, $DA
    .byte $02, $DA, $00, $DA, $01, $82, $00, $82, $40, $6C, $01, $6C, $41, $74, $01, $76
    .byte $01, $70, $03, $72, $03, $6E, $01, $6E, $C1, $7C, $03, $7E, $03, $60, $01, $62
    .byte $01, $78, $01, $7A, $01, $64, $00, $66, $00, $68, $00, $6A, $00, $D0, $00, $D0
    .byte $40, $D2, $01, $D2, $41, $CC, $01, $CE, $01, $68, $00, $6A, $00, $68, $00, $6A
    .byte $00, $68, $00, $6A, $00, $B4, $03, $B6, $03, $B8, $03, $BA, $03, $BC, $03, $BE
    .byte $03, $FE, $01, $FE, $41, $FE, $41, $FE, $01, $84, $00, $86, $00, $D6, $00, $F2
    .byte $00, $88, $00, $D4, $00, $8A, $03, $8C, $00, $8E, $03, $8E, $43, $E2, $00, $E2
    .byte $40, $E4, $00, $E4, $40, $C8, $03, $C8, $43, $DC, $01, $DC, $41, $DE, $01, $DE
    .byte $41, $E0, $01, $E0, $41, $E8, $00, $E6, $00, $EA, $00, $E6, $00, $EC, $00, $E6
    .byte $00, $EE, $00, $E6, $00
