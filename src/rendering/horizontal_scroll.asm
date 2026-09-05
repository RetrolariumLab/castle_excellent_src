; Player-following horizontal scroll update
; CPU range $C43D-$C479
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
