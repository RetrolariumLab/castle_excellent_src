; Knight arrow directional collision probes, movement, and cleanup
; CPU range $9F74-$9FF2
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateKnightArrow:
    STX CurrentObjectOffset
    LDA RuntimeObjectState,X
    BMI MoveKnightArrowLeft

MoveKnightArrowRight:
    LDY RuntimeObjectY,X
    JSR GetRuntimeObjectXPlus7
    BEQ ProbeKnightArrowRightEdge
    CMP #KnightArrowWorldPageOne
    BNE ClearKnightArrow
    CPX #KnightArrowWorldRightLimitLo
    BCS ClearKnightArrow

ProbeKnightArrowRightEdge:
    STX KnightArrowProbeXLo
    STA KnightArrowProbeXHi
    STY KnightArrowProbeY
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDA KnightArrowProbeY
    CLC
    ADC #KnightArrowVerticalExtent
    TAY
    LDX KnightArrowProbeXLo
    LDA KnightArrowProbeXHi
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectXLo,X
    CLC
    ADC #KnightArrowStep
    STA RuntimeObjectXLo,X
    BCC ReturnFromKnightArrowUpdate
    INC RuntimeObjectXHi,X

ReturnFromKnightArrowUpdate:
    RTS

ClearKnightArrow:
    LDX CurrentRuntimeObjectOffset
    JMP ClearCurrentRuntimeObject

MoveKnightArrowLeft:
    LDY RuntimeObjectY,X
    LDA RuntimeObjectXHi,X
    PHA
    LDA RuntimeObjectXLo,X
    SEC
    SBC #KnightArrowStep
    TAX
    PLA
    SBC #KnightArrowCoordinateBorrow
    BCC ClearKnightArrow

ProbeKnightArrowLeftEdge:
    STX KnightArrowProbeXLo
    STA KnightArrowProbeXHi
    STY KnightArrowProbeY
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDA KnightArrowProbeY
    CLC
    ADC #KnightArrowVerticalExtent
    TAY
    LDX KnightArrowProbeXLo
    LDA KnightArrowProbeXHi
    JSR SampleCollisionAtPixel
    BCS ClearKnightArrow
    BMI ClearKnightArrow
    LDX CurrentRuntimeObjectOffset
    LDA KnightArrowProbeXLo
    STA RuntimeObjectXLo,X
    LDA KnightArrowProbeXHi
    STA RuntimeObjectXHi,X
    RTS
