; Mutable room cell coordinates, actions, and restoration
; Original CPU range $A58A-$A7DA

ConvertPixelPositionToTileCoordinates:
    LSR A
    TXA
    ROR A
    LSR A
    LSR A
    TAX
    TYA
    LSR A
    LSR A
    LSR A
    TAY
    RTS

UnreferencedTileToPixelConversionBytes:
    .byte $98, $0A, $0A, $0A, $A8, $8A, $0A, $0A, $0A, $AA, $2A, $29, $01, $60

GetRoomCellPointer:
    STY RoomCellPointerLo
    LDA #$00
    STA RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    TYA
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    BCC AddRoomCellBufferBase
    INC RoomCellPointerHi

AddRoomCellBufferBase:
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    ASL RoomCellPointerLo
    ROL RoomCellPointerHi
    LDA #<RoomCells
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    LDA #>RoomCells
    ADC RoomCellPointerHi
    STA RoomCellPointerHi
    TXA
    LSR A
    CLC
    ADC RoomCellPointerLo
    STA RoomCellPointerLo
    BCC ReturnRoomCellPointer
    INC RoomCellPointerHi

ReturnRoomCellPointer:
    RTS

TryOpenMutableCell19:
    LDA MutableCellActionInventoryCounts + $04
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts + $04
    JMP OpenPersistentMutableCell

TryOpenMutableCell1C:
    LDA MutableCellActionInventoryCounts + $03
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts + $03
    JMP OpenPersistentMutableCell

TryOpenMutableCell1F:
    LDA MutableCellActionInventoryCounts + $05
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts + $05
    JMP OpenPersistentMutableCell

TryOpenMutableCell22:
    LDA MutableCellActionInventoryCounts + $02
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts + $02
    JMP OpenPersistentMutableCell

TryOpenMutableCell25:
    LDA MutableCellActionInventoryCounts
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts
    JMP OpenPersistentMutableCell

TryOpenMutableCell29:
    LDA MutableCellActionInventoryCounts + $01
    JSR RequireMutableCellActionReady
    DEC MutableCellActionInventoryCounts + $01

OpenPersistentMutableCell:
    LDA MutableCellActionProbeY
    SEC
    SBC #MutableCellActionProbeYOffset
    STA MutableCellActionProbeY
    TAY
    LDX MutableCellActionProbeXLo
    LDA MutableCellActionProbeXHi
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    JSR RestoreMutableCellByOrdinal
    LDA MutableCellActionDirection
    BMI CheckLeftMutableCellBoundary
    LDA PlayerXLo
    CMP #MutableCellActionRightBoundaryLo
    LDA PlayerXHi
    SBC #MutableCellActionRightBoundaryHi
    BCC PlayMutableCellOpenSound
    BCS SetMutableCellActionDelay

CheckLeftMutableCellBoundary:
    LDA PlayerXLo
    CMP #MutableCellActionLeftBoundaryLo
    LDA PlayerXHi
    SBC #MutableCellActionLeftBoundaryHi
    BCS PlayMutableCellOpenSound

SetMutableCellActionDelay:
    LDA #MutableCellActionDelayFrames
    STA MutableCellActionMovementDelay

PlayMutableCellOpenSound:
    JSR StartMutableCellOpenSoundEffect
    RTS

GetActivePlayerMotionState:
    LDA MutableCellActionMotionState
    CMP #PlayerMotionInactiveThreshold
    BCC ReturnActivePlayerMotionState
    LDA #PlayerMotionInactive

ReturnActivePlayerMotionState:
    ORA #PlayerMotionInactive
    RTS

RequireMutableCellActionReady:
    BEQ AbortMutableCellAction
    JSR GetActivePlayerMotionState
    ORA MutableCellActionMotionPhase
    BEQ CheckMutableCellActionAlignment

AbortMutableCellAction:
    PLA
    PLA
    RTS

CheckMutableCellActionAlignment:
    LDA PlayerY
    AND #MutableCellActionAlignmentMask
    CMP #MutableCellActionAlignedRemainder
    BNE AbortMutableCellAction
    RTS

FindMutableCellOrdinalAtPosition:
    STX MutableCellTileColumn
    STY MutableCellTileRow
    JSR GetRoomCellPointer
    LDY #$00
    LDA (RoomCellPointerLo),Y
    CMP #$55
    BEQ UseMutableCellAbove
    CMP #$63
    BEQ UseMutableCellAbove
    JSR IsPersistentMutableRightCell
    BNE CheckMutableCellAnchor

UseMutableCellAbove:
    DEC MutableCellTileRow
    LDX MutableCellTileColumn
    LDY MutableCellTileRow
    JSR GetRoomCellPointer
    LDY #$00
    LDA (RoomCellPointerLo),Y

CheckMutableCellAnchor:
    CMP #$54
    BEQ CountMutableCellOrdinal
    CMP #$62
    BEQ CountMutableCellOrdinal
    JSR IsPersistentMutableCell
    BEQ CountMutableCellOrdinal
    SEC
    RTS

CountMutableCellOrdinal:
    LDX #$01
    LDY #$00

ScanPreviousMutableCell:
    LDA RoomCellPointerLo
    BNE MoveToPreviousRoomCell
    LDA RoomCellPointerHi
    CMP #$04
    BEQ ReturnMutableCellOrdinal

MoveToPreviousRoomCell:
    LDA RoomCellPointerLo
    BNE ReadPreviousRoomCell
    DEC RoomCellPointerHi

ReadPreviousRoomCell:
    DEC RoomCellPointerLo
    LDY #$00
    LDA (RoomCellPointerLo),Y
    CMP #$54
    BEQ CountPreviousMutableCell
    JSR IsPersistentMutableCell
    BNE ScanPreviousMutableCell

