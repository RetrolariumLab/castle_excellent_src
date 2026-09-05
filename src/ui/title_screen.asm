; Title screen, input edge, and attract-mode timeout
; CPU range $F8FC-$F972
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RunTitleScreen:
    LDA #TitleNametableChrPage
    JSR CopyChrNametablePagesToVram
    LDA #>TitlePaletteData
    STA TitlePalettePointerHi
    LDA #<TitlePaletteData
    STA TitlePalettePointerLo
    JSR UploadPaletteFromPointer
    LDY #TitleChrBank
    JSR SelectChrBank
    JSR ResetPpuScroll
    LDX #$00
    STX TitleFrameCounterLo
    STX TitleFrameCounterHi
    DEX
    STX DemoPlaybackActive
    JSR InitializeTitleDemoPlayback
    JSR LoadAudioTrackSet5
    SEI

WaitForTitleSetupVblank:
    LDA PPU_STATUS
    BPL WaitForTitleSetupVblank
    LDA #TitlePpuMask
    STA PPU_MASK
    LDA #TitlePpuControl
    STA PPU_CTRL
    JSR ReadController1WithoutNmiControl
    EOR #$FF
    STA PreviousController1Buttons

WaitForTitleFrameVblank:
    LDA PPU_STATUS
    BPL WaitForTitleFrameVblank
    JSR UpdateAudioStreams
    INC TitleFrameCounterLo
    BNE CheckTitleTimeout
    INC TitleFrameCounterHi

CheckTitleTimeout:
    LDA TitleFrameCounterHi
    CMP #TitleTimeoutHighByte
    BCS ExitTitleScreen
    JSR ReadController1WithoutNmiControl
    TAX
    AND PreviousController1Buttons
    AND #SubCommandStartButtonMask
    PHA
    TXA
    EOR #$FF
    STA PreviousController1Buttons
    PLA
    BEQ WaitForTitleFrameVblank
    LDA #$00
    STA DemoPlaybackActive

ExitTitleScreen:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$00
    JMP SelectChrBank
