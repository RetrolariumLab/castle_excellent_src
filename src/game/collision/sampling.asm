; Room and runtime object collision sampling
; Original CPU range $A044-$A2B0

ClassifyAnimatedCollisionCell:
    CMP #DecrementingAnimatedCellFirst
    BCC TestIncrementingAnimatedCollisionCell
    CMP #DecrementingAnimatedCellEnd
    BCS TestIncrementingAnimatedCollisionCell
    LDY #$00
    SEC
    RTS

TestIncrementingAnimatedCollisionCell:
    CMP #IncrementingAnimatedCellFirst
    BCC ReturnNonAnimatedCollisionCell
    CMP #IncrementingAnimatedCellEnd
    BCS ReturnNonAnimatedCollisionCell
    LDY #$FF
    SEC
    RTS

ReturnNonAnimatedCollisionCell:
    CLC
    RTS

GetEnemyTypeFilter:
    TAY
    PHP
    BPL ReturnNonEnemyTypeFilter
    PLP
    LDA EnemyTypeFilterValues - RuntimeObjectCollisionTypeFirst,Y
    RTS

ReturnNonEnemyTypeFilter:
    PLP
    LDA #$FF
    RTS

EnemyTypeFilterValues:
    .byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF

GetRuntimeObjectSolidFlag:
    TAY
    PHP
    BPL ReturnNonRuntimeObjectSolidFlag
    PLP
    LDA RuntimeObjectSolidFlags - RuntimeObjectCollisionTypeFirst,Y
    RTS

ReturnNonRuntimeObjectSolidFlag:
    PLP
    LDA #$FF
    RTS

RuntimeObjectSolidFlags:
    .byte $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $00
    .byte $FF, $FF, $FF, $FF, $FF, $FF

SampleCollisionAtPixel:
    CPY #RuntimeObjectVisibleYLimit
    BCC AddressCollisionSampleCell
    CLC
    LDA #EmptyRoomCell
    LDY #$00
    RTS

AddressCollisionSampleCell:
    STA CollisionSampleXHi
    STX CollisionSampleXLo
    STA CollisionSampleShiftXHi
    STX CollisionSampleColumn
    STY CollisionSampleY
    LDA #$00
    STA CollisionSampleCellPointerHi
    TYA
    LSR A
    LSR A
    LSR A
    STA CollisionSampleCellPointerLo
    ASL CollisionSampleCellPointerLo
    ROL CollisionSampleCellPointerHi
    ASL CollisionSampleCellPointerLo
    ROL CollisionSampleCellPointerHi
    CLC
    ADC CollisionSampleCellPointerLo
    STA CollisionSampleCellPointerLo
    BCC FinishCollisionSampleRowPointer
    INC CollisionSampleCellPointerHi

FinishCollisionSampleRowPointer:
    ASL CollisionSampleCellPointerLo
    ROL CollisionSampleCellPointerHi
    ASL CollisionSampleCellPointerLo
    ROL CollisionSampleCellPointerHi
    LDA #>RoomCells
    CLC
    ADC CollisionSampleCellPointerHi
    STA CollisionSampleCellPointerHi
    LSR CollisionSampleShiftXHi
    ROR CollisionSampleColumn
    LSR CollisionSampleShiftXHi
    ROR CollisionSampleColumn
    LSR CollisionSampleShiftXHi
    ROR CollisionSampleColumn
    LSR CollisionSampleShiftXHi
    ROR CollisionSampleColumn
    LDY CollisionSampleColumn
    LDA (CollisionSampleCellPointerLo),Y
    CMP #EmptyRoomCell
    BEQ ScanRuntimeObjectsAtCollisionPoint
    TAX
    LDA CollisionSampleXLo
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA ObjectCollisionFlagsByRoomCellHalf,X
    BEQ ScanRuntimeObjectsAtCollisionPoint
    JSR ClassifyCollisionCellPairIndex
    BNE ReturnRoomCellCollisionSample
    LDY CollisionSampleAnimationCounter
    BPL ReturnRoomCellCollisionSample
    LDA #$00

ReturnRoomCellCollisionSample:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

