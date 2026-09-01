; Player protection countdowns and hazard-cell contact
; CPU range $A835-$A8A8
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdatePlayerProtectionAndHazardState:
    LDA PlayerInvulnerabilityCountdown
    BEQ TickHazardProtectionCountdown
    LDA RoomFrameCounter
    AND #PlayerProtectionTickMask
    BNE TickHazardProtectionCountdown
    DEC PlayerInvulnerabilityCountdown
    BNE TickHazardProtectionCountdown
    JSR SelectRoomAudio

TickHazardProtectionCountdown:
    LDA PlayerHazardProtectionCountdown
    BEQ UpdatePlayerHazardCellContact
    LDA RoomFrameCounter
    AND #PlayerProtectionTickMask
    BNE UpdatePlayerHazardCellContact
    DEC PlayerHazardProtectionCountdown
    BNE UpdatePlayerHazardCellContact
    JSR SelectRoomAudio

UpdatePlayerHazardCellContact:
    LDA PlayerOnHazardCell
    LDA PlayerY
    CLC
    ADC #PlayerHazardProbeYOffset
    TAY
    CPY #PlayerHazardProbeTopBoundary
    BCC UseNonHazardRoomCell
    CPY #PlayerHazardProbeBottomBoundary
    BCS UseNonHazardRoomCell
    LDA PlayerXLo
    CLC
    ADC #<PlayerHazardProbeXOffset
    TAX
    LDA PlayerXHi
    ADC #>PlayerHazardProbeXOffset
    BEQ SamplePlayerHazardRoomCell
    CMP #PlayerHazardProbeRightBoundaryHi
    BNE UseNonHazardRoomCell
    CPX #PlayerHazardProbeRightBoundaryLo
    BCC SamplePlayerHazardRoomCell

UseNonHazardRoomCell:
    LDA #PlayerHazardContactInactive
    JMP ClassifyPlayerHazardRoomCell

SamplePlayerHazardRoomCell:
    PHA
    TYA
    SEC
    SBC #PlayerHazardProbeRoomYOffset
    TAY
    PLA
    JSR PrepareRoomCellSampleAddress
    LDY HazardCellColumnOffset
    LDA (HazardCellRowPointerLo),Y

ClassifyPlayerHazardRoomCell:
    LDX #PlayerHazardContactInactive
    CMP #HazardRoomCell
    BNE CheckRestoredHazardRoomCellTop
    LDX #PlayerHazardContactActive

CheckRestoredHazardRoomCellTop:
    CMP #RestoredHazardRoomCellTop
    BNE CheckRestoredHazardRoomCellBottom
    LDX #PlayerHazardContactActive

CheckRestoredHazardRoomCellBottom:
    CMP #RestoredHazardRoomCellBottom
    BNE StorePlayerHazardCellContact
    LDX #PlayerHazardContactActive

StorePlayerHazardCellContact:
    STX PlayerOnHazardCell
    RTS
