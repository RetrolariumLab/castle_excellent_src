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
  complete room decoder at `$E45D-$E8DE` into `src/game/rooms/decoder.asm`;
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
- [x] reconstruct Reset and the NMI-paced main loop, including cold/warm boot,
  the `POWER`/`POW` signature contract, and the two-NMI frame gate;
- [x] reconstruct the common NMI frame handler, 23-task request scheduler,
  OAM/scroll interlock, controller paths, modular counters, and audio tick;
- [x] reconstruct OAM staging-to-DMA transposition, eight-frame sprite-priority
  rotation, full record reversal, and sized RAM-array operand generation;
- [x] reconstruct the NMI status task, its foreground-formatting interlock,
  three HUD PPU writes, and exact 23-entry handler layout;
- [x] reconstruct all 20 NMI room-row tasks, the 14+6 nametable split, 400 cell
  lookups, and 800 tile writes with an exact independent machine-code model;
- [x] reconstruct both NMI attribute tasks, including 56-byte left upload,
  28-to-52-byte right-edge expansion, and timing compensation;
- [x] reconstruct castle-map input, all 100 visited/current marker positions,
  and the room-display finalizer that requests all 23 NMI tasks;
- expand the first deterministic FCEUX CDL/Ghidra reconciliation into broad
  title, gameplay, transition, death, ending, and save/load scenarios;
- classify every PRG byte as code, typed data, text, or padding;
- promote proven system, game, rendering, audio, room, object, and vector
  ranges into semantic modules while preserving one address-ordered translation
  unit;
- complete RAM and routine maps;
- maintain an original-to-current label provenance ledger;
- add focused runtime scenarios for title, gameplay, death, room transitions,
  sub-command, ending, and save/load.

## Semantic reconstruction 2.0

- lossless decode/encode for all 100 room streams;
- typed object definitions and runtime-record contracts;
- collision, movement, lift, water, door, key, and enemy state machines;
- graphics, palette, metasprite, text, and audio authoring formats;
- Castlequest USA revision alignment and byte-identical profile.
