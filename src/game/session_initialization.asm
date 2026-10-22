; New game, room initialization, animation, and status formatting
; Original CPU range $A2B1-$A589

InitializeNewGame:
    LDA #InitialRoomNumber
    STA CurrentRoomNumber
    LDA #InitialPlayerLives
    STA PlayerLives
    LDA #$00
    STA GameOverActive
    STA NewGameCollisionProbeState
    STA CurrentRoomState
    STA RoomStateLoadMirror
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    STA NewGameRuntimeState + $06
    STA NewGameRuntimeState + $07
    STA PlayerTransitionCountdown
    STA PauseMode
    STA CastleMapMode
    STA NewGameRuntimeState + $0A
    STA NewGameRuntimeState + $08
    STA NewGameRuntimeState + $09
    STA NewGamePlayerCellState
    STA NewGamePlayerMotionState
    STA NewGamePlayerMotionCounterA
    STA NewGamePlayerMotionCounterB
    STA NewGameScreenState
    STA Pulse1SoundEffectBusy
    STA Pulse2SoundEffectBusy
    STA TriangleSoundEffectBusy
    STA NoiseSoundEffectBusy
    LDA #$FF
    STA StatusTilesBusy
    LDA #$00
    STA NewGameRuntimeState
    STA NewGameRuntimeState + $01
    STA NewGameRuntimeState + $02
    STA NewGameRuntimeState + $03
    STA NewGameRuntimeState + $05
    STA NewGameRuntimeState + $04
    LDA #$00
    STA PlayerXHi
    STA NewGameRuntimeState + $0C
    STA PlayerXLo
    STA NewGameRuntimeState + $0B
    STA NewGameTransitionState
    LDX #(NewGameRuntimeStateSize - 1)

CopyInitialRuntimeState:
    LDA NewGameRuntimeState,X
    STA RoomRuntimeLoadMirror,X
    STA RoomRuntimeStateSnapshotA,X
    DEX
    BPL CopyInitialRuntimeState
    LDX #SaveMutableRegionSize

ClearNewGameMutableState:
    STA SaveMutableRegion - 1,X
    DEX
    BNE ClearNewGameMutableState
    LDX #SaveObjectRegionSize

ClearNewGameObjectState:
    STA SaveObjectRegion - 1,X
    DEX
    BNE ClearNewGameObjectState
    LDX #NewGameRoomStateClearSize

ClearNewGameRoomState:
    STA CurrentRoomState - 1,X
    DEX
    BNE ClearNewGameRoomState
    LDX #RoomVisitedFlagCount

ClearNewGameVisitedRooms:
    STA RoomVisitedFlags - 1,X
    DEX
    BNE ClearNewGameVisitedRooms
    LDA CurrentRoomNumber
    STA CurrentRoomState
    LDA #InitialPlayerY
    STA PlayerY
    STA NewGameRuntimeState + $0D

UploadRoomPalette:
    LDA #>RoomPaletteData
    STA RoomPalettePointerHi
    LDA #<RoomPaletteData
    STA RoomPalettePointerLo
    JMP UploadPaletteFromPointer

LoadRoom:
    JSR DisableNmi
    LDX CurrentRoomNumber
    LDA #$FF
    STA RoomVisitedFlags - 1,X
    LDA #$00
    LDX #RuntimeObjectRecordBytes

ClearRoomRuntimeObjects:
    STA RuntimeObjectRecords - 1,X
    DEX
    BNE ClearRoomRuntimeObjects
    LDX CurrentRoomNumber
    DEX
    JSR DecodeRoom
    JSR LoadRoomObjectsAndState
    JSR ResetNmiTaskRequests
    JSR ClearRoomNametablesAndSprites
    JSR InitializeRoomStatusDisplay
    JSR BuildRoomAttributeTables
    JSR UploadRoomAttributeTables
    JSR ResetRoomRuntimeState

SelectRoomAudio:
    LDA DemoPlaybackActive
    BNE CheckRoomMusicSuppression
    JSR StopAudioStreams
    JSR ClearSoundEffectRequests

CheckRoomMusicSuppression:
    LDA PlayerTransitionCountdown
    BEQ CheckRoomMusicTrack3
    RTS

CheckRoomMusicTrack3:
    LDA RoomInvulnerabilityMusicCondition
    BEQ CheckRoomMusicTrack1
    JMP LoadAudioTrackSet3

CheckRoomMusicTrack1:
    LDA RoomHazardProtectionMusicCondition
    BEQ SelectDefaultRoomMusic
    JMP LoadAudioTrackSet1

