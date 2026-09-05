; Room-transition state mirroring and rendering resume
; CPU range $952D-$9551
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FinishRoomTransition:
    LDA #$FF
    STA PauseMode
    LDA TransitionPlayerXLo
    STA RoomRuntimeLoadMirror + $0B
    LDA TransitionPlayerXHi
    STA RoomRuntimeLoadMirror + $0C
    LDA TransitionPlayerY
    STA RoomRuntimeLoadMirror + $0D
    LDA TransitionHazardProtectionCountdown
    STA TransitionHazardProtectionMirror
    LDA TransitionInvulnerabilityCountdown
    STA TransitionInvulnerabilityMirror
    JSR ResetPpuScroll
    JSR EnableNmi
    JMP WaitForVblankAndEnableRendering
