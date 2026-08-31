; Preservation PRG between object data and persistent-state saving
; CPU range $F8FC-$FDC4
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

RunTitleScreen:
    LDA #$18
    JSR CopyChrNametablePagesToVram
    LDA #$C5
    STA $22
    LDA #$0D
    STA $21
    JSR UploadPaletteFromPointer
    LDY #$01
    JSR SelectChrBank
    JSR ResetPpuScroll
    LDX #$00
    STX $21
    STX $22
    DEX
    STX DemoPlaybackActive
    JSR Func_B7FD
    JSR LoadAudioTrackSet5
    SEI

Label_F925:
    LDA PPU_STATUS
    BPL Label_F925
    LDA #$0A
    STA PPU_MASK
    LDA #$38
    STA PPU_CTRL
    JSR ReadController1WithoutNmiControl
    EOR #$FF
    STA PreviousController1Buttons

Label_F93C:
    LDA PPU_STATUS
    BPL Label_F93C
    JSR UpdateAudioStreams
    INC $21
    BNE Label_F94A
    INC $22

Label_F94A:
    LDA $22
    CMP #$03
    BCS Label_F968
    JSR ReadController1WithoutNmiControl
    TAX
    AND PreviousController1Buttons
    AND #$08
    PHA
    TXA
    EOR #$FF
    STA PreviousController1Buttons
    PLA
    BEQ Label_F93C
    LDA #$00
    STA DemoPlaybackActive

Label_F968:
    JSR DisableNmi
    JSR DisableRendering
    LDY #$00
    JMP SelectChrBank

CopyChrNametablePagesToVram:
    STA $16
    LDA #$20
    STA $17
    JSR ClearRoomNametablesAndSprites
    LDY #$03
    JSR SelectChrBank
    LDX #$00

Label_F983:
    LDA PPU_STATUS
    LDA $16
    STA PPU_ADDR
    STX PPU_ADDR
    LDA PPU_DATA
    LDY PPU_DATA
    LDA $17
    STA PPU_ADDR
    STX PPU_ADDR
    STY PPU_DATA
    INX
    BNE Label_F983
    INC $16
    INC $17
    LDA $17
    CMP #$24
    BCC Label_F983
    RTS

HandleSubCommandInput:
    LDA a:$07CC
    BEQ Label_F9B3
    RTS

Label_F9B3:
    LDA DemoPlaybackActive
    BEQ Label_F9B9
    RTS

Label_F9B9:
    LDA PreviousController2Buttons
    EOR #$FF
    AND Controller2Buttons
    AND #$03
    BNE Label_F9CC
    LDA Controller2Buttons
    STA PreviousController2Buttons
    RTS

Label_F9CC:
    JSR ClearRoomNametablesAndSprites
    LDA #$00
    STA JOYPAD1
    STA APU_STATUS

Label_F9D7:
    LDA PPU_STATUS
    BPL Label_F9D7
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0A
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$77
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$8D
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CD
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$93
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$83
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$88
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8D
    STA PPU_ADDR
    LDA #$FB
    STA $22
    LDA #$98
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA #$00
    STA $1D
    LDA #$FF
    STA $1C

Label_FA74:
    LDA PPU_STATUS
    BPL Label_FA74
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    LDX #$FF
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$CB
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$4B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$22
    STA PPU_ADDR
    LDA #$8B
    STA PPU_ADDR
    STX PPU_DATA
    LDA PPU_STATUS
    LDA #$00
    STA $22
    LDA $1D
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    ROL $22
    CLC
    ADC #$8B
    STA $21
    LDA #$21
    ADC $22
    STA PPU_ADDR
    LDA $21
    STA PPU_ADDR
    LDA #$6B
    STA PPU_DATA
    JSR ResetPpuScroll

