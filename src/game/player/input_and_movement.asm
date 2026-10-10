; Player input and movement
; CPU range $82CE-$8679
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdatePlayerInputAndMovement:
    LDA PlayerTransitionCountdown
    BEQ CheckPlayerTopBoundary
    RTS

CheckPlayerTopBoundary:
    LDA PlayerY
    BNE UpdatePlayerJumpAudio
    JMP TransitionToRoomAbove

UpdatePlayerJumpAudio:
    JSR GetActivePlayerMotionState
    AND #$03
    BNE UpdatePlayerActionInput
    LDA Controller1Buttons
    AND #ControllerButtonA
    BNE UpdatePlayerActionInput
    STA PlayerMovementState
    LDA Pulse1SoundEffectRequest
    CMP #$01
    BNE UpdatePlayerActionInput
    LDA #$0E
    STA APU_STATUS
    LDA #$00
    STA Pulse1SoundEffectRequest

UpdatePlayerActionInput:
    LDA Controller1Buttons
    AND #ControllerButtonB
    BNE StartPlayerAction
    STA MovementPlayerActionCountdown
    STA PlayerActionHeldLatch
    BEQ AdvancePlayerVerticalMotion

StartPlayerAction:
    LDA PlayerActionHeldLatch
    BNE TickPlayerAction
    LDA #PlayerActionDuration
    STA MovementPlayerActionCountdown
    STA PlayerActionHeldLatch
    BNE AdvancePlayerVerticalMotion

TickPlayerAction:
    LDA MovementPlayerActionCountdown
    BEQ AdvancePlayerVerticalMotion
    DEC MovementPlayerActionCountdown

AdvancePlayerVerticalMotion:
    LDA PlayerMovementState
    CMP #PlayerMotionInactiveThreshold
    BCC SelectPlayerVerticalMovement
    LDA PlayerXLo
    AND #PlayerCoordinateAlignmentMask
    BNE SelectPlayerVerticalMovement
    DEC PlayerMovementState
    JSR StartPulse1SoundEffect1

SelectPlayerVerticalMovement:
    JSR GetActivePlayerMotionState
    BNE AdvancePlayerAscent
    JMP ApplyPlayerGravity

AdvancePlayerAscent:
    DEC PlayerMovementState
    BNE MovePlayerUpward
    LDA #PlayerMovementPhaseActive
    STA PlayerMovementPhase

MovePlayerUpward:
    LDA PlayerMovementState
    CMP #PlayerAscentMoveThreshold
    BCS PreparePlayerUpwardProbe
    JMP ContinuePlayerHorizontalUpdate

PreparePlayerUpwardProbe:
    LDY PlayerY
    DEY
    DEY
    STY PlayerUpwardProbeY
    CPY #PlayerScreenTopBoundary
    BCS ProbePlayerUpwardCollision
    JMP ContinuePlayerHorizontalUpdate

ProbePlayerUpwardCollision:
    JSR GetPlayerXPlus7
    LDY PlayerUpwardProbeY
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerUpwardCollision
    LDA PlayerXHi
    LDX PlayerXLo
    LDY PlayerUpwardProbeY
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerUpwardCollision
    JSR GetPlayerXPlus15
    LDY PlayerUpwardProbeY
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerUpwardCollision
    DEC PlayerY
    DEC PlayerY
    JMP ContinuePlayerHorizontalUpdate

DispatchPlayerUpwardCollision:
    ASL A
    TAX
    BCS SelectPlayerUpwardRuntimeHandler
    LDA PlayerUpwardRoomCellCollisionHandlerPointers,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerUpwardRoomCellCollisionHandlerPointers + 1,X
    STA PlayerMovementCollisionHandlerPointerHi
    JMP InvokePlayerUpwardCollisionHandler

SelectPlayerUpwardRuntimeHandler:
    LDA PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA PlayerMovementCollisionHandlerPointerHi

InvokePlayerUpwardCollisionHandler:
    LDA #>(ResumeAfterPlayerUpwardCollision - 1)
    PHA
    LDA #<(ResumeAfterPlayerUpwardCollision - 1)
    PHA
    JMP (PlayerMovementCollisionHandlerPointerLo)

ResumeAfterPlayerUpwardCollision:
    JMP ContinuePlayerHorizontalUpdate

ApplyPlayerGravity:
    LDA #PlayerDownwardInitialProbeOffset
    STA PlayerDownwardProbeYOffset

ProbePlayerDownwardCollision:
    LDA #$00
    STA PlayerDownwardSolidProbeCount
    STA PlayerDownwardCenterCollision
    LDA PlayerY
    CLC
    ADC PlayerDownwardProbeYOffset
    TAY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerDownwardCenter
    STA PlayerDownwardLeftCollision
    JSR ClassifyAnimatedCollisionCell
    BCS RetryPlayerDownwardProbe
    INC PlayerDownwardSolidProbeCount

