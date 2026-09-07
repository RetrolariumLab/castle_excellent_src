; Music selection, stream engine, tables, and MML data
; CPU range $B875-$C20C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

LoadAudioTrackSet0:
    LDX #AudioTrackSet0Offset
    BEQ GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet1:
    LDX #AudioTrackSet1Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet2:
    LDX #AudioTrackSet2Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet3:
    LDX #AudioTrackSet3Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet4:
    LDX #AudioTrackSet4Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet5:
    LDX #AudioTrackSet5Record - AudioTrackTable
    BNE LoadAudioTrackSetByOffset

LoadAudioTrackSet7:
    LDX #AudioTrackSet7Record - AudioTrackTable

GuardAudioTrackLoadDuringDemo:
    LDA DemoPlaybackActive
    BEQ LoadAudioTrackSetByOffset
    RTS

LoadAudioTrackSetByOffset:
    LDA AudioTrackTable,X
    STA AudioStreamPointerLo
    LDA AudioTrackTable + 1,X
    STA AudioStreamPointerHi
    LDA AudioTrackTable + 2,X
    STA AudioPulse2StreamPointerLo
    LDA AudioTrackTable + 3,X
    STA AudioPulse2StreamPointerHi
    LDA AudioTrackTable + 4,X
    STA AudioTriangleStreamPointerLo
    LDA AudioTrackTable + 5,X
    STA AudioTriangleStreamPointerHi
    LDA AudioTrackTable + 6,X
    STA AudioPulseParameters
    LDA AudioTrackTable + 7,X
    STA AudioPulse2TrackParameters
    LDA #AudioTrackInitialTicks
    STA AudioStreamTicksRemaining
    STA AudioPulse2TicksRemaining
    STA AudioTriangleTicksRemaining
    RTS

AudioTrackTable:
    .byte $E7, $BB, $3F, $BC, $EE, $BC, $BF, $BB

AudioTrackSet1Record:
    .byte $4F, $BD, $80, $BD, $B9, $BD, $BF, $BB

AudioTrackSet2Record:
    .byte $F4, $BD, $F4, $BD, $38, $BE, $A9, $A9

AudioTrackSet3Record:
    .byte $5D, $BE, $BC, $BE, $1B, $BF, $2F, $2B

AudioTrackSet4Record:
    .byte $92, $BF, $FB, $BF, $5D, $C0, $3F, $3B

AudioTrackSet5Record:
    .byte $A1, $C0, $DE, $C0, $17, $C1, $3F, $BB

AudioTrackSet6Record:
    .byte $00, $00, $58, $C1, $58, $C1, $02, $02

AudioTrackSet7Record:
    .byte $58, $C1, $85, $C1, $C2, $C1, $7F, $7F

StopAudioStreams:
    LDA #$00
    STA APU_STATUS
    STA AudioStreamPointerLo
    STA AudioStreamPointerHi
    STA AudioPulse2StreamPointerLo
    STA AudioPulse2StreamPointerHi
    STA AudioTriangleStreamPointerLo
    STA AudioTriangleStreamPointerHi
    RTS

ClearSoundEffectRequests:
    LDA #$00
    STA Pulse1SoundEffectRequest
    STA Pulse2SoundEffectRequest
    STA TriangleSoundEffectRequest
    STA NoiseSoundEffectRequest
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
    BNE TickActiveAudioStream
    RTS

TickActiveAudioStream:
    DEC AudioStreamTicksRemaining,X
    BEQ ReadAudioStreamCommand
    LDA AudioStreamTicksRemaining,X
    CMP #$03
    BNE ReturnFromAudioStreamUpdate
    JSR ReadChannelSoundRequest
    BNE ReturnFromAudioStreamUpdate
    CPX #$00
    BNE CheckPulse2GateMask
    LDA #$0E

CheckPulse2GateMask:
    CPX #$04
    BNE CheckTriangleGateMask
    LDA #$0D

CheckTriangleGateMask:
    CPX #$08
    BNE ApplyAudioChannelGate
    LDA #$0B

ApplyAudioChannelGate:
    STA APU_STATUS

