; Address-ordered 32 KiB CHR payload
; Banks 2 and 3 contain compressed room bitstreams as well as cartridge data

.segment "CHR"

    .incbin "assets/generated/chr/castle_excellent.chr"
