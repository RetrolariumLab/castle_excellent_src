; Object sprite selectors
; CPU range $ADE7-$B1D5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DrawRuntimeObjectType01Sprite:
    LDA RoomFrameCounter
    LSR A
    AND #$03
    BNE SelectType01Frame2OrMiddle
    LDX #$B5
    LDY #$94
    JMP DrawTwoObjectSpritesAndAdvance

SelectType01Frame2OrMiddle:
    CMP #$02
    BNE DrawType01MiddleFrame
    LDX #$B5
    LDY #$9C
    JMP DrawTwoObjectSpritesAndAdvance

DrawType01MiddleFrame:
    LDX #$B5
    LDY #$98
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType02Sprite:
    LDX #$B5
    LDY #$AC

DrawTwoObjectSpritesAndAdvance:
    JSR DrawTwoObjectSprites
    JMP AdvanceFrameSpriteObject

DrawRuntimeObjectType03Sprite:
    LDX #$B5
    LDY #$BC
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType04Sprite:
    LDA RuntimeObjectState,X
    BMI SelectType04NegativeStateSprite
    LDA RuntimeObjectFighterJumpCountdown,X
    BEQ SelectType04PositiveStateAnimation
    LDX #$B5
    LDY #$0E
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04PositiveStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType04PositiveFrame2OrMiddle
    LDX #$B4
    LDY #$F6
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType04PositiveMiddleFrame
    LDX #$B4
    LDY #$FE
    JMP DrawTwoObjectSpritesAndAdvance

DrawType04PositiveMiddleFrame:
    LDX #$B4
    LDY #$FA
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeStateSprite:
    LDA RuntimeObjectFighterJumpCountdown,X
    BEQ SelectType04NegativeStateAnimation
    LDX #$B5
    LDY #$12
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType04NegativeFrame2OrMiddle
    LDX #$B5
    LDY #$02
    JMP DrawTwoObjectSpritesAndAdvance

SelectType04NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType04NegativeMiddleFrame
    LDX #$B5
    LDY #$0A
    JMP DrawTwoObjectSpritesAndAdvance

DrawType04NegativeMiddleFrame:
    LDX #$B5
    LDY #$06
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType05Sprite:
    LDA RuntimeObjectState,X
    BMI SelectType05NegativeStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType05PositiveFrame2OrMiddle
    LDX #$B5
    LDY #$16
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType05PositiveMiddleFrame
    LDX #$B5
    LDY #$1E
    JMP DrawTwoObjectSpritesAndAdvance

DrawType05PositiveMiddleFrame:
    LDX #$B5
    LDY #$1A
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType05NegativeFrame2OrMiddle
    LDX #$B5
    LDY #$22
    JMP DrawTwoObjectSpritesAndAdvance

SelectType05NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType05NegativeMiddleFrame
    LDX #$B5
    LDY #$2A
    JMP DrawTwoObjectSpritesAndAdvance

DrawType05NegativeMiddleFrame:
    LDX #$B5
    LDY #$26
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType06Sprite:
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
    LDX #$B5
    LDY #$2E
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
    LDX #$B5
    LDY #$30
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06InnerTransitionFrame:
    CMP #$09
    BEQ DrawType06InnerTransitionFrame
    CMP #$0E
    BNE SelectType06CycleFrame

DrawType06InnerTransitionFrame:
    LDX #$B5
    LDY #$34
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06CycleFrame:
    LDA RoomFrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType06AlternatingFrame
    LDX #$B5
    LDY #$38
    JMP DrawTwoObjectSpritesAndAdvance

SelectType06AlternatingFrame:
    AND #$01
    BEQ DrawType06EvenCycleFrame
    LDX #$B5
    LDY #$3C
    JMP DrawTwoObjectSpritesAndAdvance

DrawType06EvenCycleFrame:
    LDX #$B5
    LDY #$40
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType07Sprite:
    LDA RuntimeObjectState,X
    BMI SelectType07NegativeStateAnimation
    LDA FrameCounter
    CLC
    ADC RuntimeObjectKnightArrowCooldown,X
    LSR A
    LSR A
    AND #$03
    BNE SelectType07PositiveFrame2OrMiddle
    LDX #$B5
    LDY #$44
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType07PositiveMiddleFrame
    LDX #$B5
    LDY #$4C
    JMP DrawTwoObjectSpritesAndAdvance

DrawType07PositiveMiddleFrame:
    LDX #$B5
    LDY #$48
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07NegativeStateAnimation:
    LDA FrameCounter
    CLC
    ADC RuntimeObjectKnightArrowCooldown,X
    LSR A
    LSR A
    AND #$03
    BNE SelectType07NegativeFrame2OrMiddle
    LDX #$B5
    LDY #$50
    JMP DrawTwoObjectSpritesAndAdvance

