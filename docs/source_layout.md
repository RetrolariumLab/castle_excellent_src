# Source layout

The source is one canonical address-ordered PRG translation unit. Its 32 PRG
modules own every byte from `$8000` through `$FFFF` exactly once.

| Module | CPU span | Lines | Responsibility |
| --- | --- | ---: | --- |
| `src/system/famicom_platform.asm` | `$8000-$82CD` | 511 | Famicom platform transport, PPU, and startup |
| `src/game/player/input_and_movement.asm` | `$82CE-$8679` | 559 | Player input and movement |
| `src/game/player/transitions_and_push.asm` | `$867A-$89E0` | 521 | Player room transitions and object pushing |
| `src/game/objects/lifts/linked_control.asm` | `$89E1-$8C11` | 346 | Linked lift control |
| `src/game/collectibles/pickups_and_rewards.asm` | `$8C12-$8DAA` | 284 | Collectible collision, inventory, and rewards |
| `src/game/collision/player_pipeline.asm` | `$8DAB-$93F5` | 386 | Player collision pipeline |
| `src/game/runtime/frame_pipeline.asm` | `$93F6-$965B` | 364 | Player transition and object frame pipeline |
| `src/game/objects/lifts/movement.asm` | `$965C-$9A36` | 587 | Pushable and lift movement |
| `src/game/objects/enemies/patrol.asm` | `$9A37-$9D64` | 504 | Platform and walking enemy patrol behaviors |
| `src/game/objects/enemies/special.asm` | `$9D65-$A043` | 478 | Special enemy behaviors and transient lifecycle |
| `src/game/collision/sampling.asm` | `$A044-$A2B0` | 378 | Room and runtime object collision sampling |
| `src/game/session_initialization.asm` | `$A2B1-$A589` | 421 | New game, room initialization, animation, and status formatting |
| `src/game/rooms/mutable_cells.asm` | `$A58A-$A7DA` | 399 | Mutable room cell coordinates, actions, and restoration |
| `src/game/rooms/navigation_and_rules.asm` | `$A7DB-$AC12` | 327 | Room navigation and player interaction rules |
| `src/rendering/sprites/frame.asm` | `$AC13-$ADE6` | 237 | Frame sprite construction |
| `src/rendering/sprites/selectors.asm` | `$ADE7-$B1D5` | 664 | Object sprite selectors |
| `src/rendering/sprites/metasprites.asm` | `$B1D6-$B64B` | 486 | Object metasprites and descriptor data |
| `src/rendering/scenes.asm` | `$B64C-$B874` | 245 | Room screen and title demo scenes |
| `src/audio/music_engine.asm` | `$B875-$C20C` | 629 | Music selection, stream engine, tables, and MML data |
| `src/audio/sound_effects.asm` | `$C20D-$C43C` | 291 | Sound effect engine and tables |
| `src/rendering/frame_pipeline.asm` | `$C43D-$C8BB` | 561 | Scroll, palette, NMI, OAM, and status rendering pipeline |
| `src/rendering/room_rows/top.asm` | `$C8BC-$CF0A` | 559 | Room row upload tasks 00 through 04 |
| `src/rendering/room_rows/upper_middle.asm` | `$CF0B-$D559` | 559 | Room row upload tasks 05 through 09 |
| `src/rendering/room_rows/lower_middle.asm` | `$D55A-$DBA8` | 559 | Room row upload tasks 10 through 14 |
| `src/rendering/room_rows/bottom.asm` | `$DBA9-$E1F7` | 559 | Room row upload tasks 15 through 19 |
| `src/rendering/rooms/upload_and_decode.asm` | `$E1F8-$E8DE` | 438 | Room attribute upload and compressed map decoding |
| `src/rendering/rooms/attributes_and_map.asm` | `$E8DF-$EB6B` | 354 | Room attributes and castle map |
| `src/game/rooms/load_pipeline.asm` | `$EB6C-$EDEE` | 363 | Room finalization, object loading, and persistent-state application |
| `src/game/rooms/state_and_data.asm` | `$EDEF-$F8FB` | 345 | Mutable state, persistent state, and room object data |
| `src/ui/title_and_subcommands.asm` | `$F8FC-$FBFD` | 414 | Title screen and sub-command interface |
| `src/game/persistence_and_endings.asm` | `$FBFE-$FEE7` | 380 | Save, load, persistent snapshots, and ending sequences |
| `src/system/prg_tail.asm` | `$FEE8-$FFFF` | 41 | Fixed PRG tail, room tile tables, and interrupt vectors |

The non-PRG entrypoint `src/main.asm` owns the iNES header and canonical include,
while `src/graphics/chr.asm` includes the four private 8 KiB CHR banks.
`src/memory/hardware.inc`, `src/memory/ram.inc`, and
`src/revisions/profile.inc` emit no bytes.

## Module policy

Semantic PRG modules target 300–700 lines. The reconstruction audit rejects a
larger module, a smaller module without an explicit `size_exception` in
`config/reconstruction/source_layout.json`, or two source names with the same first
underscore-delimited word in one directory. This keeps names useful at a glance
and prevents address-era fragments such as repeated `room_*` or `enemy_*`
files from accumulating again.

Five deliberately short modules remain:

| Module | Lines | Reason |
| --- | ---: | --- |
| `src/game/collectibles/pickups_and_rewards.asm` | 284 | The cohesive collectible subsystem is 284 lines; merging either neighbor would mix lift control or player collision state. |
| `src/rendering/sprites/frame.asm` | 237 | The bounded frame-sprite builder is a cohesive 237-line subsystem. |
| `src/rendering/scenes.asm` | 245 | The 253-line scene renderer owns one contiguous room-screen and title-demo span. |
| `src/audio/sound_effects.asm` | 291 | The complete sound-effect engine is 291 lines and its adjacent ranges belong to music data and rendering. |
| `src/system/prg_tail.asm` | 41 | The short fixed-layout tail must remain adjacent to the vectors at the end of PRG. |

The four room-row upload modules are intentionally parallel rather than merged:
each is a complete 559-line unrolled group of five NMI tasks and already falls
inside the target range. Their descriptive names live in a dedicated
`rendering/room_rows` directory without a repeated filename prefix.

## Deterministic regeneration

`config/reconstruction/source_layout.json` is the machine-readable authority. The platform
module declares the PRG segment and includes the following 31 modules in CPU
order. `scripts/workflow/generate_disassembly.py` regenerates every module from pinned
Ghidra facts, named symbols, operand overrides, revision overlays, and typed
source replacements. `make disassembly-check` rejects any stale module.

Ghidra-defined instructions are emitted mnemonically and all other ranges use
`.byte`. Static direct branch, jump, and call operands are labels. Because
Ghidra cannot represent overlapping instructions, proven entry points inside an
existing instruction remain ca65 offset symbols such as
`Label_E5A1 = * + 1`.

`config/reconstruction/memory_symbols.json` makes operand naming deterministic. A global
entry is used everywhere its address appears; an address-scoped entry is used
only inside the proven subsystem range. `config/reconstruction/operand_overrides.json`
records relocatable ca65 expressions together with the exact original operand
and an evidence note; regeneration fails if the underlying instruction changes.

CHR banks 2 and 3 are not purely graphics. Their room bitstreams remain
address-stable and are authored only through the proven level codec.