ProbePlayerDownwardCenter:
    LDA PlayerY
    CLC
    ADC PlayerDownwardProbeYOffset
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCC ProbePlayerDownwardRight
    STA PlayerDownwardCenterCollision
    JSR ClassifyAnimatedCollisionCell
    BCS RetryPlayerDownwardProbe
    INC PlayerDownwardSolidProbeCount

ProbePlayerDownwardRight:
    LDA PlayerY
    CLC
    ADC PlayerDownwardProbeYOffset
    TAY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    BCS RetryPlayerDownwardProbe
    LDA PlayerDownwardSolidProbeCount
    BEQ MovePlayerDownward
    LDA PlayerDownwardCenterCollision
    BNE UsePlayerDownwardCollision
    LDA PlayerDownwardLeftCollision

UsePlayerDownwardCollision:
    JMP RetryPlayerDownwardProbe

MovePlayerDownward:
    LDA #PlayerMovementPhaseActive
    STA PlayerMovementPhase
    LDA PlayerDownwardProbeYOffset
    CMP #$11
    BNE AdvancePlayerDownward
    INC PlayerY

AdvancePlayerDownward:
    INC PlayerY
    LDA PlayerY
    CMP #PlayerScreenBottomBoundary
    BCC ContinuePlayerHorizontalUpdate
    JMP TransitionToRoomBelow

RetryPlayerDownwardProbe:
    LDX #PlayerDownwardRetryProbeOffset
    CPX PlayerDownwardProbeYOffset
    BEQ DispatchPlayerDownwardCollision
    STX PlayerDownwardProbeYOffset
    JMP ProbePlayerDownwardCollision

DispatchPlayerDownwardCollision:
    ASL A
    TAX
    BCS SelectPlayerDownwardRuntimeHandler
    LDA PlayerDownwardRoomCellCollisionHandlerPointers,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerDownwardRoomCellCollisionHandlerPointers + 1,X
    STA PlayerMovementCollisionHandlerPointerHi
    JMP InvokePlayerDownwardCollisionHandler

SelectPlayerDownwardRuntimeHandler:
    LDA PlayerDownwardRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerDownwardRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA PlayerMovementCollisionHandlerPointerHi

InvokePlayerDownwardCollisionHandler:
    LDA #>(ResumeAfterPlayerDownwardCollision - 1)
    PHA
    LDA #<(ResumeAfterPlayerDownwardCollision - 1)
    PHA
    JMP (PlayerMovementCollisionHandlerPointerLo)

ResumeAfterPlayerDownwardCollision:
    LDA PlayerMovementState
    CMP #$21
    BCS StartAlignedPlayerJump
    LDA Controller1Buttons
    AND #ControllerButtonA
    BEQ ResetGroundedPlayerMotion
    LDA PlayerXLo
    AND #$07
    BNE PrimePlayerJump
    LDA PlayerGroundCounterA
    CLC
    ADC PlayerGroundCounterB
    CMP #PlayerGroundedCounterSum
    BCS PrimePlayerJump
    LDA PlayerGroundCounterB
    BMI ContinuePlayerHorizontalUpdate
    INC PlayerGroundCounterB
    JMP ContinuePlayerHorizontalUpdate

PrimePlayerJump:
    LDA #PlayerJumpInitialState
    STA PlayerMovementState

StartAlignedPlayerJump:
    LDA PlayerXLo
    AND #$07
    BNE ContinuePlayerHorizontalUpdate
    LDA #PlayerJumpActiveState
    STA PlayerMovementState
    JSR StartPulse1SoundEffect1

ContinuePlayerHorizontalUpdate:
    JMP ApplyPlayerActionMovementLock

ResetGroundedPlayerMotion:
    LDA Controller1Buttons
    AND #PlayerHorizontalInputMask
    BNE ApplyPlayerActionMovementLock
    LDA PlayerXLo
    AND #$07
    BNE ApplyPlayerActionMovementLock
    LDA #$00
    STA PlayerGroundCounterA
    STA PlayerGroundCounterB

ApplyPlayerActionMovementLock:
    LDA MovementPlayerActionCountdown
    BEQ TickPlayerHorizontalDelay
    JSR GetActivePlayerMotionState
    ORA PlayerMovementPhase
    BNE TickPlayerHorizontalDelay
    JMP HandlePlayerActionHit

