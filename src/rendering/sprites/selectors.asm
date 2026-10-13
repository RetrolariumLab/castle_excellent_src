; Object sprite selectors
; CPU range $ADE7-$B1D5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DrawFairySprite:
    LDA RoomFrameCounter
    LSR A
    AND #$03
    BNE SelectType01Frame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $9E)
    LDY #<(ObjectSpriteFrameRecords + $9E)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType01Frame2OrMiddle:
    CMP #$02
    BNE DrawType01MiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $A6)
    LDY #<(ObjectSpriteFrameRecords + $A6)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType01MiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $A2)
    LDY #<(ObjectSpriteFrameRecords + $A2)
    JMP DrawTwoObjectSpritesAndAdvance

DrawPrincessSprite:
    LDX #>(ObjectSpriteFrameRecords + $B6)
    LDY #<(ObjectSpriteFrameRecords + $B6)

DrawTwoObjectSpritesAndAdvance:
    JSR DrawTwoObjectSprites
    JMP AdvanceFrameSpriteObject

DrawOxygenTankSprite:
    LDX #>(ObjectSpriteFrameRecords + $C6)
    LDY #<(ObjectSpriteFrameRecords + $C6)
    JMP DrawTwoObjectSpritesAndAdvance

DrawFighterSprite:
    LDA RuntimeObjectState,X
    BMI SelectType04NegativeStateSprite
    LDA RuntimeObjectFighterJumpCountdown,X
    BEQ SelectType04PositiveStateAnimation
    LDX #>(ObjectSpriteFrameRecords + $18)
    LDY #<(ObjectSpriteFrameRecords + $18)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04PositiveStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType04PositiveFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords)
    LDY #<(ObjectSpriteFrameRecords)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType04PositiveMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $08)
    LDY #<(ObjectSpriteFrameRecords + $08)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType04PositiveMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $04)
    LDY #<(ObjectSpriteFrameRecords + $04)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeStateSprite:
    LDA RuntimeObjectFighterJumpCountdown,X
    BEQ SelectType04NegativeStateAnimation
    LDX #>(ObjectSpriteFrameRecords + $1C)
    LDY #<(ObjectSpriteFrameRecords + $1C)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType04NegativeFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $0C)
    LDY #<(ObjectSpriteFrameRecords + $0C)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType04NegativeMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $14)
    LDY #<(ObjectSpriteFrameRecords + $14)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType04NegativeMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $10)
    LDY #<(ObjectSpriteFrameRecords + $10)
    JMP DrawTwoObjectSpritesAndAdvance

DrawBishopSprite:
    LDA RuntimeObjectState,X
    BMI SelectType05NegativeStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType05PositiveFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $20)
    LDY #<(ObjectSpriteFrameRecords + $20)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType05PositiveMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $28)
    LDY #<(ObjectSpriteFrameRecords + $28)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType05PositiveMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $24)
    LDY #<(ObjectSpriteFrameRecords + $24)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType05NegativeFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $2C)
    LDY #<(ObjectSpriteFrameRecords + $2C)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType05NegativeMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $34)
    LDY #<(ObjectSpriteFrameRecords + $34)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType05NegativeMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $30)
    LDY #<(ObjectSpriteFrameRecords + $30)
    JMP DrawTwoObjectSpritesAndAdvance

DrawDevilFlowerSprite:
    LDA RoomFrameCounter
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #$08
    BCS SelectType06LateRoomPhase
    LDA RuntimeObjectXLo,X
    ORA #$04
    STA RuntimeObjectXLo,X
    LDX #>(ObjectSpriteFrameRecords + $38)
    LDY #<(ObjectSpriteFrameRecords + $38)
    JSR DrawOneObjectSprite
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    AND #$F8
    STA RuntimeObjectXLo,X
    JMP AdvanceFrameSpriteObject