ReturnFromAudioStreamUpdate:
    RTS

ReadAudioStreamCommand:
    LDA (AudioStreamPointerLo,X)
    BNE DispatchAudioStreamCommand
    JMP SkipStreamTerminator

DispatchAudioStreamCommand:
    JSR AdvanceAudioStream
    CMP #$6F
    BNE CheckTempoCommand
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
    JMP ReadAudioStreamCommand

CheckTempoCommand:
    CMP #$74
    BNE CheckDefaultLengthCommand
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    SEC
    SBC #$30
    ASL A
    ASL A
    ASL A
    STA AudioTempoOffset
    JMP ReadAudioStreamCommand

CheckDefaultLengthCommand:
    CMP #$6C
    BNE CheckVolumeCommand
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    CMP #$40
    BNE CheckDefaultLength8
    LDA #$00
    BEQ StoreChannelDefaultLength

CheckDefaultLength8:
    CMP #$38
    BNE CheckDefaultLength4
    LDA #$01
    BNE StoreChannelDefaultLength

CheckDefaultLength4:
    CMP #$34
    BNE CheckDefaultLength2
    LDA #$02
    BNE StoreChannelDefaultLength

CheckDefaultLength2:
    CMP #$32
    BNE UseDefaultLength1
    LDA #$03
    BNE StoreChannelDefaultLength

UseDefaultLength1:
    LDA #$04

StoreChannelDefaultLength:
    CPX #$00
    BNE StorePulse2DefaultLength
    STA AudioPulse1DefaultLengthIndex

StorePulse2DefaultLength:
    CPX #$04
    BNE StoreTriangleDefaultLength
    STA AudioPulse2DefaultLengthIndex

StoreTriangleDefaultLength:
    CPX #$08
    BNE ReadNextAudioStreamCommand
    STA AudioTriangleDefaultLengthIndex

ReadNextAudioStreamCommand:
    JMP ReadAudioStreamCommand

CheckVolumeCommand:
    CMP #$76
    BNE CheckNoteCommand
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    JMP ReadAudioStreamCommand

CheckNoteCommand:
    CMP #$61
    BCC CheckRestCommand
    CMP #$68
    BCS CheckRestCommand
    SEC
    SBC #$61
    TAY
    LDA NoteSemitoneOffsets,Y
    CLC
    ADC AudioStreamOctaveOffset,X
    TAY
    LDA (AudioStreamPointerLo,X)
    CMP #$2B
    BNE CheckFlatAccidental
    INY
    JSR AdvanceAudioStream
    JMP BuildPeriodTableIndex

CheckFlatAccidental:
    CMP #$2D
    BNE BuildPeriodTableIndex
    DEY
    JSR AdvanceAudioStream

BuildPeriodTableIndex:
    INY
    TYA
    ASL A
    TAY
    JMP ProcessAudioEvent

CheckRestCommand:
    CMP #$72
    BEQ UseRestPeriod
    JMP ReadAudioStreamRestartPointer

UseRestPeriod:
    LDY #$00

ProcessAudioEvent:
    JSR ReadChannelSoundRequest
    BNE SelectChannelDefaultLength
    JSR ConfigureAudioChannel
    CPX #$08
    BNE WriteAudioChannelPeriod
    TYA
    BEQ WriteAudioChannelPeriod
    CLC
    ADC #$18
    TAY

WriteAudioChannelPeriod:
    LDA ApuPeriodTable,Y
    STA APU_PL1_LO,X
    LDA ApuPeriodTable + 1,Y
    STA APU_PL1_HI,X

SelectChannelDefaultLength:
    CPX #$00
    BNE SelectPulse2DefaultLength
    LDA AudioPulse1DefaultLengthIndex
    JMP LoadDefaultEventDuration

SelectPulse2DefaultLength:
    CPX #$04
    BNE SelectTriangleDefaultLength
    LDA AudioPulse2DefaultLengthIndex
    JMP LoadDefaultEventDuration

SelectTriangleDefaultLength:
    LDA AudioTriangleDefaultLengthIndex

