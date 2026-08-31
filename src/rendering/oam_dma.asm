; OAM DMA construction and sprite-order transforms
; CPU range $C6B9-$C803
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

BuildDmaOam:
    LDX #$00

CopyNextOamInterleaveBlock:
    TXA
    LSR A
    LSR A
    LSR A
    LSR A
    LSR A
    STA OamOutputBlockIndex
    LDA FrameCounter
    AND #OamRotationFrameCount - 1
    CLC
    ADC OamOutputBlockIndex
    TAY
    LDA OamRotationOffsets,Y
    TAY
    LDA OamStagingBuffer,Y
    STA OamDmaBuffer,X
    LDA OamStagingBuffer + $01,Y
    STA OamDmaBuffer + $01,X
    LDA OamStagingBuffer + $02,Y
    STA OamDmaBuffer + $02,X
    LDA OamStagingBuffer + $03,Y
    STA OamDmaBuffer + $03,X
    LDA OamStagingBuffer + $20,Y
    STA OamDmaBuffer + $04,X
    LDA OamStagingBuffer + $21,Y
    STA OamDmaBuffer + $05,X
    LDA OamStagingBuffer + $22,Y
    STA OamDmaBuffer + $06,X
    LDA OamStagingBuffer + $23,Y
    STA OamDmaBuffer + $07,X
    LDA OamStagingBuffer + $40,Y
    STA OamDmaBuffer + $08,X
    LDA OamStagingBuffer + $41,Y
    STA OamDmaBuffer + $09,X
    LDA OamStagingBuffer + $42,Y
    STA OamDmaBuffer + $0A,X
    LDA OamStagingBuffer + $43,Y
    STA OamDmaBuffer + $0B,X
    LDA OamStagingBuffer + $60,Y
    STA OamDmaBuffer + $0C,X
    LDA OamStagingBuffer + $61,Y
    STA OamDmaBuffer + $0D,X
    LDA OamStagingBuffer + $62,Y
    STA OamDmaBuffer + $0E,X
    LDA OamStagingBuffer + $63,Y
    STA OamDmaBuffer + $0F,X
    LDA OamStagingBuffer + $80,Y
    STA OamDmaBuffer + $10,X
    LDA OamStagingBuffer + $81,Y
    STA OamDmaBuffer + $11,X
    LDA OamStagingBuffer + $82,Y
    STA OamDmaBuffer + $12,X
    LDA OamStagingBuffer + $83,Y
    STA OamDmaBuffer + $13,X
    LDA OamStagingBuffer + $A0,Y
    STA OamDmaBuffer + $14,X
    LDA OamStagingBuffer + $A1,Y
    STA OamDmaBuffer + $15,X
    LDA OamStagingBuffer + $A2,Y
    STA OamDmaBuffer + $16,X
    LDA OamStagingBuffer + $A3,Y
    STA OamDmaBuffer + $17,X
    LDA OamStagingBuffer + $C0,Y
    STA OamDmaBuffer + $18,X
    LDA OamStagingBuffer + $C1,Y
    STA OamDmaBuffer + $19,X
    LDA OamStagingBuffer + $C2,Y
    STA OamDmaBuffer + $1A,X
    LDA OamStagingBuffer + $C3,Y
    STA OamDmaBuffer + $1B,X
    LDA OamStagingBuffer + $E0,Y
    STA OamDmaBuffer + $1C,X
    LDA OamStagingBuffer + $E1,Y
    STA OamDmaBuffer + $1D,X
    LDA OamStagingBuffer + $E2,Y
    STA OamDmaBuffer + $1E,X
    LDA OamStagingBuffer + $E3,Y
    STA OamDmaBuffer + $1F,X
    TXA
    ADC #OamInterleaveBlockSize
    BEQ FinishDmaOamBuild
    TAX
    JMP CopyNextOamInterleaveBlock

FinishDmaOamBuild:
    LDA #$FF
    STA ScrollUpdatePending
    RTS

OamRotationOffsets:
    .byte $00, $04, $08, $0C, $10, $14, $18, $1C, $00, $04, $08, $0C, $10, $14, $18

UnusedOamRotationOffset:
    .byte $1C

ReusePreviousDmaOam:
    JSR ReverseDmaOam
    LDY #$03
    LDX #$72

WaitForPreviousOamTiming:
    DEX
    BNE WaitForPreviousOamTiming
    DEY
    BNE WaitForPreviousOamTiming
    JMP UpdateScrollLatch

ReverseDmaOam:
    LDX #$00
    LDY #OamBufferSize - OamSpriteSize

SwapNextOamSpritePair:
    LDA OamDmaBuffer,X
    PHA
    LDA OamDmaBuffer + $01,X
    PHA
    LDA OamDmaBuffer + $02,X
    PHA
    LDA OamDmaBuffer + $03,X
    PHA
    LDA OamDmaBuffer,Y
    STA OamDmaBuffer,X
    LDA OamDmaBuffer + $01,Y
    STA OamDmaBuffer + $01,X
    LDA OamDmaBuffer + $02,Y
    STA OamDmaBuffer + $02,X
    LDA OamDmaBuffer + $03,Y
    STA OamDmaBuffer + $03,X
    PLA
    STA OamDmaBuffer + $03,Y
    PLA
    STA OamDmaBuffer + $02,Y
    PLA
    STA OamDmaBuffer + $01,Y
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
    BPL SwapNextOamSpritePair
    RTS
