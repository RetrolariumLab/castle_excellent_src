; Top-level room loading and audio selection
; CPU range $A35C-$A3AB
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
    JSR ClearSoundRequests

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