LoadDefaultEventDuration:
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    LDA (AudioStreamPointerLo,X)
    CMP #$40
    BEQ CheckExplicitLength1
    CMP #$30
    BCC ApplyDottedDuration
    CMP #$3A
    BCS ApplyDottedDuration

CheckExplicitLength1:
    CMP #$31
    BNE CheckExplicitLength2
    LDY #$04

CheckExplicitLength2:
    CMP #$32
    BNE CheckExplicitLength4
    LDY #$03

CheckExplicitLength4:
    CMP #$34
    BNE CheckExplicitLength8
    LDY #$02

CheckExplicitLength8:
    CMP #$38
    BNE CheckExplicitLength16
    LDY #$01

CheckExplicitLength16:
    CMP #$40
    BNE LoadExplicitEventDuration
    LDY #$00

LoadExplicitEventDuration:
    TYA
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

ApplyDottedDuration:
    LDA (AudioStreamPointerLo,X)
    CMP #$2E
    BNE ReturnFromAudioEvent
    LDA AudioStreamTicksRemaining,X
    LSR A
    CLC
    ADC AudioStreamTicksRemaining,X
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

ReturnFromAudioEvent:
    RTS

SkipStreamTerminator:
    JSR AdvanceAudioStream

ReadAudioStreamRestartPointer:
    LDA (AudioStreamPointerLo,X)
    PHA
    JSR AdvanceAudioStream
    ORA (AudioStreamPointerLo,X)
    TAY
    LDA (AudioStreamPointerLo,X)
    PHA
    TYA
    BNE RestartAudioStream
    STA AudioStreamPointerLo,X
    STA AudioStreamPointerHi,X
    PLA
    PLA
    RTS

RestartAudioStream:
    PLA
    STA AudioStreamPointerHi,X
    PLA
    STA AudioStreamPointerLo,X
    JMP ReadAudioStreamCommand

ReadChannelSoundRequest:
    CPX #$00
    BNE ReadPulse2SoundRequest
    LDA Pulse1SoundEffectRequest
    RTS

ReadPulse2SoundRequest:
    CPX #$04
    BNE ReadTriangleSoundRequest
    LDA Pulse2SoundEffectRequest
    RTS

ReadTriangleSoundRequest:
    CPX #$08
    BNE ReturnInvalidChannelRequest
    LDA TriangleSoundEffectRequest
    RTS

ReturnInvalidChannelRequest:
    LDA #$FF
    RTS

AdvanceAudioStream:
    INC AudioStreamPointerLo,X
    BNE ReturnFromAdvanceAudioStream
    INC AudioStreamPointerHi,X

ReturnFromAdvanceAudioStream:
    RTS

UnreferencedLowercaseHexDigitDecodeBytes:
    .byte $C9, $3A, $B0, $04, $38, $E9, $30, $60, $E9, $57, $60

ConfigureAudioChannel:
    LDA #$0F
    STA APU_STATUS
    CPX #$00
    BNE ConfigurePulse2AudioChannel
    LDA AudioPulseParameters
    STA APU_PL1_VOL
    LDA #$08
    STA APU_PL1_SWEEP
    RTS

ConfigurePulse2AudioChannel:
    CPX #$04
    BNE ConfigureTriangleAudioChannel
    LDA AudioPulse2TrackParameters
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    RTS

ConfigureTriangleAudioChannel:
    CPX #$08
    BNE ReturnFromConfigureAudioChannel
    LDA #$FF
    STA APU_TRI_LINEAR

ReturnFromConfigureAudioChannel:
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
    .byte $63, $65, $63, $72, $38, $00, $E7, $BB

Track0Pulse2MusicStream:
    .byte $76, $39, $6C, $40, $6F, $34, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $63, $6F, $34, $62, $61, $67, $66, $65, $64, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $63, $6F, $34
    .byte $62, $61, $67, $38, $72, $38, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $63, $6F, $34, $62, $61, $67, $66, $65, $64, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $6F, $34, $67
    .byte $61, $62, $6F, $35, $63, $38, $72, $38, $6F, $34, $63, $67, $65, $67, $64, $67
    .byte $63, $67, $64, $67, $63, $67, $65, $67, $63, $67, $65, $67, $66, $62, $64, $62
    .byte $66, $62, $64, $66, $65, $67, $63, $67, $65, $67, $63, $67, $65, $67, $64, $67
    .byte $63, $67, $64, $67, $63, $67, $65, $67, $63, $67, $64, $67, $64, $67, $65, $67
    .byte $64, $67, $65, $67, $63, $67, $6F, $35, $63, $38, $72, $38, $00, $3F, $BC

