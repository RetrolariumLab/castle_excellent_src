; Preservation PRG before shared screen palettes
; CPU range $B7FD-$C4FC
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

ReadDemoController1:
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
    LDA DemoPlaybackActive
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
    STA Pulse1SoundEffectBusy
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
    STA Pulse1SoundEffectBusy
    RTS

Func_C233:
    LDA #$0F
    STA APU_STATUS
    LDA #$02
    STA Pulse2SoundEffectBusy
    STA NoiseSoundEffectBusy
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
    STA Pulse2SoundEffectBusy
    STA NoiseSoundEffectBusy
    RTS

StartInventoryCollectibleSoundEffect:
    LDA #$0F
    STA APU_STATUS
    LDA #$03
    STA Pulse2SoundEffectBusy
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
    STA Pulse2SoundEffectBusy
    RTS

Func_C29A:
    LDA #$0F
    STA APU_STATUS
    LDA #$04
    STA NoiseSoundEffectBusy
    STA $F5
    LDA #$18
    STA APU_NOISE_VOL
    LDA #$0C
    STA APU_NOISE_LO
    LDA #$38
    STA APU_NOISE_HI
    LDA #$00
    STA $F6
    STA NoiseSoundEffectBusy
    RTS

StartMutableCellOpenSoundEffect:
    LDA #$0F
    STA APU_STATUS
    LDA #$05
    STA TriangleSoundEffectBusy
    STA NoiseSoundEffectBusy
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
    STA TriangleSoundEffectBusy
    STA NoiseSoundEffectBusy
    RTS

UpdateSoundEffects:
    LDA #$0F
    STA APU_STATUS
    LDA Pulse1SoundEffectBusy
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
    LDA Pulse2SoundEffectBusy
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
    LDA TriangleSoundEffectBusy
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
    LDA NoiseSoundEffectBusy
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

UpdateHorizontalScroll:
    LDA PauseMode
    BEQ Label_C443
    RTS

Label_C443:
    LDA PlayerXLo
    SEC
    SBC #$40
    STA $2B
    LDA PlayerXHi
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
    JSR DivideUnsigned16
    LDA $27
    STA $34

Label_C479:
    RTS

DivideUnsigned16:
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

UploadPaletteFromPointer:
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
