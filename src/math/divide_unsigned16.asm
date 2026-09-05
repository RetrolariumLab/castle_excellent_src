; Unsigned 16-bit division helper
; CPU range $C47A-$C4CC
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DivideUnsigned16:
    LDA UnsignedDivisionDivisorLo
    ORA UnsignedDivisionDivisorHi
    BNE InitializeUnsignedDivision
    SEC
    RTS

InitializeUnsignedDivision:
    LDA #$01
    STA UnsignedDivisionBitLo
    LDA #$00
    STA UnsignedDivisionBitHi
    STA UnsignedDivisionQuotientHi
    STA UnsignedDivisionQuotientLo

AlignUnsignedDivisor:
    LDA UnsignedDivisionDivisorHi
    BMI TrySubtractUnsignedDivisor
    ASL UnsignedDivisionDivisorLo
    ROL UnsignedDivisionDivisorHi
    ASL UnsignedDivisionBitLo
    ROL UnsignedDivisionBitHi
    JMP AlignUnsignedDivisor

TrySubtractUnsignedDivisor:
    LDA UnsignedDivisionDividendLo
    CMP UnsignedDivisionDivisorLo
    LDA UnsignedDivisionDividendHi
    SBC UnsignedDivisionDivisorHi
    BCC ShiftUnsignedDivisorRight
    LDA UnsignedDivisionDividendLo
    SBC UnsignedDivisionDivisorLo
    STA UnsignedDivisionDividendLo
    LDA UnsignedDivisionDividendHi
    SBC UnsignedDivisionDivisorHi
    STA UnsignedDivisionDividendHi
    LDA UnsignedDivisionBitLo
    CLC
    ADC UnsignedDivisionQuotientLo
    STA UnsignedDivisionQuotientLo
    LDA UnsignedDivisionBitHi
    ADC UnsignedDivisionQuotientHi
    STA UnsignedDivisionQuotientHi

ShiftUnsignedDivisorRight:
    LSR UnsignedDivisionDivisorHi
    ROR UnsignedDivisionDivisorLo
    BCS ReturnFromUnsignedDivision
    LSR UnsignedDivisionBitHi
    ROR UnsignedDivisionBitLo
    BCC TrySubtractUnsignedDivisor

ReturnFromUnsignedDivision:
    RTS
