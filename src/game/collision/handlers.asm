; Upward, horizontal, and shared collision handlers and the per-frame update
; Original CPU range $903F-$93F5

PlayerUpwardRoomCellCollisionHandlerPointers:
    .addr ReturnFromPlayerCollisionHandler  ; cell $00
    .addr ReturnFromPlayerCollisionHandler  ; cell $01
    .addr ReturnFromPlayerCollisionHandler  ; cell $02
    .addr ReturnFromPlayerCollisionHandler  ; cell $03
    .addr ReturnFromPlayerCollisionHandler  ; cell $04
    .addr ReturnFromPlayerCollisionHandler  ; cell $05
    .addr ReturnFromPlayerCollisionHandler  ; cell $06
    .addr ReturnFromPlayerCollisionHandler  ; cell $07
    .addr ReturnFromPlayerCollisionHandler  ; cell $08
    .addr ReturnFromPlayerCollisionHandler  ; cell $09
    .addr ReturnFromPlayerCollisionHandler  ; cell $0A
    .addr ReturnFromPlayerCollisionHandler  ; cell $0B
    .addr ReturnFromPlayerCollisionHandler  ; cell $0C
    .addr ReturnFromPlayerCollisionHandler  ; cell $0D
    .addr ReturnFromPlayerCollisionHandler  ; cell $0E
    .addr ReturnFromPlayerCollisionHandler  ; cell $0F
    .addr ReturnFromPlayerCollisionHandler  ; cell $10
    .addr ReturnFromPlayerCollisionHandler  ; cell $11
    .addr ReturnFromPlayerCollisionHandler  ; cell $12
    .addr ReturnFromPlayerCollisionHandler  ; cell $13
    .addr ReturnFromPlayerCollisionHandler  ; cell $14
    .addr ReturnFromPlayerCollisionHandler  ; cell $15
    .addr ReturnFromPlayerCollisionHandler  ; cell $16
    .addr ReturnFromPlayerCollisionHandler  ; cell $17
    .addr ReturnFromPlayerCollisionHandler  ; cell $18
    .addr ReturnFromPlayerCollisionHandler  ; cell $19
    .addr ReturnFromPlayerCollisionHandler  ; cell $1A
    .addr ReturnFromPlayerCollisionHandler  ; cell $1B
    .addr ReturnFromPlayerCollisionHandler  ; cell $1C
    .addr ReturnFromPlayerCollisionHandler  ; cell $1D
    .addr ReturnFromPlayerCollisionHandler  ; cell $1E
    .addr ReturnFromPlayerCollisionHandler  ; cell $1F
    .addr ReturnFromPlayerCollisionHandler  ; cell $20
    .addr ReturnFromPlayerCollisionHandler  ; cell $21
    .addr ReturnFromPlayerCollisionHandler  ; cell $22
    .addr ReturnFromPlayerCollisionHandler  ; cell $23
    .addr ReturnFromPlayerCollisionHandler  ; cell $24
    .addr ReturnFromPlayerCollisionHandler  ; cell $25
    .addr ReturnFromPlayerCollisionHandler  ; cell $26
    .addr ReturnFromPlayerCollisionHandler  ; cell $27
    .addr ReturnFromPlayerCollisionHandler  ; cell $28
    .addr ReturnFromPlayerCollisionHandler  ; cell $29
    .addr ReturnFromPlayerCollisionHandler  ; cell $2A
    .addr ReturnFromPlayerCollisionHandler  ; cell $2B
    .addr ReturnFromPlayerCollisionHandler  ; cell $2C
    .addr ReturnFromPlayerCollisionHandler  ; cell $2D
    .addr ReturnFromPlayerCollisionHandler  ; cell $2E
    .addr ReturnFromPlayerCollisionHandler  ; cell $2F
    .addr ReturnFromPlayerCollisionHandler  ; cell $30
    .addr ReturnFromPlayerCollisionHandler  ; cell $31
    .addr ReturnFromPlayerCollisionHandler  ; cell $32
    .addr ReturnFromPlayerCollisionHandler  ; cell $33
    .addr ReturnFromPlayerCollisionHandler  ; cell $34
    .addr ReturnFromPlayerCollisionHandler  ; cell $35
    .addr ReturnFromPlayerCollisionHandler  ; cell $36
    .addr ReturnFromPlayerCollisionHandler  ; cell $37
    .addr ReturnFromPlayerCollisionHandler  ; cell $38
    .addr ReturnFromPlayerCollisionHandler  ; cell $39
    .addr ReturnFromPlayerCollisionHandler  ; cell $3A
    .addr ReturnFromPlayerCollisionHandler  ; cell $3B
    .addr ReturnFromPlayerCollisionHandler  ; cell $3C
    .addr ReturnFromPlayerCollisionHandler  ; cell $3D
    .addr ReturnFromPlayerCollisionHandler  ; cell $3E
    .addr ReturnFromPlayerCollisionHandler  ; cell $3F
    .addr ReturnFromPlayerCollisionHandler  ; cell $40
    .addr ReturnFromPlayerCollisionHandler  ; cell $41
    .addr ReturnFromPlayerCollisionHandler  ; cell $42
    .addr ReturnFromPlayerCollisionHandler  ; cell $43
    .addr ReturnFromPlayerCollisionHandler  ; cell $44
    .addr ReturnFromPlayerCollisionHandler  ; cell $45
    .addr ReturnFromPlayerCollisionHandler  ; cell $46
    .addr ReturnFromPlayerCollisionHandler  ; cell $47
    .addr ReturnFromPlayerCollisionHandler  ; cell $48
    .addr ReturnFromPlayerCollisionHandler  ; cell $49
    .addr ReturnFromPlayerCollisionHandler  ; cell $4A
    .addr ReturnFromPlayerCollisionHandler  ; cell $4B
    .addr ReturnFromPlayerCollisionHandler  ; cell $4C
    .addr ReturnFromPlayerCollisionHandler  ; cell $4D
    .addr ReturnFromPlayerCollisionHandler  ; cell $4E
    .addr ReturnFromPlayerCollisionHandler  ; cell $4F
    .addr ReturnFromPlayerCollisionHandler  ; cell $50
    .addr ReturnFromPlayerCollisionHandler  ; cell $51
    .addr ReturnFromPlayerCollisionHandler  ; cell $52
    .addr ReturnFromPlayerCollisionHandler  ; cell $53
    .addr ReturnFromPlayerCollisionHandler  ; cell $54
    .addr ReturnFromPlayerCollisionHandler  ; cell $55
    .addr ReturnFromPlayerCollisionHandler  ; cell $56
    .addr ReturnFromPlayerCollisionHandler  ; cell $57
    .addr ReturnFromPlayerCollisionHandler  ; cell $58
    .addr ReturnFromPlayerCollisionHandler  ; cell $59
    .addr ReturnFromPlayerCollisionHandler  ; cell $5A
    .addr ReturnFromPlayerCollisionHandler  ; cell $5B
    .addr ReturnFromPlayerCollisionHandler  ; cell $5C
    .addr ReturnFromPlayerCollisionHandler  ; cell $5D
    .addr ReturnFromPlayerCollisionHandler  ; cell $5E
    .addr ReturnFromPlayerCollisionHandler  ; cell $5F
    .addr ReturnFromPlayerCollisionHandler  ; cell $60
    .addr ReturnFromPlayerCollisionHandler  ; cell $61
    .addr ReturnFromPlayerCollisionHandler  ; cell $62
    .addr ReturnFromPlayerCollisionHandler  ; cell $63

PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6:
    .addr ReturnFromPlayerCollisionHandler  ; $80
    .addr HandleFairyPlayerCollision  ; $81 Fairy
    .addr ReturnFromPlayerCollisionHandler  ; $82 Princess
    .addr CollectOxygenTank  ; $83 ItemOxygenTank
    .addr StartPlayerDeathTransition  ; $84 EnemyFighter
    .addr StartPlayerDeathTransition  ; $85 EnemyBishop
    .addr StartPlayerDeathTransition  ; $86 EnemyDevilFlower
    .addr StartPlayerDeathTransition  ; $87 EnemyKnight
    .addr StartPlayerDeathTransition  ; $88 EnemyWitch
    .addr StartPlayerDeathTransition  ; $89 EnemyFlame
    .addr ReturnFromPlayerCollisionHandler  ; $8A ObjectJar
    .addr ReturnFromPlayerCollisionHandler  ; $8B ObjectBrick
    .addr ReturnFromPlayerCollisionHandler  ; $8C ObjectBlock
    .addr ReturnFromPlayerCollisionHandler  ; $8D ObjectBarrel
    .addr ReturnFromPlayerCollisionHandler  ; $8E ObjectPulley
    .addr ReturnFromPlayerCollisionHandler  ; $8F ObjectCandle
    .addr ReturnFromPlayerCollisionHandler  ; $90 ItemDarkBlueKey
    .addr ReturnFromPlayerCollisionHandler  ; $91 ItemRedKey
    .addr ReturnFromPlayerCollisionHandler  ; $92 ItemPinkKey
    .addr ReturnFromPlayerCollisionHandler  ; $93 ItemGreenKey
    .addr ReturnFromPlayerCollisionHandler  ; $94 ItemBlueKey
    .addr ReturnFromPlayerCollisionHandler  ; $95 ItemYellowKey
    .addr CollectCastleMap  ; $96 ItemCastleMap
    .addr CollectPotion  ; $97 ItemPotion
    .addr CollectCross  ; $98 ItemCross
    .addr CollectRing  ; $99 ItemRing
    .addr CollectMoneyBag  ; $9A ItemMoneyBag
    .addr CollectRuntimeType9B  ; $9B
    .addr ReturnFromPlayerCollisionHandler  ; $9C
    .addr ReturnFromPlayerCollisionHandler  ; $9D
    .addr ReturnFromPlayerCollisionHandler  ; $9E
    .addr HandlePowerLightPlayerCollision  ; $9F ItemPowerLight
    .addr ReturnFromPlayerCollisionHandler  ; $A0 WitchSummon
    .addr ReturnFromPlayerCollisionHandler  ; $A1 ObjectLift
    .addr ReturnFromPlayerCollisionHandler  ; $A2 ObjectLiftWide
    .addr ReturnFromPlayerCollisionHandler  ; $A3 ObjectFloatingPlatform
    .addr ReturnFromPlayerCollisionHandler  ; $A4 ObjectDraggableLiftTop
    .addr ReturnFromPlayerCollisionHandler  ; $A5 ObjectDraggableLiftBottom
    .addr StartPlayerDeathTransition  ; $A6 ObjectKnightArrow

