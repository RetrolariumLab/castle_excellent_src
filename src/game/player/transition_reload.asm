; Player transition countdown and current-room reload
; CPU range $93F6-$9476
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

AdvancePlayerTransitionCountdown:
    DEC PlayerTransitionCountdown
    BEQ CompletePlayerTransition
    RTS

CompletePlayerTransition:
    LDA TransitionPlayerXLo
    STA PlayerXLo
    LDA TransitionPlayerXHi
    STA PlayerXHi
    LDA TransitionPlayerY
    STA PlayerY
    LDA TransitionHazardProtectionMirror
    ORA PlayerTransitionScreenState
    BEQ FinishPlayerTransitionState
    LDA TransitionHazardProtectionMirror
    CMP PlayerCollisionHazardProtectionCountdown
    BCS SelectPlayerTransitionProtectionBase
    LDA PlayerCollisionHazardProtectionCountdown

SelectPlayerTransitionProtectionBase:
    LDY PlayerTransitionScreenState
    BEQ AddPlayerTransitionProtectionBonus
    LDA #$28

AddPlayerTransitionProtectionBonus:
    CLC
    ADC #$0A
    STA PlayerCollisionHazardProtectionCountdown

FinishPlayerTransitionState:
    LDA #$00
    STA PlayerTransitionCountdown
    LDA PlayerLives
    BNE ReloadCurrentRoomAfterPlayerTransition
    LDA GameOverActive
    BEQ ReloadCurrentRoomAfterPlayerTransition
    JMP RunGameOverSequence

ReloadCurrentRoomAfterPlayerTransition:
    JSR SaveCurrentRoomObjectState
    LDX CurrentRoomNumber
    DEX
    JSR DecodeRoom
    JSR LoadRoomObjects
    LDX #$02

CopyReloadRoomObjectState:
    LDA CurrentRoomObjectState,X
    STA ReloadRoomObjectStateBits,X
    DEX
    BPL CopyReloadRoomObjectState
    LDX #$04

CopyReloadRoomMutableCellState:
    LDA CurrentRoomMutableCellState,X
    STA ReloadRoomMutableCellStateBits,X
    DEX
    BPL CopyReloadRoomMutableCellState
    JSR ApplyRoomPersistentState
    JSR ResetRoomRuntimeState
    JSR ResetNmiTaskRequests
    JSR ClearRoomNametablesAndSprites
    JSR InitializeRoomStatusDisplay
    JSR BuildRoomAttributeTables
    JSR UploadRoomAttributeTables
    JSR UpdateHorizontalScroll
    LDA #$FF
    STA PauseMode
    JSR WaitForVblankAndEnableRendering
    JMP EnableNmi
