; Preservation PRG before NMI task reset
; CPU range $8F29-$9577
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $CB, $87, $CB, $87, $CB, $87
    .byte $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87, $CB, $87
    .byte $CB, $87, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $85, $87, $85, $87
    .byte $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87, $85, $87
    .byte $85, $87, $85, $87, $6B, $92, $6B, $92, $6B, $92, $70, $8D, $6B, $92, $80, $8C
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $9E, $8C, $F2, $8C, $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C
    .byte $6B, $92, $6B, $92, $6B, $92, $3D, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $9E, $8C, $F2, $8C, $B2, $8C
    .byte $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92, $6B, $92, $3D, $8D, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $B0, $8D, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $DD, $A5
    .byte $DD, $A5, $6B, $92, $E7, $A5, $E7, $A5, $6B, $92, $F1, $A5, $F1, $A5, $6B, $92
    .byte $FB, $A5, $FB, $A5, $6B, $92, $05, $A6, $05, $A6, $6B, $92, $6B, $92, $0F, $A6
    .byte $0F, $A6, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $6B, $92, $6B, $92, $6B, $92, $70, $8D, $6B, $92, $80, $8C, $B0, $8D, $B0, $8D
    .byte $B0, $8D, $B0, $8D, $B0, $8D, $B0, $8D, $1A, $88, $1A, $88, $1A, $88, $1A, $88
    .byte $E1, $89, $1A, $88, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $9E, $8C, $F2, $8C, $B2, $8C, $C2, $8C, $D2, $8C, $E2, $8C, $6B, $92, $6B, $92
    .byte $6B, $92, $3D, $8D, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92, $6B, $92
    .byte $B0, $8D
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
    LDA CurrentRoomObjectState,X
    STA $16,X
    DEX
    BPL Label_9442
    LDX #$04

Label_944C:
    LDA CurrentRoomMutableCellState,X
    STA $19,X
    DEX
    BPL Label_944C
    JSR ApplyRoomPersistentState
    JSR ResetRoomRuntimeState
    JSR ResetNmiTaskRequests
    JSR ClearRoomNametablesAndSprites
    JSR InitializeRoomStatusDisplay
    JSR BuildRoomAttributeTables
    JSR UploadRoomAttributeTables
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
