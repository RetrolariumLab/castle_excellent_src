; Room attribute upload and compressed map decoding
; Original CPU range $E1F8-$E8DE

UploadLeftRoomAttributesTask:
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA RoomAttributeScratch + $08
    STA PPU_DATA
    LDA RoomAttributeScratch + $09
    STA PPU_DATA
    LDA RoomAttributeScratch + $0A
    STA PPU_DATA
    LDA RoomAttributeScratch + $0B
    STA PPU_DATA
    LDA RoomAttributeScratch + $0C
    STA PPU_DATA
    LDA RoomAttributeScratch + $0D
    STA PPU_DATA
    LDA RoomAttributeScratch + $0E
    STA PPU_DATA
    LDA RoomAttributeScratch + $0F
    STA PPU_DATA
    LDA RoomAttributeScratch + $10
    STA PPU_DATA
    LDA RoomAttributeScratch + $11
    STA PPU_DATA
    LDA RoomAttributeScratch + $12
    STA PPU_DATA
    LDA RoomAttributeScratch + $13
    STA PPU_DATA
    LDA RoomAttributeScratch + $14
    STA PPU_DATA
    LDA RoomAttributeScratch + $15
    STA PPU_DATA
    LDA RoomAttributeScratch + $16
    STA PPU_DATA
    LDA RoomAttributeScratch + $17
    STA PPU_DATA
    LDA RoomAttributeScratch + $18
    STA PPU_DATA
    LDA RoomAttributeScratch + $19
    STA PPU_DATA
    LDA RoomAttributeScratch + $1A
    STA PPU_DATA
    LDA RoomAttributeScratch + $1B
    STA PPU_DATA
    LDA RoomAttributeScratch + $1C
    STA PPU_DATA
    LDA RoomAttributeScratch + $1D
    STA PPU_DATA
    LDA RoomAttributeScratch + $1E
    STA PPU_DATA
    LDA RoomAttributeScratch + $1F
    STA PPU_DATA
    LDA RoomAttributeScratch + $20
    STA PPU_DATA
    LDA RoomAttributeScratch + $21
    STA PPU_DATA
    LDA RoomAttributeScratch + $22
    STA PPU_DATA
    LDA RoomAttributeScratch + $23
    STA PPU_DATA
    LDA RoomAttributeScratch + $24
    STA PPU_DATA
    LDA RoomAttributeScratch + $25
    STA PPU_DATA
    LDA RoomAttributeScratch + $26
    STA PPU_DATA
    LDA RoomAttributeScratch + $27
    STA PPU_DATA
    LDA RoomAttributeScratch + $28
    STA PPU_DATA
    LDA RoomAttributeScratch + $29
    STA PPU_DATA
    LDA RoomAttributeScratch + $2A
    STA PPU_DATA
    LDA RoomAttributeScratch + $2B
    STA PPU_DATA
    LDA RoomAttributeScratch + $2C
    STA PPU_DATA
    LDA RoomAttributeScratch + $2D
    STA PPU_DATA
    LDA RoomAttributeScratch + $2E
    STA PPU_DATA
    LDA RoomAttributeScratch + $2F
    STA PPU_DATA
    LDA RoomAttributeScratch + $30
    STA PPU_DATA
    LDA RoomAttributeScratch + $31
    STA PPU_DATA
    LDA RoomAttributeScratch + $32
    STA PPU_DATA
    LDA RoomAttributeScratch + $33
    STA PPU_DATA
    LDA RoomAttributeScratch + $34
    STA PPU_DATA
    LDA RoomAttributeScratch + $35
    STA PPU_DATA
    LDA RoomAttributeScratch + $36
    STA PPU_DATA
    LDA RoomAttributeScratch + $37
    STA PPU_DATA
    LDA RoomAttributeScratch + $38
    STA PPU_DATA
    LDA RoomAttributeScratch + $39
    STA PPU_DATA
    LDA RoomAttributeScratch + $3A
    STA PPU_DATA
    LDA RoomAttributeScratch + $3B
    STA PPU_DATA
    LDA RoomAttributeScratch + $3C
    STA PPU_DATA
    LDA RoomAttributeScratch + $3D
    STA PPU_DATA
    LDA RoomAttributeScratch + $3E
    STA PPU_DATA
    LDA RoomAttributeScratch + $3F
    STA PPU_DATA
    JMP NmiFrame

