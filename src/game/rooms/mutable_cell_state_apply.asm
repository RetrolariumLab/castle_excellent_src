; Mutable-cell state bit application
; CPU range $EDEF-$EE55
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ApplyMutableCellStateBit:
    LDA #>RoomCells
    STA MutableCellScanPointerHi
    LDA #<RoomCells
    STA MutableCellScanPointerLo

ScanMutableCellCandidates:
    LDY #$00
    LDA (MutableCellScanPointerLo),Y
    CMP #$54
    BEQ SelectMutableCellCandidate
    JSR IsPersistentMutableCell
    BNE AdvanceMutableCellCandidateScan

SelectMutableCellCandidate:
    DEX
    BNE AdvanceMutableCellCandidateScan
    LDA MutableCellScanPointerLo
    BNE MoveToMutableCellLeftNeighbor
    DEC MutableCellScanPointerHi

MoveToMutableCellLeftNeighbor:
    DEC MutableCellScanPointerLo
    LDY #$00
    LDA (MutableCellScanPointerLo),Y
    CMP #$16
    BEQ RestoreMutableCellBesideType16
    LDY #$02
    LDA (MutableCellScanPointerLo),Y
    CMP #$16
    BNE RestoreStandaloneMutableCell

RestoreMutableCellBesideType16:
    INC MutableCellScanPointerLo
    BNE WriteMutableCellBesideType16
    INC MutableCellScanPointerHi

WriteMutableCellBesideType16:
    LDY #$00
    LDA #$62
    STA (MutableCellScanPointerLo),Y
    LDY #RoomWidth
    LDA #$63
    STA (MutableCellScanPointerLo),Y
    RTS

RestoreStandaloneMutableCell:
    INC MutableCellScanPointerLo
    BNE WriteStandaloneMutableCell
    INC MutableCellScanPointerHi

WriteStandaloneMutableCell:
    LDY #$00
    LDA #$54
    STA (MutableCellScanPointerLo),Y
    LDA #$55
    LDY #RoomWidth
    STA (MutableCellScanPointerLo),Y
    RTS

AdvanceMutableCellCandidateScan:
    INC MutableCellScanPointerLo
    BNE CheckMutableCellCandidateScanEnd
    INC MutableCellScanPointerHi

CheckMutableCellCandidateScanEnd:
    LDA MutableCellScanPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA MutableCellScanPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanMutableCellCandidates
    RTS