Track0TriangleMusicStream:
    .byte $6C, $38, $6F, $34, $63, $6F, $33, $67, $65, $67, $64, $66, $67, $62, $6F, $34
    .byte $63, $6F, $33, $67, $65, $67, $64, $66, $67, $62, $6F, $34, $63, $6F, $33, $67
    .byte $65, $67, $64, $66, $67, $62, $6F, $34, $63, $6F, $33, $67, $65, $67, $67, $62
    .byte $6F, $34, $63, $38, $72, $38, $6F, $33, $67, $67, $66, $65, $66, $65, $65, $65
    .byte $65, $64, $64, $64, $64, $63, $65, $72, $38, $67, $67, $66, $65, $66, $65, $65
    .byte $65, $64, $66, $67, $62, $6F, $34, $63, $6F, $33, $67, $63, $72, $38, $00, $EE
    .byte $BC

Track1Pulse1MusicStream:
    .byte $74, $30, $6C, $38, $6F, $35, $63, $34, $65, $63, $64, $6F, $34, $67, $67, $34
    .byte $6F, $35, $63, $34, $65, $63, $64, $67, $67, $34, $63, $34, $65, $63, $64, $6F
    .byte $34, $67, $67, $34, $6F, $35, $63, $34, $65, $63, $64, $65, $63, $34, $00, $4F
    .byte $BD

Track1Pulse2MusicStream:
    .byte $6C, $38, $76, $64, $6F, $34, $65, $67, $6F, $35, $63, $6F, $34, $67, $64, $67
    .byte $62, $67, $65, $67, $6F, $35, $63, $6F, $34, $67, $66, $67, $62, $67, $65, $67
    .byte $6F, $35, $63, $6F, $34, $67, $64, $67, $62, $67, $65, $67, $6F, $35, $63, $6F
    .byte $34, $67, $66, $67, $65, $34, $00, $80, $BD

Track1TriangleMusicStream:
    .byte $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65, $66, $67, $64, $62, $6F, $34
    .byte $63, $6F, $33, $65, $67, $6F, $34, $63, $6F, $33, $62, $67, $66, $64, $63, $67
    .byte $65, $67, $66, $67, $61, $62, $6F, $34, $63, $6F, $33, $65, $67, $6F, $34, $63
    .byte $6F, $33, $62, $67, $6F, $34, $63, $34, $00, $B9, $BD

Track2PulseMusicStream:
    .byte $74, $32, $6C, $38, $6F, $35, $63, $2E, $63, $40, $64, $2E, $64, $40, $65, $2E
    .byte $65, $40, $66, $2E, $66, $40, $65, $34, $6F, $34, $67, $34, $6F, $35, $63, $34
    .byte $00, $00, $00

UnreferencedMusicStream:
    .byte $6C, $38, $6F, $34, $65, $2E, $65, $40, $67, $2E, $67, $40, $6F, $35, $63, $2E
    .byte $63, $40, $63, $2E, $63, $40, $63, $34, $6F, $34, $67, $34, $67, $34, $00, $00
    .byte $00

Track2TriangleMusicStream:
    .byte $6C, $38, $6F, $35, $63, $2E, $63, $40, $6F, $34, $62, $2E, $62, $40, $61, $2E
    .byte $61, $40, $61, $2D, $2E, $61, $2D, $40, $67, $34, $66, $34, $65, $34, $6F, $32
    .byte $63, $32, $00, $00, $00

