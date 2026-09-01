; Static room object tables and runtime-record loader
; CPU range $EB8F-$EC62
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