SelectDefaultRoomMusic:
    JMP LoadAudioTrackSet0

ResetRoomRuntimeState:
    LDA #$00
    STA ResetPlayerMovementStateA
    STA ResetPlayerMovementDelay
    STA NmiTaskIndex
    STA PendingScrollX
    STA AppliedScrollX
    STA ResetPlayerMovementLatch
    STA ResetRuntimeObjectUpdateSharedFlag
    STA ResetPlayerMovementStateB
    STA RoomFrameCounter
    STA ResetRoomCellAnimationCounter
    RTS

EnsureRoomAudioPlaying:
    LDA GameOverActive
    BNE ReturnWithoutRoomAudioRestart
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BEQ SelectRoomAudio

ReturnWithoutRoomAudioRestart:
    RTS

AnimateRoomCells:
    JSR AnimateFastRoomCells
    LDA RoomFrameCounter
    LSR A
    BCC ReturnRoomCellAnimation
    INC RoomCellAnimationCounter
    BMI ReturnRoomCellAnimation
    LDA RoomCellAnimationCounter
    AND #RoomCellSlowAnimationDividerMask
    BNE ReturnRoomCellAnimation
    LDA #>RoomCells
    STA AnimatedRoomCellPointerHi
    LDA #<RoomCells
    STA AnimatedRoomCellPointerLo

ScanSlowAnimatedRoomCells:
    LDY #$00
    LDA (AnimatedRoomCellPointerLo),Y
    CMP #SlowAnimatedCellFirst
    BCC AdvanceSlowRoomCellScan
    CMP #SlowAnimatedCellEnd
    BCS AdvanceSlowRoomCellScan
    TAX
    LDA SlowRoomCellAnimationFrames - SlowAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate

AdvanceSlowRoomCellScan:
    INC AnimatedRoomCellPointerLo
    BNE CheckSlowRoomCellScanEnd
    INC AnimatedRoomCellPointerHi

CheckSlowRoomCellScanEnd:
    LDA AnimatedRoomCellPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA AnimatedRoomCellPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanSlowAnimatedRoomCells

ReturnRoomCellAnimation:
    RTS

SlowRoomCellAnimationFrames:
    .byte $46, $47, $48, $45

AnimateFastRoomCells:
    LDA RoomFrameCounter
    LSR A
    BCC ReturnFastRoomCellAnimation
    LDA #>RoomCells
    STA AnimatedRoomCellPointerHi
    LDA #<RoomCells
    STA AnimatedRoomCellPointerLo

ScanFastAnimatedRoomCells:
    LDY #$00
    LDA (AnimatedRoomCellPointerLo),Y
    CMP #DecrementingAnimatedCellFirst
    BCC CheckIncrementingAnimationRange
    CMP #DecrementingAnimatedCellEnd
    BCS CheckIncrementingAnimationRange
    TAX
    LDA DecrementingRoomCellAnimationFrames - DecrementingAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    CPX #DecrementingAnimatedCellRedrawEnd
    BCS AdvanceFastRoomCellScan
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate
    JMP AdvanceFastRoomCellScan

CheckIncrementingAnimationRange:
    CMP #IncrementingAnimatedCellFirst
    BCC AdvanceFastRoomCellScan
    CMP #IncrementingAnimatedCellEnd
    BCS AdvanceFastRoomCellScan
    TAX
    LDA IncrementingRoomCellAnimationFrames - IncrementingAnimatedCellFirst,X
    STA (AnimatedRoomCellPointerLo),Y
    CPX #IncrementingAnimatedCellRedrawEnd
    BCS AdvanceFastRoomCellScan
    LDA AnimatedRoomCellPointerLo
    STA AnimatedRoomCellUpdateAddressLo
    LDA AnimatedRoomCellPointerHi
    STA AnimatedRoomCellUpdateAddressHi
    JSR RequestRoomCellRowUpdate

AdvanceFastRoomCellScan:
    INC AnimatedRoomCellPointerLo
    BNE CheckFastRoomCellScanEnd
    INC AnimatedRoomCellPointerHi

CheckFastRoomCellScanEnd:
    LDA AnimatedRoomCellPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA AnimatedRoomCellPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanFastAnimatedRoomCells

ReturnFastRoomCellAnimation:
    RTS

DecrementingRoomCellAnimationFrames:
    .byte $38, $35, $36, $37, $3C, $39, $3A, $3B, $40, $3D, $3E, $3F

IncrementingRoomCellAnimationFrames:
    .byte $57, $58, $59, $56, $5B, $5C, $5D, $5A, $5F, $60, $61, $5E

