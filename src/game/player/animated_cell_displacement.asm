; Animated-cell forced player displacement
; CPU range $8785-$8819
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

MovePlayerLeftOnIncrementingAnimatedCell:
    LDA PlayerXLo
    SEC
    SBC #AnimatedCellPlayerStep
    STA AnimatedCellPlayerXLo
    LDA PlayerXHi
    SBC #$00
    STA AnimatedCellPlayerXHi
    BMI ReturnFromAnimatedCellPlayerDisplacement
    LDY PlayerY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerMiddleYOffset
    TAY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerBottomYOffset
    TAY
    LDX AnimatedCellPlayerXLo
    LDA AnimatedCellPlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement

CommitAnimatedCellPlayerDisplacement:
    LDA AnimatedCellPlayerXLo
    STA PlayerXLo
    LDA AnimatedCellPlayerXHi
    STA PlayerXHi
    LDA #AnimatedCellMovementLatchSet
    STA PlayerAnimatedCellMovementLatch

ReturnFromAnimatedCellPlayerDisplacement:
    RTS

MovePlayerRightOnDecrementingAnimatedCell:
    LDA PlayerXLo
    CLC
    ADC #AnimatedCellPlayerStep
    STA AnimatedCellPlayerXLo
    LDA PlayerXHi
    ADC #$00
    STA AnimatedCellPlayerXHi
    LDA PlayerXLo
    CLC
    ADC #AnimatedCellPlayerRightEdgeOffset
    STA AnimatedCellPlayerEdgeXLo
    LDA PlayerXHi
    ADC #$00
    STA AnimatedCellPlayerEdgeXHi
    LDA PlayerXLo
    CMP #AnimatedCellPlayerRightLimitLo
    LDA PlayerXHi
    SBC #AnimatedCellPlayerRightLimitHi
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDY PlayerY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerMiddleYOffset
    TAY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    LDA PlayerY
    CLC
    ADC #AnimatedCellPlayerBottomYOffset
    TAY
    LDX AnimatedCellPlayerEdgeXLo
    LDA AnimatedCellPlayerEdgeXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCS ReturnFromAnimatedCellPlayerDisplacement
    BCC CommitAnimatedCellPlayerDisplacement
