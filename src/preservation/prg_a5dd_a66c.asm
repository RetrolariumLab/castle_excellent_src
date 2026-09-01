; Preservation PRG before mutable-cell lookup
; CPU range $A5DD-$A66C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

    LDA $09
    JSR Func_A658
    DEC $09
    JMP Label_A616
    LDA $08
    JSR Func_A658
    DEC $08
    JMP Label_A616
    LDA $0A
    JSR Func_A658
    DEC $0A
    JMP Label_A616
    LDA $07
    JSR Func_A658
    DEC $07
    JMP Label_A616
    LDA $05
    JSR Func_A658
    DEC $05
    JMP Label_A616
    LDA $06
    JSR Func_A658
    DEC $06

Label_A616:
    LDA $1E
    SEC
    SBC #$10
    STA $1E
    TAY
    LDX $21
    LDA $22
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    JSR RestoreMutableCellByOrdinal
    LDA $3B
    BMI Label_A63B
    LDA PlayerXLo
    CMP #$20
    LDA PlayerXHi
    SBC #$01
    BCC Label_A649
    BCS Label_A645

Label_A63B:
    LDA PlayerXLo
    CMP #$11
    LDA PlayerXHi
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
    LDA PlayerY
    AND #$0F
    CMP #$08
    BNE Label_A661
    RTS
