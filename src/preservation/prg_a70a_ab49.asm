; Preservation PRG before room metadata
; CPU range $A70A-$AB49
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_A70A:
    LDA #$04
    STA $2A
    LDA #$00
    STA $29
    STX $1F

Label_A714:
    LDY #$00
    LDA ($29),Y
    CMP #$54
    BEQ Label_A724
    JSR IsPersistentMutableCell
    BEQ Label_A724
    JMP Label_A7C7

Label_A724:
    DEX
    BEQ Label_A72A
    JMP Label_A7C7

Label_A72A:
    LDA $29
    BNE Label_A730
    DEC $2A

Label_A730:
    DEC $29
    LDY #$00
    LDA ($29),Y
    CMP #$16
    BEQ Label_A742
    LDY #$02
    LDA ($29),Y
    CMP #$16
    BNE Label_A757

Label_A742:
    INC $29
    BNE Label_A748
    INC $2A

Label_A748:
    LDY #$00
    LDA #$62
    STA ($29),Y
    LDY #$14
    LDA #$63
    STA ($29),Y
    JMP Label_A769

Label_A757:
    INC $29
    BNE Label_A75D
    INC $2A

Label_A75D:
    LDY #$00
    LDA #$54
    STA ($29),Y
    LDA #$55
    LDY #$14
    STA ($29),Y

Label_A769:
    LDA $29
    STA $44
    LDA $2A
    STA $45
    JSR Func_94AC
    DEC $1F
    LDA $1F
    AND #$07
    TAX
    LDA a:$A55B,X
    PHA
    LDA $1F
    LSR A
    LSR A
    LSR A
    TAX
    PLA
    ORA CurrentRoomMutableCellState,X
    STA CurrentRoomMutableCellState,X
    LDA $2A
    AND #$01
    STA $2A
    LDY #$07

Label_A794:
    LDA $29
    CMP #$14
    LDA $2A
    SBC #$00
    BCC Label_A7AC
    LDA $29
    SBC #$14
    STA $29
    INY
    BCS Label_A794
    DEC $2A
    JMP Label_A794

Label_A7AC:
    LDA $29
    ASL A
    CLC
    ADC #$04
    TAX
    JSR GetRoomAttributeMaskAndOffset
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributeScratch,X
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

Label_A7C7:
    INC $29
    BNE Label_A7CD
    INC $2A

Label_A7CD:
    LDA $29
    CMP #$90
    LDA $2A
    SBC #$05
    BCS Label_A7DA
    JMP Label_A714

Label_A7DA:
    RTS

Func_A7DB:
    LDA CurrentRoomIndex
    CMP #$0B
    BCC Label_A7E5
    SBC #$0A
    STA CurrentRoomIndex

Label_A7E5:
    RTS

Func_A7E6:
    LDA CurrentRoomIndex
    CMP #$5B
    BCS Label_A7F0
    ADC #$0A
    STA CurrentRoomIndex

Label_A7F0:
    RTS

Func_A7F1:
    LDA CurrentRoomIndex
    JSR Func_A80B
    BEQ Label_A7FD
    CLC
    ADC #$01
    STA CurrentRoomIndex

Label_A7FD:
    RTS

Func_A7FE:
    LDA CurrentRoomIndex
    JSR Func_A816
    BEQ Label_A80A
    SEC
    SBC #$01
    STA CurrentRoomIndex

Label_A80A:
    RTS

Func_A80B:
    LDX #$09

Label_A80D:
    CMP a:$A821,X
    BEQ Label_A815
    DEX
    BPL Label_A80D

Label_A815:
    RTS

Func_A816:
    LDX #$09

Label_A818:
    CMP a:$A82B,X
    BEQ Label_A820
    DEX
    BPL Label_A818

Label_A820:
    RTS
    .byte $0A, $14, $1E, $28, $32, $3C, $46, $50, $5A, $64, $01, $0B, $15, $1F, $29, $33
    .byte $3D, $47, $51, $5B

