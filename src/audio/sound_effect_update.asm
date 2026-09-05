; Per-frame sound-effect channel updater
; CPU range $C2F9-$C428
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

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