UploadRightRoomAttributesTask:
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA RoomAttributeScratch + $48
    STA PPU_DATA
    LDA RoomAttributeScratch + $49
    STA PPU_DATA
    LDA RoomAttributeScratch + $4A
    STA PPU_DATA
    LDA RoomAttributeScratch + $4B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $50
    STA PPU_DATA
    LDA RoomAttributeScratch + $51
    STA PPU_DATA
    LDA RoomAttributeScratch + $52
    STA PPU_DATA
    LDA RoomAttributeScratch + $53
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $58
    STA PPU_DATA
    LDA RoomAttributeScratch + $59
    STA PPU_DATA
    LDA RoomAttributeScratch + $5A
    STA PPU_DATA
    LDA RoomAttributeScratch + $5B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $60
    STA PPU_DATA
    LDA RoomAttributeScratch + $61
    STA PPU_DATA
    LDA RoomAttributeScratch + $62
    STA PPU_DATA
    LDA RoomAttributeScratch + $63
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $68
    STA PPU_DATA
    LDA RoomAttributeScratch + $69
    STA PPU_DATA
    LDA RoomAttributeScratch + $6A
    STA PPU_DATA
    LDA RoomAttributeScratch + $6B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $70
    STA PPU_DATA
    LDA RoomAttributeScratch + $71
    STA PPU_DATA
    LDA RoomAttributeScratch + $72
    STA PPU_DATA
    LDA RoomAttributeScratch + $73
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA RoomAttributeScratch + $78
    STA PPU_DATA
    LDA RoomAttributeScratch + $79
    STA PPU_DATA
    LDA RoomAttributeScratch + $7A
    STA PPU_DATA
    LDA RoomAttributeScratch + $7B
    STA PPU_DATA
    LDX #$19

WaitForRightAttributeUploadTiming:
    DEX
    BNE WaitForRightAttributeUploadTiming
    JMP NmiFrame

RoomCodebook:
    .byte $53, "1", $00
    .byte $00, "001", $00
    .byte $01, "010", $00
    .byte $02, "00010", $00
    .byte $03, "01100", $00
    .byte $04, "01111", $00
    .byte $05, "01110", $00
    .byte $16, "00001", $00
    .byte $10, "0001110", $00
    .byte $08, "00011111", $00
    .byte $19, "00011010", $00
    .byte $1A, "00011011", $00
    .byte $22, "00000101", $00
    .byte $23, "00000110", $00
    .byte $31, "00000011", $00
    .byte $32, "00000100", $00
    .byte $33, "00011000", $00
    .byte $34, "00011001", $00
    .byte $06, "011011110", $00
    .byte $07, "011011111", $00
    .byte $0C, "000000011", $00
    .byte $0D, "000000001", $00
    .byte $0E, "011010101", $00
    .byte $11, "011010010", $00
    .byte $1C, "011011001", $00
    .byte $1D, "011011010", $00
    .byte $1F, "011011100", $00
    .byte $20, "011011101", $00
    .byte $2A, "000000000", $00
    .byte $2F, "011010001", $00
    .byte $30, "011010100", $00
    .byte $43, "000001111", $00
    .byte $45, "011010110", $00
    .byte $4B, "011010111", $00
    .byte $4D, "000000100", $00
    .byte $4E, "000000101", $00
    .byte $52, "000111100", $00
    .byte $0A, "0110100111", $00
    .byte $0B, "0001111010", $00
    .byte $25, "0001111011", $00
    .byte $26, "0110100000", $00
    .byte $29, "0110110111", $00
    .byte $3D, "0000000100", $00
    .byte $4C, "0000000101", $00
    .byte $51, "0110110110", $00
    .byte $5E, "0110110000", $00
    .byte $41, "00000111001", $00
    .byte $42, "00000111010", $00
    .byte $4F, "01101000010", $00
    .byte $50, "01101000011", $00
    .byte $56, "01101001100", $00
    .byte $5A, "01101001101", $00
    .byte $35, "011011000101", $00
    .byte $39, "011011000110", $00
    .byte $44, "011011000111", $00
    .byte $49, "000001110111", $00
    .byte $4A, "011011000100", $00
    .byte $09, "0000011100000", $00
    .byte $12, "0000011100001", $00
    .byte $13, "0000011100010", $00
    .byte $14, "0000011100011", $00
    .byte $15, "0000011101100", $00
    .byte $17, "0000011101101", $00
    .byte $FF

RoomPointerTable:
    .byte $00, $00, $9B, $00, $32, $01, $B8, $01, $26, $02, $B7, $02, $5C, $03, $D7, $03
    .byte $8B, $04, $FF, $04, $5C, $05, $F5, $05, $9A, $06, $2A, $07, $8A, $07, $0E, $08
    .byte $66, $08, $C8, $08, $51, $09, $B8, $09, $44, $0A, $DF, $0A, $7A, $0B, $1C, $0C
    .byte $89, $0C, $EF, $0C, $65, $0D, $F6, $0D, $58, $0E, $D8, $0E, $91, $0F, $15, $10
    .byte $91, $10, $F7, $10, $62, $11, $DB, $11, $53, $12, $BC, $12, $5B, $13, $E2, $13
    .byte $5F, $14, $DC, $14, $46, $15, $A5, $15, $2A, $16, $85, $16, $E1, $16, $3F, $17
    .byte $A8, $17, $11, $18, $73, $18, $E2, $18, $56, $19, $C8, $19, $3F, $1A, $9C, $1A
    .byte $F4, $1A, $4C, $1B, $A6, $1B, $15, $1C, $79, $1C, $E6, $1C, $44, $1D, $AF, $1D
    .byte $24, $1E, $A5, $1E, $16, $1F, $00, $00, $83, $00, $F1, $00, $65, $01, $CA, $01
    .byte $40, $02, $AD, $02, $22, $03, $8A, $03, $F9, $03, $61, $04, $D1, $04, $5D, $05
    .byte $B9, $05, $28, $06, $BA, $06, $45, $07, $CE, $07, $7D, $08, $F8, $08, $6B, $09
    .byte $06, $0A, $9A, $0A, $25, $0B, $DB, $0B, $94, $0C, $11, $0D, $98, $0D, $3A, $0E
    .byte $C6, $0E, $5A, $0F, $FC, $0F, $AA, $10

