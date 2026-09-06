; Flying-block horizontal motion and collision reversal
; CPU range $9A37-$9AFF
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateFlyingBlock:
    STX CurrentObjectOffset
    LDA RuntimeObjectFlyingBlockStopFlag,X
    BNE ReturnFromFlyingBlockUpdate

MoveFlyingBlockRight:
    LDA RuntimeObjectState,X
    BMI MoveFlyingBlockLeft
    JSR ProbeFlyingBlockRightTop
    BCS TryReverseFlyingBlockLeft
    JSR ProbeFlyingBlockRightBottom
    BCS TryReverseFlyingBlockLeft
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FlyingBlockStep
    STA RuntimeObjectXLo,X
    BCC StoreFlyingBlockRightContactX
    INC RuntimeObjectXHi,X

StoreFlyingBlockRightContactX:
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FlyingBlockRightContactXOffset
    STA FlyingBlockContactXLo
    LDA RuntimeObjectXHi,X
    ADC #FlyingBlockCoordinateCarry
    STA FlyingBlockContactXHi

ReturnFromFlyingBlockUpdate:
    RTS

TryReverseFlyingBlockLeft:
    JSR ProbeFlyingBlockLeftTop
    BCS StopFlyingBlock
    JSR ProbeFlyingBlockLeftBottom
    BCS StopFlyingBlock
    LDX CurrentRuntimeObjectOffset
    LDA #FlyingBlockDirectionLeft
    STA RuntimeObjectState,X
    RTS

StopFlyingBlock:
    LDX CurrentRuntimeObjectOffset
    LDA #FlyingBlockStopped
    STA RuntimeObjectFlyingBlockStopFlag,X
    RTS

MoveFlyingBlockLeft:
    JSR ProbeFlyingBlockLeftTop
    BCS TryReverseFlyingBlockRight
    JSR ProbeFlyingBlockLeftBottom
    BCS TryReverseFlyingBlockRight
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    STA FlyingBlockContactXLo
    SEC
    SBC #FlyingBlockStep
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    STA FlyingBlockContactXHi
    SBC #FlyingBlockCoordinateBorrow
    STA RuntimeObjectXHi,X
    RTS

TryReverseFlyingBlockRight:
    JSR ProbeFlyingBlockRightTop
    BCS StopFlyingBlock
    JSR ProbeFlyingBlockRightBottom
    BCS StopFlyingBlock
    LDX CurrentRuntimeObjectOffset
    LDA #FlyingBlockDirectionRight
    STA RuntimeObjectState,X
    RTS

ProbeFlyingBlockRightTop:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus17
    JSR ValidateFlyingBlockProbePosition
    BCS ReturnFromFlyingBlockUpdate
    JMP SampleNormalizedRoomCollisionCell

ProbeFlyingBlockRightBottom:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FlyingBlockBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXPlus17
    JSR ValidateFlyingBlockProbePosition
    BCS ReturnFromFlyingBlockUpdate
    JMP SampleNormalizedRoomCollisionCell

ProbeFlyingBlockLeftTop:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXMinus2
    JSR ValidateFlyingBlockProbePosition
    BCS ReturnFromFlyingBlockProbe
    JMP SampleNormalizedRoomCollisionCell

ProbeFlyingBlockLeftBottom:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #FlyingBlockBottomProbeYOffset
    TAY
    JSR GetRuntimeObjectXMinus2
    JSR ValidateFlyingBlockProbePosition
    BCS ReturnFromFlyingBlockProbe
    JMP SampleNormalizedRoomCollisionCell

ValidateFlyingBlockProbePosition:
    CPY #FlyingBlockWorldYEnd
    BCS ReturnFromFlyingBlockProbe
    CMP #FlyingBlockWorldRightPage
    BCC ReturnFromFlyingBlockProbe
    CMP #FlyingBlockWorldBeyondRightPage
    BCS ReturnFromFlyingBlockProbe
    CPX #FlyingBlockWorldRightLimitLo

ReturnFromFlyingBlockProbe:
    RTS
