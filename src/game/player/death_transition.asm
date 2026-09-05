; Player death-transition state and reserve-life handling
; CPU range $8DAB-$8DD2
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleAnimatedPlayerHazard:
    LDA PlayerCollisionAnimationCounter
    BPL StartPlayerDeathTransition
    RTS

StartPlayerDeathTransition:
    LDA PlayerDeathInvulnerabilityCountdown
    ORA PlayerTransitionCountdown
    BEQ BeginPlayerDeathTransition
    RTS

BeginPlayerDeathTransition:
    LDA #$80
    STA PlayerTransitionCountdown
    LDA #$00
    STA PlayerActionCountdown
    LDA PlayerLives
    BEQ SetPlayerGameOver
    DEC PlayerLives
    JMP StartPlayerDeathAudio

SetPlayerGameOver:
    LDA #$FF
    STA GameOverActive

StartPlayerDeathAudio:
    JMP LoadAudioTrackSet2
