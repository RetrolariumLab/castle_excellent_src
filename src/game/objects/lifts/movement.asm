; Pushable and lift movement
; Original CPU range $965C-$9A36

UpdatePulley:
    LDA #PushableMotionInactive
    STA PushableHorizontalMotionLatch
    JSR UpdatePushableObjectPhysics
    LDX CurrentRuntimeObjectOffset
    LDA PushableHorizontalMotionLatch
    BEQ ReturnFromPulleyUpdate
    BPL LowerLiftAfterControlBlockMotion
    JMP RaiseDraggableLift

LowerLiftAfterControlBlockMotion:
    JMP LowerDraggableLift

ReturnFromPulleyUpdate:
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
    JSR GetEnemyTypeFilter
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

UpdateNarrowLift:
    LDA RoomFrameCounter
    AND #LiftUpdateFrameMask
    CMP #LiftUpdateFramePhase
    BEQ StepNarrowLift
    RTS

StepNarrowLift:
    LDA RuntimeObjectState,X
    BPL MoveNarrowLiftDown
    JMP MoveNarrowLiftUp

MoveNarrowLiftDown:
    LDA RuntimeObjectY,X
    CMP #LiftMaximumY
    BCS ReverseNarrowLiftUp
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCellRowStride
    LDA (LiftRoomCellPointerLo),Y
    CMP #NarrowLiftShaftCell
    BNE ReverseNarrowLiftUp
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

ReverseNarrowLiftUp:
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionUp
    STA RuntimeObjectState,X
    JMP UpdateNarrowLift

ReverseNarrowLiftDown:
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
    JMP UpdateNarrowLift

MoveNarrowLiftUp:
    JSR ClearLiftOccupantFlags
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    BEQ ReverseNarrowLiftDown
    SEC
    SBC #LiftCellStep
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA (LiftRoomCellPointerLo),Y
    CMP #EmptyRoomCell
    BNE ReverseNarrowLiftDown
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #NarrowLiftShaftCell
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
    STY NarrowLiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA NarrowLiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA NarrowLiftOccupantSpanXHi
    LDA #NarrowLiftWidth
    STA NarrowLiftOccupantSpanWidth
    JSR TestPlayerAgainstObjectSpan
    BCC MarkPlayerOnNarrowLift
    JMP RaiseNarrowLiftOccupants

MarkPlayerOnNarrowLift:
    LDA #LiftOccupantPending
    STA LiftPlayerOccupantFlag

RaiseNarrowLiftOccupants:
    LDA #NarrowLiftWidth
    STA NarrowLiftOccupantSpanWidth
    JMP RaiseLiftAndOccupants

UpdateWideLift:
    LDA RoomFrameCounter
    AND #LiftUpdateFrameMask
    CMP #LiftUpdateFramePhase
    BEQ StepWideLift
    RTS

StepWideLift:
    LDA RuntimeObjectState,X
    BPL MoveWideLiftDown
    JMP MoveWideLiftUp

MoveWideLiftDown:
    LDA RuntimeObjectY,X
    CMP #LiftMaximumY
    BCS ReverseWideLiftUp
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCellRowStride
    LDA (LiftRoomCellPointerLo),Y
    CMP #WideLiftLeftShaftCell
    BNE ReverseWideLiftUp
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
    STA WideLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA WideLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #LiftCellStep
    STA RuntimeObjectY,X
    RTS

ReverseWideLiftUp:
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionUp
    STA RuntimeObjectState,X
    JMP UpdateWideLift

ReverseWideLiftDown:
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
    STA WideLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA WideLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdates
    LDX CurrentRuntimeObjectOffset
    LDA #LiftDirectionDown
    STA RuntimeObjectState,X
    JMP UpdateWideLift

MoveWideLiftUp:
    JSR ClearLiftOccupantFlags
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    BEQ ReverseWideLiftDown
    SEC
    SBC #LiftCellStep
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA (LiftRoomCellPointerLo),Y
    CMP #EmptyRoomCell
    BNE ReverseWideLiftDown
    LDA #EmptyRoomCell
    STA (LiftRoomCellPointerLo),Y
    LDA #EmptyRoomCell
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA #WideLiftLeftShaftCell
    LDY #LiftCellRowStride
    STA (LiftRoomCellPointerLo),Y
    LDA #WideLiftRightShaftCell
    INY
    STA (LiftRoomCellPointerLo),Y
    LDA LiftRoomCellPointerLo
    STA WideLiftRoomCellUpdateAddressLo
    LDA LiftRoomCellPointerHi
    STA WideLiftRoomCellUpdateAddressHi
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
    LDA #WideLiftWidth
    STA LiftOccupantSpanWidth
    JSR TestPlayerAgainstObjectSpan
    BCC MarkPlayerOnWideLift
    JMP RaiseWideLiftOccupants

MarkPlayerOnWideLift:
    LDA #LiftOccupantPending
    STA LiftPlayerOccupantFlag

RaiseWideLiftOccupants:
    LDA #WideLiftWidth
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
