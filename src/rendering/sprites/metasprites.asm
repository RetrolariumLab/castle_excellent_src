; Object metasprites and descriptor data
; CPU range $B1D6-$B64B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DrawTwoObjectSprites:
    STX MetaspritePointerHi
    STY MetaspritePointerLo
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #ObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC DrawSecondStandardObjectSprite
    BNE DrawSecondStandardObjectSprite
    LDX OamStagingWriteOffset
    LDY #$00
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

DrawSecondStandardObjectSprite:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #SecondStandardObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC FinishTwoObjectSprites
    BNE FinishTwoObjectSprites
    LDX OamStagingWriteOffset
    LDY #$02
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

FinishTwoObjectSprites:
    RTS

DrawOneObjectSprite:
    STX MetaspritePointerHi
    STY MetaspritePointerLo
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #ObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC FinishOneObjectSprite
    BNE FinishOneObjectSprite
    LDX OamStagingWriteOffset
    LDY #$00
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

FinishOneObjectSprite:
    RTS

DrawFourObjectSprites:
    STX MetaspritePointerHi
    STY MetaspritePointerLo
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #ObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC DrawSecondWideObjectSprite
    BNE DrawSecondWideObjectSprite
    LDX OamStagingWriteOffset
    LDY #$00
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

DrawSecondWideObjectSprite:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #SecondStandardObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC DrawThirdWideObjectSprite
    BNE DrawThirdWideObjectSprite
    LDX OamStagingWriteOffset
    LDY #$02
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

DrawThirdWideObjectSprite:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #ThirdWideObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC DrawFourthWideObjectSprite
    BNE DrawFourthWideObjectSprite
    LDX OamStagingWriteOffset
    LDY #$04
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$05
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

DrawFourthWideObjectSprite:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #FourthWideObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC FinishFourObjectSprites
    BNE FinishFourObjectSprites
    LDX OamStagingWriteOffset
    LDY #$06
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$07
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

FinishFourObjectSprites:
    RTS

DrawTwoCompactObjectSprites:
    STX MetaspritePointerHi
    STY MetaspritePointerLo
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #ObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC DrawSecondCompactObjectSprite
    BNE DrawSecondCompactObjectSprite
    LDX OamStagingWriteOffset
    LDY #$00
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$01
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

DrawSecondCompactObjectSprite:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #SecondCompactObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC FinishCompactObjectSprites
    BNE FinishCompactObjectSprites
    LDX OamStagingWriteOffset
    LDY #$02
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01,X
    LDY #$03
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02,X
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectMetaspriteYBias
    LDX OamStagingWriteOffset
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX OamStagingWriteOffset

FinishCompactObjectSprites:
    RTS

DrawPlayerMetasprite:
    STX MetaspritePointerHi
    STY MetaspritePointerLo
    LDA PlayerXLo
    CLC
    ADC #ObjectSpriteWorldX
    STA MetaspriteWorldXLo
    LDA PlayerXHi
    ADC #$00
    STA MetaspriteWorldXHi
    LDA MetaspriteWorldXLo
    SEC
    SBC MetaspritePendingScrollX
    STA MetaspriteScreenX
    LDA MetaspriteWorldXHi
    SBC #$00
    BCC FinishPlayerMetasprite
    BNE FinishPlayerMetasprite
    LDA PlayerMetaspriteDeadReadState
    ASL A
    ASL A
    TXA
    LDY #$00
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $01
    LDY #$01
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $02
    LDY #$02
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $05
    LDY #$03
    LDA (MetaspritePointerLo),Y
    STA OamStagingBuffer + $06
    LDA PlayerY
    CLC
    ADC #PlayerMetaspriteYBias
    STA OamStagingBuffer
    STA OamStagingBuffer + $04
    LDA MetaspriteScreenX
    STA OamStagingBuffer + $03
    CLC
    ADC #HardwareSpriteWidth
    STA OamStagingBuffer + $07
    BCC FinishPlayerMetasprite
    LDA #OamHiddenY
    STA OamStagingBuffer + $04

FinishPlayerMetasprite:
    RTS

PlayerRightWalkMetasprite0:
    .byte $90, $02, $92, $02

PlayerRightWalkMetaspriteMiddle:
    .byte $94, $02, $96, $02

PlayerRightWalkMetasprite2:
    .byte $98, $02, $9A, $02