Track3Pulse1MusicStream:
    .byte $74, $32, $6C, $38, $6F, $34, $67, $34, $62, $67, $66, $34, $61, $66, $67, $34
    .byte $62, $67, $61, $6F, $35, $64, $64, $34, $6F, $34, $67, $34, $62, $67, $66, $34
    .byte $61, $66, $67, $62, $6F, $35, $65, $64, $72, $32, $63, $34, $65, $63, $6F, $34
    .byte $62, $2D, $34, $6F, $35, $64, $6F, $34, $62, $2D, $6F, $35, $63, $34, $65, $63
    .byte $64, $67, $67, $34, $63, $34, $65, $63, $6F, $34, $62, $2D, $34, $6F, $35, $64
    .byte $6F, $34, $62, $2D, $6F, $35, $63, $65, $61, $67, $72, $32, $00, $5D, $BE

Track3Pulse2MusicStream:
    .byte $6C, $38, $6F, $33, $62, $34, $6F, $34, $64, $6F, $33, $62, $61, $34, $6F, $34
    .byte $63, $6F, $33, $61, $62, $34, $6F, $34, $64, $6F, $33, $62, $6F, $34, $64, $6F
    .byte $33, $61, $61, $34, $62, $34, $6F, $34, $64, $6F, $33, $62, $61, $34, $6F, $34
    .byte $63, $6F, $33, $61, $62, $6F, $34, $64, $61, $67, $72, $32, $65, $34, $67, $65
    .byte $64, $34, $66, $64, $65, $34, $67, $65, $67, $64, $64, $34, $65, $34, $67, $65
    .byte $64, $34, $66, $64, $65, $67, $6F, $35, $64, $63, $72, $32, $00, $BC, $BE

Track3TriangleMusicStream:
    .byte $6C, $38, $6F, $33, $67, $34, $64, $67, $66, $34, $63, $66, $67, $34, $64, $67
    .byte $66, $34, $64, $66, $67, $34, $64, $67, $66, $34, $63, $66, $67, $64, $6F, $34
    .byte $63, $6F, $33, $62, $72, $38, $6F, $32, $67, $72, $38, $67, $6F, $34, $63, $34
    .byte $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D, $34, $66, $62, $2D, $6F, $34
    .byte $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D, $34, $66, $62, $2D
    .byte $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D, $34, $66
    .byte $62, $2D, $6F, $34, $63, $6F, $33, $67, $6F, $34, $66, $65, $72, $38, $6F, $32
    .byte $63, $72, $38, $63, $00, $1B, $BF

Track4Pulse1MusicStream:
    .byte $74, $35, $76, $66, $6C, $40, $6F, $34, $67, $38, $61, $67, $66, $2B, $67, $6F
    .byte $35, $65, $34, $63, $38, $6F, $34, $62, $34, $61, $38, $6C, $34, $6F, $35, $64
    .byte $2E, $6C, $38, $6F, $34, $66, $67, $2E, $61, $40, $62, $6F, $35, $63, $2E, $64
    .byte $40, $63, $34, $64, $65, $34, $63, $6C, $40, $67, $38, $61, $67, $66, $2B, $67
    .byte $66, $34, $65, $38, $63, $2B, $34, $64, $38, $61, $34, $63, $38, $6C, $38, $6F
    .byte $34, $62, $61, $2E, $67, $40, $6F, $35, $66, $65, $2E, $64, $40, $63, $65, $67
    .byte $6F, $36, $63, $34, $72, $38, $00, $00, $00

Track4Pulse2MusicStream:
    .byte $76, $66, $6C, $40, $6F, $34, $65, $38, $66, $65, $64, $2B, $65, $67, $34, $67
    .byte $38, $67, $34, $66, $38, $6C, $34, $61, $2E, $6C, $38, $64, $65, $2E, $66, $40
    .byte $67, $61, $2E, $66, $40, $65, $34, $66, $67, $34, $65, $6C, $40, $6F, $35, $65
    .byte $38, $66, $65, $64, $2B, $65, $63, $2B, $34, $6F, $34, $61, $38, $65, $34, $66
    .byte $38, $6F, $35, $63, $34, $6F, $34, $66, $2B, $38, $6C, $38, $67, $66, $2E, $64
    .byte $40, $62, $67, $2E, $66, $40, $65, $67, $6F, $35, $63, $65, $34, $72, $38, $00
    .byte $00, $00

