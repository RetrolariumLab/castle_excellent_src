; Preservation PRG after room-screen initialization
; CPU range $B7FD-$E45C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_B7FD:
    LDA #$2C
    STA $FD
    LDA #$B8
    STA $FE
    LDA #$00
    STA $FF
    RTS

Func_B80A:
    INC $FF
    LDA $FF
    CMP #$0C
    BCS Label_B820
    LDY #$00

Label_B814:
    LDA ($FD),Y
    CMP #$FF
    BNE Label_B81D
    JMP Reset

Label_B81D:
    AND #$F3
    RTS

Label_B820:
    INC $FD
    BNE Label_B826
    INC $FE

Label_B826:
    LDY #$00
    STY $FF
    BEQ Label_B814
    .byte $80, $80, $80, $80, $80, $80, $01, $01, $01, $01, $80, $80, $80, $80, $80, $80
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81, $81, $81, $81
    .byte $00, $41, $41, $41, $41, $41, $41, $43, $41, $43, $82, $40, $40, $40, $40, $40
    .byte $40, $40, $01, $01, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $FF

LoadAudioTrackSet0:
    LDX #$00
    BEQ Label_B88F

LoadAudioTrackSet1:
    LDX #$08
    BNE Label_B88F

LoadAudioTrackSet2:
    LDX #$10
    BNE Label_B88F

LoadAudioTrackSet3:
    LDX #$18
    BNE Label_B88F

LoadAudioTrackSet4:
    LDX #$20
    BNE Label_B88F

LoadAudioTrackSet5:
    LDX #$28
    BNE LoadAudioTrackSetByOffset

LoadAudioTrackSet7:
    LDX #$38

Label_B88F:
    LDA a:$07C7
    BEQ LoadAudioTrackSetByOffset
    RTS

LoadAudioTrackSetByOffset:
    LDA AudioTrackTable,X
    STA AudioStreamPointerLo
    LDA a:$B8C7,X
    STA AudioStreamPointerHi
    LDA a:$B8C8,X
    STA $DF
    LDA a:$B8C9,X
    STA $E0
    LDA a:$B8CA,X
    STA $E3
    LDA a:$B8CB,X
    STA $E4
    LDA a:$B8CC,X
    STA AudioPulseParameters
    LDA a:$B8CD,X
    STA $E8
    LDA #$01
    STA AudioStreamTicksRemaining
    STA $E1
    STA $E5
    RTS

AudioTrackTable:
    .byte $E7, $BB, $3F, $BC, $EE, $BC, $BF, $BB, $4F, $BD, $80, $BD, $B9, $BD, $BF, $BB
    .byte $F4, $BD, $F4, $BD, $38, $BE, $A9, $A9, $5D, $BE, $BC, $BE, $1B, $BF, $2F, $2B
    .byte $92, $BF, $FB, $BF, $5D, $C0, $3F, $3B, $A1, $C0, $DE, $C0, $17, $C1, $3F, $BB
    .byte $00, $00, $58, $C1, $58, $C1, $02, $02, $58, $C1, $85, $C1, $C2, $C1, $7F, $7F

StopAudioStreams:
    LDA #$00
    STA APU_STATUS
    STA AudioStreamPointerLo
    STA AudioStreamPointerHi
    STA $DF
    STA $E0
    STA $E3
    STA $E4
    RTS

ClearSoundRequests:
    LDA #$00
    STA $EC
    STA $EF
    STA $F2
    STA $F5
    RTS

UpdateAudioStreams:
    LDX #$00
    JSR UpdateAudioStream
    LDX #$04
    JSR UpdateAudioStream
    LDX #$08

UpdateAudioStream:
    LDA AudioStreamPointerLo,X
    ORA AudioStreamPointerHi,X
    BNE Label_B936
    RTS

Label_B936:
    DEC AudioStreamTicksRemaining,X
    BEQ Label_B95B
    LDA AudioStreamTicksRemaining,X
    CMP #$03
    BNE Label_B95A
    JSR ReadChannelSoundRequest
    BNE Label_B95A
    CPX #$00
    BNE Label_B94B
    LDA #$0E

Label_B94B:
    CPX #$04
    BNE Label_B951
    LDA #$0D

Label_B951:
    CPX #$08
    BNE Label_B957
    LDA #$0B

Label_B957:
    STA APU_STATUS

Label_B95A:
    RTS

Label_B95B:
    LDA (AudioStreamPointerLo,X)
    BNE Label_B962
    JMP Label_BA9D

Label_B962:
    JSR AdvanceAudioStream
    CMP #$6F
    BNE Label_B97E
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    SEC
    SBC #$32
    STA AudioStreamOctaveOffset,X
    ASL A
    CLC
    ADC AudioStreamOctaveOffset,X
    ASL A
    ASL A
    STA AudioStreamOctaveOffset,X
    JMP Label_B95B

Label_B97E:
    CMP #$74
    BNE Label_B992
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    SEC
    SBC #$30
    ASL A
    ASL A
    ASL A
    STA AudioTempoOffset
    JMP Label_B95B

Label_B992:
    CMP #$6C
    BNE Label_B9D2
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    CMP #$40
    BNE Label_B9A3
    LDA #$00
    BEQ Label_B9BD

Label_B9A3:
    CMP #$38
    BNE Label_B9AB
    LDA #$01
    BNE Label_B9BD

Label_B9AB:
    CMP #$34
    BNE Label_B9B3
    LDA #$02
    BNE Label_B9BD

Label_B9B3:
    CMP #$32
    BNE Label_B9BB
    LDA #$03
    BNE Label_B9BD

Label_B9BB:
    LDA #$04

Label_B9BD:
    CPX #$00
    BNE Label_B9C3
    STA AudioDefaultLengthIndices

Label_B9C3:
    CPX #$04
    BNE Label_B9C9
    STA $EA

Label_B9C9:
    CPX #$08
    BNE Label_B9CF
    STA $EB

Label_B9CF:
    JMP Label_B95B

Label_B9D2:
    CMP #$76
    BNE Label_B9DE
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    JMP Label_B95B