RoomBitMasks:
    .byte $80, $40, $20, $10, $08, $04, $02, $01

ReadRoomBit:
    LDA PPU_STATUS
    LDA RoomStreamPointerHi
    STA PPU_ADDR
    LDA RoomStreamPointerLo
    STA PPU_ADDR
    LDA PPU_DATA
    LDA PPU_DATA
    LDX RoomDecoderBitIndex
    AND RoomBitMasks,X
    PHP
    INX
    STX RoomDecoderBitIndex
    CPX #$08
    BCC RestoreRoomBitFlags
    LDX #$00
    STX RoomDecoderBitIndex
    INC RoomStreamPointerLo
    BNE RestoreRoomBitFlags
    INC RoomStreamPointerHi

RestoreRoomBitFlags:
    PLP
    RTS

RefillRoomBitWindow:
    STX RoomLookaheadWriteIndex
    JSR ReadRoomBit
    CLC
    BEQ StoreRoomLookaheadBit
    SEC

StoreRoomLookaheadBit:
    LDA #$30
    ADC #$00
    LDX RoomLookaheadWriteIndex
    STA RoomBitLookahead,X
    INX
    CPX #$10
    BCC RefillRoomBitWindow
    RTS

DecodeRoom:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$02
    JSR SelectChrBank
    CPX #$43
    BCC LoadRoomStreamPointer
    LDY #$03
    JSR SelectChrBank

LoadRoomStreamPointer:
    TXA
    ASL A
    TAX
    LDA RoomPointerTable,X
    STA RoomStreamPointerLo
    LDA RoomPointerTable + 1,X
    STA RoomStreamPointerHi
    LDA #$00
    STA RoomDecoderBitIndex
    STA RoomOutputOffsetLo
    STA RoomOutputOffsetHi
    LDX #$00
    JSR RefillRoomBitWindow

DecodeNextRoomCell:
    LDA #>RoomCodebook
    STA RoomCodePointerHi
    LDA #<RoomCodebook
    STA RoomCodePointerLo

ReadRoomCodebookEntry:
    LDY #$00
    LDA (RoomCodePointerLo),Y
    STA DecodedRoomCell
    INC RoomCodePointerLo
    BNE CompareRoomCodeword
    INC RoomCodePointerHi

CompareRoomCodeword:
    LDY #$00
    LDX #$00

CompareRoomCodewordBit:
    LDA (RoomCodePointerLo),Y
    BEQ ConsumeMatchedRoomCodeword
    CMP RoomBitLookahead,X
    BNE SkipRoomCodeword
    INX
    INY
    CPY #$10
    BCC CompareRoomCodewordBit

TrapOversizedRoomCodeword:
    JMP TrapOversizedRoomCodeword

SkipRoomCodeword:
    INY
    LDA (RoomCodePointerLo),Y
    BNE SkipRoomCodeword
    INY
    LDA (RoomCodePointerLo),Y
    CMP #$FF
    BNE AdvanceRoomCodebookPointer

TrapExhaustedRoomCodebook:
    JMP TrapExhaustedRoomCodebook

AdvanceRoomCodebookPointer:
    TYA
    CLC
    ADC RoomCodePointerLo
    STA RoomCodePointerLo
    BCC ReadNextRoomCodebookEntry
    INC RoomCodePointerHi

ReadNextRoomCodebookEntry:
    JMP ReadRoomCodebookEntry

ConsumeMatchedRoomCodeword:
    LDY #$00

ShiftRoomBitLookahead:
    LDA RoomBitLookahead,X
    STA RoomBitLookahead,Y
    INY
    INX
    CPX #$10
    BCC ShiftRoomBitLookahead
    TYA
    TAX
    JSR RefillRoomBitWindow
    LDA RoomOutputOffsetLo
    STA RoomOutputPointerLo
    LDA RoomOutputOffsetHi
    CLC
    ADC #$04
    STA RoomOutputPointerHi
    LDY #$00
    LDA DecodedRoomCell
    STA (RoomOutputPointerLo),Y
    INC RoomOutputOffsetLo
    BNE CheckRoomDecodeComplete
    INC RoomOutputOffsetHi

CheckRoomDecodeComplete:
    LDA RoomOutputOffsetLo
    CMP #$90
    BNE DecodeNextRoomCell
    LDA RoomOutputOffsetHi
    CMP #$01
    BNE DecodeNextRoomCell
    LDY #$00
    JMP SelectChrBank
