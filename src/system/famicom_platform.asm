; Famicom platform transport, PPU, and startup
; Original CPU range $8000-$82CD

DelayLongPulseHalf:
    LDX #$91

WaitLongPulseHalf:
    DEX
    BNE WaitLongPulseHalf
    RTS

DelayShortPulseHalf:
    LDX #$47

WaitShortPulseHalf:
    DEX
    BNE WaitShortPulseHalf
    RTS

WaitForPulseEdge:
    LDY #$00

MeasurePulseEdgeDelay:
    INY
    BEQ ReturnPulseEdgeTimeout
    LDA JOYPAD1
    AND #PulseInputMask
    EOR PulseInputLevel
    BEQ MeasurePulseEdgeDelay
    EOR PulseInputLevel
    STA PulseInputLevel
    RTS

ReturnPulseEdgeTimeout:
    DEY
    RTS

CountPulseEdgesInWindow:
    LDX #PulseSampleCount
    LDY #$00

SamplePulseWindow:
    LDA JOYPAD1
    AND #PulseInputMask
    EOR PulseInputLevel
    BEQ PadUnchangedPulseSample
    EOR PulseInputLevel
    STA PulseInputLevel
    INY
    DEX
    BNE SamplePulseWindow
    RTS

PadUnchangedPulseSample:
    LDA PulseInputLevel
    LDA PulseInputLevel
    LDA PulseInputLevel
    DEX
    BNE SamplePulseWindow
    RTS

EmitLongPulseCycle:
    LDA #$00
    STA JOYPAD1
    JSR DelayLongPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayLongPulseHalf
    LDA #$00
    STA JOYPAD1
    RTS

EmitPulseBitFromCarry:
    BCC EmitLongPulseCycle

EmitShortPulsePair:
    LDA #$00
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$00
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$01
    STA JOYPAD1
    JSR DelayShortPulseHalf
    LDA #$00
    STA JOYPAD1
    RTS

ReceivePulsePreamble:
    LDA #PulseReceiveMode
    STA JOYPAD1
    LDX #$00
    STX PulseInputLevel

ReadNextPulsePreambleEdge:
    JSR WaitForPulseEdge
    CPY #PulsePreambleMinEdgeDelay
    BCC ReceivePulsePreamble
    CPY #PulsePreambleMaxEdgeDelayExclusive
    BCS ReceivePulsePreamble
    INX
    BNE ReadNextPulsePreambleEdge
    RTS

SendPulsePreamble:
    LDA #PulsePreamblePageTotal
    STA PulsePreamblePageCount
    LDY #$00

SendPulsePreambleCycles:
    JSR EmitShortPulsePair
    DEY
    BNE SendPulsePreambleCycles
    DEC PulsePreamblePageCount
    BNE SendPulsePreambleCycles
    CLC
    RTS

SendPulseByte:
    JSR EmitLongPulseCycle
    LDY #DataIoBitCount

SendNextPulseBit:
    ASL DataIoByte
    JSR EmitPulseBitFromCarry
    DEY
    BNE SendNextPulseBit
    JSR EmitShortPulsePair
    JMP EmitShortPulsePair

ReceivePulseByte:
    LDA JOYPAD1
    AND #PulseInputMask
    BEQ ReceivePulseByte

WaitForPulseStartLow:
    LDA JOYPAD1
    AND #PulseInputMask
    BNE WaitForPulseStartLow
    STA PulseInputLevel
    JSR WaitForPulseEdge

MeasurePulseStartWidth:
    STY PulseAccumulatedWidth
    JSR WaitForPulseEdge
    TYA
    CLC
    ADC PulseAccumulatedWidth
    BCS MeasurePulseStartWidth
    CMP #PulseStartMinWidth
    BCC MeasurePulseStartWidth
    LDA #DataIoBitCount
    STA PulseBitsRemaining

