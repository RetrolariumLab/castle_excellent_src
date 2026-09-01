; Persistent state application and room-cell object creation
; CPU range $ECB7-$EDD1
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ApplyRoomPersistentState:
    LDX #$00

ApplyNextObjectStateBit:
    LSR AppliedRoomObjectStateBits + 2
    ROR AppliedRoomObjectStateBits + 1
    ROR AppliedRoomObjectStateBits
    BCC AdvanceObjectStateBit
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA RuntimeObjectState,X
    STA RuntimeObjectByte5,X

AdvanceObjectStateBit:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ApplyNextObjectStateBit
    LDX #$01
    STX MutableCellStateBitIndex

ApplyNextMutableCellStateBit:
    LDX MutableCellStateBitIndex
    LSR AppliedRoomMutableCellStateBits + 4
    ROR AppliedRoomMutableCellStateBits + 3
    ROR AppliedRoomMutableCellStateBits + 2
    ROR AppliedRoomMutableCellStateBits + 1
    ROR AppliedRoomMutableCellStateBits
    BCC AdvanceMutableCellStateBit
    JSR ApplyMutableCellStateBit

AdvanceMutableCellStateBit:
    INC MutableCellStateBitIndex
    LDX MutableCellStateBitIndex
    CPX #RoomMutableCellStateBitLimit
    BCC ApplyNextMutableCellStateBit
    LDX CurrentRoomNumber
    LDA RoomObjectCounts - 1,X
    TAX
    LDA RuntimeObjectOffsetByCount,X
    STA CellObjectRecordOffset
    LDA #>RoomCells
    STA RoomCellScanPointerHi
    LDA #<RoomCells
    STA RoomCellScanPointerLo

ScanRoomCellObjectMarkers:
    LDY #$00
    LDA (RoomCellScanPointerLo),Y
    CMP #$4B
    BNE CheckCellObjectMarker4D
    LDA #$53
    STA (RoomCellScanPointerLo),Y
    LDA #$A1
    JSR SpawnRoomCellObject
    JMP AdvanceRoomCellMarkerScan

CheckCellObjectMarker4D:
    CMP #$4D
    BNE CheckCellObjectMarker51
    LDA #$53
    STA (RoomCellScanPointerLo),Y
    LDA #$A2
    JSR SpawnRoomCellObject
    JMP AdvanceRoomCellMarkerScan

CheckCellObjectMarker51:
    CMP #$51
    BNE CheckCellObjectMarker49
    LDA #$53
    STA (RoomCellScanPointerLo),Y
    LDA #$A3
    JSR SpawnRoomCellObject
    JMP AdvanceRoomCellMarkerScan

CheckCellObjectMarker49:
    CMP #$49
    BNE CheckCellObjectMarker4A
    LDA #$53
    STA (RoomCellScanPointerLo),Y
    LDA #$A4
    JSR SpawnRoomCellObject
    JMP AdvanceRoomCellMarkerScan

CheckCellObjectMarker4A:
    CMP #$4A
    BNE AdvanceRoomCellMarkerScan
    LDA #$53
    STA (RoomCellScanPointerLo),Y
    LDA #$A5
    JSR SpawnRoomCellObject
    JMP AdvanceRoomCellMarkerScan

AdvanceRoomCellMarkerScan:
    INC RoomCellScanPointerLo
    BNE CheckRoomCellMarkerScanEnd
    INC RoomCellScanPointerHi

CheckRoomCellMarkerScanEnd:
    LDA RoomCellScanPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA RoomCellScanPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanRoomCellObjectMarkers
    RTS

SpawnRoomCellObject:
    STA SpawnedCellObjectType
    LDA RoomCellScanPointerLo
    STA SpawnCellColumnOffsetLo
    LDA RoomCellScanPointerHi
    SEC
    SBC #>RoomCells
    STA SpawnCellColumnOffsetHi
    LDA #$00
    STA SpawnCellRow

DivideCellOffsetByRoomWidth:
    LDA SpawnCellColumnOffsetLo
    CMP #RoomWidth
    LDA SpawnCellColumnOffsetHi
    SBC #$00
    BCC ScaleCellObjectCoordinates
    LDA SpawnCellColumnOffsetLo
    SEC
    SBC #RoomWidth
    STA SpawnCellColumnOffsetLo
    LDA SpawnCellColumnOffsetHi
    SBC #$00
    STA SpawnCellColumnOffsetHi
    INC SpawnCellRow
    JMP DivideCellOffsetByRoomWidth

ScaleCellObjectCoordinates:
    ASL SpawnCellRow
    ASL SpawnCellRow
    ASL SpawnCellRow
    ASL SpawnCellColumnOffsetLo
    ROL SpawnCellColumnOffsetHi
    ASL SpawnCellColumnOffsetLo
    ROL SpawnCellColumnOffsetHi
    ASL SpawnCellColumnOffsetLo
    ROL SpawnCellColumnOffsetHi
    ASL SpawnCellColumnOffsetLo
    ROL SpawnCellColumnOffsetHi
    LDX CellObjectRecordOffset
    LDA SpawnCellColumnOffsetLo
    STA RuntimeObjectXLo,X
    LDA SpawnCellColumnOffsetHi
    STA RuntimeObjectXHi,X
    LDA SpawnCellRow
    STA RuntimeObjectY,X
    LDA SpawnedCellObjectType
    STA RuntimeObjectRecords,X
    CMP #$A3
    BNE AdvanceCellObjectRecord
    LDA #$FF
    STA RuntimeObjectState,X

AdvanceCellObjectRecord:
    LDA CellObjectRecordOffset
    CLC
    ADC #RuntimeObjectRecordSize
    STA CellObjectRecordOffset
    RTS
