; Special enemy behaviors and transient lifecycle
; CPU range $9D65-$A043
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateFlame:
    LDA NoiseSoundEffectRequest
    BNE UpdateFlameFrame
    JSR StartNoiseSoundEffect4

UpdateFlameFrame:
    LDX CurrentRuntimeObjectOffset
    LDA RoomFrameCounter
    AND #FlameUpdateFrameMask
    BEQ SelectFlameMovementAxis
    RTS

SelectFlameMovementAxis:
    LDA RuntimeObjectFlameMovementMode,X
    BPL CheckFlamePlayerX
    JMP MoveFlameVertically

CheckFlamePlayerX:
    LDA PlayerXLo
    CMP RuntimeObjectXLo,X
    BNE MoveFlameHorizontally
    LDA PlayerXHi
    CMP RuntimeObjectXHi,X
    BNE MoveFlameHorizontally
    LDA #FlameVerticalMode
    STA RuntimeObjectFlameMovementMode,X
    BNE SelectFlameVerticalDirection

MoveFlameHorizontally:
    LDA RuntimeObjectState,X
    BMI MoveFlameLeft
    JSR ProbeWalkingEnemyRightEdge
    BCS SwitchFlameToVerticalMovement
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FlameStep
    STA RuntimeObjectXLo,X
    BCC ReturnFromFlameHorizontalMove
    INC RuntimeObjectXHi,X

ReturnFromFlameHorizontalMove:
    RTS

SwitchFlameToVerticalMovement:
    LDX CurrentRuntimeObjectOffset
    LDA #FlameVerticalMode
    STA RuntimeObjectFlameMovementMode,X
    RTS

MoveFlameLeft:
    JSR ProbeWalkingEnemyLeftEdge
    BCS SwitchFlameToVerticalMovement
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    SEC
    SBC #FlameStep
    STA RuntimeObjectXLo,X
    BCS ReturnFromFlameLeftMove
    DEC RuntimeObjectXHi,X

ReturnFromFlameLeftMove:
    RTS

MoveFlameVertically:
    LDA PlayerY
    SEC
    SBC #FlamePlayerYOffset
    CMP RuntimeObjectY,X
    BEQ ReverseFlameDirection

SelectFlameVerticalDirection:
    LDA RuntimeObjectState,X
    BMI MoveFlameDown
    JSR ProbeFlameAbove
    BCS ReverseFlameDirection
    LDX CurrentRuntimeObjectOffset
    DEC RuntimeObjectY,X
    DEC RuntimeObjectY,X
    RTS

ReverseFlameDirection:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectState,X
    EOR #FlameDirectionToggleMask
    STA RuntimeObjectState,X
    LDA #FlameHorizontalMode
    STA RuntimeObjectFlameMovementMode,X
    RTS

MoveFlameDown:
    JSR ProbeFlameBelow
    BCS ReverseFlameDirection
    LDX CurrentRuntimeObjectOffset
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    RTS

ProbeFlameAbove:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    CPY #FlameWorldYEnd
    BCS ReturnFromFlameAboveProbe
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS ReturnFromFlameAboveProbe
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS ReturnFromFlameAboveProbe
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel

ReturnFromFlameAboveProbe:
    RTS

ProbeFlameBelow:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FlameBottomProbeYOffset
    CMP #FlameWorldYEnd
    BCS ReturnFromFlameBelowProbe
    TAY
    JSR GetRuntimeObjectX
    JSR SampleCollisionAtPixel
    BCS ReturnFromFlameBelowProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FlameBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleCollisionAtPixel
    BCS ReturnFromFlameBelowProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FlameBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleCollisionAtPixel

ReturnFromFlameBelowProbe:
    RTS

ProbeWalkingEnemyLeftEdge:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel
    BCS ReturnFromWalkingEnemyLeftEdgeProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #EnemyMiddleEdgeProbeYOffset
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel
    BCS ReturnFromWalkingEnemyLeftEdgeProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #EnemyBottomEdgeProbeYOffset
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR SampleCollisionAtPixel

