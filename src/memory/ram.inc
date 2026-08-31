; Evidence-backed RAM aliases from the published Castle Excellent analysis
; These definitions do not yet rewrite operands in the raw preservation payload

CurrentRoomIndex = $0037
CurrentObjectOffset = $0041

AudioTempoOffset = $00DA
AudioStreamPointerLo = $00DB
AudioStreamPointerHi = $00DC
AudioStreamTicksRemaining = $00DD
AudioStreamOctaveOffset = $00DE
AudioStreamStateSize = $04
AudioStreamCount = 3
AudioPulseParameters = $00E7
AudioDefaultLengthIndices = $00E9

Controller1Buttons = $0775
Controller2Buttons = $0776

RuntimeObjectRecords = $004A
RuntimeObjectXLo = $004B
RuntimeObjectXHi = $004C
RuntimeObjectY = $004D
RuntimeObjectState = $004E
RuntimeObjectByte5 = $004F
RuntimeObjectRecordSize = $06
RuntimeObjectRecordBytes = $90
RuntimeObjectRecordCount = 24

RoomAttributeScratch = $0100
RoomAttributeScratchSize = $80
NametableAttributeTableSize = $40
InitialRoomAttributeCount = $10

OamDmaBuffer = $0200
OamStagingBuffer = $0300

RoomCells = $0400
RoomWidth = 20
RoomHeight = 20
RoomCellCount = 400

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

NmiTaskRequests = $0785
NmiTaskRequestCount = 23
StatusScoreTiles = $079D
StatusScoreTerminator = $07A2

; Contextual room-audio selection aliases at $A38A-$A3AB
RoomMusicTrack1Condition = $000D
RoomMusicTrack3Condition = $000E
SuppressRoomMusicSelection = $0772
KeepRoomAudioPlaying = $07C7

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
