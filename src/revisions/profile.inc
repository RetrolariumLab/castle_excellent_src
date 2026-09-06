; Build-time constants that differ between supported cartridge revisions
; The default remains the Source Reconstruction 1.0 Japanese HSP-05 image

.ifndef CASTLEQUEST_USA
CASTLEQUEST_USA = 0
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
