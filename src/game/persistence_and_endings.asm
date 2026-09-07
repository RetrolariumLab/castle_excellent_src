; Save, load, persistent snapshots, and ending sequences
; CPU range $FBFE-$FEE7
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SaveGameState:
    JSR DisableNmi
    LDA PlayerLives
    BNE CheckSaveStateAvailable
    JMP UpdateSubCommandMenu

CheckSaveStateAvailable:
    LDA RoomStateLoadMirror
    BNE BeginSaveTransfer
    JMP UpdateSubCommandMenu

BeginSaveTransfer:
    DEC PlayerLives
    JSR ClearRoomNametablesAndSprites
    LDA #>SaveTransferMessage
    STA SaveLoadPpuStringPointerHi
    LDA #<SaveTransferMessage
    STA SaveLoadPpuStringPointerLo
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR ShowBackgroundOnlyMessage
    JSR SendDataPreamble
    LDA CurrentRoomNumber
    JSR SendDataByte
    LDA RoomRuntimeLoadMirror + $0E
    JSR SendDataByte
    LDX #$00

SendSavedRuntimeState:
    LDA RoomRuntimeLoadMirror,X
    JSR SendDataByte
    INX
    CPX #SaveRuntimeStateSize
    BCC SendSavedRuntimeState
    JSR SaveRoomStateSnapshotB
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    LDX #SaveMutableRegionSize

SendSavedMutableRegion:
    LDA SaveMutableRegion - 1,X
    JSR SendDataByte
    DEX
    BNE SendSavedMutableRegion
    LDX #SaveObjectRegionSize

SendSavedObjectRegion:
    LDA SaveObjectRegion - 1,X
    JSR SendDataByte
    DEX
    BNE SendSavedObjectRegion
    LDX #RoomVisitedFlagCount

SendSavedVisitedFlags:
    LDA RoomVisitedFlags - 1,X
    JSR SendDataByte
    DEX
    BNE SendSavedVisitedFlags
    LDX #SaveDataSignatureSize

SendSaveDataSignature:
    LDA BackwardSaveSignatureText,X
    JSR SendDataByte
    DEX
    BNE SendSaveDataSignature
    JMP ExitSubCommandMenu

LoadErrorMessage:
    .byte $7C, $7F, $71, $74, $FF, $75, $82, $82, $7F, $82, $00

LoadErrorPrompt:
    .byte $80, $85, $83, $78, $FF, $71, $FF, $7F, $82, $FF, $72, $00

BackwardSaveSignatureText:
    .byte $47, $4E, $55, $54, $55, $45, $44, $45, $42

ShowLoadErrorScreen:
    JSR ClearRoomNametablesAndSprites
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    LDA #>LoadErrorMessage
    STA SaveLoadPpuStringPointerHi
    LDA #<LoadErrorMessage
    STA SaveLoadPpuStringPointerLo
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$4A
    STA PPU_ADDR
    LDA #>LoadErrorPrompt
    STA SaveLoadPpuStringPointerHi
    LDA #<LoadErrorPrompt
    STA SaveLoadPpuStringPointerLo
    JSR ShowBackgroundOnlyMessage

WaitForLoadErrorAcknowledgement:
    JSR ReadController1WithoutNmiControl
    AND #SaveLoadAcknowledgeButtons
    BEQ WaitForLoadErrorAcknowledgement
    JSR InitializeNewGame
    LDA #$00
    STA APU_STATUS
    STA SaveLoadScreenState
    JMP OpenSubCommandMenu

ShowBackgroundOnlyMessage:
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    JSR ResetPpuScroll
    STA APU_STATUS

WaitForSaveLoadVblank:
    LDA PPU_STATUS
    BPL WaitForSaveLoadVblank
    LDA #PpuMaskBackgroundOnly
    STA PPU_MASK
    JMP DisableNmi

HandleLoadFailure:
    JMP ShowLoadErrorScreen