PlayerNeutralMetasprite:
    .byte $A4, $02, $A6, $02

PlayerRightMotionMetasprite:
    .byte $9C, $02, $9E, $02

PlayerLeftWalkMetasprite0:
    .byte $92, $42, $90, $42

PlayerLeftWalkMetaspriteMiddle:
    .byte $96, $42, $94, $42

PlayerLeftWalkMetasprite2:
    .byte $9A, $42, $98, $42

PlayerNeutralMotionMetasprite:
    .byte $A0, $02, $A2, $02

PlayerLeftMotionMetasprite:
    .byte $9E, $42, $9C, $42

PlayerRightActionMetasprite:
    .byte $B0, $02, $B2, $02

PlayerLeftActionMetasprite:
    .byte $B2, $42, $B0, $42

PlayerTransitionMetasprite0:
    .byte $C0, $02, $C2, $02

PlayerTransitionMetasprite1:
    .byte $C4, $02, $C6, $02

PlayerTransitionMetasprite2:
    .byte $FA, $02, $FC, $02

PlayerTransitionMetasprite3:
    .byte $8A, $02, $8C, $02
; Object sprite frame records; the Draw*Sprite selectors pass their addresses in X:Y
ObjectSpriteFrameRecords:
    .byte $00, $01, $02, $01, $04, $01, $06, $01, $08, $01, $0A, $01, $02, $41, $00, $41
    .byte $06, $41, $04, $41, $0A, $41, $08, $41, $A8, $01, $AA, $01, $AA, $41, $A8, $41
    .byte $24, $02, $26, $02, $28, $02, $2A, $02, $2C, $02, $2E, $02, $26, $42, $24, $42
    .byte $2A, $42, $28, $42, $2E, $42, $2C, $42, $30, $02, $32, $02, $32, $42, $34, $02
    .byte $34, $42, $36, $02, $36, $42, $38, $02, $38, $42, $3A, $02, $3A, $42, $18, $03
    .byte $1A, $03, $1C, $03, $1E, $03, $20, $03, $22, $03, $1A, $43, $18, $43, $1E, $43
    .byte $1C, $43, $22, $43, $20, $43, $0C, $00, $0E, $00, $10, $00, $12, $00, $14, $00
    .byte $16, $00, $AC, $00, $AE, $00, $0E, $40, $0C, $40, $12, $40, $10, $40, $16, $40
    .byte $14, $40, $AE, $40, $AC, $40, $48, $01, $4A, $01, $4C, $01, $4E, $01, $50, $01
    .byte $52, $01, $4A, $41, $48, $41, $4E, $41, $4C, $41, $52, $41, $50, $41, $54, $02
    .byte $56, $02, $58, $02, $5A, $02, $5C, $02, $5E, $02, $56, $42, $54, $42, $5A, $42
    .byte $58, $42, $5E, $42, $5C, $42, $F6, $02, $F8, $02, $D8, $00, $D8, $01, $D8, $02
    .byte $DA, $02, $DA, $00, $DA, $01, $82, $00, $82, $40, $6C, $01, $6C, $41, $74, $01
    .byte $76, $01, $70, $03, $72, $03, $6E, $01, $6E, $C1, $7C, $03, $7E, $03, $60, $01
    .byte $62, $01, $78, $01, $7A, $01, $64, $00, $66, $00, $68, $00, $6A, $00, $D0, $00
    .byte $D0, $40, $D2, $01, $D2, $41, $CC, $01, $CE, $01, $68, $00, $6A, $00, $68, $00
    .byte $6A, $00, $68, $00, $6A, $00, $B4, $03, $B6, $03, $B8, $03, $BA, $03, $BC, $03
    .byte $BE, $03, $FE, $01, $FE, $41, $FE, $41, $FE, $01, $84, $00, $86, $00, $D6, $00
    .byte $F2, $00, $88, $00, $D4, $00, $8A, $03, $8C, $00, $8E, $03, $8E, $43, $E2, $00
    .byte $E2, $40, $E4, $00, $E4, $40, $C8, $03, $C8, $43, $DC, $01, $DC, $41, $DE, $01
    .byte $DE, $41, $E0, $01, $E0, $41, $E8, $00, $E6, $00, $EA, $00, $E6, $00, $EC, $00
    .byte $E6, $00, $EE, $00, $E6, $00
