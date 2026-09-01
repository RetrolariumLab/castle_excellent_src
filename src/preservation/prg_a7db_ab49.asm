; Preservation PRG after mutable-cell restoration
; CPU range $A7DB-$AB49
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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

UpdatePlayerCellState:
    LDA $0E
    BEQ Label_A847
    LDA RoomFrameCounter
    AND #$1F
    BNE Label_A847
    DEC $0E
    BNE Label_A847
    JSR SelectRoomAudio

Label_A847:
    LDA $0D
    BEQ Label_A859
    LDA RoomFrameCounter
    AND #$1F
    BNE Label_A859
    DEC $0D
    BNE Label_A859
    JSR SelectRoomAudio

Label_A859:
    LDA a:$077C
    LDA PlayerY
    CLC
    ADC #$08
    TAY
    CPY #$10
    BCC Label_A87E
    CPY #$B0
    BCS Label_A87E
    LDA PlayerXLo
    CLC
    ADC #$07
    TAX
    LDA PlayerXHi
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
    SBC PlayerY
    BCS Label_A8B9
    EOR #$FF
    ADC #$01

Label_A8B9:
    CMP #$04
    BCS Label_A8E2
    LDA RuntimeObjectXLo,X
    SEC
    SBC PlayerXLo
    STA $25
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
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

HandlePauseInput:
    LDA Controller1Buttons
    AND #$03
    BEQ Label_A8F6
    LDA PreviousController1Buttons
    AND #$03
    BNE Label_A8F6
    LDA PauseMode
    BNE Label_A912

Label_A8F6:
    LDA Controller1Buttons
    AND #$08
    BEQ Label_A91E
    LDA PreviousController1Buttons
    AND #$08
    BNE Label_A91E
    LDA PauseMode
    BNE Label_A912
    LDA #$00
    STA APU_STATUS
    LDA #$FF
    BNE Label_A914

Label_A912:
    LDA #$00

Label_A914:
    STA PauseMode
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

Label_A91E:
    LDA PauseMode
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
    STA PreviousController1Buttons
    RTS
    .byte $01, $01, $01, $01, $01, $01
    ORA (HighScoreLo,X)
    ORA (HighScoreLo,X)
    ORA (HighScoreLo,X)
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
