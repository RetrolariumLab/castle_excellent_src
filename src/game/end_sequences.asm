; Game-over and type $82 completion sequences
; CPU range $FE31-$FEE7
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RunGameOverSequence:
    JSR UpdateHighScoreFromPlayerScore
    JSR ClearRoomNametablesAndSprites
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #GameOverMessagePpuAddressHi
    STA PPU_ADDR
    LDA #GameOverMessagePpuAddressLo
    STA PPU_ADDR
    LDA #>GameOverMessageTiles
    STA GameOverMessagePointerHi
    LDA #<GameOverMessageTiles
    STA GameOverMessagePointerLo
    JSR ShowBackgroundOnlyMessage
    JSR StopAudioStreams
    JSR ClearSoundEffectRequests
    JSR LoadAudioTrackSet2
    LDA #EndSequencePpuMask
    STA PPU_MASK
    SEI
    LDA #EndSequencePpuControl
    STA PPU_CTRL

WaitForGameOverAudioVblank:
    LDA PPU_STATUS
    BPL WaitForGameOverAudioVblank
    JSR UpdateAudioStreams
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForGameOverAudioVblank
    LDX #GameOverRestartDelayFrames

WaitForGameOverRestartDelayVblank:
    LDA PPU_STATUS
    BPL WaitForGameOverRestartDelayVblank
    DEX
    BNE WaitForGameOverRestartDelayVblank
    JMP Reset

GameOverMessageTiles:
    .byte $77, $71, $7D, $75, $FF, $7F, $86, $75, $82, $00

RunType82CompletionSequence:
    JSR UpdateHighScoreFromPlayerScore
    LDA #CompletionNametableChrPage
    JSR CopyChrNametablePagesToVram
    LDA #>CompletionPaletteData
    STA CompletionPalettePointerHi
    LDA #<CompletionPaletteData
    STA CompletionPalettePointerLo
    JSR UploadPaletteFromPointer
    LDY #CompletionChrBank
    JSR SelectChrBank
    JSR DisableNmi
    JSR StopAudioStreams
    JSR ClearSoundEffectRequests
    JSR LoadAudioTrackSet4

WaitForType82CompletionSetupVblank:
    LDA PPU_STATUS
    BPL WaitForType82CompletionSetupVblank
    JSR WaitForVblankAndEnableRendering
    LDA #EndSequencePpuMask
    STA PPU_MASK
    SEI
    LDA #EndSequencePpuControl
    STA PPU_CTRL

WaitForType82CompletionAudioVblank:
    LDA PPU_STATUS
    BPL WaitForType82CompletionAudioVblank
    JSR UpdateAudioStreams
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForType82CompletionAudioVblank

FreezeAfterType82CompletionAudio:
    BEQ FreezeAfterType82CompletionAudio

UpdateHighScoreFromPlayerScore:
    LDA EndingPlayerScoreLo
    CMP HighScoreLo
    LDA EndingPlayerScoreHi
    SBC HighScoreHi
    BCC ReturnFromHighScoreUpdate
    LDA EndingPlayerScoreLo
    STA HighScoreLo
    LDA EndingPlayerScoreHi
    STA HighScoreHi

ReturnFromHighScoreUpdate:
    RTS
