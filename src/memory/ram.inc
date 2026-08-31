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
RuntimeObjectRecordSize = $06
RuntimeObjectRecordBytes = $90
RuntimeObjectRecordCount = 24

RoomAttributeScratch = $0100
RoomAttributeScratchSize = $80

OamDmaBuffer = $0200
OamStagingBuffer = $0300

RoomCells = $0400
RoomWidth = 20
RoomHeight = 20
RoomCellCount = 400

RoomBitLookahead = $0702
RoomBitLookaheadSize = 16

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
LoadedObjectInitialState = $004E

; NMI task requests 21 and 22 upload the left and right room attribute tables
NmiRoomAttributesLeftRequest = $079A
NmiRoomAttributesRightRequest = $079B
