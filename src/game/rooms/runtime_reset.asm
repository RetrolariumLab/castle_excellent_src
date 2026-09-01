; Room-runtime reset and conditional room-audio restart
; CPU range $A3AC-$A3D1
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ResetRoomRuntimeState:
    LDA #$00
    STA ResetPlayerMovementStateA
    STA ResetPlayerMovementDelay
    STA NmiTaskIndex
    STA PendingScrollX
    STA AppliedScrollX
    STA ResetPlayerMovementLatch
    STA ResetRuntimeObjectUpdateSharedFlag
    STA ResetPlayerMovementStateB
    STA RoomFrameCounter
    STA ResetRoomCellAnimationCounter
    RTS

EnsureRoomAudioPlaying:
    LDA GameOverActive
    BNE ReturnWithoutRoomAudioRestart
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BEQ SelectRoomAudio

ReturnWithoutRoomAudioRestart:
    RTS
