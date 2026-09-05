; Evidence-backed RAM aliases from the published Castle Excellent analysis
; These definitions do not yet rewrite operands in the raw preservation payload

HighScoreLo = $0001
HighScoreHi = $0002
PlayerInventoryCounts = $0005
PlayerScoreLo = $000B
PlayerScoreHi = $000C
PlayerHazardProtectionCountdown = $000D
PlayerInvulnerabilityCountdown = $000E
PlayerCollisionHazardProtectionCountdown = $000D
PlayerDeathInvulnerabilityCountdown = $000E
PlayerLives = $0013

CurrentRoomNumber = $0037
PlayerXLo = $0038
PlayerXHi = $0039
PlayerY = $003A
PlayerOnHazardCell = $077C
PlayerCollisionHazardCellContact = $077C
CurrentObjectOffset = $0041
CurrentRuntimeObjectOffset = $0043

; Contextual runtime-object dispatcher state at $9583-$95BE
RuntimeObjectHandlerPointerLo = $0031
RuntimeObjectHandlerPointerHi = $0032
RuntimeObjectUpdateSharedFlag = $07C6

; Contextual player collision-result dispatch at $9477-$949B
PlayerCollisionHandlerPointerLo = $0031
PlayerCollisionHandlerPointerHi = $0032

; Contextual result buffer for controller polling at $80FF-$8157
PolledControllerButtons = $0020

; Contextual Famicom data-I/O state at $8000-$8224
DataIoByte = $0017
DataIoSavedX = $001A
DataIoTransportMode = $001F
PulseAccumulatedWidth = $002D
PulseBitsRemaining = $002E
PulsePreamblePageCount = $002F
PulseInputLevel = $0030

AudioTempoOffset = $00DA
AudioStreamPointerLo = $00DB
AudioStreamPointerHi = $00DC
AudioStreamTicksRemaining = $00DD
AudioStreamOctaveOffset = $00DE
AudioStreamStateSize = $04
AudioStreamCount = 3
AudioPulseParameters = $00E7
AudioDefaultLengthIndices = $00E9

; Frame and NMI scheduler state
FrameCounter = $0000
NmiTaskIndex = $00F8
NmiTaskHandlerPointerLo = $00F9
NmiTaskHandlerPointerHi = $00FA
OamStagingBusy = $00FB
NmiFrameCountdown = $00FC

FrameCounterModulo3A = $0763
FrameCounterModulo5 = $0764
FrameCounterModulo6 = $0765
FrameCounterModulo7 = $0766
FrameCounterModulo3B = $0767
FrameCounterModulo10 = $0768
FrameCounterModulo11 = $0769
FrameCounterModulo30 = $076A
RoomFrameCounter = $076B
PlayerTransitionCountdown = $0772
StatusInventoryTiles = $076C
StatusInventoryTileCount = 6

; Contextual horizontal-scroll latches in the NMI frame handler
PendingScrollX = $0034
AppliedScrollX = $0035
ScrollUpdatePending = $0036
Controller1Buttons = $0775
Controller2Buttons = $0776
PreviousController1Buttons = $0777
PreviousController2Buttons = $0778
PowerOnSignatureRam = $077E
ResetCounterLo = $0783
ResetCounterHi = $0784
PauseMode = $07C4
PauseModeInactive = $00
PauseModeActive = $FF
CastleMapMode = $07C5
DemoPlaybackActive = $07C7
PhysicalController1Buttons = $07CE

