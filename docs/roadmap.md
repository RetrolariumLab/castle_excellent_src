# Roadmap

## Bootstrap scaffold (complete)

- CNROM linker and private-asset build boundary;
- exact complete-file and region identity profile;
- safe split, inspect, verify, lint, and test commands;
- documented room/object architecture;
- tested prefix-code decoder;
- initial debugger watch and breakpoint sets.

## Preservation baseline (complete)

- pinned local Ghidra 12.1.3 and GhidraNes loader;
- reproducible headless import and instruction-fact export;
- byte-identical address-ordered ca65 PRG listing;
- symbolic direct branch, jump, and call targets;
- initial semantic naming for interrupts, rooms, objects, and data tables;
- dependency-free `make format` and strict `make lint`;
- generate native debugger symbols;
- freeze `make verify` as the permanent gate.

## Source reconstruction 1.0

- [x] establish a contiguous multi-file source-layout contract and promote the
  complete room decoder at `$E45D-$E8DE` into `src/rendering/rooms/upload_and_decode.asm`;
- [x] add deterministic global and address-scoped RAM/I/O operand naming;
- [x] promote `$E8DF-$EA35` into a semantic room attribute module and
  independently reconstruct both 64-byte attribute buffers for all 100 rooms;
- [x] promote `$EB8F-$EC62` into a semantic static-object loader and prove all
  100 object-list terminators, lookup-table overlap, and runtime-pool capacity;
- [x] promote the `$EDD2-$EDEE` stream seeker and `$EF06-$F8FB` object data,
  add an exact object-stream encoder, and prove one persistent bit per object;
- [x] reconstruct the paired room-state loader/saver, both nine-byte snapshots,
  and the 108-byte persistent mutable-cell bitmap with its 101 offsets;
- [x] reconstruct persistent-state application, mutable-cell predicates,
  object-count/stride tables, and all five cell-derived runtime-object types;
- [x] reconstruct the top-level room-loading vertical slice, including NMI
  request reset, screen initialization, status data, and snapshot rotation;
- [x] reconstruct both controller pollers, fixed PPU mode helpers, and the
  four-entry CNROM bank-select table with exhaustive input-model checks;
- [x] reconstruct both Famicom save-data transports, their pulse and expansion
  serial formats, common byte wrappers, preamble, and error-return contracts;
- [x] reconstruct the 394-byte save payload, reversed RAM traversals, exact
  `BEDEUTUN` signature, load-error path, and post-load room restoration;
- [x] reconstruct pixel/tile/cell addressing, one-based mutable-cell lookup,
  both restored cell forms, persistent-bit updates, and render requests;
- [x] reconstruct shared 16-bit player/object X probes and exhaustively verify
  their register order, offsets, carry, borrow, and wraparound;
- [x] reconstruct room-transition completion, runtime-type filtering, and
  mutable-cell collision normalization with exhaustive flag-preservation tests;
- [x] reconstruct the `$A6CA-$A6D7` doubled cell-index classifier and prove
  its exact `$8A-$91` match domain across every possible X value;
- [x] reconstruct all six inventory-backed persistent-cell actions, their
  pointer-table provenance, stack-unwind guard, alignment, and boundary delay;
- [x] reconstruct one-based movement across the 10x10 castle room grid and
  prove both ten-entry horizontal edge tables across all 100 rooms;
- [x] reconstruct all four player room-boundary routes, aligned entry state,
  castle-edge X clamps, room reload order, and horizontal mutable-cell repair;
- [x] reconstruct player jump, gravity, horizontal input/collision dispatch,
  ten-frame action state, and the complete 24-record action-hit scan;
- [x] reconstruct player-driven horizontal object pushing, support/clearance
  probes, world bounds, destroyable obstructions, and synchronized movement;
- [x] reconstruct type-`$8E` linked-lift control, paired `$A4/$A5` discovery,
  track-cell edits, transitive occupant closure, and two-pixel movement;
- [x] separate the active unknown registry from resolved evidence and reduce it
  to the questions that can still change public contracts;
- [x] prove all 100 compressed-room physical boundaries, byte-exact encoding,
  one-filled final-byte padding, and fixed CHR-bank arena capacity;
- [x] generate Mesen/FCEUX symbols, resolve every configured watch/breakpoint
  against ld65 output, and prove live lookup plus a named NMI execution hook;
- [x] reconstruct player protection countdown decay, room-audio restoration,
  and bottom-center hazard contact across all coordinates and room cells;
- [x] reconstruct the shared runtime-object/player proximity predicate, all 15
  call sites, exclusive thresholds, and original negative-page alias behavior;
- [x] reconstruct pause/resume edge handling, APU shutdown, and paused
  four-pixel horizontal scrolling across complete input/state domains;
- [x] classify both 100x2 room-cell collision-flag tables and the 48-entry
  runtime-object width/height tables, including all 18 exact consumers;
- [x] reconstruct the 24-record runtime-object update dispatcher, its manual
  indirect-call convention, and all 42 handler pointers;
- [x] reconstruct new-game state initialization, physical persistent-region
  clears, partial mirror/snapshot writes, lives, and room-palette fallthrough;
- [x] reconstruct room-runtime reset ownership and the game-over/stream-pointer
  guard that conditionally restarts room audio;
- [x] reconstruct both full-room cell-animation scans, opposite four-phase
  directions, intermittent cadence, and NMI row-redraw requests;
