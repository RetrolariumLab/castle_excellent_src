; Player room transitions and object pushing
; CPU range $867A-$89E0
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

TransitionToRoomAbove:
    LDA #AboveRoomEntryPlayerY
    STA PlayerY
    STA BoundaryTransitionPlayerY
    LDA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerXLo
    AND #RoomBoundaryPlayerXAlignmentMask
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomAbove
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

TransitionToRoomBelow:
    LDA #BelowRoomEntryPlayerY
    STA PlayerY
    STA BoundaryTransitionPlayerY
    LDA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerXLo
    AND #RoomBoundaryPlayerXAlignmentMask
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomBelow
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

HandleLeftRoomBoundary:
    LDA CurrentRoomNumber
    JSR FindLeftmostCastleRoom
    BNE TransitionToRoomLeft
    LDA #<LeftRoomEdgePlayerX
    STA PlayerXLo
    STA PlayerXHi
    JMP UpdateHorizontalScroll

TransitionToRoomLeft:
    LDA #<RightRoomEdgePlayerX
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    LDA #>RightRoomEdgePlayerX
    STA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerY
    STA BoundaryTransitionPlayerY
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomLeft
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #RoomBoundaryEntranceProbeYOffset
    TAY
    LDA #>RightRoomEdgePlayerX
    LDX #<RightRoomEdgePlayerX
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS FinishLeftRoomTransition
    JSR RestoreMutableCellByOrdinal

FinishLeftRoomTransition:
    JMP FinishRoomTransition

HandleRightRoomBoundary:
    LDA CurrentRoomNumber
    JSR FindRightmostCastleRoom
    BNE TransitionToRoomRight
    LDA #>RightRoomEdgePlayerX
    STA PlayerXHi
    LDA #<RightRoomEdgePlayerX
    STA PlayerXLo
    JMP UpdateHorizontalScroll

TransitionToRoomRight:
    LDA #<LeftRoomEdgePlayerX
    STA PlayerXLo
    STA PlayerXHi
    STA BoundaryTransitionPlayerXLo
    STA BoundaryTransitionPlayerXHi
    LDA PlayerY
    STA BoundaryTransitionPlayerY
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomRight
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #RoomBoundaryEntranceProbeYOffset
    TAY
    LDA #>LeftRoomEdgePlayerX
    LDX #<LeftRoomEdgePlayerX
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS FinishRightRoomTransition
    JSR RestoreMutableCellByOrdinal

FinishRightRoomTransition:
    JMP FinishRoomTransition

SaveCurrentRoomObjectState:
    LDX #$00

EncodeNextRoomObjectStateBit:
    SEC
    LDA RuntimeObjectRecords,X
    BPL RotateRoomObjectStateBit
    CMP #RuntimeObjectPersistentTypeEnd

RotateRoomObjectStateBit:
    ROR SavedRoomObjectStateBits + $02
    ROR SavedRoomObjectStateBits + $01
    ROR SavedRoomObjectStateBits
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC EncodeNextRoomObjectStateBit
    LDA CurrentRoomNumber
    STA CurrentRoomState
    LDA SavedRoomObjectStateBits
    STA CurrentRoomObjectState
    LDA SavedRoomObjectStateBits + $01
    STA CurrentRoomObjectState + $01
    LDA SavedRoomObjectStateBits + $02
    STA CurrentRoomObjectState + $02
    RTS

MovePlayerLeftOnIncrementingAnimatedCell:
    LDA PlayerXLo
    SEC
    SBC #AnimatedCellPlayerStep
    STA AnimatedCellPlayerXLo
    LDA PlayerXHi
    SBC #$00
    STA AnimatedCellPlayerXHi
    BMI ReturnFromAnimatedCellPlayerDisplacement
    LDY PlayerY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerMiddleYOffset
    TAY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerBottomYOffset
    TAY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement

CommitAnimatedCellPlayerDisplacement:
    LDA AnimatedCellPlayerXLo
    STA PlayerXLo
    LDA AnimatedCellPlayerXHi
    STA PlayerXHi
    LDA #AnimatedCellMovementLatchSet
    STA PlayerAnimatedCellMovementLatch

ReturnFromAnimatedCellPlayerDisplacement:
    RTS

