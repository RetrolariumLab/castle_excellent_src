; Pixel, tile, and room-cell coordinate conversion
; CPU range $A58A-$A5DC
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ConvertPixelPositionToTileCoordinates:
    LSR A
    TXA
    ROR A
    LSR A
    LSR A
    TAX
    TYA
    LSR A
    LSR A
    LSR A
    TAY
    RTS

UnreferencedTileToPixelConversionBytes:
    .byte $98, $0A, $0A, $0A, $A8, $8A, $0A, $0A, $0A, $AA, $2A, $29, $01, $60

GetRoomCellPointer:
    STY RoomCellPointerLo
    LDA #$00
    STA RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    TYA
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    BCC AddRoomCellBufferBase
    INC RoomCellPointerHi

AddRoomCellBufferBase:
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    LDA #<RoomCells
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    LDA #>RoomCells
    ADC RoomCellPointerHi
    STA RoomCellPointerHi
    TXA
    LSR A
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    BCC ReturnRoomCellPointer
    INC RoomCellPointerHi

ReturnRoomCellPointer:
    RTS
