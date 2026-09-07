; Room row upload tasks 10 through 14
; CPU range $D55A-$DBA8
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadRoomCellRow10:
    LDA #$22
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX RoomCells + $C8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $C9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $CF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX RoomCells + $D6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $D9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $DA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $DB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow11:
    LDA #$22
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX RoomCells + $DC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $DD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $DE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $DF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $E9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX RoomCells + $EA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $EB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $EC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $ED
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $EE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $EF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow12:
    LDA #$22
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX RoomCells + $F0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $F9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $FA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $FB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $FC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $FD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX RoomCells + $FE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $FF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $100
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $101
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $102
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $103
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow13:
    LDA #$22
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX RoomCells + $104
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $105
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $106
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $107
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $108
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $109
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $110
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $111
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX RoomCells + $112
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $113
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $114
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $115
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $116
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $117
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow14:
    LDA #$22
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX RoomCells + $118
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $119
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $120
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $121
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $122
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $123
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $124
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $125
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX RoomCells + $126
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $127
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $128
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $129
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
