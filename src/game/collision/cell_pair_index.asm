; Collision-cell pair lookup-index classification
; CPU range $A6CA-$A6D7
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ClassifyCollisionCellPairIndex:
    CPX #CollisionCellPairIndexFirst
    BCC ReturnOrdinaryCollisionCellPair
    CPX #CollisionCellPairIndexEnd
    BCS ReturnOrdinaryCollisionCellPair
    LDY #CollisionCellPairMatched
    RTS

ReturnOrdinaryCollisionCellPair:
    LDY #CollisionCellPairNotMatched
    RTS
