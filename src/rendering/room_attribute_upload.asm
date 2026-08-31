; NMI left and right room attribute upload tasks
; CPU range $E1F8-$E45C
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
