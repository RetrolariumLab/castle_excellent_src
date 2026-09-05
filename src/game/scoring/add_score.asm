; Player score award and extra-life threshold
; CPU range $8D04-$8D3C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

AddPlayerScore:
    PHA
    LDA DemoPlaybackActive
    BNE DiscardDemoScoreAward
    JSR ComputePlayerScoreThousands
    LDY ScoreThousandsQuotient
    PLA
    CLC
    ADC AwardPlayerScoreLo
    STA AwardPlayerScoreLo
    BCC CompareScoreLifeThreshold
    INC AwardPlayerScoreHi

CompareScoreLifeThreshold:
    JSR ComputePlayerScoreThousands
    TYA
    EOR ScoreThousandsQuotient
    BEQ ReturnFromAddPlayerScore
    INC PlayerLives
    BNE ReturnFromAddPlayerScore
    DEC PlayerLives

ReturnFromAddPlayerScore:
    RTS

DiscardDemoScoreAward:
    PLA
    RTS

ComputePlayerScoreThousands:
    LDA AwardPlayerScoreLo
    STA ScoreDivisionDividendLo
    LDA AwardPlayerScoreHi
    STA ScoreDivisionDividendHi
    LDA #ScoreLifeThresholdHi
    STA ScoreDivisionDivisorHi
    LDA #ScoreLifeThresholdLo
    STA ScoreDivisionDivisorLo
    JMP DivideUnsigned16
