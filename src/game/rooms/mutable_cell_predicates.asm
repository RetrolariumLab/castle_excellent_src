; Persistent mutable-cell predicates
; CPU range $A6D8-$A709
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

IsPersistentMutableCell:
    CMP #$19
    BCC ReturnMutableCellPredicate
    BEQ ReturnMutableCellPredicate
    CMP #$29
    BCS ReturnMutableCellPredicate
    CMP #$1C
    BEQ ReturnMutableCellPredicate
    CMP #$1F
    BEQ ReturnMutableCellPredicate
    CMP #$22
    BEQ ReturnMutableCellPredicate
    CMP #$25
    RTS

IsPersistentMutableRightCell:
    CMP #$1A
    BCC ReturnMutableCellPredicate
    BEQ ReturnMutableCellPredicate
    CMP #$2A
    BCS ReturnMutableCellPredicate
    CMP #$1D
    BEQ ReturnMutableCellPredicate
    CMP #$20
    BEQ ReturnMutableCellPredicate
    CMP #$23
    BEQ ReturnMutableCellPredicate
    CMP #$26

ReturnMutableCellPredicate:
    RTS