SelectType07NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType07NegativeMiddleFrame
    LDX #$B5
    LDY #$58
    JMP DrawTwoObjectSpritesAndAdvance

DrawType07NegativeMiddleFrame:
    LDX #$B5
    LDY #$54
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType08Sprite:
    LDA RuntimeObjectState,X
    BMI SelectType08NegativeStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType08PositiveFrame2OrMiddle
    LDX #$B5
    LDY #$5C
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType08PositiveMiddleFrame
    LDX #$B5
    LDY #$64
    JMP DrawTwoObjectSpritesAndAdvance

DrawType08PositiveMiddleFrame:
    LDX #$B5
    LDY #$60
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08NegativeStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType08NegativeFrame2OrMiddle
    LDX #$B5
    LDY #$6C
    JMP DrawTwoObjectSpritesAndAdvance

SelectType08NegativeFrame2OrMiddle:
    CMP #$02
    BNE DrawType08NegativeMiddleFrame
    LDX #$B5
    LDY #$74
    JMP DrawTwoObjectSpritesAndAdvance

DrawType08NegativeMiddleFrame:
    LDX #$B5
    LDY #$70
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType09Sprite:
    LDA RuntimeObjectState,X
    BPL SelectType09PositiveStateAnimation
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE DrawType09NegativeNonzeroFrame
    LDX #$B5
    LDY #$88
    JMP DrawTwoObjectSpritesAndAdvance

DrawType09NegativeNonzeroFrame:
    CMP #$02
    LDX #$B5
    LDY #$90
    JMP DrawTwoObjectSpritesAndAdvance

UnreferencedType09FrameSelectionBytes:
    .byte $A2, $B5, $A0, $8C, $4C, $0C, $AE

SelectType09PositiveStateAnimation:
    LDA FrameCounter
    LSR A
    LSR A
    AND #$03
    BNE SelectType09PositiveFrame2OrMiddle
    LDX #$B5
    LDY #$7C
    JMP DrawTwoObjectSpritesAndAdvance

SelectType09PositiveFrame2OrMiddle:
    CMP #$02
    BNE DrawType09PositiveMiddleFrame
    LDX #$B5
    LDY #$84
    JMP DrawTwoObjectSpritesAndAdvance

DrawType09PositiveMiddleFrame:
    LDX #$B5
    LDY #$80
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType10Sprite:
    LDX #$B5
    LDY #$C0
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType11Sprite:
    LDX #$B5
    LDY #$C4
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType12Sprite:
    LDX #$B5
    LDY #$C8
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType13Sprite:
    LDX #$B5
    LDY #$CC
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType14Sprite:
    LDX #$B5
    LDY #$D0
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType15Sprite:
    LDA FrameCounter
    AND #$08
    BNE DrawType15AlternateFrame
    LDX #$B5
    LDY #$D4
    JMP DrawTwoObjectSpritesAndAdvance

DrawType15AlternateFrame:
    LDX #$B5
    LDY #$D8
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType16Sprite:
    LDX #$B5
    LDY #$B0

DrawOneObjectSpriteAndAdvance:
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

DrawRuntimeObjectType17Sprite:
    LDX #$B5
    LDY #$B2
    JMP DrawOneObjectSpriteAndAdvance

DrawRuntimeObjectType18Sprite:
    LDX #$B5
    LDY #$B4
    JMP DrawOneObjectSpriteAndAdvance

DrawRuntimeObjectType19Sprite:
    LDX #$B5
    LDY #$B6
    JMP DrawOneObjectSpriteAndAdvance

DrawRuntimeObjectType20Sprite:
    LDX #$B5
    LDY #$B8
    JMP DrawOneObjectSpriteAndAdvance

DrawRuntimeObjectType21Sprite:
    LDX #$B5
    LDY #$BA
    JMP DrawOneObjectSpriteAndAdvance

DrawRuntimeObjectType22Sprite:
    LDX #$B5
    LDY #$DC
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType23Sprite:
    LDX #$B5
    LDY #$E0
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType24Sprite:
    LDX #$B5
    LDY #$E4
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType25Sprite:
    LDX #$B5
    LDY #$E8
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType26Sprite:
    LDX #$B5
    LDY #$EC
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType27Sprite:
    LDX #$B5
    LDY #$F0
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType28Sprite:
    LDX #$B5
    LDY #$F4
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType29Or30Sprite:
    LDX #$B5
    LDY #$FC
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType31Sprite:
    LDA RoomFrameCounter
    BMI SelectType31RoomFrameParity
    JMP AdvanceFrameSpriteObject

