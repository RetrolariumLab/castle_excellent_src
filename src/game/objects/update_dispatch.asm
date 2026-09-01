; Runtime-object update dispatcher and handler table
; CPU range $9583-$9612
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateRuntimeObjects:
    LDX #$00
    STX CurrentRuntimeObjectOffset

DispatchNextRuntimeObject:
    LDA #$00
    STA RuntimeObjectUpdateSharedFlag
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectRecords,X
    AND #RuntimeObjectTypeIndexMask
    BEQ AdvanceRuntimeObjectUpdate
    LDA RuntimeObjectY,X
    CMP #RuntimeObjectVisibleYLimit
    BCS AdvanceRuntimeObjectUpdate
    LDA RuntimeObjectRecords,X
    ASL A
    TAX
    LDA RuntimeObjectHandlerPointers,X
    STA RuntimeObjectHandlerPointerLo
    LDA RuntimeObjectHandlerPointers + 1,X
    STA RuntimeObjectHandlerPointerHi
    LDA #>(AdvanceRuntimeObjectUpdate - 1)
    PHA
    LDA #<(AdvanceRuntimeObjectUpdate - 1)
    PHA
    LDX CurrentRuntimeObjectOffset
    JMP (RuntimeObjectHandlerPointerLo)

AdvanceRuntimeObjectUpdate:
    LDA CurrentRuntimeObjectOffset
    CLC
    ADC #RuntimeObjectRecordSize
    STA CurrentRuntimeObjectOffset
    CMP #RuntimeObjectRecordBytes
    BCC DispatchNextRuntimeObject
    RTS

RuntimeObjectHandlerPointers:
    .byte $A9, $A2, $C6, $9C, $A9, $A2, $A9, $A2, $D8, $9C, $00, $9B, $A9, $A2, $3B, $9C
    .byte $CB, $9E, $65, $9D, $74, $96, $74, $96, $74, $96, $74, $96, $5C, $96, $74, $96
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $F3, $9F, $96, $97, $69, $98, $37, $9A, $A9, $A2, $A9, $A2, $74, $9F, $A9, $A2
    .byte $1C, $A0, $33, $A0
