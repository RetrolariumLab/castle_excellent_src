; Preservation PRG before the room decoder
; CPU range $8000-$E45C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

.segment "PRG"

Func_8000:
    LDX #$91

Label_8002:
    DEX
    BNE Label_8002
    RTS

Func_8006:
    LDX #$47

Label_8008:
    DEX
    BNE Label_8008
    RTS

Func_800C:
    LDY #$00

Label_800E:
    INY
    BEQ Label_801F
    LDA JOYPAD1
    AND #$02
    EOR $30
    BEQ Label_800E
    EOR $30
    STA $30
    RTS

Label_801F:
    DEY
    RTS

Func_8021:
    LDX #$28
    LDY #$00

Label_8025:
    LDA JOYPAD1
    AND #$02
    EOR $30
    BEQ Label_8037
    EOR $30
    STA $30
    INY
    DEX
    BNE Label_8025
    RTS

Label_8037:
    LDA $30
    LDA $30
    LDA $30
    DEX
    BNE Label_8025
    RTS

Func_8041:
    LDA #$00
    STA JOYPAD1
    JSR Func_8000
    LDA #$01
    STA JOYPAD1
    JSR Func_8000
    LDA #$00
    STA JOYPAD1
    RTS

Func_8057:
    BCC Func_8041

Func_8059:
    LDA #$00
    STA JOYPAD1
    JSR Func_8006
    LDA #$01
    STA JOYPAD1
    JSR Func_8006
    LDA #$00
    STA JOYPAD1
    JSR Func_8006
    LDA #$01
    STA JOYPAD1
    JSR Func_8006
    LDA #$00
    STA JOYPAD1
    RTS

Func_807F:
    LDA #$04
    STA JOYPAD1
    LDX #$00
    STX $30

Label_8088:
    JSR Func_800C
    CPY #$12
    BCC Func_807F
    CPY #$1A
    BCS Func_807F
    INX
    BNE Label_8088
    RTS

Func_8097:
    LDA #$21
    STA $2F
    LDY #$00

Label_809D:
    JSR Func_8059
    DEY
    BNE Label_809D
    DEC $2F
    BNE Label_809D
    CLC
    RTS

Func_80A9:
    JSR Func_8041
    LDY #$08

Label_80AE:
    ASL $17
    JSR Func_8057
    DEY
    BNE Label_80AE
    JSR Func_8059
    JMP Func_8059

Func_80BC:
    LDA JOYPAD1
    AND #$02
    BEQ Func_80BC

Label_80C3:
    LDA JOYPAD1
    AND #$02
    BNE Label_80C3
    STA $30
    JSR Func_800C

Label_80CF:
    STY $2D
    JSR Func_800C
    TYA
    CLC
    ADC $2D
    BCS Label_80CF
    CMP #$50
    BCC Label_80CF
    LDA #$08
    STA $2E

Label_80E2:
    JSR Func_8021
    CPY #$04
    BCS Label_80FE
    CPY #$02
    ROL $17
    TYA
    LSR A
    BCS Label_80F4
    JSR Func_800C

Label_80F4:
    JSR Func_800C
    DEC $2E
    BNE Label_80E2
    LDA $2D
    CLC

Label_80FE:
    RTS

ReadController1:
    JSR DisableNmi
    JSR PollController1
    JSR EnableNmi
    LDA $20
    RTS

Func_810B:
    JSR PollController1
    LDA $20
    RTS

PollController1:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #$08

Label_811C:
    LDA JOYPAD1
    LSR A
    BCS Label_8123
    LSR A

Label_8123:
    ROR $20
    DEX
    BNE Label_811C
    RTS

ReadController2:
    JSR DisableNmi
    JSR PollController2
    JSR EnableNmi
    LDA $20
    RTS
    .byte $20, $3B, $81, $A5, $20, $60

PollController2:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #$08

Label_8146:
    LDA a:$4017
    LSR A
    BCS Label_814D
    LSR A

Label_814D:
    ROR $20
    DEX
    BNE Label_8146
    JSR EnableNmi
    LDA $20
    RTS

DisableNmi:
    LDA #$30
    STA PPU_CTRL
    RTS

EnableNmi:
    LDA #$B0
    STA PPU_CTRL
    RTS

DisableRendering:
    LDA #$00
    STA PPU_MASK
    RTS

WaitForVblankAndEnableRendering:
    LDA PPU_STATUS
    BPL WaitForVblankAndEnableRendering
    LDA #$1E
    STA PPU_MASK
    RTS

SelectChrBank:
    LDA a:$817C,Y
    STA a:$817C,Y
    RTS
    .byte $00, $01, $02, $03

Func_8180:
    BIT $1F
    BPL Label_8187
    JMP Func_8097

Label_8187:
    JSR Func_821A
    LDA #$00
    STA $17
    JSR Func_81EA
    LDA #$AA
    STA $17
    JSR Func_81EA
    LDA #$55
    STA $17
    JMP Func_81EA

Func_819F:
    BIT $1F
    BPL Label_81A6
    JMP Func_807F

Label_81A6:
    JSR Func_821A
    JSR Func_81FF
    JSR Func_81FF
    LDA $17
    CMP #$AA
    BNE Label_81C0
    JSR Func_81FF
    LDA $17
    CMP #$55
    BNE Label_81C0
    CLC
    RTS

Label_81C0:
    SEC
    RTS

Func_81C2:
    STA $17
    STX $1A
    BIT $1F
    BPL Label_81D0
    JSR Func_80A9
    JMP Label_81D3

Label_81D0:
    JSR Func_81EA

Label_81D3:
    LDX $1A
    RTS

Func_81D6:
    STX $1A
    BIT $1F
    BMI Label_81E2
    JSR Func_81FF
    JMP Label_81E5

Label_81E2:
    JSR Func_80BC

Label_81E5:
    LDX $1A
    LDA $17
    RTS

Func_81EA:
    LDY #$07

Label_81EC:
    ASL $17
    LDA #$00
    ROL A
    ORA #$06
    STA JOYPAD1
    AND #$03
    STA JOYPAD1
    DEY
    BPL Label_81EC
    RTS

Func_81FF:
    LDY #$07

Label_8201:
    LDA a:$4017
    LSR A
    LSR A
    AND #$01
    ORA #$06
    STA JOYPAD1
    AND #$03
    STA JOYPAD1
    LSR A
    ROL $17
    DEY
    BPL Label_8201
    CLC
    RTS

Func_821A:
    LDA #$00
    STA JOYPAD1
    LDA #$02
    STA JOYPAD1
    RTS

Reset:
    SEI
    CLD
    LDA #$00
    STA PPU_CTRL

Label_822C:
    LDA PPU_STATUS
    BPL Label_822C

Label_8231:
    LDA PPU_STATUS
    BPL Label_8231
    CLD
    LDX #$FF
    TXS
    LDX #$02

Label_823C:
    LDA a:$077E,X
    CMP a:$82C9,X
    BNE Label_8249
    DEX
    BPL Label_823C
    BMI Label_8260

Label_8249:
    LDX #$02

Label_824B:
    LDA a:$82C9,X
    STA a:$077E,X
    DEX
    BPL Label_824B
    LDA #$00
    STA $01
    STA $02
    STA a:$0783
    STA a:$0784

Label_8260:
    INC a:$0783
    BNE Label_8268
    INC a:$0784

Label_8268:
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JSR Func_F8FC
    JSR Func_A2B1
    JSR LoadRoom

Label_8277:
    LDA PPU_STATUS
    BPL Label_8277
    JSR EnableNmi
    JSR WaitForVblankAndEnableRendering

Label_8282:
    LDA #$02
    STA $FC
    JSR Func_EA36
    LDA a:$07C5
    BNE Label_82C3
    JSR Func_A4A5
    JSR Func_A8E3
    LDA a:$07C4
    BNE Label_82AE
    JSR Func_82CE
    JSR Func_A835
    JSR Func_A3C6
    JSR Func_9583
    JSR Func_9386
    JSR Func_A3D2
    INC a:$076B

Label_82AE:
    JSR Func_C43D
    JSR Func_AC13
    JSR Func_F9AD
    LDA a:$07C7
    BEQ Label_82C3
    LDA a:$07CE
    AND #$08
    BNE Label_8268

Label_82C3:
    LDA $FC
    BNE Label_82C3
    BEQ Label_8282
    BVC Label_831A
    .byte $57, $45, $52

Func_82CE:
    LDA a:$0772
    BEQ Label_82D4
    RTS

Label_82D4:
    LDA $3A
    BNE Label_82DB
    JMP Label_867A

Label_82DB:
    JSR Func_A64D
    AND #$03
    BNE Label_82FA
    LDA Controller1Buttons
    AND #$01
    BNE Label_82FA
    STA $3C
    LDA $EC
    CMP #$01
    BNE Label_82FA
    LDA #$0E
    STA APU_STATUS
    LDA #$00
    STA $EC

Label_82FA:
    LDA Controller1Buttons
    AND #$02
    BNE Label_8309
    STA a:$0779
    STA a:$077A
    BEQ Label_8320

Label_8309:
    LDA a:$077A
    BNE Label_8318
    LDA #$0A
    STA a:$0779
    STA a:$077A
    BNE Label_8320

Label_831A = * + 2  ; overlapping entry $831A

Label_8318:
    LDA a:$0779
    BEQ Label_8320
    DEC a:$0779

Label_8320:
    LDA $3C
    CMP #$21
    BCC Label_8331
    LDA $38
    AND #$07
    BNE Label_8331
    DEC $3C
    JSR Func_C20D

Label_8331:
    JSR Func_A64D
    BNE Label_8339
    JMP Label_83A4

Label_8339:
    DEC $3C
    BNE Label_8341
    LDA #$FF
    STA $3E

Label_8341:
    LDA $3C
    CMP #$10
    BCS Label_834A
    JMP Label_8478

Label_834A:
    LDY $3A
    DEY
    DEY
    STY $1A
    CPY #$10
    BCS Label_8357
    JMP Label_8478

Label_8357:
    JSR Func_94DB
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    LDA $39
    LDX $38
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    JSR Func_94DF
    LDY $1A
    JSR Func_8DD3
    BCS Label_837D
    DEC $3A
    DEC $3A
    JMP Label_8478

Label_837D:
    ASL A
    TAX
    BCS Label_838E
    LDA a:$903F,X
    STA $31
    LDA a:$9040,X
    STA $32
    JMP Label_8398

Label_838E:
    LDA a:$9107,X
    STA $31
    LDA a:$9108,X
    STA $32

Label_8398:
    LDA #$83
    PHA
    LDA #$A0
    PHA
    JMP ($0031)
    JMP Label_8478

Label_83A4:
    LDA #$11
    STA $1F

Label_83A8:
    LDA #$00
    STA $1E
    STA $2F
    LDA $3A
    CLC
    ADC $1F
    TAY
    JSR Func_94DB
    JSR Func_8DD3
    BCC Label_83C5
    STA $30
    JSR Func_A044
    BCS Label_840F
    INC $1E

Label_83C5:
    LDA $3A
    CLC
    ADC $1F
    TAY
    LDX $38
    LDA $39
    JSR Func_8DD3
    BCC Label_83DD
    STA $2F
    JSR Func_A044
    BCS Label_840F
    INC $1E

Label_83DD:
    LDA $3A
    CLC
    ADC $1F
    TAY
    JSR Func_94DF
    JSR Func_8DD3
    BCS Label_840F
    LDA $1E
    BEQ Label_83F8
    LDA $2F
    BNE Label_83F5
    LDA $30

Label_83F5:
    JMP Label_840F

Label_83F8:
    LDA #$FF
    STA $3E
    LDA $1F
    CMP #$11
    BNE Label_8404
    INC $3A

Label_8404:
    INC $3A
    LDA $3A
    CMP #$A0
    BCC Label_8478
    JMP Label_86A0

Label_840F:
    LDX #$10
    CPX $1F
    BEQ Label_841A
    STX $1F
    JMP Label_83A8

Label_841A:
    ASL A
    TAX
    BCS Label_842B
    LDA a:$8F29,X
    STA $31
    LDA a:$8F2A,X
    STA $32
    JMP Label_8435

Label_842B:
    LDA a:$8FF1,X
    STA $31
    LDA a:$8FF2,X
    STA $32

Label_8435:
    LDA #$84
    PHA
    LDA #$3D
    PHA
    JMP ($0031)
    LDA $3C
    CMP #$21
    BCS Label_846B
    LDA Controller1Buttons
    AND #$01
    BEQ Label_847B
    LDA $38
    AND #$07
    BNE Label_8467
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_8467
    LDA a:$07CA
    BMI Label_8478
    INC a:$07CA
    JMP Label_8478

Label_8467:
    LDA #$21
    STA $3C

Label_846B:
    LDA $38
    AND #$07
    BNE Label_8478
    LDA #$20
    STA $3C
    JSR Func_C20D

Label_8478:
    JMP Label_8490

Label_847B:
    LDA Controller1Buttons
    AND #$C0
    BNE Label_8490
    LDA $38
    AND #$07
    BNE Label_8490
    LDA #$00
    STA a:$07C9
    STA a:$07CA

Label_8490:
    LDA a:$0779
    BEQ Label_849F
    JSR Func_A64D
    ORA $3E
    BNE Label_849F
    JMP Label_85CA

Label_849F:
    LDA $3F
    BEQ Label_84A8
    DEC $3F
    JMP Label_8512

Label_84A8:
    LDA a:$0774
    PHP
    LDA #$00
    STA a:$0774
    PLP
    BNE Label_84C8
    LDA $3B
    BEQ Label_84D9
    LDA $38
    AND #$07
    BNE Label_8512
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    BNE Label_84D9

Label_84C8:
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    LDA $38
    AND #$07
    BEQ Label_84D9
    JMP Label_85CA

Label_84D9:
    LDA #$00
    STA $3B
    LDA Controller1Buttons
    AND #$C0
    BNE Label_84E7
    JMP Label_85CA

Label_84E7:
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_84FD
    LDA a:$07C9
    BMI Label_84FA
    INC a:$07C9

Label_84FA:
    JMP Label_85CA

Label_84FD:
    LDA Controller1Buttons
    AND #$C0
    BEQ Label_8512
    CMP #$C0
    BEQ Label_8512
    LDX #$7F
    CMP #$40
    BNE Label_8510
    LDX #$FF

Label_8510:
    STX $3B

Label_8512:
    LDA $3B
    BNE Label_8519
    JMP Label_85CA

Label_8519:
    BMI Label_8538
    LDA $38
    CLC
    ADC #$11
    STA $21
    LDA $39
    ADC #$00
    STA $22
    LDA $38
    CLC
    ADC #$02
    STA $23
    LDA $39
    ADC #$00
    STA $24
    JMP Label_8549

Label_8538:
    LDA $38
    SEC
    SBC #$02
    STA $21
    STA $23
    LDA $39
    SBC #$00
    STA $22
    STA $24

Label_8549:
    LDA $24
    BEQ Label_855D
    CMP #$01
    BEQ Label_8554
    JMP Label_86C6

Label_8554:
    LDA $23
    CMP #$31
    BCC Label_855D
    JMP Label_870F

Label_855D:
    LDA #$FF
    STA a:$07CB
    LDA $3A
    CLC
    ADC #$0F
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR Func_8DD3
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA $3A
    CLC
    ADC #$07
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR Func_8DD3
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA $22
    LDX $21
    LDY $3A
    STY $1E
    JSR Func_8DD3
    BCS Label_85A6
    LDA $24
    STA $39
    LDA $23
    STA $38
    JMP Label_85CA

Label_85A6:
    ASL A
    TAX
    BCS Label_85B7
    LDA a:$9155,X
    STA $31
    LDA a:$9156,X
    STA $32
    JMP Label_85C1

Label_85B7:
    LDA a:$921D,X
    STA $31
    LDA a:$921E,X
    STA $32

Label_85C1:
    LDA #$85
    PHA
    LDA #$C9
    PHA
    JMP ($0031)

Label_85CA:
    LDA a:$0779
    BNE Label_85D2
    JMP Label_8673

Label_85D2:
    LDA $3B
    BNE Label_85D9
    JMP Label_8673

Label_85D9:
    BMI Label_85F5
    LDA $38
    CLC
    ADC #$16
    STA $21
    LDA $39
    ADC #$00
    STA $22
    LDA $21
    CMP #$40
    LDA $22
    SBC #$01
    BCC Label_8604
    JMP Label_8673

Label_85F5:
    LDA $38
    SEC
    SBC #$06
    STA $21
    LDA $39
    SBC #$00
    STA $22
    BMI Label_8673

Label_8604:
    LDA $3A
    SEC
    SBC #$05
    STA $16
    LDX #$00

Label_860D:
    LDA RuntimeObjectRecords,X
    BPL Label_866A
    CMP #$A8
    BCS Label_866A
    TAY
    LDA $16
    SEC
    SBC RuntimeObjectY,X
    BCC Label_866A
    SBC a:$AA9A,Y
    BCS Label_866A
    LDA $21
    STA $23
    LDA $22
    STA $24
    LDA $23
    SEC
    SBC RuntimeObjectXLo,X
    STA $23
    LDA $24
    SBC RuntimeObjectXHi,X
    BCC Label_866A
    STA $24
    LDA $23
    SBC a:$AA6A,Y
    BCS Label_866A
    LDA $24
    BNE Label_866A
    LDA RuntimeObjectRecords,X
    CMP #$85
    BEQ Label_8673
    CMP #$89
    BEQ Label_8673
    CMP #$86
    BEQ Label_8673
    STX $16
    TYA
    JSR Func_A05E
    BNE Label_8673
    LDA #$A8
    LDX $16
    STA RuntimeObjectRecords,X
    LDA #$00
    STA $4E,X
    JSR Func_C233
    JMP Label_8673

Label_866A:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_860D

Label_8673:
    LDA Controller1Buttons
    STA a:$0777
    RTS

Label_867A:
    LDA #$98
    STA $3A
    STA $12
    LDA $39
    STA $11
    LDA $38
    AND #$F8
    STA $38
    STA $10
    JSR Func_8758
    JSR Func_A7DB
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR Func_C43D
    JMP Func_952D

Label_86A0:
    LDA #$10
    STA $3A
    STA $12
    LDA $39
    STA $11
    LDA $38
    AND #$F8
    STA $38
    STA $10
    JSR Func_8758
    JSR Func_A7E6
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR Func_C43D
    JMP Func_952D

Label_86C6:
    LDA CurrentRoomIndex
    JSR Func_A816
    BNE Label_86D6
    LDA #$00
    STA $38
    STA $39
    JMP Func_C43D

Label_86D6:
    LDA #$30
    STA $38
    STA $10
    LDA #$01
    STA $39
    STA $11
    LDA $3A
    STA $12
    JSR Func_8758
    JSR Func_A7FE
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR Func_C43D
    LDA $3A
    SEC
    SBC #$10
    TAY
    LDA #$01
    LDX #$30
    JSR Func_A58A
    JSR Func_A66D
    BCS Label_870C
    JSR Func_A70A

Label_870C:
    JMP Func_952D

Label_870F:
    LDA CurrentRoomIndex
    JSR Func_A80B
    BNE Label_8721
    LDA #$01
    STA $39
    LDA #$30
    STA $38
    JMP Func_C43D

Label_8721:
    LDA #$00
    STA $38
    STA $39
    STA $10
    STA $11
    LDA $3A
    STA $12
    JSR Func_8758
    JSR Func_A7F1
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR Func_C43D
    LDA $3A
    SEC
    SBC #$10
    TAY
    LDA #$00
    LDX #$00
    JSR Func_A58A
    JSR Func_A66D
    BCS Label_8755
    JSR Func_A70A

Label_8755:
    JMP Func_952D

Func_8758:
    LDX #$00

Label_875A:
    SEC
    LDA RuntimeObjectRecords,X
    BPL Label_8761
    CMP #$A8

