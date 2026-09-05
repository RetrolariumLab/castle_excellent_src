; Sub-command menu entry gating and controller edge detection
; CPU range $F9AD-$F9CB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleSubCommandInput:
    LDA GameOverActive
    BEQ CheckSubCommandDemoGate
    RTS

CheckSubCommandDemoGate:
    LDA DemoPlaybackActive
    BEQ DetectSubCommandOpenEdge
    RTS

DetectSubCommandOpenEdge:
    LDA PreviousController2Buttons
    EOR #$FF
    AND Controller2Buttons
    AND #SubCommandOpenButtonMask
    BNE OpenSubCommandMenu
    LDA Controller2Buttons
    STA PreviousController2Buttons
    RTS