SelectType06LateRoomPhase:
    CMP #$08
    BEQ DrawType06OuterTransitionFrame
    CMP #$0F
    BNE SelectType06InnerTransitionFrame

DrawType06OuterTransitionFrame:
    LDX #>(ObjectSpriteFrameRecords + $3A)
    LDY #<(ObjectSpriteFrameRecords + $3A)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06InnerTransitionFrame:
    CMP #$09
    BEQ DrawType06InnerTransitionFrame
    CMP #$0E
    BNE SelectType06CycleFrame

DrawType06InnerTransitionFrame:
    LDX #>(ObjectSpriteFrameRecords + $3E)
    LDY #<(ObjectSpriteFrameRecords + $3E)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06CycleFrame:
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType06AlternatingFrame
    LDX #>(ObjectSpriteFrameRecords + $42)
    LDY #<(ObjectSpriteFrameRecords + $42)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06AlternatingFrame:
    AND #$01
    BEQ DrawType06EvenCycleFrame
    LDX #>(ObjectSpriteFrameRecords + $46)
    LDY #<(ObjectSpriteFrameRecords + $46)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType06EvenCycleFrame:
    LDX #>(ObjectSpriteFrameRecords + $4A)
    LDY #<(ObjectSpriteFrameRecords + $4A)
    JMP DrawTwoObjectSpritesAndAdvance

DrawKnightSprite:
    LDA RuntimeObjectState,X
    BMI SelectType07NegativeStateAnimation
    LDA FrameCounter
    CLC
    ADC RuntimeObjectKnightArrowCooldown,X
    LSR A
    LSR A
    AND #$03
    BNE SelectType07PositiveFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $4E)
    LDY #<(ObjectSpriteFrameRecords + $4E)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType07PositiveMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $56)
    LDY #<(ObjectSpriteFrameRecords + $56)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType07PositiveMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $52)
    LDY #<(ObjectSpriteFrameRecords + $52)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07NegativeStateAnimation:
    LDA FrameCounter
    CLC
    ADC RuntimeObjectKnightArrowCooldown,X
    LSR A
    LSR A
    AND #$03
    BNE SelectType07NegativeFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $5A)
    LDY #<(ObjectSpriteFrameRecords + $5A)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType07NegativeMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $62)
    LDY #<(ObjectSpriteFrameRecords + $62)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType07NegativeMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $5E)
    LDY #<(ObjectSpriteFrameRecords + $5E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawWitchSprite:
    LDA RuntimeObjectState,X
    BMI SelectType08NegativeStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType08PositiveFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $66)
    LDY #<(ObjectSpriteFrameRecords + $66)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType08PositiveMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $6E)
    LDY #<(ObjectSpriteFrameRecords + $6E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType08PositiveMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $6A)
    LDY #<(ObjectSpriteFrameRecords + $6A)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType08NegativeFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $76)
    LDY #<(ObjectSpriteFrameRecords + $76)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType08NegativeMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $7E)
    LDY #<(ObjectSpriteFrameRecords + $7E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType08NegativeMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $7A)
    LDY #<(ObjectSpriteFrameRecords + $7A)
    JMP DrawTwoObjectSpritesAndAdvance

DrawFlameSprite:
    LDA RuntimeObjectState,X
    BPL SelectType09PositiveStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE DrawType09NegativeNonzeroFrame
    LDX #>(ObjectSpriteFrameRecords + $92)
    LDY #<(ObjectSpriteFrameRecords + $92)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType09NegativeNonzeroFrame:
    CMP #$02
    LDX #>(ObjectSpriteFrameRecords + $9A)
    LDY #<(ObjectSpriteFrameRecords + $9A)
    JMP DrawTwoObjectSpritesAndAdvance

UnreferencedType09FrameSelectionBytes:
    .byte $A2, $B5, $A0, $8C, $4C, $0C, $AE

