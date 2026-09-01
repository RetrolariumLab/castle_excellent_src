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
    LDA TransitionStateByte0
    STA TransitionStateMirror0
    LDA TransitionStateByte1
    STA TransitionStateMirror1
    JSR ResetPpuScroll
    JSR EnableNmi
    JMP WaitForVblankAndEnableRendering
