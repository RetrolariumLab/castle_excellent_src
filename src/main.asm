; Castle Excellent (Japan) NES source-reconstruction entrypoint

.setcpu "6502"

.segment "HEADER"

    .byte "NES", $1A  ; iNES magic
    .byte $02  ; two 16 KiB PRG-ROM banks
    .byte $04  ; four 8 KiB CHR-ROM banks
    .byte $31  ; mapper 3, vertical mirroring
    .byte $00  ; upper mapper bits
    .byte $00  ; PRG-RAM size (legacy field)
    .byte $00  ; NTSC
    .byte $00, $00, $00, $00, $00, $00

.include "memory/hardware.inc"
.include "revisions/profile.inc"
.include "memory/ram.inc"

.include "input/famicom_data_pulse.asm"
.include "graphics/chr.asm"
