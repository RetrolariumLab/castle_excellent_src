; Fixed PRG tail, room tile tables, and interrupt vectors
; Original CPU range $FEE8-$FFFF

PaddingBeforeTileTables:
; Pad with $FF up to the fixed tile tables at PrgTileTablesAddress; the
; original padding is $48 bytes, and a negative count fails the build when the
; code before it grows past the space
    .res PrgStart + (PrgTileTablesAddress - PrgBaseAddress) - *, $FF

LeftTileByCell:
    .byte $02, $02, $05, $05, $05, $05, $FF, $02, $00, $02, $06, $FF, $02, $07, $25, $27
    .byte $27, $29, $14, $17, $17, $FF, $18, $1A, $02, $5B, $5D, $02, $53, $55, $02, $57
    .byte $59, $02, $57, $59, $02, $5B, $5D, $02, $02, $53, $55, $02, $02, $02, $02, $0A
    .byte $0C, $0E, $0F, $10, $11, $2B, $2F, $49, $32, $4D, $4F, $2C, $4B, $4D, $4F, $2C
    .byte $4B, $3E, $3F, $3F, $41, $1B, $21, $1D, $1F, $FF, $FF, $FF, $12, $FF, $FF, $FF
    .byte $24, $FF, $43, $FF, $FF, $FF, $2B, $2F, $49, $32, $4D, $4F, $2C, $4B, $4D, $4F
    .byte $2C, $4B, $18, $18

RightTileByCell:
    .byte $02, $02, $05, $05, $05, $05, $02, $FF, $01, $02, $02, $06, $07, $FF, $26, $28
    .byte $28, $2A, $15, $17, $19, $16, $18, $FF, $02, $5C, $5E, $02, $54, $56, $02, $58
    .byte $5A, $02, $58, $5A, $02, $5C, $5E, $02, $02, $54, $56, $02, $02, $02, $02, $0B
    .byte $0D, $0E, $0F, $10, $11, $4C, $4E, $2D, $30, $2E, $31, $4A, $33, $4C, $4E, $2D
    .byte $30, $3F, $40, $3F, $42, $1C, $22, $1E, $20, $FF, $FF, $FF, $13, $FF, $FF, $23
    .byte $FF, $FF, $44, $FF, $FF, $FF, $4C, $4E, $2D, $30, $2E, $31, $4A, $33, $4C, $4E
    .byte $2D, $30, $18, $18

PaddingBeforeVectors:
    .byte $FF, $FF

NmiVector:
    .addr Nmi

ResetVector:
    .addr Reset

IrqVector:
    .addr Irq
