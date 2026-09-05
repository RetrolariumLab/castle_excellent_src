; Vector padding and 6502 interrupt vectors
; CPU range $FFF8-$FFFF
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

PaddingBeforeVectors:
    .byte $FF, $FF

NmiVector:
    .addr Nmi

ResetVector:
    .addr Reset

IrqVector:
    .addr Irq
