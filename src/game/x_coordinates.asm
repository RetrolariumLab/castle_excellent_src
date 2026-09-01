; Player and runtime-object 16-bit X-coordinate helpers
; CPU range $94DB-$952C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

GetPlayerXPlus7:
    LDA #$07
    BNE AddPlayerXOffset

GetPlayerXPlus15:
    LDA #$0F

AddPlayerXOffset:
    CLC
    ADC PlayerXLo
    TAX
    LDA PlayerXHi
    ADC #$00
    RTS

GetRuntimeObjectX:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    TAX
    PLA
    RTS

GetRuntimeObjectXPlus7:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$07
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus8:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$08
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus15:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$0F
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus17:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$11

ReturnOffsetRuntimeObjectX:
    TAX
    PLA
    ADC #$00
    RTS

GetRuntimeObjectXMinus2:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    TAX
    PLA
    SBC #$00
    RTS
