; Player and object-span overlap test
; CPU range $9613-$965B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

TestPlayerAgainstObjectSpan:
    LDA ObjectSpanY
    CLC
    ADC #PlayerObjectVerticalSpan
    SEC
    SBC PlayerY
    BCC ReturnPlayerOutsideObjectSpan
    SBC #PlayerObjectVerticalSpan
    BCS ReturnPlayerOutsideObjectSpan
    LDA ObjectSpanXLo
    SEC
    SBC #PlayerObjectLeftReach
    STA ObjectSpanBoundaryXLo
    LDA ObjectSpanXHi
    SBC #$00
    STA ObjectSpanBoundaryXHi
    LDA ObjectSpanBoundaryXHi
    BPL ComparePlayerXWithObjectSpanStart
    LDA #$00
    STA ObjectSpanBoundaryXHi
    STA ObjectSpanBoundaryXLo

ComparePlayerXWithObjectSpanStart:
    LDA PlayerXLo
    CMP ObjectSpanBoundaryXLo
    LDA PlayerXHi
    SBC ObjectSpanBoundaryXHi
    BCC ReturnPlayerOutsideObjectSpan
    LDA ObjectSpanXLo
    CLC
    ADC ObjectSpanWidth
    STA ObjectSpanBoundaryXLo
    LDA ObjectSpanXHi
    ADC #$00
    STA ObjectSpanBoundaryXHi
    LDA PlayerXLo
    CMP ObjectSpanBoundaryXLo
    LDA PlayerXHi
    SBC ObjectSpanBoundaryXHi
    BCS ReturnPlayerOutsideObjectSpan
    RTS

ReturnPlayerOutsideObjectSpan:
    SEC
    RTS
