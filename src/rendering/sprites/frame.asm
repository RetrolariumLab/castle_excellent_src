; Frame sprite construction
; CPU range $AC13-$ADE6
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

BuildFrameSprites:
    LDA #$FF
    STA OamStagingBusy
    LDX #$00
    LDA #OamHiddenY

ClearOamStagingBuffer:
    STA OamStagingBuffer,X
    INX
    BNE ClearOamStagingBuffer
    JSR DrawPlayerSprite
    JSR DrawPlayerActionSprite
    LDX #FirstObjectOamStagingOffset
    STX OamStagingWriteOffset
    LDY #$00
    STY CurrentObjectOffset

DispatchNextObjectSprite:
    LDY CurrentObjectOffset
    LDA a:RuntimeObjectY,Y
    CMP #RuntimeObjectVisibleYLimit
    BCS AdvanceFrameSpriteObject
    LDA a:RuntimeObjectRecords,Y
    BEQ AdvanceFrameSpriteObject
    AND #RuntimeObjectTypeIndexMask
    ASL A
    TAY
    LDA ObjectSpriteHandlerPointers,Y
    STA ObjectSpriteHandlerPointerLo
    LDA ObjectSpriteHandlerPointers + 1,Y
    STA ObjectSpriteHandlerPointerHi
    LDX CurrentObjectOffset
    JMP (ObjectSpriteHandlerPointerLo)

AdvanceFrameSpriteObject:
    LDA CurrentObjectOffset
    CLC
    ADC #RuntimeObjectRecordSize
    STA CurrentObjectOffset
    CMP #RuntimeObjectRecordBytes
    BCC DispatchNextObjectSprite
    LDA #$00
    STA OamStagingBusy
    RTS

DrawPlayerSprite:
    LDA PlayerTransitionCountdown
    BEQ SelectPlayerNormalSprite
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectPlayerTransitionFrame1OrLater
    LDX #>PlayerTransitionMetasprite0
    LDY #<PlayerTransitionMetasprite0
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerTransitionFrame1OrLater:
    CMP #$01
    BNE SelectPlayerTransitionFrame2Or3
    LDX #>PlayerTransitionMetasprite1
    LDY #<PlayerTransitionMetasprite1
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerTransitionFrame2Or3:
    CMP #$02
    BNE DrawPlayerTransitionFrame3
    LDX #>PlayerTransitionMetasprite2
    LDY #<PlayerTransitionMetasprite2
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

DrawPlayerTransitionFrame3:
    LDX #>PlayerTransitionMetasprite3
    LDY #<PlayerTransitionMetasprite3
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerNormalSprite:
    LDA PlayerSpriteDirection
    BNE SelectPlayerDirectionalSprite
    LDA PlayerSpriteMotionState
    ORA PlayerSpriteMotionPhase
    BNE DrawPlayerNeutralMotionSprite
    LDX #>PlayerNeutralMetasprite
    LDY #<PlayerNeutralMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

DrawPlayerNeutralMotionSprite:
    LDX #>PlayerNeutralMotionMetasprite
    LDY #<PlayerNeutralMotionMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerDirectionalSprite:
    BMI SelectPlayerLeftSprite
    LDA PlayerSpriteMotionState
    ORA PlayerSpriteMotionPhase
    BEQ SelectPlayerRightActionSprite
    LDX #>PlayerRightMotionMetasprite
    LDY #<PlayerRightMotionMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerRightActionSprite:
    LDA PlayerActionCountdown
    BEQ SelectPlayerRightWalkSprite
    LDX #>PlayerRightActionMetasprite
    LDY #<PlayerRightActionMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerRightWalkSprite:
    LDA FrameCounter
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE SelectPlayerRightWalkFrame2Or3
    LDX #>PlayerRightWalkMetasprite0
    LDY #<PlayerRightWalkMetasprite0
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerRightWalkFrame2Or3:
    CMP #$02
    BNE DrawPlayerRightWalkMiddleFrame
    LDX #>PlayerRightWalkMetasprite2
    LDY #<PlayerRightWalkMetasprite2
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

DrawPlayerRightWalkMiddleFrame:
    LDX #>PlayerRightWalkMetaspriteMiddle
    LDY #<PlayerRightWalkMetaspriteMiddle
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerLeftSprite:
    LDA PlayerSpriteMotionState
    ORA PlayerSpriteMotionPhase
    BEQ SelectPlayerLeftActionSprite
    LDX #>PlayerLeftMotionMetasprite
    LDY #<PlayerLeftMotionMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerLeftActionSprite:
    LDA PlayerActionCountdown
    BEQ SelectPlayerLeftWalkSprite
    LDX #>PlayerLeftActionMetasprite
    LDY #<PlayerLeftActionMetasprite
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerLeftWalkSprite:
    LDA FrameCounter
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE SelectPlayerLeftWalkFrame2Or3
    LDX #>PlayerLeftWalkMetasprite0
    LDY #<PlayerLeftWalkMetasprite0
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

