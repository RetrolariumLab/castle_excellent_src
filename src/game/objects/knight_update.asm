; Knight patrol, facing gate, and arrow creation
; CPU range $9C3B-$9CC5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateKnight:
    LDA RuntimeObjectByte5,X
    BEQ UpdateKnightPatrol
    DEC RuntimeObjectByte5,X
    RTS

UpdateKnightPatrol:
    JSR UpdateWalkingEnemyPhysics
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #KnightPlayerYAlignmentOffset
    CMP PlayerY
    BEQ CheckKnightFacingPlayer
    RTS

CheckKnightFacingPlayer:
    LDA RuntimeObjectXLo,X
    CMP PlayerXLo
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
    BCC CheckKnightFacingRight
    LDA RuntimeObjectState,X
    BMI CheckKnightArrowCadence
    RTS

CheckKnightFacingRight:
    LDA RuntimeObjectState,X
    BPL CheckKnightArrowCadence
    RTS

CheckKnightArrowCadence:
    LDA RoomFrameCounter
    AND #KnightArrowFrameMask
    BEQ FindKnightArrowSlot
    RTS

FindKnightArrowSlot:
    LDX CurrentRoomNumber
    LDA RoomObjectCounts - 1,X
    TAY
    LDX RuntimeObjectOffsetByCount,Y

ScanKnightArrowSlot:
    LDA RuntimeObjectRecords,X
    BEQ SpawnKnightArrow
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanKnightArrowSlot
    RTS

SpawnKnightArrow:
    LDY CurrentRuntimeObjectOffset
    LDA #KnightArrowCooldown
    STA a:RuntimeObjectByte5,Y
    LDA #KnightArrowRuntimeType
    STA RuntimeObjectRecords,X
    LDA a:RuntimeObjectY,Y
    CLC
    ADC #KnightArrowYOffset
    STA RuntimeObjectY,X
    LDA a:RuntimeObjectState,Y
    BMI SpawnKnightArrowLeft
    LDA a:RuntimeObjectXLo,Y
    CLC
    ADC #KnightArrowRightXOffset
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    ADC #KnightArrowCoordinateCarry
    STA RuntimeObjectXHi,X
    LDA #KnightArrowDirectionRight
    STA RuntimeObjectState,X
    JMP ReturnFromKnightUpdate

SpawnKnightArrowLeft:
    LDA a:RuntimeObjectXLo,Y
    SEC
    SBC #KnightArrowLeftXOffset
    STA RuntimeObjectXLo,X
    LDA a:RuntimeObjectXHi,Y
    SBC #KnightArrowCoordinateBorrow
    STA RuntimeObjectXHi,X
    LDA #KnightArrowDirectionLeft
    STA RuntimeObjectState,X

ReturnFromKnightUpdate:
    RTS
