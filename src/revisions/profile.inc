; Build-time constants that differ between supported cartridge revisions

.ifndef CASTLEQUEST_USA
    .error "assemble a revision's entry file, src/revisions/<id>.asm"
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

; Fixed PRG landmarks used to keep the tail tables and vectors in place
PrgBaseAddress = $8000
PrgTileTablesAddress = $FF30
