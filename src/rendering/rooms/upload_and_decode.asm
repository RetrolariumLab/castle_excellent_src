; Room attribute upload and compressed map decoding
; CPU range $E1F8-$E8DE
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
    .byte $53, $31, $00, $00, $30, $30, $31, $00, $01, $30, $31, $30, $00, $02, $30, $30
    .byte $30, $31, $30, $00, $03, $30, $31, $31, $30, $30, $00, $04, $30, $31, $31, $31
    .byte $31, $00, $05, $30, $31, $31, $31, $30, $00, $16, $30, $30, $30, $30, $31, $00
    .byte $10, $30, $30, $30, $31, $31, $31, $30, $00, $08, $30, $30, $30, $31, $31, $31
    .byte $31, $31, $00, $19, $30, $30, $30, $31, $31, $30, $31, $30, $00, $1A, $30, $30
    .byte $30, $31, $31, $30, $31, $31, $00, $22, $30, $30, $30, $30, $30, $31, $30, $31
    .byte $00, $23, $30, $30, $30, $30, $30, $31, $31, $30, $00, $31, $30, $30, $30, $30
    .byte $30, $30, $31, $31, $00, $32, $30, $30, $30, $30, $30, $31, $30, $30, $00, $33
    .byte $30, $30, $30, $31, $31, $30, $30, $30, $00, $34, $30, $30, $30, $31, $31, $30
    .byte $30, $31, $00, $06, $30, $31, $31, $30, $31, $31, $31, $31, $30, $00, $07, $30
    .byte $31, $31, $30, $31, $31, $31, $31, $31, $00, $0C, $30, $30, $30, $30, $30, $30
    .byte $30, $31, $31, $00, $0D, $30, $30, $30, $30, $30, $30, $30, $30, $31, $00, $0E
    .byte $30, $31, $31, $30, $31, $30, $31, $30, $31, $00, $11, $30, $31, $31, $30, $31
    .byte $30, $30, $31, $30, $00, $1C, $30, $31, $31, $30, $31, $31, $30, $30, $31, $00
    .byte $1D, $30, $31, $31, $30, $31, $31, $30, $31, $30, $00, $1F, $30, $31, $31, $30
    .byte $31, $31, $31, $30, $30, $00, $20, $30, $31, $31, $30, $31, $31, $31, $30, $31
    .byte $00, $2A, $30, $30, $30, $30, $30, $30, $30, $30, $30, $00, $2F, $30, $31, $31
    .byte $30, $31, $30, $30, $30, $31, $00, $30, $30, $31, $31, $30, $31, $30, $31, $30
    .byte $30, $00, $43, $30, $30, $30, $30, $30, $31, $31, $31, $31, $00, $45, $30, $31
    .byte $31, $30, $31, $30, $31, $31, $30, $00, $4B, $30, $31, $31, $30, $31, $30, $31
    .byte $31, $31, $00, $4D, $30, $30, $30, $30, $30, $30, $31, $30, $30, $00, $4E, $30
    .byte $30, $30, $30, $30, $30, $31, $30, $31, $00, $52, $30, $30, $30, $31, $31, $31
    .byte $31, $30, $30, $00, $0A, $30, $31, $31, $30, $31, $30, $30, $31, $31, $31, $00
    .byte $0B, $30, $30, $30, $31, $31, $31, $31, $30, $31, $30, $00, $25, $30, $30, $30
    .byte $31, $31, $31, $31, $30, $31, $31, $00, $26, $30, $31, $31, $30, $31, $30, $30
    .byte $30, $30, $30, $00, $29, $30, $31, $31, $30, $31, $31, $30, $31, $31, $31, $00
    .byte $3D, $30, $30, $30, $30, $30, $30, $30, $31, $30, $30, $00, $4C, $30, $30, $30
    .byte $30, $30, $30, $30, $31, $30, $31, $00, $51, $30, $31, $31, $30, $31, $31, $30
    .byte $31, $31, $30, $00, $5E, $30, $31, $31, $30, $31, $31, $30, $30, $30, $30, $00
    .byte $41, $30, $30, $30, $30, $30, $31, $31, $31, $30, $30, $31, $00, $42, $30, $30
    .byte $30, $30, $30, $31, $31, $31, $30, $31, $30, $00, $4F, $30, $31, $31, $30, $31
    .byte $30, $30, $30, $30, $31, $30, $00, $50, $30, $31, $31, $30, $31, $30, $30, $30
    .byte $30, $31, $31, $00, $56, $30, $31, $31, $30, $31, $30, $30, $31, $31, $30, $30
    .byte $00, $5A, $30, $31, $31, $30, $31, $30, $30, $31, $31, $30, $31, $00, $35, $30
    .byte $31, $31, $30, $31, $31, $30, $30, $30, $31, $30, $31, $00, $39, $30, $31, $31
    .byte $30, $31, $31, $30, $30, $30, $31, $31, $30, $00, $44, $30, $31, $31, $30, $31
    .byte $31, $30, $30, $30, $31, $31, $31, $00, $49, $30, $30, $30, $30, $30, $31, $31
    .byte $31, $30, $31, $31, $31, $00, $4A, $30, $31, $31, $30, $31, $31, $30, $30, $30
    .byte $31, $30, $30, $00, $09, $30, $30, $30, $30, $30, $31, $31, $31, $30, $30, $30
    .byte $30, $30, $00, $12, $30, $30, $30, $30, $30, $31, $31, $31, $30, $30, $30, $30
    .byte $31, $00, $13, $30, $30, $30, $30, $30, $31, $31, $31, $30, $30, $30, $31, $30
    .byte $00, $14, $30, $30, $30, $30, $30, $31, $31, $31, $30, $30, $30, $31, $31, $00
    .byte $15, $30, $30, $30, $30, $30, $31, $31, $31, $30, $31, $31, $30, $30, $00, $17
    .byte $30, $30, $30, $30, $30, $31, $31, $31, $30, $31, $31, $30, $31, $00, $FF

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
