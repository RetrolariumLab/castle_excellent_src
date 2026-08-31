; NMI task-request reset
; CPU range $9578-$9582
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ResetNmiTaskRequests:
    LDA #$FF
    LDX #NmiTaskRequestCount - 1

ClearNextNmiTaskRequest:
    STA NmiTaskRequests,X
    DEX
    BPL ClearNextNmiTaskRequest
    RTS
