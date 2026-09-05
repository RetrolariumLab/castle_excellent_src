; Runtime-object overlap scan
; CPU range $A247-$A2A9
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FindRuntimeObjectOverlappingSpan:
    CPX #RuntimeObjectRecordBytes
    BCS ReturnFromRuntimeObjectHandler
    LDA RuntimeObjectRecords,X
    BPL AdvanceRuntimeOverlapCandidate
    CMP #RuntimeOverlapTypeEnd
    BCS AdvanceRuntimeOverlapCandidate
    TAY
    LDA RuntimeOverlapSpanY
    SEC
    SBC RuntimeObjectY,X
    BCC AdvanceRuntimeOverlapCandidate
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvanceRuntimeOverlapCandidate
    LDA RuntimeOverlapSpanXLo
    SEC
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA RuntimeOverlapBoundaryXLo
    LDA RuntimeOverlapSpanXHi
    SBC #$00
    STA RuntimeOverlapBoundaryXHi
    INC RuntimeOverlapBoundaryXLo
    BNE ClampRuntimeOverlapLeftBoundary
    INC RuntimeOverlapBoundaryXHi

ClampRuntimeOverlapLeftBoundary:
    LDA RuntimeOverlapBoundaryXHi
    BPL TestRuntimeOverlapHorizontalBounds
    LDA #$00
    STA RuntimeOverlapBoundaryXHi
    STA RuntimeOverlapBoundaryXLo

TestRuntimeOverlapHorizontalBounds:
    LDA RuntimeObjectXLo,X
    CMP RuntimeOverlapBoundaryXLo
    LDA RuntimeObjectXHi,X
    SBC RuntimeOverlapBoundaryXHi
    BCC AdvanceRuntimeOverlapCandidate
    LDA RuntimeOverlapSpanXLo
    CLC
    ADC RuntimeOverlapSpanWidth
    STA RuntimeOverlapBoundaryXLo
    LDA RuntimeOverlapSpanXHi
    ADC #$00
    STA RuntimeOverlapBoundaryXHi
    LDA RuntimeObjectXLo,X
    CMP RuntimeOverlapBoundaryXLo
    LDA RuntimeObjectXHi,X
    SBC RuntimeOverlapBoundaryXHi
    BCS AdvanceRuntimeOverlapCandidate
    RTS

AdvanceRuntimeOverlapCandidate:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC FindRuntimeObjectOverlappingSpan

ReturnFromRuntimeObjectHandler:
    RTS