SelectType31RoomFrameParity:
    LDA RoomFrameCounter
    LSR A
    BCC DrawType31EvenRoomFrame
    LDX #$B6
    LDY #$08
    JMP DrawTwoObjectSpritesAndAdvance

DrawType31EvenRoomFrame:
    LDX #$B6
    LDY #$0C
    JMP DrawTwoObjectSpritesAndAdvance

DrawWitchSummonSprite:
    LDX FrameCounterModulo3A
    BNE SelectWitchSummonModulo3Frame1Or2
    LDX #$B5
    LDY #$FC
    JMP DrawTwoObjectSpritesAndAdvance

SelectWitchSummonModulo3Frame1Or2:
    DEX
    BNE DrawWitchSummonModulo3Frame2
    LDX #$B6
    LDY #$00
    JMP DrawTwoObjectSpritesAndAdvance

DrawWitchSummonModulo3Frame2:
    LDX #$B6
    LDY #$04
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType33Sprite:
    LDX #$B6
    LDY #$18
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType34Sprite:
    LDX #$B6
    LDY #$10
    JSR DrawFourObjectSprites
    JMP AdvanceFrameSpriteObject

DrawRuntimeObjectType35Sprite:
    LDX #$B6
    LDY #$20
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType36Sprite:
    LDX #$B6
    LDY #$24
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType37Sprite:
    LDX #$B6
    LDY #$28
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType38Sprite:
    LDA RuntimeObjectY,X
    SEC
    SBC #$0B
    STA RuntimeObjectY,X
    LDA RuntimeObjectState,X
    BMI DrawType38NegativeStateSprite
    LDX #$B6
    LDY #$2E
    JSR DrawOneObjectSprite
    JMP RestoreType38ObjectY

DrawType38NegativeStateSprite:
    LDX #$B6
    LDY #$2C
    JSR DrawOneObjectSprite

RestoreType38ObjectY:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0B
    STA RuntimeObjectY,X

DrawRuntimeObjectType39Sprite:
    JMP AdvanceFrameSpriteObject

DrawRuntimeObjectType40Sprite:
    LDA RuntimeObjectState,X
    LSR A
    BNE SelectType40StatePair1OrLater
    LDX #$B6
    LDY #$30
    JMP DrawTwoObjectSpritesAndAdvance

SelectType40StatePair1OrLater:
    CMP #$01
    BNE DrawType40LaterStateFrame
    LDX #$B6
    LDY #$34
    JMP DrawTwoObjectSpritesAndAdvance

DrawType40LaterStateFrame:
    LDX #$B6
    LDY #$38
    JMP DrawTwoObjectSpritesAndAdvance

DrawRuntimeObjectType41Sprite:
    LDA RuntimeObjectState,X
    CMP #$01
    BNE SelectType41State2
    LDX #$B6
    LDY #$3C
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State2:
    CMP #$02
    BNE SelectType41State3
    LDX #$B6
    LDY #$40
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State3:
    CMP #$03
    BNE SelectType41State4
    LDX #$B6
    LDY #$44
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41State4:
    CMP #$04
    BNE SelectType41CompactState5
    LDX #$B6
    LDY #$48
    JSR DrawOneObjectSprite
    JMP AdvanceFrameSpriteObject

SelectType41CompactState5:
    CMP #$05
    BNE SelectType41CompactState6
    LDX #$B6
    LDY #$3C
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState6:
    CMP #$06
    BNE SelectType41CompactState7
    LDX #$B6
    LDY #$40
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState7:
    CMP #$07
    BNE SelectType41CompactState8
    LDX #$B6
    LDY #$44
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41CompactState8:
    CMP #$08
    BNE SelectType41WideState9
    LDX #$B6
    LDY #$48
    JSR DrawTwoCompactObjectSprites
    JMP AdvanceFrameSpriteObject

SelectType41WideState9:
    CMP #$09
    BNE SelectType41WideState10
    LDX #$B6
    LDY #$3C
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState10:
    CMP #$0A
    BNE SelectType41WideState11
    LDX #$B6
    LDY #$40
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState11:
    CMP #$0B
    BNE SelectType41WideState12
    LDX #$B6
    LDY #$44
    JMP DrawTwoObjectSpritesAndAdvance

SelectType41WideState12:
    CMP #$0C
    BNE FinishType41Sprite
    LDX #$B6
    LDY #$48
    JSR DrawTwoObjectSprites

FinishType41Sprite:
    JMP AdvanceFrameSpriteObject
