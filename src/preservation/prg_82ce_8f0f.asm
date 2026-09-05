; Preservation PRG after the main loop
; CPU range $82CE-$8757
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

UpdatePlayerInputAndMovement:
    LDA PlayerTransitionCountdown
    BEQ Label_82D4
    RTS

Label_82D4:
    LDA PlayerY
    BNE Label_82DB
    JMP Label_867A

Label_82DB:
    JSR GetActivePlayerMotionState
    AND #$03
    BNE Label_82FA
    LDA Controller1Buttons
    AND #$01
    BNE Label_82FA
    STA $3C
    LDA Pulse1SoundEffectRequest
    CMP #$01
    BNE Label_82FA
    LDA #$0E
    STA APU_STATUS
    LDA #$00
    STA Pulse1SoundEffectRequest

Label_82FA:
    LDA Controller1Buttons
    AND #$02
    BNE Label_8309
    STA a:$0779
    STA a:$077A
    BEQ Label_8320

Label_8309:
    LDA a:$077A
    BNE Label_8318
    LDA #$0A
    STA a:$0779
    STA a:$077A
    BNE Label_8320

Label_8318:
    LDA a:$0779
    BEQ Label_8320
    DEC a:$0779

Label_8320:
    LDA $3C
    CMP #$21
    BCC Label_8331
    LDA PlayerXLo
    AND #$07
    BNE Label_8331
    DEC $3C
    JSR StartPulse1SoundEffect1

Label_8331:
    JSR GetActivePlayerMotionState
    BNE Label_8339
    JMP Label_83A4

Label_8339:
    DEC $3C
    BNE Label_8341
    LDA #$FF
    STA $3E

Label_8341:
    LDA $3C
    CMP #$10
    BCS Label_834A
    JMP Label_8478

Label_834A:
    LDY PlayerY
    DEY
    DEY
    STY $1A
    CPY #$10
    BCS Label_8357
    JMP Label_8478

Label_8357:
    JSR GetPlayerXPlus7
    LDY $1A
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_837D
    LDA PlayerXHi
    LDX PlayerXLo
    LDY $1A
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_837D
    JSR GetPlayerXPlus15
    LDY $1A
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_837D
    DEC PlayerY
    DEC PlayerY
    JMP Label_8478

Label_837D:
    ASL A
    TAX
    BCS Label_838E
    LDA PlayerUpwardRoomCellCollisionHandlerPointers,X
    STA $31
    LDA PlayerUpwardRoomCellCollisionHandlerPointers + 1,X
    STA $32
    JMP Label_8398

Label_838E:
    LDA PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA $31
    LDA PlayerUpwardRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA $32

Label_8398:
    LDA #$83
    PHA
    LDA #$A0
    PHA
    JMP ($0031)
    JMP Label_8478

Label_83A4:
    LDA #$11
    STA $1F

Label_83A8:
    LDA #$00
    STA $1E
    STA $2F
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    JSR GetPlayerXPlus7
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_83C5
    STA $30
    JSR ClassifyAnimatedCollisionCell
    BCS Label_840F
    INC $1E

Label_83C5:
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    LDX PlayerXLo
    LDA PlayerXHi
    JSR SamplePlayerCollisionAtScreenPixel
    BCC Label_83DD
    STA $2F
    JSR ClassifyAnimatedCollisionCell
    BCS Label_840F
    INC $1E

Label_83DD:
    LDA PlayerY
    CLC
    ADC $1F
    TAY
    JSR GetPlayerXPlus15
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_840F
    LDA $1E
    BEQ Label_83F8
    LDA $2F
    BNE Label_83F5
    LDA $30

Label_83F5:
    JMP Label_840F

Label_83F8:
    LDA #$FF
    STA $3E
    LDA $1F
    CMP #$11
    BNE Label_8404
    INC PlayerY

Label_8404:
    INC PlayerY
    LDA PlayerY
    CMP #$A0
    BCC Label_8478
    JMP Label_86A0

Label_840F:
    LDX #$10
    CPX $1F
    BEQ Label_841A
    STX $1F
    JMP Label_83A8

Label_841A:
    ASL A
    TAX
    BCS Label_842B
    LDA PlayerDownwardRoomCellCollisionHandlerPointers,X
    STA $31
    LDA PlayerDownwardRoomCellCollisionHandlerPointers + 1,X
    STA $32
    JMP Label_8435

Label_842B:
    LDA PlayerDownwardRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA $31
    LDA PlayerDownwardRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA $32

