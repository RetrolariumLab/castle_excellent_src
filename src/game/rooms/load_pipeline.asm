; Room finalization, object loading, and persistent-state application
; CPU range $EB6C-$EDEE
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FinalizeRoomLoad:
    JSR ClearRoomNametablesAndSprites
    JSR UploadRoomPalette
    JSR InitializeRoomStatusDisplay
    LDA #$FF
    LDX #NmiTaskRequestCount - 1

RequestAllNmiTasks:
    STA NmiTaskRequests,X
    DEX
    BPL RequestAllNmiTasks
    JSR ResetPpuScroll
    JSR WaitForVblankAndEnableRendering
    LDA #PpuCtrlCastleMapNmi
    STA PPU_CTRL
    LDY #$00
    JMP SelectChrBank

RuntimeObjectTypeByEncodedType:
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81
    .byte $82, $83, $84, $84, $84, $84, $85, $85, $85, $85, $86, $86, $86, $86, $87, $87
    .byte $87, $87, $88, $88, $88, $88, $89, $89, $89, $89, $8A, $8B, $8C, $8D, $8E, $8F
    .byte $90

RuntimeObjectStateByEncodedType:
    .byte $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $9B, $9F, $9D, $9E, $9E, $9E
    .byte $9F, $A0, $00, $FF, $FF, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF
    .byte $FF, $00, $00, $FF, $FF, $00, $00, $00, $00

LoadRoomObjects:
    LDA #$00
    TAX

ClearRuntimeObjectRecords:
    STA RuntimeObjectRecords,X
    INX
    CPX #RuntimeObjectRecordBytes
    BCC ClearRuntimeObjectRecords
    LDX CurrentRoomNumber
    DEX
    JSR SeekRoomObjectStream
    LDX #$00

LoadNextRoomObject:
    LDY #$00
    LDA (RoomObjectStreamPointerLo),Y
    CMP #$FF
    BEQ ReturnRoomObjectsLoaded
    TAY
    LDA RuntimeObjectTypeByEncodedType,Y
    STA RuntimeObjectRecords,X
    LDA #$00
    CPY #$12
    BCC StoreRoomObjectInitialState
    CPY #$2A
    BCS StoreRoomObjectInitialState
    LDA RuntimeObjectStateByEncodedType,Y

StoreRoomObjectInitialState:
    STA RuntimeObjectState,X
    LDA #$00
    STA RoomObjectXHighScratch
    LDY #$01
    LDA (RoomObjectStreamPointerLo),Y
    ASL A
    ROL RoomObjectXHighScratch
    ASL A
    ROL RoomObjectXHighScratch
    ASL A
    ROL RoomObjectXHighScratch
    ASL A
    ROL RoomObjectXHighScratch
    STA RuntimeObjectXLo,X
    LDA RoomObjectXHighScratch
    STA RuntimeObjectXHi,X
    INY
    LDA (RoomObjectStreamPointerLo),Y
    ASL A
    ASL A
    ASL A
    STA RuntimeObjectY,X
    LDA RuntimeObjectRecords,X
    CMP #$90
    BCC AdvanceRoomObjectStream
    CMP #$96
    BCS AdvanceRoomObjectStream
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$04
    STA RuntimeObjectXLo,X
    BCC AdvanceRoomObjectStream
    INC RuntimeObjectXHi,X

AdvanceRoomObjectStream:
    LDA #$03
    CLC
    ADC RoomObjectStreamPointerLo
    STA RoomObjectStreamPointerLo
    BCC AdvanceRuntimeObjectRecord
    INC RoomObjectStreamPointerHi

AdvanceRuntimeObjectRecord:
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    JMP LoadNextRoomObject

ReturnRoomObjectsLoaded:
    RTS

LoadRoomObjectsAndState:
    JSR LoadRoomObjects
    JSR SaveRoomStateSnapshotB
    LDX #RoomStateRecordSize - 1

RotateRoomStateSnapshots:
    LDA CurrentRoomState,X
    STA RoomStateSnapshotB,X
    LDA RoomStateLoadMirror,X
    STA RoomStateSnapshotA,X
    DEX
    BPL RotateRoomStateSnapshots
    LDX #RoomRuntimeSnapshotSize - 1

RotateRoomRuntimeSnapshots:
    LDA ActiveRoomRuntimeState,X
    STA RoomRuntimeStateSnapshotB,X
    LDA RoomRuntimeLoadMirror,X
    STA RoomRuntimeStateSnapshotA,X
    DEX
    BPL RotateRoomRuntimeSnapshots

SelectAndApplyRoomState:
    LDX CurrentRoomNumber
    CPX RoomStateSnapshotB
    BNE LoadPersistentStateForRoom
    STX CurrentRoomState
    JSR RestoreRoomStateSnapshotB
    JMP MirrorSelectedRoomState

LoadPersistentStateForRoom:
    JSR LoadRoomPersistentState

MirrorSelectedRoomState:
    LDA CurrentRoomNumber
    STA CurrentRoomState
    LDX #RoomStateRecordSize - 1

CopyRoomStateLoadMirror:
    LDA CurrentRoomState,X
    STA RoomStateLoadMirror,X
    DEX
    BPL CopyRoomStateLoadMirror
    LDX #RoomRuntimeLoadMirrorSize - 1

CopyRoomRuntimeLoadMirror:
    LDA ActiveRoomRuntimeState,X
    STA RoomRuntimeLoadMirror,X
    DEX
    BPL CopyRoomRuntimeLoadMirror

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
    STA RuntimeObjectAux,X

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

SeekRoomObjectStream:
    LDA #<RoomObjectStream
    STA SoughtRoomObjectPointerLo
    LDA #>RoomObjectStream
    STA SoughtRoomObjectPointerHi
    LDY #$00
    INX

SelectRoomObjectList:
    DEX
    BEQ ReturnRoomObjectStreamPointer

ScanRoomObjectList:
    LDA (SoughtRoomObjectPointerLo),Y
    INC SoughtRoomObjectPointerLo
    BNE CheckRoomObjectListTerminator
    INC SoughtRoomObjectPointerHi

CheckRoomObjectListTerminator:
    CMP #$FF
    BNE ScanRoomObjectList
    BEQ SelectRoomObjectList

ReturnRoomObjectStreamPointer:
    RTS
