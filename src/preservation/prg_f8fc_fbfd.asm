; Preservation PRG before save and load orchestration
; CPU range $F8FC-$FBFD
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RunTitleScreen:
    LDA #$18
    JSR CopyChrNametablePagesToVram
    LDA #$C5
    STA $22
    LDA #$0D
    STA $21
    JSR UploadPaletteFromPointer
    LDY #$01
    JSR SelectChrBank
    JSR ResetPpuScroll
    LDX #$00
    STX $21
    STX $22
    DEX
    STX DemoPlaybackActive
    JSR Func_B7FD
    JSR LoadAudioTrackSet5
    SEI

Label_F925:
    LDA PPU_STATUS
    BPL Label_F925
    LDA #$0A
    STA PPU_MASK
    LDA #$38
    STA PPU_CTRL
    JSR ReadController1WithoutNmiControl
    EOR #$FF
    STA PreviousController1Buttons

Label_F93C:
    LDA PPU_STATUS
    BPL Label_F93C
    JSR UpdateAudioStreams
    INC $21
    BNE Label_F94A
    INC $22

Label_F94A:
    LDA $22
    CMP #$03
    BCS Label_F968
    JSR ReadController1WithoutNmiControl
    TAX
    AND PreviousController1Buttons
    AND #$08
    PHA
    TXA
    EOR #$FF
    STA PreviousController1Buttons
    PLA
    BEQ Label_F93C
    LDA #$00
    STA DemoPlaybackActive

Label_F968:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$00
    JMP SelectChrBank

CopyChrNametablePagesToVram:
    STA $16
    LDA #$20
    STA $17
    JSR ClearRoomNametablesAndSprites
    LDY #$03
    JSR SelectChrBank
    LDX #$00

Label_F983:
    LDA PPU_STATUS
    LDA $16
    STA PPU_ADDR
    STX PPU_ADDR
    LDA PPU_DATA
    LDY PPU_DATA
    LDA $17
    STA PPU_ADDR
    STX PPU_ADDR
    STY PPU_DATA
    INX
    BNE Label_F983
    INC $16
    INC $17
    LDA $17
    CMP #$24
    BCC Label_F983
    RTS

HandleSubCommandInput:
    LDA GameOverActive
    BEQ Label_F9B3
    RTS

Label_F9B3:
    LDA DemoPlaybackActive
    BEQ Label_F9B9
    RTS

Label_F9B9:
    LDA PreviousController2Buttons
    EOR #$FF
    AND Controller2Buttons
    AND #$03
    BNE OpenSubCommandMenu
    LDA Controller2Buttons
    STA PreviousController2Buttons
    RTS

OpenSubCommandMenu:
    JSR ClearRoomNametablesAndSprites
    LDA #$00
    STA JOYPAD1
    STA APU_STATUS

Label_F9D7:
    LDA PPU_STATUS
    BPL Label_F9D7
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0A
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$77
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$8D
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CD
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$93
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$83
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$88
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$98
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA #$00
    STA $1D
    LDA #$FF
    STA $1C

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
    STA $22
    LDA $1D
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ROL $22
    CLC
    ADC #$8B
    STA $21
    LDA #$21
    ADC $22
    STA PPU_ADDR
    LDA $21
    STA PPU_ADDR
    LDA #$6B
    STA PPU_DATA
    JSR ResetPpuScroll

Label_FAF5:
    LDA PPU_STATUS
    BPL Label_FAF5
    LDA #$08
    STA PPU_MASK
    JSR DisableNmi
    JSR ReadController1WithoutNmiControl
    PHA
    AND $1C
    TAY
    PLA
    EOR #$FF
    STA $1C
    TYA
    AND #$24
    BEQ Label_FB27
    INC $1D
    LDA $1D
    CMP #$05
    BCS Label_FB1E
    JMP UpdateSubCommandMenu

Label_FB1E:
    LDA #$00
    STA $1D
    BNE Label_FB27
    JMP UpdateSubCommandMenu

Label_FB27:
    TYA
    AND #$08
    BEQ Label_FB32
    LDA #$00
    STA $1F
    BEQ Label_FB62

Label_FB32:
    TYA
    AND #$01
    BEQ Label_FB3D
    LDA #$FF
    STA $1F
    BNE Label_FB62

Label_FB3D:
    TYA
    AND #$10
    BEQ Label_FB4E
    DEC $1D
    LDA $1D
    CMP #$FF
    BNE Label_FB4E
    LDA #$04
    STA $1D

Label_FB4E:
    JMP UpdateSubCommandMenu

ExitSubCommandMenu:
    LDA #$FF
    STA PauseMode
    STA PreviousController2Buttons
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JMP FinalizeRoomLoad

Label_FB62:
    LDX $1D
    BEQ Label_FBAC
    DEX
    BEQ Label_FBD6
    DEX
    BEQ Label_FB71
    DEX
    BEQ Label_FB74
    BNE ExitSubCommandMenu

Label_FB71:
    JMP LoadGameState

Label_FB74:
    JMP SaveGameState
    .byte $83, $85, $72, $FF, $73, $7F, $7D, $7D, $71, $7E, $74, $00, $7C, $7F, $71, $74
    .byte $00, $83, $71, $86, $75, $00, $82, $75, $83, $75, $84, $00, $72, $71, $73, $7B
    .byte $00, $77, $71, $7D, $75, $00

LoadTransferMessage:
    .byte $7C, $7F, $71, $74, $79, $7E, $77, $00

SaveTransferMessage:
    .byte $83, $71, $86, $79, $7E, $77, $00

Label_FBAC:
    LDA PlayerLives
    BNE Label_FBB3
    JMP UpdateSubCommandMenu

Label_FBB3:
    JSR LoadRoomPersistentState
    LDX #$0D

Label_FBB8:
    LDA RoomRuntimeLoadMirror,X
    STA $05,X
    DEX
    BPL Label_FBB8

Label_FBC0:
    LDA $10
    STA PlayerXLo
    LDA $11
    STA PlayerXHi
    LDA $12
    STA PlayerY
    DEC PlayerLives
    LDA #$00
    STA a:$07CD
    JMP RebuildLoadedRoom

Label_FBD6:
    LDA PlayerLives
    BNE Label_FBDD
    JMP UpdateSubCommandMenu

Label_FBDD:
    LDA RoomStateSnapshotA
    BNE Label_FBE5
    JMP UpdateSubCommandMenu

Label_FBE5:
    STA CurrentRoomIndex
    JSR RestoreRoomStateSnapshotA
    LDX #$0D

Label_FBEC:
    LDA RoomRuntimeStateSnapshotA,X
    STA $05,X
    DEX
    BPL Label_FBEC
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    BEQ Label_FBC0
