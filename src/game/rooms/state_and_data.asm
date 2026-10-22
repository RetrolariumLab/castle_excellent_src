; Mutable state, persistent state, and room object data
; Original CPU range $EDEF-$F8FB

ApplyMutableCellStateBit:
    LDA #>RoomCells
    STA MutableCellScanPointerHi
    LDA #<RoomCells
    STA MutableCellScanPointerLo

ScanMutableCellCandidates:
    LDY #$00
    LDA (MutableCellScanPointerLo),Y
    CMP #$54
    BEQ SelectMutableCellCandidate
    JSR IsPersistentMutableCell
    BNE AdvanceMutableCellCandidateScan

SelectMutableCellCandidate:
    DEX
    BNE AdvanceMutableCellCandidateScan
    LDA MutableCellScanPointerLo
    BNE MoveToMutableCellLeftNeighbor
    DEC MutableCellScanPointerHi

MoveToMutableCellLeftNeighbor:
    DEC MutableCellScanPointerLo
    LDY #$00
    LDA (MutableCellScanPointerLo),Y
    CMP #$16
    BEQ RestoreMutableCellBesideType16
    LDY #$02
    LDA (MutableCellScanPointerLo),Y
    CMP #$16
    BNE RestoreStandaloneMutableCell

RestoreMutableCellBesideType16:
    INC MutableCellScanPointerLo
    BNE WriteMutableCellBesideType16
    INC MutableCellScanPointerHi

WriteMutableCellBesideType16:
    LDY #$00
    LDA #$62
    STA (MutableCellScanPointerLo),Y
    LDY #RoomWidth
    LDA #$63
    STA (MutableCellScanPointerLo),Y
    RTS

RestoreStandaloneMutableCell:
    INC MutableCellScanPointerLo
    BNE WriteStandaloneMutableCell
    INC MutableCellScanPointerHi

WriteStandaloneMutableCell:
    LDY #$00
    LDA #$54
    STA (MutableCellScanPointerLo),Y
    LDA #$55
    LDY #RoomWidth
    STA (MutableCellScanPointerLo),Y
    RTS

AdvanceMutableCellCandidateScan:
    INC MutableCellScanPointerLo
    BNE CheckMutableCellCandidateScanEnd
    INC MutableCellScanPointerHi

CheckMutableCellCandidateScanEnd:
    LDA MutableCellScanPointerLo
    CMP #<RoomMutableCellPersistentState
    LDA MutableCellScanPointerHi
    SBC #>RoomMutableCellPersistentState
    BCC ScanMutableCellCandidates
    RTS

RestoreRoomStateSnapshotB:
    LDX #$03

RestoreSnapshotBObjectState:
    LDA RoomStateSnapshotB,X
    STA CurrentRoomState,X
    STA LoadedRoomObjectStateBits - 1,X
    DEX
    BNE RestoreSnapshotBObjectState
    LDX #$04

RestoreSnapshotBMutableCellState:
    LDA RoomMutableCellStateSnapshotB,X
    STA CurrentRoomMutableCellState,X
    STA LoadedRoomMutableCellStateBits,X
    DEX
    BPL RestoreSnapshotBMutableCellState
    RTS

RestoreRoomStateSnapshotA:
    LDX #$03

RestoreSnapshotAObjectState:
    LDA RoomStateSnapshotA,X
    STA CurrentRoomState,X
    STA LoadedRoomObjectStateBits - 1,X
    DEX
    BNE RestoreSnapshotAObjectState
    LDX #$04

RestoreSnapshotAMutableCellState:
    LDA RoomMutableCellStateSnapshotA,X
    STA CurrentRoomMutableCellState,X
    STA LoadedRoomMutableCellStateBits,X
    DEX
    BPL RestoreSnapshotAMutableCellState
    RTS

LoadRoomPersistentState:
    LDA #$00
    LDX #$07