SelectType09PositiveStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType09PositiveFrame2OrMiddle
    LDX #>(ObjectSpriteFrameRecords + $86)
    LDY #<(ObjectSpriteFrameRecords + $86)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType09PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType09PositiveMiddleFrame
    LDX #>(ObjectSpriteFrameRecords + $8E)
    LDY #<(ObjectSpriteFrameRecords + $8E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType09PositiveMiddleFrame:
    LDX #>(ObjectSpriteFrameRecords + $8A)
    LDY #<(ObjectSpriteFrameRecords + $8A)
    JMP DrawTwoObjectSpritesAndAdvance

DrawJarSprite:
    LDX #>(ObjectSpriteFrameRecords + $CA)
    LDY #<(ObjectSpriteFrameRecords + $CA)
    JMP DrawTwoObjectSpritesAndAdvance

DrawBrickSprite:
    LDX #>(ObjectSpriteFrameRecords + $CE)
    LDY #<(ObjectSpriteFrameRecords + $CE)
    JMP DrawTwoObjectSpritesAndAdvance

DrawBlockSprite:
    LDX #>(ObjectSpriteFrameRecords + $D2)
    LDY #<(ObjectSpriteFrameRecords + $D2)
    JMP DrawTwoObjectSpritesAndAdvance

DrawBarrelSprite:
    LDX #>(ObjectSpriteFrameRecords + $D6)
    LDY #<(ObjectSpriteFrameRecords + $D6)
    JMP DrawTwoObjectSpritesAndAdvance

DrawPulleySprite:
    LDX #>(ObjectSpriteFrameRecords + $DA)
    LDY #<(ObjectSpriteFrameRecords + $DA)
    JMP DrawTwoObjectSpritesAndAdvance

DrawCandleSprite:
    LDA FrameCounter
    AND #$08
    BNE DrawType15AlternateFrame
    LDX #>(ObjectSpriteFrameRecords + $DE)
    LDY #<(ObjectSpriteFrameRecords + $DE)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType15AlternateFrame:
    LDX #>(ObjectSpriteFrameRecords + $E2)
    LDY #<(ObjectSpriteFrameRecords + $E2)
    JMP DrawTwoObjectSpritesAndAdvance

DrawDarkBlueKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $BA)
    LDY #<(ObjectSpriteFrameRecords + $BA)

DrawOneObjectSpriteAndAdvance:
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

DrawRedKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $BC)
    LDY #<(ObjectSpriteFrameRecords + $BC)
    JMP DrawOneObjectSpriteAndAdvance

DrawPinkKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $BE)
    LDY #<(ObjectSpriteFrameRecords + $BE)
    JMP DrawOneObjectSpriteAndAdvance

DrawGreenKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $C0)
    LDY #<(ObjectSpriteFrameRecords + $C0)
    JMP DrawOneObjectSpriteAndAdvance

DrawBlueKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $C2)
    LDY #<(ObjectSpriteFrameRecords + $C2)
    JMP DrawOneObjectSpriteAndAdvance

DrawYellowKeySprite:
    LDX #>(ObjectSpriteFrameRecords + $C4)
    LDY #<(ObjectSpriteFrameRecords + $C4)
    JMP DrawOneObjectSpriteAndAdvance

DrawCastleMapSprite:
    LDX #>(ObjectSpriteFrameRecords + $E6)
    LDY #<(ObjectSpriteFrameRecords + $E6)
    JMP DrawTwoObjectSpritesAndAdvance

DrawPotionSprite:
    LDX #>(ObjectSpriteFrameRecords + $EA)
    LDY #<(ObjectSpriteFrameRecords + $EA)
    JMP DrawTwoObjectSpritesAndAdvance

DrawCrossSprite:
    LDX #>(ObjectSpriteFrameRecords + $EE)
    LDY #<(ObjectSpriteFrameRecords + $EE)
    JMP DrawTwoObjectSpritesAndAdvance

