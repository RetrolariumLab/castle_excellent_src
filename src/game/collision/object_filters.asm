; Animated-cell and runtime-object collision filters
; CPU range $A044-$A0C3
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ClassifyAnimatedCollisionCell:
    CMP #DecrementingAnimatedCellFirst
    BCC TestIncrementingAnimatedCollisionCell
    CMP #DecrementingAnimatedCellEnd
    BCS TestIncrementingAnimatedCollisionCell
    LDY #$00
    SEC
    RTS

TestIncrementingAnimatedCollisionCell:
    CMP #IncrementingAnimatedCellFirst
    BCC ReturnNonAnimatedCollisionCell
    CMP #IncrementingAnimatedCellEnd
    BCS ReturnNonAnimatedCollisionCell
    LDY #$FF
    SEC
    RTS

ReturnNonAnimatedCollisionCell:
    CLC
    RTS

GetRuntimeObjectType84To89Filter:
    TAY
    PHP
    BPL ReturnNonRuntimeObjectType84To89Filter
    PLP
    LDA RuntimeObjectType84To89FilterValues - RuntimeObjectCollisionTypeFirst,Y
    RTS

ReturnNonRuntimeObjectType84To89Filter:
    PLP
    LDA #$FF
    RTS

RuntimeObjectType84To89FilterValues:
    .byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF

GetRuntimeObjectSolidFlag:
    TAY
    PHP
    BPL ReturnNonRuntimeObjectSolidFlag
    PLP
    LDA RuntimeObjectSolidFlags - RuntimeObjectCollisionTypeFirst,Y
    RTS

ReturnNonRuntimeObjectSolidFlag:
    PLP
    LDA #$FF
    RTS

RuntimeObjectSolidFlags:
    .byte $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $00
    .byte $FF, $FF, $FF, $FF, $FF, $FF
