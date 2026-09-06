; Fairy bobbing and Fighter player-triggered jump updates
; CPU range $9CC6-$9D64
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateFairy:
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #FairyVerticalFrameMask
    STA FairyVerticalFrameBit
    LDA RuntimeObjectY,X
    AND #FairyVerticalAlignmentMask
    ORA FairyVerticalFrameBit
    STA RuntimeObjectY,X
    RTS

UpdateFighter:
    JSR MeasureCurrentObjectPlayerXSeparation
    LDA FighterPlayerXSeparationHi
    BNE UpdateFighterJumpState
    LDA FighterPlayerXSeparationLo
    CMP #FighterPlayerRange
    BCS UpdateFighterJumpState
    LDX CurrentRuntimeObjectOffset
    LDA PlayerY
    SEC
    SBC #FighterPlayerYOffset
    CMP RuntimeObjectY,X
    BCC UpdateFighterJumpState
    LDA #FighterNearPlayerFlag
    STA FighterUpdateSharedFlag

UpdateFighterJumpState:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectByte5,X
    BNE ContinueFighterJump
    JSR GetActivePlayerMotionState
    CMP #FighterJumpMotionThreshold
    BCS TryStartFighterJump
    JMP UpdateWalkingEnemyPhysics

TryStartFighterJump:
    LDA RuntimeObjectY,X
    CLC
    ADC #FighterSupportProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS StartFighterJump
    JMP UpdateWalkingEnemyPhysics

StartFighterJump:
    LDX CurrentRuntimeObjectOffset
    LDA #FighterJumpDuration
    STA RuntimeObjectByte5,X

ContinueFighterJump:
    DEC RuntimeObjectByte5,X
    LDA #FighterJumpActiveFlag
    STA FighterUpdateSharedFlag
    JSR UpdateWalkingEnemyPhysics
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS ReturnFromFighterUpdate
    BMI ReturnFromFighterUpdate
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS ReturnFromFighterUpdate
    BMI ReturnFromFighterUpdate
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel
    BCS ReturnFromFighterUpdate
    BMI ReturnFromFighterUpdate
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    CPY #FighterTopBoundary
    BCC ReturnFromFighterUpdate
    DEY
    DEY
    STY RuntimeObjectY,X

ReturnFromFighterUpdate:
    RTS