ClearLoadedRoomStateBits:
    STA LoadedRoomObjectStateBits,X
    DEX
    BPL ClearLoadedRoomStateBits
    LDX CurrentRoomNumber
    LDA RoomObjectStateOffsets,X
    SEC
    SBC RoomObjectStateOffsets - 1,X
    TAY
    LDA RoomObjectStateOffsets - 1,X
    TAX
    LDA RoomObjectPersistentState,X
    STA LoadedRoomObjectStateBits
    STA CurrentRoomObjectState
    DEY
    BEQ LoadRoomMutableCellState
    LDA RoomObjectPersistentState + 1,X
    STA LoadedRoomObjectStateBits + 1
    STA CurrentRoomObjectState + 1
    DEY
    BEQ LoadRoomMutableCellState
    LDA RoomObjectPersistentState + 2,X
    STA LoadedRoomObjectStateBits + 2
    STA CurrentRoomObjectState + 2

LoadRoomMutableCellState:
    LDX CurrentRoomNumber
    LDA RoomMutableCellStateOffsets,X
    SEC
    SBC RoomMutableCellStateOffsets - 1,X
    TAY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellStateOffsets - 1,X
    TAX
    LDA RoomMutableCellPersistentState,X
    STA LoadedRoomMutableCellStateBits
    STA CurrentRoomMutableCellState
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 1,X
    STA LoadedRoomMutableCellStateBits + 1
    STA CurrentRoomMutableCellState + 1
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 2,X
    STA LoadedRoomMutableCellStateBits + 2
    STA CurrentRoomMutableCellState + 2
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 3,X
    STA LoadedRoomMutableCellStateBits + 3
    STA CurrentRoomMutableCellState + 3
    DEY
    BEQ ReturnRoomPersistentStateLoaded
    LDA RoomMutableCellPersistentState + 4,X
    STA LoadedRoomMutableCellStateBits + 4
    STA CurrentRoomMutableCellState + 4

ReturnRoomPersistentStateLoaded:
    RTS

RoomObjectStateOffsets:
    .byte $00, $01, $02, $03, $05, $06, $09, $0A, $0B, $0D, $0F, $10, $11, $12, $14, $15
    .byte $17, $18, $19, $1A, $1C, $1D, $1E, $1F, $20, $21, $24, $25, $26, $27, $28, $2A
    .byte $2C, $2D, $2F, $30, $31, $32, $33, $35, $36, $37, $3A, $3B, $3C, $3D, $3E, $40
    .byte $41, $42, $44, $46, $48, $49, $4A, $4B, $4C, $4E, $4F, $50, $51, $52, $54, $55
    .byte $57, $58, $5A, $5C, $5E, $5F, $60, $62, $63, $66, $67, $68, $6A, $6C, $6E, $70
    .byte $71, $72, $74, $75, $77, $78, $79, $7A, $7B, $7C, $7E, $80, $81, $82, $84, $86
    .byte $87, $88, $8A, $8C, $8D