LoadGameState:
    JSR DisableNmi
    JSR ReceiveDataPreamble
    BCS HandleLoadFailure
    JSR ClearRoomNametablesAndSprites
    LDA #>LoadTransferMessage
    STA SaveLoadPpuStringPointerHi
    LDA #<LoadTransferMessage
    STA SaveLoadPpuStringPointerLo
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR ShowBackgroundOnlyMessage
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    STA CurrentRoomNumber
    STA CurrentRoomState
    JSR ReceiveDataByte
    STA PlayerLives
    LDX #$00

ReceiveSavedRuntimeState:
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    STA SaveLoadRuntimeState,X
    INX
    CPX #SaveRuntimeStateSize
    BCC ReceiveSavedRuntimeState
    LDX #SaveMutableRegionSize

ReceiveSavedMutableRegion:
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    STA SaveMutableRegion - 1,X
    DEX
    BNE ReceiveSavedMutableRegion
    LDX #SaveObjectRegionSize

ReceiveSavedObjectRegion:
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    STA SaveObjectRegion - 1,X
    DEX
    BNE ReceiveSavedObjectRegion
    LDX #RoomVisitedFlagCount

ReceiveSavedVisitedFlags:
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    STA RoomVisitedFlags - 1,X
    DEX
    BNE ReceiveSavedVisitedFlags
    LDX #SaveDataSignatureSize

VerifySaveDataSignature:
    JSR ReceiveDataByte
    BCS HandleLoadFailure
    CMP BackwardSaveSignatureText,X
    BNE HandleLoadFailure
    DEX
    BNE VerifySaveDataSignature
    LDA #$00
    STA JOYPAD1
    STA RoomStateLoadMirror
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    LDA SaveLoadRuntimeState + $0B
    STA PlayerXLo
    LDA SaveLoadRuntimeState + $0C
    STA PlayerXHi
    LDA SaveLoadRuntimeState + $0D
    STA PlayerY

RebuildLoadedRoom:
    LDA #$00
    STA PlayerTransitionCountdown
    LDX CurrentRoomNumber
    DEX
    JSR DecodeRoom
    JSR BuildRoomAttributeTables
    JSR LoadRoomObjects
    JSR SelectAndApplyRoomState
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #$10
    TAY
    LDA PlayerXHi
    LDX PlayerXLo
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS ReturnFromSaveLoad
    JSR RestoreMutableCellByOrdinal

ReturnFromSaveLoad:
    JMP ExitSubCommandMenu

SaveRoomStateSnapshotB:
    LDA RoomStateSnapshotB
    BEQ ReturnRoomPersistentStateSaved
    TAY
    LDA RoomObjectStateOffsets,Y
    SEC
    SBC RoomObjectStateOffsets - 1,Y
    TAY
    LDX RoomStateSnapshotB
    LDA RoomObjectStateOffsets - 1,X
    TAX
    LDA RoomObjectStateSnapshotB
    STA RoomObjectPersistentState,X
    DEY
    BEQ SaveRoomMutableCellState
    LDA RoomObjectStateSnapshotB + 1
    STA RoomObjectPersistentState + 1,X
    DEY
    BEQ SaveRoomMutableCellState
    LDA RoomObjectStateSnapshotB + 2
    STA RoomObjectPersistentState + 2,X

SaveRoomMutableCellState:
    LDY RoomStateSnapshotB
    LDA RoomMutableCellStateOffsets,Y
    SEC
    SBC RoomMutableCellStateOffsets - 1,Y
    TAY
    BEQ ReturnRoomPersistentStateSaved
    LDX RoomStateSnapshotB
    LDA RoomMutableCellStateOffsets - 1,X
    TAX
    LDA RoomMutableCellStateSnapshotB
    STA RoomMutableCellPersistentState,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 1
    STA RoomMutableCellPersistentState + 1,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 2
    STA RoomMutableCellPersistentState + 2,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 3
    STA RoomMutableCellPersistentState + 3,X
    DEY
    BEQ ReturnRoomPersistentStateSaved
    LDA RoomMutableCellStateSnapshotB + 4
    STA RoomMutableCellPersistentState + 4,X

ReturnRoomPersistentStateSaved:
    RTS

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
