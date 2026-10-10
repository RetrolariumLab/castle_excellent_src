; Runtime object types, byte zero of each six-byte record at RuntimeObjectRecords
; Names follow the community wiki; per-type handler, collision, and sprite
; tables are indexed by type minus $80
; Enemy* types $84-$89 are the dagger's target range, Item* types are
; collected on touch, and Object* types are scenery the player can push or ride

RuntimeTypeEmpty = $00
RuntimeTypeFairy = $81
RuntimeTypePrincess = $82
; Grants temporary protection from water
RuntimeTypeItemOxygenTank = $83
RuntimeTypeEnemyFighter = $84
RuntimeTypeEnemyBishop = $85
; Grows out of a cocoon; its vertical hit area follows that animation
RuntimeTypeEnemyDevilFlower = $86
RuntimeTypeEnemyKnight = $87
RuntimeTypeEnemyWitch = $88
RuntimeTypeEnemyFlame = $89
RuntimeTypeObjectJar = $8A
RuntimeTypeObjectBrick = $8B
RuntimeTypeObjectBlock = $8C
RuntimeTypeObjectBarrel = $8D
; Pushing it left or right moves the draggable lift
RuntimeTypeObjectPulley = $8E
RuntimeTypeObjectCandle = $8F
RuntimeTypeItemDarkBlueKey = $90
RuntimeTypeItemRedKey = $91
RuntimeTypeItemPinkKey = $92
RuntimeTypeItemGreenKey = $93
RuntimeTypeItemBlueKey = $94
RuntimeTypeItemYellowKey = $95
; Makes the Select castle map available
RuntimeTypeItemCastleMap = $96
; Grants one extra life
RuntimeTypeItemPotion = $97
RuntimeTypeItemCross = $98
RuntimeTypeItemRing = $99
RuntimeTypeItemMoneyBag = $9A
; Grants temporary invulnerability
RuntimeTypeItemPowerLight = $9F
; Transient record that turns into a Fighter, Bishop, or Knight
RuntimeTypeWitchSummon = $A0
RuntimeTypeObjectLift = $A1
RuntimeTypeObjectLiftWide = $A2
RuntimeTypeObjectFloatingPlatform = $A3
; Upper and lower halves of the lift moved by the pulley
RuntimeTypeObjectDraggableLiftTop = $A4
RuntimeTypeObjectDraggableLiftBottom = $A5
RuntimeTypeObjectKnightArrow = $A6
; Burst left by a defeated, crushed, or destroyed object
RuntimeTypeEffectDefeat = $A8
; Rising remnant of a collected item
RuntimeTypeEffectCollectedItem = $A9

RuntimeTypeEnemyFirst = RuntimeTypeEnemyFighter
RuntimeTypeEnemyLast = RuntimeTypeEnemyFlame
RuntimeTypeKeyFirst = RuntimeTypeItemDarkBlueKey
RuntimeTypeKeyLast = RuntimeTypeItemYellowKey
