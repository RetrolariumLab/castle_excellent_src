; Transient runtime-object lifecycles and replacement table
; CPU range $9FF3-$A043
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateRuntimeObjectType32:
    DEC RuntimeObjectState,X
    BEQ ReplaceRuntimeObjectType32
    RTS

ReplaceRuntimeObjectType32:
    LDA FrameCounter
    AND #RuntimeObjectType32StateParityMask
    BEQ StoreRuntimeObjectType32State
    LDA #$FF

StoreRuntimeObjectType32State:
    STA RuntimeObjectState,X
    LDA FrameCounterModulo30
    LSR A
    TAY
    LDA RuntimeObjectType32ReplacementTypes,Y
    STA RuntimeObjectRecords,X
    RTS

RuntimeObjectType32ReplacementTypes:
    .byte $84, $85, $85, $87, $87, $84, $84, $84, $84, $87, $84, $85, $84, $85, $84

UpdateRuntimeObjectType40:
    INC RuntimeObjectState,X
    LDA RuntimeObjectState,X
    CMP #RuntimeObjectType40StateLimit
    BCC ReturnFromTransientObjectUpdate

ClearCurrentRuntimeObject:
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA RuntimeObjectState,X
    STA RuntimeObjectByte5,X

ReturnFromTransientObjectUpdate:
    RTS

UpdateRuntimeObjectType41:
    LDA RoomFrameCounter
    LSR A
    BCC TickRuntimeObjectType41Lifetime
    LDA RuntimeObjectY,X
    BEQ TickRuntimeObjectType41Lifetime
    DEC RuntimeObjectY,X

TickRuntimeObjectType41Lifetime:
    DEC RuntimeObjectByte5,X
    BEQ ClearCurrentRuntimeObject
    RTS
