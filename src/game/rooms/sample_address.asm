; Room-cell sample address preparation
; CPU range $8ECB-$8F0F
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

PrepareRoomCellSampleAddress:
    STA RoomCellSampleXHi
    STA RoomCellSampleColumnHi
    STX RoomCellSampleXLo
    STX RoomCellSampleColumnLo
    STY RoomCellSampleY
    LDA #$00
    STA RoomCellSamplePointerHi
    TYA
    LSR A
    LSR A
    LSR A
    STA RoomCellSamplePointerLo
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    CLC
    ADC RoomCellSamplePointerLo
    STA RoomCellSamplePointerLo
    BCC FinishRoomCellSampleRowPointer
    INC RoomCellSamplePointerHi

FinishRoomCellSampleRowPointer:
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    ASL RoomCellSamplePointerLo
    ROL RoomCellSamplePointerHi
    LDA #>RoomCells
    CLC
    ADC RoomCellSamplePointerHi
    STA RoomCellSamplePointerHi
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    LSR RoomCellSampleColumnHi
    ROR RoomCellSampleColumnLo
    RTS
