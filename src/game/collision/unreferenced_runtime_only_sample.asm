; Unreferenced runtime-object-only point collision sampler
; CPU range $A1D4-$A246
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
