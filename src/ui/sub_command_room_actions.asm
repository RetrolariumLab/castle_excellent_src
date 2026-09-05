; Sub-command current and previous room restoration
; CPU range $FBAC-$FBFD
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ResetCurrentRoomFromSubCommand:
    LDA PlayerLives
    BNE BeginSubCommandCurrentRoomReset
    JMP UpdateSubCommandMenu

BeginSubCommandCurrentRoomReset:
    JSR LoadRoomPersistentState
    LDX #$0D

CopySubCommandCurrentRoomState:
    LDA RoomRuntimeLoadMirror,X
    STA SubCommandActiveRoomRuntimeState,X
    DEX
    BPL CopySubCommandCurrentRoomState

RestoreSubCommandPlayerState:
    LDA SubCommandActiveRoomRuntimeState + $0B
    STA PlayerXLo
    LDA SubCommandActiveRoomRuntimeState + $0C
    STA PlayerXHi
    LDA SubCommandActiveRoomRuntimeState + $0D
    STA PlayerY
    DEC PlayerLives
    LDA #$00
    STA SubCommandScreenState
    JMP RebuildLoadedRoom

ReturnToPreviousRoomFromSubCommand:
    LDA PlayerLives
    BNE CheckSubCommandPreviousRoomSnapshot
    JMP UpdateSubCommandMenu

CheckSubCommandPreviousRoomSnapshot:
    LDA RoomStateSnapshotA
    BNE BeginSubCommandPreviousRoomRestore
    JMP UpdateSubCommandMenu

BeginSubCommandPreviousRoomRestore:
    STA CurrentRoomNumber
    JSR RestoreRoomStateSnapshotA
    LDX #$0D

CopySubCommandPreviousRoomState:
    LDA RoomRuntimeStateSnapshotA,X
    STA SubCommandActiveRoomRuntimeState,X
    DEX
    BPL CopySubCommandPreviousRoomState
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    BEQ RestoreSubCommandPlayerState
