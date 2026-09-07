; Player transition and object frame pipeline
; CPU range $93F6-$965B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

AdvancePlayerTransitionCountdown:
    DEC PlayerTransitionCountdown
    BEQ CompletePlayerTransition
    RTS

CompletePlayerTransition:
    LDA TransitionPlayerXLo
    STA PlayerXLo
    LDA TransitionPlayerXHi
    STA PlayerXHi
    LDA TransitionPlayerY
    STA PlayerY
    LDA TransitionHazardProtectionMirror
    ORA PlayerTransitionScreenState
    BEQ FinishPlayerTransitionState
    LDA TransitionHazardProtectionMirror
    CMP PlayerCollisionHazardProtectionCountdown
    BCS SelectPlayerTransitionProtectionBase
    LDA PlayerCollisionHazardProtectionCountdown

SelectPlayerTransitionProtectionBase:
    LDY PlayerTransitionScreenState
    BEQ AddPlayerTransitionProtectionBonus
    LDA #$28

AddPlayerTransitionProtectionBonus:
    CLC
    ADC #$0A
    STA PlayerCollisionHazardProtectionCountdown

FinishPlayerTransitionState:
    LDA #$00
    STA PlayerTransitionCountdown
    LDA PlayerLives
    BNE ReloadCurrentRoomAfterPlayerTransition
    LDA GameOverActive
    BEQ ReloadCurrentRoomAfterPlayerTransition
    JMP RunGameOverSequence

ReloadCurrentRoomAfterPlayerTransition:
    JSR SaveCurrentRoomObjectState
    LDX CurrentRoomNumber
    DEX
    JSR DecodeRoom
    JSR LoadRoomObjects
    LDX #$02

CopyReloadRoomObjectState:
    LDA CurrentRoomObjectState,X
    STA ReloadRoomObjectStateBits,X
    DEX
    BPL CopyReloadRoomObjectState
    LDX #$04

CopyReloadRoomMutableCellState:
    LDA CurrentRoomMutableCellState,X
    STA ReloadRoomMutableCellStateBits,X
    DEX
    BPL CopyReloadRoomMutableCellState
    JSR ApplyRoomPersistentState
    JSR ResetRoomRuntimeState
    JSR ResetNmiTaskRequests
    JSR ClearRoomNametablesAndSprites
    JSR InitializeRoomStatusDisplay
    JSR BuildRoomAttributeTables
    JSR UploadRoomAttributeTables
    JSR UpdateHorizontalScroll
    LDA #$FF
    STA PauseMode
    JSR WaitForVblankAndEnableRendering
    JMP EnableNmi

DispatchPlayerCollisionSample:
    ASL A
    TAX
    BCS SelectPlayerRuntimeCollisionHandler
    LDA PlayerRoomCellCollisionHandlerPointers,X
    STA PlayerCollisionHandlerPointerLo
    LDA PlayerRoomCellCollisionHandlerPointers + 1,X
    STA PlayerCollisionHandlerPointerHi
    JMP InvokePlayerCollisionHandler

SelectPlayerRuntimeCollisionHandler:
    LDA PlayerRuntimeCollisionHandlerPointers,X
    STA PlayerCollisionHandlerPointerLo
    LDA PlayerRuntimeCollisionHandlerPointers + 1,X
    STA PlayerCollisionHandlerPointerHi

InvokePlayerCollisionHandler:
    LDA #>(ReturnFromPlayerCollisionDispatch - 1)
    PHA
    LDA #<(ReturnFromPlayerCollisionDispatch - 1)
    PHA
    JMP (PlayerCollisionHandlerPointerLo)

ReturnFromPlayerCollisionDispatch:
    RTS

RequestRoomCellRowUpdate:
    JSR GetRoomCellRowFromPointer
    LDA #NmiTaskPending
    STA NmiTaskRequests + $01,Y
    RTS

UnreferencedSingleRowIndexShimBytes:
    .byte $4A, $4A, $4A, $A8, $4C, $9F, $94

RequestRoomCellRowUpdates:
    JSR GetRoomCellRowFromPointer
    LDA #NmiTaskPending
    STA NmiTaskRequests + $01,Y
    CPY #RoomHeight
    BCS ReturnRoomCellRowUpdates
    STA NmiTaskRequests + $02,Y

ReturnRoomCellRowUpdates:
    RTS

UnreferencedAdjacentRowIndexShimBytes:
    .byte $4A, $4A, $4A, $A8, $4C, $AF, $94