Label_8761:
    ROR $18
    ROR $17
    ROR $16
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_875A
    LDA CurrentRoomIndex
    STA a:$0712
    LDA $16
    STA a:$0713
    LDA $17
    STA a:$0714
    LDA $18
    STA a:$0715
    RTS
    .byte $A5, $38, $38, $E9, $02, $85, $21, $A5, $39, $E9, $00, $85, $22, $30, $36, $A4
    .byte $3A, $A6, $21, $A5, $22, $20, $D3, $8D, $B0, $2B, $A5, $3A, $18, $69, $07, $A8
    .byte $A6, $21, $A5, $22, $20, $D3, $8D, $B0, $1C, $A5, $3A, $18, $69, $0F, $A8, $A6
    .byte $21, $A5, $22, $20, $D3, $8D, $B0, $0D, $A5, $21, $85, $38, $A5, $22, $85, $39
    .byte $A9, $FF, $8D, $74, $07, $60, $A5, $38, $18, $69, $02, $85, $21, $A5, $39, $69
    .byte $00, $85, $22, $A5, $38, $18, $69, $11, $85, $23, $A5, $39, $69, $00, $85, $24
    .byte $A5, $38, $C9, $3F, $A5, $39, $E9, $01, $B0, $DB, $A4, $3A, $A6, $23, $A5, $24
    .byte $20, $D3, $8D, $B0, $D0, $A5, $3A, $18, $69, $07, $A8, $A6, $23, $A5, $24, $20
    .byte $D3, $8D, $B0, $C1, $A5, $3A, $18, $69, $0F, $A8, $A6, $23, $A5, $24, $20, $D3
    .byte $8D, $B0, $B2, $90, $A3, $20, $4D, $A6, $05, $3E, $F0, $01, $60, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $EA, $94, $20, $5D, $95, $B0, $21, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $F2, $94, $20, $5D, $95, $B0, $11, $A6, $41, $B5
    .byte $4D, $18, $69, $11, $A8, $20, $08, $95, $20, $5D, $95, $B0, $01, $60, $A6, $41
    .byte $86, $1C, $A5, $3B, $30, $62, $A9, $FF, $85, $41, $A5, $38, $18, $69, $11, $AA
    .byte $A5, $39, $69, $00, $A4, $3A, $20, $D3, $8D, $90, $08, $A5, $41, $C5, $1C, $F0
    .byte $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $07, $A8, $A5, $38, $18
    .byte $69, $10, $AA, $A5, $39, $69, $00, $20, $D3, $8D, $90, $08, $A5, $41, $C5, $1C
    .byte $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $0F, $A8, $A5, $38
    .byte $18, $69, $10, $AA, $A5, $39, $69, $00, $20, $D3, $8D, $90, $08, $A5, $41, $C5
    .byte $1C, $F0, $02, $38, $60, $4C, $1C, $89, $A9, $FF, $85, $41, $A5, $38, $38, $E9
    .byte $02, $AA, $A5, $39, $E9, $00, $A4, $3A, $20, $D3, $8D, $90, $08, $A5, $41, $C5
    .byte $1C, $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $07, $A8, $A5
    .byte $38, $38, $E9, $01, $AA, $A5, $39, $E9, $00, $20, $D3, $8D, $90, $08, $A5, $41
    .byte $C5, $1C, $F0, $02, $38, $60, $A9, $FF, $85, $41, $A5, $3A, $18, $69, $0F, $A8
    .byte $A5, $38, $38, $E9, $01, $AA, $A5, $39, $E9, $00, $20, $D3, $8D, $90, $08, $A5
    .byte $41, $C5, $1C, $F0, $02, $38, $60, $A6, $1C, $A5, $3B, $30, $18, $B5, $4B, $18
    .byte $69, $10, $85, $25, $B5, $4C, $69, $00, $85, $26, $A5, $25, $C9, $40, $A5, $26
    .byte $E9, $01, $90, $1B, $60, $B5, $4B, $85, $25, $B5, $4C, $85, $26, $A5, $25, $D0
    .byte $02, $C6, $26, $C6, $25, $A5, $25, $C9, $40, $A5, $26, $E9, $01, $B0, $E5, $B4
    .byte $4D, $A5, $26, $A6, $25, $20, $5D, $95, $B0, $26, $30, $24, $A6, $1C, $B5, $4D
    .byte $18, $69, $07, $A8, $A5, $26, $A6, $25, $20, $5D, $95, $B0, $13, $30, $11, $A6
    .byte $1C, $B5, $4D, $18, $69, $0F, $A8, $A5, $26, $A6, $25, $20, $5D, $95, $90, $1B
    .byte $C9, $80, $90, $15, $20, $5E, $A0, $D0, $10, $A6, $42, $A9, $A8, $95, $4A, $A9
    .byte $00, $95, $4E, $20, $33, $C2, $4C, $A0, $89, $38, $60, $A6, $1C, $A5, $3B, $30
    .byte $1E, $B5, $4B, $18, $69, $02, $95, $4B, $90, $02, $F6, $4C, $A5, $38, $18, $69
    .byte $02, $85, $38, $90, $02, $E6, $39, $A9, $7F, $8D, $73, $07, $4C, $DF, $89, $B5
    .byte $4B, $38, $E9, $02, $95, $4B, $B0, $02, $D6, $4C, $A5, $38, $38, $E9, $02, $85
    .byte $38, $B0, $02, $C6, $39, $A9, $FF, $8D, $73, $07, $18

Label_89E0:
    RTS
    .byte $A9, $00, $8D, $73, $07, $20, $1A, $88, $AD, $73, $07, $D0, $01, $60, $10, $03
    .byte $4C, $C2, $8A, $A6, $41
    LDY RuntimeObjectY,X
    DEY
    JSR Func_94F2
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$41
    BCC Label_89E0
    CMP #$44
    BCS Label_89E0
    LDA a:$0773
    BEQ Label_89E0
    BPL Label_8A15
    JMP Func_8AC2

Label_8A15:
    LDX #$00

Label_8A17:
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8A27
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8A17
    RTS

Label_8A27:
    STX $1E
    LDX #$00

Label_8A2B:
    LDA RuntimeObjectRecords,X
    CMP #$A5
    BEQ Label_8A3B
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8A2B
    RTS

Label_8A3B:
    STX $1F
    LDA RuntimeObjectY,X
    CLC
    ADC #$09
    TAY
    STY $1C
    JSR Func_94EA
    JSR Func_955D
    CMP #$53
    BEQ Label_8A52
    JMP Label_8AC1

Label_8A52:
    LDY $1C
    LDX $1F
    JSR Func_9508
    JSR Func_955D
    CMP #$53
    BEQ Label_8A63
    JMP Label_8AC1

Label_8A63:
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$0A
    TAY
    JSR Func_94EA
    JSR Func_955D
    CMP #$53
    BNE Label_8AC1
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$0A
    TAY
    JSR Func_9508
    JSR Func_955D
    CMP #$53
    BNE Label_8AC1
    LDY $1C
    LDX $1F
    JSR Func_9508
    JSR Func_955D
    CMP #$53
    BNE Label_8AC1
    LDX $1E
    LDY RuntimeObjectY,X
    INY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$00
    LDA #$52
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_949C
    LDX $1E
    JSR Func_8ABB
    LDX $1F

Func_8ABB:
    LDY RuntimeObjectY,X
    INY
    INY
    STY RuntimeObjectY,X

Label_8AC1:
    RTS

Func_8AC2:
    LDX CurrentObjectOffset
    LDY RuntimeObjectY,X
    DEY
    JSR Func_94FD
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$41
    BCC Label_8AC1
    CMP #$44
    BCS Label_8AC1
    LDX #$00

Label_8ADB:
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8AEB
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8ADB
    RTS

Label_8AEB:
    STX $1E
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94EA
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$52
    BEQ Label_8B00
    RTS

Label_8B00:
    LDX #$00

Label_8B02:
    LDA RuntimeObjectRecords,X
    CMP #$A5
    BEQ Label_8B12
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_8B02
    RTS

Label_8B12:
    STX $1F
    LDX $1E
    LDA RuntimeObjectY,X
    CLC
    ADC #$06
    TAY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$00
    LDA #$53
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_949C
    JSR Func_9A2C
    LDX $1E
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y
    LDX $1F
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y
    LDA #$10
    STA $47

Label_8B51:
    LDA #$00
    STA $16
    LDX #$00
    STX $17

Label_8B59:
    LDX $17
    LDA a:$07AB,X
    BMI Label_8B6D

Label_8B60:
    INX
    CPX #$18
    STX $17
    BCC Label_8B59
    LDA $16
    BNE Label_8B51
    BEQ Label_8BB0

Label_8B6D:
    LDA #$7F
    STA a:$07AB,X
    LDA a:$8F10,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #$08
    STA $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA RuntimeObjectRecords,X
    TAY
    LDA a:$AA6A,Y
    STA $47
    LDX #$00

Label_8B8F:
    JSR Func_A247
    BCS Label_8BA9
    JSR Func_9A1F
    LDA a:$07AB,Y
    BNE Label_8BA1
    LDA #$FF
    STA a:$07AB,Y

Label_8BA1:
    TXA
    CLC
    ADC #$06
    TAX
    JMP Label_8B8F

Label_8BA9:
    INC $16
    LDX $17
    JMP Label_8B60

Label_8BB0:
    LDX #$00
    STX $16

Label_8BB4:
    LDX $16
    LDA a:$07AB,X
    BEQ Label_8BF9
    LDA a:$8F10,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #$02
    BCC Label_8BEB
    STA RuntimeObjectY,X
    TAY
    LDA RuntimeObjectRecords,X
    CMP #$A4
    BEQ Label_8BF9
    JSR Func_94EA
    JSR Func_A1A3
    BCS Label_8BEB
    BMI Label_8BEB
    LDX $16
    LDA a:$8F10,X
    TAX
    LDY RuntimeObjectY,X
    JSR Func_9508
    JSR Func_A1A3
    BMI Label_8BEB
    BCC Label_8BF9

Label_8BEB:
    LDX $16
    LDA a:$8F10,X
    TAX
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA $4E,X

Label_8BF9:
    INC $16
    LDA $16
    CMP #$18
    BCC Label_8BB4
    LDA a:$07C3
    BEQ Label_8C11
    LDA $3A
    SEC
    SBC #$02
    BCS Label_8C0F
    LDA #$00

Label_8C0F:
    STA $3A

Label_8C11:
    RTS
    .byte $20, $A9, $A8, $B0, $63, $E6, $06, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20
    .byte $A9, $A8, $B0, $54, $E6, $05, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20, $A9
    .byte $A8, $B0, $45, $E6, $09, $A9, $0A, $20, $04, $8D, $4C, $69, $8C, $20, $A9, $A8
    .byte $B0, $36, $E6, $08, $A9, $0A, $20, $04, $8D, $4C, $69, $8C
    JSR Func_A8A9
    BCS Label_8C7A
    INC $0A
    LDA #$0A
    JSR Func_8D04
    JMP Label_8C69
    JSR Func_A8A9
    BCS Label_8C7A
    INC $07
    LDA #$0A
    JSR Func_8D04

Label_8C69:
    JSR Func_C272
    LDA #$05
    LDX CurrentObjectOffset
    STA $4E,X
    LDA #$A9
    STA RuntimeObjectRecords,X
    LDA #$14
    STA $4F,X

Label_8C7A:
    RTS
    .byte $A6, $41, $4C, $24, $A0, $20, $A9, $A8, $90, $01, $60, $EE, $CD, $07, $A9, $64
    .byte $20, $04, $8D, $A5, $0D, $D0, $03, $20, $79, $B8, $A9, $28, $85, $0D, $A9, $09
    .byte $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $FF, $85, $0F, $A9, $64, $20
    .byte $04, $8D, $A9, $09, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $14, $20
    .byte $04, $8D, $A9, $06, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $28, $20
    .byte $04, $8D, $A9, $07, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $50, $20
    .byte $04, $8D, $A9, $08, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $64, $20
    .byte $04, $8D, $A9, $09, $4C, $6E, $8C, $20, $A9, $A8, $90, $01, $60, $A9, $64, $20
    .byte $04, $8D, $E6, $13, $A9
    ORA #$4C

Func_8D04 = * + 2  ; overlapping entry $8D04
    ROR a:$488C
    LDA a:$07C7
    BNE Label_8D28
    JSR Func_8D2A
    LDY $27
    PLA
    CLC
    ADC $0B
    STA $0B
    BCC Label_8D19
    INC $0C

Label_8D19:
    JSR Func_8D2A
    TYA
    EOR $27
    BEQ Label_8D27
    INC $13
    BNE Label_8D27
    DEC $13

Label_8D27:
    RTS

Label_8D28:
    PLA
    RTS

Func_8D2A:
    LDA $0B
    STA $2B
    LDA $0C
    STA $2C
    LDA #$03
    STA $2A
    LDA #$E8
    STA $29
    JMP Func_C47A
    .byte $AD, $6B, $07, $10, $14, $A6, $41, $B5, $4B, $C5, $38, $F0, $01, $60, $A5, $0E
    .byte $D0, $03, $20, $81, $B8, $A9, $28, $85, $0E, $60, $AD, $CC, $07, $D0, $13, $20
    .byte $A9, $A8, $B0, $0E, $20, $85, $B8, $A5, $DB, $05, $DC, $D0, $FA, $68, $68, $4C
    .byte $8E, $FE, $60, $20, $A9, $A8, $B0, $FA, $20, $8D, $B8, $A5, $DB, $05, $DC, $D0
    .byte $FA, $A6, $41, $A9, $91, $95, $4A, $B5, $4B, $38, $E9, $10, $95, $4B, $B0, $02
    .byte $D6, $4C, $A5, $37, $C9, $59, $D0, $15, $A9, $91, $85, $D4, $B5, $4B, $38, $E9
    .byte $10, $85, $D5, $B5, $4C, $E9, $00, $85, $D6, $B5, $4D, $85, $D7, $60, $A5, $40
    .byte $10, $01, $60

Label_8DB0:
    LDA $0E
    ORA a:$0772
    BEQ Label_8DB8
    RTS

Label_8DB8:
    LDA #$80
    STA a:$0772
    LDA #$00
    STA a:$0779
    LDA $13
    BEQ Label_8DCB
    DEC $13
    JMP Label_8DD0

Label_8DCB:
    LDA #$FF
    STA a:$07CC

Label_8DD0:
    JMP LoadAudioTrackSet2

Func_8DD3:
    CPY #$10
    BCC Label_8DE7
    CPY #$B0
    BCS Label_8DE7
    CMP #$00
    BEQ Label_8DF0
    CMP #$01
    BNE Label_8DE7
    CPX #$40
    BCC Label_8DF0

Label_8DE7:
    CLC
    LDA #$53
    LDX #$00
    STX a:$07CB
    RTS

Label_8DF0:
    PHA
    TYA
    SEC
    SBC #$10
    TAY
    PLA
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$53
    BEQ Label_8E2B
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$A95A,X
    BEQ Label_8E2B
    JSR Func_A6CA
    BNE Label_8E1C
    LDY $40
    BPL Label_8E1C
    LDA #$00

Label_8E1C:
    PHA
    LDA #$00
    STA a:$07CB
    PLA
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

Label_8E2B:
    LDY #$00
    STY $1D

Label_8E2F:
    LDY $1D
    LDX a:$8F10,Y
    STX CurrentObjectOffset
    LDA RuntimeObjectRecords,X
    BEQ Label_8EB7
    CMP #$A8
    BCS Label_8EB7
    DEC a:$07CB
    INC a:$07CB
    BEQ Label_8E4D
    LDA RuntimeObjectRecords,X
    JSR Func_9552
    BCC Label_8EB7

Label_8E4D:
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_8EB7
    SBC a:$AA9A,Y
    BCS Label_8EB7
    CPY #$86
    BNE Label_8E7A
    PHA
    LDA a:$076B
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #$08
    BCS Label_8E79
    PLA
    CMP #$F8
    BCC Label_8EB7
    LDA $3C
    BEQ Label_8E7A
    BNE Label_8EB7
    PLA
    JMP Label_8EB7

Label_8E79:
    PLA

Label_8E7A:
    LDA $27
    STA $2B
    LDA $28
    STA $2C
    LDA $2B
    SEC
    SBC RuntimeObjectXLo,X
    STA $2B
    LDA $2C
    SBC RuntimeObjectXHi,X
    BCC Label_8EB7
    STA $2C
    LDA $2B
    SBC a:$AA6A,Y
    BCS Label_8EB7
    LDA $2C
    BNE Label_8EB7
    LDA RuntimeObjectRecords,X
    JSR Func_A091
    CLC
    BEQ Label_8EA5
    SEC

Label_8EA5:
    LDA RuntimeObjectRecords,X
    JSR Func_A05E
    BNE Label_8EAD
    CLC

Label_8EAD:
    LDA RuntimeObjectRecords,X
    LDY #$00
    STY a:$07CB
    LDY #$01
    RTS

Label_8EB7:
    INC $1D
    LDA $1D
    CMP #$18
    BCS Label_8EC2
    JMP Label_8E2F

Label_8EC2:
    CLC
    LDA #$53
    LDY #$00
    STY a:$07CB
    RTS

Func_8ECB:
    STA $28
    STA $2A
    STX $27
    STX $29
    STY $1B
    LDA #$00
    STA $2C
    TYA
    LSR A
    LSR A
    LSR A
    STA $2B
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    CLC
    ADC $2B
    STA $2B
    BCC Label_8EF0
    INC $2C

Label_8EF0:
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    LDA #$04
    CLC
    ADC $2C
    STA $2C
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    RTS
    .byte $00, $06, $0C, $12, $18, $1E, $24, $2A, $30, $36, $3C, $42, $48, $4E, $54, $5A
    .byte $60, $66, $6C, $72, $78, $7E, $84, $8A, $90, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB
    .byte $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85
    .byte $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $6B, $92, $6B
    .byte $92, $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0
    .byte $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0
    .byte $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2
    .byte $8C, $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D
    .byte $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0
    .byte $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $9E, $8C, $F2, $8C, $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B
    .byte $92, $6B, $92, $6B, $92, $3D, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $DD, $A5, $DD, $A5, $6B, $92, $E7, $A5, $E7
    .byte $A5, $6B, $92, $F1, $A5, $F1, $A5, $6B, $92, $FB, $A5, $FB, $A5, $6B, $92, $05
    .byte $A6, $05, $A6, $6B, $92, $6B, $92, $0F, $A6, $0F, $A6, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $70
    .byte $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0
    .byte $8D, $1A, $88, $1A, $88, $1A, $88, $1A, $88, $E1, $89, $1A, $88, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2, $8C, $B2, $8C, $C2
    .byte $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D, $6B, $92, $6B
    .byte $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D
    RTS
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $AB, $8D, $AB, $8D, $AB, $8D
    .byte $AB, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $70, $8D, $57, $8D, $80, $8C
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $12, $8C, $21, $8C, $30, $8C, $3F, $8C
    .byte $4E, $8C, $5D, $8C, $9E, $8C, $F2, $8C, $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C
    .byte $6B, $92, $6B, $92, $6B, $92, $3D, $8D, $6B, $92, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92

Func_9386:
    LDA a:$0772
    BEQ Label_938E
    JMP Label_93F6

Label_938E:
    LDY $3A
    LDX $38
    LDA $39
    JSR Func_8DD3
    JSR Func_9477
    LDY $3A
    JSR Func_94DF
    JSR Func_8DD3
    JSR Func_9477
    LDA $3A
    CLC
    ADC #$0F
    TAY
    LDX $38
    LDA $39
    JSR Func_8DD3
    JSR Func_9477
    LDA $3A
    CLC
    ADC #$0F
    TAY
    JSR Func_94DF
    JSR Func_8DD3
    JSR Func_9477
    LDA $3A
    CLC
    ADC #$07
    TAY
    JSR Func_94DB
    JSR Func_8DD3
    JSR Func_9477
    LDY $3A
    JSR Func_94DB
    JSR Func_8DD3
    JSR Func_9477
    LDY $3A
    JSR Func_94DF
    JSR Func_8DD3
    JSR Func_9477
    LDA a:$077C
    BEQ Label_93F5
    LDA $0D
    BNE Label_93F5
    JMP Label_8DB0

Label_93F5:
    RTS

Label_93F6:
    DEC a:$0772
    BEQ Label_93FC
    RTS

Label_93FC:
    LDA $10
    STA $38
    LDA $11
    STA $39
    LDA $12
    STA $3A
    LDA $14
    ORA a:$07CD
    BEQ Label_9423
    LDA $14
    CMP $0D
    BCS Label_9417
    LDA $0D

Label_9417:
    LDY a:$07CD
    BEQ Label_941E
    LDA #$28

Label_941E:
    CLC
    ADC #$0A
    STA $0D

Label_9423:
    LDA #$00
    STA a:$0772
    LDA $13
    BNE Label_9434
    LDA a:$07CC
    BEQ Label_9434
    JMP Func_FE31

Label_9434:
    JSR Func_8758
    LDX CurrentRoomIndex
    DEX
    JSR DecodeRoom
    JSR LoadRoomObjects
    LDX #$02

Label_9442:
    LDA a:$0713,X
    STA $16,X
    DEX
    BPL Label_9442
    LDX #$04

Label_944C:
    LDA a:$0716,X
    STA $19,X
    DEX
    BPL Label_944C
    JSR Func_ECB7
    JSR Func_A3AC
    JSR Func_9578
    JSR Func_B64C
    JSR Func_B6C9
    JSR BuildRoomAttributeTables
    JSR Func_B7BD
    JSR Func_C43D
    LDA #$FF
    STA a:$07C4
    JSR WaitForVblankAndEnableRendering
    JMP EnableNmi

Func_9477:
    ASL A
    TAX
    BCS Label_9488
    LDA a:$926C,X
    STA $31
    LDA a:$926D,X
    STA $32
    JMP Label_9492

Label_9488:
    LDA a:$9334,X
    STA $31
    LDA a:$9335,X
    STA $32

Label_9492:
    LDA #$94
    PHA
    LDA #$9A
    PHA
    JMP ($0031)
    RTS

Func_949C:
    JSR Func_94C3
    LDA #$FF
    STA a:$0786,Y
    RTS
    .byte $4A, $4A, $4A, $A8, $4C, $9F, $94

Func_94AC:
    JSR Func_94C3
    LDA #$FF
    STA a:$0786,Y
    CPY #$14
    BCS Label_94BB
    STA a:$0787,Y

Label_94BB:
    RTS
    .byte $4A, $4A, $4A, $A8, $4C, $AF, $94

Func_94C3:
    LSR $45
    ROR $44
    LSR $45
    ROR $44
    LDA $44
    AND #$7F
    LDY #$00

Label_94D1:
    CMP #$05
    BCC Label_94DA
    INY
    SBC #$05
    BCS Label_94D1

