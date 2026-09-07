; Linked lift control
; CPU range $89E1-$8C11
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleLiftControlBlockHorizontalCollision:
    LDA #LinkedLiftMotionInactive
    STA PlayerObjectPushDirectionLatch
    JSR PushPlayerAndRuntimeObject
    LDA PlayerObjectPushDirectionLatch
    BNE RouteLiftControlBlockPushMotion
    RTS

RouteLiftControlBlockPushMotion:
    BPL RestoreLiftControlBlockOffsetForLowering
    JMP RestoreLiftControlBlockOffsetForRaising

RestoreLiftControlBlockOffsetForLowering:
    LDX CurrentObjectOffset

LowerLinkedLift:
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus7
    JSR PrepareRoomCellSampleAddress
    LDY LinkedLiftControlCellColumn
    LDA (LinkedLiftRoomCellPointerLo),Y
    CMP #LinkedLiftControlCellFirst
    BCC ReturnPlayerObjectPush
    CMP #LinkedLiftControlCellEnd
    BCS ReturnPlayerObjectPush
    LDA PlayerObjectPushDirectionLatch
    BEQ ReturnPlayerObjectPush
    BPL FindPrimaryLinkedLiftForLowering
    JMP RestoreLiftControlBlockOffsetForRaising

FindPrimaryLinkedLiftForLowering:
    LDX #LiftFirstObjectSlot

ScanPrimaryLinkedLiftForLowering:
    LDA RuntimeObjectRecords,X
    CMP #PrimaryLinkedLiftType
    BEQ RememberPrimaryLinkedLiftForLowering
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanPrimaryLinkedLiftForLowering
    RTS

RememberPrimaryLinkedLiftForLowering:
    STX PrimaryLinkedLiftOffset
    LDX #LiftFirstObjectSlot

ScanSecondaryLinkedLiftForLowering:
    LDA RuntimeObjectRecords,X
    CMP #SecondaryLinkedLiftType
    BEQ ProbeLinkedLiftLoweringClearance
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanSecondaryLinkedLiftForLowering
    RTS

ProbeLinkedLiftLoweringClearance:
    STX SecondaryLinkedLiftOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #SecondaryLinkedLiftClearanceYOffset
    TAY
    STY SecondaryLinkedLiftClearanceY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BEQ ProbeSecondaryLinkedLiftRightClearance
    JMP ReturnFromLinkedLiftControl

ProbeSecondaryLinkedLiftRightClearance:
    LDY SecondaryLinkedLiftClearanceY
    LDX SecondaryLinkedLiftOffset
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BEQ ProbePrimaryLinkedLiftClearance
    JMP ReturnFromLinkedLiftControl

ProbePrimaryLinkedLiftClearance:
    LDX PrimaryLinkedLiftOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PrimaryLinkedLiftClearanceYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromLinkedLiftControl
    LDX PrimaryLinkedLiftOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PrimaryLinkedLiftClearanceYOffset
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromLinkedLiftControl
    LDY SecondaryLinkedLiftClearanceY
    LDX SecondaryLinkedLiftOffset
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    CMP #EmptyRoomCell
    BNE ReturnFromLinkedLiftControl
    LDX PrimaryLinkedLiftOffset
    LDY RuntimeObjectY,X
    INY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA #LinkedLiftTrackCell
    STA (LinkedLiftRoomCellPointerLo),Y
    LDA LinkedLiftRoomCellPointerLo
    STA LinkedLiftRoomCellUpdateAddressLo
    LDA LinkedLiftRoomCellPointerHi
    STA LinkedLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    LDX PrimaryLinkedLiftOffset
    JSR LowerLinkedLiftObjectByStep
    LDX SecondaryLinkedLiftOffset

LowerLinkedLiftObjectByStep:
    LDY RuntimeObjectY,X
    INY
    INY
    STY RuntimeObjectY,X

ReturnFromLinkedLiftControl:
    RTS

RestoreLiftControlBlockOffsetForRaising:
    LDX CurrentObjectOffset

RaiseLinkedLift:
    LDY RuntimeObjectY,X
    DEY
    JSR GetRuntimeObjectXPlus8
    JSR PrepareRoomCellSampleAddress
    LDY LinkedLiftControlCellColumn
    LDA (LinkedLiftRoomCellPointerLo),Y
    CMP #LinkedLiftControlCellFirst
    BCC ReturnFromLinkedLiftControl
    CMP #LinkedLiftControlCellEnd
    BCS ReturnFromLinkedLiftControl
    LDX #LiftFirstObjectSlot

ScanPrimaryLinkedLiftForRaising:
    LDA RuntimeObjectRecords,X
    CMP #PrimaryLinkedLiftType
    BEQ ProbeLinkedLiftTrackAbove
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanPrimaryLinkedLiftForRaising
    RTS

ProbeLinkedLiftTrackAbove:
    STX PrimaryLinkedLiftOffset
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR GetRuntimeObjectX
    JSR PrepareRoomCellSampleAddress
    LDY LinkedLiftControlCellColumn
    LDA (LinkedLiftRoomCellPointerLo),Y
    CMP #LinkedLiftTrackCell
    BEQ FindSecondaryLinkedLiftForRaising
    RTS

FindSecondaryLinkedLiftForRaising:
    LDX #LiftFirstObjectSlot

ScanSecondaryLinkedLiftForRaising:
    LDA RuntimeObjectRecords,X
    CMP #SecondaryLinkedLiftType
    BEQ PrepareLinkedLiftRaising
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanSecondaryLinkedLiftForRaising
    RTS

