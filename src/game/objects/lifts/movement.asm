; Pushable and lift movement
; CPU range $965C-$9A36
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateLiftControlBlock:
    LDA #PushableMotionInactive
    STA PushableHorizontalMotionLatch
    JSR UpdatePushableObjectPhysics
    LDX CurrentRuntimeObjectOffset
    LDA PushableHorizontalMotionLatch
    BEQ ReturnFromLiftControlBlockUpdate
    BPL LowerLiftAfterControlBlockMotion
    JMP RaiseLinkedLift

LowerLiftAfterControlBlockMotion:
    JMP LowerLinkedLift

ReturnFromLiftControlBlockUpdate:
    RTS

UpdatePushableObjectPhysics:
    STX CurrentObjectOffset
    LDA #EmptyRoomCell
    STA PushablePreviousSupportCollision
    LDA #PushableSupportCollisionCountInitial
    STA PushableSupportCollisionCount
    LDA RuntimeObjectXLo,X
    STA PushableCandidateXLo
    LDA RuntimeObjectXHi,X
    STA PushableCandidateXHi
    LDA RuntimeObjectY,X
    CLC
    ADC #PushableSupportYOffset
    STA PushableSupportProbeY
    TAY
    LDA PushableCandidateXHi
    LDX PushableCandidateXLo
    JSR SampleNormalizedRoomCollisionCell
    BCC ProbePushableMiddleSupport
    STA PushablePreviousSupportCollision
    INC PushableSupportCollisionCount
    JSR ClassifyAnimatedCollisionCell
    BCS HandlePushableSupportCollision

ProbePushableMiddleSupport:
    LDY PushableSupportProbeY
    LDA PushableCandidateXLo
    CLC
    ADC #PushableMiddleXOffset
    TAX
    LDA PushableCandidateXHi
    ADC #$00
    JSR SampleNormalizedRoomCollisionCell
    BCC ProbePushableRightSupport
    STA PushablePreviousSupportCollision
    INC PushableSupportCollisionCount
    JSR ClassifyAnimatedCollisionCell
    BCS HandlePushableSupportCollision

ProbePushableRightSupport:
    LDY PushableSupportProbeY
    LDA PushableCandidateXLo
    CLC
    ADC #PushableRightXOffset
    TAX
    LDA PushableCandidateXHi
    ADC #$00
    JSR SampleNormalizedRoomCollisionCell
    BCS HandlePushableSupportCollision
    LDA PushablePreviousSupportCollision
    LDY PushableSupportCollisionCount
    BNE HandlePushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CMP #RuntimeObjectVisibleYLimit
    BCS ReturnFromPushableObjectUpdate
    ADC #PushableFallStep
    STA RuntimeObjectY,X

ReturnFromPushableObjectUpdate:
    RTS

HandlePushableSupportCollision:
    STA PushableSupportCollision
    STX PushableSupportProbeXLo
    JSR ClassifyAnimatedCollisionCell
    BCS TryMovePushableRightOnConveyor
    JMP TryCrushRuntimeObjectBelowPushable

TryMovePushableRightOnConveyor:
    BMI TryMovePushableLeftOnConveyor
    LDA #PushableConveyorStep
    CLC
    ADC PushableCandidateXLo
    STA PushableCandidateXLo
    LDA PushableCandidateXHi
    ADC #$00
    STA PushableCandidateXHi
    LDA PushableCandidateXLo
    CLC
    ADC #PushableRightXOffset
    STA PushableLeadingEdgeXLo
    LDA PushableCandidateXHi
    ADC #$00
    STA PushableLeadingEdgeXHi
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    LDX PushableLeadingEdgeXLo
    LDA PushableLeadingEdgeXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    LDX PushableLeadingEdgeXLo
    LDA PushableLeadingEdgeXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDA #PushableMotionRight
    STA PushableHorizontalMotionLatch
    JMP CommitConveyorPushableX

TryMovePushableLeftOnConveyor:
    LDA PushableCandidateXLo
    SEC
    SBC #PushableConveyorStep
    STA PushableCandidateXLo
    LDA PushableCandidateXHi
    SBC #$00
    STA PushableCandidateXHi
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    LDX PushableCandidateXLo
    LDA PushableCandidateXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    LDX PushableCandidateXLo
    LDA PushableCandidateXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDA #PushableMotionLeft
    STA PushableHorizontalMotionLatch

CommitConveyorPushableX:
    LDX CurrentRuntimeObjectOffset
    LDA PushableCandidateXLo
    STA RuntimeObjectXLo,X
    LDA PushableCandidateXHi
    STA RuntimeObjectXHi,X

ReturnFromPushableSupportCollision:
    RTS

TryCrushRuntimeObjectBelowPushable:
    LDA PushableSupportCollision
    JSR GetRuntimeObjectType84To89Filter
    BEQ ValidatePushableCrushContact
    RTS

