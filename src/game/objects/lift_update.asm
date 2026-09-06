; Small and large lift state machines and occupant propagation
; CPU range $9796-$9A36
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