Track4TriangleMusicStream:
    .byte $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65, $63, $65, $66, $63, $66, $63
    .byte $66, $65, $64, $66, $61, $67, $34, $64, $63, $65, $67, $38, $63, $65, $67, $62
    .byte $2D, $66, $62, $2D, $61, $34, $63, $2B, $64, $61, $64, $64, $2B, $66, $2B, $61
    .byte $67, $64, $67, $64, $67, $64, $63, $6F, $34, $63, $6F, $33, $67, $63, $34, $72
    .byte $38, $00, $00, $00

Track5Pulse1MusicStream:
    .byte $74, $32, $76, $66, $6C, $38, $6F, $35, $63, $34, $2E, $6F, $34, $66, $67, $6F
    .byte $35, $63, $64, $34, $2E, $67, $34, $2E, $66, $65, $64, $65, $32, $2E, $67, $66
    .byte $2B, $67, $61, $2D, $32, $67, $61, $2D, $62, $2D, $32, $61, $62, $2D, $6F, $36
    .byte $63, $72, $6F, $35, $62, $2D, $6F, $36, $63, $31, $00, $00, $00

Track5Pulse2MusicStream:
    .byte $76, $66, $6C, $38, $6F, $34, $67, $34, $2E, $63, $64, $67, $67, $34, $2E, $6F
    .byte $35, $64, $34, $2E, $64, $63, $6F, $34, $62, $2D, $6F, $35, $63, $2B, $32, $2E
    .byte $65, $64, $2B, $65, $63, $32, $6F, $34, $62, $6F, $35, $63, $64, $32, $63, $2B
    .byte $64, $67, $72, $66, $67, $31, $00, $00, $00

Track5TriangleMusicStream:
    .byte $6C, $38, $6F, $33, $63, $32, $2E, $6F, $32, $62, $32, $2E, $62, $2D, $34, $2E
    .byte $61, $6F, $33, $65, $67, $61, $34, $2E, $6F, $32, $61, $34, $2E, $61, $2D, $6F
    .byte $33, $63, $65, $2D, $61, $2D, $65, $2D, $63, $6F, $32, $62, $2D, $6F, $33, $64
    .byte $66, $62, $2D, $66, $64, $6F, $33, $63, $65, $67, $6F, $34, $63, $31, $00, $00
    .byte $00

SharedTrack6And7MusicStream:
    .byte $74, $30, $6C, $34, $6F, $34, $62, $2D, $6F, $35, $63, $64, $63, $64, $65, $64
    .byte $65, $66, $65, $66, $67, $61, $72, $34, $63, $62, $2D, $32, $61, $67, $66, $2B
    .byte $66, $65, $66, $67, $66, $31, $2E, $66, $31, $2E, $00, $00, $00

Track7Pulse2MusicStream:
    .byte $6C, $34, $6F, $34, $67, $61, $62, $2D, $61, $62, $2D, $6F, $35, $63, $6F, $34
    .byte $62, $2D, $6F, $35, $63, $64, $63, $64, $65, $66, $72, $34, $6F, $34, $67, $66
    .byte $2B, $32, $66, $2B, $67, $67, $67, $67, $61, $62, $2D, $61, $67, $61, $62, $2D
    .byte $6F, $35, $63, $6F, $34, $62, $2D, $61, $31, $2E, $00, $00, $00

Track7TriangleMusicStream:
    .byte $6C, $34, $6F, $34, $72, $38, $67, $67, $67, $61, $61, $61, $38, $72, $38, $62
    .byte $2D, $62, $2D, $62, $2D, $6F, $35, $63, $63, $63, $38, $63, $72, $34, $6F, $34
    .byte $61, $6F, $35, $65, $2D, $32, $63, $6F, $34, $72, $38, $62, $2D, $62, $2D, $62
    .byte $2D, $6F, $35, $63, $63, $63, $38, $63, $6F, $34, $62, $2D, $6F, $35, $63, $64
    .byte $2D, $65, $2D, $64, $2D, $63, $31, $2E, $00, $00, $00
