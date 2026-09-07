; Scroll, palette, NMI, OAM, and status rendering pipeline
; CPU range $C43D-$C8BB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateHorizontalScroll:
    LDA PauseMode
    BEQ UpdateUnpausedHorizontalScroll
    RTS

UpdateUnpausedHorizontalScroll:
    LDA PlayerXLo
    SEC
    SBC #<HorizontalScrollPlayerMargin
    STA HorizontalScrollDividendLo
    LDA PlayerXHi
    SBC #>HorizontalScrollPlayerMargin
    BCS CheckMaximumHorizontalScroll

SetMinimumHorizontalScroll:
    LDA #$00
    STA HorizontalScrollPendingX
    BEQ ReturnFromHorizontalScrollUpdate

CheckMaximumHorizontalScroll:
    LDA HorizontalScrollDividendLo
    BEQ SetMinimumHorizontalScroll
    CMP #HorizontalScrollMaximumDelta
    BCC ScaleHorizontalScrollPosition
    LDA #HorizontalScrollMaximum
    STA HorizontalScrollPendingX
    BNE ReturnFromHorizontalScrollUpdate

ScaleHorizontalScrollPosition:
    ASL A
    STA HorizontalScrollDividendLo
    LDA #$00
    STA HorizontalScrollDivisorHi
    ROL A
    STA HorizontalScrollDividendHi
    LDA #HorizontalScrollDivisor
    STA HorizontalScrollDivisorLo
    JSR DivideUnsigned16
    LDA HorizontalScrollQuotientLo
    STA HorizontalScrollPendingX

ReturnFromHorizontalScrollUpdate:
    RTS

DivideUnsigned16:
    LDA UnsignedDivisionDivisorLo
    ORA UnsignedDivisionDivisorHi
    BNE InitializeUnsignedDivision
    SEC
    RTS

InitializeUnsignedDivision:
    LDA #$01
    STA UnsignedDivisionBitLo
    LDA #$00
    STA UnsignedDivisionBitHi
    STA UnsignedDivisionQuotientHi
    STA UnsignedDivisionQuotientLo

AlignUnsignedDivisor:
    LDA UnsignedDivisionDivisorHi
    BMI TrySubtractUnsignedDivisor
    ASL UnsignedDivisionDivisorLo
    ROL UnsignedDivisionDivisorHi
    ASL UnsignedDivisionBitLo
    ROL UnsignedDivisionBitHi
    JMP AlignUnsignedDivisor

TrySubtractUnsignedDivisor:
    LDA UnsignedDivisionDividendLo
    CMP UnsignedDivisionDivisorLo
    LDA UnsignedDivisionDividendHi
    SBC UnsignedDivisionDivisorHi
    BCC ShiftUnsignedDivisorRight
    LDA UnsignedDivisionDividendLo
    SBC UnsignedDivisionDivisorLo
    STA UnsignedDivisionDividendLo
    LDA UnsignedDivisionDividendHi
    SBC UnsignedDivisionDivisorHi
    STA UnsignedDivisionDividendHi
    LDA UnsignedDivisionBitLo
    CLC
    ADC UnsignedDivisionQuotientLo
    STA UnsignedDivisionQuotientLo
    LDA UnsignedDivisionBitHi
    ADC UnsignedDivisionQuotientHi
    STA UnsignedDivisionQuotientHi

ShiftUnsignedDivisorRight:
    LSR UnsignedDivisionDivisorHi
    ROR UnsignedDivisionDivisorLo
    BCS ReturnFromUnsignedDivision
    LSR UnsignedDivisionBitHi
    ROR UnsignedDivisionBitLo
    BCC TrySubtractUnsignedDivisor

ReturnFromUnsignedDivision:
    RTS

UploadPaletteFromPointer:
    JSR DisableNmi
    JSR DisableRendering

WaitForPaletteUploadVblank:
    LDA PPU_STATUS
    BPL WaitForPaletteUploadVblank
    LDA #>PpuPaletteAddress
    STA PPU_ADDR
    LDY #<PpuPaletteAddress
    STY PPU_ADDR

UploadNextPaletteByte:
    LDA (PaletteSourcePointerLo),Y
    STA PPU_DATA
    INY
    CPY #PpuPaletteByteCount
    BCC UploadNextPaletteByte
    LDA #>PpuPaletteAddress
    STA PPU_ADDR
    LDA #<PpuPaletteAddress
    STA PPU_ADDR
    STA PPU_ADDR
    STA PPU_ADDR
    RTS