Label_FAF5:
    LDA PPU_STATUS
    BPL Label_FAF5
    LDA #$08
    STA PPU_MASK
    JSR DisableNmi
    JSR ReadController1WithoutNmiControl
    PHA
    AND $1C
    TAY
    PLA
    EOR #$FF
    STA $1C
    TYA
    AND #$24
    BEQ Label_FB27
    INC $1D
    LDA $1D
    CMP #$05
    BCS Label_FB1E
    JMP Label_FA74

Label_FB1E:
    LDA #$00
    STA $1D
    BNE Label_FB27
    JMP Label_FA74

Label_FB27:
    TYA
    AND #$08
    BEQ Label_FB32
    LDA #$00
    STA $1F
    BEQ Label_FB62

Label_FB32:
    TYA
    AND #$01
    BEQ Label_FB3D
    LDA #$FF
    STA $1F
    BNE Label_FB62

Label_FB3D:
    TYA
    AND #$10
    BEQ Label_FB4E
    DEC $1D
    LDA $1D
    CMP #$FF
    BNE Label_FB4E
    LDA #$04
    STA $1D

Label_FB4E:
    JMP Label_FA74

Func_FB51:
    LDA #$FF
    STA PauseMode
    STA PreviousController2Buttons
    JSR StopAudioStreams
    JSR ClearSoundRequests
    JMP FinalizeRoomLoad

Label_FB62:
    LDX $1D
    BEQ Label_FBAC
    DEX
    BEQ Label_FBD6
    DEX
    BEQ Label_FB71
    DEX
    BEQ Label_FB74
    BNE Func_FB51

Label_FB71:
    JMP Func_FD06

Label_FB74:
    JMP Label_FBFE
    .byte $83, $85, $72, $FF, $73, $7F, $7D, $7D, $71, $7E, $74, $00, $7C, $7F, $71, $74
    .byte $00, $83, $71, $86, $75, $00, $82, $75, $83, $75, $84, $00, $72, $71, $73, $7B
    .byte $00, $77, $71, $7D, $75, $00, $7C, $7F, $71, $74, $79, $7E, $77, $00, $83, $71
    .byte $86, $79, $7E, $77, $00

Label_FBAC:
    LDA $13
    BNE Label_FBB3
    JMP Label_FA74

Label_FBB3:
    JSR LoadRoomPersistentState
    LDX #$0D

Label_FBB8:
    LDA RoomRuntimeLoadMirror,X
    STA $05,X
    DEX
    BPL Label_FBB8

Label_FBC0:
    LDA $10
    STA $38
    LDA $11
    STA $39
    LDA $12
    STA $3A
    DEC $13
    LDA #$00
    STA a:$07CD
    JMP Label_FD96

Label_FBD6:
    LDA $13
    BNE Label_FBDD
    JMP Label_FA74

Label_FBDD:
    LDA RoomStateSnapshotA
    BNE Label_FBE5
    JMP Label_FA74

Label_FBE5:
    STA CurrentRoomIndex
    JSR RestoreRoomStateSnapshotA
    LDX #$0D

Label_FBEC:
    LDA RoomRuntimeStateSnapshotA,X
    STA $05,X
    DEX
    BPL Label_FBEC
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    BEQ Label_FBC0

Label_FBFE:
    JSR DisableNmi
    LDA $13
    BNE Label_FC08
    JMP Label_FA74

Label_FC08:
    LDA RoomStateLoadMirror
    BNE Label_FC10
    JMP Label_FA74

Label_FC10:
    DEC $13
    JSR ClearRoomNametablesAndSprites
    LDA #$FB
    STA $22
    LDA #$A5
    STA $21
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR Func_FCEA
    JSR Func_8180
    LDA CurrentRoomIndex
    JSR Func_81C2
    LDA a:$0744
    JSR Func_81C2
    LDX #$00

Label_FC3D:
    LDA RoomRuntimeLoadMirror,X
    JSR Func_81C2
    INX
    CPX #$0E
    BCC Label_FC3D
    JSR SaveRoomStateSnapshotB
    LDA #$00
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    LDX #$78

Label_FC55:
    LDA RoomCells + $18F,X
    JSR Func_81C2
    DEX
    BNE Label_FC55
    LDX #$96

