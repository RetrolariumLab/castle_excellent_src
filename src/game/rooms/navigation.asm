; Ten-by-ten castle room navigation
; CPU range $A7DB-$A834
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

MoveToRoomAbove:
    LDA CurrentRoomNumber
    CMP #FirstRoomWithAboveNeighbor
    BCC ReturnFromVerticalRoomMove
    SBC #CastleRoomColumns
    STA CurrentRoomNumber

ReturnFromVerticalRoomMove:
    RTS

MoveToRoomBelow:
    LDA CurrentRoomNumber
    CMP #FirstBottomRowRoomNumber
    BCS ReturnFromRoomMoveDown
    ADC #CastleRoomColumns
    STA CurrentRoomNumber

ReturnFromRoomMoveDown:
    RTS

MoveToRoomRight:
    LDA CurrentRoomNumber
    JSR FindRightmostCastleRoom
    BEQ ReturnFromRoomMoveRight
    CLC
    ADC #AdjacentRoomNumberStep
    STA CurrentRoomNumber

ReturnFromRoomMoveRight:
    RTS

MoveToRoomLeft:
    LDA CurrentRoomNumber
    JSR FindLeftmostCastleRoom
    BEQ ReturnFromRoomMoveLeft
    SEC
    SBC #AdjacentRoomNumberStep
    STA CurrentRoomNumber

ReturnFromRoomMoveLeft:
    RTS

FindRightmostCastleRoom:
    LDX #(CastleRoomRows - 1)

ScanRightmostCastleRooms:
    CMP RightmostCastleRoomNumbers,X
    BEQ ReturnRoomEdgeSearch
    DEX
    BPL ScanRightmostCastleRooms

ReturnRoomEdgeSearch:
    RTS

FindLeftmostCastleRoom:
    LDX #(CastleRoomRows - 1)

ScanLeftmostCastleRooms:
    CMP LeftmostCastleRoomNumbers,X
    BEQ ReturnLeftRoomEdgeSearch
    DEX
    BPL ScanLeftmostCastleRooms

ReturnLeftRoomEdgeSearch:
    RTS

RightmostCastleRoomNumbers:
    .byte $0A, $14, $1E, $28, $32, $3C, $46, $50, $5A, $64

LeftmostCastleRoomNumbers:
    .byte $01, $0B, $15, $1F, $29, $33, $3D, $47, $51, $5B
