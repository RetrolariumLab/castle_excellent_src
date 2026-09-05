; Five sound-effect channel starters
; CPU range $C20D-$C2F8
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

StartPulse1SoundEffect1:
    LDA #$0F
    STA APU_STATUS
    LDA #$01
    STA Pulse1SoundEffectBusy
    STA Pulse1SoundEffectRequest
    LDA #$DF
    STA APU_PL1_VOL
    LDA #$BA
    STA APU_PL1_SWEEP
    LDA #$40
    STA APU_PL1_LO
    LDA #$A0
    STA APU_PL1_HI
    LDA #$00
    STA Pulse1SoundEffectBusy
    RTS

StartPulse2NoiseSoundEffect2:
    LDA #$0F
    STA APU_STATUS
    LDA #$02
    STA Pulse2SoundEffectBusy
    STA NoiseSoundEffectBusy
    STA Pulse2SoundEffectRequest
    STA NoiseSoundEffectRequest
    LDA #$83
    STA APU_PL2_VOL
    LDA #$96
    STA APU_PL2_SWEEP
    LDA #$FF
    STA APU_PL2_LO
    LDA #$F1
    STA APU_PL2_HI
    LDA #$C1
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$F8
    STA APU_NOISE_HI
    LDA #$00
    STA Pulse2SoundEffectStep
    STA Pulse2SoundEffectBusy
    STA NoiseSoundEffectBusy
    RTS

StartInventoryCollectibleSoundEffect:
    LDA #$0F
    STA APU_STATUS
    LDA #$03
    STA Pulse2SoundEffectBusy
    STA Pulse2SoundEffectRequest
    LDA #$40
    STA APU_PL2_VOL
    LDA #$08
    STA APU_PL2_SWEEP
    LDA #$50
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    LDA #$00
    STA Pulse2SoundEffectStep
    STA Pulse2SoundEffectBusy
    RTS

StartNoiseSoundEffect4:
    LDA #$0F
    STA APU_STATUS
    LDA #$04
    STA NoiseSoundEffectBusy
    STA NoiseSoundEffectRequest
    LDA #$18
    STA APU_NOISE_VOL
    LDA #$0C
    STA APU_NOISE_LO
    LDA #$38
    STA APU_NOISE_HI
    LDA #$00
    STA NoiseSoundEffectStep
    STA NoiseSoundEffectBusy
    RTS

StartMutableCellOpenSoundEffect:
    LDA #$0F
    STA APU_STATUS
    LDA #$05
    STA TriangleSoundEffectBusy
    STA NoiseSoundEffectBusy
    STA TriangleSoundEffectRequest
    STA NoiseSoundEffectRequest
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$F0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0F
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    LDA #$00
    STA TriangleSoundEffectStep
    STA NoiseSoundEffectStep
    STA TriangleSoundEffectBusy
    STA NoiseSoundEffectBusy
    RTS
