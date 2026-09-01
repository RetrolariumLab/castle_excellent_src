; Preservation PRG between mutable-cell lookup and predicates
; CPU range $A6CA-$A6D7
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_A6CA:
    CPX #$8A
    BCC Label_A6D5
    CPX #$92
    BCS Label_A6D5
    LDY #$00
    RTS

Label_A6D5:
    LDY #$FF
    RTS
