; Mutable room-cell restoration and render requests
; CPU range $A70A-$A7DA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RestoreMutableCellByOrdinal:
    LDA #>RoomCells
    STA MutableCellRestorePointerHi
    LDA #<RoomCells
    STA MutableCellRestorePointerLo
    STX RestoredMutableCellOrdinal

ScanNextMutableCell:
    LDY #$00
    LDA (MutableCellRestorePointerLo),Y
    CMP #$54
    BEQ SelectMutableCellOrdinal
    JSR IsPersistentMutableCell
    BEQ SelectMutableCellOrdinal
    JMP AdvanceMutableCellScan

SelectMutableCellOrdinal:
    DEX
    BEQ InspectMutableCellNeighbors
    JMP AdvanceMutableCellScan

InspectMutableCellNeighbors:
    LDA MutableCellRestorePointerLo
    BNE ReadMutableCellLeftNeighbor
    DEC MutableCellRestorePointerHi

ReadMutableCellLeftNeighbor:
    DEC MutableCellRestorePointerLo
    LDY #$00
    LDA (MutableCellRestorePointerLo),Y
    CMP #$16
    BEQ RestoreAlternateMutableCell
    LDY #$02
    LDA (MutableCellRestorePointerLo),Y
    CMP #$16
    BNE RestoreStandardMutableCell

RestoreAlternateMutableCell:
    INC MutableCellRestorePointerLo
    BNE WriteAlternateMutableCell
    INC MutableCellRestorePointerHi

WriteAlternateMutableCell:
    LDY #$00
    LDA #$62
    STA (MutableCellRestorePointerLo),Y
    LDY #RoomWidth
    LDA #$63
    STA (MutableCellRestorePointerLo),Y
    JMP PersistRestoredMutableCell

RestoreStandardMutableCell:
    INC MutableCellRestorePointerLo
    BNE WriteStandardMutableCell
    INC MutableCellRestorePointerHi

WriteStandardMutableCell:
    LDY #$00
    LDA #$54
    STA (MutableCellRestorePointerLo),Y
    LDA #$55
    LDY #RoomWidth
    STA (MutableCellRestorePointerLo),Y

PersistRestoredMutableCell:
    LDA MutableCellRestorePointerLo
    STA RestoredMutableCellAddressLo
    LDA MutableCellRestorePointerHi
    STA RestoredMutableCellAddressHi
    JSR RequestRoomCellRowUpdates
    DEC RestoredMutableCellOrdinal
    LDA RestoredMutableCellOrdinal
    AND #$07
    TAX
    LDA MutableCellStateBitMasks,X
    PHA
    LDA RestoredMutableCellOrdinal
    LSR A
    LSR A
    LSR A
    TAX
    PLA
    ORA CurrentRoomMutableCellState,X
    STA CurrentRoomMutableCellState,X
    LDA MutableCellRestorePointerHi
    AND #$01
    STA MutableCellRestorePointerHi
    LDY #$07

ComputeRestoredMutableCellRow:
    LDA MutableCellRestorePointerLo
    CMP #RoomWidth
    LDA MutableCellRestorePointerHi
    SBC #$00
    BCC RequestRestoredCellAttributes
    LDA MutableCellRestorePointerLo
    SBC #RoomWidth
    STA MutableCellRestorePointerLo
    INY
    BCS ComputeRestoredMutableCellRow
    DEC MutableCellRestorePointerHi
    JMP ComputeRestoredMutableCellRow

RequestRestoredCellAttributes:
    LDA MutableCellRestorePointerLo
    ASL A
    CLC
    ADC #$04
    TAX
    JSR GetRoomAttributeMaskAndOffset
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributeScratch,X
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

AdvanceMutableCellScan:
    INC MutableCellRestorePointerLo
    BNE CheckMutableCellScanEnd
    INC MutableCellRestorePointerHi

CheckMutableCellScanEnd:
    LDA MutableCellRestorePointerLo
    CMP #<RoomMutableCellPersistentState
    LDA MutableCellRestorePointerHi
    SBC #>RoomMutableCellPersistentState
    BCS ReturnMutableCellNotFound
    JMP ScanNextMutableCell

ReturnMutableCellNotFound:
    RTS
