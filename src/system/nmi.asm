; NMI frame handler and scheduler
; CPU range $C55D-$C6B8
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
    LDA PendingScrollX
    STA AppliedScrollX

ApplyHorizontalScroll:
    LDA CastleMapMode
    BNE AdvanceNmiTaskScheduler
    LDA PPU_STATUS
    LDA AppliedScrollX
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
