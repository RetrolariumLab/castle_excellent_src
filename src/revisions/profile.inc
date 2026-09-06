; Build-time constants that differ between supported cartridge revisions
; The default remains the Source Reconstruction 1.0 Japanese HSP-05 image

.ifndef CASTLEQUEST_USA
CASTLEQUEST_USA = 0
.endif

.if CASTLEQUEST_USA
    .define RevisionTitlePaletteAsset "assets/generated/revisions/castlequest-usa/prg/title_palette.bin"
    .define RevisionSubCommandTextAsset "assets/generated/revisions/castlequest-usa/prg/sub_command_text.bin"
InitialPlayerLives = 50
SubCommandSelectionCount = 3
SubCommandLastSelection = 2
.else
    .define RevisionTitlePaletteAsset "assets/generated/revisions/castle-excellent-japan-hsp-05/prg/title_palette.bin"
    .define RevisionSubCommandTextAsset "assets/generated/revisions/castle-excellent-japan-hsp-05/prg/sub_command_text.bin"
InitialPlayerLives = 3
SubCommandSelectionCount = 5
SubCommandLastSelection = 4
.endif
