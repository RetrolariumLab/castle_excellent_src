; Runtime inventory collectible collision handlers
; CPU range $8C12-$8C7A
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

CollectInventoryRuntimeType90:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $01
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType91:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType92:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $04
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType93:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $03
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType94:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $05
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore
    JMP FinalizeInventoryCollectible

CollectInventoryRuntimeType95:
    JSR IsCurrentObjectNearPlayer
    BCS ReturnFromInventoryCollectible
    INC InventoryCollectibleCounts + $02
    LDA #InventoryCollectibleScore
    JSR AddPlayerScore

FinalizeInventoryCollectible:
    JSR StartInventoryCollectibleSoundEffect
    LDA #CollectedObjectState5

TransformCollectedRuntimeObject:
    LDX CurrentObjectOffset
    STA RuntimeObjectState,X
    LDA #CollectedObjectRuntimeType
    STA RuntimeObjectRecords,X
    LDA #CollectedObjectLifetime
    STA RuntimeObjectByte5,X

ReturnFromInventoryCollectible:
    RTS