Label_8435:
    LDA #$84
    PHA
    LDA #$3D
    PHA
    JMP ($0031)
    LDA $3C
    CMP #$21
    BCS Label_846B
    LDA Controller1Buttons
    AND #$01
    BEQ Label_847B
    LDA PlayerXLo
    AND #$07
    BNE Label_8467
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_8467
    LDA a:$07CA
    BMI Label_8478
    INC a:$07CA
    JMP Label_8478

Label_8467:
    LDA #$21
    STA $3C

Label_846B:
    LDA PlayerXLo
    AND #$07
    BNE Label_8478
    LDA #$20
    STA $3C
    JSR StartPulse1SoundEffect1

Label_8478:
    JMP Label_8490

Label_847B:
    LDA Controller1Buttons
    AND #$C0
    BNE Label_8490
    LDA PlayerXLo
    AND #$07
    BNE Label_8490
    LDA #$00
    STA a:$07C9
    STA a:$07CA

Label_8490:
    LDA a:$0779
    BEQ Label_849F
    JSR GetActivePlayerMotionState
    ORA $3E
    BNE Label_849F
    JMP Label_85CA

Label_849F:
    LDA $3F
    BEQ Label_84A8
    DEC $3F
    JMP Label_8512

Label_84A8:
    LDA a:$0774
    PHP
    LDA #$00
    STA a:$0774
    PLP
    BNE Label_84C8
    LDA $3B
    BEQ Label_84D9
    LDA PlayerXLo
    AND #$07
    BNE Label_8512
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    BNE Label_84D9

Label_84C8:
    LDA #$02
    STA a:$07C9
    STA a:$07CA
    LDA PlayerXLo
    AND #$07
    BEQ Label_84D9
    JMP Label_85CA

Label_84D9:
    LDA #$00
    STA $3B
    LDA Controller1Buttons
    AND #$C0
    BNE Label_84E7
    JMP Label_85CA

Label_84E7:
    LDA a:$07C9
    CLC
    ADC a:$07CA
    CMP #$02
    BCS Label_84FD
    LDA a:$07C9
    BMI Label_84FA
    INC a:$07C9

Label_84FA:
    JMP Label_85CA

Label_84FD:
    LDA Controller1Buttons
    AND #$C0
    BEQ Label_8512
    CMP #$C0
    BEQ Label_8512
    LDX #$7F
    CMP #$40
    BNE Label_8510
    LDX #$FF

Label_8510:
    STX $3B

Label_8512:
    LDA $3B
    BNE Label_8519
    JMP Label_85CA

Label_8519:
    BMI Label_8538
    LDA PlayerXLo
    CLC
    ADC #$11
    STA $21
    LDA PlayerXHi
    ADC #$00
    STA $22
    LDA PlayerXLo
    CLC
    ADC #$02
    STA $23
    LDA PlayerXHi
    ADC #$00
    STA $24
    JMP Label_8549

Label_8538:
    LDA PlayerXLo
    SEC
    SBC #$02
    STA $21
    STA $23
    LDA PlayerXHi
    SBC #$00
    STA $22
    STA $24

Label_8549:
    LDA $24
    BEQ Label_855D
    CMP #$01
    BEQ Label_8554
    JMP Label_86C6

Label_8554:
    LDA $23
    CMP #$31
    BCC Label_855D
    JMP Label_870F

Label_855D:
    LDA #$FF
    STA a:$07CB
    LDA PlayerY
    CLC
    ADC #$0F
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA PlayerY
    CLC
    ADC #$07
    TAY
    STY $1E
    LDA $22
    LDX $21
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_85A6
    LDA #$FF
    STA a:$07CB
    LDA $22
    LDX $21
    LDY PlayerY
    STY $1E
    JSR SamplePlayerCollisionAtScreenPixel
    BCS Label_85A6
    LDA $24
    STA PlayerXHi
    LDA $23
    STA PlayerXLo
    JMP Label_85CA

Label_85A6:
    ASL A
    TAX
    BCS Label_85B7
    LDA PlayerHorizontalRoomCellCollisionHandlerPointers,X
    STA $31
    LDA PlayerHorizontalRoomCellCollisionHandlerPointers + 1,X
    STA $32
    JMP Label_85C1

Label_85B7:
    LDA PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6,X
    STA $31
    LDA PlayerHorizontalRuntimeCollisionHandlerPointerEntries80ToA6 + 1,X
    STA $32

Label_85C1:
    LDA #$85
    PHA
    LDA #$C9
    PHA
    JMP ($0031)

