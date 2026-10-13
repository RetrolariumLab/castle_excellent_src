; Room navigation and player interaction rules
; CPU range $A7DB-$AC12
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

MoveToRoomAbove:
    LDA CurrentRoomNumber
    CMP #FirstRoomWithAboveNeighbor
    BCC ReturnFromVerticalRoomMove
    SBC #CastleRoomColumns
    STA CurrentRoomNumber

ReturnFromVerticalRoomMove:
    RTS

MoveToRoomBelow:
    LDA CurrentRoomNumber
    CMP #FirstBottomRowRoomNumber
    BCS ReturnFromRoomMoveDown
    ADC #CastleRoomColumns
    STA CurrentRoomNumber

ReturnFromRoomMoveDown:
    RTS

MoveToRoomRight:
    LDA CurrentRoomNumber
    JSR FindRightmostCastleRoom
    BEQ ReturnFromRoomMoveRight
    CLC
    ADC #AdjacentRoomNumberStep
    STA CurrentRoomNumber

ReturnFromRoomMoveRight:
    RTS

MoveToRoomLeft:
    LDA CurrentRoomNumber
    JSR FindLeftmostCastleRoom
    BEQ ReturnFromRoomMoveLeft
    SEC
    SBC #AdjacentRoomNumberStep
    STA CurrentRoomNumber

ReturnFromRoomMoveLeft:
    RTS

FindRightmostCastleRoom:
    LDX #(CastleRoomRows - 1)

ScanRightmostCastleRooms:
    CMP RightmostCastleRoomNumbers,X
    BEQ ReturnRoomEdgeSearch
    DEX
    BPL ScanRightmostCastleRooms

ReturnRoomEdgeSearch:
    RTS

FindLeftmostCastleRoom:
    LDX #(CastleRoomRows - 1)

ScanLeftmostCastleRooms:
    CMP LeftmostCastleRoomNumbers,X
    BEQ ReturnLeftRoomEdgeSearch
    DEX
    BPL ScanLeftmostCastleRooms

ReturnLeftRoomEdgeSearch:
    RTS

RightmostCastleRoomNumbers:
    .byte $0A, $14, $1E, $28, $32, $3C, $46, $50, $5A, $64

LeftmostCastleRoomNumbers:
    .byte $01, $0B, $15, $1F, $29, $33, $3D, $47, $51, $5B

UpdatePlayerProtectionAndHazardState:
    LDA PlayerInvulnerabilityCountdown
    BEQ TickHazardProtectionCountdown
    LDA RoomFrameCounter
    AND #PlayerProtectionTickMask
    BNE TickHazardProtectionCountdown
    DEC PlayerInvulnerabilityCountdown
    BNE TickHazardProtectionCountdown
    JSR SelectRoomAudio

TickHazardProtectionCountdown:
    LDA PlayerHazardProtectionCountdown
    BEQ UpdatePlayerHazardCellContact
    LDA RoomFrameCounter
    AND #PlayerProtectionTickMask
    BNE UpdatePlayerHazardCellContact
    DEC PlayerHazardProtectionCountdown
    BNE UpdatePlayerHazardCellContact
    JSR SelectRoomAudio

UpdatePlayerHazardCellContact:
    LDA PlayerOnHazardCell
    LDA PlayerY
    CLC
    ADC #PlayerHazardProbeYOffset
    TAY
    CPY #PlayerHazardProbeTopBoundary
    BCC UseNonHazardRoomCell
    CPY #PlayerHazardProbeBottomBoundary
    BCS UseNonHazardRoomCell
    LDA PlayerXLo
    CLC
    ADC #<PlayerHazardProbeXOffset
    TAX
    LDA PlayerXHi
    ADC #>PlayerHazardProbeXOffset
    BEQ SamplePlayerHazardRoomCell
    CMP #PlayerHazardProbeRightBoundaryHi
    BNE UseNonHazardRoomCell
    CPX #PlayerHazardProbeRightBoundaryLo
    BCC SamplePlayerHazardRoomCell

UseNonHazardRoomCell:
    LDA #PlayerHazardContactInactive
    JMP ClassifyPlayerHazardRoomCell

SamplePlayerHazardRoomCell:
    PHA
    TYA
    SEC
    SBC #PlayerHazardProbeRoomYOffset
    TAY
    PLA
    JSR PrepareRoomCellSampleAddress
    LDY HazardCellColumnOffset
    LDA (HazardCellRowPointerLo),Y

ClassifyPlayerHazardRoomCell:
    LDX #PlayerHazardContactInactive
    CMP #HazardRoomCell
    BNE CheckRestoredHazardRoomCellTop
    LDX #PlayerHazardContactActive