DecodeNextPulseBit:
    JSR CountPulseEdgesInWindow
    CPY #PulseInvalidEdgeCount
    BCS ReturnPulseByteStatus
    CPY #PulseOneEdgeCount
    ROL DataIoByte
    TYA
    LSR A
    BCS WaitForPulseBitTail
    JSR WaitForPulseEdge

WaitForPulseBitTail:
    JSR WaitForPulseEdge
    DEC PulseBitsRemaining
    BNE DecodeNextPulseBit
    LDA PulseAccumulatedWidth
    CLC

ReturnPulseByteStatus:
    RTS

ReadController1:
    JSR DisableNmi
    JSR PollController1
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS

ReadController1WithoutNmiControl:
    JSR PollController1
    LDA PolledControllerButtons
    RTS

PollController1:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #ControllerSerialBitCount

ReadNextController1Bit:
    LDA JOYPAD1
    LSR A
    BCS ShiftController1Bit
    LSR A

ShiftController1Bit:
    ROR PolledControllerButtons
    DEX
    BNE ReadNextController1Bit
    RTS

ReadController2:
    JSR DisableNmi
    JSR PollController2
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS

UnreferencedController2ReadWrapperBytes:
    .byte $20, $3B, $81, $A5, $20, $60

PollController2:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #ControllerSerialBitCount

ReadNextController2Bit:
    LDA JOYPAD2
    LSR A
    BCS ShiftController2Bit
    LSR A

ShiftController2Bit:
    ROR PolledControllerButtons
    DEX
    BNE ReadNextController2Bit
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS

DisableNmi:
    LDA #PpuCtrlGameplayNoNmi
    STA PPU_CTRL
    RTS

EnableNmi:
    LDA #PpuCtrlGameplayNmi
    STA PPU_CTRL
    RTS

DisableRendering:
    LDA #PpuMaskRenderingDisabled
    STA PPU_MASK
    RTS

WaitForVblankAndEnableRendering:
    LDA PPU_STATUS
    BPL WaitForVblankAndEnableRendering
    LDA #PpuMaskGameplay
    STA PPU_MASK
    RTS

SelectChrBank:
    LDA ChrBankSelectValues,Y
    STA ChrBankSelectValues,Y
    RTS

ChrBankSelectValues:
    .byte $00, $01, $02, $03

SendDataPreamble:
    BIT DataIoTransportMode
    BPL SendExpansionPreamble
    JMP SendPulsePreamble

SendExpansionPreamble:
    JSR StrobeExpansionPort
    LDA #$00
    STA DataIoByte
    JSR SendExpansionByte
    LDA #DataPreambleSyncA
    STA DataIoByte
    JSR SendExpansionByte
    LDA #DataPreambleSyncB
    STA DataIoByte
    JMP SendExpansionByte

ReceiveDataPreamble:
    BIT DataIoTransportMode
    BPL ReceiveExpansionPreamble
    JMP ReceivePulsePreamble

ReceiveExpansionPreamble:
    JSR StrobeExpansionPort
    JSR ReceiveExpansionByte
    JSR ReceiveExpansionByte
    LDA DataIoByte
    CMP #DataPreambleSyncA
    BNE ReturnDataPreambleFailure
    JSR ReceiveExpansionByte
    LDA DataIoByte
    CMP #DataPreambleSyncB
    BNE ReturnDataPreambleFailure
    CLC
    RTS

ReturnDataPreambleFailure:
    SEC
    RTS

SendDataByte:
    STA DataIoByte
    STX DataIoSavedX
    BIT DataIoTransportMode
    BPL SendExpansionBytePath
    JSR SendPulseByte
    JMP RestoreDataIoSendX

SendExpansionBytePath:
    JSR SendExpansionByte

RestoreDataIoSendX:
    LDX DataIoSavedX
    RTS

ReceiveDataByte:
    STX DataIoSavedX
    BIT DataIoTransportMode
    BMI ReceivePulseBytePath
    JSR ReceiveExpansionByte
    JMP ReturnDataByte

