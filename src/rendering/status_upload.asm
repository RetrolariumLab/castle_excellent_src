; NMI status upload and task handler tables
; CPU range $C804-$C8BB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadStatusTiles:
    LDA StatusTilesBusy
    BEQ WriteStatusTiles
    JMP UploadRoomCellRow00

WriteStatusTiles:
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$96
    STA PPU_ADDR
    LDA StatusScoreTiles
    STA PPU_DATA
    LDA StatusScoreTiles + $01
    STA PPU_DATA
    LDA StatusScoreTiles + $02
    STA PPU_DATA
    LDA StatusScoreTiles + $03
    STA PPU_DATA
    LDA StatusScoreTiles + $04
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$87
    STA PPU_ADDR
    LDA StatusInventoryTiles
    STA PPU_DATA
    LDA StatusInventoryTiles + $01
    STA PPU_DATA
    LDA StatusInventoryTiles + $05
    STA PPU_DATA
    LDA StatusInventoryTiles + $04
    STA PPU_DATA
    LDA StatusInventoryTiles + $03
    STA PPU_DATA
    LDA StatusInventoryTiles + $02
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A8
    STA PPU_ADDR
    LDA StatusLivesTiles + $01
    STA PPU_DATA
    LDA StatusLivesTiles
    STA PPU_DATA
    LDY #$01
    LDX #$28

WaitForStatusUploadTiming:
    DEX
    BNE WaitForStatusUploadTiming
    DEY
    BNE WaitForStatusUploadTiming
    JMP NmiFrame

NmiTaskHandlerHighBytes:
    .byte $C8, $C8, $C9, $CB, $CC, $CD, $CF, $D0, $D1, $D2, $D4, $D5, $D6, $D7, $D9, $DA
    .byte $DB, $DC, $DE, $DF, $E0, $E1, $E3

NmiTaskHandlerLowBytes:
    .byte $04, $BC, $FF, $42, $85, $C8, $0B, $4E, $91, $D4, $17, $5A, $9D, $E0, $23, $66
    .byte $A9, $EC, $2F, $72, $B5, $F8, $58
