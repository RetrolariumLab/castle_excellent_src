; Runtime-type filtering and mutable-cell collision normalization
; CPU range $9552-$9577
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

IsRuntimeObjectType90To95:
    CMP #$90
    BCC ReturnRuntimeObjectTypeOutsideRange
    CMP #$96
    BCS ReturnRuntimeObjectTypeOutsideRange
    RTS

ReturnRuntimeObjectTypeOutsideRange:
    SEC
    RTS

SampleNormalizedRoomCollisionCell:
    JSR SampleCollisionAtPixel
    PHP
    CMP #$62
    BEQ NormalizeMutableCollisionCell
    CMP #$63
    BEQ NormalizeMutableCollisionCell
    CMP #$54
    BEQ NormalizeMutableCollisionCell
    CMP #$55
    BEQ NormalizeMutableCollisionCell
    PLP
    RTS

NormalizeMutableCollisionCell:
    LDA #$53
    PLP
    CLC
    RTS