CheckRestoredHazardRoomCellTop:
    CMP #RestoredHazardRoomCellTop
    BNE CheckRestoredHazardRoomCellBottom
    LDX #PlayerHazardContactActive

CheckRestoredHazardRoomCellBottom:
    CMP #RestoredHazardRoomCellBottom
    BNE StorePlayerHazardCellContact
    LDX #PlayerHazardContactActive

StorePlayerHazardCellContact:
    STX PlayerOnHazardCell
    RTS

IsCurrentObjectNearPlayer:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectPlayerProximityYOffset
    SEC
    SBC PlayerY
    BCS CompareObjectPlayerYDistance
    EOR #$FF
    ADC #$01

CompareObjectPlayerYDistance:
    CMP #ObjectPlayerProximityYLimit
    BCS ReturnObjectPlayerProximityResult
    LDA RuntimeObjectXLo,X
    SEC
    SBC PlayerXLo
    STA ObjectPlayerDeltaXLo
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
    STA ObjectPlayerDeltaXHi
    BCS CheckObjectPlayerXDistanceHigh
    LDA ObjectPlayerDeltaXLo
    EOR #$FF
    ADC #$01
    STA ObjectPlayerDeltaXLo
    LDA ObjectPlayerDeltaXHi
    EOR #$FF
    STA ObjectPlayerDeltaXHi

CheckObjectPlayerXDistanceHigh:
    BEQ CompareObjectPlayerXDistance
    SEC
    RTS

CompareObjectPlayerXDistance:
    LDA ObjectPlayerDeltaXLo
    CMP #ObjectPlayerProximityXLimit

ReturnObjectPlayerProximityResult:
    RTS

HandlePauseInput:
    LDA Controller1Buttons
    AND #PauseResumeButtons
    BEQ CheckPauseStartEdge
    LDA PreviousController1Buttons
    AND #PauseResumeButtons
    BNE CheckPauseStartEdge
    LDA PauseMode
    BNE LeavePauseMode

CheckPauseStartEdge:
    LDA Controller1Buttons
    AND #ControllerButtonStart
    BEQ CheckPausedScrollInput
    LDA PreviousController1Buttons
    AND #ControllerButtonStart
    BNE CheckPausedScrollInput
    LDA PauseMode
    BNE LeavePauseMode
    LDA #ApuChannelsDisabled
    STA APU_STATUS
    LDA #PauseModeActive
    BNE StorePauseMode

LeavePauseMode:
    LDA #PauseModeInactive

StorePauseMode:
    STA PauseMode
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

CheckPausedScrollInput:
    LDA PauseMode
    BNE UpdatePausedScroll
    RTS

UpdatePausedScroll:
    LDA Controller1Buttons
    AND #ControllerButtonLeft
    BEQ CheckPausedScrollRight
    LDA PausedScrollX
    SEC
    SBC #PauseScrollStep
    BCS StorePausedScrollLeft
    LDA #PauseScrollMinimum

StorePausedScrollLeft:
    STA PausedScrollX
    LDA #PauseScrollUpdateRequested
    STA PausedScrollUpdatePending
    JMP RememberPauseButtons

CheckPausedScrollRight:
    LDA Controller1Buttons
    AND #ControllerButtonRight
    BEQ RememberPauseButtons
    LDA PausedScrollX
    CLC
    ADC #PauseScrollStep
    BPL StorePausedScrollRight
    LDA #PauseScrollMaximum

StorePausedScrollRight:
    STA PausedScrollX
    LDA #PauseScrollUpdateRequested
    STA PausedScrollUpdatePending

RememberPauseButtons:
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

