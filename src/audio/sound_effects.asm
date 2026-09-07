; Sound effect engine and tables
; CPU range $C20D-$C43C
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

UpdateSoundEffects:
    LDA #$0F
    STA APU_STATUS
    LDA Pulse1SoundEffectBusy
    BNE UpdatePulse2SoundEffect
    LDA Pulse1SoundEffectRequest
    BEQ UpdatePulse2SoundEffect
    CMP #$01
    BNE UpdatePulse2SoundEffect
    LDA APU_STATUS
    AND #$01
    BNE UpdatePulse2SoundEffect
    LDA #$00
    STA Pulse1SoundEffectRequest
    BEQ UpdatePulse2SoundEffect

UpdatePulse2SoundEffect:
    LDA Pulse2SoundEffectBusy
    BNE UpdateTriangleSoundEffect
    LDA Pulse2SoundEffectRequest
    BEQ UpdateTriangleSoundEffect
    CMP #$03
    BNE UpdatePulse2SoundEffect2
    LDA APU_STATUS
    AND #$02
    BNE UpdateTriangleSoundEffect
    INC Pulse2SoundEffectStep
    LDX Pulse2SoundEffectStep
    CPX #$04
    BCC AdvanceInventoryCollectibleSoundEffect
    LDA #$00
    STA Pulse2SoundEffectRequest
    BEQ UpdateTriangleSoundEffect

AdvanceInventoryCollectibleSoundEffect:
    LDA InventorySoundEffectPeriodLow,X
    STA APU_PL2_LO
    LDA #$48
    STA APU_PL2_HI
    BNE UpdateTriangleSoundEffect

UpdatePulse2SoundEffect2:
    CMP #$02
    BNE UpdateTriangleSoundEffect
    LDA APU_STATUS
    AND #$02
    BNE UpdateTriangleSoundEffect
    STA Pulse2SoundEffectRequest

UpdateTriangleSoundEffect:
    LDA TriangleSoundEffectBusy
    BNE UpdateNoiseSoundEffect
    LDA TriangleSoundEffectRequest
    BEQ UpdateNoiseSoundEffect
    CMP #$02
    BNE UpdateTriangleSoundEffect5
    LDA APU_STATUS
    AND #$04
    BNE UpdateNoiseSoundEffect
    INC TriangleSoundEffectStep
    LDX TriangleSoundEffectStep
    CPX #$04
    BCC AdvanceTriangleSoundEffect2
    LDA #$00
    STA TriangleSoundEffectRequest
    BEQ UpdateNoiseSoundEffect

AdvanceTriangleSoundEffect2:
    LDA #$3F
    STA APU_TRI_LINEAR
    LDA TriangleSoundEffect2PeriodLow,X
    STA APU_TRI_LO
    LDA #$59
    STA APU_TRI_HI
    JMP UpdateNoiseSoundEffect

UpdateTriangleSoundEffect5:
    CMP #$05
    BNE UpdateNoiseSoundEffect
    LDA APU_STATUS
    AND #$04
    BNE UpdateNoiseSoundEffect
    INC TriangleSoundEffectStep
    LDX TriangleSoundEffectStep
    CPX #$02
    BCC AdvanceMutableCellTriangleSound
    LDA #$00
    STA TriangleSoundEffectRequest
    JMP UpdateNoiseSoundEffect

AdvanceMutableCellTriangleSound:
    LDA #$30
    STA APU_TRI_LINEAR
    LDA #$A0
    STA APU_TRI_LO
    LDA #$60
    STA APU_TRI_HI
    JMP UpdateNoiseSoundEffect

UpdateNoiseSoundEffect:
    LDA NoiseSoundEffectBusy
    BNE ReturnFromUpdateSoundEffects
    LDA NoiseSoundEffectRequest
    BEQ ReturnFromUpdateSoundEffects
    CMP #$04
    BNE UpdateNoiseSoundEffect5
    LDA APU_STATUS
    AND #$08
    BNE ReturnFromUpdateSoundEffects
    INC NoiseSoundEffectStep
    LDA NoiseSoundEffectStep
    CMP #$04
    BCS FinishNoiseSoundEffect4
    AND #$03
    TAX
    LDA NoiseSoundEffect4Volume,X
    STA APU_NOISE_VOL
    LDA NoiseSoundEffect4Period,X
    STA APU_NOISE_LO
    LDA NoiseSoundEffect4Length,X
    STA APU_NOISE_HI
    JMP ReturnFromUpdateSoundEffects

FinishNoiseSoundEffect4:
    LDA #$00
    STA NoiseSoundEffectRequest
    BEQ ReturnFromUpdateSoundEffects

UpdateNoiseSoundEffect5:
    CMP #$05
    BNE UpdateNoiseSoundEffect2
    LDA APU_STATUS
    AND #$08
    BNE ReturnFromUpdateSoundEffects
    INC NoiseSoundEffectStep
    LDX NoiseSoundEffectStep
    CPX #$02
    BCC AdvanceMutableCellNoiseSound
    LDA #$00
    STA NoiseSoundEffectRequest
    BEQ ReturnFromUpdateSoundEffects

AdvanceMutableCellNoiseSound:
    LDA #$04
    STA APU_NOISE_VOL
    LDA #$0D
    STA APU_NOISE_LO
    LDA #$60
    STA APU_NOISE_HI
    BNE ReturnFromUpdateSoundEffects

UpdateNoiseSoundEffect2:
    CMP #$02
    BNE ReturnFromUpdateSoundEffects
    LDA APU_STATUS
    AND #$08
    BNE ReturnFromUpdateSoundEffects
    LDA #$00
    STA NoiseSoundEffectRequest

ReturnFromUpdateSoundEffects:
    RTS

TriangleSoundEffect2PeriodLow:
    .byte $F0, $E0, $D0, $C0

InventorySoundEffectPeriodLow:
    .byte $50, $3F, $3D, $35

NoiseSoundEffect4Volume:
    .byte $18, $1B, $1E, $03

NoiseSoundEffect4Period:
    .byte $0C, $09, $06, $02

NoiseSoundEffect4Length:
    .byte $38, $38, $58, $38
