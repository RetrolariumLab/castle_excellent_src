; Room-cell and runtime-object point collision sample
; CPU range $A0C4-$A1A2
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