PlayerHorizontalRoomCellCollisionHandlerPointers:
    .addr ReturnFromPlayerCollisionHandler  ; cell $00
    .addr ReturnFromPlayerCollisionHandler  ; cell $01
    .addr ReturnFromPlayerCollisionHandler  ; cell $02
    .addr ReturnFromPlayerCollisionHandler  ; cell $03
    .addr ReturnFromPlayerCollisionHandler  ; cell $04
    .addr ReturnFromPlayerCollisionHandler  ; cell $05
    .addr ReturnFromPlayerCollisionHandler  ; cell $06
    .addr ReturnFromPlayerCollisionHandler  ; cell $07
    .addr ReturnFromPlayerCollisionHandler  ; cell $08
    .addr ReturnFromPlayerCollisionHandler  ; cell $09
    .addr ReturnFromPlayerCollisionHandler  ; cell $0A
    .addr ReturnFromPlayerCollisionHandler  ; cell $0B
    .addr ReturnFromPlayerCollisionHandler  ; cell $0C
    .addr ReturnFromPlayerCollisionHandler  ; cell $0D
    .addr ReturnFromPlayerCollisionHandler  ; cell $0E
    .addr ReturnFromPlayerCollisionHandler  ; cell $0F
    .addr ReturnFromPlayerCollisionHandler  ; cell $10
    .addr ReturnFromPlayerCollisionHandler  ; cell $11
    .addr ReturnFromPlayerCollisionHandler  ; cell $12
    .addr ReturnFromPlayerCollisionHandler  ; cell $13
    .addr ReturnFromPlayerCollisionHandler  ; cell $14
    .addr ReturnFromPlayerCollisionHandler  ; cell $15
    .addr ReturnFromPlayerCollisionHandler  ; cell $16
    .addr ReturnFromPlayerCollisionHandler  ; cell $17
    .addr ReturnFromPlayerCollisionHandler  ; cell $18
    .addr TryOpenMutableCell19  ; cell $19
    .addr TryOpenMutableCell19  ; cell $1A
    .addr ReturnFromPlayerCollisionHandler  ; cell $1B
    .addr TryOpenMutableCell1C  ; cell $1C
    .addr TryOpenMutableCell1C  ; cell $1D
    .addr ReturnFromPlayerCollisionHandler  ; cell $1E
    .addr TryOpenMutableCell1F  ; cell $1F
    .addr TryOpenMutableCell1F  ; cell $20
    .addr ReturnFromPlayerCollisionHandler  ; cell $21
    .addr TryOpenMutableCell22  ; cell $22
    .addr TryOpenMutableCell22  ; cell $23
    .addr ReturnFromPlayerCollisionHandler  ; cell $24
    .addr TryOpenMutableCell25  ; cell $25
    .addr TryOpenMutableCell25  ; cell $26
    .addr ReturnFromPlayerCollisionHandler  ; cell $27
    .addr ReturnFromPlayerCollisionHandler  ; cell $28
    .addr TryOpenMutableCell29  ; cell $29
    .addr TryOpenMutableCell29  ; cell $2A
    .addr ReturnFromPlayerCollisionHandler  ; cell $2B
    .addr ReturnFromPlayerCollisionHandler  ; cell $2C
    .addr ReturnFromPlayerCollisionHandler  ; cell $2D
    .addr ReturnFromPlayerCollisionHandler  ; cell $2E
    .addr ReturnFromPlayerCollisionHandler  ; cell $2F
    .addr ReturnFromPlayerCollisionHandler  ; cell $30
    .addr ReturnFromPlayerCollisionHandler  ; cell $31
    .addr ReturnFromPlayerCollisionHandler  ; cell $32
    .addr ReturnFromPlayerCollisionHandler  ; cell $33
    .addr ReturnFromPlayerCollisionHandler  ; cell $34
    .addr ReturnFromPlayerCollisionHandler  ; cell $35
    .addr ReturnFromPlayerCollisionHandler  ; cell $36
    .addr ReturnFromPlayerCollisionHandler  ; cell $37
    .addr ReturnFromPlayerCollisionHandler  ; cell $38
    .addr ReturnFromPlayerCollisionHandler  ; cell $39
    .addr ReturnFromPlayerCollisionHandler  ; cell $3A
    .addr ReturnFromPlayerCollisionHandler  ; cell $3B
    .addr ReturnFromPlayerCollisionHandler  ; cell $3C
    .addr ReturnFromPlayerCollisionHandler  ; cell $3D
    .addr ReturnFromPlayerCollisionHandler  ; cell $3E
    .addr ReturnFromPlayerCollisionHandler  ; cell $3F
    .addr ReturnFromPlayerCollisionHandler  ; cell $40
    .addr ReturnFromPlayerCollisionHandler  ; cell $41
    .addr ReturnFromPlayerCollisionHandler  ; cell $42
    .addr ReturnFromPlayerCollisionHandler  ; cell $43
    .addr ReturnFromPlayerCollisionHandler  ; cell $44
    .addr ReturnFromPlayerCollisionHandler  ; cell $45
    .addr ReturnFromPlayerCollisionHandler  ; cell $46
    .addr ReturnFromPlayerCollisionHandler  ; cell $47
    .addr ReturnFromPlayerCollisionHandler  ; cell $48
    .addr ReturnFromPlayerCollisionHandler  ; cell $49
    .addr ReturnFromPlayerCollisionHandler  ; cell $4A
    .addr ReturnFromPlayerCollisionHandler  ; cell $4B
    .addr ReturnFromPlayerCollisionHandler  ; cell $4C
    .addr ReturnFromPlayerCollisionHandler  ; cell $4D
    .addr ReturnFromPlayerCollisionHandler  ; cell $4E
    .addr ReturnFromPlayerCollisionHandler  ; cell $4F
    .addr ReturnFromPlayerCollisionHandler  ; cell $50
    .addr ReturnFromPlayerCollisionHandler  ; cell $51
    .addr ReturnFromPlayerCollisionHandler  ; cell $52
    .addr ReturnFromPlayerCollisionHandler  ; cell $53
    .addr ReturnFromPlayerCollisionHandler  ; cell $54
    .addr ReturnFromPlayerCollisionHandler  ; cell $55
    .addr ReturnFromPlayerCollisionHandler  ; cell $56
    .addr ReturnFromPlayerCollisionHandler  ; cell $57
    .addr ReturnFromPlayerCollisionHandler  ; cell $58
    .addr ReturnFromPlayerCollisionHandler  ; cell $59
    .addr ReturnFromPlayerCollisionHandler  ; cell $5A
    .addr ReturnFromPlayerCollisionHandler  ; cell $5B
    .addr ReturnFromPlayerCollisionHandler  ; cell $5C
    .addr ReturnFromPlayerCollisionHandler  ; cell $5D
    .addr ReturnFromPlayerCollisionHandler  ; cell $5E
    .addr ReturnFromPlayerCollisionHandler  ; cell $5F
    .addr ReturnFromPlayerCollisionHandler  ; cell $60
    .addr ReturnFromPlayerCollisionHandler  ; cell $61
    .addr ReturnFromPlayerCollisionHandler  ; cell $62
    .addr ReturnFromPlayerCollisionHandler  ; cell $63

PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6:
    .addr ReturnFromPlayerCollisionHandler  ; $80
    .addr HandleFairyPlayerCollision  ; $81 Fairy
    .addr ReturnFromPlayerCollisionHandler  ; $82 Princess
    .addr CollectOxygenTank  ; $83 ItemOxygenTank
    .addr StartPlayerDeathTransition  ; $84 EnemyFighter
    .addr StartPlayerDeathTransition  ; $85 EnemyBishop
    .addr StartPlayerDeathTransition  ; $86 EnemyDevilFlower
    .addr StartPlayerDeathTransition  ; $87 EnemyKnight
    .addr StartPlayerDeathTransition  ; $88 EnemyWitch
    .addr StartPlayerDeathTransition  ; $89 EnemyFlame
    .addr PushPlayerAndRuntimeObject  ; $8A ObjectJar
    .addr PushPlayerAndRuntimeObject  ; $8B ObjectBrick
    .addr PushPlayerAndRuntimeObject  ; $8C ObjectBlock
    .addr PushPlayerAndRuntimeObject  ; $8D ObjectBarrel
    .addr HandlePulleyHorizontalCollision  ; $8E ObjectPulley
    .addr PushPlayerAndRuntimeObject  ; $8F ObjectCandle
    .addr ReturnFromPlayerCollisionHandler  ; $90 ItemDarkBlueKey
    .addr ReturnFromPlayerCollisionHandler  ; $91 ItemRedKey
    .addr ReturnFromPlayerCollisionHandler  ; $92 ItemPinkKey
    .addr ReturnFromPlayerCollisionHandler  ; $93 ItemGreenKey
    .addr ReturnFromPlayerCollisionHandler  ; $94 ItemBlueKey
    .addr ReturnFromPlayerCollisionHandler  ; $95 ItemYellowKey
    .addr CollectCastleMap  ; $96 ItemCastleMap
    .addr CollectPotion  ; $97 ItemPotion
    .addr CollectCross  ; $98 ItemCross
    .addr CollectRing  ; $99 ItemRing
    .addr CollectMoneyBag  ; $9A ItemMoneyBag
    .addr CollectRuntimeType9B  ; $9B
    .addr ReturnFromPlayerCollisionHandler  ; $9C
    .addr ReturnFromPlayerCollisionHandler  ; $9D
    .addr ReturnFromPlayerCollisionHandler  ; $9E
    .addr HandlePowerLightPlayerCollision  ; $9F ItemPowerLight
    .addr ReturnFromPlayerCollisionHandler  ; $A0 WitchSummon
    .addr ReturnFromPlayerCollisionHandler  ; $A1 ObjectLift
    .addr ReturnFromPlayerCollisionHandler  ; $A2 ObjectLiftWide
    .addr ReturnFromPlayerCollisionHandler  ; $A3 ObjectFloatingPlatform
    .addr ReturnFromPlayerCollisionHandler  ; $A4 ObjectDraggableLiftTop
    .addr ReturnFromPlayerCollisionHandler  ; $A5 ObjectDraggableLiftBottom
    .addr StartPlayerDeathTransition  ; $A6 ObjectKnightArrow

