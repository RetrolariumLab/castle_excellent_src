; Room row upload tasks 15 through 19
; CPU range $DBA9-$E1F7
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UploadRoomCellRow15:
    LDA #$22
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX RoomCells + $12C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $12F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $130
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $131
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $132
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $133
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $134
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $135
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $136
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $137
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $138
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $139
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX RoomCells + $13A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $13F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow16:
    LDA #$22
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX RoomCells + $140
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $141
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $142
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $143
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $144
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $145
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $146
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $147
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $148
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $149
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $14A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $14B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $14C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $14D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX RoomCells + $14E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $14F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $150
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $151
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $152
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $153
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow17:
    LDA #$23
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX RoomCells + $154
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $155
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $156
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $157
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $158
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $159
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $15F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $160
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $161
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX RoomCells + $162
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $163
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $164
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $165
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $166
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $167
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow18:
    LDA #$23
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX RoomCells + $168
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $169
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $16F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $170
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $171
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $172
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $173
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $174
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $175
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX RoomCells + $176
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $177
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $178
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $179
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame

UploadRoomCellRow19:
    LDA #$23
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX RoomCells + $17C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $17F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $180
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $181
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $182
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $183
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $184
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $185
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $186
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $187
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $188
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $189
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX RoomCells + $18A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX RoomCells + $18F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
