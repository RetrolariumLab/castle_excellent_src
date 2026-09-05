; Player room-cell and runtime-object collision handler tables
; CPU range $926B-$9385
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ReturnFromPlayerCollisionHandler:
    RTS

PlayerRoomCellCollisionHandlerPointers:
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $AB, $8D, $AB, $8D, $AB, $8D
    .byte $AB, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92

PlayerRuntimeCollisionHandlerPointers:
    .byte $6B, $92, $70, $8D, $57, $8D, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $12, $8C, $21, $8C, $30, $8C, $3F, $8C, $4E, $8C, $5D, $8C, $9E, $8C, $F2, $8C
    .byte $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D
    .byte $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92
    .byte $6B, $92
