; 32-byte PPU palette uploader
; CPU range $C4CD-$C4FC
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadPaletteFromPointer:
    JSR DisableNmi
    JSR DisableRendering

WaitForPaletteUploadVblank:
    LDA PPU_STATUS
    BPL WaitForPaletteUploadVblank
    LDA #>PpuPaletteAddress
    STA PPU_ADDR
    LDY #<PpuPaletteAddress
    STY PPU_ADDR

UploadNextPaletteByte:
    LDA (PaletteSourcePointerLo),Y
    STA PPU_DATA
    INY
    CPY #PpuPaletteByteCount
    BCC UploadNextPaletteByte
    LDA #>PpuPaletteAddress
    STA PPU_ADDR
    LDA #<PpuPaletteAddress
    STA PPU_ADDR
    STA PPU_ADDR
    STA PPU_ADDR
    RTS