Label_94DA:
    RTS

Func_94DB:
    LDA #$07
    BNE Label_94E1

Func_94DF:
    LDA #$0F

Label_94E1:
    CLC
    ADC $38
    TAX
    LDA $39
    ADC #$00
    RTS

Func_94EA:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    TAX
    PLA
    RTS

Func_94F2:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$07
    JMP Label_951B

Func_94FD:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$08
    JMP Label_951B

Func_9508:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$0F
    JMP Label_951B

Func_9513:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$11

Label_951B:
    TAX
    PLA
    ADC #$00
    RTS

Func_9520:
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    TAX
    PLA
    SBC #$00
    RTS

Func_952D:
    LDA #$FF
    STA a:$07C4
    LDA $10
    STA a:$0741
    LDA $11
    STA a:$0742
    LDA $12
    STA a:$0743
    LDA $0D
    STA $14
    LDA $0E
    STA $15
    JSR ResetPpuScroll
    JSR EnableNmi
    JMP WaitForVblankAndEnableRendering

Func_9552:
    CMP #$90
    BCC Label_955B
    CMP #$96
    BCS Label_955B
    RTS

Label_955B:
    SEC
    RTS

Func_955D:
    JSR Func_A0C4
    PHP
    CMP #$62
    BEQ Label_9573
    CMP #$63
    BEQ Label_9573
    CMP #$54
    BEQ Label_9573
    CMP #$55
    BEQ Label_9573
    PLP
    RTS

Label_9573:
    LDA #$53
    PLP
    CLC
    RTS

Func_9578:
    LDA #$FF
    LDX #$16

Label_957C:
    STA a:$0785,X
    DEX
    BPL Label_957C
    RTS

Func_9583:
    LDX #$00
    STX $43

Label_9587:
    LDA #$00
    STA a:$07C6
    LDX $43
    LDA RuntimeObjectRecords,X
    AND #$7F
    BEQ Label_95B3
    LDA RuntimeObjectY,X
    CMP #$A0
    BCS Label_95B3
    LDA RuntimeObjectRecords,X
    ASL A
    TAX
    LDA a:$95BF,X
    STA $31
    LDA a:$95C0,X
    STA $32
    LDA #$95
    PHA
    LDA #$B2
    PHA
    LDX $43
    JMP ($0031)

Label_95B3:
    LDA $43
    CLC
    ADC #$06
    STA $43
    CMP #$90
    BCC Label_9587
    RTS
    .byte $A9, $A2, $C6, $9C, $A9, $A2, $A9, $A2, $D8, $9C, $00, $9B, $A9, $A2, $3B, $9C
    .byte $CB, $9E, $65, $9D, $74, $96, $74, $96, $74, $96, $74, $96, $5C, $96, $74, $96
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2, $A9, $A2
    .byte $F3, $9F, $96, $97, $69, $98, $37, $9A, $A9, $A2, $A9, $A2, $74, $9F, $A9, $A2
    .byte $1C, $A0, $33, $A0

Func_9613:
    .byte $A5, $46, $18, $69, $10, $38, $E5, $3A, $90, $3D, $E9, $10, $B0, $39, $A5, $44
    .byte $38, $E9, $0F, $85, $48, $A5, $45, $E9, $00, $85, $49, $A5, $49, $10, $06, $A9
    .byte $00, $85, $49, $85, $48, $A5, $38, $C5, $48, $A5, $39, $E5, $49, $90, $18, $A5
    .byte $44, $18, $65, $47, $85, $48, $A5, $45, $69, $00, $85, $49, $A5, $38, $C5, $48
    .byte $A5, $39, $E5, $49, $B0, $01, $60, $38, $60, $A9, $00, $8D, $73, $07, $20, $74
    .byte $96, $A6, $43, $AD, $73, $07, $F0, $08, $10, $03, $4C, $C4, $8A, $4C, $F6, $89
    .byte $60, $86, $41, $A9, $53, $85, $1E, $A9, $00, $85, $1F, $B5, $4B, $85, $21, $B5
    .byte $4C, $85, $22, $B5, $4D, $18, $69, $11, $85, $16, $A8, $A5, $22, $A6, $21, $20
    .byte $5D, $95, $90, $09, $85, $1E, $E6, $1F, $20, $44, $A0, $B0, $3E, $A4, $16, $A5
    .byte $21, $18, $69, $07, $AA, $A5, $22, $69, $00, $20, $5D, $95, $90, $09, $85, $1E
    .byte $E6, $1F, $20, $44, $A0, $B0, $24, $A4, $16, $A5, $21, $18, $69, $0F, $AA, $A5
    .byte $22, $69, $00, $20, $5D, $95, $B0, $13, $A5, $1E, $A4, $1F, $D0, $0D, $A6, $43
    .byte $B5, $4D, $C9, $A0, $B0, $04, $69, $02, $95, $4D, $60, $85, $16, $86, $17, $20
    .byte $44, $A0, $B0, $03, $4C, $6F, $97, $30, $44, $A9, $02, $18, $65, $21, $85, $21
    .byte $A5, $22, $69, $00, $85, $22, $A5, $21, $18, $69, $0F, $85, $23, $A5, $22, $69
    .byte $00, $85, $24, $A6, $43, $B4, $4D, $A6, $23, $A5, $24, $20, $5D, $95, $B0, $5B
    .byte $30, $59, $A6, $43, $B5, $4D, $18, $69, $0F, $A8, $A6, $23, $A5, $24, $20, $5D
    .byte $95, $B0, $48, $30, $46, $A9, $7F, $8D, $73, $07, $4C, $64, $97, $A5, $21, $38
    .byte $E9, $02, $85, $21, $A5, $22, $E9, $00, $85, $22, $A6, $43, $B4, $4D, $A6, $21
    .byte $A5, $22, $20, $5D, $95, $B0, $24, $30, $22, $A6, $43, $B5, $4D, $18, $69, $0F
    .byte $A8, $A6, $21, $A5, $22, $20, $5D, $95, $B0, $11, $30, $0F, $A9, $FF, $8D, $73
    .byte $07, $A6, $43, $A5, $21, $95, $4B, $A5, $22, $95, $4C, $60, $A5, $16, $20, $5E
    .byte $A0, $F0, $01, $60, $A5, $1E, $C5, $16, $F0, $07, $A5, $1E, $C9, $53, $F0, $01
    .byte $60, $A6, $42

Label_9786:
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA $4E,X
    JMP Func_C233

Func_9791:
    LDX $43
    JMP Label_9786

Label_9796:
    LDA a:$076B
    AND #$1F
    CMP #$1F
    BEQ Label_97A0
    RTS

Label_97A0:
    LDA $4E,X
    BPL Label_97A7
    JMP Label_980E

Label_97A7:
    LDA RuntimeObjectY,X
    CMP #$98
    BCS Label_97DE
    TAY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$14
    LDA ($2B),Y
    CMP #$4C
    BNE Label_97DE
    LDA #$53
    STA ($2B),Y
    LDA #$53
    LDY #$00
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$08
    STA RuntimeObjectY,X
    RTS

Label_97DE:
    LDX $43
    LDA #$FF
    STA $4E,X
    JMP Label_9796

Label_97E7:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDA #$53
    LDY #$00
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA #$00
    STA $4E,X
    JMP Label_9796

Label_980E:
    JSR Func_9A2C
    LDX $43
    LDA RuntimeObjectY,X
    BEQ Label_97E7
    SEC
    SBC #$08
    TAY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y
    CMP #$53
    BNE Label_97E7
    LDA #$53
    STA ($2B),Y
    LDA #$4C
    LDY #$14
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA #$10
    STA $47
    JSR Func_9613
    BCC Label_985D
    JMP Label_9862

Label_985D:
    LDA #$FF
    STA a:$07C3

Label_9862:
    LDA #$10
    STA $47
    JMP Label_994E

Label_9869:
    LDA a:$076B
    AND #$1F
    CMP #$1F
    BEQ Label_9873
    RTS

Label_9873:
    LDA $4E,X
    BPL Label_987A
    JMP Label_98EC

Label_987A:
    LDA RuntimeObjectY,X
    CMP #$98
    BCS Label_98B9
    TAY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$14
    LDA ($2B),Y
    CMP #$4F
    BNE Label_98B9
    LDA #$53
    STA ($2B),Y
    LDA #$53
    INY
    STA ($2B),Y
    LDA #$53
    LDY #$00
    STA ($2B),Y
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$08
    STA RuntimeObjectY,X
    RTS

Label_98B9:
    LDX $43
    LDA #$FF
    STA $4E,X
    JMP Label_9869

Label_98C2:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDA #$53
    LDY #$00
    STA ($2B),Y
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA #$00
    STA $4E,X
    JMP Label_9869

Label_98EC:
    JSR Func_9A2C
    LDX $43
    LDA RuntimeObjectY,X
    BEQ Label_98C2
    SEC
    SBC #$08
    TAY
    JSR Func_94EA
    JSR Func_A58A
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y
    CMP #$53
    BNE Label_98C2
    LDA #$53
    STA ($2B),Y
    LDA #$53
    INY
    STA ($2B),Y
    LDA #$4F
    LDY #$14
    STA ($2B),Y
    LDA #$50
    INY
    STA ($2B),Y
    LDA $2B
    STA $44
    LDA $2C
    STA $45
    JSR Func_94AC
    LDX $43
    LDA RuntimeObjectY,X
    TAY
    DEY
    STY $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA #$20
    STA $47
    JSR Func_9613
    BCC Label_9945
    JMP Label_994A

Label_9945:
    LDA #$FF
    STA a:$07C3

Label_994A:
    LDA #$20
    STA $47

Label_994E:
    LDX $43
    JSR Func_9A1F
    LDA #$FF
    STA a:$07AB,Y

Label_9958:
    LDA #$00
    STA $16
    LDX #$00
    STX $17

Label_9960:
    LDX $17
    LDA a:$07AB,X
    BMI Label_9974

Label_9967:
    INX
    CPX #$18
    STX $17
    BCC Label_9960
    LDA $16
    BNE Label_9958
    BEQ Label_99C1

Label_9974:
    LDA #$7F
    STA a:$07AB,X
    LDA a:$8F10,X
    TAX
    LDA RuntimeObjectY,X
    SEC
    SBC #$08
    STA $46
    LDA RuntimeObjectXLo,X
    STA $44
    LDA RuntimeObjectXHi,X
    STA $45
    LDA RuntimeObjectRecords,X
    TAY
    LDA a:$AA6A,Y
    STA $47
    LDX #$00

Label_9996:
    JSR Func_A247
    BCS Label_99B0
    JSR Func_9A1F
    LDA a:$07AB,Y
    BNE Label_99A8
    LDA #$FF
    STA a:$07AB,Y

Label_99A8:
    TXA
    CLC
    ADC #$06
    TAX
    JMP Label_9996

Label_99B0:
    JSR Func_9613
    BCS Label_99BA
    LDA #$FF
    STA a:$07C3

Label_99BA:
    INC $16
    LDX $17
    JMP Label_9967

Label_99C1:
    LDX #$00
    STX $16

Label_99C5:
    LDX $16
    LDA a:$07AB,X
    BEQ Label_9A08
    LDA a:$8F10,X
    TAX
    LDA RuntimeObjectY,X
    CMP #$08
    BCC Label_99FA
    SEC
    SBC #$01
    AND #$F8
    STA RuntimeObjectY,X
    TAY
    JSR Func_94EA
    JSR Func_A1A3
    BCS Label_99FA
    BMI Label_99FA
    LDX $16
    LDA a:$8F10,X
    TAX
    LDY RuntimeObjectY,X
    JSR Func_9508
    JSR Func_A1A3
    BMI Label_99FA
    BCC Label_9A08

Label_99FA:
    LDX $16
    LDA a:$8F10,X
    TAX
    LDA #$A8
    STA RuntimeObjectRecords,X
    LDA #$00
    STA $4E,X

Label_9A08:
    INC $16
    LDA $16
    CMP #$18
    BCC Label_99C5
    LDA a:$07C3
    BEQ Label_9A1E
    LDA $3A
    SEC
    SBC #$01
    AND #$F8
    STA $3A

Label_9A1E:
    RTS

Func_9A1F:
    LDY #$00
    TXA

Label_9A22:
    CMP #$06
    BCC Label_9A2B
    INY
    SBC #$06
    BCS Label_9A22

Label_9A2B:
    RTS

Func_9A2C:
    LDX #$18
    LDA #$00

Label_9A30:
    STA a:$07AB,X
    DEX
    BPL Label_9A30
    RTS
    STX CurrentObjectOffset
    LDA $4F,X
    BNE Label_9A65
    LDA $4E,X
    BMI Label_9A7E
    JSR Func_9AAD
    BCS Label_9A66
    JSR Func_9ABC
    BCS Label_9A66
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_9A58
    INC RuntimeObjectXHi,X

Label_9A58:
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$05
    STA $44
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $45

Label_9A65:
    RTS

Label_9A66:
    JSR Func_9ACF
    BCS Label_9A77
    JSR Func_9ADE
    BCS Label_9A77
    LDX $43
    LDA #$FF
    STA $4E,X
    RTS

Label_9A77:
    LDX $43
    LDA #$FF
    STA $4F,X
    RTS

Label_9A7E:
    JSR Func_9ACF
    BCS Label_9A9C
    JSR Func_9ADE
    BCS Label_9A9C
    LDX $43
    LDA RuntimeObjectXLo,X
    STA $44
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    STA $45
    SBC #$00
    STA RuntimeObjectXHi,X
    RTS

Label_9A9C:
    JSR Func_9AAD
    BCS Label_9A77
    JSR Func_9ABC
    BCS Label_9A77
    LDX $43
    LDA #$00
    STA $4E,X
    RTS

Func_9AAD:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9513
    JSR Func_9AF1
    BCS Label_9A65
    JMP Func_955D

Func_9ABC:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9513
    JSR Func_9AF1
    BCS Label_9A65
    JMP Func_955D

Func_9ACF:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9520
    JSR Func_9AF1
    BCS Label_9AFF
    JMP Func_955D

Func_9ADE:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9520
    JSR Func_9AF1
    BCS Label_9AFF
    JMP Func_955D

Func_9AF1:
    CPY #$A0
    BCS Label_9AFF
    CMP #$01
    BCC Label_9AFF
    CMP #$02
    BCS Label_9AFF
    CPX #$40

Label_9AFF:
    RTS

Func_9B00:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0E
    TAY
    JSR Func_94F2
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    CMP #$16
    BNE Label_9B1B
    JMP Func_9791

Label_9B1B:
    LDX $43
    LDA a:$07C6
    BMI Label_9B8B
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_94EA
    JSR Func_A0C4
    BPL Label_9B33
    JMP Func_9791

Label_9B33:
    BCS Label_9B8B
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$07
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BPL Label_9B55
    JMP Func_9791

Label_9B55:
    BCS Label_9B8B
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BPL Label_9B77
    JMP Func_9791

Label_9B77:
    BCS Label_9B8B
    LDX $43
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    LDA RuntimeObjectY,X
    CMP #$A0
    BCS Label_9B8A
    LDA #$00
    STA a:$07C6

Label_9B8A:
    RTS

Label_9B8B:
    CMP #$8F
    BNE Label_9B92
    JMP Func_9791

Label_9B92:
    LDX $43
    STX CurrentObjectOffset
    LDA $4E,X
    BPL Label_9B9D
    JMP Label_9BED

Label_9B9D:
    JSR Func_9E7D
    BCS Label_9BE5
    LDA a:$07C6
    BNE Label_9BC4
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$11
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCC Label_9BE5

Label_9BC4:
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CMP #$2F
    LDA RuntimeObjectXHi,X
    SBC #$01
    BCS Label_9BE5
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA RuntimeObjectXHi,X

Label_9BDF:
    LDA #$00
    STA a:$07C6
    RTS

Label_9BE5:
    LDX $43
    LDA #$FF
    STA $4E,X
    BNE Label_9BDF

Label_9BED:
    JSR Func_9E52
    BCS Label_9C31
    LDA a:$07C6
    BNE Label_9C14
    LDX $43
    STX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    TAY
    LDA RuntimeObjectXHi,X
    STA $22
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    TAX
    LDA $22
    SBC #$00
    JSR Func_A0C4
    BCC Label_9C31

Label_9C14:
    LDX $43
    LDA RuntimeObjectXHi,X
    BNE Label_9C20
    LDA RuntimeObjectXLo,X
    CMP #$02
    BCC Label_9C31

Label_9C20:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA RuntimeObjectXHi,X
    STA a:$07C6
    RTS

Label_9C31:
    LDX $43
    LDA #$00
    STA $4E,X
    STA a:$07C6
    RTS
    LDA $4F,X
    BEQ Label_9C42
    DEC $4F,X
    RTS

Label_9C42:
    JSR Func_9B00
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    CMP $3A
    BEQ Label_9C51
    RTS

Label_9C51:
    LDA RuntimeObjectXLo,X
    CMP $38
    LDA RuntimeObjectXHi,X
    SBC $39
    BCC Label_9C60
    LDA $4E,X
    BMI Label_9C65
    RTS

Label_9C60:
    LDA $4E,X
    BPL Label_9C65
    RTS

Label_9C65:
    LDA a:$076B
    AND #$3F
    BEQ Label_9C6D
    RTS

Label_9C6D:
    LDX CurrentRoomIndex
    LDA a:$AB49,X
    TAY
    LDX a:$8F10,Y

Label_9C76:
    LDA RuntimeObjectRecords,X
    BEQ Label_9C84
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_9C76
    RTS

Label_9C84:
    LDY $43
    LDA #$03
    STA a:$004F,Y
    LDA #$A6
    STA RuntimeObjectRecords,X
    LDA a:RuntimeObjectY,Y
    CLC
    ADC #$07
    STA RuntimeObjectY,X
    LDA a:$004E,Y
    BMI Label_9CB2
    LDA a:RuntimeObjectXLo,Y
    CLC
    ADC #$12
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    ADC #$00
    STA RuntimeObjectXHi,X
    LDA #$00
    STA $4E,X
    JMP Label_9CC5

Label_9CB2:
    LDA a:RuntimeObjectXLo,Y
    SEC
    SBC #$06
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    SBC #$00
    STA RuntimeObjectXHi,X
    LDA #$FF
    STA $4E,X

Label_9CC5:
    RTS
    LDA a:$076B
    LSR A
    LSR A
    AND #$01
    STA $16
    LDA RuntimeObjectY,X
    AND #$FE
    ORA $16
    STA RuntimeObjectY,X
    RTS
    JSR Func_9EA8
    LDA $22
    BNE Label_9CF5
    LDA $21
    CMP #$50
    BCS Label_9CF5
    LDX $43
    LDA $3A
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BCC Label_9CF5
    LDA #$7F
    STA a:$07C6

Label_9CF5:
    LDX $43
    STX CurrentObjectOffset
    LDA $4F,X
    BNE Label_9D1E
    JSR Func_A64D
    CMP #$14
    BCS Label_9D07
    JMP Func_9B00

Label_9D07:
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    TAY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9D18
    JMP Func_9B00

Label_9D18:
    LDX $43
    LDA #$0C
    STA $4F,X

Label_9D1E:
    DEC $4F,X
    LDA #$FF
    STA a:$07C6
    JSR Func_9B00
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_9508
    JSR Func_A0C4
    BCS Label_9D64
    BMI Label_9D64
    LDX $43
    LDY RuntimeObjectY,X
    CPY #$02
    BCC Label_9D64
    DEY
    DEY
    STY RuntimeObjectY,X

Label_9D64:
    RTS
    LDA $F5
    BNE Label_9D6C
    JSR Func_C29A

Label_9D6C:
    LDX $43
    LDA a:$076B
    AND #$01
    BEQ Label_9D76
    RTS

Label_9D76:
    LDA $4F,X
    BPL Label_9D7D
    JMP Label_9DC0

Label_9D7D:
    LDA $38
    CMP RuntimeObjectXLo,X
    BNE Label_9D8F
    LDA $39
    CMP RuntimeObjectXHi,X
    BNE Label_9D8F
    LDA #$FF
    STA $4F,X
    BNE Label_9DC9

Label_9D8F:
    LDA $4E,X
    BMI Label_9DAD
    JSR Func_9E7D
    BCS Label_9DA6
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$02
    STA RuntimeObjectXLo,X
    BCC Label_9DA5
    INC RuntimeObjectXHi,X

Label_9DA5:
    RTS

Label_9DA6:
    LDX $43
    LDA #$FF
    STA $4F,X
    RTS

Label_9DAD:
    JSR Func_9E52
    BCS Label_9DA6
    LDX $43
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$02
    STA RuntimeObjectXLo,X
    BCS Label_9DBF
    DEC RuntimeObjectXHi,X

Label_9DBF:
    RTS

Label_9DC0:
    LDA $3A
    SEC
    SBC #$10
    CMP RuntimeObjectY,X
    BEQ Label_9DD9

Label_9DC9:
    LDA $4E,X
    BMI Label_9DE6
    JSR Func_9DF2
    BCS Label_9DD9
    LDX $43
    DEC RuntimeObjectY,X
    DEC RuntimeObjectY,X
    RTS

Label_9DD9:
    LDX $43
    LDA $4E,X
    EOR #$FF
    STA $4E,X
    LDA #$00
    STA $4F,X
    RTS