DrawRingSprite:
    LDX #>(ObjectSpriteFrameRecords + $F2)
    LDY #<(ObjectSpriteFrameRecords + $F2)
    JMP DrawTwoObjectSpritesAndAdvance

DrawMoneyBagSprite:
    LDX #>(ObjectSpriteFrameRecords + $F6)
    LDY #<(ObjectSpriteFrameRecords + $F6)
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType27Sprite:
    LDX #>(ObjectSpriteFrameRecords + $FA)
    LDY #<(ObjectSpriteFrameRecords + $FA)
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType28Sprite:
    LDX #>(ObjectSpriteFrameRecords + $FE)
    LDY #<(ObjectSpriteFrameRecords + $FE)
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType29Or30Sprite:
    LDX #>(ObjectSpriteFrameRecords + $106)
    LDY #<(ObjectSpriteFrameRecords + $106)
    JMP DrawTwoObjectSpritesAndAdvance

DrawPowerLightSprite:
    LDA RoomFrameCounter
    BMI SelectType31RoomFrameParity
    JMP AdvanceFrameSpriteObject

SelectType31RoomFrameParity:
    LDA RoomFrameCounter
    LSR A
    BCC DrawType31EvenRoomFrame
    LDX #>(ObjectSpriteFrameRecords + $112)
    LDY #<(ObjectSpriteFrameRecords + $112)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType31EvenRoomFrame:
    LDX #>(ObjectSpriteFrameRecords + $116)
    LDY #<(ObjectSpriteFrameRecords + $116)
    JMP DrawTwoObjectSpritesAndAdvance

DrawWitchSummonSprite:
    LDX FrameCounterModulo3A
    BNE SelectWitchSummonModulo3Frame1Or2
    LDX #>(ObjectSpriteFrameRecords + $106)
    LDY #<(ObjectSpriteFrameRecords + $106)
    JMP DrawTwoObjectSpritesAndAdvance

SelectWitchSummonModulo3Frame1Or2:
    DEX
    BNE DrawWitchSummonModulo3Frame2
    LDX #>(ObjectSpriteFrameRecords + $10A)
    LDY #<(ObjectSpriteFrameRecords + $10A)
    JMP DrawTwoObjectSpritesAndAdvance

DrawWitchSummonModulo3Frame2:
    LDX #>(ObjectSpriteFrameRecords + $10E)
    LDY #<(ObjectSpriteFrameRecords + $10E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawLiftSprite:
    LDX #>(ObjectSpriteFrameRecords + $122)
    LDY #<(ObjectSpriteFrameRecords + $122)
    JMP DrawTwoObjectSpritesAndAdvance

DrawWideLiftSprite:
    LDX #>(ObjectSpriteFrameRecords + $11A)
    LDY #<(ObjectSpriteFrameRecords + $11A)
    JSR DrawFourObjectSprites
    JMP AdvanceFrameSpriteObject

DrawFloatingPlatformSprite:
    LDX #>(ObjectSpriteFrameRecords + $12A)
    LDY #<(ObjectSpriteFrameRecords + $12A)
    JMP DrawTwoObjectSpritesAndAdvance

DrawDraggableLiftTopSprite:
    LDX #>(ObjectSpriteFrameRecords + $12E)
    LDY #<(ObjectSpriteFrameRecords + $12E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawDraggableLiftBottomSprite:
    LDX #>(ObjectSpriteFrameRecords + $132)
    LDY #<(ObjectSpriteFrameRecords + $132)
    JMP DrawTwoObjectSpritesAndAdvance

DrawKnightArrowSprite:
    LDA RuntimeObjectY,X
    SEC
    SBC #$0B
    STA RuntimeObjectY,X
    LDA RuntimeObjectState,X
    BMI DrawType38NegativeStateSprite
    LDX #>(ObjectSpriteFrameRecords + $138)
    LDY #<(ObjectSpriteFrameRecords + $138)
    JSR DrawOneObjectSprite
    JMP RestoreType38ObjectY