ValidatePushableCrushContact:
    LDA PushablePreviousSupportCollision
    CMP PushableSupportCollision
    BEQ SelectCrushedRuntimeObject
    LDA PushablePreviousSupportCollision
    CMP #EmptyRoomCell
    BEQ SelectCrushedRuntimeObject
    RTS

SelectCrushedRuntimeObject:
    LDX PushableCollisionObjectOffset

DestroyRuntimeObjectWithSound:
    LDA #CrushedRuntimeObjectType
    STA RuntimeObjectRecords,X
    LDA #DestroyedRuntimeObjectInitialState
    STA RuntimeObjectState,X
    JMP StartPulse2NoiseSoundEffect2

DestroyCurrentRuntimeObjectWithSound:
    LDX CurrentRuntimeObjectOffset
    JMP DestroyRuntimeObjectWithSound

UpdateSmallLift:
    LDA RoomFrameCounter
    AND #LiftUpdateFrameMask
    CMP #LiftUpdateFramePhase
    BEQ StepSmallLift
    RTS

StepSmallLift:
    LDA RuntimeObjectState,X
    BPL MoveSmallLiftDown
    JMP MoveSmallLiftUp

MoveSmallLiftDown:
    LDA RuntimeObjectY,X
    CMP #LiftMaximumY
    BCS ReverseSmallLiftUp
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCellRowStride
    LDA (LiftRoomCellPointerLo),Y
    CMP #SmallLiftShaftCell
    BNE ReverseSmallLiftUp
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #EmptyRoomCell
    LDY #LiftCurrentCellOffset
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #LiftCellStep
    STA RuntimeObjectY,X
    RTS

ReverseSmallLiftUp:
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionUp
    STA RuntimeObjectState,X
    JMP UpdateSmallLift

ReverseSmallLiftDown:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDA #EmptyRoomCell
    LDY #LiftCurrentCellOffset
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionDown
    STA RuntimeObjectState,X
    JMP UpdateSmallLift

MoveSmallLiftUp:
    JSR ClearLiftOccupantFlags
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    BEQ ReverseSmallLiftDown
    SEC
    SBC #LiftCellStep
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA (LiftRoomCellPointerLo),Y
    CMP #EmptyRoomCell
    BNE ReverseSmallLiftDown
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #SmallLiftShaftCell
    LDY #LiftCellRowStride
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY SmallLiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA SmallLiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA SmallLiftOccupantSpanXHi
    LDA #SmallLiftWidth
    STA SmallLiftOccupantSpanWidth
    JSR TestPlayerAgainstObjectSpan
    BCC MarkPlayerOnSmallLift
    JMP RaiseSmallLiftOccupants

MarkPlayerOnSmallLift:
    LDA #LiftOccupantPending
    STA LiftPlayerOccupantFlag

RaiseSmallLiftOccupants:
    LDA #SmallLiftWidth
    STA SmallLiftOccupantSpanWidth
    JMP RaiseLiftAndOccupants

UpdateLargeLift:
    LDA RoomFrameCounter
    AND #LiftUpdateFrameMask
    CMP #LiftUpdateFramePhase
    BEQ StepLargeLift
    RTS

StepLargeLift:
    LDA RuntimeObjectState,X
    BPL MoveLargeLiftDown
    JMP MoveLargeLiftUp

MoveLargeLiftDown:
    LDA RuntimeObjectY,X
    CMP #LiftMaximumY
    BCS ReverseLargeLiftUp
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCellRowStride
    LDA (LiftRoomCellPointerLo),Y
    CMP #LargeLiftLeftShaftCell
    BNE ReverseLargeLiftUp
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #EmptyRoomCell
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA #EmptyRoomCell
    LDY #LiftCurrentCellOffset
    STA (LiftRoomCellPointerLo),Y
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LargeLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LargeLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #LiftCellStep
    STA RuntimeObjectY,X
    RTS

ReverseLargeLiftUp:
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionUp
    STA RuntimeObjectState,X
    JMP UpdateLargeLift

ReverseLargeLiftDown:
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDA #EmptyRoomCell
    LDY #LiftCurrentCellOffset
    STA (LiftRoomCellPointerLo),Y
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LargeLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LargeLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionDown
    STA RuntimeObjectState,X
    JMP UpdateLargeLift

MoveLargeLiftUp:
    JSR ClearLiftOccupantFlags
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    BEQ ReverseLargeLiftDown
    SEC
    SBC #LiftCellStep
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA (LiftRoomCellPointerLo),Y
    CMP #EmptyRoomCell
    BNE ReverseLargeLiftDown
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #EmptyRoomCell
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA #LargeLiftLeftShaftCell
    LDY #LiftCellRowStride
    STA (LiftRoomCellPointerLo),Y
    LDA #LargeLiftRightShaftCell
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA LargeLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA LargeLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY LiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA LiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA LiftOccupantSpanXHi
    LDA #LargeLiftWidth
    STA LiftOccupantSpanWidth
    JSR TestPlayerAgainstObjectSpan
    BCC MarkPlayerOnLargeLift
    JMP RaiseLargeLiftOccupants