CompletionPaletteData:
    .byte $0F, $16, $36, $30, $0F, $1A, $36, $30, $0F, $08, $17, $27, $0F, $00, $10, $30

TitlePaletteData:
    .incbin RevisionTitlePaletteAsset

CastleMapPaletteData:
    .byte $0F, $16, $10, $30, $0F, $18, $1A, $2A, $0F, $07, $17, $27, $0F, $12, $21, $28
    .byte $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A, $36

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
    LDA #PpuCtrlGameplayNmi
    STA PPU_CTRL
    LDA CastleMapMode
    BNE NmiFrame
    LDA NmiTaskIndex
    TAX
    LDA NmiTaskHandlerHighBytes,X
    STA NmiTaskHandlerPointerHi
    LDA NmiTaskHandlerLowBytes,X
    STA NmiTaskHandlerPointerLo
    JMP (NmiTaskHandlerPointerLo)

NmiFrame:
    LDA #$00
    STA OAM_ADDR
    LDA #OamDmaBufferPage
    STA OAM_DMA
    LDA #PpuCtrlGameplayNmi
    STA PPU_CTRL
    LDA PPU_STATUS
    LDA #$00
    STA PPU_SCROLL
    STA PPU_SCROLL
    LDA OamStagingBusy
    BEQ RebuildOamDmaBuffer
    JMP ReusePreviousDmaOam

RebuildOamDmaBuffer:
    LDA #$FF
    STA OamStagingBusy
    JSR BuildDmaOam
    LDA #$00
    STA OamStagingBusy
    LDY #$04
    LDX #$40

WaitForOamBuildTiming:
    DEX
    BNE WaitForOamBuildTiming
    DEY
    BNE WaitForOamBuildTiming

UpdateScrollLatch:
    LDA ScrollUpdatePending
    BEQ ApplyHorizontalScroll
    LDA ResetPendingScrollX
    STA ResetAppliedScrollX

ApplyHorizontalScroll:
    LDA CastleMapMode
    BNE AdvanceNmiTaskScheduler
    LDA PPU_STATUS
    LDA ResetAppliedScrollX
    STA PPU_SCROLL
    LDA #$00
    STA PPU_SCROLL
    STA ScrollUpdatePending

AdvanceNmiTaskScheduler:
    INC FrameCounter
    LDX NmiTaskIndex
    LDA #$00
    STA NmiTaskRequests,X
    CPX #NmiTaskRequestCount - 1
    BCC FindNextPendingNmiTask

WrapNmiTaskIndex:
    LDX #$00
    STX NmiTaskIndex
    BEQ TickMainFrameCountdown

FindNextPendingNmiTask:
    INX
    CPX #NmiTaskRequestCount
    BCS WrapNmiTaskIndex
    LDA NmiTaskRequests,X
    BEQ FindNextPendingNmiTask
    STX NmiTaskIndex

TickMainFrameCountdown:
    LDA NmiFrameCountdown
    BEQ PollFrameControllers
    DEC NmiFrameCountdown

PollFrameControllers:
    LDA DemoPlaybackActive
    BNE ReadDemoPlaybackInput
    JSR ReadController1
    STA Controller1Buttons
    JSR ReadController2
    STA Controller2Buttons
    JMP ReadPhysicalControllerInput

ReadDemoPlaybackInput:
    JSR ReadDemoController1
    STA Controller1Buttons
    LDA #$00
    STA Controller2Buttons

ReadPhysicalControllerInput:
    JSR ReadController1
    STA PhysicalController1Buttons
    INC FrameCounterModulo3A
    LDA FrameCounterModulo3A
    CMP #$03
    BCC TickModulo5Counter
    LDA #$00
    STA FrameCounterModulo3A

TickModulo5Counter:
    INC FrameCounterModulo5
    LDA FrameCounterModulo5
    CMP #$05
    BCC TickModulo6Counter
    LDA #$00
    STA FrameCounterModulo5

TickModulo6Counter:
    INC FrameCounterModulo6
    LDA FrameCounterModulo6
    CMP #$06
    BCC TickModulo7Counter
    LDA #$00
    STA FrameCounterModulo6

