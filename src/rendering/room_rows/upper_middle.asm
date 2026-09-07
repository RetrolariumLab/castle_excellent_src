; Room row upload tasks 05 through 09
; CPU range $CF0B-$D559
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadRoomCellRow05:
    LDA #$21
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX RoomCells + $64
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $65
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $66
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $67
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $68
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $69
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $6F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $70
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $71
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX RoomCells + $72
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $73
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $74
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $75
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $76
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $77
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow06:
    LDA #$21
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX RoomCells + $78
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $79
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $7F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $80
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $81
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $82
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $83
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $84
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $85
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX RoomCells + $86
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $87
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $88
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $89
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $8A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $8B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow07:
    LDA #$21
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX RoomCells + $8C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $8D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $8E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $8F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $90
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $91
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $92
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $93
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $94
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $95
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $96
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $97
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $98
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $99
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX RoomCells + $9A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $9B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $9C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $9D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $9E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $9F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow08:
    LDA #$21
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX RoomCells + $A0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $A9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $AA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $AB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $AC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $AD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX RoomCells + $AE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $AF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow09:
    LDA #$22
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX RoomCells + $B4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $B9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $BF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX RoomCells + $C2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