ReceivePulseBytePath:
    JSR ReceivePulseByte

ReturnDataByte:
    LDX DataIoSavedX
    LDA DataIoByte
    RTS

SendExpansionByte:
    LDY #DataIoBitCount - 1

SendNextExpansionBit:
    ASL DataIoByte
    LDA #$00
    ROL A
    ORA #ExpansionSerialClockHigh
    STA JOYPAD1
    AND #ExpansionSerialClockLowMask
    STA JOYPAD1
    DEY
    BPL SendNextExpansionBit
    RTS

ReceiveExpansionByte:
    LDY #DataIoBitCount - 1

ReceiveNextExpansionBit:
    LDA EXPANSION_PORT_INPUT
    LSR A
    LSR A
    AND #ExpansionSerialDataBit
    ORA #ExpansionSerialClockHigh
    STA JOYPAD1
    AND #ExpansionSerialClockLowMask
    STA JOYPAD1
    LSR A
    ROL DataIoByte
    DEY
    BPL ReceiveNextExpansionBit
    CLC
    RTS

StrobeExpansionPort:
    LDA #$00
    STA JOYPAD1
    LDA #ExpansionSerialStrobe
    STA JOYPAD1
    RTS

Reset:
    SEI
    CLD
    LDA #PpuMaskRenderingDisabled
    STA PPU_CTRL

WaitForFirstResetVblank:
    LDA PPU_STATUS
    BPL WaitForFirstResetVblank

WaitForSecondResetVblank:
    LDA PPU_STATUS
    BPL WaitForSecondResetVblank
    CLD
    LDX #$FF
    TXS
    LDX #PowerOnSignatureCheckedBytes - 1

CheckPowerOnSignature:
    LDA PowerOnSignatureRam,X
    CMP PowerOnSignature,X
    BNE InitializeColdBootState
    DEX
    BPL CheckPowerOnSignature
    BMI IncrementResetCounter

InitializeColdBootState:
    LDX #PowerOnSignatureCheckedBytes - 1

CopyPowerOnSignature:
    LDA PowerOnSignature,X
    STA PowerOnSignatureRam,X
    DEX
    BPL CopyPowerOnSignature
    LDA #$00
    STA HighScoreLo
    STA HighScoreHi
    STA ResetCounterLo
    STA ResetCounterHi

IncrementResetCounter:
    INC ResetCounterLo
    BNE StartNewGame
    INC ResetCounterHi

StartNewGame:
    JSR StopAudioStreams
    JSR ClearSoundEffectRequests
    JSR RunTitleScreen
    JSR InitializeNewGame
    JSR LoadRoom

WaitForRoomLoadVblank:
    LDA PPU_STATUS
    BPL WaitForRoomLoadVblank
    JSR EnableNmi
    JSR WaitForVblankAndEnableRendering

MainFrameLoop:
    LDA #NmiFramesPerMainUpdate
    STA NmiFrameCountdown
    JSR HandleCastleMapInput
    LDA CastleMapMode
    BNE WaitForMainFrame
    JSR FormatPlayerStatusTiles
    JSR HandlePauseInput
    LDA PauseMode
    BNE RenderMainFrame
    JSR UpdatePlayerInputAndMovement
    JSR UpdatePlayerProtectionAndHazardState
    JSR EnsureRoomAudioPlaying
    JSR UpdateRuntimeObjects
    JSR UpdatePlayerCollisionState
    JSR AnimateRoomCells
    INC RoomFrameCounter

RenderMainFrame:
    JSR UpdateHorizontalScroll
    JSR BuildFrameSprites
    JSR HandleSubCommandInput
    LDA DemoPlaybackActive
    BEQ WaitForMainFrame
    LDA PhysicalController1Buttons
    AND #ControllerButtonStart
    BNE StartNewGame

WaitForMainFrame:
    LDA NmiFrameCountdown
    BNE WaitForMainFrame
    BEQ MainFrameLoop

PowerOnSignature:
    .byte "POWER"
