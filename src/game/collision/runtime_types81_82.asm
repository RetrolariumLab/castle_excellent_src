; Runtime types $81 and $82 player collision handlers
; CPU range $8D57-$8DAA
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

HandleRuntimeType82PlayerCollision:
    LDA GameOverActive
    BNE ReturnFromRuntimeType81Or82Collision

CheckRuntimeType82PlayerProximity:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromRuntimeType81Or82Collision
    JSR LoadAudioTrackSet4

WaitForRuntimeType82Audio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForRuntimeType82Audio

ExitCollisionDispatchForRuntimeType82:
    PLA
    PLA
    JMP RunType82CompletionSequence

ReturnFromRuntimeType81Or82Collision:
    RTS

HandleRuntimeType81PlayerCollision:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromRuntimeType81Or82Collision
    JSR LoadAudioTrackSet7

WaitForRuntimeType81Audio:
    LDA AudioStreamPointerLo
    ORA AudioStreamPointerHi
    BNE WaitForRuntimeType81Audio

TransformRuntimeType81Object:
    LDX CurrentObjectOffset
    LDA #RuntimeType81ReplacementType
    STA RuntimeObjectRecords,X
    LDA RuntimeObjectXLo,X
    SEC
    SBC #RuntimeType81HorizontalShift
    STA RuntimeObjectXLo,X
    BCS CheckRuntimeType81CloneRoom
    DEC RuntimeObjectXHi,X

CheckRuntimeType81CloneRoom:
    LDA CurrentRoomNumber
    CMP #RuntimeType81CloneRoom
    BNE ReturnFromRuntimeType81Collision

SpawnRuntimeType81Clone:
    LDA #RuntimeType81ReplacementType
    STA RuntimeType81CloneType
    LDA RuntimeObjectXLo,X
    SEC
    SBC #RuntimeType81HorizontalShift
    STA RuntimeType81CloneXLo
    LDA RuntimeObjectXHi,X
    SBC #$00
    STA RuntimeType81CloneXHi
    LDA RuntimeObjectY,X
    STA RuntimeType81CloneY

ReturnFromRuntimeType81Collision:
    RTS
