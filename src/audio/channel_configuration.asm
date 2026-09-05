; APU channel configuration for streamed notes
; CPU range $BAE9-$BB15
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

ConfigureAudioChannel:
    LDA #$0F
    STA APU_STATUS
    CPX #$00
    BNE ConfigurePulse2AudioChannel
    LDA AudioPulseParameters
    STA APU_PL1_VOL
    LDA #$08
    STA APU_PL1_SWEEP
    RTS

ConfigurePulse2AudioChannel:
    CPX #$04
    BNE ConfigureTriangleAudioChannel
    LDA AudioPulse2TrackParameters
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    RTS

ConfigureTriangleAudioChannel:
    CPX #$08
    BNE ReturnFromConfigureAudioChannel
    LDA #$FF
    STA APU_TRI_LINEAR

ReturnFromConfigureAudioChannel:
    RTS
