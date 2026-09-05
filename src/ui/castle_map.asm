; Castle map input, visited-room drawing, and player marker
; CPU range $EA36-$EB6B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