PlayerCollisionFlagsByRoomCellHalf:
; Left and right eight-pixel halves per cell: $01 solid, $80 touch-only, $00 empty
    .byte $01, $01  ; cell $00
    .byte $01, $01  ; cell $01
    .byte $01, $01  ; cell $02
    .byte $01, $01  ; cell $03
    .byte $01, $01  ; cell $04
    .byte $01, $01  ; cell $05
    .byte $00, $01  ; cell $06
    .byte $01, $00  ; cell $07
    .byte $01, $01  ; cell $08
    .byte $01, $01  ; cell $09
    .byte $00, $01  ; cell $0A
    .byte $00, $00  ; cell $0B
    .byte $01, $00  ; cell $0C
    .byte $00, $00  ; cell $0D
    .byte $01, $01  ; cell $0E
    .byte $01, $01  ; cell $0F
    .byte $01, $01  ; cell $10
    .byte $01, $01  ; cell $11
    .byte $01, $01  ; cell $12
    .byte $01, $01  ; cell $13
    .byte $01, $01  ; cell $14
    .byte $00, $00  ; cell $15
    .byte $00, $00  ; cell $16
    .byte $00, $00  ; cell $17
    .byte $01, $01  ; cell $18
    .byte $01, $01  ; cell $19
    .byte $01, $01  ; cell $1A
    .byte $01, $01  ; cell $1B
    .byte $01, $01  ; cell $1C
    .byte $01, $01  ; cell $1D
    .byte $01, $01  ; cell $1E
    .byte $01, $01  ; cell $1F
    .byte $01, $01  ; cell $20
    .byte $01, $01  ; cell $21
    .byte $01, $01  ; cell $22
    .byte $01, $01  ; cell $23
    .byte $01, $01  ; cell $24
    .byte $01, $01  ; cell $25
    .byte $01, $01  ; cell $26
    .byte $01, $01  ; cell $27
    .byte $01, $01  ; cell $28
    .byte $01, $01  ; cell $29
    .byte $01, $01  ; cell $2A
    .byte $01, $01  ; cell $2B
    .byte $01, $01  ; cell $2C
    .byte $01, $01  ; cell $2D
    .byte $01, $01  ; cell $2E
    .byte $80, $80  ; cell $2F
    .byte $80, $80  ; cell $30
    .byte $80, $80  ; cell $31
    .byte $80, $80  ; cell $32
    .byte $80, $80  ; cell $33
    .byte $80, $80  ; cell $34
    .byte $01, $01  ; cell $35
    .byte $01, $01  ; cell $36
    .byte $01, $01  ; cell $37
    .byte $01, $01  ; cell $38
    .byte $01, $01  ; cell $39
    .byte $01, $01  ; cell $3A
    .byte $01, $01  ; cell $3B
    .byte $01, $01  ; cell $3C
    .byte $01, $01  ; cell $3D
    .byte $01, $01  ; cell $3E
    .byte $01, $01  ; cell $3F
    .byte $01, $01  ; cell $40
    .byte $01, $00  ; cell $41
    .byte $00, $01  ; cell $42
    .byte $00, $00  ; cell $43
    .byte $01, $01  ; cell $44
    .byte $01, $01  ; cell $45
    .byte $01, $01  ; cell $46
    .byte $01, $01  ; cell $47
    .byte $01, $01  ; cell $48
    .byte $01, $01  ; cell $49
    .byte $01, $01  ; cell $4A
    .byte $01, $01  ; cell $4B
    .byte $01, $01  ; cell $4C
    .byte $01, $01  ; cell $4D
    .byte $01, $01  ; cell $4E
    .byte $00, $00  ; cell $4F
    .byte $00, $00  ; cell $50
    .byte $01, $01  ; cell $51
    .byte $00, $00  ; cell $52
    .byte $00, $00  ; cell $53
    .byte $00, $00  ; cell $54
    .byte $00, $00  ; cell $55
    .byte $01, $01  ; cell $56
    .byte $01, $01  ; cell $57
    .byte $01, $01  ; cell $58
    .byte $01, $01  ; cell $59
    .byte $01, $01  ; cell $5A
    .byte $01, $01  ; cell $5B
    .byte $01, $01  ; cell $5C
    .byte $01, $01  ; cell $5D
    .byte $01, $01  ; cell $5E
    .byte $01, $01  ; cell $5F
    .byte $01, $01  ; cell $60
    .byte $01, $01  ; cell $61
    .byte $00, $00  ; cell $62
    .byte $00, $00  ; cell $63