Label_9DE6:
    JSR Func_9E1F
    BCS Label_9DD9
    LDX $43
    INC RuntimeObjectY,X
    INC RuntimeObjectY,X
    RTS

Func_9DF2:
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    CPY #$A0
    BCS Label_9E1E
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9E1E
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9E1E
    LDX $43
    LDY RuntimeObjectY,X
    DEY
    DEY
    JSR Func_9508
    JSR Func_A0C4

Label_9E1E:
    RTS

Func_9E1F:
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    CMP #$A0
    BCS Label_9E51
    TAY
    JSR Func_94EA
    JSR Func_A0C4
    BCS Label_9E51
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_94F2
    JSR Func_A0C4
    BCS Label_9E51
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$11
    TAY
    JSR Func_9508
    JSR Func_A0C4

Label_9E51:
    RTS

Func_9E52:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9520
    JSR Func_A0C4
    BCS Label_9E7C
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9520
    JSR Func_A0C4
    BCS Label_9E7C
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR Func_9520
    JSR Func_A0C4

Label_9E7C:
    RTS

Func_9E7D:
    LDX $43
    LDY RuntimeObjectY,X
    JSR Func_9513
    JSR Func_A0C4
    BCS Label_9EA7
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$07
    TAY
    JSR Func_9513
    JSR Func_A0C4
    BCS Label_9EA7
    LDX $43
    LDA RuntimeObjectY,X
    CLC
    ADC #$0F
    TAY
    JSR Func_9513
    JSR Func_A0C4

Label_9EA7:
    RTS

Func_9EA8:
    LDA $38
    CLC
    SBC RuntimeObjectXLo,X
    STA $21
    LDA $39
    SBC RuntimeObjectXHi,X
    STA $22
    STA $24
    BPL Label_9ECA
    LDA $21
    EOR #$FF
    CLC
    ADC #$01
    STA $21
    LDA $22
    EOR #$FF
    ADC #$00
    STA $22

Label_9ECA:
    RTS
    JSR Func_9B00
    LDA a:$076B
    CMP #$E0
    BNE Label_9ECA
    LDX $43
    LDA $4E,X
    BMI Label_9EEB
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$10
    STA $21
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $22
    JMP Label_9EF8

Label_9EEB:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$10
    STA $21
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA $22

Label_9EF8:
    LDA $21
    CMP #$30
    LDA $22
    SBC #$01
    BCS Label_9F73
    LDY RuntimeObjectY,X
    STY $16
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9F73
    LDY $16
    LDA $21
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCS Label_9F73
    LDA $16
    CLC
    ADC #$0F
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9F73
    LDA $16
    CLC
    ADC #$0F
    TAY
    LDA $21
    CLC
    ADC #$0F
    TAX
    LDA $22
    ADC #$00
    JSR Func_A0C4
    BCS Label_9F73
    LDY CurrentRoomIndex
    LDX a:$AB49,Y
    LDA a:$8F10,X
    TAX

Label_9F4D:
    LDA RuntimeObjectRecords,X
    BEQ Label_9F5B
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_9F4D
    RTS

Label_9F5B:
    LDA #$A0
    STA RuntimeObjectRecords,X
    LDA $21
    STA RuntimeObjectXLo,X
    LDA $22
    STA RuntimeObjectXHi,X
    LDA $16
    STA RuntimeObjectY,X
    LDA #$10
    STA $4E,X
    LDA #$00
    STA $4F,X

Label_9F73:
    RTS
    STX CurrentObjectOffset
    LDA $4E,X
    BMI Label_9FBA
    LDY RuntimeObjectY,X
    JSR Func_94F2
    BEQ Label_9F89
    CMP #$01
    BNE Label_9FB5
    CPX #$40
    BCS Label_9FB5

Label_9F89:
    STX $21
    STA $22
    STY $16
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDX $43
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$03
    STA RuntimeObjectXLo,X
    BCC Label_9FB4
    INC RuntimeObjectXHi,X

Label_9FB4:
    RTS

Label_9FB5:
    LDX $43
    JMP Label_A024

Label_9FBA:
    LDY RuntimeObjectY,X
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #$03
    TAX
    PLA
    SBC #$00
    BCC Label_9FB5
    STX $21
    STA $22
    STY $16
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDA $16
    CLC
    ADC #$08
    TAY
    LDX $21
    LDA $22
    JSR Func_A0C4
    BCS Label_9FB5
    BMI Label_9FB5
    LDX $43
    LDA $21
    STA RuntimeObjectXLo,X
    LDA $22
    STA RuntimeObjectXHi,X
    RTS
    DEC $4E,X
    BEQ Label_9FF8
    RTS

Label_9FF8:
    LDA $00
    AND #$01
    BEQ Label_A000
    LDA #$FF

Label_A000:
    STA $4E,X
    LDA a:$076A
    LSR A
    TAY
    LDA a:$A00D,Y
    STA RuntimeObjectRecords,X
    RTS
    .byte $84, $85, $85, $87, $87, $84, $84, $84, $84, $87, $84, $85, $84, $85, $84
    INC $4E,X
    LDA $4E,X
    CMP #$0F
    BCC Label_A032

Label_A024:
    LDA #$00
    STA RuntimeObjectRecords,X
    STA RuntimeObjectXLo,X
    STA RuntimeObjectXHi,X
    STA RuntimeObjectY,X
    STA $4E,X
    STA $4F,X

Label_A032:
    RTS
    LDA a:$076B
    LSR A
    BCC Label_A03F
    LDA RuntimeObjectY,X
    BEQ Label_A03F
    DEC RuntimeObjectY,X

Label_A03F:
    DEC $4F,X
    BEQ Label_A024
    RTS

Func_A044:
    CMP #$35
    BCC Label_A050
    CMP #$41
    BCS Label_A050
    LDY #$00
    SEC
    RTS

Label_A050:
    CMP #$56
    BCC Label_A05C
    CMP #$62
    BCS Label_A05C
    LDY #$FF
    SEC
    RTS

Label_A05C:
    CLC
    RTS

Func_A05E:
    TAY
    PHP
    BPL Label_A067
    PLP
    LDA a:$9FEB,Y
    RTS

Label_A067:
    PLP
    LDA #$FF
    RTS
    .byte $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF

Func_A091:
    TAY
    PHP
    BPL Label_A09A
    PLP
    LDA a:$A01E,Y
    RTS

Label_A09A:
    PLP
    LDA #$FF
    RTS
    .byte $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $00, $00, $00, $00, $00, $00
    BRK
    BRK
    .byte $00, $00, $00, $00, $00, $FF, $FF, $00, $FF, $FF, $FF, $FF, $FF, $FF

Func_A0C4:
    CPY #$A0
    BCC Label_A0CE
    CLC
    LDA #$53
    LDY #$00
    RTS

Label_A0CE:
    STA $28
    STX $27
    STA $2A
    STX $29
    STY $1B
    LDA #$00
    STA $2C
    TYA
    LSR A
    LSR A
    LSR A
    STA $2B
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    CLC
    ADC $2B
    STA $2B
    BCC Label_A0F3
    INC $2C

Label_A0F3:
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    LDA #$04
    CLC
    ADC $2C
    STA $2C
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LSR $2A
    ROR $29
    LDY $29
    LDA ($2B),Y
    CMP #$53
    BEQ Label_A13C
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$AA22,X
    BEQ Label_A13C
    JSR Func_A6CA
    BNE Label_A134
    LDY $40
    BPL Label_A134
    LDA #$00

Label_A134:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS

Label_A13C:
    LDY #$00
    STY $1D

Label_A140:
    LDY $1D
    LDX a:$8F10,Y
    CPX CurrentObjectOffset
    BEQ Label_A195
    LDA RuntimeObjectRecords,X
    BEQ Label_A195
    CMP #$A8
    BCS Label_A195
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A195
    SBC a:$AA9A,Y
    BCS Label_A195
    LDA $27
    STA $2B
    LDA $28
    STA $2C
    LDA $2B
    SEC
    SBC RuntimeObjectXLo,X
    STA $2B
    LDA $2C
    SBC RuntimeObjectXHi,X
    STA $2C
    BCC Label_A195
    LDA $2B
    SEC
    SBC a:$AA6A,Y
    STA $2B
    LDA $2C
    SBC #$00
    STA $2C
    BCS Label_A195
    STX $42
    LDA RuntimeObjectRecords,X
    JSR Func_A091
    CLC
    BEQ Label_A190
    SEC

Label_A190:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

Label_A195:
    INC $1D
    LDA $1D
    CMP #$18
    BCC Label_A140
    CLC
    LDA #$53
    LDY #$00
    RTS

Func_A1A3:
    CPY #$A0
    BCC Label_A1AD
    CLC
    LDA #$53
    LDX #$00
    RTS

Label_A1AD:
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y
    TAX
    LDA $27
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA a:$AA22,X
    JSR Func_A6CA
    BNE Label_A1CC
    LDA $40
    BPL Label_A1CC
    LDA #$00

Label_A1CC:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS
    .byte $C0, $A0, $90, $06, $18, $A9, $53, $A0, $00, $60, $85, $28, $86, $27, $84, $1B
    .byte $A0, $00, $84, $1D

Label_A1E8:
    LDY $1D
    LDX a:$8F10,Y
    LDA RuntimeObjectRecords,X
    BEQ Label_A239
    CMP #$A8
    BCS Label_A239
    TAY
    LDA $1B
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A239
    SBC a:$AA9A,Y
    BCS Label_A239
    LDA $27
    STA $2B
    .byte $A5
    PLP
    STA $2C
    LDA $2B
    SEC
    SBC RuntimeObjectXLo,X
    STA $2B
    LDA $2C
    SBC RuntimeObjectXHi,X
    STA $2C
    BCC Label_A239
    LDA $2B
    SEC
    SBC a:$AA6A,Y
    STA $2B
    LDA $2C
    SBC #$00
    STA $2C
    BCS Label_A239
    STX $42
    LDA RuntimeObjectRecords,X
    JSR Func_A091
    CLC
    BEQ Label_A234
    SEC

Label_A234:
    LDA RuntimeObjectRecords,X
    LDY #$01
    RTS

Label_A239:
    INC $1D
    LDA $1D
    CMP #$18
    BCC Label_A1E8
    CLC
    LDA #$53
    LDY #$00
    RTS

Func_A247:
    CPX #$90
    BCS Label_A2A9
    LDA RuntimeObjectRecords,X
    BPL Label_A2A0
    CMP #$A8
    BCS Label_A2A0
    TAY
    LDA $46
    SEC
    SBC RuntimeObjectY,X
    BCC Label_A2A0
    SBC a:$AA9A,Y
    BCS Label_A2A0
    LDA $44
    SEC
    SBC a:$AA6A,Y
    STA $48
    LDA $45
    SBC #$00
    STA $49
    INC $48
    BNE Label_A274
    INC $49

Label_A274:
    LDA $49
    BPL Label_A27E
    LDA #$00
    STA $49
    STA $48

Label_A27E:
    LDA RuntimeObjectXLo,X
    CMP $48
    LDA RuntimeObjectXHi,X
    SBC $49
    BCC Label_A2A0
    LDA $44
    CLC
    ADC $47
    STA $48
    LDA $45
    ADC #$00
    STA $49
    LDA RuntimeObjectXLo,X
    CMP $48
    LDA RuntimeObjectXHi,X
    SBC $49
    BCS Label_A2A0
    RTS

Label_A2A0:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Func_A247

Label_A2A9:
    RTS
    .byte $98, $4A
    LSR A
    LSR A
    STA $F8
    RTS

Func_A2B1:
    LDA #$47
    STA CurrentRoomIndex
    LDA #$03
    STA $13
    LDA #$00
    STA a:$07CC
    STA a:$07CB
    STA a:$0712
    STA a:$071B
    STA a:$0724
    STA a:$072D
    STA $0B
    STA $0C
    STA a:$0772
    STA a:$07C4
    STA a:$07C5
    STA $0F
    STA $0D
    STA $0E
    STA a:$077C
    STA $3C
    STA a:$07C9
    STA a:$07CA
    STA a:$07CD
    STA a:$07D0
    STA a:$07D1
    STA a:$07D2
    STA a:$07D3
    LDA #$FF
    STA a:$07C8
    LDA #$00
    STA $05
    STA $06
    STA $07
    STA $08
    STA $0A
    STA $09
    LDA #$00
    STA $39
    STA $11
    STA $38
    STA $10
    STA $14
    LDX #$0D

Label_A31B:
    LDA $05,X
    STA a:$0736,X
    STA a:$0745,X
    DEX
    BPL Label_A31B
    LDX #$78

Label_A328:
    STA a:$058F,X
    DEX
    BNE Label_A328
    LDX #$96

Label_A330:
    STA a:$0607,X
    DEX
    BNE Label_A330
    LDX #$1B

Label_A338:
    STA a:$0711,X
    DEX
    BNE Label_A338
    LDX #$64

Label_A340:
    STA a:$069D,X
    DEX
    BNE Label_A340
    LDA CurrentRoomIndex
    STA a:$0712
    LDA #$98
    STA $3A
    STA $12

Func_A351:
    LDA #$C5
    STA $22
    LDA #$3D
    STA $21
    JMP Func_C4CD

LoadRoom:
    JSR DisableNmi
    LDX CurrentRoomIndex
    LDA #$FF
    STA a:$069D,X
    LDA #$00
    LDX #$90

Label_A36A:
    STA $49,X
    DEX
    BNE Label_A36A
    LDX CurrentRoomIndex
    DEX
    JSR DecodeRoom
    JSR Func_EC63
    JSR Func_9578
    JSR Func_B64C
    JSR Func_B6C9
    JSR BuildRoomAttributeTables
    JSR Func_B7BD
    JSR Func_A3AC

Func_A38A:
    LDA a:$07C7
    BNE Label_A395
    JSR StopAudioStreams
    JSR ClearSoundRequests

Label_A395:
    LDA a:$0772
    BEQ Label_A39B
    RTS

Label_A39B:
    LDA $0E
    BEQ Label_A3A2
    JMP LoadAudioTrackSet3

Label_A3A2:
    LDA $0D
    BEQ Label_A3A9
    JMP LoadAudioTrackSet1

Label_A3A9:
    JMP LoadAudioTrackSet0

Func_A3AC:
    LDA #$00
    STA $3B
    STA $3F
    STA $F8
    STA $34
    STA $35
    STA a:$0774
    STA a:$07C6
    STA $3C
    STA a:$076B
    STA $40
    RTS

Func_A3C6:
    LDA a:$07CC
    BNE Label_A3D1
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BEQ Func_A38A

Label_A3D1:
    RTS

Func_A3D2:
    JSR Func_A41F
    LDA a:$076B
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
    JSR Func_949C

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
    LDA a:$076B
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
    JSR Func_949C
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
    JSR Func_949C

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

Func_A497:
    JSR Func_A563
    LDA $01
    STA $03
    LDA $02
    STA $04
    JMP Label_A4B0

Func_A4A5:
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
    INC a:$079D,X
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
    LDA a:$079D,X
    CLC
    ADC #$60
    STA a:$079D,X
    DEX
    BPL Label_A4DD
    LDX #$00

Label_A4EB:
    LDA a:$079D,X
    CMP #$60
    BNE Label_A4FC
    LDA #$FF
    STA a:$079D,X
    INX
    CPX #$05
    BCC Label_A4EB

Label_A4FC:
    LDA #$60
    STA a:$07A5
    STA a:$07A6
    STA a:$07A7
    LDA $13

Label_A509:
    CMP #$64
    BCC Label_A515
    SBC #$64
    INC a:$07A7
    JMP Label_A509

Label_A515:
    CMP #$0A
    BCC Label_A521
    SBC #$0A
    INC a:$07A6
    JMP Label_A515

Label_A521:
    CLC
    ADC #$60
    STA a:$07A5
    LDX #$02

Label_A529:
    LDA a:$07A5,X
    CMP #$60
    BNE Label_A538
    LDA #$FF
    STA a:$07A5,X
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
    STA a:$076C,X
    DEX
    BPL Label_A53A
    LDA #$00
    STA a:$07C8
    RTS
    .byte $27, $03, $00, $00, $00, $10, $E8, $64, $0A, $01, $01, $02, $04, $08, $10, $20
    .byte $40, $80

Func_A563:
    LDA #$FF
    STA a:$07C8
    LDA #$00
    LDX #$07

Label_A56C:
    STA a:$079D,X
    DEX
    BPL Label_A56C
    RTS
    .byte $85, $1B, $29, $07, $A8, $A5, $1B, $86, $1B, $46, $1B, $6A, $46, $1B, $6A, $46
    .byte $1B, $6A, $AA, $B9, $5B, $A5, $60

Func_A58A:
    LSR A
    TXA
    ROR A
    LSR A
    LSR A
    TAX
    TYA
    LSR A
    LSR A
    LSR A
    TAY
    RTS
    .byte $98, $0A, $0A, $0A, $A8, $8A, $0A, $0A, $0A, $AA, $2A, $29, $01, $60

Func_A5A4:
    STY $2B
    LDA #$00
    STA $2C
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    TYA
    CLC
    ADC $2B
    STA $2B
    BCC Label_A5BC
    INC $2C

Label_A5BC:
    ASL $2B
    ROL $2C
    ASL $2B
    ROL $2C
    LDA #$00
    CLC
    ADC $2B
    STA $2B
    LDA #$04
    ADC $2C
    STA $2C
    TXA
    LSR A
    CLC
    ADC $2B
    STA $2B
    BCC Label_A5DC
    INC $2C

Label_A5DC:
    RTS
    .byte $A5, $09, $20, $58, $A6, $C6, $09, $4C, $16, $A6, $A5, $08, $20, $58, $A6, $C6
    .byte $08, $4C, $16, $A6, $A5, $0A, $20, $58, $A6, $C6, $0A, $4C, $16, $A6
    LDA $07
    JSR Func_A658
    DEC $07
    JMP Label_A616
    .byte $A5, $05, $20, $58, $A6, $C6, $05, $4C, $16, $A6, $A5, $06, $20, $58, $A6, $C6
    .byte $06

Label_A616:
    LDA $1E
    SEC
    SBC #$10
    STA $1E
    TAY
    LDX $21
    LDA $22
    JSR Func_A58A
    JSR Func_A66D
    JSR Func_A70A
    LDA $3B
    BMI Label_A63B
    LDA $38
    CMP #$20
    LDA $39
    SBC #$01
    BCC Label_A649
    BCS Label_A645

Label_A63B:
    LDA $38
    CMP #$11
    LDA $39
    SBC #$00
    BCS Label_A649

Label_A645:
    LDA #$09
    STA $3F

Label_A649:
    JSR Func_C2BD
    RTS

Func_A64D:
    LDA $3C
    CMP #$21
    BCC Label_A655
    LDA #$00

Label_A655:
    ORA #$00
    RTS

Func_A658:
    BEQ Label_A661
    JSR Func_A64D
    ORA $3E
    BEQ Label_A664

Label_A661:
    PLA
    PLA
    RTS

Label_A664:
    LDA $3A
    AND #$0F
    CMP #$08
    BNE Label_A661
    RTS

Func_A66D:
    STX $21
    STY $22
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y
    CMP #$55
    BEQ Label_A685
    CMP #$63
    BEQ Label_A685
    JSR Func_A6F1
    BNE Label_A692

Label_A685:
    DEC $22
    LDX $21
    LDY $22
    JSR Func_A5A4
    LDY #$00
    LDA ($2B),Y

Label_A692:
    CMP #$54
    BEQ Label_A6A1
    CMP #$62
    BEQ Label_A6A1
    JSR Func_A6D8
    BEQ Label_A6A1
    SEC
    RTS

Label_A6A1:
    LDX #$01
    LDY #$00

Label_A6A5:
    LDA $2B
    BNE Label_A6AF
    LDA $2C
    CMP #$04
    BEQ Label_A6C8

Label_A6AF:
    LDA $2B
    BNE Label_A6B5
    DEC $2C

Label_A6B5:
    DEC $2B
    LDY #$00
    LDA ($2B),Y
    CMP #$54
    BEQ Label_A6C4
    JSR Func_A6D8
    BNE Label_A6A5

Label_A6C4:
    INX
    JMP Label_A6A5

Label_A6C8:
    CLC
    RTS

Func_A6CA:
    CPX #$8A
    BCC Label_A6D5
    CPX #$92
    BCS Label_A6D5
    LDY #$00
    RTS

Label_A6D5:
    LDY #$FF
    RTS

Func_A6D8:
    CMP #$19
    BCC Label_A709
    BEQ Label_A709
    CMP #$29
    BCS Label_A709
    CMP #$1C
    BEQ Label_A709
    CMP #$1F
    BEQ Label_A709
    CMP #$22
    BEQ Label_A709
    CMP #$25
    RTS

Func_A6F1:
    CMP #$1A
    BCC Label_A709
    BEQ Label_A709
    CMP #$2A
    BCS Label_A709
    CMP #$1D
    BEQ Label_A709
    CMP #$20
    BEQ Label_A709
    CMP #$23
    BEQ Label_A709
    CMP #$26

Label_A709:
    RTS

Func_A70A:
    LDA #$04
    STA $2A
    LDA #$00
    STA $29
    STX $1F

Label_A714:
    LDY #$00
    LDA ($29),Y
    CMP #$54
    BEQ Label_A724
    JSR Func_A6D8
    BEQ Label_A724
    JMP Label_A7C7