Label_85CA:
    LDA a:$0779
    BNE Label_85D2
    JMP Label_8673

Label_85D2:
    LDA $3B
    BNE Label_85D9
    JMP Label_8673

Label_85D9:
    BMI Label_85F5
    LDA PlayerXLo
    CLC
    ADC #$16
    STA $21
    LDA PlayerXHi
    ADC #$00
    STA $22
    LDA $21
    CMP #$40
    LDA $22
    SBC #$01
    BCC Label_8604
    JMP Label_8673

Label_85F5:
    LDA PlayerXLo
    SEC
    SBC #$06
    STA $21
    LDA PlayerXHi
    SBC #$00
    STA $22
    BMI Label_8673

Label_8604:
    LDA PlayerY
    SEC
    SBC #$05
    STA $16
    LDX #$00

Label_860D:
    LDA RuntimeObjectRecords,X
    BPL Label_866A
    CMP #$A8
    BCS Label_866A
    TAY
    LDA $16
    SEC
    SBC RuntimeObjectY,X
    BCC Label_866A
    SBC RuntimeObjectCollisionHeights - RuntimeObjectCollisionTypeFirst,Y
    BCS Label_866A
    LDA $21
    STA $23
    LDA $22
    STA $24
    LDA $23
    SEC
    SBC RuntimeObjectXLo,X
    STA $23
    LDA $24
    SBC RuntimeObjectXHi,X
    BCC Label_866A
    STA $24
    LDA $23
    SBC RuntimeObjectCollisionWidths - RuntimeObjectCollisionTypeFirst,Y
    BCS Label_866A
    LDA $24
    BNE Label_866A
    LDA RuntimeObjectRecords,X
    CMP #$85
    BEQ Label_8673
    CMP #$89
    BEQ Label_8673
    CMP #$86
    BEQ Label_8673
    STX $16
    TYA
    JSR GetRuntimeObjectType84To89Filter
    BNE Label_8673
    LDA #$A8
    LDX $16
    STA RuntimeObjectRecords,X
    LDA #$00
    STA RuntimeObjectState,X
    JSR StartPulse2NoiseSoundEffect2
    JMP Label_8673

Label_866A:
    TXA
    CLC
    ADC #$06
    TAX
    CPX #$90
    BCC Label_860D

Label_8673:
    LDA Controller1Buttons
    STA PreviousController1Buttons
    RTS

Label_867A:
    LDA #$98
    STA PlayerY
    STA $12
    LDA PlayerXHi
    STA $11
    LDA PlayerXLo
    AND #$F8
    STA PlayerXLo
    STA $10
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomAbove
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

Label_86A0:
    LDA #$10
    STA PlayerY
    STA $12
    LDA PlayerXHi
    STA $11
    LDA PlayerXLo
    AND #$F8
    STA PlayerXLo
    STA $10
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomBelow
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    JMP FinishRoomTransition

Label_86C6:
    LDA CurrentRoomNumber
    JSR FindLeftmostCastleRoom
    BNE Label_86D6
    LDA #$00
    STA PlayerXLo
    STA PlayerXHi
    JMP UpdateHorizontalScroll

Label_86D6:
    LDA #$30
    STA PlayerXLo
    STA $10
    LDA #$01
    STA PlayerXHi
    STA $11
    LDA PlayerY
    STA $12
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomLeft
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #$10
    TAY
    LDA #$01
    LDX #$30
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS Label_870C
    JSR RestoreMutableCellByOrdinal

Label_870C:
    JMP FinishRoomTransition

Label_870F:
    LDA CurrentRoomNumber
    JSR FindRightmostCastleRoom
    BNE Label_8721
    LDA #$01
    STA PlayerXHi
    LDA #$30
    STA PlayerXLo
    JMP UpdateHorizontalScroll

Label_8721:
    LDA #$00
    STA PlayerXLo
    STA PlayerXHi
    STA $10
    STA $11
    LDA PlayerY
    STA $12
    JSR SaveCurrentRoomObjectState
    JSR MoveToRoomRight
    LDA #$00
    STA a:$07CD
    JSR LoadRoom
    JSR UpdateHorizontalScroll
    LDA PlayerY
    SEC
    SBC #$10
    TAY
    LDA #$00
    LDX #$00
    JSR ConvertPixelPositionToTileCoordinates
    JSR FindMutableCellOrdinalAtPosition
    BCS Label_8755
    JSR RestoreMutableCellByOrdinal

Label_8755:
    JMP FinishRoomTransition