TickPlayerHorizontalDelay:
    LDA PlayerHorizontalMovementDelay
    BEQ ConsumeForcedPlayerMovement
    DEC PlayerHorizontalMovementDelay
    JMP MovePlayerHorizontally

ConsumeForcedPlayerMovement:
    LDA PlayerForcedMovementLatch
    PHP
    LDA #$00
    STA PlayerForcedMovementLatch
    PLP
    BNE ContinueForcedPlayerMovement
    LDA PlayerMovementDirection
    BEQ ReadPlayerHorizontalInput
    LDA PlayerXLo
    AND #$07
    BNE MovePlayerHorizontally
    LDA #$02
    STA PlayerGroundCounterA
    STA PlayerGroundCounterB
    BNE ReadPlayerHorizontalInput

ContinueForcedPlayerMovement:
    LDA #$02
    STA PlayerGroundCounterA
    STA PlayerGroundCounterB
    LDA PlayerXLo
    AND #$07
    BEQ ReadPlayerHorizontalInput
    JMP HandlePlayerActionHit

ReadPlayerHorizontalInput:
    LDA #$00
    STA PlayerMovementDirection
    LDA Controller1Buttons
    AND #$C0
    BNE DelayPlayerDirectionChange
    JMP HandlePlayerActionHit

DelayPlayerDirectionChange:
    LDA PlayerGroundCounterA
    CLC
    ADC PlayerGroundCounterB
    CMP #$02
    BCS SelectPlayerHorizontalDirection
    LDA PlayerGroundCounterA
    BMI SkipPlayerHorizontalMovement
    INC PlayerGroundCounterA

SkipPlayerHorizontalMovement:
    JMP HandlePlayerActionHit

SelectPlayerHorizontalDirection:
    LDA Controller1Buttons
    AND #PlayerHorizontalInputMask
    BEQ MovePlayerHorizontally
    CMP #$C0
    BEQ MovePlayerHorizontally
    LDX #PlayerDirectionRight
    CMP #$40
    BNE StorePlayerHorizontalDirection
    LDX #PlayerDirectionLeft

StorePlayerHorizontalDirection:
    STX PlayerMovementDirection

MovePlayerHorizontally:
    LDA PlayerMovementDirection
    BNE BuildPlayerHorizontalProbe
    JMP HandlePlayerActionHit

BuildPlayerHorizontalProbe:
    BMI BuildPlayerLeftwardProbe
    LDA PlayerXLo
    CLC
    ADC #PlayerRightCollisionProbeOffset
    STA PlayerHorizontalProbeXLo
    LDA PlayerXHi
    ADC #$00
    STA PlayerHorizontalProbeXHi
    LDA PlayerXLo
    CLC
    ADC #PlayerHorizontalStep
    STA PlayerHorizontalCandidateXLo
    LDA PlayerXHi
    ADC #$00
    STA PlayerHorizontalCandidateXHi
    JMP CheckPlayerHorizontalRoomBoundary

BuildPlayerLeftwardProbe:
    LDA PlayerXLo
    SEC
    SBC #PlayerHorizontalStep
    STA PlayerHorizontalProbeXLo
    STA PlayerHorizontalCandidateXLo
    LDA PlayerXHi
    SBC #$00
    STA PlayerHorizontalProbeXHi
    STA PlayerHorizontalCandidateXHi

CheckPlayerHorizontalRoomBoundary:
    LDA PlayerHorizontalCandidateXHi
    BEQ ProbePlayerHorizontalCollision
    CMP #$01
    BEQ CheckPlayerRightRoomBoundary
    JMP HandleLeftRoomBoundary

CheckPlayerRightRoomBoundary:
    LDA PlayerHorizontalCandidateXLo
    CMP #PlayerRightRoomBoundaryLo
    BCC ProbePlayerHorizontalCollision
    JMP HandleRightRoomBoundary

ProbePlayerHorizontalCollision:
    LDA #$FF
    STA PlayerHorizontalCollisionObjectFilter
    LDA PlayerY
    CLC
    ADC #PlayerHorizontalProbeBottomOffset
    TAY
    STY PlayerHorizontalProbeY
    LDA PlayerHorizontalProbeXHi
    LDX PlayerHorizontalProbeXLo
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerHorizontalCollision
    LDA #$FF
    STA PlayerHorizontalCollisionObjectFilter
    LDA PlayerY
    CLC
    ADC #PlayerHorizontalProbeMiddleOffset
    TAY
    STY PlayerHorizontalProbeY
    LDA PlayerHorizontalProbeXHi
    LDX PlayerHorizontalProbeXLo
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerHorizontalCollision
    LDA #$FF
    STA PlayerHorizontalCollisionObjectFilter
    LDA PlayerHorizontalProbeXHi
    LDX PlayerHorizontalProbeXLo
    LDY PlayerY
    STY PlayerHorizontalProbeY
    JSR SamplePlayerCollisionAtScreenPixel
    BCS DispatchPlayerHorizontalCollision
    LDA PlayerHorizontalCandidateXHi
    STA PlayerXHi
    LDA PlayerHorizontalCandidateXLo
    STA PlayerXLo
    JMP HandlePlayerActionHit