RuntimeObjectRecords = $004A
RuntimeObjectXLo = $004B
RuntimeObjectXHi = $004C
RuntimeObjectY = $004D
RuntimeObjectState = $004E
RuntimeObjectByte5 = $004F
RuntimeObjectRecordSize = $06
RuntimeObjectRecordBytes = $90
RuntimeObjectRecordCount = 24
RuntimeObjectTypeIndexMask = $7F
RuntimeObjectVisibleYLimit = $A0
RoomCellSampleY = $001B
RoomCellSampleXLo = $0027
RoomCellSampleXHi = $0028
RoomCellSampleColumnLo = $0029
RoomCellSampleColumnHi = $002A
RoomCellSamplePointerLo = $002B
RoomCellSamplePointerHi = $002C
PlayerCollisionSampleY = $001B
PlayerCollisionObjectIndex = $001D
PlayerCollisionSampleXLo = $0027
PlayerCollisionSampleXHi = $0028
PlayerCollisionSampleColumn = $0029
PlayerCollisionCellPointerLo = $002B
PlayerCollisionCellPointerHi = $002C
PlayerCollisionDeltaXLo = $002B
PlayerCollisionDeltaXHi = $002C
PlayerCollisionMotionState = $003C
PlayerCollisionObjectFilterActive = $07CB
PlayerCollisionAnimationCounter = $0040
PlayerCollisionScreenYFirst = $10
PlayerCollisionScreenYEnd = $B0
PlayerCollisionScreenXEndLo = $40
PlayerCollisionRuntimeTypeEnd = $A8
PlayerCollisionSpecialRuntimeType = $86
PlayerCollisionSpecialPhaseThreshold = $08
ObjectSpanXLo = $0044
ObjectSpanXHi = $0045
ObjectSpanY = $0046
ObjectSpanWidth = $0047
ObjectSpanBoundaryXLo = $0048
ObjectSpanBoundaryXHi = $0049
PlayerObjectVerticalSpan = $10
PlayerObjectLeftReach = $0F
RuntimeObjectType32StateParityMask = $01
RuntimeObjectType40StateLimit = $0F
RuntimeOverlapSpanXLo = $0044
RuntimeOverlapSpanXHi = $0045
RuntimeOverlapSpanY = $0046
RuntimeOverlapSpanWidth = $0047
RuntimeOverlapBoundaryXLo = $0048
RuntimeOverlapBoundaryXHi = $0049
RuntimeOverlapTypeEnd = $A8
CollisionSampleY = $001B
CollisionSampleObjectIndex = $001D
CollisionSampleXLo = $0027
CollisionSampleXHi = $0028
CollisionSampleColumn = $0029
CollisionSampleShiftXHi = $002A
CollisionSampleCellPointerLo = $002B
CollisionSampleCellPointerHi = $002C
CollisionSampleDeltaXLo = $002B
CollisionSampleDeltaXHi = $002C
CollisionSampleAnimationCounter = $0040
CollisionSampleObjectOffset = $0042
RoomCollisionSampleCellPointerLo = $002B
RoomCollisionSampleCellPointerHi = $002C
EmptyRoomCell = $53
ObjectPlayerDeltaXLo = $0025
ObjectPlayerDeltaXHi = $0026
ObjectPlayerProximityYOffset = $10
ObjectPlayerProximityYLimit = $04
ObjectPlayerProximityXLimit = $05

; Contextual paused-scroll state at $A8E3-$A959
PausedScrollX = $0034
PausedScrollUpdatePending = $0036
PauseScrollStep = $04
PauseScrollMinimum = $00
PauseScrollMaximum = $80
PauseScrollUpdateRequested = $FF

RoomCellCollisionTypeCount = 100
RoomCellCollisionHalfCount = 2
RuntimeObjectCollisionTypeFirst = $80
RuntimeObjectCollisionDimensionCount = 48

RoomAttributeScratch = $0100
RoomAttributeScratchSize = $80
NametableAttributeTableSize = $40
InitialRoomAttributeCount = $10

OamDmaBuffer = $0200
OamStagingBuffer = $0300
OamSpriteSize = 4
OamSpriteCount = 64
OamBufferSize = $100
OamInterleaveBlockSize = $20
OamInterleaveBlockCount = 8
OamRotationFrameCount = 8
OamHiddenY = $F0
FirstObjectOamStagingOffset = $0C
ObjectSpriteHandlerCount = 42
PlayerActionSpriteTile = $CA
PlayerRightActionSpriteAttributes = $03
PlayerLeftActionSpriteAttributes = $43

