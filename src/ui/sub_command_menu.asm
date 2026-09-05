; Sub-command menu rendering, selection, and dispatch
; CPU range $F9CC-$FB76
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
    DEX
    BEQ ExecuteSubCommandLoad
    DEX
    BEQ ExecuteSubCommandSave
    BNE ExitSubCommandMenu

ExecuteSubCommandLoad:
    JMP LoadGameState

ExecuteSubCommandSave:
    JMP SaveGameState
