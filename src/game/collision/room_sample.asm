; Room-cell-only collision sample
; CPU range $A1A3-$A1D3
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SampleRoomCollisionAtPixel:
    CPY #RuntimeObjectVisibleYLimit
    BCC AddressRoomCollisionSample
    CLC
    LDA #EmptyRoomCell
    LDX #$00
    RTS

AddressRoomCollisionSample:
    JSR PrepareRoomCellSampleAddress
    LDY CollisionSampleColumn
    LDA (RoomCollisionSampleCellPointerLo),Y
    TAX
    LDA CollisionSampleXLo
    LSR A
    LSR A
    LSR A
    LSR A
    TXA
    ROL A
    TAX
    LDA ObjectCollisionFlagsByRoomCellHalf,X
    JSR ClassifyCollisionCellPairIndex
    BNE ReturnRoomCollisionSample
    LDA CollisionSampleAnimationCounter
    BPL ReturnRoomCollisionSample
    LDA #$00

ReturnRoomCollisionSample:
    PHA
    LSR A
    PLA
    PHP
    TXA
    LSR A
    PLP
    RTS