ScanRuntimeObjectsAtCollisionPoint:
    LDY #$00
    STY CollisionSampleObjectIndex

TestNextRuntimeObjectAtCollisionPoint:
    LDY CollisionSampleObjectIndex
    LDX RuntimeObjectOffsetByCount,Y
    CPX CurrentObjectOffset
    BEQ AdvanceRuntimeObjectCollisionSample
    LDA RuntimeObjectRecords,X
    BEQ AdvanceRuntimeObjectCollisionSample
    CMP #RuntimeOverlapTypeEnd
    BCS AdvanceRuntimeObjectCollisionSample
    TAY
    LDA CollisionSampleY
    SEC
    SBC RuntimeObjectY,X
    BCC AdvanceRuntimeObjectCollisionSample
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvanceRuntimeObjectCollisionSample
    LDA CollisionSampleXLo
    STA CollisionSampleDeltaXLo
    LDA CollisionSampleXHi
    STA CollisionSampleDeltaXHi
    LDA CollisionSampleDeltaXLo
    SEC
    SBC RuntimeObjectXLo,X
    STA CollisionSampleDeltaXLo
    LDA CollisionSampleDeltaXHi
    SBC RuntimeObjectXHi,X
    STA CollisionSampleDeltaXHi
    BCC AdvanceRuntimeObjectCollisionSample
    LDA CollisionSampleDeltaXLo
    SEC
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA CollisionSampleDeltaXLo
    LDA CollisionSampleDeltaXHi
    SBC #$00
    STA CollisionSampleDeltaXHi
    BCS AdvanceRuntimeObjectCollisionSample
    STX CollisionSampleObjectOffset
    LDA RuntimeObjectRecords,X
    JSR GetRuntimeObjectSolidFlag
    CLC
    BEQ ReturnRuntimeObjectCollisionSample
    SEC

ReturnRuntimeObjectCollisionSample:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

AdvanceRuntimeObjectCollisionSample:
    INC CollisionSampleObjectIndex
    LDA CollisionSampleObjectIndex
    CMP #RuntimeObjectRecordCount
    BCC TestNextRuntimeObjectAtCollisionPoint
    CLC
    LDA #EmptyRoomCell
    LDY #$00
    RTS

SampleRoomCollisionAtPixel:
    CPY #RuntimeObjectVisibleYLimit
    BCC AddressRoomCollisionSample
    CLC
    LDA #EmptyRoomCell
    LDX #$00
    RTS

AddressRoomCollisionSample:
    JSR PrepareRoomCellSampleAddress
    LDY CollisionSampleColumn
    LDA (RoomCollisionSampleCellPointerLo),Y
    TAX
    LDA CollisionSampleXLo
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA ObjectCollisionFlagsByRoomCellHalf,X
    JSR ClassifyCollisionCellPairIndex
    BNE ReturnRoomCollisionSample
    LDA CollisionSampleAnimationCounter
    BPL ReturnRoomCollisionSample
    LDA #$00

ReturnRoomCollisionSample:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

SampleRuntimeObjectCollisionAtPixel:
    CPY #RuntimeObjectVisibleYLimit
    BCC InitializeRuntimeOnlyCollisionSample
    CLC
    LDA #EmptyRoomCell
    LDY #$00
    RTS

InitializeRuntimeOnlyCollisionSample:
    STA RuntimeOnlySampleXHi
    STX RuntimeOnlySampleXLo
    STY RuntimeOnlySampleY
    LDY #$00
    STY RuntimeOnlySampleObjectIndex

TestNextRuntimeOnlyCollisionSample:
    LDY RuntimeOnlySampleObjectIndex
    LDX RuntimeObjectOffsetByCount,Y
    LDA RuntimeObjectRecords,X
    BEQ AdvanceRuntimeOnlyCollisionSample
    CMP #RuntimeOverlapTypeEnd
    BCS AdvanceRuntimeOnlyCollisionSample
    TAY
    LDA RuntimeOnlySampleY
    SEC
    SBC RuntimeObjectY,X
    BCC AdvanceRuntimeOnlyCollisionSample
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvanceRuntimeOnlyCollisionSample
    LDA RuntimeOnlySampleXLo
    STA RuntimeOnlySampleDeltaXLo
    LDA RuntimeOnlySampleXHi
    STA RuntimeOnlySampleDeltaXHi
    LDA RuntimeOnlySampleDeltaXLo
    SEC
    SBC RuntimeObjectXLo,X
    STA RuntimeOnlySampleDeltaXLo
    LDA RuntimeOnlySampleDeltaXHi
    SBC RuntimeObjectXHi,X
    STA RuntimeOnlySampleDeltaXHi
    BCC AdvanceRuntimeOnlyCollisionSample
    LDA RuntimeOnlySampleDeltaXLo
    SEC
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA RuntimeOnlySampleDeltaXLo
    LDA RuntimeOnlySampleDeltaXHi
    SBC #$00
    STA RuntimeOnlySampleDeltaXHi
    BCS AdvanceRuntimeOnlyCollisionSample
    STX RuntimeOnlySampleObjectOffset
    LDA RuntimeObjectRecords,X
    JSR GetRuntimeObjectSolidFlag
    CLC
    BEQ ReturnRuntimeOnlyCollisionSample
    SEC

ReturnRuntimeOnlyCollisionSample:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

AdvanceRuntimeOnlyCollisionSample:
    INC RuntimeOnlySampleObjectIndex
    LDA RuntimeOnlySampleObjectIndex
    CMP #RuntimeObjectRecordCount
    BCC TestNextRuntimeOnlyCollisionSample
    CLC
    LDA #EmptyRoomCell
    LDY #$00
    RTS

FindRuntimeObjectOverlappingSpan:
    CPX #RuntimeObjectRecordBytes
    BCS ReturnFromRuntimeObjectHandler
    LDA RuntimeObjectRecords,X
    BPL AdvanceRuntimeOverlapCandidate
    CMP #RuntimeOverlapTypeEnd
    BCS AdvanceRuntimeOverlapCandidate
    TAY
    LDA RuntimeOverlapSpanY
    SEC
    SBC RuntimeObjectY,X
    BCC AdvanceRuntimeOverlapCandidate
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvanceRuntimeOverlapCandidate
    LDA RuntimeOverlapSpanXLo
    SEC
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    STA RuntimeOverlapBoundaryXLo
    LDA RuntimeOverlapSpanXHi
    SBC #$00
    STA RuntimeOverlapBoundaryXHi
    INC RuntimeOverlapBoundaryXLo
    BNE ClampRuntimeOverlapLeftBoundary
    INC RuntimeOverlapBoundaryXHi

ClampRuntimeOverlapLeftBoundary:
    LDA RuntimeOverlapBoundaryXHi
    BPL TestRuntimeOverlapHorizontalBounds
    LDA #$00
    STA RuntimeOverlapBoundaryXHi
    STA RuntimeOverlapBoundaryXLo

TestRuntimeOverlapHorizontalBounds:
    LDA RuntimeObjectXLo,X
    CMP RuntimeOverlapBoundaryXLo
    LDA RuntimeObjectXHi,X
    SBC RuntimeOverlapBoundaryXHi
    BCC AdvanceRuntimeOverlapCandidate
    LDA RuntimeOverlapSpanXLo
    CLC
    ADC RuntimeOverlapSpanWidth
    STA RuntimeOverlapBoundaryXLo
    LDA RuntimeOverlapSpanXHi
    ADC #$00
    STA RuntimeOverlapBoundaryXHi
    LDA RuntimeObjectXLo,X
    CMP RuntimeOverlapBoundaryXLo
    LDA RuntimeObjectXHi,X
    SBC RuntimeOverlapBoundaryXHi
    BCS AdvanceRuntimeOverlapCandidate
    RTS

AdvanceRuntimeOverlapCandidate:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC FindRuntimeObjectOverlappingSpan

ReturnFromRuntimeObjectHandler:
    RTS

UnreferencedNmiTaskIndexFromYBytes:
    .byte $98, $4A, $4A, $4A, $85, $F8, $60
