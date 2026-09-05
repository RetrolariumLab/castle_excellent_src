; Player-driven horizontal runtime-object pushing
; CPU range $881A-$89E0
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
