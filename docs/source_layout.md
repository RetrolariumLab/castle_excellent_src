# Source layout and symbols

The source is one address-ordered PRG translation unit. Its 33 PRG modules own
every byte from `$8000` through `$FFFF` exactly once; the CPU spans are the
original image's (a module that grows moves the ones after it).

| Module | Original CPU span | Responsibility |
| --- | --- | --- |
| `src/system/famicom_platform.asm` | `$8000-$82CD` | Famicom platform transport, PPU, and startup |
| `src/game/player/input_and_movement.asm` | `$82CE-$8679` | Player input and movement |
| `src/game/player/transitions_and_push.asm` | `$867A-$89E0` | Player room transitions and object pushing |
| `src/game/objects/lifts/linked_control.asm` | `$89E1-$8C11` | Linked lift control |
| `src/game/collectibles/pickups_and_rewards.asm` | `$8C12-$8DAA` | Collectible collision, inventory, and rewards |
| `src/game/collision/player_pipeline.asm` | `$8DAB-$903E` | Player collision sampling and downward handlers |
| `src/game/collision/handlers.asm` | `$903F-$93F5` | Upward, horizontal, and shared collision handlers and the per-frame update |
| `src/game/runtime/frame_pipeline.asm` | `$93F6-$965B` | Player transition and object frame pipeline |
| `src/game/objects/lifts/movement.asm` | `$965C-$9A36` | Pushable and lift movement |
| `src/game/objects/enemies/patrol.asm` | `$9A37-$9D64` | Platform and walking enemy patrol behaviors |
| `src/game/objects/enemies/special.asm` | `$9D65-$A043` | Special enemy behaviors and transient lifecycle |
| `src/game/collision/sampling.asm` | `$A044-$A2B0` | Room and runtime object collision sampling |
| `src/game/session_initialization.asm` | `$A2B1-$A589` | New game, room initialization, animation, and status formatting |
| `src/game/rooms/mutable_cells.asm` | `$A58A-$A7DA` | Mutable room cell coordinates, actions, and restoration |
| `src/game/rooms/navigation_and_rules.asm` | `$A7DB-$AC12` | Room navigation and player interaction rules |
| `src/rendering/sprites/frame.asm` | `$AC13-$ADE6` | Frame sprite construction |
| `src/rendering/sprites/selectors.asm` | `$ADE7-$B1D5` | Object sprite selectors |
| `src/rendering/sprites/metasprites.asm` | `$B1D6-$B64B` | Object metasprites and descriptor data |
| `src/rendering/scenes.asm` | `$B64C-$B874` | Room screen and title demo scenes |
| `src/audio/music_engine.asm` | `$B875-$C20C` | Music selection, stream engine, tables, and MML data |
| `src/audio/sound_effects.asm` | `$C20D-$C43C` | Sound effect engine and tables |
| `src/rendering/frame_pipeline.asm` | `$C43D-$C8BB` | Scroll, palette, NMI, OAM, and status rendering pipeline |
| `src/rendering/room_rows/top.asm` | `$C8BC-$CF0A` | Room row upload tasks 00 through 04 |
| `src/rendering/room_rows/upper_middle.asm` | `$CF0B-$D559` | Room row upload tasks 05 through 09 |
| `src/rendering/room_rows/lower_middle.asm` | `$D55A-$DBA8` | Room row upload tasks 10 through 14 |
| `src/rendering/room_rows/bottom.asm` | `$DBA9-$E1F7` | Room row upload tasks 15 through 19 |
| `src/rendering/rooms/upload_and_decode.asm` | `$E1F8-$E8DE` | Room attribute upload and compressed map decoding |
| `src/rendering/rooms/attributes_and_map.asm` | `$E8DF-$EB6B` | Room attributes and castle map |
| `src/game/rooms/load_pipeline.asm` | `$EB6C-$EDEE` | Room finalization, object loading, and persistent-state application |
| `src/game/rooms/state_and_data.asm` | `$EDEF-$F8FB` | Mutable state, persistent state, and room object data |
| `src/ui/title_and_subcommands.asm` | `$F8FC-$FBFD` | Title screen and sub-command interface |
| `src/game/persistence_and_endings.asm` | `$FBFE-$FEE7` | Save, load, persistent snapshots, and ending sequences |
| `src/system/prg_tail.asm` | `$FEE8-$FFFF` | Fixed PRG tail, room tile tables, and interrupt vectors |

`src/main.asm` owns the iNES header and includes the PRG modules above in CPU
order (each revision's entry file, `src/revisions/<id>.asm`, includes it), while
`src/graphics/chr.asm` includes the four private 8 KiB CHR banks.
`src/memory/hardware.inc`, `src/memory/ram.inc`, and
`src/revisions/profile.inc` emit no bytes.

## Module policy

PRG modules target 300–700 lines, a few cohesive ones are shorter, and no two
source names in one directory share their first underscore-delimited word.
The four room-row upload modules stay parallel rather than merged: each is a
complete unrolled group of five NMI tasks, in `rendering/room_rows`.

## Maintaining the source

Releases 1.0 to 3.0 regenerated every module from pinned Ghidra facts, a symbol
ledger, RAM aliases and operand overrides, and audited the result; that pipeline
and its ledgers remain at those tags. From 3.1 the source is the authority and
is edited directly: `make test` rebuilds every ROM byte for byte, and
`make test-full` plays the attract mode on a build whose routines all moved
(`make build-relocated`).

`src/memory/ram.inc` names the RAM and I/O addresses; [ram_map.md](ram_map.md)
describes lifetimes, overlaps and subsystem contracts. Bytes without a stable
meaning stay unnamed rather than receiving speculative names. Proven entry
points inside an existing instruction remain ca65 offset symbols such as
`Label_E5A1 = * + 1`.
