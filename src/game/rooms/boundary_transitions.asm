; Player room-boundary transitions and edge clamping
; CPU range $867A-$8757
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

TransitionToRoomAbove:
    LDA #AboveRoomEntryPlayerY
    STA PlayerY
    STA BoundaryTransitionPlayerY
    LDA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerXLo
    AND #RoomBoundaryPlayerXAlignmentMask
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomAbove
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

TransitionToRoomBelow:
    LDA #BelowRoomEntryPlayerY
    STA PlayerY
    STA BoundaryTransitionPlayerY
    LDA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerXLo
    AND #RoomBoundaryPlayerXAlignmentMask
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomBelow
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

HandleLeftRoomBoundary:
    LDA CurrentRoomNumber
    JSR FindLeftmostCastleRoom
    BNE TransitionToRoomLeft
    LDA #<LeftRoomEdgePlayerX
    STA PlayerXLo
    STA PlayerXHi
    JMP UpdateHorizontalScroll

TransitionToRoomLeft:
    LDA #<RightRoomEdgePlayerX
    STA PlayerXLo
    STA BoundaryTransitionPlayerXLo
    LDA #>RightRoomEdgePlayerX
    STA PlayerXHi
    STA BoundaryTransitionPlayerXHi
    LDA PlayerY
    STA BoundaryTransitionPlayerY
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomLeft
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #RoomBoundaryEntranceProbeYOffset
    TAY
    LDA #>RightRoomEdgePlayerX
    LDX #<RightRoomEdgePlayerX
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS FinishLeftRoomTransition
    JSR RestoreMutableCellByOrdinal

FinishLeftRoomTransition:
    JMP FinishRoomTransition

HandleRightRoomBoundary:
    LDA CurrentRoomNumber
    JSR FindRightmostCastleRoom
    BNE TransitionToRoomRight
    LDA #>RightRoomEdgePlayerX
    STA PlayerXHi
    LDA #<RightRoomEdgePlayerX
    STA PlayerXLo
    JMP UpdateHorizontalScroll

TransitionToRoomRight:
    LDA #<LeftRoomEdgePlayerX
    STA PlayerXLo
    STA PlayerXHi
    STA BoundaryTransitionPlayerXLo
    STA BoundaryTransitionPlayerXHi
    LDA PlayerY
    STA BoundaryTransitionPlayerY
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomRight
    LDA #BoundaryTransitionScreenStateInactive
    STA BoundaryTransitionScreenState
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #RoomBoundaryEntranceProbeYOffset
    TAY
    LDA #>LeftRoomEdgePlayerX
    LDX #<LeftRoomEdgePlayerX
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS FinishRightRoomTransition
    JSR RestoreMutableCellByOrdinal

FinishRightRoomTransition:
    JMP FinishRoomTransition