Label_B9DE:
    CMP #$61
    BCC Label_BA0D
    CMP #$68
    BCS Label_BA0D
    SEC
    SBC #$61
    TAY
    LDA NoteSemitoneOffsets,Y
    CLC
    ADC AudioStreamOctaveOffset,X
    TAY
    LDA (AudioStreamPointerLo,X)
    CMP #$2B
    BNE Label_B9FE
    INY
    JSR AdvanceAudioStream
    JMP Label_BA06

Label_B9FE:
    CMP #$2D
    BNE Label_BA06
    DEY
    JSR AdvanceAudioStream

Label_BA06:
    INY
    TYA
    ASL A
    TAY
    JMP Label_BA16

Label_BA0D:
    CMP #$72
    BEQ Label_BA14
    JMP Label_BAA0

Label_BA14:
    LDY #$00

Label_BA16:
    JSR ReadChannelSoundRequest
    BNE Label_BA35
    JSR ConfigureAudioChannel
    CPX #$08
    BNE Label_BA29
    TYA
    BEQ Label_BA29
    CLC
    ADC #$18
    TAY

Label_BA29:
    LDA ApuPeriodTable,Y
    STA APU_PL1_LO,X
    LDA a:$BB56,Y
    STA APU_PL1_HI,X

Label_BA35:
    CPX #$00
    BNE Label_BA3E
    LDA AudioDefaultLengthIndices
    JMP Label_BA49

Label_BA3E:
    CPX #$04
    BNE Label_BA47
    LDA $EA
    JMP Label_BA49

Label_BA47:
    LDA $EB

Label_BA49:
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    LDA (AudioStreamPointerLo,X)
    CMP #$40
    BEQ Label_BA60
    CMP #$30
    BCC Label_BA8B
    CMP #$3A
    BCS Label_BA8B

Label_BA60:
    CMP #$31
    BNE Label_BA66
    LDY #$04

Label_BA66:
    CMP #$32
    BNE Label_BA6C
    LDY #$03

Label_BA6C:
    CMP #$34
    BNE Label_BA72
    LDY #$02

Label_BA72:
    CMP #$38
    BNE Label_BA78
    LDY #$01

Label_BA78:
    CMP #$40
    BNE Label_BA7E
    LDY #$00

Label_BA7E:
    TYA
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

Label_BA8B:
    LDA (AudioStreamPointerLo,X)
    CMP #$2E
    BNE Label_BA9C
    LDA AudioStreamTicksRemaining,X
    LSR A
    CLC
    ADC AudioStreamTicksRemaining,X
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

Label_BA9C:
    RTS

Label_BA9D:
    JSR AdvanceAudioStream

Label_BAA0:
    LDA (AudioStreamPointerLo,X)
    PHA
    JSR AdvanceAudioStream
    ORA (AudioStreamPointerLo,X)
    TAY
    LDA (AudioStreamPointerLo,X)
    PHA
    TYA
    BNE Label_BAB6
    STA AudioStreamPointerLo,X
    STA AudioStreamPointerHi,X
    PLA
    PLA
    RTS

Label_BAB6:
    PLA
    STA AudioStreamPointerHi,X
    PLA
    STA AudioStreamPointerLo,X
    JMP Label_B95B

ReadChannelSoundRequest:
    CPX #$00
    BNE Label_BAC6
    LDA $EC
    RTS

Label_BAC6:
    CPX #$04
    BNE Label_BACD
    LDA $EF
    RTS

Label_BACD:
    CPX #$08
    BNE Label_BAD4
    LDA $F2
    RTS

Label_BAD4:
    LDA #$FF
    RTS

AdvanceAudioStream:
    INC AudioStreamPointerLo,X
    BNE Label_BADD
    INC AudioStreamPointerHi,X

Label_BADD:
    RTS
    .byte $C9, $3A, $B0, $04, $38, $E9, $30, $60, $E9, $57, $60

ConfigureAudioChannel:
    LDA #$0F
    STA APU_STATUS
    CPX #$00
    BNE Label_BAFD
    LDA AudioPulseParameters
    STA APU_PL1_VOL
    LDA #$08
    STA APU_PL1_SWEEP
    RTS

Label_BAFD:
    CPX #$04
    BNE Label_BB0C
    LDA $E8
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    RTS

Label_BB0C:
    CPX #$08
    BNE Label_BB15
    LDA #$FF
    STA APU_TRI_LINEAR

Label_BB15:
    RTS

NoteSemitoneOffsets:
    .byte $09, $0B, $00, $02, $04, $05, $07

NoteLengthTable:
    .byte $05, $0A, $14, $28, $50, $01, $01, $01, $06, $0C, $18, $30, $60, $01, $01, $01
    .byte $07, $0E, $1C, $38, $70, $01, $01, $01, $08, $10, $20, $40, $80, $01, $01, $01
    .byte $09, $12, $24, $48, $90, $01, $01, $01, $0A, $14, $28, $50, $A0, $01, $01, $01
    .byte $0B, $16, $2C, $58, $B0, $01, $01, $01

ApuPeriodTable:
    .byte $00, $00, $B3, $06, $53, $06, $F8, $05, $A3, $05, $52, $05, $06, $05, $BE, $04
    .byte $7A, $04, $3A, $04, $FD, $03, $C4, $03, $8E, $03, $59, $03, $29, $03, $FC, $02
    .byte $D1, $02, $A9, $02, $83, $02, $5F, $02, $3D, $02, $1D, $02, $FE, $01, $E2, $01
    .byte $C7, $01, $AC, $01, $94, $01, $7E, $01, $68, $01, $54, $01, $41, $01, $2F, $01
    .byte $1E, $01, $0E, $01, $FF, $00, $F1, $00, $E3, $00, $D6, $00, $CA, $00, $BF, $00
    .byte $B4, $00, $AA, $00, $A0, $00, $97, $00, $8F, $00, $87, $00, $7F, $00, $78, $00
    .byte $71, $00, $6B, $00, $65, $00, $5F, $00, $5A, $00, $55, $00, $50, $00, $4B, $00
    .byte $47, $00, $43, $00, $3F, $00, $3C, $00, $38, $00, $35, $00, $32, $00, $2F, $00
    .byte $2D, $00, $2A, $00, $28, $00, $25, $00, $23, $00, $21, $00, $1F, $00, $1E, $00
    .byte $1C, $00

