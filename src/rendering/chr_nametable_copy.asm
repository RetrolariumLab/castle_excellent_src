; Four-page CHR-ROM to PPU nametable copier
; CPU range $F973-$F9AC
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CopyChrNametablePagesToVram:
    STA ChrNametableCopySourcePage
    LDA #ChrNametableDestinationFirstPage
    STA ChrNametableCopyDestinationPage
    JSR ClearRoomNametablesAndSprites
    LDY #ChrNametableCopyBank
    JSR SelectChrBank
    LDX #$00

CopyNextChrNametablePageByte:
    LDA PPU_STATUS
    LDA ChrNametableCopySourcePage
    STA PPU_ADDR
    STX PPU_ADDR
    LDA PPU_DATA
    LDY PPU_DATA
    LDA ChrNametableCopyDestinationPage
    STA PPU_ADDR
    STX PPU_ADDR
    STY PPU_DATA
    INX
    BNE CopyNextChrNametablePageByte
    INC ChrNametableCopySourcePage
    INC ChrNametableCopyDestinationPage
    LDA ChrNametableCopyDestinationPage
    CMP #ChrNametableDestinationEndPage
    BCC CopyNextChrNametablePageByte
    RTS
