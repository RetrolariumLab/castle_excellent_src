; Room attributes and castle map
; CPU range $E8DF-$EB6B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

GetRoomAttributeMaskAndOffset:
    LDA #$00
    STA RoomAttributeByteOffset
    CPX #$20
    BCC MapRoomAttributePosition
    LDA #$40
    STA RoomAttributeByteOffset
    TXA
    SEC
    SBC #$20
    TAX

MapRoomAttributePosition:
    TYA
    ASL A
    AND #$F8
    CLC
    ADC RoomAttributeByteOffset
    STA RoomAttributeByteOffset
    TXA
    LSR A
    LSR A
    CLC
    ADC RoomAttributeByteOffset
    STA RoomAttributeByteOffset
    TYA
    AND #$02
    STA RoomAttributeQuadrantIndex
    TXA
    LSR A
    AND #$01
    ORA RoomAttributeQuadrantIndex
    TAX
    LDA RoomAttributeQuadrantMasks,X
    LDX RoomAttributeByteOffset
    RTS

RoomAttributeQuadrantMasks:
    .byte $03, $0C, $30, $C0

BuildRoomAttributeTables:
    LDX #$00
    TXA

ClearRoomAttributeScratch:
    STA RoomAttributeScratch,X
    INX
    BPL ClearRoomAttributeScratch
    LDA #$00
    STA RoomAttributeRow
    LDX #$00

CopyInitialRoomAttributes:
    LDA InitialRoomAttributes,X
    STA RoomAttributeScratch,X
    INX
    CPX #$10
    BCC CopyInitialRoomAttributes

BeginRoomAttributeRow:
    LDA #$00
    STA RoomAttributeColumn
    LDA RoomAttributeRow
    ASL A
    ASL A
    CLC
    ADC RoomAttributeRow
    STA RoomCellRowPointerLo
    LDA #$00
    STA RoomCellRowPointerHi
    ASL RoomCellRowPointerLo
    ROL RoomCellRowPointerHi
    ASL RoomCellRowPointerLo
    ROL RoomCellRowPointerHi
    LDA RoomCellRowPointerLo
    CLC
    ADC #<RoomCells
    STA RoomCellRowPointerLo
    LDA RoomCellRowPointerHi
    ADC #>RoomCells
    STA RoomCellRowPointerHi

ProcessRoomAttributeCell:
    LDA RoomAttributeColumn
    ASL A
    CLC
    ADC #$04
    TAX
    LDA RoomAttributeRow
    CLC
    ADC #$07
    TAY
    JSR GetRoomAttributeMaskAndOffset
    PHA
    EOR #$FF
    AND RoomAttributeScratch,X
    STA RoomAttributePreservedBits
    LDY RoomAttributeColumn
    LDA (RoomCellRowPointerLo),Y
    CMP #$53
    BEQ DiscardRoomAttributeMask
    CMP #$09
    BEQ DiscardRoomAttributeMask
    JSR IsRoomCellAttributePreserving
    BEQ DiscardRoomAttributeMask
    TAY
    PLA
    AND RoomCellAttributeValues,Y
    ORA RoomAttributePreservedBits
    STA RoomAttributeScratch,X
    JMP AdvanceRoomAttributeCell

DiscardRoomAttributeMask:
    PLA

AdvanceRoomAttributeCell:
    INC RoomAttributeColumn
    LDA RoomAttributeColumn
    CMP #RoomWidth
    BCC ProcessRoomAttributeCell
    INC RoomAttributeRow
    LDA RoomAttributeRow
    CMP #RoomHeight
    BCC BeginRoomAttributeRow
    LDA #$FF
    STA NmiRoomAttributesLeftRequest
    STA NmiRoomAttributesRightRequest
    RTS

IsRoomCellAttributePreserving:
    CMP #$18
    BEQ ReturnRoomCellAttributeClass
    CMP #$1B
    BEQ ReturnRoomCellAttributeClass
    CMP #$1E
    BEQ ReturnRoomCellAttributeClass
    CMP #$21
    BEQ ReturnRoomCellAttributeClass
    CMP #$24
    BEQ ReturnRoomCellAttributeClass
    CMP #$27
    BEQ ReturnRoomCellAttributeClass
    CMP #$28
    BEQ ReturnRoomCellAttributeClass
    CMP #$2B
    BEQ ReturnRoomCellAttributeClass
    CMP #$2C
    BEQ ReturnRoomCellAttributeClass
    CMP #$2D
    BEQ ReturnRoomCellAttributeClass
    CMP #$2E

ReturnRoomCellAttributeClass:
    RTS

RoomCellAttributeValues:
    .byte $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $AA, $AA, $AA, $AA, $AA, $AA, $55, $55
    .byte $55, $AA, $AA, $AA, $55, $55, $55, $AA, $55, $55, $55, $AA, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $55, $55, $55, $55, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00

HandleCastleMapInput:
    LDA CastleMapAvailable
    BNE ProcessCastleMapButton
    RTS