; Contextual frame-sprite state at $AC13-$ADE6
OamStagingWriteOffset = $0016
ObjectSpriteHandlerPointerLo = $0031
ObjectSpriteHandlerPointerHi = $0032
PlayerSpriteDirection = $003B
PlayerSpriteMotionState = $003C
PlayerSpriteMotionPhase = $003E
PlayerActionCountdown = $0779

; Contextual metasprite-renderer state at $B1D6-$B4B5
PlayerMetaspriteDeadReadState = $0018
MetaspriteScreenX = $001B
MetaspritePointerLo = $0021
MetaspritePointerHi = $0022
MetaspriteWorldXLo = $002B
MetaspriteWorldXHi = $002C
MetaspritePendingScrollX = $0034
ObjectMetaspriteYBias = $37
PlayerMetaspriteYBias = $27
ObjectSpriteWorldX = $20
SecondStandardObjectSpriteWorldX = $28
ThirdWideObjectSpriteWorldX = $30
FourthWideObjectSpriteWorldX = $38
SecondCompactObjectSpriteWorldX = $24
MetaspriteDescriptorBytesPerSprite = 2
HardwareSpriteWidth = 8

; Contextual OAM interleave scratch at $C6B9-$C79C
OamOutputBlockIndex = $0020

RoomCells = $0400
RoomWidth = 20
RoomHeight = 20
RoomCellCount = 400
RoomCellPointerRowMask = $7F
RoomCellPointerRowDivisor = 5
DecrementingAnimatedCellFirst = $35
DecrementingAnimatedCellEnd = $41
DecrementingAnimatedCellRedrawEnd = $39
SlowAnimatedCellFirst = $45
SlowAnimatedCellEnd = $49
IncrementingAnimatedCellFirst = $56
IncrementingAnimatedCellEnd = $62
IncrementingAnimatedCellRedrawEnd = $5A
RoomCellSlowAnimationDividerMask = $03
CollisionCellPairIndexFirst = $8A
CollisionCellPairIndexEnd = $92
CollisionCellPairMatched = $00
CollisionCellPairNotMatched = $FF

RoomMutableCellPersistentState = $0590
RoomMutableCellPersistentStateBytes = $6C
RoomMutableCellStateBitLimit = $28
RoomObjectPersistentState = $0608
RoomObjectPersistentStateBytes = $8D
RoomVisitedFlags = $069E
RoomVisitedFlagCount = 100

RoomBitLookahead = $0702
RoomBitLookaheadSize = 16

CurrentRoomState = $0712
CurrentRoomObjectState = $0713
CurrentRoomMutableCellState = $0716
RoomStateLoadMirror = $071B
RoomStateSnapshotA = $0724
RoomObjectStateSnapshotA = $0725
RoomMutableCellStateSnapshotA = $0728
RoomStateSnapshotB = $072D
RoomObjectStateSnapshotB = $072E
RoomMutableCellStateSnapshotB = $0731
RoomStateRecordSize = 9
RoomRuntimeLoadMirror = $0736
RoomRuntimeStateSnapshotA = $0745
RoomRuntimeStateSnapshotB = $0754
RoomRuntimeSnapshotSize = 14
RoomRuntimeLoadMirrorSize = 15

; Contextual save/load serialization views at $FBFE-$FDC4
SaveLoadRuntimeState = $0005
SaveLoadPpuStringPointerLo = $0021
SaveLoadPpuStringPointerHi = $0022
SaveLoadScreenState = $07CD
SaveRuntimeStateSize = 14
SaveMutableRegion = $0590
SaveMutableRegionSize = $78
SaveObjectRegion = $0608
SaveObjectRegionSize = $96
SaveDataSignatureSize = 8
NewGameRuntimeStateSize = 14
NewGameRoomStateClearSize = 27
InitialRoomNumber = $47
InitialPlayerLives = 3
InitialPlayerY = $98