MovePlayerRightOnDecrementingAnimatedCell:
    LDA PlayerXLo
    CLC
    ADC #AnimatedCellPlayerStep
    STA AnimatedCellPlayerXLo
    LDA PlayerXHi
    ADC #$00
    STA AnimatedCellPlayerXHi
    LDA PlayerXLo
    CLC
    ADC #AnimatedCellPlayerRightEdgeOffset
    STA AnimatedCellPlayerEdgeXLo
    LDA PlayerXHi
    ADC #$00
    STA AnimatedCellPlayerEdgeXHi
    LDA PlayerXLo
    CMP #AnimatedCellPlayerRightLimitLo
    LDA PlayerXHi
    SBC #AnimatedCellPlayerRightLimitHi
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDY PlayerY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerMiddleYOffset
    TAY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerBottomYOffset
    TAY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    BCC CommitAnimatedCellPlayerDisplacement

PushPlayerAndRuntimeObject:
    JSR GetActivePlayerMotionState
    ORA PlayerPushMotionPhase
    BEQ ProbePushedObjectSupport
    RTS

ProbePushedObjectSupport:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PushedObjectSupportYOffset
    TAY
    JSR GetRuntimeObjectX
    JSR SampleNormalizedRoomCollisionCell
    BCS ProbePlayerPushClearance
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PushedObjectSupportYOffset
    TAY
    JSR GetRuntimeObjectXPlus7
    JSR SampleNormalizedRoomCollisionCell
    BCS ProbePlayerPushClearance
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PushedObjectSupportYOffset
    TAY
    JSR GetRuntimeObjectXPlus15
    JSR SampleNormalizedRoomCollisionCell
    BCS ProbePlayerPushClearance
    RTS

ProbePlayerPushClearance:
    LDX CurrentObjectOffset
    STX PushedRuntimeObjectOffset
    LDA PlayerPushDirection
    BMI ProbePlayerPushLeftTop
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerXLo
    CLC
    ADC #PlayerPushRightTopXOffset
    TAX
    LDA PlayerXHi
    ADC #$00
    LDY PlayerY
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerPushRightMiddle
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ ProbePlayerPushRightMiddle
    SEC
    RTS

ProbePlayerPushRightMiddle:
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #PlayerPushMiddleYOffset
    TAY
    LDA PlayerXLo
    CLC
    ADC #PlayerPushRightLowerXOffset
    TAX
    LDA PlayerXHi
    ADC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerPushRightBottom
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ ProbePlayerPushRightBottom
    SEC
    RTS

ProbePlayerPushRightBottom:
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #PlayerPushBottomYOffset
    TAY
    LDA PlayerXLo
    CLC
    ADC #PlayerPushRightLowerXOffset
    TAX
    LDA PlayerXHi
    ADC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC AcceptRightPlayerPushClearance
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ AcceptRightPlayerPushClearance
    SEC
    RTS

AcceptRightPlayerPushClearance:
    JMP SelectPushedObjectLeadingEdge

ProbePlayerPushLeftTop:
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerXLo
    SEC
    SBC #PlayerPushLeftTopXOffset
    TAX
    LDA PlayerXHi
    SBC #$00
    LDY PlayerY
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerPushLeftMiddle
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ ProbePlayerPushLeftMiddle
    SEC
    RTS

ProbePlayerPushLeftMiddle:
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #PlayerPushMiddleYOffset
    TAY
    LDA PlayerXLo
    SEC
    SBC #PlayerPushLeftLowerXOffset
    TAX
    LDA PlayerXHi
    SBC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerPushLeftBottom
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ ProbePlayerPushLeftBottom
    SEC
    RTS

ProbePlayerPushLeftBottom:
    LDA #PlayerPushNoCurrentObjectOffset
    STA CurrentObjectOffset
    LDA PlayerY
    CLC
    ADC #PlayerPushBottomYOffset
    TAY
    LDA PlayerXLo
    SEC
    SBC #PlayerPushLeftLowerXOffset
    TAX
    LDA PlayerXHi
    SBC #$00
    JSR SamplePlayerCollisionAtScreenPixel
    BCC SelectPushedObjectLeadingEdge
    LDA CurrentObjectOffset
    CMP PushedRuntimeObjectOffset
    BEQ SelectPushedObjectLeadingEdge
    SEC
    RTS

