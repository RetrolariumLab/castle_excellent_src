; NMI room-row tile upload tasks 00-04
; CPU range $C8BC-$CF0A
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadRoomCellRow00:
    LDA #$20
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX RoomCells
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $01
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $02
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $03
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $04
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $05
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $06
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $07
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $08
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $09
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $0A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $0B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $0C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $0D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$24
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX RoomCells + $0E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $0F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $10
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $11
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow01:
    LDA #$21
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX RoomCells + $14
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $19
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $1F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $20
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $21
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX RoomCells + $22
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $23
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $24
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $25
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $26
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $27
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow02:
    LDA #$21
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX RoomCells + $28
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $29
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $2F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $30
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $31
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $32
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $33
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $34
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $35
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX RoomCells + $36
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $37
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $38
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $39
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $3A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $3B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow03:
    LDA #$21
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX RoomCells + $3C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $3D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $3E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $3F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $40
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $41
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $42
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $43
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $44
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $45
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $46
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $47
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $48
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $49
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX RoomCells + $4A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $4B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $4C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $4D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $4E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $4F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow04:
    LDA #$21
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX RoomCells + $50
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $51
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $52
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $53
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $54
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $55
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $56
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $57
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $58
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $59
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $5A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $5B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $5C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $5D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX RoomCells + $5E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $5F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $60
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $61
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $62
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $63
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
