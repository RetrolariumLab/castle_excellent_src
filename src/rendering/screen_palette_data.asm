; Overlapping completion, title, and castle-map palettes
; CPU range $C4FD-$C53C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CompletionPaletteData:
    .byte $0F, $16, $36, $30, $0F, $1A, $36, $30, $0F, $08, $17, $27, $0F, $00, $10, $30

TitlePaletteData:
    .incbin RevisionTitlePaletteAsset

CastleMapPaletteData:
    .byte $0F, $16, $10, $30, $0F, $18, $1A, $2A, $0F, $07, $17, $27, $0F, $12, $21, $28
    .byte $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A, $36
