; Room object loading, state selection, and snapshot rotation
; CPU range $EC63-$ECB6
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

LoadRoomObjectsAndState:
    JSR LoadRoomObjects
    JSR SaveRoomStateSnapshotB
    LDX #RoomStateRecordSize - 1

RotateRoomStateSnapshots:
    LDA CurrentRoomState,X
    STA RoomStateSnapshotB,X
    LDA RoomStateLoadMirror,X
    STA RoomStateSnapshotA,X
    DEX
    BPL RotateRoomStateSnapshots
    LDX #RoomRuntimeSnapshotSize - 1

RotateRoomRuntimeSnapshots:
    LDA ActiveRoomRuntimeState,X
    STA RoomRuntimeStateSnapshotB,X
    LDA RoomRuntimeLoadMirror,X
    STA RoomRuntimeStateSnapshotA,X
    DEX
    BPL RotateRoomRuntimeSnapshots

SelectAndApplyRoomState:
    LDX CurrentRoomIndex
    CPX RoomStateSnapshotB
    BNE LoadPersistentStateForRoom
    STX CurrentRoomState
    JSR RestoreRoomStateSnapshotB
    JMP MirrorSelectedRoomState

LoadPersistentStateForRoom:
    JSR LoadRoomPersistentState

MirrorSelectedRoomState:
    LDA CurrentRoomIndex
    STA CurrentRoomState
    LDX #RoomStateRecordSize - 1

CopyRoomStateLoadMirror:
    LDA CurrentRoomState,X
    STA RoomStateLoadMirror,X
    DEX
    BPL CopyRoomStateLoadMirror
    LDX #RoomRuntimeLoadMirrorSize - 1

CopyRoomRuntimeLoadMirror:
    LDA ActiveRoomRuntimeState,X
    STA RoomRuntimeLoadMirror,X
    DEX
    BPL CopyRoomRuntimeLoadMirror
