; Textual MML stream interpreter and scheduler
; CPU range $B906-$BADD
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
