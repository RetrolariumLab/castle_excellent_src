; Collectible collision, inventory, and rewards
; CPU range $8C12-$8DAA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CollectDarkBlueKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $01
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectRedKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectPinkKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $04
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectGreenKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $03
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectBlueKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $05
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectYellowKey:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $02
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore

FinalizeInventoryCollectible:
    JSR StartInventoryCollectibleSoundEffect
    LDA #CollectedObjectState5

TransformCollectedRuntimeObject:
    LDX CurrentObjectOffset
    STA RuntimeObjectState,X
    LDA #CollectedObjectRuntimeType
    STA RuntimeObjectRecords,X
    LDA #CollectedObjectLifetime
    STA RuntimeObjectCollectedLifetime,X

ReturnFromInventoryCollectible:
    RTS

UnreferencedRuntimeObjectClearTailBytes:
    .byte $A6, $41, $4C, $24, $A0

CollectOxygenTank:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyOxygenTankCollectible
    RTS

ApplyOxygenTankCollectible:
    INC OxygenTankScreenState
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA CollectibleHazardProtectionCountdown
    BNE SetOxygenTankProtection
    JSR LoadAudioTrackSet1

SetOxygenTankProtection:
    LDA #OxygenTankProtectionDuration
    STA CollectibleHazardProtectionCountdown
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectCastleMap:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyCastleMapCollectible
    RTS

ApplyCastleMapCollectible:
    LDA #CastleMapAvailableValue
    STA CastleMapAvailable
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectCross:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyCrossCollectible
    RTS

ApplyCrossCollectible:
    LDA #CollectibleScore20
    JSR AddPlayerScore
    LDA #CollectedObjectState6
    JMP TransformCollectedRuntimeObject

CollectRing:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRingCollectible
    RTS

ApplyRingCollectible:
    LDA #CollectibleScore40
    JSR AddPlayerScore
    LDA #CollectedObjectState7
    JMP TransformCollectedRuntimeObject

CollectMoneyBag:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyMoneyBagCollectible
    RTS

ApplyMoneyBagCollectible:
    LDA #CollectibleScore80
    JSR AddPlayerScore
    LDA #CollectedObjectState8
    JMP TransformCollectedRuntimeObject

CollectRuntimeType9B:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType9BCollectible
    RTS

ApplyRuntimeType9BCollectible:
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectPotion:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyPotionCollectible
    RTS

ApplyPotionCollectible:
    LDA #CollectibleScore100
    JSR AddPlayerScore
    INC PlayerLives
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

AddPlayerScore:
    PHA
    LDA DemoPlaybackActive
    BNE DiscardDemoScoreAward
    JSR ComputePlayerScoreThousands
    LDY ScoreThousandsQuotient
    PLA
    CLC
    ADC AwardPlayerScoreLo
    STA AwardPlayerScoreLo
    BCC CompareScoreLifeThreshold
    INC AwardPlayerScoreHi

CompareScoreLifeThreshold:
    JSR ComputePlayerScoreThousands
    TYA
    EOR ScoreThousandsQuotient
    BEQ ReturnFromAddPlayerScore
    INC PlayerLives
    BNE ReturnFromAddPlayerScore
    DEC PlayerLives

ReturnFromAddPlayerScore:
    RTS

DiscardDemoScoreAward:
    PLA
    RTS

ComputePlayerScoreThousands:
    LDA AwardPlayerScoreLo
    STA ScoreDivisionDividendLo
    LDA AwardPlayerScoreHi
    STA ScoreDivisionDividendHi
    LDA #ScoreLifeThresholdHi
    STA ScoreDivisionDivisorHi
    LDA #ScoreLifeThresholdLo
    STA ScoreDivisionDivisorLo
    JMP DivideUnsigned16

HandlePowerLightPlayerCollision:
    LDA RoomFrameCounter
    BPL ReturnFromPowerLightCollision
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    BEQ CheckPowerLightAudio

ReturnFromPowerLightXMismatch:
    RTS

CheckPowerLightAudio:
    LDA PowerLightInvulnerabilityCountdown
    BNE RefreshPowerLightInvulnerability
    JSR LoadAudioTrackSet3

RefreshPowerLightInvulnerability:
    LDA #PowerLightInvulnerabilityDuration
    STA PowerLightInvulnerabilityCountdown

ReturnFromPowerLightCollision:
    RTS

HandlePrincessPlayerCollision:
    LDA GameOverActive
    BNE ReturnFromFairyOrPrincessCollision

CheckPrincessPlayerProximity:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromFairyOrPrincessCollision
    JSR LoadAudioTrackSet4

WaitForPrincessAudio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForPrincessAudio

ExitCollisionDispatchForPrincess:
    PLA
    PLA
    JMP RunType82CompletionSequence

ReturnFromFairyOrPrincessCollision:
    RTS

HandleFairyPlayerCollision:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromFairyOrPrincessCollision
    JSR LoadAudioTrackSet7

WaitForFairyAudio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForFairyAudio

TransformFairyObject:
    LDX CurrentObjectOffset
    LDA #FairyReplacementType
    STA RuntimeObjectRecords,X
    LDA RuntimeObjectXLo,X
    SEC
    SBC #FairyHorizontalShift
    STA RuntimeObjectXLo,X
    BCS CheckFairyCloneRoom
    DEC RuntimeObjectXHi,X

CheckFairyCloneRoom:
    LDA CurrentRoomNumber
    CMP #FairyCloneRoom
    BNE ReturnFromFairyCollision

SpawnFairyClone:
    LDA #FairyReplacementType
    STA FairyCloneType
    LDA RuntimeObjectXLo,X
    SEC
    SBC #FairyHorizontalShift
    STA FairyCloneXLo
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA FairyCloneXHi
    LDA RuntimeObjectY,X
    STA FairyCloneY

ReturnFromFairyCollision:
    RTS
