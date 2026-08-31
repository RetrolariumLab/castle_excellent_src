; PPU state helpers and CNROM bank selection
; CPU range $8158-$817F
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

DisableNmi:
    LDA #PpuCtrlGameplayNoNmi
    STA PPU_CTRL
    RTS

EnableNmi:
    LDA #PpuCtrlGameplayNmi
    STA PPU_CTRL
    RTS

DisableRendering:
    LDA #PpuMaskRenderingDisabled
    STA PPU_MASK
    RTS

WaitForVblankAndEnableRendering:
    LDA PPU_STATUS
    BPL WaitForVblankAndEnableRendering
    LDA #PpuMaskGameplay
    STA PPU_MASK
    RTS

SelectChrBank:
    LDA ChrBankSelectValues,Y
    STA ChrBankSelectValues,Y
    RTS

ChrBankSelectValues:
    .byte $00, $01, $02, $03