Label_A724:
    DEX
    BEQ Label_A72A
    JMP Label_A7C7

Label_A72A:
    LDA $29
    BNE Label_A730
    DEC $2A

Label_A730:
    DEC $29
    LDY #$00
    LDA ($29),Y
    CMP #$16
    BEQ Label_A742
    LDY #$02
    LDA ($29),Y
    CMP #$16
    BNE Label_A757

Label_A742:
    INC $29
    BNE Label_A748
    INC $2A

Label_A748:
    LDY #$00
    LDA #$62
    STA ($29),Y
    LDY #$14
    LDA #$63
    STA ($29),Y
    JMP Label_A769

Label_A757:
    INC $29
    BNE Label_A75D
    INC $2A

Label_A75D:
    LDY #$00
    LDA #$54
    STA ($29),Y
    LDA #$55
    LDY #$14
    STA ($29),Y

Label_A769:
    LDA $29
    STA $44
    LDA $2A
    STA $45
    JSR Func_94AC
    DEC $1F
    LDA $1F
    AND #$07
    TAX
    LDA a:$A55B,X
    PHA
    LDA $1F
    LSR A
    LSR A
    LSR A
    TAX
    PLA
    ORA a:$0716,X
    STA a:$0716,X
    LDA $2A
    AND #$01
    STA $2A
    LDY #$07

Label_A794:
    LDA $29
    CMP #$14
    LDA $2A
    SBC #$00
    BCC Label_A7AC
    LDA $29
    SBC #$14
    STA $29
    INY
    BCS Label_A794
    DEC $2A
    JMP Label_A794

Label_A7AC:
    LDA $29
    ASL A
    CLC
    ADC #$04
    TAX
    JSR GetRoomAttributeMaskAndOffset
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributeScratch,X
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

Label_A7C7:
    INC $29
    BNE Label_A7CD
    INC $2A

Label_A7CD:
    LDA $29
    CMP #$90
    LDA $2A
    SBC #$05
    BCS Label_A7DA
    JMP Label_A714

Label_A7DA:
    RTS

Func_A7DB:
    LDA CurrentRoomIndex
    CMP #$0B
    BCC Label_A7E5
    SBC #$0A
    STA CurrentRoomIndex

Label_A7E5:
    RTS

Func_A7E6:
    LDA CurrentRoomIndex
    CMP #$5B
    BCS Label_A7F0
    ADC #$0A
    STA CurrentRoomIndex

Label_A7F0:
    RTS

Func_A7F1:
    LDA CurrentRoomIndex
    JSR Func_A80B
    BEQ Label_A7FD
    CLC
    ADC #$01
    STA CurrentRoomIndex

Label_A7FD:
    RTS

Func_A7FE:
    LDA CurrentRoomIndex
    JSR Func_A816
    BEQ Label_A80A
    SEC
    SBC #$01
    STA CurrentRoomIndex

Label_A80A:
    RTS

Func_A80B:
    LDX #$09

Label_A80D:
    CMP a:$A821,X
    BEQ Label_A815
    DEX
    BPL Label_A80D

Label_A815:
    RTS

Func_A816:
    LDX #$09

Label_A818:
    CMP a:$A82B,X
    BEQ Label_A820
    DEX
    BPL Label_A818

Label_A820:
    RTS
    .byte $0A, $14, $1E, $28, $32, $3C, $46, $50, $5A, $64, $01, $0B, $15, $1F, $29, $33
    .byte $3D, $47, $51, $5B

Func_A835:
    LDA $0E
    BEQ Label_A847
    LDA a:$076B
    AND #$1F
    BNE Label_A847
    DEC $0E
    BNE Label_A847
    JSR Func_A38A

Label_A847:
    LDA $0D
    BEQ Label_A859
    LDA a:$076B
    AND #$1F
    BNE Label_A859
    DEC $0D
    BNE Label_A859
    JSR Func_A38A

Label_A859:
    LDA a:$077C
    LDA $3A
    CLC
    ADC #$08
    TAY
    CPY #$10
    BCC Label_A87E
    CPY #$B0
    BCS Label_A87E
    LDA $38
    CLC
    ADC #$07
    TAX
    LDA $39
    ADC #$00
    BEQ Label_A883
    CMP #$01
    BNE Label_A87E
    CPX #$40
    BCC Label_A883

Label_A87E:
    LDA #$00
    JMP Label_A891

Label_A883:
    PHA
    TYA
    SEC
    SBC #$10
    TAY
    PLA
    JSR Func_8ECB
    LDY $29
    LDA ($2B),Y

Label_A891:
    LDX #$00
    CMP #$16
    BNE Label_A899
    LDX #$FF

Label_A899:
    CMP #$62
    BNE Label_A89F
    LDX #$FF

Label_A89F:
    CMP #$63
    BNE Label_A8A5
    LDX #$FF

Label_A8A5:
    STX a:$077C
    RTS

Func_A8A9:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$10
    SEC
    SBC $3A
    BCS Label_A8B9
    EOR #$FF
    ADC #$01

Label_A8B9:
    CMP #$04
    BCS Label_A8E2
    LDA RuntimeObjectXLo,X
    SEC
    SBC $38
    STA $25
    LDA RuntimeObjectXHi,X
    SBC $39
    STA $26
    BCS Label_A8DA
    LDA $25
    EOR #$FF
    ADC #$01
    STA $25
    LDA $26
    EOR #$FF
    STA $26

Label_A8DA:
    BEQ Label_A8DE
    SEC
    RTS

Label_A8DE:
    LDA $25
    CMP #$05

Label_A8E2:
    RTS

Func_A8E3:
    LDA Controller1Buttons
    AND #$03
    BEQ Label_A8F6
    LDA a:$0777
    AND #$03
    BNE Label_A8F6
    LDA a:$07C4
    BNE Label_A912

Label_A8F6:
    LDA Controller1Buttons
    AND #$08
    BEQ Label_A91E
    LDA a:$0777
    AND #$08
    BNE Label_A91E
    LDA a:$07C4
    BNE Label_A912
    LDA #$00
    STA APU_STATUS
    LDA #$FF
    BNE Label_A914

Label_A912:
    LDA #$00

Label_A914:
    STA a:$07C4
    LDA Controller1Buttons
    STA a:$0777
    RTS

Label_A91E:
    LDA a:$07C4
    BNE Label_A924
    RTS

Label_A924:
    LDA Controller1Buttons
    AND #$40
    BEQ Label_A93D
    LDA $34
    SEC
    SBC #$04
    BCS Label_A934
    LDA #$00

Label_A934:
    STA $34
    LDA #$FF
    STA $36
    JMP Label_A953

Label_A93D:
    LDA Controller1Buttons
    AND #$80
    BEQ Label_A953
    LDA $34
    CLC
    ADC #$04
    BPL Label_A94D
    LDA #$80

Label_A94D:
    STA $34
    LDA #$FF
    STA $36

Label_A953:
    LDA Controller1Buttons
    STA a:$0777
    RTS
    .byte $01, $01, $01, $01, $01, $01
    ORA ($01,X)
    ORA ($01,X)
    ORA ($01,X)
    BRK
    .byte $01, $01, $00, $01, $01, $01, $01, $00, $01, $00, $00, $01, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00
    .byte $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $00, $01, $01, $00, $01, $01, $01, $01, $00
    .byte $01, $00, $01, $01, $00, $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $81, $81, $81, $81, $81, $81, $81
    .byte $81, $81, $81, $81, $81, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00
    .byte $01, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00
    .byte $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $20, $10, $10, $10, $08, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $10, $08, $08, $08, $08, $08, $08, $10, $10, $10, $10, $10, $10
    .byte $10, $10, $10, $08, $06, $03, $0F, $02, $11, $05, $06, $0B, $0C, $03, $03, $06
    .byte $0F, $05, $0A, $08, $07, $02, $0A, $04, $03, $04, $04, $03, $12, $06, $07, $07
    .byte $05, $09, $09, $04, $0C, $04, $08, $08, $02, $09, $08, $08, $11, $07, $08, $07
    .byte $06, $09, $05, $08, $0F, $09, $0A, $03, $05, $06, $06, $0C, $06, $06, $03, $08
    .byte $09, $08, $0E, $07, $09, $09, $0E, $04, $04, $0D, $07, $11, $06, $04, $09, $0D
    .byte $09, $09, $05, $06, $0A, $07, $09, $06, $07, $07, $08, $08, $0B, $09, $07, $03
    .byte $0E, $0C, $06, $06, $09, $0C, $04, $00, $01, $02, $03, $04, $05, $07, $09, $0B
    .byte $0C, $0D, $0D, $0E, $0F, $10, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B
    .byte $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B
    .byte $2C, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C
    .byte $3D, $3E, $3F, $40, $41, $42, $43, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D
    .byte $4E, $4F, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D
    .byte $5E, $5F, $60, $61, $62, $63, $65, $66, $67, $68, $69, $6C

Func_AC13:
    LDA #$FF
    STA $FB
    LDX #$00
    LDA #$F0

Label_AC1B:
    STA OamStagingBuffer,X
    INX
    BNE Label_AC1B
    JSR Func_AC60
    JSR Func_AD54
    LDX #$0C
    STX $16
    LDY #$00
    STY CurrentObjectOffset

Label_AC2F:
    LDY CurrentObjectOffset
    LDA a:RuntimeObjectY,Y
    CMP #$A0
    BCS Func_AC50
    LDA a:RuntimeObjectRecords,Y
    BEQ Func_AC50
    AND #$7F
    ASL A
    TAY
    LDA ObjectHandlerTable,Y
    STA $31
    LDA a:$AD94,Y
    STA $32
    LDX CurrentObjectOffset
    JMP ($0031)

Func_AC50:
    LDA CurrentObjectOffset
    CLC
    ADC #$06
    STA CurrentObjectOffset
    CMP #$90
    BCC Label_AC2F
    LDA #$00
    STA $FB
    RTS

Func_AC60:
    LDA a:$0772
    BEQ Label_AC9E
    LDA a:$076B
    LSR A
    LSR A
    AND #$03
    BNE Label_AC78
    LDX #$B4
    LDY #$E6
    JSR Func_B457
    JMP Label_AD4F

Label_AC78:
    CMP #$01
    BNE Label_AC86
    LDX #$B4
    LDY #$EA
    JSR Func_B457
    JMP Label_AD4F

Label_AC86:
    CMP #$02
    BNE Label_AC94
    LDX #$B4
    LDY #$EE
    JSR Func_B457
    JMP Label_AD4F

Label_AC94:
    LDX #$B4
    LDY #$F2
    JSR Func_B457
    JMP Label_AD4F

Label_AC9E:
    LDA $3B
    BNE Label_ACBC
    LDA $3C
    ORA $3E
    BNE Label_ACB2
    LDX #$B4
    LDY #$C2
    JSR Func_B457
    JMP Label_AD4F

Label_ACB2:
    LDX #$B4
    LDY #$D6
    JSR Func_B457
    JMP Label_AD4F

Label_ACBC:
    BMI Label_AD08
    LDA $3C
    ORA $3E
    BEQ Label_ACCE
    LDX #$B4
    LDY #$C6
    JSR Func_B457
    JMP Label_AD4F

Label_ACCE:
    LDA a:$0779
    BEQ Label_ACDD
    LDX #$B4
    LDY #$DE
    JSR Func_B457
    JMP Label_AD4F

Label_ACDD:
    LDA $00
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE Label_ACF0
    LDX #$B4
    LDY #$B6
    JSR Func_B457
    JMP Label_AD4F

Label_ACF0:
    CMP #$02
    BNE Label_ACFE
    LDX #$B4
    LDY #$BE
    JSR Func_B457
    JMP Label_AD4F

Label_ACFE:
    LDX #$B4
    LDY #$BA
    JSR Func_B457
    JMP Label_AD4F

Label_AD08:
    LDA $3C
    ORA $3E
    BEQ Label_AD18
    LDX #$B4
    LDY #$DA
    JSR Func_B457
    JMP Label_AD4F

Label_AD18:
    LDA a:$0779
    BEQ Label_AD27
    LDX #$B4
    LDY #$E2
    JSR Func_B457
    JMP Label_AD4F

Label_AD27:
    LDA $00
    LSR A
    LSR A
    LSR A
    AND #$03
    BNE Label_AD3A
    LDX #$B4
    LDY #$CA
    JSR Func_B457
    JMP Label_AD4F

Label_AD3A:
    CMP #$02
    BNE Label_AD48
    LDX #$B4
    LDY #$D2
    JSR Func_B457
    JMP Label_AD4F

Label_AD48:
    LDX #$B4
    LDY #$CE
    JSR Func_B457

Label_AD4F:
    LDA #$00
    STA $3E
    RTS

Func_AD54:
    LDA a:$0779
    BNE Label_AD5A
    RTS

Label_AD5A:
    LDA $3B
    BNE Label_AD5F
    RTS

Label_AD5F:
    BMI Label_AD7B
    LDA OamStagingBuffer
    STA a:$0308
    LDA a:$0303
    CLC
    ADC #$0F
    STA a:$030B
    LDA #$CA
    STA a:$0309
    LDA #$03
    STA a:$030A
    RTS

Label_AD7B:
    LDA OamStagingBuffer
    STA a:$0308
    LDA a:$0303
    SEC
    SBC #$07
    STA a:$030B
    LDA #$CA
    STA a:$0309
    LDA #$43

ObjectHandlerTable = * + 2  ; overlapping entry $AD93
    STA a:$030A
    RTS
    .byte $E7, $AD, $08, $AE, $12, $AE, $19, $AE, $75, $AE, $BB, $AE, $1E, $AF, $6A, $AF
    .byte $B0, $AF, $F4, $AF, $FB, $AF, $02, $B0, $09, $B0, $10, $B0, $17, $B0, $2B, $B0
    .byte $35, $B0, $3C, $B0, $43, $B0, $4A, $B0, $51, $B0, $58, $B0, $5F, $B0, $66, $B0
    .byte $6D, $B0, $74, $B0, $7B, $B0, $82, $B0, $89, $B0, $89, $B0, $90, $B0, $AC, $B0
    .byte $C9, $B0, $D0, $B0, $DA, $B0, $E1, $B0, $E8, $B0, $EF, $B0, $14, $B1, $17, $B1
    .byte $35, $B1, $AD, $6B, $07, $4A, $29, $03, $D0, $07, $A2, $B5, $A0, $94, $4C, $0C
    .byte $AE, $C9, $02, $D0, $07, $A2, $B5, $A0, $9C, $4C, $0C, $AE, $A2, $B5, $A0, $98
    .byte $4C, $0C, $AE, $A2, $B5, $A0, $AC

Label_AE0C:
    JSR Func_B1D6
    JMP Func_AC50
    .byte $A2, $B5, $A0, $BC, $4C, $0C, $AE, $B5, $4E, $30, $2C, $B5, $4F, $F0, $07, $A2
    .byte $B5, $A0, $0E, $4C, $0C, $AE, $A5, $00, $4A, $4A, $29, $03, $D0, $07, $A2, $B4
    .byte $A0, $F6, $4C, $0C, $AE, $C9, $02, $D0, $07, $A2, $B4, $A0, $FE, $4C, $0C, $AE
    .byte $A2, $B4, $A0, $FA, $4C, $0C, $AE, $B5, $4F, $F0, $07, $A2, $B5, $A0, $12, $4C
    .byte $0C, $AE, $A5, $00, $4A, $4A, $29, $03, $D0, $07, $A2, $B5, $A0, $02, $4C, $0C
    .byte $AE, $C9, $02, $D0, $07, $A2, $B5, $A0, $0A, $4C, $0C, $AE, $A2, $B5, $A0, $06
    .byte $4C, $0C, $AE
    LDA $4E,X
    BMI Label_AE9A
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AE88
    LDX #$B5
    LDY #$16
    JMP Label_AE0C

Label_AE88:
    CMP #$02
    BNE Label_AE93
    LDX #$B5
    LDY #$1E
    JMP Label_AE0C

Label_AE93:
    LDX #$B5
    LDY #$1A
    JMP Label_AE0C

Label_AE9A:
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AEA9
    LDX #$B5
    LDY #$22
    JMP Label_AE0C

Label_AEA9:
    CMP #$02
    BNE Label_AEB4
    LDX #$B5
    LDY #$2A
    JMP Label_AE0C

Label_AEB4:
    LDX #$B5
    LDY #$26
    JMP Label_AE0C
    LDA a:$076B
    LSR A
    LSR A
    LSR A
    LSR A
    CMP #$08
    BCS Label_AEDE
    LDA RuntimeObjectXLo,X
    ORA #$04
    STA RuntimeObjectXLo,X
    LDX #$B5
    LDY #$2E
    JSR Func_B265
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    AND #$F8
    STA RuntimeObjectXLo,X
    JMP Func_AC50

Label_AEDE:
    CMP #$08
    BEQ Label_AEE6
    CMP #$0F
    BNE Label_AEED

Label_AEE6:
    LDX #$B5
    LDY #$30
    JMP Label_AE0C

Label_AEED:
    CMP #$09
    BEQ Label_AEF5
    CMP #$0E
    BNE Label_AEFC

Label_AEF5:
    LDX #$B5
    LDY #$34
    JMP Label_AE0C

Label_AEFC:
    LDA a:$076B
    LSR A
    LSR A
    AND #$03
    BNE Label_AF0C
    LDX #$B5
    LDY #$38
    JMP Label_AE0C

Label_AF0C:
    AND #$01
    BEQ Label_AF17
    LDX #$B5
    LDY #$3C
    JMP Label_AE0C

Label_AF17:
    LDX #$B5
    LDY #$40
    JMP Label_AE0C
    LDA $4E,X
    BMI Label_AF46
    LDA $00
    CLC
    ADC $4F,X
    LSR A
    LSR A
    AND #$03
    BNE Label_AF34
    LDX #$B5
    LDY #$44
    JMP Label_AE0C

Label_AF34:
    CMP #$02
    BNE Label_AF3F
    LDX #$B5
    LDY #$4C
    JMP Label_AE0C

Label_AF3F:
    LDX #$B5
    LDY #$48
    JMP Label_AE0C

Label_AF46:
    LDA $00
    CLC
    ADC $4F,X
    LSR A
    LSR A
    AND #$03
    BNE Label_AF58
    LDX #$B5
    LDY #$50
    JMP Label_AE0C

Label_AF58:
    CMP #$02
    BNE Label_AF63
    LDX #$B5
    LDY #$58
    JMP Label_AE0C

Label_AF63:
    LDX #$B5
    LDY #$54
    JMP Label_AE0C
    LDA $4E,X
    BMI Label_AF8F
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AF7D
    LDX #$B5
    LDY #$5C
    JMP Label_AE0C

Label_AF7D:
    CMP #$02
    BNE Label_AF88
    LDX #$B5
    LDY #$64
    JMP Label_AE0C

Label_AF88:
    LDX #$B5
    LDY #$60
    JMP Label_AE0C

Label_AF8F:
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AF9E
    LDX #$B5
    LDY #$6C
    JMP Label_AE0C

Label_AF9E:
    CMP #$02
    BNE Label_AFA9
    LDX #$B5
    LDY #$74
    JMP Label_AE0C

Label_AFA9:
    LDX #$B5
    LDY #$70
    JMP Label_AE0C
    LDA $4E,X
    BPL Label_AFD3
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AFC3
    LDX #$B5
    LDY #$88
    JMP Label_AE0C

Label_AFC3:
    CMP #$02
    LDX #$B5
    LDY #$90
    JMP Label_AE0C
    .byte $A2, $B5, $A0, $8C, $4C, $0C, $AE

Label_AFD3:
    LDA $00
    LSR A
    LSR A
    AND #$03
    BNE Label_AFE2
    LDX #$B5
    LDY #$7C
    JMP Label_AE0C

Label_AFE2:
    CMP #$02
    BNE Label_AFED
    LDX #$B5
    LDY #$84
    JMP Label_AE0C

Label_AFED:
    LDX #$B5
    LDY #$80
    JMP Label_AE0C
    LDX #$B5
    LDY #$C0
    JMP Label_AE0C
    LDX #$B5
    LDY #$C4
    JMP Label_AE0C
    LDX #$B5
    LDY #$C8
    JMP Label_AE0C
    LDX #$B5
    LDY #$CC
    JMP Label_AE0C
    LDX #$B5
    LDY #$D0
    JMP Label_AE0C
    LDA $00
    AND #$08
    BNE Label_B024
    LDX #$B5
    LDY #$D4
    JMP Label_AE0C

Label_B024:
    LDX #$B5
    LDY #$D8
    JMP Label_AE0C
    LDX #$B5
    LDY #$B0

Label_B02F:
    JSR Func_B265
    JMP Func_AC50
    LDX #$B5
    LDY #$B2
    JMP Label_B02F
    LDX #$B5
    LDY #$B4
    JMP Label_B02F
    LDX #$B5
    LDY #$B6
    JMP Label_B02F
    LDX #$B5
    LDY #$B8
    JMP Label_B02F
    LDX #$B5
    LDY #$BA
    JMP Label_B02F
    LDX #$B5
    LDY #$DC
    JMP Label_AE0C
    LDX #$B5
    LDY #$E0
    JMP Label_AE0C
    LDX #$B5
    LDY #$E4
    JMP Label_AE0C
    LDX #$B5
    LDY #$E8
    JMP Label_AE0C
    LDX #$B5
    LDY #$EC
    JMP Label_AE0C
    LDX #$B5
    LDY #$F0
    JMP Label_AE0C
    LDX #$B5
    LDY #$F4
    JMP Label_AE0C
    LDX #$B5
    LDY #$FC
    JMP Label_AE0C
    LDA a:$076B
    BMI Label_B098
    JMP Func_AC50