TickModulo7Counter:
    INC FrameCounterModulo7
    LDA FrameCounterModulo7
    CMP #$07
    BCC TickSecondModulo3Counter
    LDA #$00
    STA FrameCounterModulo7

TickSecondModulo3Counter:
    INC FrameCounterModulo3B
    LDA FrameCounterModulo3B
    CMP #$03
    BCC TickModulo10Counter
    LDA #$00
    STA FrameCounterModulo3B

TickModulo10Counter:
    INC FrameCounterModulo10
    LDA FrameCounterModulo10
    CMP #$0A
    BCC TickModulo11Counter
    LDA #$00
    STA FrameCounterModulo10

TickModulo11Counter:
    INC FrameCounterModulo11
    LDA FrameCounterModulo11
    CMP #$0B
    BCC TickModulo30Counter
    LDA #$00
    STA FrameCounterModulo11

TickModulo30Counter:
    INC FrameCounterModulo30
    LDA FrameCounterModulo30
    CMP #$1E
    BCC UpdateFrameAudio
    LDA #$00
    STA FrameCounterModulo30

UpdateFrameAudio:
    LDA PauseMode
    BNE MaybeReverseDmaOam
    JSR UpdateAudioStreams
    JSR UpdateSoundEffects

MaybeReverseDmaOam:
    LDA OamStagingBusy
    BNE RestoreNmiRegisters
    LDA FrameCounter
    LSR A
    BCC RestoreNmiRegisters
    JSR ReverseDmaOam

RestoreNmiRegisters:
    PLA
    TAY
    PLA
    TAX
    PLA

Irq:
    RTI

BuildDmaOam:
    LDX #$00

CopyNextOamInterleaveBlock:
    TXA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA OamOutputBlockIndex
    LDA FrameCounter
    AND #OamRotationFrameCount - 1
    CLC
    ADC OamOutputBlockIndex
    TAY
    LDA OamRotationOffsets,Y
    TAY
    LDA OamStagingBuffer,Y
    STA OamDmaBuffer,X
    LDA OamStagingBuffer + $01,Y
    STA OamDmaBuffer + $01,X
    LDA OamStagingBuffer + $02,Y
    STA OamDmaBuffer + $02,X
    LDA OamStagingBuffer + $03,Y
    STA OamDmaBuffer + $03,X
    LDA OamStagingBuffer + $20,Y
    STA OamDmaBuffer + $04,X
    LDA OamStagingBuffer + $21,Y
    STA OamDmaBuffer + $05,X
    LDA OamStagingBuffer + $22,Y
    STA OamDmaBuffer + $06,X
    LDA OamStagingBuffer + $23,Y
    STA OamDmaBuffer + $07,X
    LDA OamStagingBuffer + $40,Y
    STA OamDmaBuffer + $08,X
    LDA OamStagingBuffer + $41,Y
    STA OamDmaBuffer + $09,X
    LDA OamStagingBuffer + $42,Y
    STA OamDmaBuffer + $0A,X
    LDA OamStagingBuffer + $43,Y
    STA OamDmaBuffer + $0B,X
    LDA OamStagingBuffer + $60,Y
    STA OamDmaBuffer + $0C,X
    LDA OamStagingBuffer + $61,Y
    STA OamDmaBuffer + $0D,X
    LDA OamStagingBuffer + $62,Y
    STA OamDmaBuffer + $0E,X
    LDA OamStagingBuffer + $63,Y
    STA OamDmaBuffer + $0F,X
    LDA OamStagingBuffer + $80,Y
    STA OamDmaBuffer + $10,X
    LDA OamStagingBuffer + $81,Y
    STA OamDmaBuffer + $11,X
    LDA OamStagingBuffer + $82,Y
    STA OamDmaBuffer + $12,X
    LDA OamStagingBuffer + $83,Y
    STA OamDmaBuffer + $13,X
    LDA OamStagingBuffer + $A0,Y
    STA OamDmaBuffer + $14,X
    LDA OamStagingBuffer + $A1,Y
    STA OamDmaBuffer + $15,X
    LDA OamStagingBuffer + $A2,Y
    STA OamDmaBuffer + $16,X
    LDA OamStagingBuffer + $A3,Y
    STA OamDmaBuffer + $17,X
    LDA OamStagingBuffer + $C0,Y
    STA OamDmaBuffer + $18,X
    LDA OamStagingBuffer + $C1,Y
    STA OamDmaBuffer + $19,X
    LDA OamStagingBuffer + $C2,Y
    STA OamDmaBuffer + $1A,X
    LDA OamStagingBuffer + $C3,Y
    STA OamDmaBuffer + $1B,X
    LDA OamStagingBuffer + $E0,Y
    STA OamDmaBuffer + $1C,X
    LDA OamStagingBuffer + $E1,Y
    STA OamDmaBuffer + $1D,X
    LDA OamStagingBuffer + $E2,Y
    STA OamDmaBuffer + $1E,X
    LDA OamStagingBuffer + $E3,Y
    STA OamDmaBuffer + $1F,X
    TXA
    ADC #OamInterleaveBlockSize
    BEQ FinishDmaOamBuild
    TAX
    JMP CopyNextOamInterleaveBlock

