; Sub-command menu and transfer-status tile text
; CPU range $FB77-$FBAB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SubCommandTitleText:
    .incbin RevisionSubCommandTextAsset, 0, 12

SubCommandLoadText:
    .incbin RevisionSubCommandTextAsset, 12, 5

SubCommandSaveText:
    .incbin RevisionSubCommandTextAsset, 17, 5

SubCommandResetText:
    .incbin RevisionSubCommandTextAsset, 22, 6

SubCommandBackText:
    .incbin RevisionSubCommandTextAsset, 28, 5

SubCommandGameText:
    .incbin RevisionSubCommandTextAsset, 33, 5

LoadTransferMessage:
    .incbin RevisionSubCommandTextAsset, 38, 8

SaveTransferMessage:
    .incbin RevisionSubCommandTextAsset, 46, 7