SelectPlayerLeftWalkFrame2Or3:
    CMP #$02
    BNE DrawPlayerLeftWalkMiddleFrame
    LDX #>PlayerLeftWalkMetasprite2
    LDY #<PlayerLeftWalkMetasprite2
    JSR DrawPlayerMetasprite
    JMP FinishPlayerSprite

DrawPlayerLeftWalkMiddleFrame:
    LDX #>PlayerLeftWalkMetaspriteMiddle
    LDY #<PlayerLeftWalkMetaspriteMiddle
    JSR DrawPlayerMetasprite

FinishPlayerSprite:
    LDA #$00
    STA PlayerSpriteMotionPhase
    RTS

DrawPlayerActionSprite:
    LDA PlayerActionCountdown
    BNE CheckPlayerActionDirection
    RTS

CheckPlayerActionDirection:
    LDA PlayerSpriteDirection
    BNE DrawPlayerActionSpriteByDirection
    RTS

DrawPlayerActionSpriteByDirection:
    BMI DrawPlayerLeftActionSprite
    LDA OamStagingBuffer
    STA OamStagingBuffer + $08
    LDA OamStagingBuffer + $03
    CLC
    ADC #$0F
    STA OamStagingBuffer + $0B
    LDA #PlayerActionSpriteTile
    STA OamStagingBuffer + $09
    LDA #PlayerRightActionSpriteAttributes
    STA OamStagingBuffer + $0A
    RTS

DrawPlayerLeftActionSprite:
    LDA OamStagingBuffer
    STA OamStagingBuffer + $08
    LDA OamStagingBuffer + $03
    SEC
    SBC #$07
    STA OamStagingBuffer + $0B
    LDA #PlayerActionSpriteTile
    STA OamStagingBuffer + $09
    LDA #PlayerLeftActionSpriteAttributes

ObjectSpriteHandlerPointers = * + 2  ; overlapping entry $AD93
    STA OamStagingBuffer + $0A
    RTS
; Entries for types $81-$A9; entry 0 overlaps the STA operand above and is never used
    .addr DrawFairySprite  ; $81 Fairy
    .addr DrawPrincessSprite  ; $82 Princess
    .addr DrawOxygenTankSprite  ; $83 ItemOxygenTank
    .addr DrawFighterSprite  ; $84 EnemyFighter
    .addr DrawBishopSprite  ; $85 EnemyBishop
    .addr DrawDevilFlowerSprite  ; $86 EnemyDevilFlower
    .addr DrawKnightSprite  ; $87 EnemyKnight
    .addr DrawWitchSprite  ; $88 EnemyWitch
    .addr DrawFlameSprite  ; $89 EnemyFlame
    .addr DrawJarSprite  ; $8A ObjectJar
    .addr DrawBrickSprite  ; $8B ObjectBrick
    .addr DrawBlockSprite  ; $8C ObjectBlock
    .addr DrawBarrelSprite  ; $8D ObjectBarrel
    .addr DrawPulleySprite  ; $8E ObjectPulley
    .addr DrawCandleSprite  ; $8F ObjectCandle
    .addr DrawDarkBlueKeySprite  ; $90 ItemDarkBlueKey
    .addr DrawRedKeySprite  ; $91 ItemRedKey
    .addr DrawPinkKeySprite  ; $92 ItemPinkKey
    .addr DrawGreenKeySprite  ; $93 ItemGreenKey
    .addr DrawBlueKeySprite  ; $94 ItemBlueKey
    .addr DrawYellowKeySprite  ; $95 ItemYellowKey
    .addr DrawCastleMapSprite  ; $96 ItemCastleMap
    .addr DrawPotionSprite  ; $97 ItemPotion
    .addr DrawCrossSprite  ; $98 ItemCross
    .addr DrawRingSprite  ; $99 ItemRing
    .addr DrawMoneyBagSprite  ; $9A ItemMoneyBag
    .addr DrawRuntimeObjectType27Sprite  ; $9B
    .addr DrawRuntimeObjectType28Sprite  ; $9C
    .addr DrawRuntimeObjectType29Or30Sprite  ; $9D
    .addr DrawRuntimeObjectType29Or30Sprite  ; $9E
    .addr DrawPowerLightSprite  ; $9F ItemPowerLight
    .addr DrawWitchSummonSprite  ; $A0 WitchSummon
    .addr DrawLiftSprite  ; $A1 ObjectLift
    .addr DrawWideLiftSprite  ; $A2 ObjectLiftWide
    .addr DrawFloatingPlatformSprite  ; $A3 ObjectFloatingPlatform
    .addr DrawDraggableLiftTopSprite  ; $A4 ObjectDraggableLiftTop
    .addr DrawDraggableLiftBottomSprite  ; $A5 ObjectDraggableLiftBottom
    .addr DrawKnightArrowSprite  ; $A6 ObjectKnightArrow
    .addr DrawRuntimeObjectType39Sprite  ; $A7
    .addr DrawDefeatEffectSprite  ; $A8 EffectDefeat
    .addr DrawCollectedItemEffectSprite  ; $A9 EffectCollectedItem