RoomObjectStream:
    .byte $35, $0A, $0E, $35, $0B, $0E, $35, $0B, $10, $34, $0F, $10, $34, $0F, $0E, $34
    .byte $10, $10, $35, $08, $0A, $34, $08, $0C, $FF, $3C, $02, $05, $30, $08, $08, $2C
    .byte $09, $09, $2C, $0E, $09, $14, $05, $09, $30, $11, $0E, $FF, $2C, $0A, $0A, $3A
    .byte $10, $01, $3A, $11, $01, $FF, $2D, $05, $02, $2D, $07, $02, $2D, $09, $02, $2D
    .byte $0B, $03, $2D, $0E, $03, $2D, $10, $03, $2A, $05, $06, $2A, $0C, $07, $2A, $05
    .byte $0B, $2A, $08, $0B, $2F, $01, $02, $2F, $03, $02, $2F, $0D, $00, $2F, $0A, $0B
    .byte $2B, $0A, $0E, $FF, $2C, $0D, $04, $2C, $06, $06, $FF, $2C, $0C, $10, $35, $09
    .byte $01, $34, $0A, $01, $33, $0B, $01, $33, $0C, $01, $35, $09, $05, $34, $0A, $05
    .byte $34, $0B, $05, $33, $0C, $05, $35, $09, $0A, $35, $0A, $0A, $34, $0B, $0A, $33
    .byte $0C, $0A, $35, $08, $0F, $35, $09, $0F, $34, $0A, $0F, $34, $0B, $0F, $FF, $32
    .byte $01, $08, $32, $02, $08, $35, $10, $0E, $35, $11, $0E, $35, $12, $0E, $FF, $2A
    .byte $11, $11, $2C, $03, $0B, $2C, $10, $0B, $15, $10, $09, $13, $03, $09, $10, $09
    .byte $0A, $FF, $24, $0F, $11, $14, $09, $04, $3A, $0F, $02, $3A, $0D, $04, $31, $06
    .byte $0A, $30, $04, $0A, $31, $02, $0A, $38, $10, $0B, $38, $10, $07, $38, $10, $0F
    .byte $2B, $0D, $09, $FF, $13, $09, $03, $15, $0F, $03, $12, $08, $09, $30, $08, $01
    .byte $33, $06, $01, $32, $0F, $01, $34, $11, $0C, $2F, $11, $11, $39, $0B, $0D, $39
    .byte $0A, $0D, $38, $05, $0D, $38, $04, $0D, $FF, $35, $0B, $0E, $35, $0C, $0F, $2A
    .byte $08, $07, $FF, $37, $01, $08, $3A, $0F, $0A, $3A, $0E, $0A, $FF, $35, $07, $0A
    .byte $34, $08, $0A, $39, $0A, $0E, $39, $0A, $10, $3C, $05, $0E, $37, $0A, $0A, $FF
    .byte $2A, $0F, $02, $2A, $11, $03, $2A, $0F, $04, $2A, $11, $08, $2A, $0F, $0F, $2A
    .byte $11, $11, $2A, $0F, $11, $2A, $0A, $08, $2B, $0A, $11, $33, $07, $09, $31, $04
    .byte $02, $31, $03, $02, $38, $03, $0A, $39, $02, $0A, $3A, $01, $0A, $FF, $2D, $07
    .byte $11, $18, $09, $11, $18, $10, $02, $34, $10, $05, $34, $11, $05, $FF, $32, $01
    .byte $00, $31, $02, $00, $35, $01, $02, $34, $02, $02, $1E, $05, $11, $20, $0E, $11
    .byte $1A, $09, $0C, $1A, $0A, $0C, $1A, $0A, $07, $1A, $09, $07, $FF, $38, $05, $02
    .byte $38, $0E, $02, $38, $05, $06, $38, $0E, $06, $35, $02, $04, $35, $03, $04, $33
    .byte $10, $00, $33, $11, $00, $FF, $2B, $04, $10, $2B, $05, $10, $2B, $06, $10, $2E
    .byte $0C, $06, $32, $06, $00, $31, $07, $00, $30, $08, $00, $FF, $1E, $05, $02, $18
    .byte $0A, $11, $FF, $35, $01, $00, $38, $06, $00, $38, $07, $00, $34, $11, $00, $12
    .byte $0F, $01, $12, $0B, $01, $12, $08, $03, $1A, $08, $08, $33, $06, $0C, $11, $0D
    .byte $0C, $FF, $37, $0D, $0B, $3A, $0C, $0B, $3A, $0B, $0B, $3A, $0A, $0B, $FF, $39
    .byte $03, $02, $39, $04, $02, $39, $05, $02, $FF, $11, $05, $07, $32, $11, $11, $32
    .byte $12, $11, $37, $0B, $04, $FF, $35, $0F, $0E, $34, $0F, $10, $33, $0F, $12, $14
    .byte $07, $0E, $FF, $16, $10, $0D, $1A, $10, $11, $1A, $0D, $11, $FF, $37, $02, $0C
    .byte $37, $04, $0C, $2D, $0A, $0C, $2F, $0C, $0C, $2D, $0E, $0C, $2D, $10, $0C, $3A
    .byte $02, $05, $2A, $0A, $07, $2F, $0C, $07, $2F, $0E, $07, $2A, $10, $07, $2A, $12
    .byte $07, $2A, $06, $00, $2A, $08, $00, $2F, $0A, $00, $2D, $0C, $00, $2D, $0E, $00
    .byte $2E, $10, $00, $FF, $16, $0D, $11, $18, $0E, $11, $27, $08, $09, $29, $0B, $09
    .byte $1A, $09, $0C, $1A, $0A, $0C, $FF, $33, $0D, $11, $3A, $09, $0A, $37, $01, $04
    .byte $1A, $02, $04, $2C, $0A, $0D, $3A, $0C, $0A, $38, $08, $11, $FF, $37, $0F, $0D
    .byte $12, $0B, $06, $14, $08, $01, $3A, $12, $00, $1A, $04, $09, $39, $10, $00, $38
    .byte $0E, $00, $FF, $3A, $0E, $00, $33, $05, $00, $33, $08, $00, $38, $0F, $06, $39
    .byte $10, $04, $FF, $30, $12, $01, $38, $11, $01, $38, $10, $01, $1A, $0C, $02, $2C
    .byte $08, $07, $2A, $0E, $0C, $37, $0F, $10, $2B, $0B, $11, $16, $07, $11, $FF, $2C
    .byte $11, $02, $2C, $0A, $03, $2E, $0D, $01, $2C, $0E, $07, $2C, $0D, $0D, $2C, $11
    .byte $0E, $2C, $09, $0D, $2C, $08, $11, $2C, $06, $11, $FF, $34, $01, $0F, $35, $02
    .byte $0F, $1A, $01, $0A, $24, $10, $11, $FF, $32, $12, $10, $2A, $0C, $11, $2A, $0C
    .byte $0F, $2A, $0C, $0D, $2A, $0C, $0B, $2A, $0C, $09, $24, $0E, $0B, $24, $0E, $11
    .byte $39, $05, $06, $39, $06, $06, $32, $05, $0D, $35, $05, $0F, $FF, $24, $0A, $10
    .byte $2C, $0A, $08, $2E, $0A, $05, $34, $0A, $0B, $FF, $2C, $0F, $01, $2C, $0C, $01
    .byte $2B, $09, $01, $2B, $06, $01, $2F, $03, $01, $32, $12, $0D, $30, $0A, $0D, $32
    .byte $04, $0D, $FF, $2A, $03, $03, $2A, $03, $05, $2A, $03, $07, $2A, $05, $07, $2A
    .byte $06, $01, $2A, $09, $01, $2A, $10, $01, $1A, $07, $07, $FF, $2B, $09, $0C, $2E
    .byte $0B, $05, $FF, $30, $07, $0C, $30, $05, $0C, $2B, $12, $0D, $2B, $12, $0B, $1A
    .byte $02, $06, $14, $08, $11, $31, $02, $00, $34, $03, $00, $1A, $07, $06, $FF, $3A
    .byte $0A, $01, $14, $06, $05, $32, $06, $08, $3A, $02, $01, $3A, $08, $11, $37, $09
    .byte $11, $3A, $0A, $11, $2C, $0F, $0C, $FF, $34, $06, $07, $1E, $0D, $11, $22, $07
    .byte $10, $1E, $05, $03, $35, $04, $01, $2C, $0D, $09, $22, $08, $0A, $22, $09, $0D
    .byte $FF, $34, $12, $0C, $34, $10, $0B, $33, $10, $10, $33, $0E, $0F, $33, $0A, $03
    .byte $34, $09, $00, $33, $08, $09, $32, $06, $09, $33, $04, $09, $35, $02, $00, $2C
    .byte $03, $00, $2C, $0A, $00, $2C, $09, $06, $2C, $08, $0F, $2C, $0F, $00, $2C, $10
    .byte $03, $2C, $0F, $0B, $FF, $38, $08, $0F, $30, $0C, $0F, $30, $0D, $0F, $35, $07
    .byte $0F, $1E, $04, $11, $27, $02, $01, $27, $02, $06, $FF, $3A, $05, $01, $3A, $03
    .byte $01, $3A, $01, $01, $2E, $0B, $07, $2C, $11, $11, $18, $0A, $11, $16, $09, $11
    .byte $34, $06, $11, $FF, $39, $12, $01, $38, $0F, $01, $38, $09, $01, $39, $06, $01
    .byte $37, $06, $0D, $35, $04, $0D, $35, $01, $0D, $FF, $39, $11, $01, $37, $0A, $01
    .byte $37, $09, $01, $39, $02, $01, $35, $12, $0E, $33, $0F, $0E, $FF, $2B, $04, $0B
    .byte $2B, $05, $0B, $2B, $04, $0D, $2B, $05, $0D, $2B, $04, $0F, $2B, $05, $0F, $2B
    .byte $0A, $04, $2B, $0D, $01, $34, $01, $0C, $FF, $33, $12, $09, $16, $03, $11, $18
    .byte $06, $11, $1E, $03, $0C, $20, $10, $0C, $FF, $37, $12, $04, $3A, $12, $06, $3A
    .byte $12, $08, $3A, $12, $0A, $2D, $08, $03, $2D, $03, $0B, $2E, $04, $02, $2D, $08
    .byte $0A, $FF, $2C, $0A, $0F, $2C, $0A, $0D, $2C, $0A, $0B, $2C, $0A, $09, $2C, $0A
    .byte $07, $2C, $0A, $05, $2C, $08, $05, $2C, $0A, $03, $2C, $08, $03, $2C, $0A, $01
    .byte $2C, $08, $01, $35, $03, $0B, $35, $04, $0B, $32, $0D, $0D, $35, $0E, $0D, $FF
    .byte $37, $02, $02, $2C, $09, $06, $2C, $07, $08, $2C, $09, $08, $2C, $05, $0B, $2C
    .byte $0B, $0B, $33, $03, $0E, $33, $05, $11, $33, $0B, $11, $FF, $37, $05, $01, $33
    .byte $08, $01, $33, $0B, $01, $16, $06, $07, $18, $0D, $07, $20, $09, $0B, $33, $05
    .byte $0E, $33, $06, $0E, $38, $0D, $0E, $38, $0E, $0E, $FF, $2A, $06, $05, $0E, $0B
    .byte $0A, $30, $0C, $0F, $FF, $37, $07, $07, $35, $07, $09, $35, $07, $0B, $2B, $05
    .byte $01, $1E, $02, $0D, $FF, $14, $08, $09, $14, $0A, $05, $14, $0C, $09, $14, $0E
    .byte $05, $14, $10, $09, $2A, $0A, $11, $FF, $32, $12, $0D, $37, $0F, $0D, $12, $01
    .byte $06, $12, $08, $06, $2D, $0B, $11, $14, $05, $0B, $FF, $31, $01, $01, $31, $02
    .byte $01, $31, $03, $01, $3A, $01, $05, $3A, $02, $05, $3A, $01, $09, $3A, $02, $09
    .byte $37, $01, $0D, $37, $07, $10, $18, $08, $11, $20, $0F, $11, $27, $0B, $06, $FF
    .byte $34, $02, $00, $34, $0D, $00, $2D, $04, $01, $2D, $0B, $01, $2B, $08, $04, $2B
    .byte $0F, $04, $FF, $39, $08, $05, $39, $0A, $05, $39, $10, $05, $39, $12, $05, $37
    .byte $06, $0D, $14, $0D, $0D, $FF, $34, $0B, $00, $39, $04, $07, $39, $01, $07, $FF
    .byte $39, $10, $07, $39, $11, $07, $38, $05, $01, $38, $06, $01, $38, $07, $01, $37
    .byte $07, $06, $37, $08, $09, $18, $0E, $0D, $FF, $35, $08, $00, $34, $0C, $00, $35
    .byte $12, $07, $35, $08, $0E, $34, $0C, $0E, $24, $0A, $0B, $20, $10, $11, $2C, $06
    .byte $11, $2C, $0E, $11, $FF, $37, $02, $07, $3A, $01, $0C, $3A, $02, $0C, $3A, $03
    .byte $0C, $3A, $04, $0C, $18, $0E, $0D, $2D, $0E, $10, $34, $0F, $10, $FF, $39, $0B
    .byte $02, $39, $08, $02, $39, $07, $05, $39, $0D, $05, $39, $0A, $05, $39, $0F, $08
    .byte $39, $0C, $08, $39, $06, $0A, $39, $0C, $0C, $33, $0A, $0A, $33, $06, $07, $32
    .byte $01, $05, $2C, $04, $0C, $32, $09, $07, $FF, $2B, $0F, $01, $2B, $09, $0C, $2B
    .byte $07, $0E, $2B, $05, $0E, $2B, $07, $11, $32, $0A, $0B, $37, $07, $07, $FF, $3A
    .byte $0B, $04, $37, $11, $04, $39, $0B, $09, $37, $11, $09, $34, $0F, $10, $33, $08
    .byte $11, $2B, $08, $09, $2B, $08, $0B, $2B, $08, $0D, $FF, $39, $0B, $05, $3A, $0B
    .byte $03, $32, $0B, $01, $35, $04, $0B, $38, $02, $10, $39, $05, $10, $38, $08, $10
    .byte $38, $0E, $10, $39, $11, $10, $FF, $3A, $02, $09, $2F, $04, $08, $39, $06, $06
    .byte $14, $08, $03, $14, $0B, $03, $37, $0D, $06, $38, $0F, $08, $27, $11, $09, $34
    .byte $10, $10, $38, $0E, $10, $33, $0C, $10, $38, $0A, $10, $39, $03, $10, $38, $01
    .byte $10, $FF, $27, $10, $05, $27, $10, $09, $34, $06, $0F, $3A, $11, $0F, $FF, $2B
    .byte $0C, $11, $2B, $06, $10, $38, $03, $01, $38, $04, $01, $FF, $3A, $05, $01, $3A
    .byte $06, $01, $39, $11, $01, $39, $12, $01, $33, $05, $06, $35, $06, $06, $36, $11
    .byte $06, $34, $05, $0A, $38, $10, $0A, $35, $03, $0F, $20, $09, $03, $18, $09, $07
    .byte $20, $09, $0C, $FF, $38, $08, $02, $38, $0A, $02, $38, $0C, $02, $35, $12, $06
    .byte $37, $12, $0A, $2B, $0A, $0C, $18, $0A, $11, $FF, $35, $02, $02, $32, $08, $01
    .byte $32, $0C, $01, $37, $10, $01, $35, $02, $06, $32, $09, $0B, $34, $01, $0D, $12
    .byte $03, $03, $2B, $06, $0A, $3A, $12, $0B, $3A, $11, $0A, $3A, $10, $09, $3A, $0F
    .byte $08, $3A, $0E, $07, $3A, $0D, $06, $3A, $0C, $05, $3A, $0B, $04, $FF, $27, $0E
    .byte $0D, $27, $0B, $0D, $37, $0B, $09, $35, $0E, $08, $2F, $0B, $06, $2B, $0E, $05
    .byte $FF, $35, $0C, $04, $2B, $0E, $0E, $2B, $10, $0E, $2B, $0D, $0F, $FF, $14, $09
    .byte $02, $39, $02, $09, $37, $01, $09, $38, $04, $0A, $38, $05, $0A, $38, $11, $0A
    .byte $39, $12, $0A, $38, $01, $0E, $32, $12, $10, $FF, $2C, $0B, $02, $34, $12, $01
    .byte $3A, $01, $06, $3A, $02, $06, $30, $01, $0B, $32, $02, $0B, $34, $11, $0A, $34
    .byte $12, $0A, $35, $01, $0F, $2B, $0F, $11, $24, $09, $05, $16, $06, $0C, $18, $09
    .byte $0C, $FF, $2B, $10, $0D, $2B, $03, $02, $2F, $0A, $0B, $37, $12, $01, $39, $11
    .byte $03, $38, $10, $04, $38, $0A, $04, $39, $09, $03, $3A, $08, $01, $FF, $33, $0F
    .byte $01, $34, $10, $01, $32, $0F, $03, $35, $01, $07, $37, $0D, $06, $39, $03, $11
    .byte $39, $04, $11, $20, $09, $11, $3C, $0C, $11, $FF, $37, $05, $02, $22, $04, $07
    .byte $37, $01, $0A, $22, $04, $0C, $3A, $01, $0F, $FF, $35, $03, $01, $2A, $06, $02
    .byte $18, $0D, $06, $2B, $0C, $0C, $2B, $07, $11, $2B, $05, $11, $FF, $34, $01, $01
    .byte $34, $02, $01, $37, $09, $02, $35, $07, $0B, $35, $12, $01, $1A, $05, $08, $1A
    .byte $0F, $08, $37, $06, $0B, $37, $05, $0B, $37, $0B, $02, $FF, $34, $11, $0E, $37
    .byte $01, $03, $2B, $0A, $01, $2B, $08, $08, $2B, $0A, $0D, $2B, $0D, $0D, $35, $06
    .byte $09, $FF, $30, $01, $02, $16, $06, $03, $37, $09, $01, $33, $12, $02, $34, $01
    .byte $06, $1E, $06, $08, $2D, $09, $08, $34, $04, $11, $32, $09, $11, $FF, $32, $12
    .byte $04, $32, $01, $04, $11, $01, $0B, $1A, $02, $01, $37, $01, $01, $2F, $11, $01
    .byte $FF, $2B, $08, $11, $32, $12, $0E, $3A, $06, $02, $3A, $04, $02, $3A, $03, $02
    .byte $3A, $01, $02, $37, $08, $0D, $FF, $32, $03, $0E, $2B, $02, $06, $2B, $04, $06
    .byte $14, $12, $0E, $37, $12, $0C, $37, $11, $0C, $37, $10, $0C, $FF, $2D, $0F, $11
    .byte $1A, $10, $0C, $37, $12, $0C, $38, $11, $0C, $3A, $11, $0A, $3A, $10, $0A, $3A
    .byte $0F, $0A, $39, $01, $03, $FF, $2C, $09, $03, $2C, $07, $03, $2C, $0C, $02, $11
    .byte $0C, $05, $2B, $11, $04, $2B, $11, $08, $30, $11, $0E, $0E, $0A, $08, $FF, $37
    .byte $01, $01, $2D, $06, $07, $37, $01, $0F, $3A, $0F, $01, $3A, $12, $01, $3A, $0F
    .byte $03, $3A, $12, $03, $39, $0F, $08, $39, $12, $08, $39, $0F, $0A, $39, $12, $0A
    .byte $FF, $30, $01, $0F, $3A, $02, $0E, $3A, $02, $0C, $3A, $01, $0C, $34, $06, $05
    .byte $2C, $08, $07, $2C, $0D, $07, $2C, $11, $07, $11, $12, $05, $FF, $38, $07, $03
    .byte $38, $0A, $03, $38, $0E, $02, $39, $0D, $05, $39, $0F, $05, $33, $04, $06, $33
    .byte $0E, $08, $FF, $2A, $0E, $02, $2A, $08, $06, $11, $01, $05, $FF, $35, $01, $01
    .byte $39, $01, $05, $39, $02, $05, $39, $03, $05, $3A, $01, $09, $3A, $02, $09, $3A
    .byte $03, $09, $37, $01, $0D, $35, $02, $0D, $37, $03, $0D, $2B, $0F, $0C, $12, $06
    .byte $06, $16, $0C, $11, $18, $0F, $11, $FF, $35, $01, $01, $35, $12, $01, $34, $12
    .byte $05, $33, $01, $05, $3A, $01, $09, $37, $02, $09, $37, $11, $09, $30, $12, $09
    .byte $30, $12, $0B, $11, $0B, $09, $1A, $09, $0E, $1A, $0A, $0E, $FF, $3A, $09, $01
    .byte $33, $01, $05, $35, $05, $05, $1E, $05, $08, $16, $07, $11, $18, $0A, $11, $FF
    .byte $2A, $02, $0C, $37, $0B, $01, $18, $0F, $02, $2C, $11, $05, $37, $11, $08, $12
    .byte $0E, $11, $FF, $2E, $07, $02, $2C, $01, $08, $2C, $03, $08, $2C, $05, $08, $2C
    .byte $0A, $0C, $35, $0B, $0F, $35, $0C, $0F, $34, $0D, $0F, $2C, $10, $0F, $FF, $2A
    .byte $01, $03, $33, $01, $07, $32, $01, $0A, $35, $02, $07, $11, $05, $07, $35, $0A
    .byte $07, $32, $12, $0A, $20, $0F, $03, $3A, $12, $01, $3A, $0E, $01, $3A, $07, $01
    .byte $3A, $0B, $01, $FF, $33, $08, $03, $32, $09, $05, $34, $0B, $03, $35, $0B, $01
    .byte $FF