; Contextual room-cell coordinate and mutable restoration scratch
RoomCellPointerLo = $002B
RoomCellPointerHi = $002C
MutableCellTileColumn = $0021
MutableCellTileRow = $0022
RestoredMutableCellOrdinal = $001F
MutableCellRestorePointerLo = $0029
MutableCellRestorePointerHi = $002A
RestoredMutableCellAddressLo = $0044
RestoredMutableCellAddressHi = $0045
RoomCellUpdateAddressLo = $0044
RoomCellUpdateAddressHi = $0045
MutableCellActionProbeY = $001E
MutableCellActionInventoryCounts = $0005
MutableCellActionProbeXLo = $0021
MutableCellActionProbeXHi = $0022
MutableCellActionDirection = $003B
MutableCellActionMotionState = $003C
MutableCellActionMotionPhase = $003E
MutableCellActionMovementDelay = $003F
MutableCellActionProbeYOffset = $10
MutableCellActionLeftBoundaryLo = $11
MutableCellActionLeftBoundaryHi = $00
MutableCellActionRightBoundaryLo = $20
MutableCellActionRightBoundaryHi = $01
MutableCellActionDelayFrames = 9
PlayerMotionInactiveThreshold = $21
PlayerMotionInactive = $00
MutableCellActionAlignmentMask = $0F
MutableCellActionAlignedRemainder = $08
CastleRoomColumns = 10
CastleRoomRows = 10
FirstRoomWithAboveNeighbor = 11
FirstBottomRowRoomNumber = 91
AdjacentRoomNumberStep = 1
PlayerProtectionTickMask = $1F
PlayerHazardProbeXOffset = 7
PlayerHazardProbeYOffset = 8
PlayerHazardProbeTopBoundary = $10
PlayerHazardProbeBottomBoundary = $B0
PlayerHazardProbeRightBoundaryLo = $40
PlayerHazardProbeRightBoundaryHi = $01
PlayerHazardProbeRoomYOffset = $10
PlayerHazardContactInactive = $00
PlayerHazardContactActive = $FF
HazardRoomCell = $16
RestoredHazardRoomCellTop = $62
RestoredHazardRoomCellBottom = $63
HazardCellColumnOffset = $0029
HazardCellRowPointerLo = $002B
TransitionPlayerXLo = $0010
TransitionPlayerXHi = $0011
TransitionPlayerY = $0012
TransitionHazardProtectionCountdown = $000D
TransitionInvulnerabilityCountdown = $000E
TransitionHazardProtectionMirror = $0014
TransitionInvulnerabilityMirror = $0015
PlayerTransitionScreenState = $07CD
ReloadRoomObjectStateBits = $0016
ReloadRoomMutableCellStateBits = $0019

NmiTaskRequests = $0785
NmiTaskRequestCount = 23
NmiTaskPending = $FF
StatusScoreTiles = $079D
StatusScoreTileCount = 5
StatusScoreBufferSize = 8
StatusScoreTerminator = $07A2
StatusLivesTiles = $07A5
StatusLivesFormattedTileCount = 3
StatusLivesUploadedTileCount = 2
StatusTilesBusy = $07C8
StatusTilesReady = $00
StatusTilesLocked = $FF
StatusDigitTileZero = $60
StatusBlankTile = $FF
StatusInventoryMaxValue = 9
DecimalHundreds = 100
DecimalTens = 10
GameOverActive = $07CC
Pulse1SoundEffectBusy = $07D0
Pulse2SoundEffectBusy = $07D1
TriangleSoundEffectBusy = $07D2
NoiseSoundEffectBusy = $07D3

CastleMapRoomCount = 100
CastleMapColumns = 10
CastleMapModeActive = $1E
CastleMapAvailable = $000F
CastleMapRoomIndex = $001F
CastleMapPpuAddressLo = $0021
CastleMapPpuAddressHi = $0022

; Contextual room-audio selection aliases at $A38A-$A3AB
RoomHazardProtectionMusicCondition = $000D
RoomInvulnerabilityMusicCondition = $000E