Label_B098:
    LDA a:$076B
    LSR A
    BCC Label_B0A5
    LDX #$B6
    LDY #$08
    JMP Label_AE0C

Label_B0A5:
    LDX #$B6
    LDY #$0C
    JMP Label_AE0C
    LDX a:$0763
    BNE Label_B0B8
    LDX #$B5
    LDY #$FC
    JMP Label_AE0C

Label_B0B8:
    DEX
    BNE Label_B0C2
    LDX #$B6
    LDY #$00
    JMP Label_AE0C

Label_B0C2:
    LDX #$B6
    LDY #$04
    JMP Label_AE0C
    LDX #$B6
    LDY #$18
    JMP Label_AE0C
    LDX #$B6
    LDY #$10
    JSR Func_B2AF
    JMP Func_AC50
    LDX #$B6
    LDY #$20
    JMP Label_AE0C
    LDX #$B6
    LDY #$24
    JMP Label_AE0C
    LDX #$B6
    LDY #$28
    JMP Label_AE0C
    LDA RuntimeObjectY,X
    SEC
    SBC #$0B
    STA RuntimeObjectY,X
    LDA $4E,X
    BMI Label_B104
    LDX #$B6
    LDY #$2E
    JSR Func_B265
    JMP Label_B10B

Label_B104:
    LDX #$B6
    LDY #$2C
    JSR Func_B265

Label_B10B:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$0B
    STA RuntimeObjectY,X
    JMP Func_AC50
    LDA $4E,X
    LSR A
    BNE Label_B123
    LDX #$B6
    LDY #$30
    JMP Label_AE0C

Label_B123:
    CMP #$01
    BNE Label_B12E
    LDX #$B6
    LDY #$34
    JMP Label_AE0C

Label_B12E:
    LDX #$B6
    LDY #$38
    JMP Label_AE0C
    LDA $4E,X
    CMP #$01
    BNE Label_B145
    LDX #$B6
    LDY #$3C
    JSR Func_B265
    JMP Func_AC50

Label_B145:
    CMP #$02
    BNE Label_B153
    LDX #$B6
    LDY #$40
    JSR Func_B265
    JMP Func_AC50

Label_B153:
    CMP #$03
    BNE Label_B161
    LDX #$B6
    LDY #$44
    JSR Func_B265
    JMP Func_AC50

Label_B161:
    CMP #$04
    BNE Label_B16F
    LDX #$B6
    LDY #$48
    JSR Func_B265
    JMP Func_AC50

Label_B16F:
    CMP #$05
    BNE Label_B17D
    LDX #$B6
    LDY #$3C
    JSR Func_B3C8
    JMP Func_AC50

Label_B17D:
    CMP #$06
    BNE Label_B18B
    LDX #$B6
    LDY #$40
    JSR Func_B3C8
    JMP Func_AC50

Label_B18B:
    CMP #$07
    BNE Label_B199
    LDX #$B6
    LDY #$44
    JSR Func_B3C8
    JMP Func_AC50

Label_B199:
    CMP #$08
    BNE Label_B1A7
    LDX #$B6
    LDY #$48
    JSR Func_B3C8
    JMP Func_AC50

Label_B1A7:
    CMP #$09
    BNE Label_B1B2
    LDX #$B6
    LDY #$3C
    JMP Label_AE0C

Label_B1B2:
    CMP #$0A
    BNE Label_B1BD
    LDX #$B6
    LDY #$40
    JMP Label_AE0C

Label_B1BD:
    CMP #$0B
    BNE Label_B1C8
    LDX #$B6
    LDY #$44
    JMP Label_AE0C

Label_B1C8:
    CMP #$0C
    BNE Label_B1D3
    LDX #$B6
    LDY #$48
    JSR Func_B1D6

Label_B1D3:
    JMP Func_AC50

Func_B1D6:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B21F
    BNE Label_B21F
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA a:$0301,X
    LDY #$01
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B21F:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$28
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B264
    BNE Label_B264
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA a:$0301,X
    LDY #$03
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B264:
    RTS

Func_B265:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B2AE
    BNE Label_B2AE
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA a:$0301,X
    LDY #$01
    LDA ($21),Y
    STA a:$0302,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    LDA $1B
    STA a:$0303,X
    INX
    INX
    INX
    INX
    STX $16

Label_B2AE:
    RTS

Func_B2AF:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B2F8
    BNE Label_B2F8
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA a:$0301,X
    LDY #$01
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B2F8:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$28
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B33D
    BNE Label_B33D
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA a:$0301,X
    LDY #$03
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B33D:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$30
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B382
    BNE Label_B382
    LDX $16
    LDY #$04
    LDA ($21),Y
    STA a:$0301,X
    LDY #$05
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B382:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$38
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B3C7
    BNE Label_B3C7
    LDX $16
    LDY #$06
    LDA ($21),Y
    STA a:$0301,X
    LDY #$07
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B3C7:
    RTS

Func_B3C8:
    STX $22
    STY $21
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$20
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B411
    BNE Label_B411
    LDX $16
    LDY #$00
    LDA ($21),Y
    STA a:$0301,X
    LDY #$01
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B411:
    LDX CurrentObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #$24
    STA $2B
    LDA RuntimeObjectXHi,X
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B456
    BNE Label_B456
    LDX $16
    LDY #$02
    LDA ($21),Y
    STA a:$0301,X
    LDY #$03
    LDA ($21),Y
    STA a:$0302,X
    LDA $1B
    STA a:$0303,X
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #$37
    LDX $16
    STA OamStagingBuffer,X
    INX
    INX
    INX
    INX
    STX $16

Label_B456:
    RTS

Func_B457:
    STX $22
    STY $21
    LDA $38
    CLC
    ADC #$20
    STA $2B
    LDA $39
    ADC #$00
    STA $2C
    LDA $2B
    SEC
    SBC $34
    STA $1B
    LDA $2C
    SBC #$00
    BCC Label_B4B5
    BNE Label_B4B5
    LDA $18
    ASL A
    ASL A
    TXA
    LDY #$00
    LDA ($21),Y
    STA a:$0301
    LDY #$01
    LDA ($21),Y
    STA a:$0302
    LDY #$02
    LDA ($21),Y
    STA a:$0305
    LDY #$03
    LDA ($21),Y
    STA a:$0306
    LDA $3A
    CLC
    ADC #$27
    STA OamStagingBuffer
    STA a:$0304
    LDA $1B
    STA a:$0303
    CLC
    ADC #$08
    STA a:$0307
    BCC Label_B4B5
    LDA #$F0
    STA a:$0304

Label_B4B5:
    RTS
    .byte $90, $02, $92, $02, $94, $02, $96, $02, $98, $02, $9A, $02, $A4, $02, $A6, $02
    .byte $9C, $02, $9E, $02, $92, $42, $90, $42, $96, $42, $94, $42, $9A, $42, $98, $42
    .byte $A0, $02, $A2, $02, $9E, $42, $9C, $42, $B0, $02, $B2, $02, $B2, $42, $B0, $42
    .byte $C0, $02, $C2, $02, $C4, $02, $C6, $02, $FA, $02, $FC, $02, $8A, $02, $8C, $02
    .byte $00, $01, $02, $01, $04, $01, $06, $01, $08, $01, $0A, $01, $02, $41, $00, $41
    .byte $06, $41, $04, $41, $0A, $41, $08, $41, $A8, $01, $AA, $01, $AA, $41, $A8, $41
    .byte $24, $02, $26, $02, $28, $02, $2A, $02, $2C, $02, $2E, $02
    ROL $42
    BIT $42
    ROL A
    .byte $42, $28, $42, $2E, $42, $2C, $42, $30, $02, $32, $02, $32, $42, $34, $02, $34
    .byte $42, $36, $02, $36, $42, $38, $02, $38, $42, $3A, $02, $3A, $42, $18, $03, $1A
    .byte $03, $1C, $03, $1E, $03, $20, $03, $22, $03, $1A, $43, $18, $43, $1E, $43, $1C
    .byte $43, $22, $43, $20, $43, $0C, $00, $0E, $00, $10, $00, $12, $00, $14, $00, $16
    .byte $00, $AC, $00, $AE, $00, $0E, $40, $0C, $40, $12, $40, $10, $40, $16, $40, $14
    .byte $40, $AE, $40, $AC, $40, $48, $01, $4A, $01, $4C, $01, $4E, $01, $50, $01, $52
    .byte $01, $4A, $41, $48, $41, $4E, $41, $4C, $41, $52, $41, $50, $41, $54, $02, $56
    .byte $02, $58, $02, $5A, $02, $5C, $02, $5E, $02, $56, $42, $54, $42, $5A, $42, $58
    .byte $42, $5E, $42, $5C, $42, $F6, $02, $F8, $02, $D8, $00, $D8, $01, $D8, $02, $DA
    .byte $02, $DA, $00, $DA, $01, $82, $00, $82, $40, $6C, $01, $6C, $41, $74, $01, $76
    .byte $01, $70, $03, $72, $03, $6E, $01, $6E, $C1, $7C, $03, $7E, $03, $60, $01, $62
    .byte $01, $78, $01, $7A, $01, $64, $00, $66, $00, $68, $00, $6A, $00, $D0, $00, $D0
    .byte $40, $D2, $01, $D2, $41, $CC, $01, $CE, $01, $68, $00, $6A, $00, $68, $00, $6A
    .byte $00, $68, $00, $6A, $00, $B4, $03, $B6, $03, $B8, $03, $BA, $03, $BC, $03, $BE
    .byte $03, $FE, $01, $FE, $41, $FE, $41, $FE, $01, $84, $00, $86, $00, $D6, $00, $F2
    .byte $00, $88, $00, $D4, $00, $8A, $03, $8C, $00, $8E, $03, $8E, $43, $E2, $00, $E2
    .byte $40, $E4, $00, $E4, $40, $C8, $03, $C8, $43, $DC, $01, $DC, $41, $DE, $01, $DE
    .byte $41, $E0, $01, $E0, $41, $E8, $00, $E6, $00, $EA, $00, $E6, $00, $EC, $00, $E6
    .byte $00, $EE, $00, $E6, $00

Func_B64C:
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX #$00
    LDA #$FF

Label_B663:
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    DEX
    BNE Label_B663
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$40
    LDA #$00

Label_B68F:
    STA PPU_DATA
    DEX
    BNE Label_B68F
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$40
    LDA #$00

Label_B6A6:
    STA PPU_DATA
    DEX
    BNE Label_B6A6
    LDX #$00
    LDA #$F0

Label_B6B0:
    STA OamDmaBuffer,X
    STA OamStagingBuffer,X
    INX
    BNE Label_B6B0

Label_B6B9:
    LDA PPU_STATUS
    BPL Label_B6B9
    LDA #$00
    STA OAM_ADDR
    LDA #$02
    STA OAM_DMA
    RTS

Func_B6C9:
    JSR DisableNmi
    JSR DisableRendering
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$8E
    STA PPU_ADDR
    LDA #$B7
    STA $22
    LDA #$7C
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$6E
    STA PPU_ADDR
    LDA #$B7
    STA $22
    LDA #$9E
    STA $21
    JSR Func_B76F
    JSR Func_A497
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$76
    STA PPU_ADDR
    LDA #$00
    STA a:$07A2
    LDA #$07
    STA $22
    LDA #$9D
    STA $21
    JSR Func_B76F
    JSR Func_A4A5
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$62
    STA PPU_ADDR
    LDA #$B7
    STA $22
    LDA #$8B
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A2
    STA PPU_ADDR
    LDA #$B7
    STA $22
    LDA #$97
    STA $21
    JSR Func_B76F
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$00

Label_B761:
    LDA InitialRoomAttributes,X
    STA PPU_DATA
    INX
    CPX #$10
    BCC Label_B761
    JMP ResetPpuScroll

Func_B76F:
    LDY #$00

Label_B771:
    LDA ($21),Y
    BEQ Label_B77B
    STA PPU_DATA
    INY
    BNE Label_B771

Label_B77B:
    RTS
    .byte $91, $92, $95, $94, $8C, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $60, $00, $8B
    .byte $8C, $8D, $FF, $FF, $52, $50, $51, $52, $50, $51, $00, $93, $8F, $96, $8C, $FF
    .byte $6B, $00, $8E, $8F, $90, $91, $92, $95, $94, $8C, $FF, $FF, $FF, $FF, $FF, $60
    .byte $00

InitialRoomAttributes:
    .byte $40, $50, $90, $A0, $A0, $60, $50, $10, $05, $01, $00, $08, $0A, $05, $05, $01

Func_B7BD:
    JSR DisableNmi
    JSR DisableRendering

Label_B7C3:
    LDA PPU_STATUS
    BPL Label_B7C3
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX #$00

Label_B7D7:
    LDA RoomAttributeScratch,X
    STA PPU_DATA
    INX
    CPX #$40
    BCC Label_B7D7
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR

Label_B7EF:
    LDA RoomAttributeScratch,X
    STA PPU_DATA
    INX
    CPX #$80
    BCC Label_B7EF
    JMP ResetPpuScroll

Func_B7FD:
    LDA #$2C
    STA $FD
    LDA #$B8
    STA $FE
    LDA #$00
    STA $FF
    RTS

Func_B80A:
    INC $FF
    LDA $FF
    CMP #$0C
    BCS Label_B820
    LDY #$00

Label_B814:
    LDA ($FD),Y
    CMP #$FF
    BNE Label_B81D
    JMP Reset

Label_B81D:
    AND #$F3
    RTS

Label_B820:
    INC $FD
    BNE Label_B826
    INC $FE

Label_B826:
    LDY #$00
    STY $FF
    BEQ Label_B814
    .byte $80, $80, $80, $80, $80, $80, $01, $01, $01, $01, $80, $80, $80, $80, $80, $80
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81, $81, $81, $81
    .byte $00, $41, $41, $41, $41, $41, $41, $43, $41, $43, $82, $40, $40, $40, $40, $40
    .byte $40, $40, $01, $01, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $81, $81
    .byte $80, $80, $80, $80, $80, $80, $80, $80, $FF

LoadAudioTrackSet0:
    LDX #$00
    BEQ Label_B88F

LoadAudioTrackSet1:
    LDX #$08
    BNE Label_B88F

LoadAudioTrackSet2:
    LDX #$10
    BNE Label_B88F

LoadAudioTrackSet3:
    LDX #$18
    BNE Label_B88F

LoadAudioTrackSet4:
    LDX #$20
    BNE Label_B88F

LoadAudioTrackSet5:
    LDX #$28
    BNE LoadAudioTrackSetByOffset

LoadAudioTrackSet7:
    LDX #$38

Label_B88F:
    LDA a:$07C7
    BEQ LoadAudioTrackSetByOffset
    RTS

LoadAudioTrackSetByOffset:
    LDA AudioTrackTable,X
    STA AudioStreamPointerLo
    LDA a:$B8C7,X
    STA AudioStreamPointerHi
    LDA a:$B8C8,X
    STA $DF
    LDA a:$B8C9,X
    STA $E0
    LDA a:$B8CA,X
    STA $E3
    LDA a:$B8CB,X
    STA $E4
    LDA a:$B8CC,X
    STA AudioPulseParameters
    LDA a:$B8CD,X
    STA $E8
    LDA #$01
    STA AudioStreamTicksRemaining
    STA $E1
    STA $E5
    RTS

AudioTrackTable:
    .byte $E7, $BB, $3F, $BC, $EE, $BC, $BF, $BB, $4F, $BD, $80, $BD, $B9, $BD, $BF, $BB
    .byte $F4, $BD, $F4, $BD, $38, $BE, $A9, $A9, $5D, $BE, $BC, $BE, $1B, $BF, $2F, $2B
    .byte $92, $BF, $FB, $BF, $5D, $C0, $3F, $3B, $A1, $C0, $DE, $C0, $17, $C1, $3F, $BB
    .byte $00, $00, $58, $C1, $58, $C1, $02, $02, $58, $C1, $85, $C1, $C2, $C1, $7F, $7F

StopAudioStreams:
    LDA #$00
    STA APU_STATUS
    STA AudioStreamPointerLo
    STA AudioStreamPointerHi
    STA $DF
    STA $E0
    STA $E3
    STA $E4
    RTS

ClearSoundRequests:
    LDA #$00
    STA $EC
    STA $EF
    STA $F2
    STA $F5
    RTS

UpdateAudioStreams:
    LDX #$00
    JSR UpdateAudioStream
    LDX #$04
    JSR UpdateAudioStream
    LDX #$08

UpdateAudioStream:
    LDA AudioStreamPointerLo,X
    ORA AudioStreamPointerHi,X
    BNE Label_B936
    RTS

Label_B936:
    DEC AudioStreamTicksRemaining,X
    BEQ Label_B95B
    LDA AudioStreamTicksRemaining,X
    CMP #$03
    BNE Label_B95A
    JSR ReadChannelSoundRequest
    BNE Label_B95A
    CPX #$00
    BNE Label_B94B
    LDA #$0E

Label_B94B:
    CPX #$04
    BNE Label_B951
    LDA #$0D

Label_B951:
    CPX #$08
    BNE Label_B957
    LDA #$0B

Label_B957:
    STA APU_STATUS

Label_B95A:
    RTS

Label_B95B:
    LDA (AudioStreamPointerLo,X)
    BNE Label_B962
    JMP Label_BA9D

Label_B962:
    JSR AdvanceAudioStream
    CMP #$6F
    BNE Label_B97E
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    SEC
    SBC #$32
    STA AudioStreamOctaveOffset,X
    ASL A
    CLC
    ADC AudioStreamOctaveOffset,X
    ASL A
    ASL A
    STA AudioStreamOctaveOffset,X
    JMP Label_B95B

Label_B97E:
    CMP #$74
    BNE Label_B992
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    SEC
    SBC #$30
    ASL A
    ASL A
    ASL A
    STA AudioTempoOffset
    JMP Label_B95B

Label_B992:
    CMP #$6C
    BNE Label_B9D2
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    CMP #$40
    BNE Label_B9A3
    LDA #$00
    BEQ Label_B9BD

Label_B9A3:
    CMP #$38
    BNE Label_B9AB
    LDA #$01
    BNE Label_B9BD

Label_B9AB:
    CMP #$34
    BNE Label_B9B3
    LDA #$02
    BNE Label_B9BD

Label_B9B3:
    CMP #$32
    BNE Label_B9BB
    LDA #$03
    BNE Label_B9BD

Label_B9BB:
    LDA #$04

Label_B9BD:
    CPX #$00
    BNE Label_B9C3
    STA AudioDefaultLengthIndices

Label_B9C3:
    CPX #$04
    BNE Label_B9C9
    STA $EA

Label_B9C9:
    CPX #$08
    BNE Label_B9CF
    STA $EB

Label_B9CF:
    JMP Label_B95B

Label_B9D2:
    CMP #$76
    BNE Label_B9DE
    LDA (AudioStreamPointerLo,X)
    JSR AdvanceAudioStream
    JMP Label_B95B

Label_B9DE:
    CMP #$61
    BCC Label_BA0D
    CMP #$68
    BCS Label_BA0D
    SEC
    SBC #$61
    TAY
    LDA NoteSemitoneOffsets,Y
    CLC
    ADC AudioStreamOctaveOffset,X
    TAY
    LDA (AudioStreamPointerLo,X)
    CMP #$2B
    BNE Label_B9FE
    INY
    JSR AdvanceAudioStream
    JMP Label_BA06

Label_B9FE:
    CMP #$2D
    BNE Label_BA06
    DEY
    JSR AdvanceAudioStream

Label_BA06:
    INY
    TYA
    ASL A
    TAY
    JMP Label_BA16

Label_BA0D:
    CMP #$72
    BEQ Label_BA14
    JMP Label_BAA0

Label_BA14:
    LDY #$00

Label_BA16:
    JSR ReadChannelSoundRequest
    BNE Label_BA35
    JSR ConfigureAudioChannel
    CPX #$08
    BNE Label_BA29
    TYA
    BEQ Label_BA29
    CLC
    ADC #$18
    TAY

Label_BA29:
    LDA ApuPeriodTable,Y
    STA APU_PL1_LO,X
    LDA a:$BB56,Y
    STA APU_PL1_HI,X

Label_BA35:
    CPX #$00
    BNE Label_BA3E
    LDA AudioDefaultLengthIndices
    JMP Label_BA49

Label_BA3E:
    CPX #$04
    BNE Label_BA47
    LDA $EA
    JMP Label_BA49

Label_BA47:
    LDA $EB

Label_BA49:
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    LDA (AudioStreamPointerLo,X)
    CMP #$40
    BEQ Label_BA60
    CMP #$30
    BCC Label_BA8B
    CMP #$3A
    BCS Label_BA8B

Label_BA60:
    CMP #$31
    BNE Label_BA66
    LDY #$04

Label_BA66:
    CMP #$32
    BNE Label_BA6C
    LDY #$03

Label_BA6C:
    CMP #$34
    BNE Label_BA72
    LDY #$02

