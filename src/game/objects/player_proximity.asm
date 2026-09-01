; Runtime-object proximity to the player
; CPU range $A8A9-$A8E2
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

IsCurrentObjectNearPlayer:
    LDX CurrentObjectOffset
    LDA RuntimeObjectY,X
    CLC
    ADC #ObjectPlayerProximityYOffset
    SEC
    SBC PlayerY
    BCS CompareObjectPlayerYDistance
    EOR #$FF
    ADC #$01

CompareObjectPlayerYDistance:
    CMP #ObjectPlayerProximityYLimit
    BCS ReturnObjectPlayerProximityResult
    LDA RuntimeObjectXLo,X
    SEC
    SBC PlayerXLo
    STA ObjectPlayerDeltaXLo
    LDA RuntimeObjectXHi,X
    SBC PlayerXHi
    STA ObjectPlayerDeltaXHi
    BCS CheckObjectPlayerXDistanceHigh
    LDA ObjectPlayerDeltaXLo
    EOR #$FF
    ADC #$01
    STA ObjectPlayerDeltaXLo
    LDA ObjectPlayerDeltaXHi
    EOR #$FF
    STA ObjectPlayerDeltaXHi

CheckObjectPlayerXDistanceHigh:
    BEQ CompareObjectPlayerXDistance
    SEC
    RTS

CompareObjectPlayerXDistance:
    LDA ObjectPlayerDeltaXLo
    CMP #ObjectPlayerProximityXLimit

ReturnObjectPlayerProximityResult:
    RTS
