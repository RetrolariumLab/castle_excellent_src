; Player collision-result handler dispatch
; CPU range $9477-$949B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DispatchPlayerCollisionSample:
    ASL A
    TAX
    BCS SelectPlayerRuntimeCollisionHandler
    LDA PlayerRoomCellCollisionHandlerPointers,X
    STA PlayerCollisionHandlerPointerLo
    LDA PlayerRoomCellCollisionHandlerPointers + 1,X
    STA PlayerCollisionHandlerPointerHi
    JMP InvokePlayerCollisionHandler

SelectPlayerRuntimeCollisionHandler:
    LDA PlayerRuntimeCollisionHandlerPointers,X
    STA PlayerCollisionHandlerPointerLo
    LDA PlayerRuntimeCollisionHandlerPointers + 1,X
    STA PlayerCollisionHandlerPointerHi

InvokePlayerCollisionHandler:
    LDA #>(ReturnFromPlayerCollisionDispatch - 1)
    PHA
    LDA #<(ReturnFromPlayerCollisionDispatch - 1)
    PHA
    JMP (PlayerCollisionHandlerPointerLo)

ReturnFromPlayerCollisionDispatch:
    RTS