Label_BA72:
    CMP #$38
    BNE Label_BA78
    LDY #$01

Label_BA78:
    CMP #$40
    BNE Label_BA7E
    LDY #$00

Label_BA7E:
    TYA
    CLC
    ADC AudioTempoOffset
    TAY
    LDA NoteLengthTable,Y
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

Label_BA8B:
    LDA (AudioStreamPointerLo,X)
    CMP #$2E
    BNE Label_BA9C
    LDA AudioStreamTicksRemaining,X
    LSR A
    CLC
    ADC AudioStreamTicksRemaining,X
    STA AudioStreamTicksRemaining,X
    JSR AdvanceAudioStream

Label_BA9C:
    RTS

Label_BA9D:
    JSR AdvanceAudioStream

Label_BAA0:
    LDA (AudioStreamPointerLo,X)
    PHA
    JSR AdvanceAudioStream
    ORA (AudioStreamPointerLo,X)
    TAY
    LDA (AudioStreamPointerLo,X)
    PHA
    TYA
    BNE Label_BAB6
    STA AudioStreamPointerLo,X
    STA AudioStreamPointerHi,X
    PLA
    PLA
    RTS

Label_BAB6:
    PLA
    STA AudioStreamPointerHi,X
    PLA
    STA AudioStreamPointerLo,X
    JMP Label_B95B

ReadChannelSoundRequest:
    CPX #$00
    BNE Label_BAC6
    LDA $EC
    RTS

Label_BAC6:
    CPX #$04
    BNE Label_BACD
    LDA $EF
    RTS

Label_BACD:
    CPX #$08
    BNE Label_BAD4
    LDA $F2
    RTS

Label_BAD4:
    LDA #$FF
    RTS

AdvanceAudioStream:
    INC AudioStreamPointerLo,X
    BNE Label_BADD
    INC AudioStreamPointerHi,X

Label_BADD:
    RTS
    .byte $C9, $3A, $B0, $04, $38, $E9, $30, $60, $E9, $57, $60

ConfigureAudioChannel:
    LDA #$0F
    STA APU_STATUS
    CPX #$00
    BNE Label_BAFD
    LDA AudioPulseParameters
    STA APU_PL1_VOL
    LDA #$08
    STA APU_PL1_SWEEP
    RTS

Label_BAFD:
    CPX #$04
    BNE Label_BB0C
    LDA $E8
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    RTS

Label_BB0C:
    CPX #$08
    BNE Label_BB15
    LDA #$FF
    STA APU_TRI_LINEAR

Label_BB15:
    RTS

NoteSemitoneOffsets:
    .byte $09, $0B, $00, $02, $04, $05, $07

NoteLengthTable:
    .byte $05, $0A, $14, $28, $50, $01, $01, $01, $06, $0C, $18, $30, $60, $01, $01, $01
    .byte $07, $0E, $1C, $38, $70, $01, $01, $01, $08, $10, $20, $40, $80, $01, $01, $01
    .byte $09, $12, $24, $48, $90, $01, $01, $01, $0A, $14, $28, $50, $A0, $01, $01, $01
    .byte $0B, $16, $2C, $58, $B0, $01, $01, $01

ApuPeriodTable:
    .byte $00, $00, $B3, $06, $53, $06, $F8, $05, $A3, $05, $52, $05, $06, $05, $BE, $04
    .byte $7A, $04, $3A, $04, $FD, $03, $C4, $03, $8E, $03, $59, $03, $29, $03, $FC, $02
    .byte $D1, $02, $A9, $02, $83, $02, $5F, $02, $3D, $02, $1D, $02, $FE, $01, $E2, $01
    .byte $C7, $01, $AC, $01, $94, $01, $7E, $01, $68, $01, $54, $01, $41, $01, $2F, $01
    .byte $1E, $01, $0E, $01, $FF, $00, $F1, $00, $E3, $00, $D6, $00, $CA, $00, $BF, $00
    .byte $B4, $00, $AA, $00, $A0, $00, $97, $00, $8F, $00, $87, $00, $7F, $00, $78, $00
    .byte $71, $00, $6B, $00, $65, $00, $5F, $00, $5A, $00, $55, $00, $50, $00, $4B, $00
    .byte $47, $00, $43, $00, $3F, $00, $3C, $00, $38, $00, $35, $00, $32, $00, $2F, $00
    .byte $2D, $00, $2A, $00, $28, $00, $25, $00, $23, $00, $21, $00, $1F, $00, $1E, $00
    .byte $1C, $00

MusicMmlData:
    .byte $74, $35, $76, $39, $6C, $38, $6F, $34, $63, $65, $67, $65, $66, $64, $67, $67
    .byte $63, $65, $67, $65, $66, $64, $67, $72, $38, $63, $65, $67, $65, $66, $64, $67
    .byte $67, $63, $65, $67, $65, $66, $64, $63, $38, $72, $38, $6F, $36, $63, $6F, $35
    .byte $62, $61, $67, $61, $67, $67, $67, $67, $66, $66, $66, $66, $65, $67, $72, $38
    .byte $6F, $36, $63, $6F, $35, $62, $61, $67, $61, $67, $67, $67, $67, $66, $65, $64
    .byte $63, $65, $63, $72, $38, $00, $E7, $BB, $76, $39, $6C, $40, $6F, $34, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $63, $6F, $34
    .byte $62, $61, $67, $66, $65, $64, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $63, $6F, $34, $62, $61, $67, $38, $72, $38, $65, $67
    .byte $63, $67, $6F, $35, $63, $6F, $34, $67, $6F, $35, $65, $63, $64, $63, $6F, $34
    .byte $62, $61, $67, $66, $65, $64, $65, $67, $63, $67, $6F, $35, $63, $6F, $34, $67
    .byte $6F, $35, $65, $63, $64, $6F, $34, $67, $61, $62, $6F, $35, $63, $38, $72, $38
    .byte $6F, $34, $63, $67, $65, $67, $64, $67, $63, $67, $64, $67, $63, $67, $65, $67
    .byte $63, $67, $65, $67, $66, $62, $64, $62, $66, $62, $64, $66, $65, $67, $63, $67
    .byte $65, $67, $63, $67, $65, $67, $64, $67, $63, $67, $64, $67, $63, $67, $65, $67
    .byte $63, $67, $64, $67, $64, $67, $65, $67, $64, $67, $65, $67, $63, $67, $6F, $35
    .byte $63, $38, $72, $38, $00, $3F, $BC, $6C, $38, $6F, $34, $63, $6F, $33, $67, $65
    .byte $67, $64, $66, $67, $62, $6F, $34, $63, $6F, $33, $67, $65, $67, $64, $66, $67
    .byte $62, $6F, $34, $63, $6F, $33, $67, $65, $67, $64, $66, $67, $62, $6F, $34, $63
    .byte $6F, $33, $67, $65, $67, $67, $62, $6F, $34, $63, $38, $72, $38, $6F, $33, $67
    .byte $67, $66, $65, $66, $65, $65, $65, $65, $64, $64, $64, $64, $63, $65, $72, $38
    .byte $67, $67, $66, $65, $66, $65, $65, $65, $64, $66, $67, $62, $6F, $34, $63, $6F
    .byte $33, $67, $63, $72, $38, $00, $EE, $BC, $74, $30, $6C, $38, $6F, $35, $63, $34
    .byte $65, $63, $64, $6F, $34, $67, $67, $34, $6F, $35, $63, $34, $65, $63, $64, $67
    .byte $67, $34, $63, $34, $65, $63, $64, $6F, $34, $67, $67, $34, $6F, $35, $63, $34
    .byte $65, $63, $64, $65, $63, $34, $00, $4F, $BD, $6C, $38, $76, $64, $6F, $34, $65
    .byte $67, $6F, $35, $63, $6F, $34, $67, $64, $67, $62, $67, $65, $67, $6F, $35, $63
    .byte $6F, $34, $67, $66, $67, $62, $67, $65, $67, $6F, $35, $63, $6F, $34, $67, $64
    .byte $67, $62, $67, $65, $67, $6F, $35, $63, $6F, $34, $67, $66, $67, $65, $34, $00
    .byte $80, $BD, $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65, $66, $67, $64, $62
    .byte $6F, $34, $63, $6F, $33, $65, $67, $6F, $34, $63, $6F, $33, $62, $67, $66, $64
    .byte $63, $67, $65, $67, $66, $67, $61, $62, $6F, $34, $63, $6F, $33, $65, $67, $6F
    .byte $34, $63, $6F, $33, $62, $67, $6F, $34, $63, $34, $00, $B9, $BD, $74, $32, $6C
    .byte $38, $6F, $35, $63, $2E, $63, $40, $64, $2E, $64, $40, $65, $2E, $65, $40, $66
    .byte $2E, $66, $40, $65, $34, $6F, $34, $67, $34, $6F, $35, $63, $34, $00, $00, $00
    .byte $6C, $38, $6F, $34, $65, $2E, $65, $40, $67, $2E, $67, $40, $6F, $35, $63, $2E
    .byte $63, $40, $63, $2E, $63, $40, $63, $34, $6F, $34, $67, $34, $67, $34, $00, $00
    .byte $00, $6C, $38, $6F, $35, $63, $2E, $63, $40, $6F, $34, $62, $2E, $62, $40, $61
    .byte $2E, $61, $40, $61, $2D, $2E, $61, $2D, $40, $67, $34, $66, $34, $65, $34, $6F
    .byte $32, $63, $32, $00, $00, $00, $74, $32, $6C, $38, $6F, $34, $67, $34, $62, $67
    .byte $66, $34, $61, $66, $67, $34, $62, $67, $61, $6F, $35, $64, $64, $34, $6F, $34
    .byte $67, $34, $62, $67, $66, $34, $61, $66, $67, $62, $6F, $35, $65, $64, $72, $32
    .byte $63, $34, $65, $63, $6F, $34, $62, $2D, $34, $6F, $35, $64, $6F, $34, $62, $2D
    .byte $6F, $35, $63, $34, $65, $63, $64, $67, $67, $34, $63, $34, $65, $63, $6F, $34
    .byte $62, $2D, $34, $6F, $35, $64, $6F, $34, $62, $2D, $6F, $35, $63, $65, $61, $67
    .byte $72, $32, $00, $5D, $BE, $6C, $38, $6F, $33, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $61, $34, $6F, $34, $63, $6F, $33, $61, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $6F, $34, $64, $6F, $33, $61, $61, $34, $62, $34, $6F, $34, $64, $6F, $33
    .byte $62, $61, $34, $6F, $34, $63, $6F, $33, $61, $62, $6F, $34, $64, $61, $67, $72
    .byte $32, $65, $34, $67, $65, $64, $34, $66, $64, $65, $34, $67, $65, $67, $64, $64
    .byte $34, $65, $34, $67, $65, $64, $34, $66, $64, $65, $67, $6F, $35, $64, $63, $72
    .byte $32, $00, $BC, $BE, $6C, $38, $6F, $33, $67, $34, $64, $67, $66, $34, $63, $66
    .byte $67, $34, $64, $67, $66, $34, $64, $66, $67, $34, $64, $67, $66, $34, $63, $66
    .byte $67, $64, $6F, $34, $63, $6F, $33, $62, $72, $38, $6F, $32, $67, $72, $38, $67
    .byte $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D, $34, $66
    .byte $62, $2D, $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33, $62, $2D
    .byte $34, $66, $62, $2D, $6F, $34, $63, $34, $6F, $33, $67, $6F, $34, $63, $6F, $33
    .byte $62, $2D, $34, $66, $62, $2D, $6F, $34, $63, $6F, $33, $67, $6F, $34, $66, $65
    .byte $72, $38, $6F, $32, $63, $72, $38, $63, $00, $1B, $BF, $74, $35, $76, $66, $6C
    .byte $40, $6F, $34, $67, $38, $61, $67, $66, $2B, $67, $6F, $35, $65, $34, $63, $38
    .byte $6F, $34, $62, $34, $61, $38, $6C, $34, $6F, $35, $64, $2E, $6C, $38, $6F, $34
    .byte $66, $67, $2E, $61, $40, $62, $6F, $35, $63, $2E, $64, $40, $63, $34, $64, $65
    .byte $34, $63, $6C, $40, $67, $38, $61, $67, $66, $2B, $67, $66, $34, $65, $38, $63
    .byte $2B, $34, $64, $38, $61, $34, $63, $38, $6C, $38, $6F, $34, $62, $61, $2E, $67
    .byte $40, $6F, $35, $66, $65, $2E, $64, $40, $63, $65, $67, $6F, $36, $63, $34, $72
    .byte $38, $00, $00, $00, $76, $66, $6C, $40, $6F, $34, $65, $38, $66, $65, $64, $2B
    .byte $65, $67, $34, $67, $38, $67, $34, $66, $38, $6C, $34, $61, $2E, $6C, $38, $64
    .byte $65, $2E, $66, $40, $67, $61, $2E, $66, $40, $65, $34, $66, $67, $34, $65, $6C
    .byte $40, $6F, $35, $65, $38, $66, $65, $64, $2B, $65, $63, $2B, $34, $6F, $34, $61
    .byte $38, $65, $34, $66, $38, $6F, $35, $63, $34, $6F, $34, $66, $2B, $38, $6C, $38
    .byte $67, $66, $2E, $64, $40, $62, $67, $2E, $66, $40, $65, $67, $6F, $35, $63, $65
    .byte $34, $72, $38, $00, $00, $00, $6C, $38, $6F, $34, $63, $6F, $33, $67, $63, $65
    .byte $63, $65, $66, $63, $66, $63, $66, $65, $64, $66, $61, $67, $34, $64, $63, $65
    .byte $67, $38, $63, $65, $67, $62, $2D, $66, $62, $2D, $61, $34, $63, $2B, $64, $61
    .byte $64, $64, $2B, $66, $2B, $61, $67, $64, $67, $64, $67, $64, $63, $6F, $34, $63
    .byte $6F, $33, $67, $63, $34, $72, $38, $00, $00, $00, $74, $32, $76, $66, $6C, $38
    .byte $6F, $35, $63, $34, $2E, $6F, $34, $66, $67, $6F, $35, $63, $64, $34, $2E, $67
    .byte $34, $2E, $66, $65, $64, $65, $32, $2E, $67, $66, $2B, $67, $61, $2D, $32, $67
    .byte $61, $2D, $62, $2D, $32, $61, $62, $2D, $6F, $36, $63, $72, $6F, $35, $62, $2D
    .byte $6F, $36, $63, $31, $00, $00, $00, $76, $66, $6C, $38, $6F, $34, $67, $34, $2E
    .byte $63, $64, $67, $67, $34, $2E, $6F, $35, $64, $34, $2E, $64, $63, $6F, $34, $62
    .byte $2D, $6F, $35, $63, $2B, $32, $2E, $65, $64, $2B, $65, $63, $32, $6F, $34, $62
    .byte $6F, $35, $63, $64, $32, $63, $2B, $64, $67, $72, $66, $67, $31, $00, $00, $00
    .byte $6C, $38, $6F, $33, $63, $32, $2E, $6F, $32, $62, $32, $2E, $62, $2D, $34, $2E
    .byte $61, $6F, $33, $65, $67, $61, $34, $2E, $6F, $32, $61, $34, $2E, $61, $2D, $6F
    .byte $33, $63, $65, $2D, $61, $2D, $65, $2D, $63, $6F, $32, $62, $2D, $6F, $33, $64
    .byte $66, $62, $2D, $66, $64, $6F, $33, $63, $65, $67, $6F, $34, $63, $31, $00, $00
    .byte $00, $74, $30, $6C, $34, $6F, $34, $62, $2D, $6F, $35, $63, $64, $63, $64, $65
    .byte $64, $65, $66, $65, $66, $67, $61, $72, $34, $63, $62, $2D, $32, $61, $67, $66
    .byte $2B, $66, $65, $66, $67, $66, $31, $2E, $66, $31, $2E, $00, $00, $00, $6C, $34
    .byte $6F, $34, $67, $61, $62, $2D, $61, $62, $2D, $6F, $35, $63, $6F, $34, $62, $2D
    .byte $6F, $35, $63, $64, $63, $64, $65, $66, $72, $34, $6F, $34, $67, $66, $2B, $32
    .byte $66, $2B, $67, $67, $67, $67, $61, $62, $2D, $61, $67, $61, $62, $2D, $6F, $35
    .byte $63, $6F, $34, $62, $2D, $61, $31, $2E, $00, $00, $00, $6C, $34, $6F, $34, $72
    .byte $38, $67, $67, $67, $61, $61, $61, $38, $72, $38, $62, $2D, $62, $2D, $62, $2D
    .byte $6F, $35, $63, $63, $63, $38, $63, $72, $34, $6F, $34, $61, $6F, $35, $65, $2D
    .byte $32, $63, $6F, $34, $72, $38, $62, $2D, $62, $2D, $62, $2D, $6F, $35, $63, $63
    .byte $63, $38, $63, $6F, $34, $62, $2D, $6F, $35, $63, $64, $2D, $65, $2D, $64, $2D
    .byte $63, $31, $2E, $00, $00, $00

Func_C20D:
    LDA #$0F
    STA APU_STATUS
    LDA #$01
    STA a:$07D0
    STA $EC
    LDA #$DF
    STA APU_PL1_VOL
    LDA #$BA
    STA APU_PL1_SWEEP
    LDA #$40
    STA APU_PL1_LO
    LDA #$A0
    STA APU_PL1_HI
    LDA #$00
    STA a:$07D0
    RTS

Func_C233:
    LDA #$0F
    STA APU_STATUS
    LDA #$02
    STA a:$07D1
    STA a:$07D3
    STA $EF
    STA $F5
    LDA #$83
    STA APU_PL2_VOL
    LDA #$96
    STA APU_PL2_SWEEP
    LDA #$FF
    STA APU_PL2_LO
    LDA #$F1
    STA APU_PL2_HI
    LDA #$C1
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$F8
    STA APU_NOISE_HI
    LDA #$00
    STA $F0
    STA a:$07D1
    STA a:$07D3
    RTS

Func_C272:
    LDA #$0F
    STA APU_STATUS
    LDA #$03
    STA a:$07D1
    STA $EF
    LDA #$40
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    LDA #$50
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    LDA #$00
    STA $F0
    STA a:$07D1
    RTS

Func_C29A:
    LDA #$0F
    STA APU_STATUS
    LDA #$04
    STA a:$07D3
    STA $F5
    LDA #$18
    STA APU_NOISE_VOL
    LDA #$0C
    STA APU_NOISE_LO
    LDA #$38
    STA APU_NOISE_HI
    LDA #$00
    STA $F6
    STA a:$07D3
    RTS

Func_C2BD:
    LDA #$0F
    STA APU_STATUS
    LDA #$05
    STA a:$07D2
    STA a:$07D3
    STA $F2
    STA $F5
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$F0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    LDA #$00
    STA $F3
    STA $F6
    STA a:$07D2
    STA a:$07D3
    RTS

Func_C2F9:
    LDA #$0F
    STA APU_STATUS
    LDA a:$07D0
    BNE Label_C318
    LDA $EC
    BEQ Label_C318
    CMP #$01
    BNE Label_C318
    LDA APU_STATUS
    AND #$01
    BNE Label_C318
    LDA #$00
    STA $EC
    BEQ Label_C318

Label_C318:
    LDA a:$07D1
    BNE Label_C354
    LDA $EF
    BEQ Label_C354
    CMP #$03
    BNE Label_C347
    LDA APU_STATUS
    AND #$02
    BNE Label_C354
    INC $F0
    LDX $F0
    CPX #$04
    BCC Label_C33A
    LDA #$00
    STA $EF
    BEQ Label_C354

Label_C33A:
    LDA a:$C42D,X
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    BNE Label_C354

Label_C347:
    CMP #$02
    BNE Label_C354
    LDA APU_STATUS
    AND #$02
    BNE Label_C354
    STA $EF

Label_C354:
    LDA a:$07D2
    BNE Label_C3B5
    LDA $F2
    BEQ Label_C3B5
    CMP #$02
    BNE Label_C389
    LDA APU_STATUS
    AND #$04
    BNE Label_C3B5
    INC $F3
    LDX $F3
    CPX #$04
    BCC Label_C376
    LDA #$00
    STA $F2
    BEQ Label_C3B5

Label_C376:
    LDA #$3F
    STA APU_TRI_LINEAR
    LDA a:$C429,X
    STA APU_TRI_LO
    LDA #$59
    STA APU_TRI_HI
    JMP Label_C3B5

Label_C389:
    CMP #$05
    BNE Label_C3B5
    LDA APU_STATUS
    AND #$04
    BNE Label_C3B5
    INC $F3
    LDX $F3
    CPX #$02
    BCC Label_C3A3
    LDA #$00
    STA $F2
    JMP Label_C3B5

Label_C3A3:
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$A0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    JMP Label_C3B5

Label_C3B5:
    LDA a:$07D3
    BNE Label_C428
    LDA $F5
    BEQ Label_C428
    CMP #$04
    BNE Label_C3EF
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    INC $F6
    LDA $F6
    CMP #$04
    BCS Label_C3E9
    AND #$03
    TAX
    LDA a:$C431,X
    STA APU_NOISE_VOL
    LDA a:$C435,X
    STA APU_NOISE_LO
    LDA a:$C439,X
    STA APU_NOISE_HI
    JMP Label_C428