ReturnFromPlayerCollisionHandler:
    RTS

PlayerRoomCellCollisionHandlerPointers:
    .addr StartPlayerDeathTransition  ; cell $00
    .addr StartPlayerDeathTransition  ; cell $01
    .addr StartPlayerDeathTransition  ; cell $02
    .addr StartPlayerDeathTransition  ; cell $03
    .addr StartPlayerDeathTransition  ; cell $04
    .addr StartPlayerDeathTransition  ; cell $05
    .addr ReturnFromPlayerCollisionHandler  ; cell $06
    .addr ReturnFromPlayerCollisionHandler  ; cell $07
    .addr ReturnFromPlayerCollisionHandler  ; cell $08
    .addr ReturnFromPlayerCollisionHandler  ; cell $09
    .addr ReturnFromPlayerCollisionHandler  ; cell $0A
    .addr ReturnFromPlayerCollisionHandler  ; cell $0B
    .addr ReturnFromPlayerCollisionHandler  ; cell $0C
    .addr ReturnFromPlayerCollisionHandler  ; cell $0D
    .addr StartPlayerDeathTransition  ; cell $0E
    .addr StartPlayerDeathTransition  ; cell $0F
    .addr StartPlayerDeathTransition  ; cell $10
    .addr StartPlayerDeathTransition  ; cell $11
    .addr ReturnFromPlayerCollisionHandler  ; cell $12
    .addr ReturnFromPlayerCollisionHandler  ; cell $13
    .addr ReturnFromPlayerCollisionHandler  ; cell $14
    .addr ReturnFromPlayerCollisionHandler  ; cell $15
    .addr ReturnFromPlayerCollisionHandler  ; cell $16
    .addr ReturnFromPlayerCollisionHandler  ; cell $17
    .addr ReturnFromPlayerCollisionHandler  ; cell $18
    .addr ReturnFromPlayerCollisionHandler  ; cell $19
    .addr ReturnFromPlayerCollisionHandler  ; cell $1A
    .addr ReturnFromPlayerCollisionHandler  ; cell $1B
    .addr ReturnFromPlayerCollisionHandler  ; cell $1C
    .addr ReturnFromPlayerCollisionHandler  ; cell $1D
    .addr ReturnFromPlayerCollisionHandler  ; cell $1E
    .addr ReturnFromPlayerCollisionHandler  ; cell $1F
    .addr ReturnFromPlayerCollisionHandler  ; cell $20
    .addr ReturnFromPlayerCollisionHandler  ; cell $21
    .addr ReturnFromPlayerCollisionHandler  ; cell $22
    .addr ReturnFromPlayerCollisionHandler  ; cell $23
    .addr ReturnFromPlayerCollisionHandler  ; cell $24
    .addr ReturnFromPlayerCollisionHandler  ; cell $25
    .addr ReturnFromPlayerCollisionHandler  ; cell $26
    .addr ReturnFromPlayerCollisionHandler  ; cell $27
    .addr ReturnFromPlayerCollisionHandler  ; cell $28
    .addr ReturnFromPlayerCollisionHandler  ; cell $29
    .addr ReturnFromPlayerCollisionHandler  ; cell $2A
    .addr ReturnFromPlayerCollisionHandler  ; cell $2B
    .addr ReturnFromPlayerCollisionHandler  ; cell $2C
    .addr ReturnFromPlayerCollisionHandler  ; cell $2D
    .addr ReturnFromPlayerCollisionHandler  ; cell $2E
