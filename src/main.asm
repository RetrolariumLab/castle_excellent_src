; Castle Excellent / Castlequest NES source, assembled through a revision's
; entry file, src/revisions/<id>.asm

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
.include "ui/screen_text.inc"
.include "memory/object_types.inc"
.include "memory/ram.inc"

; The PRG modules in CPU order; the tail pads up to the fixed tile tables
.segment "PRG"

PrgStart:
.include "system/famicom_platform.asm"
.include "game/player/input_and_movement.asm"
.include "game/player/transitions_and_push.asm"
.include "game/objects/lifts/linked_control.asm"
.include "game/collectibles/pickups_and_rewards.asm"
.include "game/collision/player_pipeline.asm"
.include "game/collision/handlers.asm"
.include "game/runtime/frame_pipeline.asm"
.include "game/objects/lifts/movement.asm"
.include "game/objects/enemies/patrol.asm"
.include "game/objects/enemies/special.asm"
.include "game/collision/sampling.asm"
.include "game/session_initialization.asm"
.include "game/rooms/mutable_cells.asm"
.include "game/rooms/navigation_and_rules.asm"
.include "rendering/sprites/frame.asm"
.include "rendering/sprites/selectors.asm"
.include "rendering/sprites/metasprites.asm"
.include "rendering/scenes.asm"
.include "audio/music_engine.asm"
.include "audio/sound_effects.asm"
.include "rendering/frame_pipeline.asm"
.include "rendering/room_rows/top.asm"
.include "rendering/room_rows/upper_middle.asm"
.include "rendering/room_rows/lower_middle.asm"
.include "rendering/room_rows/bottom.asm"
.include "rendering/rooms/upload_and_decode.asm"
.include "rendering/rooms/attributes_and_map.asm"
.include "game/rooms/load_pipeline.asm"
.include "game/rooms/state_and_data.asm"
.include "ui/title_and_subcommands.asm"
.include "game/persistence_and_endings.asm"
.include "system/prg_tail.asm"

.include "graphics/chr.asm"
