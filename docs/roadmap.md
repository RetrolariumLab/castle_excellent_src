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