; Spike cells: $2F/$30 wall spikes pointing right/left, $31/$32 floor spike
; tips/base, $33/$34 ceiling spike base/tips
    .addr StartPlayerDeathTransition  ; cell $2F
    .addr StartPlayerDeathTransition  ; cell $30
    .addr StartPlayerDeathTransition  ; cell $31
    .addr StartPlayerDeathTransition  ; cell $32
    .addr StartPlayerDeathTransition  ; cell $33
    .addr ReturnFromPlayerCollisionHandler  ; cell $34
    .addr StartPlayerDeathTransition  ; cell $35
    .addr StartPlayerDeathTransition  ; cell $36
    .addr StartPlayerDeathTransition  ; cell $37
    .addr StartPlayerDeathTransition  ; cell $38
    .addr StartPlayerDeathTransition  ; cell $39
    .addr StartPlayerDeathTransition  ; cell $3A
    .addr StartPlayerDeathTransition  ; cell $3B
    .addr StartPlayerDeathTransition  ; cell $3C
    .addr StartPlayerDeathTransition  ; cell $3D
    .addr StartPlayerDeathTransition  ; cell $3E
    .addr StartPlayerDeathTransition  ; cell $3F
    .addr StartPlayerDeathTransition  ; cell $40
    .addr ReturnFromPlayerCollisionHandler  ; cell $41
    .addr ReturnFromPlayerCollisionHandler  ; cell $42
    .addr ReturnFromPlayerCollisionHandler  ; cell $43
    .addr ReturnFromPlayerCollisionHandler  ; cell $44
    .addr HandleAnimatedPlayerHazard  ; cell $45
    .addr HandleAnimatedPlayerHazard  ; cell $46
    .addr HandleAnimatedPlayerHazard  ; cell $47
    .addr HandleAnimatedPlayerHazard  ; cell $48
    .addr ReturnFromPlayerCollisionHandler  ; cell $49
    .addr ReturnFromPlayerCollisionHandler  ; cell $4A
    .addr ReturnFromPlayerCollisionHandler  ; cell $4B
    .addr ReturnFromPlayerCollisionHandler  ; cell $4C
    .addr ReturnFromPlayerCollisionHandler  ; cell $4D
    .addr ReturnFromPlayerCollisionHandler  ; cell $4E
    .addr ReturnFromPlayerCollisionHandler  ; cell $4F
    .addr ReturnFromPlayerCollisionHandler  ; cell $50
    .addr ReturnFromPlayerCollisionHandler  ; cell $51
    .addr ReturnFromPlayerCollisionHandler  ; cell $52
    .addr ReturnFromPlayerCollisionHandler  ; cell $53
    .addr ReturnFromPlayerCollisionHandler  ; cell $54
    .addr ReturnFromPlayerCollisionHandler  ; cell $55
    .addr StartPlayerDeathTransition  ; cell $56
    .addr StartPlayerDeathTransition  ; cell $57
    .addr StartPlayerDeathTransition  ; cell $58
    .addr StartPlayerDeathTransition  ; cell $59
    .addr StartPlayerDeathTransition  ; cell $5A
    .addr StartPlayerDeathTransition  ; cell $5B
    .addr StartPlayerDeathTransition  ; cell $5C
    .addr StartPlayerDeathTransition  ; cell $5D
    .addr StartPlayerDeathTransition  ; cell $5E
    .addr StartPlayerDeathTransition  ; cell $5F
    .addr StartPlayerDeathTransition  ; cell $60
    .addr StartPlayerDeathTransition  ; cell $61
    .addr ReturnFromPlayerCollisionHandler  ; cell $62
    .addr ReturnFromPlayerCollisionHandler  ; cell $63