SelectPushedObjectLeadingEdge:
    LDX PushedRuntimeObjectOffset
    LDA PlayerPushDirection
    BMI BuildPushedObjectLeftEdge
    LDA RuntimeObjectXLo,X
    CLC
    ADC #PushedObjectWidth
    STA PushedObjectProbeXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA PushedObjectProbeXHi
    LDA PushedObjectProbeXLo
    CMP #PlayerObjectPushRightBoundaryLo
    LDA PushedObjectProbeXHi
    SBC #PlayerObjectPushRightBoundaryHi
    BCC ProbePushedObjectFront

ReturnBoundaryBlockedPlayerObjectPush:
    RTS

BuildPushedObjectLeftEdge:
    LDA RuntimeObjectXLo,X
    STA PushedObjectProbeXLo
    LDA RuntimeObjectXHi,X
    STA PushedObjectProbeXHi
    LDA PushedObjectProbeXLo
    BNE FinishPushedObjectLeftEdge
    DEC PushedObjectProbeXHi

FinishPushedObjectLeftEdge:
    DEC PushedObjectProbeXLo
    LDA PushedObjectProbeXLo
    CMP #PlayerObjectPushRightBoundaryLo
    LDA PushedObjectProbeXHi
    SBC #PlayerObjectPushRightBoundaryHi
    BCS ReturnBoundaryBlockedPlayerObjectPush

ProbePushedObjectFront:
    LDY RuntimeObjectY,X
    LDA PushedObjectProbeXHi
    LDX PushedObjectProbeXLo
    JSR SampleNormalizedRoomCollisionCell
    BCS HandlePushedObjectFrontCollision
    BMI HandlePushedObjectFrontCollision
    LDX PushedRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PlayerPushMiddleYOffset
    TAY
    LDA PushedObjectProbeXHi
    LDX PushedObjectProbeXLo
    JSR SampleNormalizedRoomCollisionCell
    BCS HandlePushedObjectFrontCollision
    BMI HandlePushedObjectFrontCollision
    LDX PushedRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #PlayerPushBottomYOffset
    TAY
    LDA PushedObjectProbeXHi
    LDX PushedObjectProbeXLo
    JSR SampleNormalizedRoomCollisionCell
    BCC CommitPlayerObjectPush

HandlePushedObjectFrontCollision:
    CMP #RuntimeObjectCollisionTypeFirst
    BCC ReturnBlockedPlayerObjectPush
    JSR GetRuntimeObjectType84To89Filter
    BNE ReturnBlockedPlayerObjectPush
    LDX PushedObjectCollisionOffset
    LDA #PushDestroyedRuntimeType
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JSR StartPulse2NoiseSoundEffect2
    JMP CommitPlayerObjectPush

ReturnBlockedPlayerObjectPush:
    SEC
    RTS

CommitPlayerObjectPush:
    LDX PushedRuntimeObjectOffset
    LDA PlayerPushDirection
    BMI MovePushedObjectLeft
    LDA RuntimeObjectXLo,X
    CLC
    ADC #PlayerObjectPushStep
    STA RuntimeObjectXLo,X
    BCC MovePlayerRightWithObject
    INC RuntimeObjectXHi,X

MovePlayerRightWithObject:
    LDA PlayerXLo
    CLC
    ADC #PlayerObjectPushStep
    STA PlayerXLo
    BCC SetRightPlayerObjectPushLatch
    INC PlayerXHi

SetRightPlayerObjectPushLatch:
    LDA #PlayerDirectionRight
    STA PlayerObjectPushDirectionLatch
    JMP ReturnSuccessfulPlayerObjectPush

MovePushedObjectLeft:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #PlayerObjectPushStep
    STA RuntimeObjectXLo,X
    BCS MovePlayerLeftWithObject
    DEC RuntimeObjectXHi,X

MovePlayerLeftWithObject:
    LDA PlayerXLo
    SEC
    SBC #PlayerObjectPushStep
    STA PlayerXLo
    BCS SetLeftPlayerObjectPushLatch
    DEC PlayerXHi

SetLeftPlayerObjectPushLatch:
    LDA #PlayerDirectionLeft
    STA PlayerObjectPushDirectionLatch

ReturnSuccessfulPlayerObjectPush:
    CLC

ReturnPlayerObjectPush:
    RTS
