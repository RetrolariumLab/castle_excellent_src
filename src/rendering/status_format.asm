; HUD score, lives, and inventory formatting
; CPU range $A497-$A572
; Generated deterministically from pinned Ghidra/GhidraNes facts
; Keep byte-identical through make verify

FormatHighScoreStatusTiles:
    JSR BeginStatusTileFormatting
    LDA HighScoreLo
    STA ScoreRemainderLo
    LDA HighScoreHi
    STA ScoreRemainderHi
    JMP FormatSelectedScore

FormatPlayerStatusTiles:
    JSR BeginStatusTileFormatting
    LDA PlayerScoreLo
    STA ScoreRemainderLo
    LDA PlayerScoreHi
    STA ScoreRemainderHi

FormatSelectedScore:
    LDX #$00

StartNextScoreDigit:
    SEC

SubtractScorePlaceValue:
    LDA ScoreRemainderLo
    SBC DecimalPlaceValueLowBytes,X
    STA ScoreRemainderLo
    LDA ScoreRemainderHi
    SBC DecimalPlaceValueHighBytes,X
    STA ScoreRemainderHi
    BCC RestoreScoreRemainder
    INC StatusScoreTiles,X
    BCS SubtractScorePlaceValue

RestoreScoreRemainder:
    LDA ScoreRemainderLo
    ADC DecimalPlaceValueLowBytes,X
    STA ScoreRemainderLo
    LDA ScoreRemainderHi
    ADC DecimalPlaceValueHighBytes,X
    STA ScoreRemainderHi
    INX
    CPX #StatusScoreTileCount
    BCC StartNextScoreDigit
    LDX #(StatusScoreTileCount - 1)

EncodeScoreDigitTiles:
    LDA StatusScoreTiles,X
    CLC
    ADC #StatusDigitTileZero
    STA StatusScoreTiles,X
    DEX
    BPL EncodeScoreDigitTiles
    LDX #$00

BlankLeadingScoreZeroes:
    LDA StatusScoreTiles,X
    CMP #StatusDigitTileZero
    BNE FormatLivesStatusTiles
    LDA #StatusBlankTile
    STA StatusScoreTiles,X
    INX
    CPX #StatusScoreTileCount
    BCC BlankLeadingScoreZeroes

FormatLivesStatusTiles:
    LDA #StatusDigitTileZero
    STA StatusLivesTiles
    STA StatusLivesTiles + $01
    STA StatusLivesTiles + $02
    LDA PlayerLives

CountLifeHundreds:
    CMP #DecimalHundreds
    BCC CountLifeTens
    SBC #DecimalHundreds
    INC StatusLivesTiles + $02
    JMP CountLifeHundreds

CountLifeTens:
    CMP #DecimalTens
    BCC EncodeLifeOnes
    SBC #DecimalTens
    INC StatusLivesTiles + $01
    JMP CountLifeTens

EncodeLifeOnes:
    CLC
    ADC #StatusDigitTileZero
    STA StatusLivesTiles
    LDX #(StatusLivesFormattedTileCount - 1)

BlankLeadingLifeZeroes:
    LDA StatusLivesTiles,X
    CMP #StatusDigitTileZero
    BNE FormatInventoryStatusTiles
    LDA #StatusBlankTile
    STA StatusLivesTiles,X
    DEX
    BNE BlankLeadingLifeZeroes

FormatInventoryStatusTiles:
    LDX #(StatusInventoryTileCount - 1)

ClampNextInventoryValue:
    LDA PlayerInventoryCounts,X
    CMP #StatusInventoryMaxValue
    BCC EncodeInventoryTile
    LDA #StatusInventoryMaxValue

EncodeInventoryTile:
    CLC
    ADC #StatusDigitTileZero
    STA StatusInventoryTiles,X
    DEX
    BPL ClampNextInventoryValue
    LDA #StatusTilesReady
    STA StatusTilesBusy
    RTS

DecimalPlaceValueHighBytes:
    .byte $27, $03, $00, $00, $00

DecimalPlaceValueLowBytes:
    .byte $10, $E8, $64, $0A, $01

MutableCellStateBitMasks:
    .byte $01, $02, $04, $08, $10, $20, $40, $80

BeginStatusTileFormatting:
    LDA #StatusTilesLocked
    STA StatusTilesBusy
    LDA #$00
    LDX #(StatusScoreBufferSize - 1)

ClearStatusScoreBuffer:
    STA StatusScoreTiles,X
    DEX
    BPL ClearStatusScoreBuffer
    RTS