GetRoomCellRowFromPointer:
    LSR RoomCellUpdateAddressHi
    ROR RoomCellUpdateAddressLo
    LSR RoomCellUpdateAddressHi
    ROR RoomCellUpdateAddressLo
    LDA RoomCellUpdateAddressLo
    AND #RoomCellPointerRowMask
    LDY #$00

DivideRoomCellPointerByRowStride:
    CMP #RoomCellPointerRowDivisor
    BCC ReturnRoomCellRow
    INY
    SBC #RoomCellPointerRowDivisor
    BCS DivideRoomCellPointerByRowStride

ReturnRoomCellRow:
    RTS

GetPlayerXPlus7:
    LDA #$07
    BNE AddPlayerXOffset

GetPlayerXPlus15:
    LDA #$0F

AddPlayerXOffset:
    CLC
    ADC PlayerXLo
    TAX
    LDA PlayerXHi
    ADC #$00
    RTS

GetRuntimeObjectX:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    TAX
    PLA
    RTS

GetRuntimeObjectXPlus7:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$07
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus8:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$08
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus15:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$0F
    JMP ReturnOffsetRuntimeObjectX

GetRuntimeObjectXPlus17:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$11

ReturnOffsetRuntimeObjectX:
    TAX
    PLA
    ADC #$00
    RTS

GetRuntimeObjectXMinus2:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    TAX
    PLA
    SBC #$00
    RTS

FinishRoomTransition:
    LDA #$FF
    STA PauseMode
    LDA TransitionPlayerXLo
    STA RoomRuntimeLoadMirror + $0B
    LDA TransitionPlayerXHi
    STA RoomRuntimeLoadMirror + $0C
    LDA TransitionPlayerY
    STA RoomRuntimeLoadMirror + $0D
    LDA TransitionHazardProtectionCountdown
    STA TransitionHazardProtectionMirror
    LDA TransitionInvulnerabilityCountdown
    STA TransitionInvulnerabilityMirror
    JSR ResetPpuScroll
    JSR EnableNmi
    JMP WaitForVblankAndEnableRendering

IsRuntimeObjectType90To95:
    CMP #$90
    BCC ReturnRuntimeObjectTypeOutsideRange
    CMP #$96
    BCS ReturnRuntimeObjectTypeOutsideRange
    RTS

ReturnRuntimeObjectTypeOutsideRange:
    SEC
    RTS

SampleNormalizedRoomCollisionCell:
    JSR SampleCollisionAtPixel
    PHP
    CMP #$62
    BEQ NormalizeMutableCollisionCell
    CMP #$63
    BEQ NormalizeMutableCollisionCell
    CMP #$54
    BEQ NormalizeMutableCollisionCell
    CMP #$55
    BEQ NormalizeMutableCollisionCell
    PLP
    RTS

NormalizeMutableCollisionCell:
    LDA #$53
    PLP
    CLC
    RTS

ResetNmiTaskRequests:
    LDA #$FF
    LDX #NmiTaskRequestCount - 1

ClearNextNmiTaskRequest:
    STA NmiTaskRequests,X
    DEX
    BPL ClearNextNmiTaskRequest
    RTS

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

TestPlayerAgainstObjectSpan:
    LDA ObjectSpanY
    CLC
    ADC #PlayerObjectVerticalSpan
    SEC
    SBC PlayerY
    BCC ReturnPlayerOutsideObjectSpan
    SBC #PlayerObjectVerticalSpan
    BCS ReturnPlayerOutsideObjectSpan
    LDA ObjectSpanXLo
    SEC
    SBC #PlayerObjectLeftReach
    STA ObjectSpanBoundaryXLo
    LDA ObjectSpanXHi
    SBC #$00
    STA ObjectSpanBoundaryXHi
    LDA ObjectSpanBoundaryXHi
    BPL ComparePlayerXWithObjectSpanStart
    LDA #$00
    STA ObjectSpanBoundaryXHi
    STA ObjectSpanBoundaryXLo

ComparePlayerXWithObjectSpanStart:
    LDA PlayerXLo
    CMP ObjectSpanBoundaryXLo
    LDA PlayerXHi
    SBC ObjectSpanBoundaryXHi
    BCC ReturnPlayerOutsideObjectSpan
    LDA ObjectSpanXLo
    CLC
    ADC ObjectSpanWidth
    STA ObjectSpanBoundaryXLo
    LDA ObjectSpanXHi
    ADC #$00
    STA ObjectSpanBoundaryXHi
    LDA PlayerXLo
    CMP ObjectSpanBoundaryXLo
    LDA PlayerXHi
    SBC ObjectSpanBoundaryXHi
    BCS ReturnPlayerOutsideObjectSpan
    RTS

ReturnPlayerOutsideObjectSpan:
    SEC
    RTS