CountPreviousMutableCell:
    INX
    JMP ScanPreviousMutableCell

ReturnMutableCellOrdinal:
    CLC
    RTS

ClassifyCollisionCellPairIndex:
    CPX #CollisionCellPairIndexFirst
    BCC ReturnOrdinaryCollisionCellPair
    CPX #CollisionCellPairIndexEnd
    BCS ReturnOrdinaryCollisionCellPair
    LDY #CollisionCellPairMatched
    RTS

ReturnOrdinaryCollisionCellPair:
    LDY #CollisionCellPairNotMatched
    RTS

IsPersistentMutableCell:
    CMP #$19
    BCC ReturnMutableCellPredicate
    BEQ ReturnMutableCellPredicate
    CMP #$29
    BCS ReturnMutableCellPredicate
    CMP #$1C
    BEQ ReturnMutableCellPredicate
    CMP #$1F
    BEQ ReturnMutableCellPredicate
    CMP #$22
    BEQ ReturnMutableCellPredicate
    CMP #$25
    RTS

IsPersistentMutableRightCell:
    CMP #$1A
    BCC ReturnMutableCellPredicate
    BEQ ReturnMutableCellPredicate
    CMP #$2A
    BCS ReturnMutableCellPredicate
    CMP #$1D
    BEQ ReturnMutableCellPredicate
    CMP #$20
    BEQ ReturnMutableCellPredicate
    CMP #$23
    BEQ ReturnMutableCellPredicate
    CMP #$26

ReturnMutableCellPredicate:
    RTS

RestoreMutableCellByOrdinal:
    LDA #>RoomCells
    STA MutableCellRestorePointerHi
    LDA #<RoomCells
    STA MutableCellRestorePointerLo
    STX RestoredMutableCellOrdinal

ScanNextMutableCell:
    LDY #$00
    LDA (MutableCellRestorePointerLo),Y
    CMP #$54
    BEQ SelectMutableCellOrdinal
    JSR IsPersistentMutableCell
    BEQ SelectMutableCellOrdinal
    JMP AdvanceMutableCellScan

SelectMutableCellOrdinal:
    DEX
    BEQ InspectMutableCellNeighbors
    JMP AdvanceMutableCellScan

InspectMutableCellNeighbors:
    LDA MutableCellRestorePointerLo
    BNE ReadMutableCellLeftNeighbor
    DEC MutableCellRestorePointerHi

ReadMutableCellLeftNeighbor:
    DEC MutableCellRestorePointerLo
    LDY #$00
    LDA (MutableCellRestorePointerLo),Y
    CMP #$16
    BEQ RestoreAlternateMutableCell
    LDY #$02
    LDA (MutableCellRestorePointerLo),Y
    CMP #$16
    BNE RestoreStandardMutableCell

RestoreAlternateMutableCell:
    INC MutableCellRestorePointerLo
    BNE WriteAlternateMutableCell
    INC MutableCellRestorePointerHi

WriteAlternateMutableCell:
    LDY #$00
    LDA #$62
    STA (MutableCellRestorePointerLo),Y
    LDY #RoomWidth
    LDA #$63
    STA (MutableCellRestorePointerLo),Y
    JMP PersistRestoredMutableCell

RestoreStandardMutableCell:
    INC MutableCellRestorePointerLo
    BNE WriteStandardMutableCell
    INC MutableCellRestorePointerHi

WriteStandardMutableCell:
    LDY #$00
    LDA #$54
    STA (MutableCellRestorePointerLo),Y
    LDA #$55
    LDY #RoomWidth
    STA (MutableCellRestorePointerLo),Y

PersistRestoredMutableCell:
    LDA MutableCellRestorePointerLo
    STA RestoredMutableCellAddressLo
    LDA MutableCellRestorePointerHi
    STA RestoredMutableCellAddressHi
    JSR RequestRoomCellRowUpdates
    DEC RestoredMutableCellOrdinal
    LDA RestoredMutableCellOrdinal
    AND #$07
    TAX
    LDA MutableCellStateBitMasks,X
    PHA
    LDA RestoredMutableCellOrdinal
    LSR A
    LSR A
    LSR A
    TAX
    PLA
    ORA CurrentRoomMutableCellState,X
    STA CurrentRoomMutableCellState,X
    LDA MutableCellRestorePointerHi
    AND #$01
    STA MutableCellRestorePointerHi
    LDY #$07

ComputeRestoredMutableCellRow:
    LDA MutableCellRestorePointerLo
    CMP #RoomWidth
    LDA MutableCellRestorePointerHi
    SBC #$00
    BCC RequestRestoredCellAttributes
    LDA MutableCellRestorePointerLo
    SBC #RoomWidth
    STA MutableCellRestorePointerLo
    INY
    BCS ComputeRestoredMutableCellRow
    DEC MutableCellRestorePointerHi
    JMP ComputeRestoredMutableCellRow

RequestRestoredCellAttributes:
    LDA MutableCellRestorePointerLo
    ASL A
    CLC
    ADC #$04
    TAX
    JSR GetRoomAttributeMaskAndOffset
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributeScratch,X
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

AdvanceMutableCellScan:
    INC MutableCellRestorePointerLo
    BNE CheckMutableCellScanEnd
    INC MutableCellRestorePointerHi

CheckMutableCellScanEnd:
    LDA MutableCellRestorePointerLo
    CMP #<RoomMutableCellPersistentState
    LDA MutableCellRestorePointerHi
    SBC #>RoomMutableCellPersistentState
    BCS ReturnMutableCellNotFound
    JMP ScanNextMutableCell

ReturnMutableCellNotFound:
    RTS