PrepareLinkedLiftRaising:
    STX SecondaryLinkedLiftOffset
    LDX PrimaryLinkedLiftOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #LinkedLiftTrackEraseYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR ConvertPixelPositionToTileCoordinates
    JSR GetRoomCellPointer
    LDY #LiftCurrentCellOffset
    LDA #EmptyRoomCell
    STA (LinkedLiftRoomCellPointerLo),Y
    LDA LinkedLiftRoomCellPointerLo
    STA LinkedLiftRoomCellUpdateAddressLo
    LDA LinkedLiftRoomCellPointerHi
    STA LinkedLiftRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    JSR ClearLiftOccupantFlags
    LDX PrimaryLinkedLiftOffset
    JSR GetRuntimeObjectSlotIndex
    LDA #LiftOccupantPending
    STA LinkedLiftOccupantFlags,Y
    LDX SecondaryLinkedLiftOffset
    JSR GetRuntimeObjectSlotIndex
    LDA #LiftOccupantPending
    STA LinkedLiftOccupantFlags,Y
    LDA #LinkedLiftOccupantWidth
    STA LinkedLiftOccupantSpanWidth

RestartLinkedLiftOccupantClosure:
    LDA #LiftOccupantClear
    STA LinkedLiftClosureExpansionCount
    LDX #LiftFirstObjectSlot
    STX LinkedLiftClosureScanIndex

FindPendingLinkedLiftOccupant:
    LDX LinkedLiftClosureScanIndex
    LDA LinkedLiftOccupantFlags,X
    BMI ExpandLinkedLiftOccupantClosure

AdvanceLinkedLiftOccupantScan:
    INX
    CPX #LiftObjectSlotCount
    STX LinkedLiftClosureScanIndex
    BCC FindPendingLinkedLiftOccupant
    LDA LinkedLiftClosureExpansionCount
    BNE RestartLinkedLiftOccupantClosure
    BEQ ApplyRisingLinkedLiftMovement

ExpandLinkedLiftOccupantClosure:
    LDA #LiftOccupantProcessed
    STA LinkedLiftOccupantFlags,X
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #LinkedLiftOccupantProbeYOffset
    STA LinkedLiftOccupantSpanY
    LDA RuntimeObjectXLo,X
    STA LinkedLiftOccupantSpanXLo
    LDA RuntimeObjectXHi,X
    STA LinkedLiftOccupantSpanXHi
    LDA RuntimeObjectRecords,X
    TAY
    LDA RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA LinkedLiftOccupantSpanWidth
    LDX #LiftFirstObjectSlot

ScanLinkedLiftOccupantOverlaps:
    JSR FindRuntimeObjectOverlappingSpan
    BCS FinishLinkedLiftOccupantExpansion
    JSR GetRuntimeObjectSlotIndex
    LDA LinkedLiftOccupantFlags,Y
    BNE AdvanceLinkedLiftOverlapScan
    LDA #LiftOccupantPending
    STA LinkedLiftOccupantFlags,Y

AdvanceLinkedLiftOverlapScan:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    JMP ScanLinkedLiftOccupantOverlaps

FinishLinkedLiftOccupantExpansion:
    INC LinkedLiftClosureExpansionCount
    LDX LinkedLiftClosureScanIndex
    JMP AdvanceLinkedLiftOccupantScan

ApplyRisingLinkedLiftMovement:
    LDX #LiftFirstObjectSlot
    STX LinkedLiftMovementSlotIndex

MoveNextLinkedLiftOccupant:
    LDX LinkedLiftMovementSlotIndex
    LDA LinkedLiftOccupantFlags,X
    BEQ AdvanceLinkedLiftMovement
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #LinkedLiftRaisingStep
    BCC CrushBlockedLinkedLiftOccupant
    STA RuntimeObjectY,X
    TAY
    LDA RuntimeObjectRecords,X
    CMP #PrimaryLinkedLiftType
    BEQ AdvanceLinkedLiftMovement
    JSR GetRuntimeObjectX
    JSR SampleRoomCollisionAtPixel
    BCS CrushBlockedLinkedLiftOccupant
    BMI CrushBlockedLinkedLiftOccupant
    LDX LinkedLiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus15
    JSR SampleRoomCollisionAtPixel
    BMI CrushBlockedLinkedLiftOccupant
    BCC AdvanceLinkedLiftMovement

CrushBlockedLinkedLiftOccupant:
    LDX LinkedLiftMovementSlotIndex
    LDA RuntimeObjectOffsetByCount,X
    TAX
    LDA #CrushedRuntimeObjectType
    STA RuntimeObjectRecords,X
    LDA #DestroyedRuntimeObjectInitialState
    STA RuntimeObjectState,X

AdvanceLinkedLiftMovement:
    INC LinkedLiftMovementSlotIndex
    LDA LinkedLiftMovementSlotIndex
    CMP #LiftObjectSlotCount
    BCC MoveNextLinkedLiftOccupant
    LDA LinkedLiftPlayerOccupantFlag
    BEQ ReturnFromLinkedLiftUpdate
    LDA PlayerY
    SEC
    SBC #LinkedLiftRaisingStep
    BCS StoreRaisedLinkedLiftPlayerY
    LDA #LinkedLiftMinimumY

StoreRaisedLinkedLiftPlayerY:
    STA PlayerY

ReturnFromLinkedLiftUpdate:
    RTS
