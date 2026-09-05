; Audio track-set selection and channel initialization
; CPU range $B875-$B8C5
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

LoadAudioTrackSet0:
    LDX #AudioTrackSet0Offset
    BEQ GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet1:
    LDX #AudioTrackSet1Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet2:
    LDX #AudioTrackSet2Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet3:
    LDX #AudioTrackSet3Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet4:
    LDX #AudioTrackSet4Record - AudioTrackTable
    BNE GuardAudioTrackLoadDuringDemo

LoadAudioTrackSet5:
    LDX #AudioTrackSet5Record - AudioTrackTable
    BNE LoadAudioTrackSetByOffset

LoadAudioTrackSet7:
    LDX #AudioTrackSet7Record - AudioTrackTable

GuardAudioTrackLoadDuringDemo:
    LDA DemoPlaybackActive
    BEQ LoadAudioTrackSetByOffset
    RTS

LoadAudioTrackSetByOffset:
    LDA AudioTrackTable,X
    STA AudioStreamPointerLo
    LDA AudioTrackTable + 1,X
    STA AudioStreamPointerHi
    LDA AudioTrackTable + 2,X
    STA AudioPulse2StreamPointerLo
    LDA AudioTrackTable + 3,X
    STA AudioPulse2StreamPointerHi
    LDA AudioTrackTable + 4,X
    STA AudioTriangleStreamPointerLo
    LDA AudioTrackTable + 5,X
    STA AudioTriangleStreamPointerHi
    LDA AudioTrackTable + 6,X
    STA AudioPulseParameters
    LDA AudioTrackTable + 7,X
    STA AudioPulse2TrackParameters
    LDA #AudioTrackInitialTicks
    STA AudioStreamTicksRemaining
    STA AudioPulse2TicksRemaining
    STA AudioTriangleTicksRemaining
    RTS
