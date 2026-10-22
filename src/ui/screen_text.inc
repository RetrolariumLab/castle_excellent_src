; Screen text: letters A-Z are tiles $71-$8A and a space is tile $FF; the
; printer stops at $00, which the macro appends

.macro ScreenText text
    .repeat .strlen(text), index
        .if .strat(text, index) = ' '
            .byte $FF
        .else
            .byte .strat(text, index) + $30
        .endif
    .endrepeat
    .byte $00
.endmacro