MusicMmlData:
    .byte $74, $35, $76, $39, $6C, $38, $6F, $34, $63, $65, $67, $65, $66, $64, $67, $67
    .byte $63, $65, $67, $65, $66, $64, $67, $72, $38, $63, $65, $67, $65, $66, $64, $67
    .byte $67, $63, $65, $67, $65, $66, $64, $63, $38, $72, $38, $6F, $36, $63, $6F, $35
    .byte $62, $61, $67, $61, $67, $67, $67, $67, $66, $66, $66, $66, $65, $67, $72, $38
    .byte $6F, $36, $63, $6F, $35, $62, $61, $67, $61, $67, $67, $67, $67, $66, $65, $64
    .byte $63, $65, $63, $72, $38, $00, $E7, $BB, $76, $39, $6C, $40, $6F, $34, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $63, $6F, $34
    .byte $62, $61, $67, $66, $65, $64, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $63, $6F, $34, $62, $61, $67, $38, $72, $38, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $63, $6F, $34
    .byte $62, $61, $67, $66, $65, $64, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $6F, $34, $67, $61, $62, $6F, $35, $63, $38, $72, $38
    .byte $6F, $34, $63, $67, $65, $67, $64, $67, $63, $67, $64, $67, $63, $67, $65, $67
    .byte $63, $67, $65, $67, $66, $62, $64, $62, $66, $62, $64, $66, $65, $67, $63, $67
    .byte $65, $67, $63, $67, $65, $67, $64, $67, $63, $67, $64, $67, $63, $67, $65, $67
    .byte $63, $67, $64, $67, $64, $67, $65, $67, $64, $67, $65, $67, $63, $67, $6F, $35
    .byte $63, $38, $72, $38, $00, $3F, $BC, $6C, $38, $6F, $34, $63, $6F, $33, $67, $65
    .byte $67, $64, $66, $67, $62, $6F, $34, $63, $6F, $33, $67, $65, $67, $64, $66, $67
    .byte $62, $6F, $34, $63, $6F, $33, $67, $65, $67, $64, $66, $67, $62, $6F, $34, $63
    .byte $6F, $33, $67, $65, $67, $67, $62, $6F, $34, $63, $38, $72, $38, $6F, $33, $67
    .byte $67, $66, $65, $66, $65, $65, $65, $65, $64, $64, $64, $64, $63, $65, $72, $38
    .byte $67, $67, $66, $65, $66, $65, $65, $65, $64, $66, $67, $62, $6F, $34, $63, $6F
    .byte $33, $67, $63, $72, $38, $00, $EE, $BC, $74, $30, $6C, $38, $6F, $35, $63, $34
    .byte $65, $63, $64, $6F, $34, $67, $67, $34, $6F, $35, $63, $34, $65, $63, $64, $67
    .byte $67, $34, $63, $34, $65, $63, $64, $6F, $34, $67, $67, $34, $6F, $35, $63, $34
    .byte $65, $63, $64, $65, $63, $34, $00, $4F, $BD, $6C, $38, $76, $64, $6F, $34, $65
    .byte $67, $6F, $35, $63, $6F, $34, $67, $64, $67, $62, $67, $65, $67, $6F, $35, $63
    .byte $6F, $34, $67, $66, $67, $62, $67, $65, $67, $6F, $35, $63, $6F, $34, $67, $64
    .byte $67, $62, $67, $65, $67, $6F, $35, $63, $6F, $34, $67, $66, $67, $65, $34, $00
    .byte $80, $BD, $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65, $66, $67, $64, $62
    .byte $6F, $34, $63, $6F, $33, $65, $67, $6F, $34, $63, $6F, $33, $62, $67, $66, $64
    .byte $63, $67, $65, $67, $66, $67, $61, $62, $6F, $34, $63, $6F, $33, $65, $67, $6F
    .byte $34, $63, $6F, $33, $62, $67, $6F, $34, $63, $34, $00, $B9, $BD, $74, $32, $6C
    .byte $38, $6F, $35, $63, $2E, $63, $40, $64, $2E, $64, $40, $65, $2E, $65, $40, $66
    .byte $2E, $66, $40, $65, $34, $6F, $34, $67, $34, $6F, $35, $63, $34, $00, $00, $00
    .byte $6C, $38, $6F, $34, $65, $2E, $65, $40, $67, $2E, $67, $40, $6F, $35, $63, $2E
    .byte $63, $40, $63, $2E, $63, $40, $63, $34, $6F, $34, $67, $34, $67, $34, $00, $00
    .byte $00, $6C, $38, $6F, $35, $63, $2E, $63, $40, $6F, $34, $62, $2E, $62, $40, $61
    .byte $2E, $61, $40, $61, $2D, $2E, $61, $2D, $40, $67, $34, $66, $34, $65, $34, $6F
    .byte $32, $63, $32, $00, $00, $00, $74, $32, $6C, $38, $6F, $34, $67, $34, $62, $67
    .byte $66, $34, $61, $66, $67, $34, $62, $67, $61, $6F, $35, $64, $64, $34, $6F, $34
    .byte $67, $34, $62, $67, $66, $34, $61, $66, $67, $62, $6F, $35, $65, $64, $72, $32
    .byte $63, $34, $65, $63, $6F, $34, $62, $2D, $34, $6F, $35, $64, $6F, $34, $62, $2D
    .byte $6F, $35, $63, $34, $65, $63, $64, $67, $67, $34, $63, $34, $65, $63, $6F, $34
    .byte $62, $2D, $34, $6F, $35, $64, $6F, $34, $62, $2D, $6F, $35, $63, $65, $61, $67
    .byte $72, $32, $00, $5D, $BE, $6C, $38, $6F, $33, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $61, $34, $6F, $34, $63, $6F, $33, $61, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $6F, $34, $64, $6F, $33, $61, $61, $34, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $61, $34, $6F, $34, $63, $6F, $33, $61, $62, $6F, $34, $64, $61, $67, $72
    .byte $32, $65, $34, $67, $65, $64, $34, $66, $64, $65, $34, $67, $65, $67, $64, $64
    .byte $34, $65, $34, $67, $65, $64, $34, $66, $64, $65, $67, $6F, $35, $64, $63, $72
    .byte $32, $00, $BC, $BE, $6C, $38, $6F, $33, $67, $34, $64, $67, $66, $34, $63, $66
    .byte $67, $34, $64, $67, $66, $34, $64, $66, $67, $34, $64, $67, $66, $34, $63, $66
    .byte $67, $64, $6F, $34, $63, $6F, $33, $62, $72, $38, $6F, $32, $67, $72, $38, $67
    .byte $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D, $34, $66
    .byte $62, $2D, $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D
    .byte $34, $66, $62, $2D, $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33
    .byte $62, $2D, $34, $66, $62, $2D, $6F, $34, $63, $6F, $33, $67, $6F, $34, $66, $65
    .byte $72, $38, $6F, $32, $63, $72, $38, $63, $00, $1B, $BF, $74, $35, $76, $66, $6C
    .byte $40, $6F, $34, $67, $38, $61, $67, $66, $2B, $67, $6F, $35, $65, $34, $63, $38
    .byte $6F, $34, $62, $34, $61, $38, $6C, $34, $6F, $35, $64, $2E, $6C, $38, $6F, $34
    .byte $66, $67, $2E, $61, $40, $62, $6F, $35, $63, $2E, $64, $40, $63, $34, $64, $65
    .byte $34, $63, $6C, $40, $67, $38, $61, $67, $66, $2B, $67, $66, $34, $65, $38, $63
    .byte $2B, $34, $64, $38, $61, $34, $63, $38, $6C, $38, $6F, $34, $62, $61, $2E, $67
    .byte $40, $6F, $35, $66, $65, $2E, $64, $40, $63, $65, $67, $6F, $36, $63, $34, $72
    .byte $38, $00, $00, $00, $76, $66, $6C, $40, $6F, $34, $65, $38, $66, $65, $64, $2B
    .byte $65, $67, $34, $67, $38, $67, $34, $66, $38, $6C, $34, $61, $2E, $6C, $38, $64
    .byte $65, $2E, $66, $40, $67, $61, $2E, $66, $40, $65, $34, $66, $67, $34, $65, $6C
    .byte $40, $6F, $35, $65, $38, $66, $65, $64, $2B, $65, $63, $2B, $34, $6F, $34, $61
    .byte $38, $65, $34, $66, $38, $6F, $35, $63, $34, $6F, $34, $66, $2B, $38, $6C, $38
    .byte $67, $66, $2E, $64, $40, $62, $67, $2E, $66, $40, $65, $67, $6F, $35, $63, $65
    .byte $34, $72, $38, $00, $00, $00, $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65
    .byte $63, $65, $66, $63, $66, $63, $66, $65, $64, $66, $61, $67, $34, $64, $63, $65
    .byte $67, $38, $63, $65, $67, $62, $2D, $66, $62, $2D, $61, $34, $63, $2B, $64, $61
    .byte $64, $64, $2B, $66, $2B, $61, $67, $64, $67, $64, $67, $64, $63, $6F, $34, $63
    .byte $6F, $33, $67, $63, $34, $72, $38, $00, $00, $00, $74, $32, $76, $66, $6C, $38
    .byte $6F, $35, $63, $34, $2E, $6F, $34, $66, $67, $6F, $35, $63, $64, $34, $2E, $67
    .byte $34, $2E, $66, $65, $64, $65, $32, $2E, $67, $66, $2B, $67, $61, $2D, $32, $67
    .byte $61, $2D, $62, $2D, $32, $61, $62, $2D, $6F, $36, $63, $72, $6F, $35, $62, $2D
    .byte $6F, $36, $63, $31, $00, $00, $00, $76, $66, $6C, $38, $6F, $34, $67, $34, $2E
    .byte $63, $64, $67, $67, $34, $2E, $6F, $35, $64, $34, $2E, $64, $63, $6F, $34, $62
    .byte $2D, $6F, $35, $63, $2B, $32, $2E, $65, $64, $2B, $65, $63, $32, $6F, $34, $62
    .byte $6F, $35, $63, $64, $32, $63, $2B, $64, $67, $72, $66, $67, $31, $00, $00, $00
    .byte $6C, $38, $6F, $33, $63, $32, $2E, $6F, $32, $62, $32, $2E, $62, $2D, $34, $2E
    .byte $61, $6F, $33, $65, $67, $61, $34, $2E, $6F, $32, $61, $34, $2E, $61, $2D, $6F
    .byte $33, $63, $65, $2D, $61, $2D, $65, $2D, $63, $6F, $32, $62, $2D, $6F, $33, $64
    .byte $66, $62, $2D, $66, $64, $6F, $33, $63, $65, $67, $6F, $34, $63, $31, $00, $00
    .byte $00, $74, $30, $6C, $34, $6F, $34, $62, $2D, $6F, $35, $63, $64, $63, $64, $65
    .byte $64, $65, $66, $65, $66, $67, $61, $72, $34, $63, $62, $2D, $32, $61, $67, $66
    .byte $2B, $66, $65, $66, $67, $66, $31, $2E, $66, $31, $2E, $00, $00, $00, $6C, $34
    .byte $6F, $34, $67, $61, $62, $2D, $61, $62, $2D, $6F, $35, $63, $6F, $34, $62, $2D
    .byte $6F, $35, $63, $64, $63, $64, $65, $66, $72, $34, $6F, $34, $67, $66, $2B, $32
    .byte $66, $2B, $67, $67, $67, $67, $61, $62, $2D, $61, $67, $61, $62, $2D, $6F, $35
    .byte $63, $6F, $34, $62, $2D, $61, $31, $2E, $00, $00, $00, $6C, $34, $6F, $34, $72
    .byte $38, $67, $67, $67, $61, $61, $61, $38, $72, $38, $62, $2D, $62, $2D, $62, $2D
    .byte $6F, $35, $63, $63, $63, $38, $63, $72, $34, $6F, $34, $61, $6F, $35, $65, $2D
    .byte $32, $63, $6F, $34, $72, $38, $62, $2D, $62, $2D, $62, $2D, $6F, $35, $63, $63
    .byte $63, $38, $63, $6F, $34, $62, $2D, $6F, $35, $63, $64, $2D, $65, $2D, $64, $2D
    .byte $63, $31, $2E, $00, $00, $00

