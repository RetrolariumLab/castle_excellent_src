; Room palette pointer setup and upload
; CPU range $A351-$A35B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadRoomPalette:
    LDA #>RoomPaletteData
    STA RoomPalettePointerHi
    LDA #<RoomPaletteData
    STA RoomPalettePointerLo
    JMP UploadPaletteFromPointer
