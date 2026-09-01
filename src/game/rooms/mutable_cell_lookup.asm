; Mutable room-cell lookup and ordinal calculation
; CPU range $A66D-$A6C9
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FindMutableCellOrdinalAtPosition:
    STX MutableCellTileColumn
    STY MutableCellTileRow
    JSR GetRoomCellPointer
    LDY #$00
    LDA (RoomCellPointerLo),Y
    CMP #$55
    BEQ UseMutableCellAbove
    CMP #$63
    BEQ UseMutableCellAbove
    JSR IsPersistentMutableRightCell
    BNE CheckMutableCellAnchor

UseMutableCellAbove:
    DEC MutableCellTileRow
    LDX MutableCellTileColumn
    LDY MutableCellTileRow
    JSR GetRoomCellPointer
    LDY #$00
    LDA (RoomCellPointerLo),Y

CheckMutableCellAnchor:
    CMP #$54
    BEQ CountMutableCellOrdinal
    CMP #$62
    BEQ CountMutableCellOrdinal
    JSR IsPersistentMutableCell
    BEQ CountMutableCellOrdinal
    SEC
    RTS

CountMutableCellOrdinal:
    LDX #$01
    LDY #$00

ScanPreviousMutableCell:
    LDA RoomCellPointerLo
    BNE MoveToPreviousRoomCell
    LDA RoomCellPointerHi
    CMP #$04
    BEQ ReturnMutableCellOrdinal

MoveToPreviousRoomCell:
    LDA RoomCellPointerLo
    BNE ReadPreviousRoomCell
    DEC RoomCellPointerHi

ReadPreviousRoomCell:
    DEC RoomCellPointerLo
    LDY #$00
    LDA (RoomCellPointerLo),Y
    CMP #$54
    BEQ CountPreviousMutableCell
    JSR IsPersistentMutableCell
    BNE ScanPreviousMutableCell

CountPreviousMutableCell:
    INX
    JMP ScanPreviousMutableCell

ReturnMutableCellOrdinal:
    CLC
    RTS