MarkPlayerOnLargeLift:
    LDA #LiftOccupantPending
    STA LiftPlayerOccupantFlag

RaiseLargeLiftOccupants:
    LDA #LargeLiftWidth
    STA LiftOccupantSpanWidth

RaiseLiftAndOccupants:
    LDX CurrentRuntimeObjectOffset
    JSR GetRuntimeObjectSlotIndex
    LDA #LiftOccupantPending
    STA LiftOccupantFlags,Y

RestartLiftOccupantClosure:
    LDA #LiftOccupantClear
    STA LiftClosureExpansionCount
    LDX #LiftFirstObjectSlot
    STX LiftClosureScanIndex

FindPendingLiftOccupant:
    LDX LiftClosureScanIndex
    LDA LiftOccupantFlags,X
    BMI ExpandLiftOccupantClosure

AdvanceLiftOccupantScan:
    INX
    CPX #LiftObjectSlotCount
    STX LiftClosureScanIndex
    BCC FindPendingLiftOccupant
    LDA LiftClosureExpansionCount
    BNE RestartLiftOccupantClosure
    BEQ ApplyRisingLiftMovement

ExpandLiftOccupantClosure:
    LDA #LiftOccupantProcessed
    STA LiftOccupantFlags,X
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #LiftCellStep
    STA LiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA LiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA LiftOccupantSpanXHi
    LDA RuntimeObjectRecords,X
    TAY
    LDA RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA LiftOccupantSpanWidth
    LDX #LiftFirstObjectSlot

ScanLiftOccupantOverlaps:
    JSR FindRuntimeObjectOverlappingSpan
    BCS IncludePlayerStandingOnOccupant
    JSR GetRuntimeObjectSlotIndex
    LDA LiftOccupantFlags,Y
    BNE AdvanceLiftOverlapScan
    LDA #LiftOccupantPending
    STA LiftOccupantFlags,Y

AdvanceLiftOverlapScan:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    JMP ScanLiftOccupantOverlaps

IncludePlayerStandingOnOccupant:
    JSR TestPlayerAgainstObjectSpan
    BCS FinishLiftOccupantExpansion
    LDA #LiftOccupantPending
    STA LiftPlayerOccupantFlag

FinishLiftOccupantExpansion:
    INC LiftClosureExpansionCount
    LDX LiftClosureScanIndex
    JMP AdvanceLiftOccupantScan

ApplyRisingLiftMovement:
    LDX #LiftFirstObjectSlot
    STX LiftMovementSlotIndex

MoveNextLiftOccupant:
    LDX LiftMovementSlotIndex
    LDA LiftOccupantFlags,X
    BEQ AdvanceLiftMovement
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    CMP #LiftCellStep
    BCC CrushBlockedLiftOccupant
    SEC
    SBC #LiftRiseAlignmentBias
    AND #LiftRiseAlignmentMask
    STA RuntimeObjectY,X
    TAY
    JSR GetRuntimeObjectX
    JSR SampleRoomCollisionAtPixel
    BCS CrushBlockedLiftOccupant
    BMI CrushBlockedLiftOccupant
    LDX LiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus15
    JSR SampleRoomCollisionAtPixel
    BMI CrushBlockedLiftOccupant
    BCC AdvanceLiftMovement

CrushBlockedLiftOccupant:
    LDX LiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA #CrushedRuntimeObjectType
    STA RuntimeObjectRecords,X
    LDA #DestroyedRuntimeObjectInitialState
    STA RuntimeObjectState,X

AdvanceLiftMovement:
    INC LiftMovementSlotIndex
    LDA LiftMovementSlotIndex
    CMP #LiftObjectSlotCount
    BCC MoveNextLiftOccupant
    LDA LiftPlayerOccupantFlag
    BEQ ReturnFromLiftUpdate
    LDA PlayerY
    SEC
    SBC #LiftRiseAlignmentBias
    AND #LiftRiseAlignmentMask
    STA PlayerY

ReturnFromLiftUpdate:
    RTS

GetRuntimeObjectSlotIndex:
    LDY #LiftFirstObjectSlot
    TXA

DivideRuntimeObjectOffsetByRecordSize:
    CMP #RuntimeObjectRecordSize
    BCC ReturnRuntimeObjectSlotIndex
    INY
    SBC #RuntimeObjectRecordSize
    BCS DivideRuntimeObjectOffsetByRecordSize

ReturnRuntimeObjectSlotIndex:
    RTS

ClearLiftOccupantFlags:
    LDX #LiftObjectSlotCount
    LDA #LiftOccupantClear

ClearNextLiftOccupantFlag:
    STA LiftOccupantFlags,X
    DEX
    BPL ClearNextLiftOccupantFlag
    RTS