Func_C20D:
    LDA #$0F
    STA APU_STATUS
    LDA #$01
    STA a:$07D0
    STA $EC
    LDA #$DF
    STA APU_PL1_VOL
    LDA #$BA
    STA APU_PL1_SWEEP
    LDA #$40
    STA APU_PL1_LO
    LDA #$A0
    STA APU_PL1_HI
    LDA #$00
    STA a:$07D0
    RTS

Func_C233:
    LDA #$0F
    STA APU_STATUS
    LDA #$02
    STA a:$07D1
    STA a:$07D3
    STA $EF
    STA $F5
    LDA #$83
    STA APU_PL2_VOL
    LDA #$96
    STA APU_PL2_SWEEP
    LDA #$FF
    STA APU_PL2_LO
    LDA #$F1
    STA APU_PL2_HI
    LDA #$C1
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$F8
    STA APU_NOISE_HI
    LDA #$00
    STA $F0
    STA a:$07D1
    STA a:$07D3
    RTS

Func_C272:
    LDA #$0F
    STA APU_STATUS
    LDA #$03
    STA a:$07D1
    STA $EF
    LDA #$40
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    LDA #$50
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    LDA #$00
    STA $F0
    STA a:$07D1
    RTS

Func_C29A:
    LDA #$0F
    STA APU_STATUS
    LDA #$04
    STA a:$07D3
    STA $F5
    LDA #$18
    STA APU_NOISE_VOL
    LDA #$0C
    STA APU_NOISE_LO
    LDA #$38
    STA APU_NOISE_HI
    LDA #$00
    STA $F6
    STA a:$07D3
    RTS