; Contextual new-game state at $A2B1-$A350
NewGameRuntimeState = $0005
NewGameTransitionState = $0014
NewGamePlayerMotionState = $003C
NewGamePlayerCellState = $077C
NewGamePlayerMotionCounterA = $07C9
NewGamePlayerMotionCounterB = $07CA
NewGameCollisionProbeState = $07CB
NewGameScreenState = $07CD

; Contextual room-palette pointer at $A351-$A35B
RoomPalettePointerLo = $0021
RoomPalettePointerHi = $0022

; Contextual room-runtime reset state at $A3AC-$A3C5
ResetPlayerMovementStateA = $003B
ResetPlayerMovementDelay = $003F
ResetPendingScrollX = $0034
ResetAppliedScrollX = $0035
ResetPlayerMovementLatch = $0774
ResetRuntimeObjectUpdateSharedFlag = $07C6
ResetPlayerMovementStateB = $003C
ResetRoomCellAnimationCounter = $0040

; Contextual room-cell animation scan at $A3D2-$A47E
AnimatedRoomCellPointerLo = $0021
AnimatedRoomCellPointerHi = $0022
RoomCellAnimationCounter = $0040
AnimatedRoomCellUpdateAddressLo = $0044
AnimatedRoomCellUpdateAddressHi = $0045

; Contextual 16-bit decimal remainder at $A497-$A4DA
ScoreRemainderLo = $0003
ScoreRemainderHi = $0004

; Contextual zero-terminated PPU tile pointer at $B6C9-$B77B
PpuTileStringPointerLo = $0021
PpuTileStringPointerHi = $0022

; Contextual live gameplay state copied by $EC63-$ECB6
ActiveRoomRuntimeState = $0005

; Contextual scratch aliases proven inside the room decoder at $E7EC-$E8DE
RoomDecoderBitIndex = $0016
RoomLookaheadWriteIndex = $0017
DecodedRoomCell = $0019
RoomStreamPointerLo = $0021
RoomStreamPointerHi = $0022
RoomCodePointerLo = $0023
RoomCodePointerHi = $0024
RoomOutputOffsetLo = $0025
RoomOutputOffsetHi = $0026
RoomOutputPointerLo = $0029
RoomOutputPointerHi = $002A

; Contextual scratch aliases proven inside the attribute builder at $E8DF-$EA35
RoomAttributeByteOffset = $0025
RoomAttributeQuadrantIndex = $0026
RoomAttributeRow = $0016
RoomAttributeColumn = $0017
RoomCellRowPointerLo = $0023
RoomCellRowPointerHi = $0024
RoomAttributePreservedBits = $0025

; Contextual scratch aliases proven inside the room-object loader at $EBE9-$EC62
RoomObjectXHighScratch = $001A
RoomObjectStreamPointerLo = $0021
RoomObjectStreamPointerHi = $0022

; Contextual state application and cell-object creation at $ECB7-$EDD1
AppliedRoomObjectStateBits = $0016
AppliedRoomMutableCellStateBits = $0019
MutableCellStateBitIndex = $001E
CellObjectRecordOffset = $0016
SpawnedCellObjectType = $0017
SpawnCellRow = $0018
RoomCellScanPointerLo = $0021
RoomCellScanPointerHi = $0022
SpawnCellColumnOffsetLo = $0023
SpawnCellColumnOffsetHi = $0024

; Output pointer of SeekRoomObjectStream at $EDD2-$EDEE
SoughtRoomObjectPointerLo = $0021
SoughtRoomObjectPointerHi = $0022

; Contextual mutable-cell scan at $EDEF-$EE55
MutableCellScanPointerLo = $0029
MutableCellScanPointerHi = $002A

; Contextual unpacked state bytes at $EE56-$EF05
LoadedRoomObjectStateBits = $0016
LoadedRoomMutableCellStateBits = $0019

; NMI task requests 21 and 22 upload the left and right room attribute tables
NmiRoomAttributesLeftRequest = $079A
NmiRoomAttributesRightRequest = $079B