ReturnFromWalkingEnemyLeftEdgeProbe:
    RTS

ProbeWalkingEnemyRightEdge:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel
    BCS ReturnFromWalkingEnemyRightEdgeProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #EnemyMiddleEdgeProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel
    BCS ReturnFromWalkingEnemyRightEdgeProbe
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #EnemyBottomEdgeProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR SampleCollisionAtPixel

ReturnFromWalkingEnemyRightEdgeProbe:
    RTS

MeasureCurrentObjectPlayerXSeparation:
    LDA PlayerXLo
    CLC
    SBC RuntimeObjectXLo,X
    STA CurrentObjectPlayerXSeparationLo
    LDA PlayerXHi
    SBC RuntimeObjectXHi,X
    STA CurrentObjectPlayerXSeparationHi
    STA CurrentObjectPlayerDeltaXSign
    BPL ReturnFromEnemyMovementHelper
    LDA CurrentObjectPlayerXSeparationLo
    EOR #PlayerDistanceComplementMask
    CLC
    ADC #PlayerDistanceAbsoluteBias
    STA CurrentObjectPlayerXSeparationLo
    LDA CurrentObjectPlayerXSeparationHi
    EOR #PlayerDistanceComplementMask
    ADC #PlayerDistanceCoordinateCarry
    STA CurrentObjectPlayerXSeparationHi

ReturnFromEnemyMovementHelper:
    RTS

UpdateWitch:
    JSR UpdateWalkingEnemyPhysics
    LDA RoomFrameCounter
    CMP #WitchSummonFramePhase
    BNE ReturnFromEnemyMovementHelper

PrepareWitchSummon:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectState,X
    BMI PrepareWitchSummonLeft
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WitchSummonHorizontalOffset
    STA WitchSummonXLo
    LDA RuntimeObjectXHi,X
    ADC #WitchSummonCoordinateCarry
    STA WitchSummonXHi
    JMP ValidateWitchSummonPosition

PrepareWitchSummonLeft:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #WitchSummonHorizontalOffset
    STA WitchSummonXLo
    LDA RuntimeObjectXHi,X
    SBC #WitchSummonCoordinateBorrow
    STA WitchSummonXHi

ValidateWitchSummonPosition:
    LDA WitchSummonXLo
    CMP #WitchSummonRightBoundaryLo
    LDA WitchSummonXHi
    SBC #WitchSummonRightBoundaryHi
    BCS ReturnFromWitchUpdate

ProbeWitchSummonTopLeft:
    LDY RuntimeObjectY,X
    STY WitchSummonY
    LDX WitchSummonXLo
    LDA WitchSummonXHi
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonTopRight:
    LDY WitchSummonY
    LDA WitchSummonXLo
    CLC
    ADC #WitchSummonExtent
    TAX
    LDA WitchSummonXHi
    ADC #WitchSummonCoordinateCarry
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonBottomLeft:
    LDA WitchSummonY
    CLC
    ADC #WitchSummonExtent
    TAY
    LDX WitchSummonXLo
    LDA WitchSummonXHi
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonBottomRight:
    LDA WitchSummonY
    CLC
    ADC #WitchSummonExtent
    TAY
    LDA WitchSummonXLo
    CLC
    ADC #WitchSummonExtent
    TAX
    LDA WitchSummonXHi
    ADC #WitchSummonCoordinateCarry
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

FindWitchSummonSlot:
    LDY CurrentRoomNumber
    LDX RoomObjectCounts - 1,Y
    LDA RuntimeObjectOffsetByCount,X
    TAX

ScanWitchSummonSlot:
    LDA RuntimeObjectRecords,X
    BEQ CreateWitchSummon
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanWitchSummonSlot
    RTS

