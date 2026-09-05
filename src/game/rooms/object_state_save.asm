; Current-room runtime object-state bitmap save
; CPU range $8758-$8784
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SaveCurrentRoomObjectState:
    LDX #$00

EncodeNextRoomObjectStateBit:
    SEC
    LDA RuntimeObjectRecords,X
    BPL RotateRoomObjectStateBit
    CMP #RuntimeObjectPersistentTypeEnd

RotateRoomObjectStateBit:
    ROR SavedRoomObjectStateBits + $02
    ROR SavedRoomObjectStateBits + $01
    ROR SavedRoomObjectStateBits
    TXA
    CLC
    ADC #RuntimeObjectRecordSize
    TAX
    CPX #RuntimeObjectRecordBytes
    BCC EncodeNextRoomObjectStateBit
    LDA CurrentRoomNumber
    STA CurrentRoomState
    LDA SavedRoomObjectStateBits
    STA CurrentRoomObjectState
    LDA SavedRoomObjectStateBits + $01
    STA CurrentRoomObjectState + $01
    LDA SavedRoomObjectStateBits + $02
    STA CurrentRoomObjectState + $02
    RTS
