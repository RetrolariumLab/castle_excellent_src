; Player room-cell and runtime-object collision sampler
; CPU range $8DD3-$8ECA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SamplePlayerCollisionAtScreenPixel:
    CPY #PlayerCollisionScreenYFirst
    BCC ReturnEmptyPlayerCollisionSample
    CPY #PlayerCollisionScreenYEnd
    BCS ReturnEmptyPlayerCollisionSample
    CMP #$00
    BEQ SamplePlayerRoomCell
    CMP #$01
    BNE ReturnEmptyPlayerCollisionSample
    CPX #PlayerCollisionScreenXEndLo
    BCC SamplePlayerRoomCell

ReturnEmptyPlayerCollisionSample:
    CLC
    LDA #EmptyRoomCell
    LDX #$00
    STX PlayerCollisionObjectFilterActive
    RTS

SamplePlayerRoomCell:
    PHA
    TYA
    SEC
    SBC #PlayerCollisionScreenYFirst
    TAY
    PLA
    JSR PrepareRoomCellSampleAddress
    LDY PlayerCollisionSampleColumn
    LDA (PlayerCollisionCellPointerLo),Y
    CMP #EmptyRoomCell
    BEQ ScanPlayerCollisionObjects
    TAX
    LDA PlayerCollisionSampleXLo
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA PlayerCollisionFlagsByRoomCellHalf,X
    BEQ ScanPlayerCollisionObjects
    JSR ClassifyCollisionCellPairIndex
    BNE ReturnPlayerRoomCellCollision
    LDY PlayerCollisionAnimationCounter
    BPL ReturnPlayerRoomCellCollision
    LDA #$00

ReturnPlayerRoomCellCollision:
    PHA
    LDA #$00
    STA PlayerCollisionObjectFilterActive
    PLA
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

ScanPlayerCollisionObjects:
    LDY #$00
    STY PlayerCollisionObjectIndex

TestNextPlayerCollisionObject:
    LDY PlayerCollisionObjectIndex
    LDX RuntimeObjectOffsetByCount,Y
    STX CurrentObjectOffset
    LDA RuntimeObjectRecords,X
    BEQ AdvancePlayerCollisionObjectScan
    CMP #PlayerCollisionRuntimeTypeEnd
    BCS AdvancePlayerCollisionObjectScan
    DEC PlayerCollisionObjectFilterActive
    INC PlayerCollisionObjectFilterActive
    BEQ TestPlayerCollisionObjectGeometry
    LDA RuntimeObjectRecords,X
    JSR IsRuntimeObjectType90To95
    BCC AdvancePlayerCollisionObjectScan

TestPlayerCollisionObjectGeometry:
    TAY
    LDA PlayerCollisionSampleY
    SEC
    SBC RuntimeObjectY,X
    BCC AdvancePlayerCollisionObjectScan
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvancePlayerCollisionObjectScan
    CPY #PlayerCollisionSpecialRuntimeType
    BNE TestPlayerCollisionObjectHorizontalSpan
    PHA
    LDA RoomFrameCounter
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #PlayerCollisionSpecialPhaseThreshold
    BCS RestoreSpecialObjectVerticalDelta
    PLA
    CMP #$F8
    BCC AdvancePlayerCollisionObjectScan
    LDA PlayerCollisionMotionState
    BEQ TestPlayerCollisionObjectHorizontalSpan
    BNE AdvancePlayerCollisionObjectScan
    PLA
    JMP AdvancePlayerCollisionObjectScan

RestoreSpecialObjectVerticalDelta:
    PLA

TestPlayerCollisionObjectHorizontalSpan:
    LDA PlayerCollisionSampleXLo
    STA PlayerCollisionDeltaXLo
    LDA PlayerCollisionSampleXHi
    STA PlayerCollisionDeltaXHi
    LDA PlayerCollisionDeltaXLo
    SEC
    SBC RuntimeObjectXLo,X
    STA PlayerCollisionDeltaXLo
    LDA PlayerCollisionDeltaXHi
    SBC RuntimeObjectXHi,X
    BCC AdvancePlayerCollisionObjectScan
    STA PlayerCollisionDeltaXHi
    LDA PlayerCollisionDeltaXLo
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvancePlayerCollisionObjectScan
    LDA PlayerCollisionDeltaXHi
    BNE AdvancePlayerCollisionObjectScan
    LDA RuntimeObjectRecords,X
    JSR GetRuntimeObjectSolidFlag
    CLC
    BEQ ApplyPlayerCollisionObjectPassThroughFilter
    SEC

ApplyPlayerCollisionObjectPassThroughFilter:
    LDA RuntimeObjectRecords,X
    JSR GetRuntimeObjectType84To89Filter
    BNE ReturnPlayerObjectCollision
    CLC

ReturnPlayerObjectCollision:
    LDA RuntimeObjectRecords,X
    LDY #$00
    STY PlayerCollisionObjectFilterActive
    LDY #$01
    RTS

AdvancePlayerCollisionObjectScan:
    INC PlayerCollisionObjectIndex
    LDA PlayerCollisionObjectIndex
    CMP #RuntimeObjectRecordCount
    BCS ReturnNoPlayerCollision
    JMP TestNextPlayerCollisionObject

ReturnNoPlayerCollision:
    CLC
    LDA #EmptyRoomCell
    LDY #$00
    STY PlayerCollisionObjectFilterActive
    RTS
