; Title-demo controller script playback
; CPU range $B7FD-$B82B
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

InitializeTitleDemoPlayback:
    LDA #<TitleDemoInputScript
    STA DemoInputPointerLo
    LDA #>TitleDemoInputScript
    STA DemoInputPointerHi
    LDA #$00
    STA DemoInputRepeatCounter
    RTS

ReadDemoController1:
    INC DemoInputRepeatCounter
    LDA DemoInputRepeatCounter
    CMP #DemoInputCommandFrames
    BCS AdvanceDemoInputPointer
    LDY #$00

ReadCurrentDemoInputCommand:
    LDA (DemoInputPointerLo),Y
    CMP #DemoInputTerminator
    BNE ReturnMaskedDemoInput
    JMP Reset

ReturnMaskedDemoInput:
    AND #DemoInputControllerMask
    RTS

AdvanceDemoInputPointer:
    INC DemoInputPointerLo
    BNE ResetDemoInputRepeatCounter
    INC DemoInputPointerHi

ResetDemoInputRepeatCounter:
    LDY #$00
    STY DemoInputRepeatCounter
    BEQ ReadCurrentDemoInputCommand
