; Preservation PRG before room-cell coordinate helpers
; CPU range $A3AC-$A589
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ResetRoomRuntimeState:
    LDA #$00
    STA $3B
    STA $3F
    STA NmiTaskIndex
    STA $34
    STA $35
    STA a:$0774
    STA a:$07C6
    STA $3C
    STA RoomFrameCounter
    STA $40
    RTS

EnsureRoomAudioPlaying:
    LDA a:$07CC
    BNE Label_A3D1
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BEQ SelectRoomAudio

Label_A3D1:
    RTS

AnimateRoomCells:
    JSR Func_A41F
    LDA RoomFrameCounter
    LSR A
    BCC Label_A41A
    INC $40
    BMI Label_A41A
    LDA $40
    AND #$03
    BNE Label_A41A
    LDA #$04
    STA $22
    LDA #$00
    STA $21

Label_A3ED:
    LDY #$00
    LDA ($21),Y
    CMP #$45
    BCC Label_A40A
    CMP #$49
    BCS Label_A40A
    TAX
    LDA a:$A3D6,X
    STA ($21),Y
    LDA $21
    STA $44
    LDA $22
    STA $45
    JSR RequestRoomCellRowUpdate

Label_A40A:
    INC $21
    BNE Label_A410
    INC $22

Label_A410:
    LDA $21
    CMP #$90
    LDA $22
    SBC #$05
    BCC Label_A3ED

Label_A41A:
    RTS
    .byte $46, $47, $48, $45

Func_A41F:
    LDA RoomFrameCounter
    LSR A
    BCC Label_A47E
    LDA #$04
    STA $22
    LDA #$00
    STA $21

Label_A42D:
    LDY #$00
    LDA ($21),Y
    CMP #$35
    BCC Label_A451
    CMP #$41
    BCS Label_A451
    TAX
    LDA a:$A44A,X
    STA ($21),Y
    CPX #$39
    BCS Label_A46E
    LDA $21
    STA $44
    LDA $22
    STA $45
    JSR RequestRoomCellRowUpdate
    JMP Label_A46E

Label_A451:
    CMP #$56
    BCC Label_A46E
    CMP #$62
    BCS Label_A46E
    TAX
    LDA a:$A435,X
    STA ($21),Y
    CPX #$5A
    BCS Label_A46E
    LDA $21
    STA $44
    LDA $22
    STA $45
    JSR RequestRoomCellRowUpdate

Label_A46E:
    INC $21
    BNE Label_A474
    INC $22

Label_A474:
    LDA $21
    CMP #$90
    LDA $22
    SBC #$05
    BCC Label_A42D

Label_A47E:
    RTS
    .byte $38, $35, $36, $37, $3C, $39, $3A, $3B, $40, $3D, $3E, $3F, $57, $58, $59, $56
    .byte $5B, $5C, $5D, $5A, $5F, $60, $61, $5E

FormatPlayerScoreTiles:
    JSR Func_A563
    LDA PlayerScoreLo
    STA $03
    LDA PlayerScoreHi
    STA $04
    JMP Label_A4B0

FormatHighScoreTiles:
    JSR Func_A563
    LDA $0B
    STA $03
    LDA $0C
    STA $04

Label_A4B0:
    LDX #$00

Label_A4B2:
    SEC

Label_A4B3:
    LDA $03
    SBC a:$A556,X
    STA $03
    LDA $04
    SBC a:$A551,X
    STA $04
    BCC Label_A4C8
    INC StatusScoreTiles,X
    BCS Label_A4B3

Label_A4C8:
    LDA $03
    ADC a:$A556,X
    STA $03
    LDA $04
    ADC a:$A551,X
    STA $04
    INX
    CPX #$05
    BCC Label_A4B2
    LDX #$04

Label_A4DD:
    LDA StatusScoreTiles,X
    CLC
    ADC #$60
    STA StatusScoreTiles,X
    DEX
    BPL Label_A4DD
    LDX #$00

Label_A4EB:
    LDA StatusScoreTiles,X
    CMP #$60
    BNE Label_A4FC
    LDA #$FF
    STA StatusScoreTiles,X
    INX
    CPX #$05
    BCC Label_A4EB

Label_A4FC:
    LDA #$60
    STA StatusLivesTiles
    STA StatusLivesTiles + $01
    STA StatusLivesTiles + $02
    LDA $13

Label_A509:
    CMP #$64
    BCC Label_A515
    SBC #$64
    INC StatusLivesTiles + $02
    JMP Label_A509

Label_A515:
    CMP #$0A
    BCC Label_A521
    SBC #$0A
    INC StatusLivesTiles + $01
    JMP Label_A515

Label_A521:
    CLC
    ADC #$60
    STA StatusLivesTiles
    LDX #$02

Label_A529:
    LDA StatusLivesTiles,X
    CMP #$60
    BNE Label_A538
    LDA #$FF
    STA StatusLivesTiles,X
    DEX
    BNE Label_A529

Label_A538:
    LDX #$05

Label_A53A:
    LDA $05,X
    CMP #$09
    BCC Label_A542
    LDA #$09

Label_A542:
    CLC
    ADC #$60
    STA StatusInventoryTiles,X
    DEX
    BPL Label_A53A
    LDA #$00
    STA StatusTilesBusy
    RTS
    .byte $27, $03, $00, $00, $00, $10, $E8, $64, $0A, $01

MutableCellStateBitMasks:
    .byte $01, $02, $04, $08, $10, $20, $40, $80

Func_A563:
    LDA #$FF
    STA StatusTilesBusy
    LDA #$00
    LDX #$07

Label_A56C:
    STA StatusScoreTiles,X
    DEX
    BPL Label_A56C
    RTS
    .byte $85, $1B, $29, $07, $A8, $A5, $1B, $86, $1B, $46, $1B, $6A, $46, $1B, $6A, $46
    .byte $1B, $6A, $AA, $B9, $5B, $A5, $60