Func_C2BD:
    LDA #$0F
    STA APU_STATUS
    LDA #$05
    STA a:$07D2
    STA a:$07D3
    STA $F2
    STA $F5
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$F0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    LDA #$00
    STA $F3
    STA $F6
    STA a:$07D2
    STA a:$07D3
    RTS

Func_C2F9:
    LDA #$0F
    STA APU_STATUS
    LDA a:$07D0
    BNE Label_C318
    LDA $EC
    BEQ Label_C318
    CMP #$01
    BNE Label_C318
    LDA APU_STATUS
    AND #$01
    BNE Label_C318
    LDA #$00
    STA $EC
    BEQ Label_C318

Label_C318:
    LDA a:$07D1
    BNE Label_C354
    LDA $EF
    BEQ Label_C354
    CMP #$03
    BNE Label_C347
    LDA APU_STATUS
    AND #$02
    BNE Label_C354
    INC $F0
    LDX $F0
    CPX #$04
    BCC Label_C33A
    LDA #$00
    STA $EF
    BEQ Label_C354

Label_C33A:
    LDA a:$C42D,X
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    BNE Label_C354

Label_C347:
    CMP #$02
    BNE Label_C354
    LDA APU_STATUS
    AND #$02
    BNE Label_C354
    STA $EF

Label_C354:
    LDA a:$07D2
    BNE Label_C3B5
    LDA $F2
    BEQ Label_C3B5
    CMP #$02
    BNE Label_C389
    LDA APU_STATUS
    AND #$04
    BNE Label_C3B5
    INC $F3
    LDX $F3
    CPX #$04
    BCC Label_C376
    LDA #$00
    STA $F2
    BEQ Label_C3B5

Label_C376:
    LDA #$3F
    STA APU_TRI_LINEAR
    LDA a:$C429,X
    STA APU_TRI_LO
    LDA #$59
    STA APU_TRI_HI
    JMP Label_C3B5

Label_C389:
    CMP #$05
    BNE Label_C3B5
    LDA APU_STATUS
    AND #$04
    BNE Label_C3B5
    INC $F3
    LDX $F3
    CPX #$02
    BCC Label_C3A3
    LDA #$00
    STA $F2
    JMP Label_C3B5

Label_C3A3:
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$A0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    JMP Label_C3B5

Label_C3B5:
    LDA a:$07D3
    BNE Label_C428
    LDA $F5
    BEQ Label_C428
    CMP #$04
    BNE Label_C3EF
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    INC $F6
    LDA $F6
    CMP #$04
    BCS Label_C3E9
    AND #$03
    TAX
    LDA a:$C431,X
    STA APU_NOISE_VOL
    LDA a:$C435,X
    STA APU_NOISE_LO
    LDA a:$C439,X
    STA APU_NOISE_HI
    JMP Label_C428

Label_C3E9:
    LDA #$00
    STA $F5
    BEQ Label_C428

Label_C3EF:
    CMP #$05
    BNE Label_C419
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    INC $F6
    LDX $F6
    CPX #$02
    BCC Label_C408
    LDA #$00
    STA $F5
    BEQ Label_C428

Label_C408:
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0D
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    BNE Label_C428

Label_C419:
    CMP #$02
    BNE Label_C428
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    LDA #$00
    STA $F5

Label_C428:
    RTS
    .byte $F0, $E0, $D0, $C0, $50, $3F, $3D, $35, $18, $1B, $1E, $03, $0C, $09, $06, $02
    .byte $38, $38, $58, $38

Func_C43D:
    LDA a:$07C4
    BEQ Label_C443
    RTS

Label_C443:
    LDA $38
    SEC
    SBC #$40
    STA $2B
    LDA $39
    SBC #$00
    BCS Label_C456

Label_C450:
    LDA #$00
    STA $34
    BEQ Label_C479

Label_C456:
    LDA $2B
    BEQ Label_C450
    CMP #$C0
    BCC Label_C464
    LDA #$80
    STA $34
    BNE Label_C479