DrawType38NegativeStateSprite:
    LDX #>(ObjectSpriteFrameRecords + $136)
    LDY #<(ObjectSpriteFrameRecords + $136)
    JSR DrawOneObjectSprite

RestoreType38ObjectY:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0B
    STA RuntimeObjectY,X

DrawRuntimeObjectType39Sprite:
    JMP AdvanceFrameSpriteObject

DrawDefeatEffectSprite:
    LDA RuntimeObjectState,X
    LSR A
    BNE SelectType40StatePair1OrLater
    LDX #>(ObjectSpriteFrameRecords + $13A)
    LDY #<(ObjectSpriteFrameRecords + $13A)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType40StatePair1OrLater:
    CMP #$01
    BNE DrawType40LaterStateFrame
    LDX #>(ObjectSpriteFrameRecords + $13E)
    LDY #<(ObjectSpriteFrameRecords + $13E)
    JMP DrawTwoObjectSpritesAndAdvance

DrawType40LaterStateFrame:
    LDX #>(ObjectSpriteFrameRecords + $142)
    LDY #<(ObjectSpriteFrameRecords + $142)
    JMP DrawTwoObjectSpritesAndAdvance

DrawCollectedItemEffectSprite:
    LDA RuntimeObjectState,X
    CMP #$01
    BNE SelectType41State2
    LDX #>(ObjectSpriteFrameRecords + $146)
    LDY #<(ObjectSpriteFrameRecords + $146)
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State2:
    CMP #$02
    BNE SelectType41State3
    LDX #>(ObjectSpriteFrameRecords + $14A)
    LDY #<(ObjectSpriteFrameRecords + $14A)
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State3:
    CMP #$03
    BNE SelectType41State4
    LDX #>(ObjectSpriteFrameRecords + $14E)
    LDY #<(ObjectSpriteFrameRecords + $14E)
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State4:
    CMP #$04
    BNE SelectType41CompactState5
    LDX #>(ObjectSpriteFrameRecords + $152)
    LDY #<(ObjectSpriteFrameRecords + $152)
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41CompactState5:
    CMP #$05
    BNE SelectType41CompactState6
    LDX #>(ObjectSpriteFrameRecords + $146)
    LDY #<(ObjectSpriteFrameRecords + $146)
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState6:
    CMP #$06
    BNE SelectType41CompactState7
    LDX #>(ObjectSpriteFrameRecords + $14A)
    LDY #<(ObjectSpriteFrameRecords + $14A)
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState7:
    CMP #$07
    BNE SelectType41CompactState8
    LDX #>(ObjectSpriteFrameRecords + $14E)
    LDY #<(ObjectSpriteFrameRecords + $14E)
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState8:
    CMP #$08
    BNE SelectType41WideState9
    LDX #>(ObjectSpriteFrameRecords + $152)
    LDY #<(ObjectSpriteFrameRecords + $152)
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41WideState9:
    CMP #$09
    BNE SelectType41WideState10
    LDX #>(ObjectSpriteFrameRecords + $146)
    LDY #<(ObjectSpriteFrameRecords + $146)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState10:
    CMP #$0A
    BNE SelectType41WideState11
    LDX #>(ObjectSpriteFrameRecords + $14A)
    LDY #<(ObjectSpriteFrameRecords + $14A)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState11:
    CMP #$0B
    BNE SelectType41WideState12
    LDX #>(ObjectSpriteFrameRecords + $14E)
    LDY #<(ObjectSpriteFrameRecords + $14E)
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState12:
    CMP #$0C
    BNE FinishType41Sprite
    LDX #>(ObjectSpriteFrameRecords + $152)
    LDY #<(ObjectSpriteFrameRecords + $152)
    JSR DrawTwoObjectSprites

FinishType41Sprite:
    JMP AdvanceFrameSpriteObject