ObjectCollisionFlagsByRoomCellHalf:
; Left and right eight-pixel halves per cell for runtime objects; $00 is empty
    .byte $01, $01  ; cell $00
    .byte $01, $01  ; cell $01
    .byte $01, $01  ; cell $02
    .byte $01, $01  ; cell $03
    .byte $01, $01  ; cell $04
    .byte $01, $01  ; cell $05
    .byte $00, $01  ; cell $06
    .byte $01, $00  ; cell $07
    .byte $01, $01  ; cell $08
    .byte $01, $01  ; cell $09
    .byte $00, $01  ; cell $0A
    .byte $00, $01  ; cell $0B
    .byte $01, $00  ; cell $0C
    .byte $01, $00  ; cell $0D
    .byte $01, $01  ; cell $0E
    .byte $01, $01  ; cell $0F
    .byte $01, $01  ; cell $10
    .byte $01, $01  ; cell $11
    .byte $00, $00  ; cell $12
    .byte $00, $00  ; cell $13
    .byte $00, $00  ; cell $14
    .byte $00, $00  ; cell $15
    .byte $00, $00  ; cell $16
    .byte $00, $00  ; cell $17
    .byte $01, $01  ; cell $18
    .byte $01, $01  ; cell $19
    .byte $01, $01  ; cell $1A
    .byte $01, $01  ; cell $1B
    .byte $01, $01  ; cell $1C
    .byte $01, $01  ; cell $1D
    .byte $01, $01  ; cell $1E
    .byte $01, $01  ; cell $1F
    .byte $01, $01  ; cell $20
    .byte $01, $01  ; cell $21
    .byte $01, $01  ; cell $22
    .byte $01, $01  ; cell $23
    .byte $01, $01  ; cell $24
    .byte $01, $01  ; cell $25
    .byte $01, $01  ; cell $26
    .byte $01, $01  ; cell $27
    .byte $01, $01  ; cell $28
    .byte $01, $01  ; cell $29
    .byte $01, $01  ; cell $2A
    .byte $01, $01  ; cell $2B
    .byte $01, $01  ; cell $2C
    .byte $01, $01  ; cell $2D
    .byte $01, $01  ; cell $2E
    .byte $81, $81  ; cell $2F
    .byte $81, $81  ; cell $30
    .byte $81, $81  ; cell $31
    .byte $81, $81  ; cell $32
    .byte $81, $81  ; cell $33
    .byte $81, $81  ; cell $34
    .byte $01, $01  ; cell $35
    .byte $01, $01  ; cell $36
    .byte $01, $01  ; cell $37
    .byte $01, $01  ; cell $38
    .byte $01, $01  ; cell $39
    .byte $01, $01  ; cell $3A
    .byte $01, $01  ; cell $3B
    .byte $01, $01  ; cell $3C
    .byte $01, $01  ; cell $3D
    .byte $01, $01  ; cell $3E
    .byte $01, $01  ; cell $3F
    .byte $01, $01  ; cell $40
    .byte $01, $00  ; cell $41
    .byte $00, $01  ; cell $42
    .byte $00, $00  ; cell $43
    .byte $01, $01  ; cell $44
    .byte $01, $01  ; cell $45
    .byte $01, $01  ; cell $46
    .byte $01, $01  ; cell $47
    .byte $01, $01  ; cell $48
    .byte $01, $01  ; cell $49
    .byte $01, $01  ; cell $4A
    .byte $01, $01  ; cell $4B
    .byte $01, $01  ; cell $4C
    .byte $01, $01  ; cell $4D
    .byte $01, $01  ; cell $4E
    .byte $01, $01  ; cell $4F
    .byte $01, $01  ; cell $50
    .byte $01, $01  ; cell $51
    .byte $00, $00  ; cell $52
    .byte $00, $00  ; cell $53
    .byte $01, $01  ; cell $54
    .byte $01, $01  ; cell $55
    .byte $01, $01  ; cell $56
    .byte $01, $01  ; cell $57
    .byte $01, $01  ; cell $58
    .byte $01, $01  ; cell $59
    .byte $01, $01  ; cell $5A
    .byte $01, $01  ; cell $5B
    .byte $01, $01  ; cell $5C
    .byte $01, $01  ; cell $5D
    .byte $01, $01  ; cell $5E
    .byte $01, $01  ; cell $5F
    .byte $01, $01  ; cell $60
    .byte $01, $01  ; cell $61
    .byte $01, $01  ; cell $62
    .byte $01, $01  ; cell $63

RuntimeObjectCollisionWidths:
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $20, $10, $10, $10, $08, $10, $10, $10, $10, $10, $10, $10, $10, $10

RuntimeObjectCollisionHeights:
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10, $10, $10, $10

RoomObjectCounts:
    .byte $08, $06, $03, $0F, $02, $11, $05, $06, $0B, $0C, $03, $03, $06, $0F, $05, $0A
    .byte $08, $07, $02, $0A, $04, $03, $04, $04, $03, $12, $06, $07, $07, $05, $09, $09
    .byte $04, $0C, $04, $08, $08, $02, $09, $08, $08, $11, $07, $08, $07, $06, $09, $05
    .byte $08, $0F, $09, $0A, $03, $05, $06, $06, $0C, $06, $06, $03, $08, $09, $08, $0E
    .byte $07, $09, $09, $0E, $04, $04, $0D, $07, $11, $06, $04, $09, $0D, $09, $09, $05
    .byte $06, $0A, $07, $09, $06, $07, $07, $08, $08, $0B, $09, $07, $03, $0E, $0C, $06
    .byte $06, $09, $0C, $04

RoomMutableCellStateOffsets:
    .byte $00, $01, $02, $03, $04, $05, $07, $09, $0B, $0C, $0D, $0D, $0E, $0F, $10, $12
    .byte $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22
    .byte $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2E, $2F, $30, $31, $32, $33
    .byte $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43
    .byte $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50, $51, $52, $53, $54
    .byte $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F, $60, $61, $62, $63, $65
    .byte $66, $67, $68, $69, $6C