Label_C464:
    ASL A
    STA $2B
    LDA #$00
    STA $2A
    ROL A
    STA $2C
    LDA #$03
    STA $29
    JSR Func_C47A
    LDA $27
    STA $34

Label_C479:
    RTS

Func_C47A:
    LDA $29
    ORA $2A
    BNE Label_C482
    SEC
    RTS

Label_C482:
    LDA #$01
    STA $25
    LDA #$00
    STA $26
    STA $28
    STA $27

Label_C48E:
    LDA $2A
    BMI Label_C49D
    ASL $29
    ROL $2A
    ASL $25
    ROL $26
    JMP Label_C48E

Label_C49D:
    LDA $2B
    CMP $29
    LDA $2C
    SBC $2A
    BCC Label_C4C0
    LDA $2B
    SBC $29
    STA $2B
    LDA $2C
    SBC $2A
    STA $2C
    LDA $25
    CLC
    ADC $27
    STA $27
    LDA $26
    ADC $28
    STA $28

Label_C4C0:
    LSR $2A
    ROR $29
    BCS Label_C4CC
    LSR $26
    ROR $25
    BCC Label_C49D

Label_C4CC:
    RTS

Func_C4CD:
    JSR DisableNmi
    JSR DisableRendering

Label_C4D3:
    LDA PPU_STATUS
    BPL Label_C4D3
    LDA #$3F
    STA PPU_ADDR
    LDY #$00
    STY PPU_ADDR

Label_C4E2:
    LDA ($21),Y
    STA PPU_DATA
    INY
    CPY #$20
    BCC Label_C4E2
    LDA #$3F
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    STA PPU_ADDR
    STA PPU_ADDR
    RTS
    .byte $0F, $16, $36, $30, $0F, $1A, $36, $30, $0F, $08, $17, $27, $0F, $00, $10, $30
    .byte $0F, $18, $28, $38, $0F, $00, $16, $30, $0F, $00, $2A, $30, $0F, $12, $22, $2A
    .byte $0F, $16, $10, $30, $0F, $18, $1A, $2A, $0F, $07, $17, $27, $0F, $12, $21, $28
    .byte $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A
    ROL $0F,X
    BIT $1A
    .byte $36

RoomPaletteData:
    .byte $0F, $12, $21, $30, $0F, $12, $21, $16, $0F, $1A, $28, $25, $0F, $08, $18, $20
    .byte $0F, $12, $21, $30, $0F, $16, $28, $20, $0F, $25, $1A, $36, $0F, $00, $10, $30

ResetPpuScroll:
    LDA PPU_STATUS
    LDA #$00
    STA PPU_SCROLL
    STA PPU_SCROLL
    RTS

Nmi:
    PHA
    TXA
    PHA
    TYA
    PHA
    LDA #$B0
    STA PPU_CTRL
    LDA a:$07C5
    BNE NmiFrame
    LDA $F8
    TAX
    LDA a:$C88E,X
    STA $FA
    LDA a:$C8A5,X
    STA $F9
    JMP ($00F9)

NmiFrame:
    LDA #$00
    STA OAM_ADDR
    LDA #$02
    STA OAM_DMA
    LDA #$B0
    STA PPU_CTRL
    LDA PPU_STATUS
    LDA #$00
    STA PPU_SCROLL
    STA PPU_SCROLL
    LDA $FB
    BEQ Label_C5A9
    JMP Func_C7AD

Label_C5A9:
    LDA #$FF
    STA $FB
    JSR BuildDmaOam
    LDA #$00
    STA $FB
    LDY #$04
    LDX #$40

Label_C5B8:
    DEX
    BNE Label_C5B8
    DEY
    BNE Label_C5B8

Label_C5BE:
    LDA $36
    BEQ Label_C5C6
    LDA $34
    STA $35

Label_C5C6:
    LDA a:$07C5
    BNE Label_C5DA
    LDA PPU_STATUS
    LDA $35
    STA PPU_SCROLL
    LDA #$00
    STA PPU_SCROLL
    STA $36

Label_C5DA:
    INC $00
    LDX $F8
    LDA #$00
    STA NmiTaskRequests,X
    CPX #$16
    BCC Label_C5ED

Label_C5E7:
    LDX #$00
    STX $F8
    BEQ Label_C5F9

Label_C5ED:
    INX
    CPX #$17
    BCS Label_C5E7
    LDA NmiTaskRequests,X
    BEQ Label_C5ED
    STX $F8

Label_C5F9:
    LDA $FC
    BEQ Label_C5FF
    DEC $FC

Label_C5FF:
    LDA a:$07C7
    BNE Label_C613
    JSR ReadController1
    STA Controller1Buttons
    JSR ReadController2
    STA Controller2Buttons
    JMP Label_C61E

Label_C613:
    JSR Func_B80A
    STA Controller1Buttons
    LDA #$00
    STA Controller2Buttons

Label_C61E:
    JSR ReadController1
    STA a:$07CE
    INC a:$0763
    LDA a:$0763
    CMP #$03
    BCC Label_C633
    LDA #$00
    STA a:$0763

Label_C633:
    INC a:$0764
    LDA a:$0764
    CMP #$05
    BCC Label_C642
    LDA #$00
    STA a:$0764

Label_C642:
    INC a:$0765
    LDA a:$0765
    CMP #$06
    BCC Label_C651
    LDA #$00
    STA a:$0765

Label_C651:
    INC a:$0766
    LDA a:$0766
    CMP #$07
    BCC Label_C660
    LDA #$00
    STA a:$0766

Label_C660:
    INC a:$0767
    LDA a:$0767
    CMP #$03
    BCC Label_C66F
    LDA #$00
    STA a:$0767

Label_C66F:
    INC a:$0768
    LDA a:$0768
    CMP #$0A
    BCC Label_C67E
    LDA #$00
    STA a:$0768

Label_C67E:
    INC a:$0769
    LDA a:$0769
    CMP #$0B
    BCC Label_C68D
    LDA #$00
    STA a:$0769

Label_C68D:
    INC a:$076A
    LDA a:$076A
    CMP #$1E
    BCC Label_C69C
    LDA #$00
    STA a:$076A

