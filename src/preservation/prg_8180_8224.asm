; Preservation PRG between PPU helpers and reset
; CPU range $8180-$8224
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
