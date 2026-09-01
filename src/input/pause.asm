; Pause toggle and paused horizontal-scroll input
; CPU range $A8E3-$A959
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandlePauseInput:
    LDA Controller1Buttons
    AND #PauseResumeButtons
    BEQ CheckPauseStartEdge
    LDA PreviousController1Buttons
    AND #PauseResumeButtons
    BNE CheckPauseStartEdge
    LDA PauseMode
    BNE LeavePauseMode

CheckPauseStartEdge:
    LDA Controller1Buttons
    AND #ControllerButtonStart
    BEQ CheckPausedScrollInput
    LDA PreviousController1Buttons
    AND #ControllerButtonStart
    BNE CheckPausedScrollInput
    LDA PauseMode
    BNE LeavePauseMode
    LDA #ApuChannelsDisabled
    STA APU_STATUS
    LDA #PauseModeActive
    BNE StorePauseMode

LeavePauseMode:
    LDA #PauseModeInactive

StorePauseMode:
    STA PauseMode
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

CheckPausedScrollInput:
    LDA PauseMode
    BNE UpdatePausedScroll
    RTS

UpdatePausedScroll:
    LDA Controller1Buttons
    AND #ControllerButtonLeft
    BEQ CheckPausedScrollRight
    LDA PausedScrollX
    SEC
    SBC #PauseScrollStep
    BCS StorePausedScrollLeft
    LDA #PauseScrollMinimum

StorePausedScrollLeft:
    STA PausedScrollX
    LDA #PauseScrollUpdateRequested
    STA PausedScrollUpdatePending
    JMP RememberPauseButtons

CheckPausedScrollRight:
    LDA Controller1Buttons
    AND #ControllerButtonRight
    BEQ RememberPauseButtons
    LDA PausedScrollX
    CLC
    ADC #PauseScrollStep
    BPL StorePausedScrollRight
    LDA #PauseScrollMaximum

StorePausedScrollRight:
    STA PausedScrollX
    LDA #PauseScrollUpdateRequested
    STA PausedScrollUpdatePending

RememberPauseButtons:
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS
