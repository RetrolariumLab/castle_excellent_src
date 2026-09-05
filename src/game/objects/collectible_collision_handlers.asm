; Runtime collectible collision handlers
; CPU range $8C80-$8CF1
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CollectRuntimeType83:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType83Collectible
    RTS

ApplyRuntimeType83Collectible:
    INC RuntimeType83ScreenState
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA CollectibleHazardProtectionCountdown
    BNE SetRuntimeType83Protection
    JSR LoadAudioTrackSet1

SetRuntimeType83Protection:
    LDA #RuntimeType83ProtectionDuration
    STA CollectibleHazardProtectionCountdown
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectRuntimeType96:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType96Collectible
    RTS

ApplyRuntimeType96Collectible:
    LDA #RuntimeType96EffectSet
    STA RuntimeType96EffectLatch
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject

CollectRuntimeType98:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType98Collectible
    RTS

ApplyRuntimeType98Collectible:
    LDA #CollectibleScore20
    JSR AddPlayerScore
    LDA #CollectedObjectState6
    JMP TransformCollectedRuntimeObject

CollectRuntimeType99:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType99Collectible
    RTS

ApplyRuntimeType99Collectible:
    LDA #CollectibleScore40
    JSR AddPlayerScore
    LDA #CollectedObjectState7
    JMP TransformCollectedRuntimeObject

CollectRuntimeType9A:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType9ACollectible
    RTS

ApplyRuntimeType9ACollectible:
    LDA #CollectibleScore80
    JSR AddPlayerScore
    LDA #CollectedObjectState8
    JMP TransformCollectedRuntimeObject

CollectRuntimeType9B:
    JSR IsCurrentObjectNearPlayer
    BCC ApplyRuntimeType9BCollectible
    RTS

ApplyRuntimeType9BCollectible:
    LDA #CollectibleScore100
    JSR AddPlayerScore
    LDA #CollectedObjectState9
    JMP TransformCollectedRuntimeObject
