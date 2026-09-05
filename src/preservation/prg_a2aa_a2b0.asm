; Preservation helper before new-game initialization
; CPU range $A2AA-$A2B0
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

    .byte $98, $4A
    LSR A
    LSR A
    STA NmiTaskIndex
    RTS
