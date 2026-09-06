; Flame tracking plus shared enemy edge and player-distance helpers
; CPU range $9D65-$9ECA
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
    LDA RuntimeObjectByte5,X
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
    STA RuntimeObjectByte5,X
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
    STA RuntimeObjectByte5,X
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
    STA RuntimeObjectByte5,X
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
