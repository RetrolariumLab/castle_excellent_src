; Room attribute addressing and table builder
; CPU range $E8DF-$EA35
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

GetRoomAttributeMaskAndOffset:
    LDA #$00
    STA RoomAttributeByteOffset
    CPX #$20
    BCC MapRoomAttributePosition
    LDA #$40
    STA RoomAttributeByteOffset
    TXA
    SEC
    SBC #$20
    TAX

MapRoomAttributePosition:
    TYA
    ASL A
    AND #$F8
    CLC
    ADC RoomAttributeByteOffset
    STA RoomAttributeByteOffset
    TXA
    LSR A
    LSR A
    CLC
    ADC RoomAttributeByteOffset
    STA RoomAttributeByteOffset
    TYA
    AND #$02
    STA RoomAttributeQuadrantIndex
    TXA
    LSR A
    AND #$01
    ORA RoomAttributeQuadrantIndex
    TAX
    LDA RoomAttributeQuadrantMasks,X
    LDX RoomAttributeByteOffset
    RTS

RoomAttributeQuadrantMasks:
    .byte $03, $0C, $30, $C0

BuildRoomAttributeTables:
    LDX #$00
    TXA

ClearRoomAttributeScratch:
    STA RoomAttributeScratch,X
    INX
    BPL ClearRoomAttributeScratch
    LDA #$00
    STA RoomAttributeRow
    LDX #$00

CopyInitialRoomAttributes:
    LDA InitialRoomAttributes,X
    STA RoomAttributeScratch,X
    INX
    CPX #$10
    BCC CopyInitialRoomAttributes

BeginRoomAttributeRow:
    LDA #$00
    STA RoomAttributeColumn
    LDA RoomAttributeRow
    ASL A
    ASL A
    CLC
    ADC RoomAttributeRow
    STA RoomCellRowPointerLo
    LDA #$00
    STA RoomCellRowPointerHi
    ASL RoomCellRowPointerLo
    ROL RoomCellRowPointerHi
    ASL RoomCellRowPointerLo
    ROL RoomCellRowPointerHi
    LDA RoomCellRowPointerLo
    CLC
    ADC #<RoomCells
    STA RoomCellRowPointerLo
    LDA RoomCellRowPointerHi
    ADC #>RoomCells
    STA RoomCellRowPointerHi

ProcessRoomAttributeCell:
    LDA RoomAttributeColumn
    ASL A
    CLC
    ADC #$04
    TAX
    LDA RoomAttributeRow
    CLC
    ADC #$07
    TAY
    JSR GetRoomAttributeMaskAndOffset
    PHA
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributePreservedBits
    LDY RoomAttributeColumn
    LDA (RoomCellRowPointerLo),Y
    CMP #$53
    BEQ DiscardRoomAttributeMask
    CMP #$09
    BEQ DiscardRoomAttributeMask
    JSR IsRoomCellAttributePreserving
    BEQ DiscardRoomAttributeMask
    TAY
    PLA
    AND RoomCellAttributeValues,Y
    ORA RoomAttributePreservedBits
    STA RoomAttributeScratch,X
    JMP AdvanceRoomAttributeCell

DiscardRoomAttributeMask:
    PLA

AdvanceRoomAttributeCell:
    INC RoomAttributeColumn
    LDA RoomAttributeColumn
    CMP #RoomWidth
    BCC ProcessRoomAttributeCell
    INC RoomAttributeRow
    LDA RoomAttributeRow
    CMP #RoomHeight
    BCC BeginRoomAttributeRow
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

IsRoomCellAttributePreserving:
    CMP #$18
    BEQ ReturnRoomCellAttributeClass
    CMP #$1B
    BEQ ReturnRoomCellAttributeClass
    CMP #$1E
    BEQ ReturnRoomCellAttributeClass
    CMP #$21
    BEQ ReturnRoomCellAttributeClass
    CMP #$24
    BEQ ReturnRoomCellAttributeClass
    CMP #$27
    BEQ ReturnRoomCellAttributeClass
    CMP #$28
    BEQ ReturnRoomCellAttributeClass
    CMP #$2B
    BEQ ReturnRoomCellAttributeClass
    CMP #$2C
    BEQ ReturnRoomCellAttributeClass
    CMP #$2D
    BEQ ReturnRoomCellAttributeClass
    CMP #$2E

ReturnRoomCellAttributeClass:
    RTS

RoomCellAttributeValues:
    .byte $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $AA, $AA, $AA, $AA, $AA, $AA, $55, $55
    .byte $55, $AA, $AA, $AA, $55, $55, $55, $AA, $55, $55, $55, $AA, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $55, $55, $55, $55, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00
