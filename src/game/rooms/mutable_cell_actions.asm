; Inventory-backed persistent mutable-cell actions
; CPU range $A5DD-$A66C
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