Label_C3E9:
    LDA #$00
    STA $F5
    BEQ Label_C428

Label_C3EF:
    CMP #$05
    BNE Label_C419
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    INC $F6
    LDX $F6
    CPX #$02
    BCC Label_C408
    LDA #$00
    STA $F5
    BEQ Label_C428

Label_C408:
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0D
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    BNE Label_C428

Label_C419:
    CMP #$02
    BNE Label_C428
    LDA APU_STATUS
    AND #$08
    BNE Label_C428
    LDA #$00
    STA $F5

Label_C428:
    RTS
    .byte $F0, $E0, $D0, $C0, $50, $3F, $3D, $35, $18, $1B, $1E, $03, $0C, $09, $06, $02
    .byte $38, $38, $58, $38

Func_C43D:
    LDA a:$07C4
    BEQ Label_C443
    RTS

Label_C443:
    LDA $38
    SEC
    SBC #$40
    STA $2B
    LDA $39
    SBC #$00
    BCS Label_C456

Label_C450:
    LDA #$00
    STA $34
    BEQ Label_C479

Label_C456:
    LDA $2B
    BEQ Label_C450
    CMP #$C0
    BCC Label_C464
    LDA #$80
    STA $34
    BNE Label_C479

Label_C464:
    ASL A
    STA $2B
    LDA #$00
    STA $2A
    ROL A
    STA $2C
    LDA #$03
    STA $29
    JSR Func_C47A
    LDA $27
    STA $34

Label_C479:
    RTS

Func_C47A:
    LDA $29
    ORA $2A
    BNE Label_C482
    SEC
    RTS

Label_C482:
    LDA #$01
    STA $25
    LDA #$00
    STA $26
    STA $28
    STA $27

Label_C48E:
    LDA $2A
    BMI Label_C49D
    ASL $29
    ROL $2A
    ASL $25
    ROL $26
    JMP Label_C48E

Label_C49D:
    LDA $2B
    CMP $29
    LDA $2C
    SBC $2A
    BCC Label_C4C0
    LDA $2B
    SBC $29
    STA $2B
    LDA $2C
    SBC $2A
    STA $2C
    LDA $25
    CLC
    ADC $27
    STA $27
    LDA $26
    ADC $28
    STA $28

Label_C4C0:
    LSR $2A
    ROR $29
    BCS Label_C4CC
    LSR $26
    ROR $25
    BCC Label_C49D

Label_C4CC:
    RTS

Func_C4CD:
    JSR DisableNmi
    JSR DisableRendering

Label_C4D3:
    LDA PPU_STATUS
    BPL Label_C4D3
    LDA #$3F
    STA PPU_ADDR
    LDY #$00
    STY PPU_ADDR

Label_C4E2:
    LDA ($21),Y
    STA PPU_DATA
    INY
    CPY #$20
    BCC Label_C4E2
    LDA #$3F
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    STA PPU_ADDR
    STA PPU_ADDR
    RTS
    .byte $0F, $16, $36, $30, $0F, $1A, $36, $30, $0F, $08, $17, $27, $0F, $00, $10, $30
    .byte $0F, $18, $28, $38, $0F, $00, $16, $30, $0F, $00, $2A, $30, $0F, $12, $22, $2A
    .byte $0F, $16, $10, $30, $0F, $18, $1A, $2A, $0F, $07, $17, $27, $0F, $12, $21, $28
    .byte $0F, $24, $1A, $36, $0F, $24, $1A, $36, $0F, $24, $1A
    ROL $0F,X
    BIT $1A
    .byte $36

RoomPaletteData:
    .byte $0F, $12, $21, $30, $0F, $12, $21, $16, $0F, $1A, $28, $25, $0F, $08, $18, $20
    .byte $0F, $12, $21, $30, $0F, $16, $28, $20, $0F, $25, $1A, $36, $0F, $00, $10, $30

ResetPpuScroll:
    LDA PPU_STATUS
    LDA #$00
    STA PPU_SCROLL
    STA PPU_SCROLL
    RTS

Nmi:
    PHA
    TXA
    PHA
    TYA
    PHA
    LDA #$B0
    STA PPU_CTRL
    LDA a:$07C5
    BNE NmiFrame
    LDA $F8
    TAX
    LDA a:$C88E,X
    STA $FA
    LDA a:$C8A5,X
    STA $F9
    JMP ($00F9)

NmiFrame:
    LDA #$00
    STA OAM_ADDR
    LDA #$02
    STA OAM_DMA
    LDA #$B0
    STA PPU_CTRL
    LDA PPU_STATUS
    LDA #$00
    STA PPU_SCROLL
    STA PPU_SCROLL
    LDA $FB
    BEQ Label_C5A9
    JMP Func_C7AD

Label_C5A9:
    LDA #$FF
    STA $FB
    JSR BuildDmaOam
    LDA #$00
    STA $FB
    LDY #$04
    LDX #$40

Label_C5B8:
    DEX
    BNE Label_C5B8
    DEY
    BNE Label_C5B8

Label_C5BE:
    LDA $36
    BEQ Label_C5C6
    LDA $34
    STA $35

Label_C5C6:
    LDA a:$07C5
    BNE Label_C5DA
    LDA PPU_STATUS
    LDA $35
    STA PPU_SCROLL
    LDA #$00
    STA PPU_SCROLL
    STA $36

Label_C5DA:
    INC $00
    LDX $F8
    LDA #$00
    STA a:$0785,X
    CPX #$16
    BCC Label_C5ED

Label_C5E7:
    LDX #$00
    STX $F8
    BEQ Label_C5F9

Label_C5ED:
    INX
    CPX #$17
    BCS Label_C5E7
    LDA a:$0785,X
    BEQ Label_C5ED
    STX $F8

Label_C5F9:
    LDA $FC
    BEQ Label_C5FF
    DEC $FC

Label_C5FF:
    LDA a:$07C7
    BNE Label_C613
    JSR ReadController1
    STA Controller1Buttons
    JSR ReadController2
    STA Controller2Buttons
    JMP Label_C61E

Label_C613:
    JSR Func_B80A
    STA Controller1Buttons
    LDA #$00
    STA Controller2Buttons

Label_C61E:
    JSR ReadController1
    STA a:$07CE
    INC a:$0763
    LDA a:$0763
    CMP #$03
    BCC Label_C633
    LDA #$00
    STA a:$0763

Label_C633:
    INC a:$0764
    LDA a:$0764
    CMP #$05
    BCC Label_C642
    LDA #$00
    STA a:$0764

Label_C642:
    INC a:$0765
    LDA a:$0765
    CMP #$06
    BCC Label_C651
    LDA #$00
    STA a:$0765

Label_C651:
    INC a:$0766
    LDA a:$0766
    CMP #$07
    BCC Label_C660
    LDA #$00
    STA a:$0766

Label_C660:
    INC a:$0767
    LDA a:$0767
    CMP #$03
    BCC Label_C66F
    LDA #$00
    STA a:$0767

Label_C66F:
    INC a:$0768
    LDA a:$0768
    CMP #$0A
    BCC Label_C67E
    LDA #$00
    STA a:$0768

Label_C67E:
    INC a:$0769
    LDA a:$0769
    CMP #$0B
    BCC Label_C68D
    LDA #$00
    STA a:$0769

Label_C68D:
    INC a:$076A
    LDA a:$076A
    CMP #$1E
    BCC Label_C69C
    LDA #$00
    STA a:$076A

Label_C69C:
    LDA a:$07C4
    BNE Label_C6A7
    JSR UpdateAudioStreams
    JSR Func_C2F9

Label_C6A7:
    LDA $FB
    BNE Label_C6B3
    LDA $00
    LSR A
    BCC Label_C6B3
    JSR ReverseDmaOam

Label_C6B3:
    PLA
    TAY
    PLA
    TAX
    PLA

Irq:
    RTI

BuildDmaOam:
    LDX #$00

Label_C6BB:
    TXA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA $20
    LDA $00
    AND #$07
    CLC
    ADC $20
    TAY
    LDA a:$C79D,Y
    TAY
    LDA OamStagingBuffer,Y
    STA OamDmaBuffer,X
    LDA a:$0301,Y
    STA a:$0201,X
    LDA a:$0302,Y
    STA a:$0202,X
    LDA a:$0303,Y
    STA a:$0203,X
    LDA a:$0320,Y
    STA a:$0204,X
    LDA a:$0321,Y
    STA a:$0205,X
    LDA a:$0322,Y
    STA a:$0206,X
    LDA a:$0323,Y
    STA a:$0207,X
    LDA a:$0340,Y
    STA a:$0208,X
    LDA a:$0341,Y
    STA a:$0209,X
    LDA a:$0342,Y
    STA a:$020A,X
    LDA a:$0343,Y
    STA a:$020B,X
    LDA a:$0360,Y
    STA a:$020C,X
    LDA a:$0361,Y
    STA a:$020D,X
    LDA a:$0362,Y
    STA a:$020E,X
    LDA a:$0363,Y
    STA a:$020F,X
    LDA a:$0380,Y
    STA a:$0210,X
    LDA a:$0381,Y
    STA a:$0211,X
    LDA a:$0382,Y
    STA a:$0212,X
    LDA a:$0383,Y
    STA a:$0213,X
    LDA a:$03A0,Y
    STA a:$0214,X
    LDA a:$03A1,Y
    STA a:$0215,X
    LDA a:$03A2,Y
    STA a:$0216,X
    LDA a:$03A3,Y
    STA a:$0217,X
    LDA a:$03C0,Y
    STA a:$0218,X
    LDA a:$03C1,Y
    STA a:$0219,X
    LDA a:$03C2,Y
    STA a:$021A,X
    LDA a:$03C3,Y
    STA a:$021B,X
    LDA a:$03E0,Y
    STA a:$021C,X
    LDA a:$03E1,Y
    STA a:$021D,X
    LDA a:$03E2,Y
    STA a:$021E,X
    LDA a:$03E3,Y
    STA a:$021F,X
    TXA
    ADC #$20
    BEQ Label_C798
    TAX
    JMP Label_C6BB

Label_C798:
    LDA #$FF
    STA $36
    RTS
    .byte $00, $04, $08, $0C, $10, $14, $18, $1C, $00, $04, $08, $0C, $10, $14, $18, $1C

Func_C7AD:
    JSR ReverseDmaOam
    LDY #$03
    LDX #$72

Label_C7B4:
    DEX
    BNE Label_C7B4
    DEY
    BNE Label_C7B4
    JMP Label_C5BE

ReverseDmaOam:
    LDX #$00
    LDY #$FC

Label_C7C1:
    LDA OamDmaBuffer,X
    PHA
    LDA a:$0201,X
    PHA
    LDA a:$0202,X
    PHA
    LDA a:$0203,X
    PHA
    LDA OamDmaBuffer,Y
    STA OamDmaBuffer,X
    LDA a:$0201,Y
    STA a:$0201,X
    LDA a:$0202,Y
    STA a:$0202,X
    LDA a:$0203,Y
    STA a:$0203,X
    PLA
    STA a:$0203,Y
    PLA
    STA a:$0202,Y
    PLA
    STA a:$0201,Y
    PLA
    STA OamDmaBuffer,Y
    DEY
    DEY
    DEY
    DEY
    INX
    INX
    INX
    INX
    BPL Label_C7C1
    RTS
    LDA a:$07C8
    BEQ Label_C80C
    JMP Label_C8BC

Label_C80C:
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$96
    STA PPU_ADDR
    LDA a:$079D
    STA PPU_DATA
    LDA a:$079E
    STA PPU_DATA
    LDA a:$079F
    STA PPU_DATA
    LDA a:$07A0
    STA PPU_DATA
    LDA a:$07A1
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$87
    STA PPU_ADDR
    LDA a:$076C
    STA PPU_DATA
    LDA a:$076D
    STA PPU_DATA
    LDA a:$0771
    STA PPU_DATA
    LDA a:$0770
    STA PPU_DATA
    LDA a:$076F
    STA PPU_DATA
    LDA a:$076E
    STA PPU_DATA
    LDA PPU_STATUS
    LDA #$20
    STA PPU_ADDR
    LDA #$A8
    STA PPU_ADDR
    LDA a:$07A6
    STA PPU_DATA
    LDA a:$07A5
    STA PPU_DATA
    LDY #$01
    LDX #$28

Label_C885:
    DEX
    BNE Label_C885
    DEY
    BNE Label_C885
    JMP NmiFrame
    .byte $C8, $C8, $C9, $CB, $CC, $CD, $CF, $D0, $D1, $D2, $D4, $D5, $D6, $D7, $D9, $DA
    .byte $DB, $DC, $DE, $DF, $E0, $E1, $E3, $04, $BC, $FF, $42, $85, $C8, $0B, $4E, $91
    .byte $D4, $17, $5A, $9D, $E0, $23, $66, $A9, $EC, $2F, $72, $B5, $F8, $58

Label_C8BC:
    LDA #$20
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX RoomCells
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0401
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0402
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0403
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0404
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0405
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0406
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0407
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0408
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0409
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$24
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$040E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$040F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0410
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0411
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0412
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0413
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$0414
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0415
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0416
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0417
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0418
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0419
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$041F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0420
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0421
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$0422
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0423
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0424
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0425
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0426
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0427
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$0428
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0429
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$042F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0430
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0431
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0432
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0433
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0434
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0435
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$0436
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0437
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0438
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0439
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$043C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$043F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0440
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0441
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0442
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0443
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0444
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0445
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0446
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0447
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0448
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0449
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$044A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$044F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX a:$0450
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0451
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0452
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0453
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0454
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0455
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0456
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0457
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0458
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0459
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX a:$045E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$045F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0460
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0461
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0462
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0463
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX a:$0464
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0465
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0466
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0467
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0468
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0469
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$046F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0470
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0471
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX a:$0472
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0473
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0474
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0475
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0476
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0477
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX a:$0478
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0479
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$047F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0480
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0481
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0482
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0483
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0484
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0485
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX a:$0486
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0487
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0488
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0489
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX a:$048C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$048F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0490
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0491
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0492
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0493
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0494
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0495
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0496
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0497
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0498
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0499
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX a:$049A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$049F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$21
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX a:$04A0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04A9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$25
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$04AE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04AF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$04B4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04B9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04BF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$04C2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$04C8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04C9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04CF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$04D6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04D9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$04DC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04DF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04E9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$04EA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04ED
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04EF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$64
    STA PPU_ADDR
    LDX a:$04F0
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F1
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F2
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F3
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F4
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F5
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F6
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F7
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F8
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04F9
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FA
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FB
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FC
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FD
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$60
    STA PPU_ADDR
    LDX a:$04FE
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$04FF
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0500
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0501
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0502
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0503
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$84
    STA PPU_ADDR
    LDX a:$0504
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0505
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0506
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0507
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0508
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0509
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$050F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0510
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0511
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$80
    STA PPU_ADDR
    LDX a:$0512
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0513
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0514
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0515
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0516
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0517
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$A4
    STA PPU_ADDR
    LDX a:$0518
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0519
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$051F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0520
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0521
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0522
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0523
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0524
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0525
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$A0
    STA PPU_ADDR
    LDX a:$0526
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0527
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0528
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0529
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$C4
    STA PPU_ADDR
    LDX a:$052C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$052F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0530
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0531
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0532
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0533
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0534
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0535
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0536
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0537
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0538
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0539
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$C0
    STA PPU_ADDR
    LDX a:$053A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$053F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$22
    STA PPU_ADDR
    LDA #$E4
    STA PPU_ADDR
    LDX a:$0540
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0541
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0542
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0543
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0544
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0545
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0546
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0547
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0548
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0549
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$26
    STA PPU_ADDR
    LDA #$E0
    STA PPU_ADDR
    LDX a:$054E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$054F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0550
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0551
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0552
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0553
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$04
    STA PPU_ADDR
    LDX a:$0554
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0555
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0556
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0557
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0558
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0559
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$055F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0560
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0561
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$00
    STA PPU_ADDR
    LDX a:$0562
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0563
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0564
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0565
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0566
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0567
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$24
    STA PPU_ADDR
    LDX a:$0568
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0569
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$056F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0570
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0571
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0572
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0573
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0574
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0575
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$20
    STA PPU_ADDR
    LDX a:$0576
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0577
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0578
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0579
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA #$23
    STA PPU_ADDR
    LDA #$44
    STA PPU_ADDR
    LDX a:$057C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$057F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0580
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0581
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0582
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0583
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0584
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0585
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0586
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0587
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0588
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$0589
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDA #$27
    STA PPU_ADDR
    LDA #$40
    STA PPU_ADDR
    LDX a:$058A
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058B
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058C
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058D
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058E
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    LDX a:$058F
    LDA LeftTileByCell,X
    STA PPU_DATA
    LDA RightTileByCell,X
    STA PPU_DATA
    JMP NmiFrame
    LDA PPU_STATUS
    LDA #$23
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA a:$0108
    STA PPU_DATA
    LDA a:$0109
    STA PPU_DATA
    LDA a:$010A
    STA PPU_DATA
    LDA a:$010B
    STA PPU_DATA
    LDA a:$010C
    STA PPU_DATA
    LDA a:$010D
    STA PPU_DATA
    LDA a:$010E
    STA PPU_DATA
    LDA a:$010F
    STA PPU_DATA
    LDA a:$0110
    STA PPU_DATA
    LDA a:$0111
    STA PPU_DATA
    LDA a:$0112
    STA PPU_DATA
    LDA a:$0113
    STA PPU_DATA
    LDA a:$0114
    STA PPU_DATA
    LDA a:$0115
    STA PPU_DATA
    LDA a:$0116
    STA PPU_DATA
    LDA a:$0117
    STA PPU_DATA
    LDA a:$0118
    STA PPU_DATA
    LDA a:$0119
    STA PPU_DATA
    LDA a:$011A
    STA PPU_DATA
    LDA a:$011B
    STA PPU_DATA
    LDA a:$011C
    STA PPU_DATA
    LDA a:$011D
    STA PPU_DATA
    LDA a:$011E
    STA PPU_DATA
    LDA a:$011F
    STA PPU_DATA
    LDA a:$0120
    STA PPU_DATA
    LDA a:$0121
    STA PPU_DATA
    LDA a:$0122
    STA PPU_DATA
    LDA a:$0123
    STA PPU_DATA
    LDA a:$0124
    STA PPU_DATA
    LDA a:$0125
    STA PPU_DATA
    LDA a:$0126
    STA PPU_DATA
    LDA a:$0127
    STA PPU_DATA
    LDA a:$0128
    STA PPU_DATA
    LDA a:$0129
    STA PPU_DATA
    LDA a:$012A
    STA PPU_DATA
    LDA a:$012B
    STA PPU_DATA
    LDA a:$012C
    STA PPU_DATA
    LDA a:$012D
    STA PPU_DATA
    LDA a:$012E
    STA PPU_DATA
    LDA a:$012F
    STA PPU_DATA
    LDA a:$0130
    STA PPU_DATA
    LDA a:$0131
    STA PPU_DATA
    LDA a:$0132
    STA PPU_DATA
    LDA a:$0133
    STA PPU_DATA
    LDA a:$0134
    STA PPU_DATA
    LDA a:$0135
    STA PPU_DATA
    LDA a:$0136
    STA PPU_DATA
    LDA a:$0137
    STA PPU_DATA
    LDA a:$0138
    STA PPU_DATA
    LDA a:$0139
    STA PPU_DATA
    LDA a:$013A
    STA PPU_DATA
    LDA a:$013B
    STA PPU_DATA
    LDA a:$013C
    STA PPU_DATA
    LDA a:$013D
    STA PPU_DATA
    LDA a:$013E
    STA PPU_DATA
    LDA a:$013F
    STA PPU_DATA
    JMP NmiFrame
    LDA PPU_STATUS
    LDA #$27
    STA PPU_ADDR
    LDA #$C8
    STA PPU_ADDR
    LDA a:$0148
    STA PPU_DATA
    LDA a:$0149
    STA PPU_DATA
    LDA a:$014A
    STA PPU_DATA
    LDA a:$014B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0150
    STA PPU_DATA
    LDA a:$0151
    STA PPU_DATA
    LDA a:$0152
    STA PPU_DATA
    LDA a:$0153
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0158
    STA PPU_DATA
    LDA a:$0159
    STA PPU_DATA
    LDA a:$015A
    STA PPU_DATA
    LDA a:$015B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0160
    STA PPU_DATA
    LDA a:$0161
    STA PPU_DATA
    LDA a:$0162
    STA PPU_DATA
    LDA a:$0163
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0168
    STA PPU_DATA
    LDA a:$0169
    STA PPU_DATA
    LDA a:$016A
    STA PPU_DATA
    LDA a:$016B
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0170
    STA PPU_DATA
    LDA a:$0171
    STA PPU_DATA
    LDA a:$0172
    STA PPU_DATA
    LDA a:$0173
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    STA PPU_DATA
    LDA a:$0178
    STA PPU_DATA
    LDA a:$0179
    STA PPU_DATA
    LDA a:$017A
    STA PPU_DATA
    LDA a:$017B
    STA PPU_DATA
    LDX #$19

Label_E457:
    DEX
    BNE Label_E457
    JMP NmiFrame

.include "../game/rooms/decoder.asm"
.include "../rendering/room_attributes.asm"
.include "prg_ea36_eb8e.asm"
.include "../game/objects/room_loader.asm"
.include "prg_ec63_ffff.asm"
