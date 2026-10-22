; Room screen and title demo scenes
; Original CPU range $B64C-$B874

ClearRoomNametablesAndSprites:
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX #$00
    LDA #$FF

FillRoomNametables:
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    DEX
    BNE FillRoomNametables
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #NametableAttributeTableSize
    LDA #$00

ClearLeftNametableAttributes:
    STA PPU_DATA
    DEX
    BNE ClearLeftNametableAttributes
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #NametableAttributeTableSize
    LDA #$00

ClearRightNametableAttributes:
    STA PPU_DATA
    DEX
    BNE ClearRightNametableAttributes
    LDX #$00
    LDA #$F0

HideRoomSprites:
    STA OamDmaBuffer,X
    STA OamStagingBuffer,X
    INX
    BNE HideRoomSprites

WaitForRoomVblankBeforeOamDma:
    LDA PPU_STATUS
    BPL WaitForRoomVblankBeforeOamDma
    LDA #$00
    STA OAM_ADDR
    LDA #$02
    STA OAM_DMA
    RTS

InitializeRoomStatusDisplay:
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$8E
    STA PPU_ADDR
    LDA #>RoomStatusTilesAt208E
    STA PpuTileStringPointerHi
    LDA #<RoomStatusTilesAt208E
    STA PpuTileStringPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$6E
    STA PPU_ADDR
    LDA #>RoomStatusTilesAt206E
    STA PpuTileStringPointerHi
    LDA #<RoomStatusTilesAt206E
    STA PpuTileStringPointerLo
    JSR WriteTerminatedPpuTiles
    JSR FormatHighScoreStatusTiles
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$76
    STA PPU_ADDR
    LDA #$00
    STA StatusScoreTerminator
    LDA #>StatusScoreTiles
    STA PpuTileStringPointerHi
    LDA #<StatusScoreTiles
    STA PpuTileStringPointerLo
    JSR WriteTerminatedPpuTiles
    JSR FormatPlayerStatusTiles
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$62
    STA PPU_ADDR
    LDA #>RoomStatusTilesAt2062
    STA PpuTileStringPointerHi
    LDA #<RoomStatusTilesAt2062
    STA PpuTileStringPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A2
    STA PPU_ADDR
    LDA #>RoomStatusTilesAt20A2
    STA PpuTileStringPointerHi
    LDA #<RoomStatusTilesAt20A2
    STA PpuTileStringPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$00

CopyInitialRoomAttributesToPpu:
    LDA InitialRoomAttributes,X
    STA PPU_DATA
    INX
    CPX #InitialRoomAttributeCount
    BCC CopyInitialRoomAttributesToPpu
    JMP ResetPpuScroll

WriteTerminatedPpuTiles:
    LDY #$00

WriteNextPpuTile:
    LDA (PpuTileStringPointerLo),Y
    BEQ ReturnFromPpuTileWrite
    STA PPU_DATA
    INY
    BNE WriteNextPpuTile

ReturnFromPpuTileWrite:
    RTS

RoomStatusTilesAt208E:
    .byte $91, $92, $95, $94, $8C, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $60, $00

RoomStatusTilesAt2062:
    .byte $8B, $8C, $8D, $FF, $FF, $52, $50, $51, $52, $50, $51, $00

RoomStatusTilesAt20A2:
    .byte $93, $8F, $96, $8C, $FF, $6B, $00

RoomStatusTilesAt206E:
    .byte $8E, $8F, $90, $91, $92, $95, $94, $8C, $FF, $FF, $FF, $FF, $FF, $60, $00

InitialRoomAttributes:
    .byte $40, $50, $90, $A0, $A0, $60, $50, $10, $05, $01, $00, $08, $0A, $05, $05, $01

UploadRoomAttributeTables:
    JSR DisableNmi
    JSR DisableRendering

WaitForAttributeUploadVblank:
    LDA PPU_STATUS
    BPL WaitForAttributeUploadVblank
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$00

UploadLeftRoomAttributes:
    LDA RoomAttributeScratch,X
    STA PPU_DATA
    INX
    CPX #NametableAttributeTableSize
    BCC UploadLeftRoomAttributes
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR

UploadRightRoomAttributes:
    LDA RoomAttributeScratch,X
    STA PPU_DATA
    INX
    CPX #RoomAttributeScratchSize
    BCC UploadRightRoomAttributes
    JMP ResetPpuScroll

InitializeTitleDemoPlayback:
    LDA #<TitleDemoInputScript
    STA DemoInputPointerLo
    LDA #>TitleDemoInputScript
    STA DemoInputPointerHi
    LDA #$00
    STA DemoInputRepeatCounter
    RTS

ReadDemoController1:
    INC DemoInputRepeatCounter
    LDA DemoInputRepeatCounter
    CMP #DemoInputCommandFrames
    BCS AdvanceDemoInputPointer
    LDY #$00

ReadCurrentDemoInputCommand:
    LDA (DemoInputPointerLo),Y
    CMP #DemoInputTerminator
    BNE ReturnMaskedDemoInput
    JMP Reset

ReturnMaskedDemoInput:
    AND #DemoInputControllerMask
    RTS

AdvanceDemoInputPointer:
    INC DemoInputPointerLo
    BNE ResetDemoInputRepeatCounter
    INC DemoInputPointerHi

ResetDemoInputRepeatCounter:
    LDY #$00
    STY DemoInputRepeatCounter
    BEQ ReadCurrentDemoInputCommand

TitleDemoInputScript:
    .byte $80, $80, $80, $80, $80, $80, $01, $01, $01, $01, $80, $80, $80, $80, $80, $80
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81, $81, $81, $81
    .byte $00, $41, $41, $41, $41, $41, $41, $43, $41, $43, $82, $40, $40, $40, $40, $40
    .byte $40, $40, $01, $01, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $FF
