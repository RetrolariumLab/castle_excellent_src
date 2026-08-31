; Famicom data-transport selection and expansion-port serial I/O
; CPU range $8180-$8224
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

SendDataPreamble:
    BIT DataIoTransportMode
    BPL SendExpansionPreamble
    JMP SendPulsePreamble

SendExpansionPreamble:
    JSR StrobeExpansionPort
    LDA #$00
    STA DataIoByte
    JSR SendExpansionByte
    LDA #DataPreambleSyncA
    STA DataIoByte
    JSR SendExpansionByte
    LDA #DataPreambleSyncB
    STA DataIoByte
    JMP SendExpansionByte

ReceiveDataPreamble:
    BIT DataIoTransportMode
    BPL ReceiveExpansionPreamble
    JMP ReceivePulsePreamble

ReceiveExpansionPreamble:
    JSR StrobeExpansionPort
    JSR ReceiveExpansionByte
    JSR ReceiveExpansionByte
    LDA DataIoByte
    CMP #DataPreambleSyncA
    BNE ReturnDataPreambleFailure
    JSR ReceiveExpansionByte
    LDA DataIoByte
    CMP #DataPreambleSyncB
    BNE ReturnDataPreambleFailure
    CLC
    RTS

ReturnDataPreambleFailure:
    SEC
    RTS

SendDataByte:
    STA DataIoByte
    STX DataIoSavedX
    BIT DataIoTransportMode
    BPL SendExpansionBytePath
    JSR SendPulseByte
    JMP RestoreDataIoSendX

SendExpansionBytePath:
    JSR SendExpansionByte

RestoreDataIoSendX:
    LDX DataIoSavedX
    RTS

ReceiveDataByte:
    STX DataIoSavedX
    BIT DataIoTransportMode
    BMI ReceivePulseBytePath
    JSR ReceiveExpansionByte
    JMP ReturnDataByte

ReceivePulseBytePath:
    JSR ReceivePulseByte

ReturnDataByte:
    LDX DataIoSavedX
    LDA DataIoByte
    RTS

SendExpansionByte:
    LDY #DataIoBitCount - 1

SendNextExpansionBit:
    ASL DataIoByte
    LDA #$00
    ROL A
    ORA #ExpansionSerialClockHigh
    STA JOYPAD1
    AND #ExpansionSerialClockLowMask
    STA JOYPAD1
    DEY
    BPL SendNextExpansionBit
    RTS

ReceiveExpansionByte:
    LDY #DataIoBitCount - 1

ReceiveNextExpansionBit:
    LDA EXPANSION_PORT_INPUT
    LSR A
    LSR A
    AND #ExpansionSerialDataBit
    ORA #ExpansionSerialClockHigh
    STA JOYPAD1
    AND #ExpansionSerialClockLowMask
    STA JOYPAD1
    LSR A
    ROL DataIoByte
    DEY
    BPL ReceiveNextExpansionBit
    CLC
    RTS

StrobeExpansionPort:
    LDA #$00
    STA JOYPAD1
    LDA #ExpansionSerialStrobe
    STA JOYPAD1
    RTS
