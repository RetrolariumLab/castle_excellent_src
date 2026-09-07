; Player collision pipeline
; CPU range $8DAB-$93F5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleAnimatedPlayerHazard:
    LDA PlayerCollisionAnimationCounter
    BPL StartPlayerDeathTransition
    RTS

StartPlayerDeathTransition:
    LDA PlayerDeathInvulnerabilityCountdown
    ORA PlayerTransitionCountdown
    BEQ BeginPlayerDeathTransition
    RTS

BeginPlayerDeathTransition:
    LDA #$80
    STA PlayerTransitionCountdown
    LDA #$00
    STA PlayerActionCountdown
    LDA PlayerLives
    BEQ SetPlayerGameOver
    DEC PlayerLives
    JMP StartPlayerDeathAudio

SetPlayerGameOver:
    LDA #$FF
    STA GameOverActive

StartPlayerDeathAudio:
    JMP LoadAudioTrackSet2

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

PrepareRoomCellSampleAddress:
    STA RoomCellSampleXHi
    STA RoomCellSampleColumnHi
    STX RoomCellSampleXLo
    STX RoomCellSampleColumnLo
    STY RoomCellSampleY
    LDA #$00
    STA RoomCellSamplePointerHi
    TYA
    LSR A
    LSR A
    LSR A
    STA RoomCellSamplePointerLo
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    CLC
    ADC RoomCellSamplePointerLo
    STA RoomCellSamplePointerLo
    BCC FinishRoomCellSampleRowPointer
    INC RoomCellSamplePointerHi

FinishRoomCellSampleRowPointer:
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    LDA #>RoomCells
    CLC
    ADC RoomCellSamplePointerHi
    STA RoomCellSamplePointerHi
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    RTS

RuntimeObjectOffsetByCount:
    .byte $00, $06, $0C, $12, $18, $1E, $24, $2A, $30, $36, $3C, $42, $48, $4E, $54, $5A
    .byte $60, $66, $6C, $72, $78, $7E, $84, $8A, $90

PlayerDownwardRoomCellCollisionHandlerPointers:
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $CB, $87, $CB, $87, $CB, $87
    .byte $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87
    .byte $CB, $87, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $85, $87, $85, $87
    .byte $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87
    .byte $85, $87, $85, $87, $6B, $92, $6B, $92

PlayerDownwardRuntimeCollisionHandlerPointerEntries80ToA6:
    .byte $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2, $8C
    .byte $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D

PlayerUpwardRoomCellCollisionHandlerPointers:
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92

PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6:
    .byte $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2, $8C
    .byte $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D

PlayerHorizontalRoomCellCollisionHandlerPointers:
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $DD, $A5, $DD, $A5, $6B, $92, $E7, $A5, $E7, $A5, $6B, $92, $F1, $A5
    .byte $F1, $A5, $6B, $92, $FB, $A5, $FB, $A5, $6B, $92, $05, $A6, $05, $A6, $6B, $92
    .byte $6B, $92, $0F, $A6, $0F, $A6, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92

PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6:
    .byte $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $1A, $88, $1A, $88, $1A, $88, $1A, $88, $E1, $89, $1A, $88
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2, $8C
    .byte $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D

ReturnFromPlayerCollisionHandler:
    RTS

PlayerRoomCellCollisionHandlerPointers:
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $AB, $8D, $AB, $8D, $AB, $8D
    .byte $AB, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92

PlayerRuntimeCollisionHandlerPointers:
    .byte $6B, $92, $70, $8D, $57, $8D, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $12, $8C, $21, $8C, $30, $8C, $3F, $8C, $4E, $8C, $5D, $8C, $9E, $8C, $F2, $8C
    .byte $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D
    .byte $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92
    .byte $6B, $92

UpdatePlayerCollisionState:
    LDA PlayerTransitionCountdown
    BEQ SamplePlayerCollisionPoints
    JMP AdvancePlayerTransitionCountdown

SamplePlayerCollisionPoints:
    LDY PlayerY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerCollisionHazardCellContact
    BEQ ReturnFromPlayerCollisionUpdate
    LDA PlayerCollisionHazardProtectionCountdown
    BNE ReturnFromPlayerCollisionUpdate
    JMP StartPlayerDeathTransition

ReturnFromPlayerCollisionUpdate:
    RTS