FormatHighScoreStatusTiles:
    JSR BeginStatusTileFormatting
    LDA HighScoreLo
    STA ScoreRemainderLo
    LDA HighScoreHi
    STA ScoreRemainderHi
    JMP FormatSelectedScore

FormatPlayerStatusTiles:
    JSR BeginStatusTileFormatting
    LDA PlayerScoreLo
    STA ScoreRemainderLo
    LDA PlayerScoreHi
    STA ScoreRemainderHi

FormatSelectedScore:
    LDX #$00

StartNextScoreDigit:
    SEC

SubtractScorePlaceValue:
    LDA ScoreRemainderLo
    SBC DecimalPlaceValueLowBytes,X
    STA ScoreRemainderLo
    LDA ScoreRemainderHi
    SBC DecimalPlaceValueHighBytes,X
    STA ScoreRemainderHi
    BCC RestoreScoreRemainder
    INC StatusScoreTiles,X
    BCS SubtractScorePlaceValue

RestoreScoreRemainder:
    LDA ScoreRemainderLo
    ADC DecimalPlaceValueLowBytes,X
    STA ScoreRemainderLo
    LDA ScoreRemainderHi
    ADC DecimalPlaceValueHighBytes,X
    STA ScoreRemainderHi
    INX
    CPX #StatusScoreTileCount
    BCC StartNextScoreDigit
    LDX #(StatusScoreTileCount - 1)

EncodeScoreDigitTiles:
    LDA StatusScoreTiles,X
    CLC
    ADC #StatusDigitTileZero
    STA StatusScoreTiles,X
    DEX
    BPL EncodeScoreDigitTiles
    LDX #$00

BlankLeadingScoreZeroes:
    LDA StatusScoreTiles,X
    CMP #StatusDigitTileZero
    BNE FormatLivesStatusTiles
    LDA #StatusBlankTile
    STA StatusScoreTiles,X
    INX
    CPX #StatusScoreTileCount
    BCC BlankLeadingScoreZeroes

FormatLivesStatusTiles:
    LDA #StatusDigitTileZero
    STA StatusLivesTiles
    STA StatusLivesTiles + $01
    STA StatusLivesTiles + $02
    LDA PlayerLives

CountLifeHundreds:
    CMP #DecimalHundreds
    BCC CountLifeTens
    SBC #DecimalHundreds
    INC StatusLivesTiles + $02
    JMP CountLifeHundreds

CountLifeTens:
    CMP #DecimalTens
    BCC EncodeLifeOnes
    SBC #DecimalTens
    INC StatusLivesTiles + $01
    JMP CountLifeTens

EncodeLifeOnes:
    CLC
    ADC #StatusDigitTileZero
    STA StatusLivesTiles
    LDX #(StatusLivesFormattedTileCount - 1)

BlankLeadingLifeZeroes:
    LDA StatusLivesTiles,X
    CMP #StatusDigitTileZero
    BNE FormatInventoryStatusTiles
    LDA #StatusBlankTile
    STA StatusLivesTiles,X
    DEX
    BNE BlankLeadingLifeZeroes

FormatInventoryStatusTiles:
    LDX #(StatusInventoryTileCount - 1)

ClampNextInventoryValue:
    LDA PlayerInventoryCounts,X
    CMP #StatusInventoryMaxValue
    BCC EncodeInventoryTile
    LDA #StatusInventoryMaxValue

EncodeInventoryTile:
    CLC
    ADC #StatusDigitTileZero
    STA StatusInventoryTiles,X
    DEX
    BPL ClampNextInventoryValue
    LDA #StatusTilesReady
    STA StatusTilesBusy
    RTS

DecimalPlaceValueHighBytes:
    .byte $27, $03, $00, $00, $00

DecimalPlaceValueLowBytes:
    .byte $10, $E8, $64, $0A, $01

MutableCellStateBitMasks:
    .byte $01, $02, $04, $08, $10, $20, $40, $80

BeginStatusTileFormatting:
    LDA #StatusTilesLocked
    STA StatusTilesBusy
    LDA #$00
    LDX #(StatusScoreBufferSize - 1)

ClearStatusScoreBuffer:
    STA StatusScoreTiles,X
    DEX
    BPL ClearStatusScoreBuffer
    RTS

UnreferencedBitIndexHelperBytes:
    .byte $85, $1B, $29, $07, $A8, $A5, $1B, $86, $1B, $46, $1B, $6A, $46, $1B, $6A, $46
    .byte $1B, $6A, $AA, $B9, $5B, $A5, $60
