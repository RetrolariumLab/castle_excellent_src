; Platform and walking enemy patrol behaviors
; Original CPU range $9A37-$9D64

UpdateFloatingPlatform:
    STX CurrentObjectOffset
    LDA RuntimeObjectFloatingPlatformStopFlag,X
    BNE ReturnFromFloatingPlatformUpdate

MoveFloatingPlatformRight:
    LDA RuntimeObjectState,X
    BMI MoveFloatingPlatformLeft
    JSR ProbeFloatingPlatformRightTop
    BCS TryReverseFloatingPlatformLeft
    JSR ProbeFloatingPlatformRightBottom
    BCS TryReverseFloatingPlatformLeft
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FloatingPlatformStep
    STA RuntimeObjectXLo,X
    BCC StoreFloatingPlatformRightContactX
    INC RuntimeObjectXHi,X

StoreFloatingPlatformRightContactX:
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FloatingPlatformRightContactXOffset
    STA FloatingPlatformContactXLo
    LDA RuntimeObjectXHi,X
    ADC #FloatingPlatformCoordinateCarry
    STA FloatingPlatformContactXHi

ReturnFromFloatingPlatformUpdate:
    RTS

TryReverseFloatingPlatformLeft:
    JSR ProbeFloatingPlatformLeftTop
    BCS StopFloatingPlatform
    JSR ProbeFloatingPlatformLeftBottom
    BCS StopFloatingPlatform
    LDX CurrentRuntimeObjectOffset
    LDA #FloatingPlatformDirectionLeft
    STA RuntimeObjectState,X
    RTS

StopFloatingPlatform:
    LDX CurrentRuntimeObjectOffset
    LDA #FloatingPlatformStopped
    STA RuntimeObjectFloatingPlatformStopFlag,X
    RTS

MoveFloatingPlatformLeft:
    JSR ProbeFloatingPlatformLeftTop
    BCS TryReverseFloatingPlatformRight
    JSR ProbeFloatingPlatformLeftBottom
    BCS TryReverseFloatingPlatformRight
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    STA FloatingPlatformContactXLo
    SEC
    SBC #FloatingPlatformStep
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    STA FloatingPlatformContactXHi
    SBC #FloatingPlatformCoordinateBorrow
    STA RuntimeObjectXHi,X
    RTS

TryReverseFloatingPlatformRight:
    JSR ProbeFloatingPlatformRightTop
    BCS StopFloatingPlatform
    JSR ProbeFloatingPlatformRightBottom
    BCS StopFloatingPlatform
    LDX CurrentRuntimeObjectOffset
    LDA #FloatingPlatformDirectionRight
    STA RuntimeObjectState,X
    RTS

ProbeFloatingPlatformRightTop:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus17
    JSR ValidateFloatingPlatformProbePosition
    BCS ReturnFromFloatingPlatformUpdate
    JMP SampleNormalizedRoomCollisionCell

ProbeFloatingPlatformRightBottom:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FloatingPlatformBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR ValidateFloatingPlatformProbePosition
    BCS ReturnFromFloatingPlatformUpdate
    JMP SampleNormalizedRoomCollisionCell

ProbeFloatingPlatformLeftTop:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXMinus2
    JSR ValidateFloatingPlatformProbePosition
    BCS ReturnFromFloatingPlatformProbe
    JMP SampleNormalizedRoomCollisionCell

ProbeFloatingPlatformLeftBottom:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FloatingPlatformBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR ValidateFloatingPlatformProbePosition
    BCS ReturnFromFloatingPlatformProbe
    JMP SampleNormalizedRoomCollisionCell

ValidateFloatingPlatformProbePosition:
    CPY #FloatingPlatformWorldYEnd
    BCS ReturnFromFloatingPlatformProbe
    CMP #FloatingPlatformWorldRightPage
    BCC ReturnFromFloatingPlatformProbe
    CMP #FloatingPlatformWorldBeyondRightPage
    BCS ReturnFromFloatingPlatformProbe
    CPX #FloatingPlatformWorldRightLimitLo

ReturnFromFloatingPlatformProbe:
    RTS

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

UpdateKnight:
    LDA RuntimeObjectKnightArrowCooldown,X
    BEQ UpdateKnightPatrol
    DEC RuntimeObjectKnightArrowCooldown,X
    RTS

UpdateKnightPatrol:
    JSR UpdateWalkingEnemyPhysics
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #KnightPlayerYAlignmentOffset
    CMP PlayerY
    BEQ CheckKnightFacingPlayer
    RTS

CheckKnightFacingPlayer:
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
    BCC CheckKnightFacingRight
    LDA RuntimeObjectState,X
    BMI CheckKnightArrowCadence
    RTS

CheckKnightFacingRight:
    LDA RuntimeObjectState,X
    BPL CheckKnightArrowCadence
    RTS

CheckKnightArrowCadence:
    LDA RoomFrameCounter
    AND #KnightArrowFrameMask
    BEQ FindKnightArrowSlot
    RTS

FindKnightArrowSlot:
    LDX CurrentRoomNumber
    LDA RoomObjectCounts - 1,X
    TAY
    LDX RuntimeObjectOffsetByCount,Y

ScanKnightArrowSlot:
    LDA RuntimeObjectRecords,X
    BEQ SpawnKnightArrow
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanKnightArrowSlot
    RTS

SpawnKnightArrow:
    LDY CurrentRuntimeObjectOffset
    LDA #KnightArrowCooldown
    STA a:RuntimeObjectAux,Y
    LDA #KnightArrowRuntimeType
    STA RuntimeObjectRecords,X
    LDA a:RuntimeObjectY,Y
    CLC
    ADC #KnightArrowYOffset
    STA RuntimeObjectY,X
    LDA a:RuntimeObjectState,Y
    BMI SpawnKnightArrowLeft
    LDA a:RuntimeObjectXLo,Y
    CLC
    ADC #KnightArrowRightXOffset
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    ADC #KnightArrowCoordinateCarry
    STA RuntimeObjectXHi,X
    LDA #KnightArrowDirectionRight
    STA RuntimeObjectState,X
    JMP ReturnFromKnightUpdate

SpawnKnightArrowLeft:
    LDA a:RuntimeObjectXLo,Y
    SEC
    SBC #KnightArrowLeftXOffset
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    SBC #KnightArrowCoordinateBorrow
    STA RuntimeObjectXHi,X
    LDA #KnightArrowDirectionLeft
    STA RuntimeObjectState,X

ReturnFromKnightUpdate:
    RTS

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
    LDA RuntimeObjectFighterJumpCountdown,X
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
    STA RuntimeObjectFighterJumpCountdown,X

ContinueFighterJump:
    DEC RuntimeObjectFighterJumpCountdown,X
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
