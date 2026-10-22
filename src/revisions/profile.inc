; Build-time constants that differ between supported cartridge revisions

.ifndef CASTLEQUEST_USA
    .error "assemble a revision's entry file, src/revisions/<id>.asm"
.endif

.if CASTLEQUEST_USA
InitialPlayerLives = 50
SubCommandSelectionCount = 3
SubCommandLastSelection = 2
.else
InitialPlayerLives = 3
SubCommandSelectionCount = 5
SubCommandLastSelection = 4
.endif

; Fixed PRG landmarks used to keep the tail tables and vectors in place
PrgBaseAddress = $8000
PrgTileTablesAddress = $FF30
