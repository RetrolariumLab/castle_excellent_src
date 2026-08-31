; Room-screen finalization and NMI task requests
; CPU range $EB6C-$EB8E
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FinalizeRoomLoad:
    JSR ClearRoomNametablesAndSprites
    JSR UploadRoomPalette
    JSR InitializeRoomStatusDisplay
    LDA #$FF
    LDX #NmiTaskRequestCount - 1

RequestAllNmiTasks:
    STA NmiTaskRequests,X
    DEX
    BPL RequestAllNmiTasks
    JSR ResetPpuScroll
    JSR WaitForVblankAndEnableRendering
    LDA #PpuCtrlCastleMapNmi
    STA PPU_CTRL
    LDY #$00
    JMP SelectChrBank
