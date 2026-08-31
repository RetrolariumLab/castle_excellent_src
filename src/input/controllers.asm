; Controller wrappers and serial polling
; CPU range $80FF-$8157
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ReadController1:
    JSR DisableNmi
    JSR PollController1
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS

ReadController1WithoutNmiControl:
    JSR PollController1
    LDA PolledControllerButtons
    RTS

PollController1:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #ControllerSerialBitCount

ReadNextController1Bit:
    LDA JOYPAD1
    LSR A
    BCS ShiftController1Bit
    LSR A

ShiftController1Bit:
    ROR PolledControllerButtons
    DEX
    BNE ReadNextController1Bit
    RTS

ReadController2:
    JSR DisableNmi
    JSR PollController2
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS

UnreferencedController2ReadWrapperBytes:
    .byte $20, $3B, $81, $A5, $20, $60

PollController2:
    LDX #$01
    STX JOYPAD1
    DEX
    STX JOYPAD1
    LDX #ControllerSerialBitCount

ReadNextController2Bit:
    LDA JOYPAD2
    LSR A
    BCS ShiftController2Bit
    LSR A

ShiftController2Bit:
    ROR PolledControllerButtons
    DEX
    BNE ReadNextController2Bit
    JSR EnableNmi
    LDA PolledControllerButtons
    RTS
