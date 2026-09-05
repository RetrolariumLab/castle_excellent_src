; Sub-command menu and transfer-status tile text
; CPU range $FB77-$FBAB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SubCommandTitleText:
    .byte $83, $85, $72, $FF, $73, $7F, $7D, $7D, $71, $7E, $74, $00

SubCommandLoadText:
    .byte $7C, $7F, $71, $74, $00

SubCommandSaveText:
    .byte $83, $71, $86, $75, $00

SubCommandResetText:
    .byte $82, $75, $83, $75, $84, $00

SubCommandBackText:
    .byte $72, $71, $73, $7B, $00

SubCommandGameText:
    .byte $77, $71, $7D, $75, $00

LoadTransferMessage:
    .byte $7C, $7F, $71, $74, $79, $7E, $77, $00

SaveTransferMessage:
    .byte $83, $71, $86, $79, $7E, $77, $00
