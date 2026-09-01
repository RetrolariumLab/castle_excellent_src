; New-game state and persistent-region initialization
; CPU range $A2B1-$A350
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

InitializeNewGame:
    LDA #InitialRoomNumber
    STA CurrentRoomIndex
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
    LDA CurrentRoomIndex
    STA CurrentRoomState
    LDA #InitialPlayerY
    STA PlayerY
    STA NewGameRuntimeState + $0D