ProcessCastleMapButton:
    LDA Controller1Buttons
    AND #ControllerButtonSelect
    BEQ CheckCastleMapExit
    LDA #$00
    STA Controller1Buttons
    STA PreviousController1Buttons
    LDA CastleMapMode
    BNE ReturnFromCastleMapInput
    JSR DrawCastleMap
    LDA #CastleMapModeActive
    STA CastleMapMode
    JSR WaitForVblankAndEnableRendering
    LDA PauseMode
    BNE RestoreCastleMapNmi
    JSR UpdateAudioStreams

RestoreCastleMapNmi:
    LDA #PpuCtrlCastleMapNmi
    STA PPU_CTRL

ReturnFromCastleMapInput:
    RTS

CheckCastleMapExit:
    LDA CastleMapMode
    BEQ ReturnFromCastleMapInput
    LDA PreviousController1Buttons
    EOR #$FF
    AND Controller1Buttons
    AND #CastleMapExitButtons
    BEQ ReturnFromCastleMapInput
    LDA #$00
    STA CastleMapMode
    JMP FinalizeRoomLoad

DrawCastleMap:
    LDA #$1C
    JSR CopyChrNametablePagesToVram
    LDY #$01
    JSR SelectChrBank
    LDA #>CastleMapPaletteData
    STA CastleMapPpuAddressHi
    LDA #<CastleMapPaletteData
    STA CastleMapPpuAddressLo
    JSR UploadPaletteFromPointer
    LDX #$00
    STX CastleMapRoomIndex

ProcessNextCastleMapRoom:
    LDX CastleMapRoomIndex
    LDA RoomVisitedFlags,X
    BNE PositionVisitedRoomMarker
    JMP AdvanceCastleMapRoom

PositionVisitedRoomMarker:
    TXA
    LDX #$00

DivideMapRoomIndexByTen:
    CMP #CastleMapColumns
    BCC ComputeMapRoomMarkerAddress
    INX
    SBC #$0A
    BCS DivideMapRoomIndexByTen

ComputeMapRoomMarkerAddress:
    ASL A
    CLC
    ADC #$C6
    STA CastleMapPpuAddressLo
    LDA #$20
    STA CastleMapPpuAddressHi
    TXA
    LSR A
    LSR A
    PHA
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC CastleMapPpuAddressLo
    STA CastleMapPpuAddressLo
    PLA
    ADC CastleMapPpuAddressHi
    STA CastleMapPpuAddressHi
    LDA PPU_STATUS
    LDA CastleMapPpuAddressHi
    STA PPU_ADDR
    LDA CastleMapPpuAddressLo
    STA PPU_ADDR
    LDA #$07
    STA PPU_DATA
    LDA #$08
    STA PPU_DATA
    LDA #$20
    ADC CastleMapPpuAddressLo
    STA CastleMapPpuAddressLo
    BCC DrawMapRoomMarkerBottom
    INC CastleMapPpuAddressHi

DrawMapRoomMarkerBottom:
    LDA PPU_STATUS
    LDA CastleMapPpuAddressHi
    STA PPU_ADDR
    LDA CastleMapPpuAddressLo
    STA PPU_ADDR
    LDA #$09
    STA PPU_DATA
    LDA #$0A
    STA PPU_DATA
    LDA CastleMapPpuAddressLo
    AND #$1F
    TAX
    ASL CastleMapPpuAddressLo
    ROL CastleMapPpuAddressHi
    ASL CastleMapPpuAddressLo
    ROL CastleMapPpuAddressHi
    LDA CastleMapPpuAddressHi
    AND #$1F

AdvanceCastleMapRoom:
    INC CastleMapRoomIndex
    LDA CastleMapRoomIndex
    CMP #CastleMapRoomCount
    BCS InitializeCastleMapPlayerMarker
    JMP ProcessNextCastleMapRoom

InitializeCastleMapPlayerMarker:
    LDX #OamSpriteSize
    LDA #$F0

HideRemainingCastleMapSprites:
    STA OamStagingBuffer,X
    INX
    BNE HideRemainingCastleMapSprites
    LDA CurrentRoomNumber
    SEC
    SBC #$01
    LDX #$00

DivideCurrentRoomByTen:
    CMP #CastleMapColumns
    BCC PositionCurrentRoomMapSprite
    INX
    SBC #$0A
    JMP DivideCurrentRoomByTen

PositionCurrentRoomMapSprite:
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #$34
    STA OamStagingBuffer + $03
    TXA
    ASL A
    ASL A
    ASL A
    ASL A
    CLC
    ADC #$33
    STA OamStagingBuffer
    LDA #$F0
    STA OamStagingBuffer + $01
    LDA #$00
    STA OamStagingBuffer + $02
    JSR ResetPpuScroll
    JSR WaitForVblankAndEnableRendering
    LDA PauseMode
    BNE ReturnFromCastleMapDraw
    JSR UpdateAudioStreams

ReturnFromCastleMapDraw:
    RTS
