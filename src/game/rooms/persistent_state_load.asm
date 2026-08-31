; Room-state snapshot restore and persistent-state loading
; CPU range $EE56-$EF05
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RestoreRoomStateSnapshotB:
    LDX #$03

RestoreSnapshotBObjectState:
    LDA RoomStateSnapshotB,X
    STA CurrentRoomState,X
    STA LoadedRoomObjectStateBits - 1,X
    DEX
    BNE RestoreSnapshotBObjectState
    LDX #$04

RestoreSnapshotBMutableCellState:
    LDA RoomMutableCellStateSnapshotB,X
    STA CurrentRoomMutableCellState,X
    STA LoadedRoomMutableCellStateBits,X
    DEX
    BPL RestoreSnapshotBMutableCellState
    RTS

RestoreRoomStateSnapshotA:
    LDX #$03

RestoreSnapshotAObjectState:
    LDA RoomStateSnapshotA,X
    STA CurrentRoomState,X
    STA LoadedRoomObjectStateBits - 1,X
    DEX
    BNE RestoreSnapshotAObjectState
    LDX #$04

RestoreSnapshotAMutableCellState:
    LDA RoomMutableCellStateSnapshotA,X
    STA CurrentRoomMutableCellState,X
    STA LoadedRoomMutableCellStateBits,X
    DEX
    BPL RestoreSnapshotAMutableCellState
    RTS

LoadRoomPersistentState:
    LDA #$00
    LDX #$07

ClearLoadedRoomStateBits:
    STA LoadedRoomObjectStateBits,X
    DEX
    BPL ClearLoadedRoomStateBits
    LDX CurrentRoomIndex
    LDA RoomObjectStateOffsets,X
    SEC
    SBC RoomObjectStateOffsets - 1,X
    TAY
    LDA RoomObjectStateOffsets - 1,X
    TAX
    LDA RoomObjectPersistentState,X
    STA LoadedRoomObjectStateBits
    STA CurrentRoomObjectState
    DEY
    BEQ LoadRoomMutableCellState
    LDA RoomObjectPersistentState + 1,X
    STA LoadedRoomObjectStateBits + 1
    STA CurrentRoomObjectState + 1
    DEY
    BEQ LoadRoomMutableCellState
    LDA RoomObjectPersistentState + 2,X
    STA LoadedRoomObjectStateBits + 2
    STA CurrentRoomObjectState + 2

LoadRoomMutableCellState:
    LDX CurrentRoomIndex
    LDA RoomMutableCellStateOffsets,X
    SEC
    SBC RoomMutableCellStateOffsets - 1,X
    TAY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellStateOffsets - 1,X
    TAX
    LDA RoomMutableCellPersistentState,X
    STA LoadedRoomMutableCellStateBits
    STA CurrentRoomMutableCellState
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 1,X
    STA LoadedRoomMutableCellStateBits + 1
    STA CurrentRoomMutableCellState + 1
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 2,X
    STA LoadedRoomMutableCellStateBits + 2
    STA CurrentRoomMutableCellState + 2
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 3,X
    STA LoadedRoomMutableCellStateBits + 3
    STA CurrentRoomMutableCellState + 3
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 4,X
    STA LoadedRoomMutableCellStateBits + 4
    STA CurrentRoomMutableCellState + 4

ReturnRoomPersistentStateLoaded:
    RTS
