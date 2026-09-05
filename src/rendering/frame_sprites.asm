; Frame sprite orchestration and object render pointers
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
    .byte $E7, $AD, $08, $AE, $12, $AE, $19, $AE, $75, $AE, $BB, $AE, $1E, $AF, $6A, $AF
    .byte $B0, $AF, $F4, $AF, $FB, $AF, $02, $B0, $09, $B0, $10, $B0, $17, $B0, $2B, $B0
    .byte $35, $B0, $3C, $B0, $43, $B0, $4A, $B0, $51, $B0, $58, $B0, $5F, $B0, $66, $B0
    .byte $6D, $B0, $74, $B0, $7B, $B0, $82, $B0, $89, $B0, $89, $B0, $90, $B0, $AC, $B0
    .byte $C9, $B0, $D0, $B0, $DA, $B0, $E1, $B0, $E8, $B0, $EF, $B0, $14, $B1, $17, $B1
    .byte $35, $B1