CreateWitchSummon:
    LDA #WitchSummonRuntimeType
    STA RuntimeObjectRecords,X
    LDA WitchSummonXLo
    STA RuntimeObjectXLo,X
    LDA WitchSummonXHi
    STA RuntimeObjectXHi,X
    LDA WitchSummonY
    STA RuntimeObjectY,X
    LDA #WitchSummonInitialCountdown
    STA RuntimeObjectState,X
    LDA #WitchSummonInitialByte5
    STA RuntimeObjectAux,X

ReturnFromWitchUpdate:
    RTS

UpdateKnightArrow:
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BMI MoveKnightArrowLeft

MoveKnightArrowRight:
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus7
    BEQ ProbeKnightArrowRightEdge
    CMP #KnightArrowWorldPageOne
    BNE ClearKnightArrow
    CPX #KnightArrowWorldRightLimitLo
    BCS ClearKnightArrow

ProbeKnightArrowRightEdge:
    STX KnightArrowProbeXLo
    STA KnightArrowProbeXHi
    STY KnightArrowProbeY
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDA KnightArrowProbeY
    CLC
    ADC #KnightArrowVerticalExtent
    TAY
    LDX KnightArrowProbeXLo
    LDA KnightArrowProbeXHi
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #KnightArrowStep
    STA RuntimeObjectXLo,X
    BCC ReturnFromKnightArrowUpdate
    INC RuntimeObjectXHi,X

ReturnFromKnightArrowUpdate:
    RTS

ClearKnightArrow:
    LDX CurrentRuntimeObjectOffset
    JMP ClearCurrentRuntimeObject

MoveKnightArrowLeft:
    LDY RuntimeObjectY,X
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #KnightArrowStep
    TAX
    PLA
    SBC #KnightArrowCoordinateBorrow
    BCC ClearKnightArrow

ProbeKnightArrowLeftEdge:
    STX KnightArrowProbeXLo
    STA KnightArrowProbeXHi
    STY KnightArrowProbeY
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDA KnightArrowProbeY
    CLC
    ADC #KnightArrowVerticalExtent
    TAY
    LDX KnightArrowProbeXLo
    LDA KnightArrowProbeXHi
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDX CurrentRuntimeObjectOffset
    LDA KnightArrowProbeXLo
    STA RuntimeObjectXLo,X
    LDA KnightArrowProbeXHi
    STA RuntimeObjectXHi,X
    RTS

UpdateWitchSummonCountdown:
    DEC RuntimeObjectState,X
    BEQ ReplaceWitchSummonWithEnemy
    RTS

ReplaceWitchSummonWithEnemy:
    LDA FrameCounter
    AND #WitchSummonedEnemyDirectionParityMask
    BEQ StoreWitchSummonedEnemyDirection
    LDA #WitchSummonedEnemyDirectionLeft

StoreWitchSummonedEnemyDirection:
    STA RuntimeObjectState,X
    LDA FrameCounterModulo30
    LSR A
    TAY
    LDA WitchSummonedEnemyTypes,Y
    STA RuntimeObjectRecords,X
    RTS

WitchSummonedEnemyTypes:
    .byte $84, $85, $85, $87, $87, $84, $84, $84, $84, $87, $84, $85, $84, $85, $84

UpdateRuntimeObjectType40:
    INC RuntimeObjectState,X
    LDA RuntimeObjectState,X
    CMP #RuntimeObjectType40StateLimit
    BCC ReturnFromTransientObjectUpdate

ClearCurrentRuntimeObject:
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA RuntimeObjectState,X
    STA RuntimeObjectAux,X

ReturnFromTransientObjectUpdate:
    RTS

UpdateRuntimeObjectType41:
    LDA RoomFrameCounter
    LSR A
    BCC TickRuntimeObjectType41Lifetime
    LDA RuntimeObjectY,X
    BEQ TickRuntimeObjectType41Lifetime
    DEC RuntimeObjectY,X

TickRuntimeObjectType41Lifetime:
    DEC RuntimeObjectCollectedLifetime,X
    BEQ ClearCurrentRuntimeObject
    RTS
