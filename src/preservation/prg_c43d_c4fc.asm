; Preservation scroll, division, and palette helpers
; CPU range $C43D-$C4FC
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateHorizontalScroll:
    LDA PauseMode
    BEQ Label_C443
    RTS

Label_C443:
    LDA PlayerXLo
    SEC
    SBC #$40
    STA $2B
    LDA PlayerXHi
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
    JSR DivideUnsigned16
    LDA $27
    STA $34

Label_C479:
    RTS

DivideUnsigned16:
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

UploadPaletteFromPointer:
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
