; Address-ordered 32 KiB CHR payload
; Banks 2 and 3 contain compressed room bitstreams as well as cartridge data

.segment "CHR"

.if CASTLEQUEST_USA
    .incbin "assets/generated/revisions/castlequest-usa/chr/castlequest.chr"
.else
    .incbin "assets/generated/chr/castle_excellent.chr"
.endif