FinishDmaOamBuild:
    LDA #$FF
    STA ScrollUpdatePending
    RTS

OamRotationOffsets:
    .byte $00, $04, $08, $0C, $10, $14, $18, $1C, $00, $04, $08, $0C, $10, $14, $18

UnusedOamRotationOffset:
    .byte $1C

ReusePreviousDmaOam:
    JSR ReverseDmaOam
    LDY #$03
    LDX #$72

WaitForPreviousOamTiming:
    DEX
    BNE WaitForPreviousOamTiming
    DEY
    BNE WaitForPreviousOamTiming
    JMP UpdateScrollLatch

ReverseDmaOam:
    LDX #$00
    LDY #OamBufferSize - OamSpriteSize

SwapNextOamSpritePair:
    LDA OamDmaBuffer,X
    PHA
    LDA OamDmaBuffer + $01,X
    PHA
    LDA OamDmaBuffer + $02,X
    PHA
    LDA OamDmaBuffer + $03,X
    PHA
    LDA OamDmaBuffer,Y
    STA OamDmaBuffer,X
    LDA OamDmaBuffer + $01,Y
    STA OamDmaBuffer + $01,X
    LDA OamDmaBuffer + $02,Y
    STA OamDmaBuffer + $02,X
    LDA OamDmaBuffer + $03,Y
    STA OamDmaBuffer + $03,X
    PLA
    STA OamDmaBuffer + $03,Y
    PLA
    STA OamDmaBuffer + $02,Y
    PLA
    STA OamDmaBuffer + $01,Y
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
    BPL SwapNextOamSpritePair
    RTS

UploadStatusTiles:
    LDA StatusTilesBusy
    BEQ WriteStatusTiles
    JMP UploadRoomCellRow00

WriteStatusTiles:
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$96
    STA PPU_ADDR
    LDA StatusScoreTiles
    STA PPU_DATA
    LDA StatusScoreTiles + $01
    STA PPU_DATA
    LDA StatusScoreTiles + $02
    STA PPU_DATA
    LDA StatusScoreTiles + $03
    STA PPU_DATA
    LDA StatusScoreTiles + $04
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$87
    STA PPU_ADDR
    LDA StatusInventoryTiles
    STA PPU_DATA
    LDA StatusInventoryTiles + $01
    STA PPU_DATA
    LDA StatusInventoryTiles + $05
    STA PPU_DATA
    LDA StatusInventoryTiles + $04
    STA PPU_DATA
    LDA StatusInventoryTiles + $03
    STA PPU_DATA
    LDA StatusInventoryTiles + $02
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A8
    STA PPU_ADDR
    LDA StatusLivesTiles + $01
    STA PPU_DATA
    LDA StatusLivesTiles
    STA PPU_DATA
    LDY #$01
    LDX #$28

WaitForStatusUploadTiming:
    DEX
    BNE WaitForStatusUploadTiming
    DEY
    BNE WaitForStatusUploadTiming
    JMP NmiFrame

NmiTaskHandlerHighBytes:
    .byte $C8, $C8, $C9, $CB, $CC, $CD, $CF, $D0, $D1, $D2, $D4, $D5, $D6, $D7, $D9, $DA
    .byte $DB, $DC, $DE, $DF, $E0, $E1, $E3

NmiTaskHandlerLowBytes:
    .byte $04, $BC, $FF, $42, $85, $C8, $0B, $4E, $91, $D4, $17, $5A, $9D, $E0, $23, $66
    .byte $A9, $EC, $2F, $72, $B5, $F8, $58
