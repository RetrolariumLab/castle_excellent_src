; Pushable-object gravity, conveyor motion, crushing, and lift control
; CPU range $965C-$9795
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateLiftControlBlock:
    LDA #PushableMotionInactive
    STA PushableHorizontalMotionLatch
    JSR UpdatePushableObjectPhysics
    LDX CurrentRuntimeObjectOffset
    LDA PushableHorizontalMotionLatch
    BEQ ReturnFromLiftControlBlockUpdate
    BPL LowerLiftAfterControlBlockMotion
    JMP RaiseLinkedLift

LowerLiftAfterControlBlockMotion:
    JMP LowerLinkedLift

ReturnFromLiftControlBlockUpdate:
    RTS

UpdatePushableObjectPhysics:
    STX CurrentObjectOffset
    LDA #EmptyRoomCell
    STA PushablePreviousSupportCollision
    LDA #PushableSupportCollisionCountInitial
    STA PushableSupportCollisionCount
    LDA RuntimeObjectXLo,X
    STA PushableCandidateXLo
    LDA RuntimeObjectXHi,X
    STA PushableCandidateXHi
    LDA RuntimeObjectY,X
    CLC
    ADC #PushableSupportYOffset
    STA PushableSupportProbeY
    TAY
    LDA PushableCandidateXHi
    LDX PushableCandidateXLo
    JSR SampleNormalizedRoomCollisionCell
    BCC ProbePushableMiddleSupport
    STA PushablePreviousSupportCollision
    INC PushableSupportCollisionCount
    JSR ClassifyAnimatedCollisionCell
    BCS HandlePushableSupportCollision

ProbePushableMiddleSupport:
    LDY PushableSupportProbeY
    LDA PushableCandidateXLo
    CLC
    ADC #PushableMiddleXOffset
    TAX
    LDA PushableCandidateXHi
    ADC #$00
    JSR SampleNormalizedRoomCollisionCell
    BCC ProbePushableRightSupport
    STA PushablePreviousSupportCollision
    INC PushableSupportCollisionCount
    JSR ClassifyAnimatedCollisionCell
    BCS HandlePushableSupportCollision

ProbePushableRightSupport:
    LDY PushableSupportProbeY
    LDA PushableCandidateXLo
    CLC
    ADC #PushableRightXOffset
    TAX
    LDA PushableCandidateXHi
    ADC #$00
    JSR SampleNormalizedRoomCollisionCell
    BCS HandlePushableSupportCollision
    LDA PushablePreviousSupportCollision
    LDY PushableSupportCollisionCount
    BNE HandlePushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CMP #RuntimeObjectVisibleYLimit
    BCS ReturnFromPushableObjectUpdate
    ADC #PushableFallStep
    STA RuntimeObjectY,X

ReturnFromPushableObjectUpdate:
    RTS

HandlePushableSupportCollision:
    STA PushableSupportCollision
    STX PushableSupportProbeXLo
    JSR ClassifyAnimatedCollisionCell
    BCS TryMovePushableRightOnConveyor
    JMP TryCrushRuntimeObjectBelowPushable

TryMovePushableRightOnConveyor:
    BMI TryMovePushableLeftOnConveyor
    LDA #PushableConveyorStep
    CLC
    ADC PushableCandidateXLo
    STA PushableCandidateXLo
    LDA PushableCandidateXHi
    ADC #$00
    STA PushableCandidateXHi
    LDA PushableCandidateXLo
    CLC
    ADC #PushableRightXOffset
    STA PushableLeadingEdgeXLo
    LDA PushableCandidateXHi
    ADC #$00
    STA PushableLeadingEdgeXHi
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    LDX PushableLeadingEdgeXLo
    LDA PushableLeadingEdgeXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    LDX PushableLeadingEdgeXLo
    LDA PushableLeadingEdgeXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDA #PushableMotionRight
    STA PushableHorizontalMotionLatch
    JMP CommitConveyorPushableX

TryMovePushableLeftOnConveyor:
    LDA PushableCandidateXLo
    SEC
    SBC #PushableConveyorStep
    STA PushableCandidateXLo
    LDA PushableCandidateXHi
    SBC #$00
    STA PushableCandidateXHi
    LDX CurrentRuntimeObjectOffset
    LDY RuntimeObjectY,X
    LDX PushableCandidateXLo
    LDA PushableCandidateXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    LDX PushableCandidateXLo
    LDA PushableCandidateXHi
    JSR SampleNormalizedRoomCollisionCell
    BCS ReturnFromPushableSupportCollision
    BMI ReturnFromPushableSupportCollision
    LDA #PushableMotionLeft
    STA PushableHorizontalMotionLatch

CommitConveyorPushableX:
    LDX CurrentRuntimeObjectOffset
    LDA PushableCandidateXLo
    STA RuntimeObjectXLo,X
    LDA PushableCandidateXHi
    STA RuntimeObjectXHi,X

ReturnFromPushableSupportCollision:
    RTS

TryCrushRuntimeObjectBelowPushable:
    LDA PushableSupportCollision
    JSR GetRuntimeObjectType84To89Filter
    BEQ ValidatePushableCrushContact
    RTS

ValidatePushableCrushContact:
    LDA PushablePreviousSupportCollision
    CMP PushableSupportCollision
    BEQ SelectCrushedRuntimeObject
    LDA PushablePreviousSupportCollision
    CMP #EmptyRoomCell
    BEQ SelectCrushedRuntimeObject
    RTS

SelectCrushedRuntimeObject:
    LDX PushableCollisionObjectOffset

DestroyRuntimeObjectWithSound:
    LDA #CrushedRuntimeObjectType
    STA RuntimeObjectRecords,X
    LDA #DestroyedRuntimeObjectInitialState
    STA RuntimeObjectState,X
    JMP StartPulse2NoiseSoundEffect2

DestroyCurrentRuntimeObjectWithSound:
    LDX CurrentRuntimeObjectOffset
    JMP DestroyRuntimeObjectWithSound