PlayerRuntimeCollisionHandlerPointers:
    .addr ReturnFromPlayerCollisionHandler  ; $80
    .addr HandleFairyPlayerCollision  ; $81 Fairy
    .addr HandlePrincessPlayerCollision  ; $82 Princess
    .addr CollectOxygenTank  ; $83 ItemOxygenTank
    .addr StartPlayerDeathTransition  ; $84 EnemyFighter
    .addr StartPlayerDeathTransition  ; $85 EnemyBishop
    .addr StartPlayerDeathTransition  ; $86 EnemyDevilFlower
    .addr StartPlayerDeathTransition  ; $87 EnemyKnight
    .addr StartPlayerDeathTransition  ; $88 EnemyWitch
    .addr StartPlayerDeathTransition  ; $89 EnemyFlame
    .addr StartPlayerDeathTransition  ; $8A ObjectJar
    .addr StartPlayerDeathTransition  ; $8B ObjectBrick
    .addr StartPlayerDeathTransition  ; $8C ObjectBlock
    .addr StartPlayerDeathTransition  ; $8D ObjectBarrel
    .addr StartPlayerDeathTransition  ; $8E ObjectPulley
    .addr StartPlayerDeathTransition  ; $8F ObjectCandle
    .addr CollectDarkBlueKey  ; $90 ItemDarkBlueKey
    .addr CollectRedKey  ; $91 ItemRedKey
    .addr CollectPinkKey  ; $92 ItemPinkKey
    .addr CollectGreenKey  ; $93 ItemGreenKey
    .addr CollectBlueKey  ; $94 ItemBlueKey
    .addr CollectYellowKey  ; $95 ItemYellowKey
    .addr CollectCastleMap  ; $96 ItemCastleMap
    .addr CollectPotion  ; $97 ItemPotion
    .addr CollectCross  ; $98 ItemCross
    .addr CollectRing  ; $99 ItemRing
    .addr CollectMoneyBag  ; $9A ItemMoneyBag
    .addr CollectRuntimeType9B  ; $9B
    .addr ReturnFromPlayerCollisionHandler  ; $9C
    .addr ReturnFromPlayerCollisionHandler  ; $9D
    .addr ReturnFromPlayerCollisionHandler  ; $9E
    .addr HandlePowerLightPlayerCollision  ; $9F ItemPowerLight
    .addr ReturnFromPlayerCollisionHandler  ; $A0 WitchSummon
    .addr StartPlayerDeathTransition  ; $A1 ObjectLift
    .addr StartPlayerDeathTransition  ; $A2 ObjectLiftWide
    .addr StartPlayerDeathTransition  ; $A3 ObjectFloatingPlatform
    .addr StartPlayerDeathTransition  ; $A4 ObjectDraggableLiftTop
    .addr StartPlayerDeathTransition  ; $A5 ObjectDraggableLiftBottom
    .addr StartPlayerDeathTransition  ; $A6 ObjectKnightArrow
    .addr ReturnFromPlayerCollisionHandler  ; $A7
    .addr ReturnFromPlayerCollisionHandler  ; $A8 EffectDefeat

UpdatePlayerCollisionState:
    LDA PlayerTransitionCountdown
    BEQ SamplePlayerCollisionPoints
    JMP AdvancePlayerTransitionCountdown

SamplePlayerCollisionPoints:
    LDY PlayerY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDY PlayerY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    JSR DispatchPlayerCollisionSample
    LDA PlayerCollisionHazardCellContact
    BEQ ReturnFromPlayerCollisionUpdate
    LDA PlayerCollisionHazardProtectionCountdown
    BNE ReturnFromPlayerCollisionUpdate
    JMP StartPlayerDeathTransition

ReturnFromPlayerCollisionUpdate:
    RTS
