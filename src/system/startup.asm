; Reset initialization and NMI-paced main loop
; CPU range $8225-$82CD
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Reset:
    SEI
    CLD
    LDA #PpuMaskRenderingDisabled
    STA PPU_CTRL

WaitForFirstResetVblank:
    LDA PPU_STATUS
    BPL WaitForFirstResetVblank

WaitForSecondResetVblank:
    LDA PPU_STATUS
    BPL WaitForSecondResetVblank
    CLD
    LDX #$FF
    TXS
    LDX #PowerOnSignatureCheckedBytes - 1

CheckPowerOnSignature:
    LDA PowerOnSignatureRam,X
    CMP PowerOnSignature,X
    BNE InitializeColdBootState
    DEX
    BPL CheckPowerOnSignature
    BMI IncrementResetCounter

InitializeColdBootState:
    LDX #PowerOnSignatureCheckedBytes - 1

CopyPowerOnSignature:
    LDA PowerOnSignature,X
    STA PowerOnSignatureRam,X
    DEX
    BPL CopyPowerOnSignature
    LDA #$00
    STA HighScoreLo
    STA HighScoreHi
    STA ResetCounterLo
    STA ResetCounterHi

IncrementResetCounter:
    INC ResetCounterLo
    BNE StartNewGame
    INC ResetCounterHi

StartNewGame:
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JSR RunTitleScreen
    JSR InitializeNewGame
    JSR LoadRoom

WaitForRoomLoadVblank:
    LDA PPU_STATUS
    BPL WaitForRoomLoadVblank
    JSR EnableNmi
    JSR WaitForVblankAndEnableRendering

MainFrameLoop:
    LDA #NmiFramesPerMainUpdate
    STA NmiFrameCountdown
    JSR HandleCastleMapInput
    LDA CastleMapMode
    BNE WaitForMainFrame
    JSR FormatPlayerStatusTiles
    JSR HandlePauseInput
    LDA PauseMode
    BNE RenderMainFrame
    JSR UpdatePlayerInputAndMovement
    JSR UpdatePlayerProtectionAndHazardState
    JSR EnsureRoomAudioPlaying
    JSR UpdateRuntimeObjects
    JSR UpdatePlayerCollisionState
    JSR AnimateRoomCells
    INC RoomFrameCounter

RenderMainFrame:
    JSR UpdateHorizontalScroll
    JSR BuildFrameSprites
    JSR HandleSubCommandInput
    LDA DemoPlaybackActive
    BEQ WaitForMainFrame
    LDA PhysicalController1Buttons
    AND #ControllerButtonStart
    BNE StartNewGame

WaitForMainFrame:
    LDA NmiFrameCountdown
    BNE WaitForMainFrame
    BEQ MainFrameLoop

PowerOnSignature:
    .byte $50, $4F, $57, $45, $52