Label_C69C:
    LDA a:$07C4
    BNE Label_C6A7
    JSR UpdateAudioStreams
    JSR Func_C2F9

Label_C6A7:
    LDA $FB
    BNE Label_C6B3
    LDA $00
    LSR A
    BCC Label_C6B3
    JSR ReverseDmaOam

Label_C6B3:
    PLA
    TAY
    PLA
    TAX
    PLA

Irq:
    RTI

BuildDmaOam:
    LDX #$00

Label_C6BB:
    TXA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA $20
    LDA $00
    AND #$07
    CLC
    ADC $20
    TAY
    LDA a:$C79D,Y
    TAY
    LDA OamStagingBuffer,Y
    STA OamDmaBuffer,X
    LDA a:$0301,Y
    STA a:$0201,X
    LDA a:$0302,Y
    STA a:$0202,X
    LDA a:$0303,Y
    STA a:$0203,X
    LDA a:$0320,Y
    STA a:$0204,X
    LDA a:$0321,Y
    STA a:$0205,X
    LDA a:$0322,Y
    STA a:$0206,X
    LDA a:$0323,Y
    STA a:$0207,X
    LDA a:$0340,Y
    STA a:$0208,X
    LDA a:$0341,Y
    STA a:$0209,X
    LDA a:$0342,Y
    STA a:$020A,X
    LDA a:$0343,Y
    STA a:$020B,X
    LDA a:$0360,Y
    STA a:$020C,X
    LDA a:$0361,Y
    STA a:$020D,X
    LDA a:$0362,Y
    STA a:$020E,X
    LDA a:$0363,Y
    STA a:$020F,X
    LDA a:$0380,Y
    STA a:$0210,X
    LDA a:$0381,Y
    STA a:$0211,X
    LDA a:$0382,Y
    STA a:$0212,X
    LDA a:$0383,Y
    STA a:$0213,X
    LDA a:$03A0,Y
    STA a:$0214,X
    LDA a:$03A1,Y
    STA a:$0215,X
    LDA a:$03A2,Y
    STA a:$0216,X
    LDA a:$03A3,Y
    STA a:$0217,X
    LDA a:$03C0,Y
    STA a:$0218,X
    LDA a:$03C1,Y
    STA a:$0219,X
    LDA a:$03C2,Y
    STA a:$021A,X
    LDA a:$03C3,Y
    STA a:$021B,X
    LDA a:$03E0,Y
    STA a:$021C,X
    LDA a:$03E1,Y
    STA a:$021D,X
    LDA a:$03E2,Y
    STA a:$021E,X
    LDA a:$03E3,Y
    STA a:$021F,X
    TXA
    ADC #$20
    BEQ Label_C798
    TAX
    JMP Label_C6BB

Label_C798:
    LDA #$FF
    STA $36
    RTS
    .byte $00, $04, $08, $0C, $10, $14, $18, $1C, $00, $04, $08, $0C, $10, $14, $18, $1C

Func_C7AD:
    JSR ReverseDmaOam
    LDY #$03
    LDX #$72

Label_C7B4:
    DEX
    BNE Label_C7B4
    DEY
    BNE Label_C7B4
    JMP Label_C5BE

ReverseDmaOam:
    LDX #$00
    LDY #$FC

Label_C7C1:
    LDA OamDmaBuffer,X
    PHA
    LDA a:$0201,X
    PHA
    LDA a:$0202,X
    PHA
    LDA a:$0203,X
    PHA
    LDA OamDmaBuffer,Y
    STA OamDmaBuffer,X
    LDA a:$0201,Y
    STA a:$0201,X
    LDA a:$0202,Y
    STA a:$0202,X
    LDA a:$0203,Y
    STA a:$0203,X
    PLA
    STA a:$0203,Y
    PLA
    STA a:$0202,Y
    PLA
    STA a:$0201,Y
    PLA
    STA OamDmaBuffer,Y
    DEY
    DEY
    DEY
    DEY
    INX
    INX
    INX
    INX
    BPL Label_C7C1
    RTS
    LDA a:$07C8
    BEQ Label_C80C
    JMP Label_C8BC

Label_C80C:
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$96
    STA PPU_ADDR
    LDA StatusScoreTiles
    STA PPU_DATA
    LDA a:$079E
    STA PPU_DATA
    LDA a:$079F
    STA PPU_DATA
    LDA a:$07A0
    STA PPU_DATA
    LDA a:$07A1
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$87
    STA PPU_ADDR
    LDA a:$076C
    STA PPU_DATA
    LDA a:$076D
    STA PPU_DATA
    LDA a:$0771
    STA PPU_DATA
    LDA a:$0770
    STA PPU_DATA
    LDA a:$076F
    STA PPU_DATA
    LDA a:$076E
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A8
    STA PPU_ADDR
    LDA a:$07A6
    STA PPU_DATA
    LDA a:$07A5
    STA PPU_DATA
    LDY #$01
    LDX #$28

Label_C885:
    DEX
    BNE Label_C885
    DEY
    BNE Label_C885
    JMP NmiFrame
    .byte $C8, $C8, $C9, $CB, $CC, $CD, $CF, $D0, $D1, $D2, $D4, $D5, $D6, $D7, $D9, $DA
    .byte $DB, $DC, $DE, $DF, $E0, $E1, $E3, $04, $BC, $FF, $42, $85, $C8, $0B, $4E, $91
    .byte $D4, $17, $5A, $9D, $E0, $23, $66, $A9, $EC, $2F, $72, $B5, $F8, $58

