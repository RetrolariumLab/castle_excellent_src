; Room-cell pointer conversion and NMI row update requests
; CPU range $949C-$94DA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RequestRoomCellRowUpdate:
    JSR GetRoomCellRowFromPointer
    LDA #NmiTaskPending
    STA NmiTaskRequests + $01,Y
    RTS

UnreferencedSingleRowIndexShimBytes:
    .byte $4A, $4A, $4A, $A8, $4C, $9F, $94

RequestRoomCellRowUpdates:
    JSR GetRoomCellRowFromPointer
    LDA #NmiTaskPending
    STA NmiTaskRequests + $01,Y
    CPY #RoomHeight
    BCS ReturnRoomCellRowUpdates
    STA NmiTaskRequests + $02,Y

ReturnRoomCellRowUpdates:
    RTS

UnreferencedAdjacentRowIndexShimBytes:
    .byte $4A, $4A, $4A, $A8, $4C, $AF, $94

GetRoomCellRowFromPointer:
    LSR RoomCellUpdateAddressHi
    ROR RoomCellUpdateAddressLo
    LSR RoomCellUpdateAddressHi
    ROR RoomCellUpdateAddressLo
    LDA RoomCellUpdateAddressLo
    AND #RoomCellPointerRowMask
    LDY #$00

DivideRoomCellPointerByRowStride:
    CMP #RoomCellPointerRowDivisor
    BCC ReturnRoomCellRow
    INY
    SBC #RoomCellPointerRowDivisor
    BCS DivideRoomCellPointerByRowStride

ReturnRoomCellRow:
    RTS
