; Frame-level player collision sampling and hazard dispatch
; CPU range $9386-$93F5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdatePlayerCollisionState:
    LDA PlayerTransitionCountdown
    BEQ SamplePlayerCollisionPoints
    JMP AdvancePlayerTransitionCountdown

SamplePlayerCollisionPoints:
    LDY PlayerY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerCollisionHazardCellContact
    BEQ ReturnFromPlayerCollisionUpdate
    LDA PlayerCollisionHazardProtectionCountdown
    BNE ReturnFromPlayerCollisionUpdate
    JMP StartPlayerDeathTransition

ReturnFromPlayerCollisionUpdate:
    RTS
