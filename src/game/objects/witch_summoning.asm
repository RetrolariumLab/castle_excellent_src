; Witch patrol, summon-space probes, and transient enemy creation
; CPU range $9ECB-$9F73
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdateWitch:
    JSR UpdateWalkingEnemyPhysics
    LDA RoomFrameCounter
    CMP #WitchSummonFramePhase
    BNE ReturnFromEnemyMovementHelper

PrepareWitchSummon:
    LDX CurrentRuntimeObjectOffset
    LDA RuntimeObjectState,X
    BMI PrepareWitchSummonLeft
    LDA RuntimeObjectXLo,X
    CLC
    ADC #WitchSummonHorizontalOffset
    STA WitchSummonXLo
    LDA RuntimeObjectXHi,X
    ADC #WitchSummonCoordinateCarry
    STA WitchSummonXHi
    JMP ValidateWitchSummonPosition

PrepareWitchSummonLeft:
    LDA RuntimeObjectXLo,X
    SEC
    SBC #WitchSummonHorizontalOffset
    STA WitchSummonXLo
    LDA RuntimeObjectXHi,X
    SBC #WitchSummonCoordinateBorrow
    STA WitchSummonXHi

ValidateWitchSummonPosition:
    LDA WitchSummonXLo
    CMP #WitchSummonRightBoundaryLo
    LDA WitchSummonXHi
    SBC #WitchSummonRightBoundaryHi
    BCS ReturnFromWitchUpdate

ProbeWitchSummonTopLeft:
    LDY RuntimeObjectY,X
    STY WitchSummonY
    LDX WitchSummonXLo
    LDA WitchSummonXHi
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonTopRight:
    LDY WitchSummonY
    LDA WitchSummonXLo
    CLC
    ADC #WitchSummonExtent
    TAX
    LDA WitchSummonXHi
    ADC #WitchSummonCoordinateCarry
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonBottomLeft:
    LDA WitchSummonY
    CLC
    ADC #WitchSummonExtent
    TAY
    LDX WitchSummonXLo
    LDA WitchSummonXHi
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

ProbeWitchSummonBottomRight:
    LDA WitchSummonY
    CLC
    ADC #WitchSummonExtent
    TAY
    LDA WitchSummonXLo
    CLC
    ADC #WitchSummonExtent
    TAX
    LDA WitchSummonXHi
    ADC #WitchSummonCoordinateCarry
    JSR SampleCollisionAtPixel
    BCS ReturnFromWitchUpdate

FindWitchSummonSlot:
    LDY CurrentRoomNumber
    LDX RoomObjectCounts - 1,Y
    LDA RuntimeObjectOffsetByCount,X
    TAX

ScanWitchSummonSlot:
    LDA RuntimeObjectRecords,X
    BEQ CreateWitchSummon
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC ScanWitchSummonSlot
    RTS

CreateWitchSummon:
    LDA #WitchSummonRuntimeType
    STA RuntimeObjectRecords,X
    LDA WitchSummonXLo
    STA RuntimeObjectXLo,X
    LDA WitchSummonXHi
    STA RuntimeObjectXHi,X
    LDA WitchSummonY
    STA RuntimeObjectY,X
    LDA #WitchSummonInitialCountdown
    STA RuntimeObjectState,X
    LDA #WitchSummonInitialByte5
    STA RuntimeObjectAux,X

ReturnFromWitchUpdate:
    RTS
