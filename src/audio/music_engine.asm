; Music selection, stream engine, tables, and MML data
; Original CPU range $B875-$C20C

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
    .addr MusicMmlData
    .addr Track0Pulse2MusicStream
    .addr Track0TriangleMusicStream
    .byte $BF, $BB

AudioTrackSet1Record:
    .addr Track1Pulse1MusicStream
    .addr Track1Pulse2MusicStream
    .addr Track1TriangleMusicStream
    .byte $BF, $BB

AudioTrackSet2Record:
    .addr Track2PulseMusicStream
    .addr Track2PulseMusicStream
    .addr Track2TriangleMusicStream
    .byte $A9, $A9

AudioTrackSet3Record:
    .addr Track3Pulse1MusicStream
    .addr Track3Pulse2MusicStream
    .addr Track3TriangleMusicStream
    .byte $2F, $2B

AudioTrackSet4Record:
    .addr Track4Pulse1MusicStream
    .addr Track4Pulse2MusicStream
    .addr Track4TriangleMusicStream
    .byte $3F, $3B

AudioTrackSet5Record:
    .addr Track5Pulse1MusicStream
    .addr Track5Pulse2MusicStream
    .addr Track5TriangleMusicStream
    .byte $3F, $BB

AudioTrackSet6Record:
    .word $0000
    .addr SharedTrack6And7MusicStream
    .addr SharedTrack6And7MusicStream
    .byte $02, $02

AudioTrackSet7Record:
    .addr SharedTrack6And7MusicStream
    .addr Track7Pulse2MusicStream
    .addr Track7TriangleMusicStream
    .byte $7F, $7F

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

; MML music streams, one ASCII command each; docs/data_formats.md lists them
MusicMmlData:
    .byte "t5v9l8o4cegefdggcegefdgr8cegefdggcegefdc8r8o6co5bagaggggffffegr8"
    .byte "o6co5bagaggggfedcecr8", $00
    .addr MusicMmlData

Track0Pulse2MusicStream:
    .byte "v9l@o4egcgo5co4go5ecdco4bagfedegcgo5co4go5ecdco4bag8r8egcgo5co4g"
    .byte "o5ecdco4bagfedegcgo5co4go5ecdo4gabo5c8r8o4cgegdgcgdgcgegcgegfbdb"
    .byte "fbdfegcgegcgegdgcgdgcgegcgdgdgegdgegcgo5c8r8", $00
    .addr Track0Pulse2MusicStream

Track0TriangleMusicStream:
    .byte "l8o4co3gegdfgbo4co3gegdfgbo4co3gegdfgbo4co3geggbo4c8r8o3ggfefeee"
    .byte "eddddcer8ggfefeeedfgbo4co3gcr8", $00
    .addr Track0TriangleMusicStream

Track1Pulse1MusicStream:
    .byte "t0l8o5c4ecdo4gg4o5c4ecdgg4c4ecdo4gg4o5c4ecdec4", $00
    .addr Track1Pulse1MusicStream

Track1Pulse2MusicStream:
    .byte "l8vdo4ego5co4gdgbgego5co4gfgbgego5co4gdgbgego5co4gfge4", $00
    .addr Track1Pulse2MusicStream

Track1TriangleMusicStream:
    .byte "l8o4co3gcefgdbo4co3ego4co3bgfdcgegfgabo4co3ego4co3bgo4c4", $00
    .addr Track1TriangleMusicStream

Track2PulseMusicStream:
    .byte "t2l8o5c.c@d.d@e.e@f.f@e4o4g4o5c4", $00, $00, $00

UnreferencedMusicStream:
    .byte "l8o4e.e@g.g@o5c.c@c.c@c4o4g4g4", $00, $00, $00

Track2TriangleMusicStream:
    .byte "l8o5c.c@o4b.b@a.a@a-.a-@g4f4e4o2c2", $00, $00, $00

Track3Pulse1MusicStream:
    .byte "t2l8o4g4bgf4afg4bgao5dd4o4g4bgf4afgbo5edr2c4eco4b-4o5do4b-o5c4ec"
    .byte "dgg4c4eco4b-4o5do4b-o5ceagr2", $00
    .addr Track3Pulse1MusicStream

Track3Pulse2MusicStream:
    .byte "l8o3b4o4do3ba4o4co3ab4o4do3bo4do3aa4b4o4do3ba4o4co3abo4dagr2e4ge"
    .byte "d4fde4gegdd4e4ged4fdego5dcr2", $00
    .addr Track3Pulse2MusicStream

Track3TriangleMusicStream:
    .byte "l8o3g4dgf4cfg4dgf4dfg4dgf4cfgdo4co3br8o2gr8go4c4o3go4co3b-4fb-o4"
    .byte "c4o3go4co3b-4fb-o4c4o3go4co3b-4fb-o4co3go4fer8o2cr8c", $00
    .addr Track3TriangleMusicStream

Track4Pulse1MusicStream:
    .byte "t5vfl@o4g8agf+go5e4c8o4b4a8l4o5d.l8o4fg.a@bo5c.d@c4de4cl@g8agf+g"
    .byte "f4e8c+4d8a4c8l8o4ba.g@o5fe.d@cego6c4r8", $00, $00, $00

Track4Pulse2MusicStream:
    .byte "vfl@o4e8fed+eg4g8g4f8l4a.l8de.f@ga.f@e4fg4el@o5e8fed+ec+4o4a8e4f"
    .byte "8o5c4o4f+8l8gf.d@bg.f@ego5ce4r8", $00, $00, $00

Track4TriangleMusicStream:
    .byte "l8o4co3gcecefcfcfedfag4dceg8cegb-fb-a4c+dadd+f+agdgdgdco4co3gc4r"
    .byte "8", $00, $00, $00

Track5Pulse1MusicStream:
    .byte "t2vfl8o5c4.o4fgo5cd4.g4.fede2.gf+ga-2ga-b-2ab-o6cro5b-o6c1", $00, $00, $00

Track5Pulse2MusicStream:
    .byte "vfl8o4g4.cdgg4.o5d4.dco4b-o5c+2.ed+ec2o4bo5cd2c+dgrfg1", $00, $00, $00

Track5TriangleMusicStream:
    .byte "l8o3c2.o2b2.b-4.ao3ega4.o2a4.a-o3ce-a-e-co2b-o3dfb-fdo3cego4c1", $00, $00, $00

SharedTrack6And7MusicStream:
    .byte "t0l4o4b-o5cdcdedefefgar4cb-2agf+fefgf1.f1.", $00, $00, $00

Track7Pulse2MusicStream:
    .byte "l4o4gab-ab-o5co4b-o5cdcdefr4o4gf+2f+ggggab-agab-o5co4b-a1.", $00, $00, $00

Track7TriangleMusicStream:
    .byte "l4o4r8gggaaa8r8b-b-b-o5ccc8cr4o4ao5e-2co4r8b-b-b-o5ccc8co4b-o5cd"
    .byte "-e-d-c1.", $00, $00, $00
