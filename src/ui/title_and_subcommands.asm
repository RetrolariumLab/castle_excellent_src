; Title screen and sub-command interface
; Original CPU range $F8FC-$FBFD

RunTitleScreen:
    LDA #TitleNametableChrPage
    JSR CopyChrNametablePagesToVram
    LDA #>TitlePaletteData
    STA TitlePalettePointerHi
    LDA #<TitlePaletteData
    STA TitlePalettePointerLo
    JSR UploadPaletteFromPointer
    LDY #TitleChrBank
    JSR SelectChrBank
    JSR ResetPpuScroll
    LDX #$00
    STX TitleFrameCounterLo
    STX TitleFrameCounterHi
    DEX
    STX DemoPlaybackActive
    JSR InitializeTitleDemoPlayback
    JSR LoadAudioTrackSet5
    SEI

WaitForTitleSetupVblank:
    LDA PPU_STATUS
    BPL WaitForTitleSetupVblank
    LDA #TitlePpuMask
    STA PPU_MASK
    LDA #TitlePpuControl
    STA PPU_CTRL
    JSR ReadController1WithoutNmiControl
    EOR #$FF
    STA PreviousController1Buttons

WaitForTitleFrameVblank:
    LDA PPU_STATUS
    BPL WaitForTitleFrameVblank
    JSR UpdateAudioStreams
    INC TitleFrameCounterLo
    BNE CheckTitleTimeout
    INC TitleFrameCounterHi

CheckTitleTimeout:
    LDA TitleFrameCounterHi
    CMP #TitleTimeoutHighByte
    BCS ExitTitleScreen
    JSR ReadController1WithoutNmiControl
    TAX
    AND PreviousController1Buttons
    AND #SubCommandStartButtonMask
    PHA
    TXA
    EOR #$FF
    STA PreviousController1Buttons
    PLA
    BEQ WaitForTitleFrameVblank
    LDA #$00
    STA DemoPlaybackActive

ExitTitleScreen:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$00
    JMP SelectChrBank

CopyChrNametablePagesToVram:
    STA ChrNametableCopySourcePage
    LDA #ChrNametableDestinationFirstPage
    STA ChrNametableCopyDestinationPage
    JSR ClearRoomNametablesAndSprites
    LDY #ChrNametableCopyBank
    JSR SelectChrBank
    LDX #$00

CopyNextChrNametablePageByte:
    LDA PPU_STATUS
    LDA ChrNametableCopySourcePage
    STA PPU_ADDR
    STX PPU_ADDR
    LDA PPU_DATA
    LDY PPU_DATA
    LDA ChrNametableCopyDestinationPage
    STA PPU_ADDR
    STX PPU_ADDR
    STY PPU_DATA
    INX
    BNE CopyNextChrNametablePageByte
    INC ChrNametableCopySourcePage
    INC ChrNametableCopyDestinationPage
    LDA ChrNametableCopyDestinationPage
    CMP #ChrNametableDestinationEndPage
    BCC CopyNextChrNametablePageByte
    RTS

HandleSubCommandInput:
    LDA GameOverActive
    BEQ CheckSubCommandDemoGate
    RTS

CheckSubCommandDemoGate:
    LDA DemoPlaybackActive
    BEQ DetectSubCommandOpenEdge
    RTS

DetectSubCommandOpenEdge:
    LDA PreviousController2Buttons
    EOR #$FF
    AND Controller2Buttons
    AND #SubCommandOpenButtonMask
    BNE OpenSubCommandMenu
    LDA Controller2Buttons
    STA PreviousController2Buttons
    RTS

OpenSubCommandMenu:
    JSR ClearRoomNametablesAndSprites
    LDA #$00
    STA JOYPAD1
    STA APU_STATUS

WaitForSubCommandMenuVblank:
    LDA PPU_STATUS
    BPL WaitForSubCommandMenuVblank
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0A
    STA PPU_ADDR
    LDA #>SubCommandTitleText
    STA SubCommandTextPointerHi
    LDA #<SubCommandTitleText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #>SubCommandResetText
    STA SubCommandTextPointerHi
    LDA #<SubCommandResetText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CD
    STA PPU_ADDR
    LDA #>SubCommandBackText
    STA SubCommandTextPointerHi
    LDA #<SubCommandBackText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0D
    STA PPU_ADDR
    LDA #>SubCommandLoadText
    STA SubCommandTextPointerHi
    LDA #<SubCommandLoadText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4D
    STA PPU_ADDR
    LDA #>SubCommandSaveText
    STA SubCommandTextPointerHi
    LDA #<SubCommandSaveText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #>SubCommandGameText
    STA SubCommandTextPointerHi
    LDA #<SubCommandGameText
    STA SubCommandTextPointerLo
    JSR WriteTerminatedPpuTiles
    LDA #$00
    STA SubCommandSelection
    LDA #$FF
    STA SubCommandPreviousButtons

