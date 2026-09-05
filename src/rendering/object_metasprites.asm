; Object and player metasprite composition
; CPU range $B1D6-$B4B5
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