- [x] reconstruct high-score/current-score identity, five-digit HUD conversion,
  life and inventory formatting, and the foreground/NMI buffer interlock;
- [x] reconstruct Reset and the NMI-paced main loop, including cold/warm boot,
  the `POWER`/`POW` signature contract, and the two-NMI frame gate;
- [x] reconstruct the common NMI frame handler, 23-task request scheduler,
  OAM/scroll interlock, controller paths, modular counters, and audio tick;
- [x] reconstruct the textual MML stream interpreter, three channel-state
  lanes, restart pointers, channel gating, and streamed-note APU setup;
- [x] reconstruct all five sound-effect starters, the per-frame channel
  arbiter, three step counters, and five period/envelope tables;
- [x] reconstruct the player-following horizontal camera curve, shared unsigned
  16-bit divider, and exact 32-byte PPU palette uploader;
- [x] classify the detached five-byte runtime-object-clear-shaped tail at
  `$8C7B-$8C7F` as unreferenced typed data and prove it has no reachable entry;
- [x] reconstruct OAM staging-to-DMA transposition, eight-frame sprite-priority
  rotation, full record reversal, and sized RAM-array operand generation;
- [x] reconstruct frame-sprite staging, player/action descriptor selection,
  24-record object render dispatch, and the overlapping 42-entry pointer table;
- [x] promote all 41 per-type sprite selectors with named state/frame branches,
  shared indexes 29/30, and the unreachable type-09 tail kept as typed data;
- [x] correlate encoded room types, loader states, runtime indexes, update and
  sprite dispatch, collision dimensions, room use, and cell-marker sources;
- [x] reconstruct the shared player/object-span test, its saturated 16-bit X
  bounds, 16-pixel Y interval, and all three direct callers;
- [x] reconstruct pushable-object gravity, conveyor displacement, support
  crushing, and the lift-control type's shared update wrapper;
- [x] reconstruct small and large lift cell movement, endpoint reversal, and
  transitive runtime-object/player occupant propagation;
- [x] reconstruct the cell-derived Flying Block, its paired leading-edge
  probes, two-pixel horizontal motion, reversal, and trapped stop state;
- [x] reconstruct shared walking-enemy gravity, support, hazard, wall/ledge
  probes, and the Bishop's two-pixel patrol entry;
- [x] reconstruct Knight facing/cadence gates, free-slot scan, and directional
  arrow creation;
- [x] reconstruct Fairy frame bobbing and Fighter proximity-triggered jump,
  shared patrol calls, and three-point rising collision checks;
- [x] reconstruct Flame axis tracking, vertical probes, shared walking-enemy
  edge probes, and biased player-X separation;
- [x] reconstruct Witch summon placement, four-corner collision checks, dynamic
  slot allocation, and the delayed Fighter/Bishop/Knight replacement lifecycle;
- [x] reconstruct Knight arrow world bounds, mirrored three-pixel movement,
  two-point leading-edge probes, and collision cleanup;
- [x] reconstruct transient runtime types 32, 40, and 41, including type
  replacement, state lifetime, odd-frame motion, and full-record clearing;
- [x] reconstruct animated-cell direction classification and both runtime-type
  collision filters, including their overlapping logical table tails;
- [x] reconstruct the resumable 24-record runtime-object overlap scan, exact
  dimension bounds, active-type filter, and shared carry/no-op return;
- [x] reconstruct five common metasprite composition paths, horizontal page
  clipping/OAM compaction, and all 203 tile/attribute descriptor pairs;
- [x] reconstruct the NMI status task, its foreground-formatting interlock,
  three HUD PPU writes, and exact 23-entry handler layout;
- [x] reconstruct all 20 NMI room-row tasks, the 14+6 nametable split, 400 cell
  lookups, and 800 tile writes with an exact independent machine-code model;
- [x] reconstruct both NMI attribute tasks, including 56-byte left upload,
  28-to-52-byte right-edge expansion, and timing compensation;
- [x] reconstruct castle-map input, all 100 visited/current marker positions,
  and the room-display finalizer that requests all 23 NMI tasks;
- [x] expand the first deterministic FCEUX CDL/Ghidra reconciliation into broad
  title, gameplay, transition, death, ending, and save/load scenarios;
- [x] add a declarative Source Reconstruction 1.0 manifest and one candidate
  gate covering static checks, live symbols, fresh runtime, and release policy;
- [x] close the six-byte runtime-object ABI, including polymorphic primary
  state and all five proven auxiliary-state interpretations;
- [x] classify every PRG byte as code, typed data, text, or padding;
- [x] promote proven system, game, rendering, audio, room, object, and vector
  ranges into semantic modules while preserving one address-ordered translation
  unit;
- [x] complete machine-readable PRG routine/label and RAM/I/O maps, with every
  PRG symbol owned by exactly one source region;
- [x] maintain the original-Ghidra-to-current label provenance join by fixed
  CPU address and enforce its exact Source 1.0 counts in the release audit;

## Semantic reconstruction 2.0

- relocatable room-stream authoring and repacking beyond the fixed 1.0 arenas;
- friendly object identities and higher-level typed object authoring;
- collision, movement, water, door, key, and enemy state machines;
- graphics, palette, metasprite, text, and audio authoring formats;
- Castlequest USA revision alignment and byte-identical profile.
