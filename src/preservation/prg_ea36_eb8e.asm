; Preservation PRG between room attributes and object loading
; CPU range $EA36-$EB8E
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

Func_EA36:
    LDA $0F
    BNE Label_EA3B
    RTS

Label_EA3B:
    LDA Controller1Buttons
    AND #$04
    BEQ Label_EA68
    LDA #$00
    STA Controller1Buttons
    STA a:$0777
    LDA a:$07C5
    BNE Label_EA67
    JSR Func_EA81
    LDA #$1E
    STA a:$07C5
    JSR WaitForVblankAndEnableRendering
    LDA a:$07C4
    BNE Label_EA62
    JSR UpdateAudioStreams

Label_EA62:
    LDA #$B8
    STA PPU_CTRL

Label_EA67:
    RTS

Label_EA68:
    LDA a:$07C5
    BEQ Label_EA67
    LDA a:$0777
    EOR #$FF
    AND Controller1Buttons
    AND #$07
    BEQ Label_EA67
    LDA #$00
    STA a:$07C5
    JMP FinalizeRoomLoad

Func_EA81:
    LDA #$1C
    JSR Func_F973
    LDY #$01
    JSR SelectChrBank
    LDA #$C5
    STA $22
    LDA #$1D
    STA $21
    JSR Func_C4CD
    LDX #$00
    STX $1F

Label_EA9A:
    LDX $1F
    LDA a:$069E,X
    BNE Label_EAA4
    JMP Label_EB18

Label_EAA4:
    TXA
    LDX #$00

Label_EAA7:
    CMP #$0A
    BCC Label_EAB0
    INX
    SBC #$0A
    BCS Label_EAA7

Label_EAB0:
    ASL A
    CLC
    ADC #$C6
    STA $21
    LDA #$20
    STA $22
    TXA
    LSR A
    LSR A
    PHA
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC $21
    STA $21
    PLA
    ADC $22
    STA $22
    LDA PPU_STATUS
    LDA $22
    STA PPU_ADDR
    LDA $21
    STA PPU_ADDR
    LDA #$07
    STA PPU_DATA
    LDA #$08
    STA PPU_DATA
    LDA #$20
    ADC $21
    STA $21
    BCC Label_EAF0
    INC $22

Label_EAF0:
    LDA PPU_STATUS
    LDA $22
    STA PPU_ADDR
    LDA $21
    STA PPU_ADDR
    LDA #$09
    STA PPU_DATA
    LDA #$0A
    STA PPU_DATA
    LDA $21
    AND #$1F
    TAX
    ASL $21
    ROL $22
    ASL $21
    ROL $22
    LDA $22
    AND #$1F

Label_EB18:
    INC $1F
    LDA $1F
    CMP #$64
    BCS Label_EB23
    JMP Label_EA9A

Label_EB23:
    LDX #$04
    LDA #$F0

Label_EB27:
    STA OamStagingBuffer,X
    INX
    BNE Label_EB27
    LDA CurrentRoomIndex
    SEC
    SBC #$01
    LDX #$00

Label_EB34:
    CMP #$0A
    BCC Label_EB3E
    INX
    SBC #$0A
    JMP Label_EB34

Label_EB3E:
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #$34
    STA a:$0303
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #$33
    STA OamStagingBuffer
    LDA #$F0
    STA a:$0301
    LDA #$00
    STA a:$0302
    JSR ResetPpuScroll
    JSR WaitForVblankAndEnableRendering
    LDA a:$07C4
    BNE Label_EB6B
    JSR UpdateAudioStreams

Label_EB6B:
    RTS

FinalizeRoomLoad:
    JSR Func_B64C
    JSR Func_A351
    JSR Func_B6C9
    LDA #$FF
    LDX #$16

Label_EB79:
    STA a:$0785,X
    DEX
    BPL Label_EB79
    JSR ResetPpuScroll
    JSR WaitForVblankAndEnableRendering
    LDA #$B8
    STA PPU_CTRL
    LDY #$00
    JMP SelectChrBank