Func_A835:
    LDA $0E
    BEQ Label_A847
    LDA a:$076B
    AND #$1F
    BNE Label_A847
    DEC $0E
    BNE Label_A847
    JSR SelectRoomAudio

Label_A847:
    LDA $0D
    BEQ Label_A859
    LDA a:$076B
    AND #$1F
    BNE Label_A859
    DEC $0D
    BNE Label_A859
    JSR SelectRoomAudio

Label_A859:
    LDA a:$077C
    LDA $3A
    CLC
    ADC #$08
    TAY
    CPY #$10
    BCC Label_A87E
    CPY #$B0
    BCS Label_A87E
    LDA $38
    CLC
    ADC #$07
    TAX
    LDA $39
    ADC #$00
    BEQ Label_A883
    CMP #$01
    BNE Label_A87E
    CPX #$40
    BCC Label_A883

Label_A87E:
    LDA #$00
    JMP Label_A891

Label_A883:
    PHA
    TYA
    SEC
    SBC #$10
    TAY
    PLA
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y

Label_A891:
    LDX #$00
    CMP #$16
    BNE Label_A899
    LDX #$FF

Label_A899:
    CMP #$62
    BNE Label_A89F
    LDX #$FF

Label_A89F:
    CMP #$63
    BNE Label_A8A5
    LDX #$FF

Label_A8A5:
    STX a:$077C
    RTS

Func_A8A9:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    SEC
    SBC $3A
    BCS Label_A8B9
    EOR #$FF
    ADC #$01

Label_A8B9:
    CMP #$04
    BCS Label_A8E2
    LDA RuntimeObjectXLo,X
    SEC
    SBC $38
    STA $25
    LDA RuntimeObjectXHi,X
    SBC $39
    STA $26
    BCS Label_A8DA
    LDA $25
    EOR #$FF
    ADC #$01
    STA $25
    LDA $26
    EOR #$FF
    STA $26

Label_A8DA:
    BEQ Label_A8DE
    SEC
    RTS

Label_A8DE:
    LDA $25
    CMP #$05

Label_A8E2:
    RTS

Func_A8E3:
    LDA Controller1Buttons
    AND #$03
    BEQ Label_A8F6
    LDA a:$0777
    AND #$03
    BNE Label_A8F6
    LDA a:$07C4
    BNE Label_A912

Label_A8F6:
    LDA Controller1Buttons
    AND #$08
    BEQ Label_A91E
    LDA a:$0777
    AND #$08
    BNE Label_A91E
    LDA a:$07C4
    BNE Label_A912
    LDA #$00
    STA APU_STATUS
    LDA #$FF
    BNE Label_A914

Label_A912:
    LDA #$00

Label_A914:
    STA a:$07C4
    LDA Controller1Buttons
    STA a:$0777
    RTS

Label_A91E:
    LDA a:$07C4
    BNE Label_A924
    RTS

Label_A924:
    LDA Controller1Buttons
    AND #$40
    BEQ Label_A93D
    LDA $34
    SEC
    SBC #$04
    BCS Label_A934
    LDA #$00

Label_A934:
    STA $34
    LDA #$FF
    STA $36
    JMP Label_A953

Label_A93D:
    LDA Controller1Buttons
    AND #$80
    BEQ Label_A953
    LDA $34
    CLC
    ADC #$04
    BPL Label_A94D
    LDA #$80

Label_A94D:
    STA $34
    LDA #$FF
    STA $36

Label_A953:
    LDA Controller1Buttons
    STA a:$0777
    RTS
    .byte $01, $01, $01, $01, $01, $01
    ORA ($01,X)
    ORA ($01,X)
    ORA ($01,X)
    BRK
    .byte $01, $01, $00, $01, $01, $01, $01, $00, $01, $00, $00, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00
    .byte $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $00, $01, $01, $00, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $81, $81, $81, $81, $81, $81, $81
    .byte $81, $81, $81, $81, $81, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00
    .byte $01, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $20, $10, $10, $10, $08, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10
