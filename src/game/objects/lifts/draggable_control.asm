; Draggable lift control
; Original CPU range $89E1-$8C11

HandlePulleyHorizontalCollision:
    LDA #DraggableLiftMotionInactive
    STA PlayerObjectPushDirectionLatch
    JSR PushPlayerAndRuntimeObject
    LDA PlayerObjectPushDirectionLatch
    BNE RoutePulleyPushMotion
    RTS

RoutePulleyPushMotion:
    BPL RestorePulleyOffsetForLowering
    JMP RestorePulleyOffsetForRaising

RestorePulleyOffsetForLowering:
    LDX CurrentObjectOffset

LowerDraggableLift:
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR PrepareRoomCellSampleAddress
    LDY DraggableLiftControlCellColumn
    LDA (DraggableLiftRoomCellPointerLo),Y
    CMP #DraggableLiftControlCellFirst
    BCC ReturnPlayerObjectPush
    CMP #DraggableLiftControlCellEnd
    BCS ReturnPlayerObjectPush
    LDA PlayerObjectPushDirectionLatch
    BEQ ReturnPlayerObjectPush
    BPL FindDraggableLiftTopForLowering
    JMP RestorePulleyOffsetForRaising

FindDraggableLiftTopForLowering:
    LDX #LiftFirstObjectSlot

ScanDraggableLiftTopForLowering:
    LDA RuntimeObjectRecords,X
    CMP #DraggableLiftTopType
    BEQ RememberDraggableLiftTopForLowering
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanDraggableLiftTopForLowering
    RTS

RememberDraggableLiftTopForLowering:
    STX DraggableLiftTopOffset
    LDX #LiftFirstObjectSlot

ScanDraggableLiftBottomForLowering:
    LDA RuntimeObjectRecords,X
    CMP #DraggableLiftBottomType
    BEQ ProbeDraggableLiftLoweringClearance
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanDraggableLiftBottomForLowering
    RTS

ProbeDraggableLiftLoweringClearance:
    STX DraggableLiftBottomOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #DraggableLiftBottomClearanceYOffset
    TAY
    STY DraggableLiftBottomClearanceY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BEQ ProbeDraggableLiftBottomRightClearance
    JMP ReturnFromDraggableLiftControl

ProbeDraggableLiftBottomRightClearance:
    LDY DraggableLiftBottomClearanceY
    LDX DraggableLiftBottomOffset
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BEQ ProbeDraggableLiftTopClearance
    JMP ReturnFromDraggableLiftControl

ProbeDraggableLiftTopClearance:
    LDX DraggableLiftTopOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #DraggableLiftTopClearanceYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromDraggableLiftControl
    LDX DraggableLiftTopOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #DraggableLiftTopClearanceYOffset
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromDraggableLiftControl
    LDY DraggableLiftBottomClearanceY
    LDX DraggableLiftBottomOffset
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromDraggableLiftControl
    LDX DraggableLiftTopOffset
    LDY RuntimeObjectY,X
    INY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA #DraggableLiftTrackCell
    STA (DraggableLiftRoomCellPointerLo),Y
    LDA DraggableLiftRoomCellPointerLo
    STA DraggableLiftRoomCellUpdateAddressLo
    LDA DraggableLiftRoomCellPointerHi
    STA DraggableLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    LDX DraggableLiftTopOffset
    JSR LowerDraggableLiftObjectByStep
    LDX DraggableLiftBottomOffset

LowerDraggableLiftObjectByStep:
    LDY RuntimeObjectY,X
    INY
    INY
    STY RuntimeObjectY,X

ReturnFromDraggableLiftControl:
    RTS

RestorePulleyOffsetForRaising:
    LDX CurrentObjectOffset

RaiseDraggableLift:
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus8
    JSR PrepareRoomCellSampleAddress
    LDY DraggableLiftControlCellColumn
    LDA (DraggableLiftRoomCellPointerLo),Y
    CMP #DraggableLiftControlCellFirst
    BCC ReturnFromDraggableLiftControl
    CMP #DraggableLiftControlCellEnd
    BCS ReturnFromDraggableLiftControl
    LDX #LiftFirstObjectSlot

ScanDraggableLiftTopForRaising:
    LDA RuntimeObjectRecords,X
    CMP #DraggableLiftTopType
    BEQ ProbeDraggableLiftTrackAbove
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanDraggableLiftTopForRaising
    RTS

ProbeDraggableLiftTrackAbove:
    STX DraggableLiftTopOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectX
    JSR PrepareRoomCellSampleAddress
    LDY DraggableLiftControlCellColumn
    LDA (DraggableLiftRoomCellPointerLo),Y
    CMP #DraggableLiftTrackCell
    BEQ FindDraggableLiftBottomForRaising
    RTS

FindDraggableLiftBottomForRaising:
    LDX #LiftFirstObjectSlot

ScanDraggableLiftBottomForRaising:
    LDA RuntimeObjectRecords,X
    CMP #DraggableLiftBottomType
    BEQ PrepareDraggableLiftRaising
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanDraggableLiftBottomForRaising
    RTS