UpdateSubCommandMenu:
    LDA PPU_STATUS
    BPL UpdateSubCommandMenu
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    LDX #$FF
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CB
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$00
    STA SubCommandCursorPpuAddressHi
    LDA SubCommandSelection
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ROL SubCommandCursorPpuAddressHi
    CLC
    ADC #$8B
    STA SubCommandCursorPpuAddressLo
    LDA #$21
    ADC SubCommandCursorPpuAddressHi
    STA PPU_ADDR
    LDA SubCommandCursorPpuAddressLo
    STA PPU_ADDR
    LDA #SubCommandCursorTile
    STA PPU_DATA
    JSR ResetPpuScroll

WaitForSubCommandInputVblank:
    LDA PPU_STATUS
    BPL WaitForSubCommandInputVblank
    LDA #$08
    STA PPU_MASK
    JSR DisableNmi
    JSR ReadController1WithoutNmiControl
    PHA
    AND SubCommandPreviousButtons
    TAY
    PLA
    EOR #$FF
    STA SubCommandPreviousButtons
    TYA
    AND #SubCommandNextButtonMask
    BEQ CheckSubCommandStartButton
    INC SubCommandSelection
    LDA SubCommandSelection
    CMP #SubCommandSelectionCount
    BCS WrapSubCommandSelectionForward
    JMP UpdateSubCommandMenu

WrapSubCommandSelectionForward:
    LDA #$00
    STA SubCommandSelection
    BNE CheckSubCommandStartButton
    JMP UpdateSubCommandMenu

CheckSubCommandStartButton:
    TYA
    AND #SubCommandStartButtonMask
    BEQ CheckSubCommandAButton
    LDA #$00
    STA SubCommandTransportMode
    BEQ ExecuteSubCommandSelection

CheckSubCommandAButton:
    TYA
    AND #SubCommandAButtonMask
    BEQ CheckSubCommandUpButton
    LDA #$FF
    STA SubCommandTransportMode
    BNE ExecuteSubCommandSelection

CheckSubCommandUpButton:
    TYA
    AND #SubCommandUpButtonMask
    BEQ RedrawSubCommandSelection
    DEC SubCommandSelection
    LDA SubCommandSelection
    CMP #$FF
    BNE RedrawSubCommandSelection
    LDA #SubCommandLastSelection
    STA SubCommandSelection

RedrawSubCommandSelection:
    JMP UpdateSubCommandMenu

ExitSubCommandMenu:
    LDA #$FF
    STA PauseMode
    STA PreviousController2Buttons
    JSR StopAudioStreams
    JSR ClearSoundEffectRequests
    JMP FinalizeRoomLoad

ExecuteSubCommandSelection:
    LDX SubCommandSelection
    BEQ ResetCurrentRoomFromSubCommand
    DEX
    BEQ ReturnToPreviousRoomFromSubCommand
.if CASTLEQUEST_USA
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
.else
    DEX
    BEQ ExecuteSubCommandLoad
    DEX
    BEQ ExecuteSubCommandSave
.endif
    BNE ExitSubCommandMenu

ExecuteSubCommandLoad:
    JMP LoadGameState

ExecuteSubCommandSave:
    JMP SaveGameState

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

ResetCurrentRoomFromSubCommand:
    LDA PlayerLives
    BNE BeginSubCommandCurrentRoomReset
    JMP UpdateSubCommandMenu

BeginSubCommandCurrentRoomReset:
    JSR LoadRoomPersistentState
    LDX #$0D

CopySubCommandCurrentRoomState:
    LDA RoomRuntimeLoadMirror,X
    STA SubCommandActiveRoomRuntimeState,X
    DEX
    BPL CopySubCommandCurrentRoomState

RestoreSubCommandPlayerState:
    LDA SubCommandActiveRoomRuntimeState + $0B
    STA PlayerXLo
    LDA SubCommandActiveRoomRuntimeState + $0C
    STA PlayerXHi
    LDA SubCommandActiveRoomRuntimeState + $0D
    STA PlayerY
    DEC PlayerLives
    LDA #$00
    STA SubCommandScreenState
    JMP RebuildLoadedRoom

ReturnToPreviousRoomFromSubCommand:
    LDA PlayerLives
    BNE CheckSubCommandPreviousRoomSnapshot
    JMP UpdateSubCommandMenu

CheckSubCommandPreviousRoomSnapshot:
    LDA RoomStateSnapshotA
    BNE BeginSubCommandPreviousRoomRestore
    JMP UpdateSubCommandMenu

BeginSubCommandPreviousRoomRestore:
    STA CurrentRoomNumber
    JSR RestoreRoomStateSnapshotA
    LDX #$0D

CopySubCommandPreviousRoomState:
    LDA RoomRuntimeStateSnapshotA,X
    STA SubCommandActiveRoomRuntimeState,X
    DEX
    BPL CopySubCommandPreviousRoomState
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    BEQ RestoreSubCommandPlayerState