Label_C8BC:
    LDA #$20
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX RoomCells
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0401
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0402
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0403
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0404
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0405
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0406
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0407
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0408
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0409
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$24
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$040E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0410
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0411
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0412
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0413
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$0414
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0415
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0416
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0417
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0418
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0419
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0420
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0421
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$0422
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0423
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0424
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0425
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0426
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0427
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$0428
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0429
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0430
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0431
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0432
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0433
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0434
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0435
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$0436
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0437
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0438
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0439
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$043C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0440
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0441
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0442
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0443
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0444
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0445
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0446
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0447
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0448
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0449
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$044A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX a:$0450
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0451
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0452
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0453
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0454
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0455
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0456
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0457
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0458
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0459
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX a:$045E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0460
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0461
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0462
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0463
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX a:$0464
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0465
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0466
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0467
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0468
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0469
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0470
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0471
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX a:$0472
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0473
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0474
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0475
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0476
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0477
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX a:$0478
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0479
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0480
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0481
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0482
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0483
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0484
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0485
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX a:$0486
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0487
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0488
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0489
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX a:$048C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0490
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0491
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0492
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0493
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0494
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0495
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0496
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0497
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0498
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0499
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX a:$049A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX a:$04A0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$04AE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$04B4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$04C2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$04C8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$04D6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$04DC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$04EA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04ED
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX a:$04F0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX a:$04FE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0500
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0501
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0502
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0503
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX a:$0504
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0505
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0506
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0507
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0508
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0509
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0510
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0511
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX a:$0512
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0513
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0514
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0515
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0516
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0517
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX a:$0518
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0519
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0520
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0521
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0522
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0523
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0524
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0525
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX a:$0526
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0527
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0528
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0529
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX a:$052C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0530
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0531
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0532
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0533
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0534
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0535
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0536
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0537
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0538
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0539
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX a:$053A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX a:$0540
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0541
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0542
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0543
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0544
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0545
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0546
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0547
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0548
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0549
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$054E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0550
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0551
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0552
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0553
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$0554
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0555
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0556
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0557
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0558
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0559
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0560
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0561
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$0562
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0563
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0564
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0565
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0566
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0567
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$0568
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0569
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0570
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0571
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0572
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0573
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0574
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0575
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$0576
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0577
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0578
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0579
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$057C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0580
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0581
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0582
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0583
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0584
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0585
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0586
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0587
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0588
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0589
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$058A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA a:$0108
    STA PPU_DATA
    LDA a:$0109
    STA PPU_DATA
    LDA a:$010A
    STA PPU_DATA
    LDA a:$010B
    STA PPU_DATA
    LDA a:$010C
    STA PPU_DATA
    LDA a:$010D
    STA PPU_DATA
    LDA a:$010E
    STA PPU_DATA
    LDA a:$010F
    STA PPU_DATA
    LDA a:$0110
    STA PPU_DATA
    LDA a:$0111
    STA PPU_DATA
    LDA a:$0112
    STA PPU_DATA
    LDA a:$0113
    STA PPU_DATA
    LDA a:$0114
    STA PPU_DATA
    LDA a:$0115
    STA PPU_DATA
    LDA a:$0116
    STA PPU_DATA
    LDA a:$0117
    STA PPU_DATA
    LDA a:$0118
    STA PPU_DATA
    LDA a:$0119
    STA PPU_DATA
    LDA a:$011A
    STA PPU_DATA
    LDA a:$011B
    STA PPU_DATA
    LDA a:$011C
    STA PPU_DATA
    LDA a:$011D
    STA PPU_DATA
    LDA a:$011E
    STA PPU_DATA
    LDA a:$011F
    STA PPU_DATA
    LDA a:$0120
    STA PPU_DATA
    LDA a:$0121
    STA PPU_DATA
    LDA a:$0122
    STA PPU_DATA
    LDA a:$0123
    STA PPU_DATA
    LDA a:$0124
    STA PPU_DATA
    LDA a:$0125
    STA PPU_DATA
    LDA a:$0126
    STA PPU_DATA
    LDA a:$0127
    STA PPU_DATA
    LDA a:$0128
    STA PPU_DATA
    LDA a:$0129
    STA PPU_DATA
    LDA a:$012A
    STA PPU_DATA
    LDA a:$012B
    STA PPU_DATA
    LDA a:$012C
    STA PPU_DATA
    LDA a:$012D
    STA PPU_DATA
    LDA a:$012E
    STA PPU_DATA
    LDA a:$012F
    STA PPU_DATA
    LDA a:$0130
    STA PPU_DATA
    LDA a:$0131
    STA PPU_DATA
    LDA a:$0132
    STA PPU_DATA
    LDA a:$0133
    STA PPU_DATA
    LDA a:$0134
    STA PPU_DATA
    LDA a:$0135
    STA PPU_DATA
    LDA a:$0136
    STA PPU_DATA
    LDA a:$0137
    STA PPU_DATA
    LDA a:$0138
    STA PPU_DATA
    LDA a:$0139
    STA PPU_DATA
    LDA a:$013A
    STA PPU_DATA
    LDA a:$013B
    STA PPU_DATA
    LDA a:$013C
    STA PPU_DATA
    LDA a:$013D
    STA PPU_DATA
    LDA a:$013E
    STA PPU_DATA
    LDA a:$013F
    STA PPU_DATA
    JMP NmiFrame
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA a:$0148
    STA PPU_DATA
    LDA a:$0149
    STA PPU_DATA
    LDA a:$014A
    STA PPU_DATA
    LDA a:$014B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0150
    STA PPU_DATA
    LDA a:$0151
    STA PPU_DATA
    LDA a:$0152
    STA PPU_DATA
    LDA a:$0153
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0158
    STA PPU_DATA
    LDA a:$0159
    STA PPU_DATA
    LDA a:$015A
    STA PPU_DATA
    LDA a:$015B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0160
    STA PPU_DATA
    LDA a:$0161
    STA PPU_DATA
    LDA a:$0162
    STA PPU_DATA
    LDA a:$0163
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0168
    STA PPU_DATA
    LDA a:$0169
    STA PPU_DATA
    LDA a:$016A
    STA PPU_DATA
    LDA a:$016B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0170
    STA PPU_DATA
    LDA a:$0171
    STA PPU_DATA
    LDA a:$0172
    STA PPU_DATA
    LDA a:$0173
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0178
    STA PPU_DATA
    LDA a:$0179
    STA PPU_DATA
    LDA a:$017A
    STA PPU_DATA
    LDA a:$017B
    STA PPU_DATA
    LDX #$19

Label_E457:
    DEX
    BNE Label_E457
    JMP NmiFrame
