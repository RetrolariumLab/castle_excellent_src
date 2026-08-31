; Static room object stream seeker
; CPU range $EDD2-$EDEE
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
