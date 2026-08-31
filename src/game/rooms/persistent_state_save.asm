; Room-state snapshot persistence writer
; CPU range $FDC5-$FE30
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SaveRoomStateSnapshotB:
    LDA RoomStateSnapshotB
    BEQ ReturnRoomPersistentStateSaved
    TAY
    LDA RoomObjectStateOffsets,Y
    SEC
    SBC RoomObjectStateOffsets - 1,Y
    TAY
    LDX RoomStateSnapshotB
    LDA RoomObjectStateOffsets - 1,X
    TAX
    LDA RoomObjectStateSnapshotB
    STA RoomObjectPersistentState,X
    DEY
    BEQ SaveRoomMutableCellState
    LDA RoomObjectStateSnapshotB + 1
    STA RoomObjectPersistentState + 1,X
    DEY
    BEQ SaveRoomMutableCellState
    LDA RoomObjectStateSnapshotB + 2
    STA RoomObjectPersistentState + 2,X

SaveRoomMutableCellState:
    LDY RoomStateSnapshotB
    LDA RoomMutableCellStateOffsets,Y
    SEC
    SBC RoomMutableCellStateOffsets - 1,Y
    TAY
    BEQ ReturnRoomPersistentStateSaved
    LDX RoomStateSnapshotB
    LDA RoomMutableCellStateOffsets - 1,X
    TAX
    LDA RoomMutableCellStateSnapshotB
    STA RoomMutableCellPersistentState,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 1
    STA RoomMutableCellPersistentState + 1,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 2
    STA RoomMutableCellPersistentState + 2,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 3
    STA RoomMutableCellPersistentState + 3,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 4
    STA RoomMutableCellPersistentState + 4,X

ReturnRoomPersistentStateSaved:
    RTS
