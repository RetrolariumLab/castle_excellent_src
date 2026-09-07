; Collectible collision, inventory, and rewards
; CPU range $8C12-$8DAA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CollectInventoryRuntimeType90:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $01
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType91:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType92:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $04
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType93:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $03
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType94:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $05
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType95:
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

CollectRuntimeType83:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType83Collectible
    RTS

ApplyRuntimeType83Collectible:
    INC RuntimeType83ScreenState
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA CollectibleHazardProtectionCountdown
    BNE SetRuntimeType83Protection
    JSR LoadAudioTrackSet1

SetRuntimeType83Protection:
    LDA #RuntimeType83ProtectionDuration
    STA CollectibleHazardProtectionCountdown
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectRuntimeType96:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType96Collectible
    RTS

ApplyRuntimeType96Collectible:
    LDA #RuntimeType96EffectSet
    STA RuntimeType96EffectLatch
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectRuntimeType98:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType98Collectible
    RTS

ApplyRuntimeType98Collectible:
    LDA #CollectibleScore20
    JSR AddPlayerScore
    LDA #CollectedObjectState6
    JMP TransformCollectedRuntimeObject

CollectRuntimeType99:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType99Collectible
    RTS

ApplyRuntimeType99Collectible:
    LDA #CollectibleScore40
    JSR AddPlayerScore
    LDA #CollectedObjectState7
    JMP TransformCollectedRuntimeObject

CollectRuntimeType9A:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType9ACollectible
    RTS

ApplyRuntimeType9ACollectible:
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

CollectRuntimeType97:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType97Collectible
    RTS

ApplyRuntimeType97Collectible:
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

HandleRuntimeType9FPlayerCollision:
    LDA RoomFrameCounter
    BPL ReturnFromRuntimeType9FCollision
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    BEQ CheckRuntimeType9FAudio

ReturnFromRuntimeType9FXMismatch:
    RTS

CheckRuntimeType9FAudio:
    LDA RuntimeType9FInvulnerabilityCountdown
    BNE RefreshRuntimeType9FInvulnerability
    JSR LoadAudioTrackSet3

RefreshRuntimeType9FInvulnerability:
    LDA #RuntimeType9FInvulnerabilityDuration
    STA RuntimeType9FInvulnerabilityCountdown

ReturnFromRuntimeType9FCollision:
    RTS

HandleRuntimeType82PlayerCollision:
    LDA GameOverActive
    BNE ReturnFromRuntimeType81Or82Collision

CheckRuntimeType82PlayerProximity:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromRuntimeType81Or82Collision
    JSR LoadAudioTrackSet4

WaitForRuntimeType82Audio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForRuntimeType82Audio

ExitCollisionDispatchForRuntimeType82:
    PLA
    PLA
    JMP RunType82CompletionSequence

ReturnFromRuntimeType81Or82Collision:
    RTS

HandleRuntimeType81PlayerCollision:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromRuntimeType81Or82Collision
    JSR LoadAudioTrackSet7

WaitForRuntimeType81Audio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForRuntimeType81Audio

TransformRuntimeType81Object:
    LDX CurrentObjectOffset
    LDA #RuntimeType81ReplacementType
    STA RuntimeObjectRecords,X
    LDA RuntimeObjectXLo,X
    SEC
    SBC #RuntimeType81HorizontalShift
    STA RuntimeObjectXLo,X
    BCS CheckRuntimeType81CloneRoom
    DEC RuntimeObjectXHi,X

CheckRuntimeType81CloneRoom:
    LDA CurrentRoomNumber
    CMP #RuntimeType81CloneRoom
    BNE ReturnFromRuntimeType81Collision

SpawnRuntimeType81Clone:
    LDA #RuntimeType81ReplacementType
    STA RuntimeType81CloneType
    LDA RuntimeObjectXLo,X
    SEC
    SBC #RuntimeType81HorizontalShift
    STA RuntimeType81CloneXLo
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA RuntimeType81CloneXHi
    LDA RuntimeObjectY,X
    STA RuntimeType81CloneY

ReturnFromRuntimeType81Collision:
    RTS