DispatchPlayerHorizontalCollision:
    ASL A
    TAX
    BCS SelectPlayerHorizontalRuntimeHandler
    LDA PlayerHorizontalRoomCellCollisionHandlerPointers,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerHorizontalRoomCellCollisionHandlerPointers + 1,X
    STA PlayerMovementCollisionHandlerPointerHi
    JMP InvokePlayerHorizontalCollisionHandler

SelectPlayerHorizontalRuntimeHandler:
    LDA PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA PlayerMovementCollisionHandlerPointerLo
    LDA PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA PlayerMovementCollisionHandlerPointerHi

InvokePlayerHorizontalCollisionHandler:
    LDA #>(HandlePlayerActionHit - 1)
    PHA
    LDA #<(HandlePlayerActionHit - 1)
    PHA
    JMP (PlayerMovementCollisionHandlerPointerLo)

HandlePlayerActionHit:
    LDA MovementPlayerActionCountdown
    BNE CheckPlayerActionFacingDirection
    JMP RememberPlayerInputAndReturn

CheckPlayerActionFacingDirection:
    LDA PlayerMovementDirection
    BNE BuildPlayerActionProbe
    JMP RememberPlayerInputAndReturn

BuildPlayerActionProbe:
    BMI BuildPlayerLeftActionProbe
    LDA PlayerXLo
    CLC
    ADC #PlayerActionRightProbeOffset
    STA PlayerActionProbeXLo
    LDA PlayerXHi
    ADC #$00
    STA PlayerActionProbeXHi
    LDA PlayerActionProbeXLo
    CMP #PlayerActionRightBoundaryLo
    LDA PlayerActionProbeXHi
    SBC #PlayerActionRightBoundaryHi
    BCC ScanPlayerActionObjects
    JMP RememberPlayerInputAndReturn

BuildPlayerLeftActionProbe:
    LDA PlayerXLo
    SEC
    SBC #PlayerActionLeftProbeOffset
    STA PlayerActionProbeXLo
    LDA PlayerXHi
    SBC #$00
    STA PlayerActionProbeXHi
    BMI RememberPlayerInputAndReturn

ScanPlayerActionObjects:
    LDA PlayerY
    SEC
    SBC #PlayerActionProbeYOffset
    STA PlayerActionScratch
    LDX #$00

TestNextPlayerActionObject:
    LDA RuntimeObjectRecords,X
    BPL AdvancePlayerActionObjectScan
    CMP #RuntimeObjectPersistentTypeEnd
    BCS AdvancePlayerActionObjectScan
    TAY
    LDA PlayerActionScratch
    SEC
    SBC RuntimeObjectY,X
    BCC AdvancePlayerActionObjectScan
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvancePlayerActionObjectScan
    LDA PlayerActionProbeXLo
    STA PlayerActionDeltaXLo
    LDA PlayerActionProbeXHi
    STA PlayerActionDeltaXHi
    LDA PlayerActionDeltaXLo
    SEC
    SBC RuntimeObjectXLo,X
    STA PlayerActionDeltaXLo
    LDA PlayerActionDeltaXHi
    SBC RuntimeObjectXHi,X
    BCC AdvancePlayerActionObjectScan
    STA PlayerActionDeltaXHi
    LDA PlayerActionDeltaXLo
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    BCS AdvancePlayerActionObjectScan
    LDA PlayerActionDeltaXHi
    BNE AdvancePlayerActionObjectScan
    LDA RuntimeObjectRecords,X
    CMP #RuntimeTypeEnemyBishop
    BEQ RememberPlayerInputAndReturn
    CMP #RuntimeTypeEnemyFlame
    BEQ RememberPlayerInputAndReturn
    CMP #RuntimeTypeEnemyDevilFlower
    BEQ RememberPlayerInputAndReturn
    STX PlayerActionScratch
    TYA
    JSR GetEnemyTypeFilter
    BNE RememberPlayerInputAndReturn
    LDA #PlayerDestroyedRuntimeType
    LDX PlayerActionScratch
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JSR StartPulse2NoiseSoundEffect2
    JMP RememberPlayerInputAndReturn

AdvancePlayerActionObjectScan:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC TestNextPlayerActionObject

RememberPlayerInputAndReturn:
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS
