; Transient runtime-object lifecycles and replacement table
; CPU range $9FF3-$A043
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateWitchSummonCountdown:
    DEC RuntimeObjectState,X
    BEQ ReplaceWitchSummonWithEnemy
    RTS

ReplaceWitchSummonWithEnemy:
    LDA FrameCounter
    AND #WitchSummonedEnemyDirectionParityMask
    BEQ StoreWitchSummonedEnemyDirection
    LDA #WitchSummonedEnemyDirectionLeft

StoreWitchSummonedEnemyDirection:
    STA RuntimeObjectState,X
    LDA FrameCounterModulo30
    LSR A
    TAY
    LDA WitchSummonedEnemyTypes,Y
    STA RuntimeObjectRecords,X
    RTS

WitchSummonedEnemyTypes:
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
    STA RuntimeObjectAux,X

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
    DEC RuntimeObjectCollectedLifetime,X
    BEQ ClearCurrentRuntimeObject
    RTS