Label_FC60:
    LDA a:$0607,X
    JSR Func_81C2
    DEX
    BNE Label_FC60
    LDX #$64

Label_FC6B:
    LDA a:$069D,X
    JSR Func_81C2
    DEX
    BNE Label_FC6B
    LDX #$08

Label_FC76:
    LDA a:$FC99,X
    JSR Func_81C2
    DEX
    BNE Label_FC76
    JMP Func_FB51
    .byte $7C, $7F, $71, $74, $FF, $75, $82, $82, $7F, $82, $00, $80, $85, $83, $78, $FF
    .byte $71, $FF, $7F, $82, $FF, $72, $00, $47, $4E, $55, $54, $55, $45, $44, $45, $42

Func_FCA2:
    JSR ClearRoomNametablesAndSprites
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0B
    STA PPU_ADDR
    LDA #$FC
    STA $22
    LDA #$82
    STA $21
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$4A
    STA PPU_ADDR
    LDA #$FC
    STA $22
    LDA #$8D
    STA $21
    JSR Func_FCEA

Label_FCD5:
    JSR ReadController1WithoutNmiControl
    AND #$03
    BEQ Label_FCD5
    JSR InitializeNewGame
    LDA #$00
    STA APU_STATUS
    STA a:$07CD
    JMP Label_F9CC

Func_FCEA:
    JSR WriteTerminatedPpuTiles
    LDA PPU_STATUS
    JSR ResetPpuScroll
    STA APU_STATUS

Label_FCF6:
    LDA PPU_STATUS
    BPL Label_FCF6
    LDA #$08
    STA PPU_MASK
    JMP DisableNmi

Label_FD03:
    JMP Func_FCA2

Func_FD06:
    JSR DisableNmi
    JSR Func_819F
    BCS Label_FD03
    JSR ClearRoomNametablesAndSprites
    LDA #$FB
    STA $22
    LDA #$9D
    STA $21
    LDA PPU_STATUS
    LDA #$21
    STA PPU_ADDR
    LDA #$0C
    STA PPU_ADDR
    JSR Func_FCEA
    JSR Func_81D6
    BCS Label_FD03
    STA CurrentRoomIndex
    STA CurrentRoomState
    JSR Func_81D6
    STA $13
    LDX #$00

Label_FD3A:
    JSR Func_81D6
    BCS Label_FD03
    STA $05,X
    INX
    CPX #$0E
    BCC Label_FD3A
    LDX #$78

Label_FD48:
    JSR Func_81D6
    BCS Label_FD03
    STA RoomCells + $18F,X
    DEX
    BNE Label_FD48
    LDX #$96

Label_FD55:
    JSR Func_81D6
    BCS Label_FD03
    STA a:$0607,X
    DEX
    BNE Label_FD55
    LDX #$64

Label_FD62:
    JSR Func_81D6
    BCS Label_FD03
    STA a:$069D,X
    DEX
    BNE Label_FD62
    LDX #$08

Label_FD6F:
    JSR Func_81D6
    BCS Label_FD03
    CMP a:$FC99,X
    BNE Label_FD03
    DEX
    BNE Label_FD6F
    LDA #$00
    STA JOYPAD1
    STA RoomStateLoadMirror
    STA RoomStateSnapshotA
    STA RoomStateSnapshotB
    LDA $10
    STA $38
    LDA $11
    STA $39
    LDA $12
    STA $3A

Label_FD96:
    LDA #$00
    STA a:$0772
    LDX CurrentRoomIndex
    DEX
    JSR DecodeRoom
    JSR BuildRoomAttributeTables
    JSR LoadRoomObjects
    JSR SelectAndApplyRoomState
    JSR UpdateHorizontalScroll
    LDA $3A
    SEC
    SBC #$10
    TAY
    LDA $39
    LDX $38
    JSR Func_A58A
    JSR Func_A66D
    BCS Label_FDC2
    JSR Func_A70A

Label_FDC2:
    JMP Func_FB51