PrepareDraggableLiftRaising:
    STX DraggableLiftBottomOffset
    LDX DraggableLiftTopOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #DraggableLiftTrackEraseYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA #EmptyRoomCell
    STA (DraggableLiftRoomCellPointerLo),Y
    LDA DraggableLiftRoomCellPointerLo
    STA DraggableLiftRoomCellUpdateAddressLo
    LDA DraggableLiftRoomCellPointerHi
    STA DraggableLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    JSR ClearLiftOccupantFlags
    LDX DraggableLiftTopOffset
    JSR GetRuntimeObjectSlotIndex
    LDA #LiftOccupantPending
    STA DraggableLiftOccupantFlags,Y
    LDX DraggableLiftBottomOffset
    JSR GetRuntimeObjectSlotIndex
    LDA #LiftOccupantPending
    STA DraggableLiftOccupantFlags,Y
    LDA #DraggableLiftOccupantWidth
    STA DraggableLiftOccupantSpanWidth

RestartDraggableLiftOccupantClosure:
    LDA #LiftOccupantClear
    STA DraggableLiftClosureExpansionCount
    LDX #LiftFirstObjectSlot
    STX DraggableLiftClosureScanIndex

FindPendingDraggableLiftOccupant:
    LDX DraggableLiftClosureScanIndex
    LDA DraggableLiftOccupantFlags,X
    BMI ExpandDraggableLiftOccupantClosure

AdvanceDraggableLiftOccupantScan:
    INX
    CPX #LiftObjectSlotCount
    STX DraggableLiftClosureScanIndex
    BCC FindPendingDraggableLiftOccupant
    LDA DraggableLiftClosureExpansionCount
    BNE RestartDraggableLiftOccupantClosure
    BEQ ApplyRisingDraggableLiftMovement

ExpandDraggableLiftOccupantClosure:
    LDA #LiftOccupantProcessed
    STA DraggableLiftOccupantFlags,X
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #DraggableLiftOccupantProbeYOffset
    STA DraggableLiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA DraggableLiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA DraggableLiftOccupantSpanXHi
    LDA RuntimeObjectRecords,X
    TAY
    LDA RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA DraggableLiftOccupantSpanWidth
    LDX #LiftFirstObjectSlot

ScanDraggableLiftOccupantOverlaps:
    JSR FindRuntimeObjectOverlappingSpan
    BCS FinishDraggableLiftOccupantExpansion
    JSR GetRuntimeObjectSlotIndex
    LDA DraggableLiftOccupantFlags,Y
    BNE AdvanceDraggableLiftOverlapScan
    LDA #LiftOccupantPending
    STA DraggableLiftOccupantFlags,Y

AdvanceDraggableLiftOverlapScan:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    JMP ScanDraggableLiftOccupantOverlaps

FinishDraggableLiftOccupantExpansion:
    INC DraggableLiftClosureExpansionCount
    LDX DraggableLiftClosureScanIndex
    JMP AdvanceDraggableLiftOccupantScan

ApplyRisingDraggableLiftMovement:
    LDX #LiftFirstObjectSlot
    STX DraggableLiftMovementSlotIndex

MoveNextDraggableLiftOccupant:
    LDX DraggableLiftMovementSlotIndex
    LDA DraggableLiftOccupantFlags,X
    BEQ AdvanceDraggableLiftMovement
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #DraggableLiftRaisingStep
    BCC CrushBlockedDraggableLiftOccupant
    STA RuntimeObjectY,X
    TAY
    LDA RuntimeObjectRecords,X
    CMP #DraggableLiftTopType
    BEQ AdvanceDraggableLiftMovement
    JSR GetRuntimeObjectX
    JSR SampleRoomCollisionAtPixel
    BCS CrushBlockedDraggableLiftOccupant
    BMI CrushBlockedDraggableLiftOccupant
    LDX DraggableLiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus15
    JSR SampleRoomCollisionAtPixel
    BMI CrushBlockedDraggableLiftOccupant
    BCC AdvanceDraggableLiftMovement

CrushBlockedDraggableLiftOccupant:
    LDX DraggableLiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA #CrushedRuntimeObjectType
    STA RuntimeObjectRecords,X
    LDA #DestroyedRuntimeObjectInitialState
    STA RuntimeObjectState,X

AdvanceDraggableLiftMovement:
    INC DraggableLiftMovementSlotIndex
    LDA DraggableLiftMovementSlotIndex
    CMP #LiftObjectSlotCount
    BCC MoveNextDraggableLiftOccupant
    LDA DraggableLiftPlayerOccupantFlag
    BEQ ReturnFromDraggableLiftUpdate
    LDA PlayerY
    SEC
    SBC #DraggableLiftRaisingStep
    BCS StoreRaisedDraggableLiftPlayerY
    LDA #DraggableLiftMinimumY

StoreRaisedDraggableLiftPlayerY:
    STA PlayerY

ReturnFromDraggableLiftUpdate:
    RTS
