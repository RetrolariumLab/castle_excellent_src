; Walking-enemy gravity, support, hazard, ledge, and patrol physics
; CPU range $9B00-$9C3A
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateWalkingEnemyPhysics:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemyHazardProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR PrepareRoomCellSampleAddress
    LDY WalkingEnemyRoomCellColumn
    LDA (WalkingEnemyRoomCellPointerLo),Y
    CMP #WalkingEnemyHazardCell
    BNE UpdateWalkingEnemySupport
    JMP DestroyCurrentRuntimeObjectWithSound

UpdateWalkingEnemySupport:
    LDX CurrentRuntimeObjectOffset
    LDA WalkingEnemyUpdateSharedFlag
    BMI HandleWalkingEnemySupport
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemySupportProbeYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BPL ProbeWalkingEnemyMiddleSupport
    JMP DestroyCurrentRuntimeObjectWithSound

ProbeWalkingEnemyMiddleSupport:
    BCS HandleWalkingEnemySupport
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemySupportProbeYOffset
    TAY
    LDA RuntimeObjectXHi,X
    STA WalkingEnemyProbeXHi
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WalkingEnemyCenterProbeXOffset
    TAX
    LDA WalkingEnemyProbeXHi
    ADC #WalkingEnemyCoordinateCarry
    JSR SampleCollisionAtPixel
    BPL ProbeWalkingEnemyRightSupport
    JMP DestroyCurrentRuntimeObjectWithSound

ProbeWalkingEnemyRightSupport:
    BCS HandleWalkingEnemySupport
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemySupportProbeYOffset
    TAY
    LDA RuntimeObjectXHi,X
    STA WalkingEnemyProbeXHi
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WalkingEnemyRightProbeXOffset
    TAX
    LDA WalkingEnemyProbeXHi
    ADC #WalkingEnemyCoordinateCarry
    JSR SampleCollisionAtPixel
    BPL FallWalkingEnemy
    JMP DestroyCurrentRuntimeObjectWithSound

FallWalkingEnemy:
    BCS HandleWalkingEnemySupport
    LDX CurrentRuntimeObjectOffset
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    LDA RuntimeObjectY,X
    CMP #WalkingEnemyVisibleYLimit
    BCS ReturnFromWalkingEnemyPhysics
    LDA #WalkingEnemySharedFlagClear
    STA WalkingEnemyUpdateSharedFlag

ReturnFromWalkingEnemyPhysics:
    RTS

HandleWalkingEnemySupport:
    CMP #HazardousPushableRuntimeType
    BNE PatrolWalkingEnemy
    JMP DestroyCurrentRuntimeObjectWithSound

PatrolWalkingEnemy:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BPL PatrolWalkingEnemyRight
    JMP PatrolWalkingEnemyLeft

PatrolWalkingEnemyRight:
    JSR ProbeWalkingEnemyRightEdge
    BCS ReverseWalkingEnemyLeft
    LDA WalkingEnemyUpdateSharedFlag
    BNE MoveWalkingEnemyRight
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemySupportProbeYOffset
    TAY
    LDA RuntimeObjectXHi,X
    STA WalkingEnemyProbeXHi
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WalkingEnemyRightLedgeProbeXOffset
    TAX
    LDA WalkingEnemyProbeXHi
    ADC #WalkingEnemyCoordinateCarry
    JSR SampleCollisionAtPixel
    BCC ReverseWalkingEnemyLeft

MoveWalkingEnemyRight:
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP #WalkingEnemyRightBoundaryLo
    LDA RuntimeObjectXHi,X
    SBC #WalkingEnemyRightBoundaryHi
    BCS ReverseWalkingEnemyLeft
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WalkingEnemyPatrolStep
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    ADC #WalkingEnemyCoordinateCarry
    STA RuntimeObjectXHi,X

ClearWalkingEnemySharedFlag:
    LDA #WalkingEnemySharedFlagClear
    STA WalkingEnemyUpdateSharedFlag
    RTS

ReverseWalkingEnemyLeft:
    LDX CurrentRuntimeObjectOffset
    LDA #WalkingEnemyDirectionLeft
    STA RuntimeObjectState,X
    BNE ClearWalkingEnemySharedFlag

PatrolWalkingEnemyLeft:
    JSR ProbeWalkingEnemyLeftEdge
    BCS ReverseWalkingEnemyRight
    LDA WalkingEnemyUpdateSharedFlag
    BNE MoveWalkingEnemyLeft
    LDX CurrentRuntimeObjectOffset
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #WalkingEnemyLeftLedgeProbeYOffset
    TAY
    LDA RuntimeObjectXHi,X
    STA WalkingEnemyProbeXHi
    LDA RuntimeObjectXLo,X
    SEC
    SBC #WalkingEnemyPatrolStep
    TAX
    LDA WalkingEnemyProbeXHi
    SBC #WalkingEnemyCoordinateBorrow
    JSR SampleCollisionAtPixel
    BCC ReverseWalkingEnemyRight

MoveWalkingEnemyLeft:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXHi,X
    BNE CommitWalkingEnemyLeft
    LDA RuntimeObjectXLo,X
    CMP #WalkingEnemyLeftBoundaryLo
    BCC ReverseWalkingEnemyRight

CommitWalkingEnemyLeft:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #WalkingEnemyPatrolStep
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    SBC #WalkingEnemyCoordinateBorrow
    STA RuntimeObjectXHi,X
    STA WalkingEnemyUpdateSharedFlag
    RTS

ReverseWalkingEnemyRight:
    LDX CurrentRuntimeObjectOffset
    LDA #WalkingEnemyDirectionRight
    STA RuntimeObjectState,X
    STA WalkingEnemyUpdateSharedFlag
    RTS
