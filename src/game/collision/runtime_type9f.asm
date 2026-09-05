; Runtime type $9F player collision handler
; CPU range $8D3D-$8D56
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleRuntimeType9FPlayerCollision:
    LDA RoomFrameCounter
    BPL ReturnFromRuntimeType9FCollision
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    BEQ CheckRuntimeType9FAudio

ReturnFromRuntimeType9FXMismatch:
    RTS

CheckRuntimeType9FAudio:
    LDA RuntimeType9FInvulnerabilityCountdown
    BNE RefreshRuntimeType9FInvulnerability
    JSR LoadAudioTrackSet3

RefreshRuntimeType9FInvulnerability:
    LDA #RuntimeType9FInvulnerabilityDuration
    STA RuntimeType9FInvulnerabilityCountdown

ReturnFromRuntimeType9FCollision:
    RTS
