; Runtime type $97 collectible collision handler
; CPU range $8CF2-$8D03
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CollectRuntimeType97:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType97Collectible
    RTS

ApplyRuntimeType97Collectible:
    LDA #CollectibleScore100
    JSR AddPlayerScore
    INC PlayerLives
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject
