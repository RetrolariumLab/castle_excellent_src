# Castle Excellent NES Disassembly

A preservation-first ca65 reconstruction and reverse-engineering workspace for
the Japanese Famicom release of **Castle Excellent** (`HSP-05`). The repository
uses the same baseline structure as the sibling `solomon_no_kagi_src` project:
private ROM inputs, explicit identity checks, a deterministic build, documented
evidence, and tested decoders for game data.

## Current status

- The repository scaffold, CNROM linker layout, manifest, tests, and research
  documentation are in place.
- The local Japanese reference is identified by complete file and region
  hashes; the public physical-chip CRCs agree with it.
- `make split` validates and extracts a legally obtained reference image.
- The complete 32 KiB PRG is represented by one address-ordered ca65
  translation unit generated from pinned headless Ghidra/GhidraNes analysis.
  The proven semantic modules are the room decoder at `$E45D-$E8DE`, room
  attribute construction at `$E8DF-$EA35`, the static-object tables and loader
  at `$EB8F-$EC62`, the stream seeker at `$EDD2-$EDEE`, and object/state data
  at `$EF06-$F8FB`. Persistent room-state offsets, snapshot restore/load, and
  save paths are also semantic modules, together with bitmap application,
  mutable-cell predicates, and cell-derived object creation. The top-level
  room loader, NMI-request reset, room-screen initialization, and room-state
  snapshot orchestration now form a semantic vertical slice. Controller
  polling, PPU mode helpers, and CNROM bank selection are also semantic
  platform modules. Reset and the NMI-paced main loop are reconstructed with
  their cold/warm boot contract and named frame phases. The NMI handler now
  exposes its 23-task scheduler, OAM/scroll synchronization, controller paths,
  modular counters, and audio tick. OAM staging-to-DMA construction and full
  sprite-order reversal are also reconstructed. The first NMI rendering task
  now documents the status interlock and all three HUD tile uploads. Twenty
  consecutive NMI tasks reconstruct the complete 20x20 room into the two
  horizontal nametables. Unresolved ranges remain explicitly named preservation
  sources.
- All direct branches, jumps, and calls use labels; the first semantic names
  cover reset/interrupts, CHR switching, rooms, objects, and core data tables.
- `make build` reconstructs a byte-identical image from the explicit iNES
  header, PRG ASM, and one ignored private CHR input; PRG is no longer included
  as a binary payload.
- `scripts/room_data.py` independently implements the published prefix-code
  room decoder; the exact local reference validates as 100 rooms, 40,000 cells,
  200 nametable attribute tables, and the exactly bounded 783-record static
  object stream. The object stream round-trips all 2,449 bytes and its 101
  cumulative offsets prove 141 bytes of packed object state. A second table
  proves 108 bytes of mutable-cell state across all rooms. Five cell markers
  create 176 additional runtime objects without overflowing the 24-slot pool.
- `scripts/audio_data.py` validates the eight-set music table and all 21
  textual command streams, including their terminators and restart pointers.
- `scripts/room_screen_data.py` validates four status-screen tile streams,
  their code-level pointer loads, and the 16 initial attribute bytes.
- `scripts/controller_input.py` exhaustively validates all 256 controller masks
  through both the D0 path and the D1 fallback used by the original pollers.
- `scripts/startup_state.py` validates the `POWER` ROM signature, the three-byte
  `POW` RAM sentinel, cold/warm reset behavior, and the two-NMI frame gate.
- `scripts/nmi_scheduler.py` validates all 23 handler pointers, request scanning,
  and the eight modular NMI frame counters.
- `scripts/oam_dma.py` validates the 64-sprite interleave, all eight frame
  rotations, the unused sixteenth table byte, and whole-record reversal.
- `scripts/status_upload.py` validates the HUD interlock, destinations, and
  source order for score, inventory, and lives tiles.
- `scripts/room_row_upload.py` validates all 20 unrolled handlers, 400 cell
  lookups, and 800 left/right metatile writes byte-for-byte against the ROM.
- `scripts/room_attribute_upload.py` validates both final NMI tasks, including
  the right-nametable edge expansion and timing delay.
- `scripts/castle_map.py` validates the complete 10x10 visited-room and current
  room marker geometry.
- `make format`, `make lint`, 121 unit tests, reproducible disassembly checks,
  byte identity, and decoding all rooms form the `make check` gate.
- A pinned local FCEUX fork captures native code/data logs; `make trace-boot`
  rejects runtime-executed PRG bytes that Ghidra failed to classify as code.
  The boot/gameplay, title/attract, and idle-timeout suite proves 15,175 code
  bytes, 3,330 data bytes, and 6,283 instruction starts, with zero runtime/static
  disagreements. Evidence-refined Ghidra exports 9,728 instructions after 30
  evidence-backed data ranges remove 183 false-positive instructions.

`assets/manifest.json` records the complete iNES, payload, header, PRG, and CHR
identity. `make verify` validates both images against that independent manifest
and compares every region with the supplied reference byte-for-byte.

## Reference image

The baseline profile is:

```text
Castle Excellent (Japan)
Catalog ID   HSP-05
File size    65,552 bytes for a standard 16-byte iNES header
Payload CRC  7FA2CC55 (headerless PRG + CHR)
Mapper       3 (CNROM), vertical mirroring
PRG          32 KiB, fixed at $8000-$FFFF, CRC32 9FA1C11F
CHR          32 KiB, four switchable 8 KiB banks, CRC32 04A8FF2E
```

ROM images and locally extracted regions are ignored by Git.

## Bootstrap

Place a legally obtained matching ROM in the project root, then run:

```bash
make inspect REFERENCE_ROM="Castle Excellent (J).nes"
make split REFERENCE_ROM="Castle Excellent (J).nes"
make disassemble REFERENCE_ROM="Castle Excellent (J).nes"
make check REFERENCE_ROM="Castle Excellent (J).nes"
```

`make inspect` prints the complete hashes for checking another dump.

## Useful targets

```bash
make scaffold-check  # lint and test without a ROM
make ghidra-bootstrap # install pinned local Ghidra and GhidraNes
make ghidra-inspect  # report loader blocks, functions, and instruction count
make disassemble    # headless analysis and canonical PRG regeneration
make fceux-bootstrap # install the hash-pinned local runtime emulator
make trace-boot     # capture CDL and reconcile execution with Ghidra facts
make trace-title    # capture an independent title/attract-mode CDL
make trace-timeout  # capture an idle game through timeout/death paths
make trace-suite    # run and merge every deterministic runtime scenario
make reconstruction-check # static checks plus a fresh emulator trace
make reconstruction-audit # enforce semantic-module ownership and naming
make format         # normalize ca65 sources and all repository text/JSON
make format-check   # check ca65 style without changing source files
make lint-asm       # check the shared ca65 source-style contract
make lint-source    # check structure, manifests, and binary policy
make lint           # run every formatting and project linter
make test           # run the complete Python unit-test suite
make quality-check  # lint and tests without requiring a reference ROM
make split           # validate and extract private header/PRG/CHR regions
make build           # assemble the complete iNES image from PRG source + CHR
make verify-prg      # compare built and original PRG with CPU-address diagnostics
make verify          # validate and compare every ROM region and extracted asset
make rom-info        # print and validate original and built image identities
make release-check   # quality, source regeneration, ROM, room, screen, input, and audio checks
make rooms           # decode all 100 rooms as JSON
make validate-rooms  # decode every room without writing JSON
make audio           # inspect music track sets and textual streams as JSON
make validate-audio  # validate music grammar, bounds, and restart pointers
make screen-data     # inspect room status-screen tile and attribute data
make validate-screen-data # validate status pointers, terminators, and bounds
make validate-input   # exhaustively validate controller serial-bit semantics
make startup-state    # inspect cold/warm reset and frame-gate state as JSON
make validate-startup # validate POWER/POW and two-NMI main-loop pacing
make nmi-state        # inspect NMI handlers, scheduler, and counters as JSON
make validate-nmi     # validate the NMI scheduling contract
make oam-state        # inspect OAM interleave and rotation as JSON
make validate-oam     # validate staging-to-DMA and reversal transforms
make status-state     # inspect the three NMI HUD writes as JSON
make validate-status  # validate HUD destinations and source order
make room-row-state   # inspect handler, nametable, and row layout as JSON
make validate-room-rows # validate all 20 room-row upload handlers
make attribute-upload-state # inspect both attribute transfers as JSON
make validate-attribute-upload # validate 108 attribute PPU writes
make castle-map-state # inspect the 10x10 map marker geometry
make validate-castle-map # validate all 100 map positions
make clean           # remove build artifacts only
```

## Repository structure

```text
assets/manifest.json       reference identity and private extraction contract
bin/                       local ca65/ld65 toolchain and license
config/linker/cnrom.cfg    complete iNES/PRG/CHR linker layout
config/symbols.json        evidence-ranked initial semantic naming
config/memory_symbols.json global and address-scoped RAM/I/O operand naming
config/operand_overrides.json evidence-backed relocatable operand expressions
config/source_layout.json  contiguous generated PRG source-region contract
config/runtime_evidence.txt tracked code/data ranges observed by FCEUX
config/prg_data_ranges.txt typed data ranges removed from Ghidra code output
config/debugger_*.json     initial Mesen breakpoints and RAM watches
docs/                      architecture, formats, evidence, and roadmap
scripts/bootstrap_ghidra.py pinned local toolchain installer
scripts/bootstrap_fceux.py pinned runtime-emulator installer
scripts/run_ghidra.py      deterministic headless import and fact export
scripts/generate_disassembly.py Ghidra facts to canonical ca65 source
scripts/runtime_coverage.py FCEUX CDL capture and static/runtime reconciliation
scripts/asm_style.py       shared ca65 formatter and linter
scripts/format_project.py  dependency-free formatting contract
scripts/project.py         inspect, split, build-support, verify, and lint tools
scripts/verify_rom.py      focused image/region comparison diagnostics
scripts/room_data.py       100-room prefix-code decoder
scripts/room_screen_data.py room status-screen data validator
scripts/controller_input.py controller serial-polling model
scripts/audio_data.py      music table and textual-stream validator
src/main.asm               assembly entrypoint
src/preservation/prg.asm   PRG entry region and ordered module includes
src/input/controllers.asm  controller wrappers and eight-bit serial polling
src/system/ppu.asm         PPU mode helpers and CNROM bank selection
src/system/startup.asm     reset signature, initialization, and main frame loop
src/system/nmi.asm         NMI task scheduler, input, OAM, scroll, and audio tick
src/rendering/oam_dma.asm  64-sprite DMA interleave and order transforms
src/rendering/status_upload.asm NMI HUD upload and task-handler tables
src/rendering/room_rows_*.asm  twenty complete NMI room-row upload tasks
src/rendering/room_attribute_upload.asm final two NMI attribute tasks
src/ui/castle_map.asm      map input, visited rooms, and current-room marker
src/game/rooms/finalize_room.asm room display and 23 NMI task requests
src/game/rooms/decoder.asm proven room codebook, pointers, and decoder
src/game/rooms/load_room.asm top-level room-loading orchestration
src/game/rooms/state_orchestration.asm snapshot selection and rotation
src/game/rooms/persistent_state_*.asm offsets plus apply/load/save paths
src/game/rooms/mutable_cell_*.asm predicates and state restoration
src/rendering/room_attributes.asm proven room attribute-table construction
src/rendering/room_screen.asm nametable, status, attribute, and OAM setup
src/system/nmi_tasks.asm   NMI task-request reset
src/game/objects/room_loader.asm proven static-object expansion into RAM
src/game/objects/stream_seek.asm proven terminated-list stream navigation
src/game/objects/room_data.asm typed object lists and persistent-state offsets
src/preservation/prg_*.asm unresolved address-bounded PRG regions
src/graphics/chr.asm       private CHR include (graphics plus room streams)
src/memory/                hardware and RAM symbol registries
tests/                     tooling and decoder tests
tools/disassembly.lock.json exact Ghidra and GhidraNes supply-chain lock
tools/runtime.lock.json exact FCEUX runtime artifact lock
tools/ghidra_scripts/      tracked headless analysis exporters
```

## Research sources and rights

The main published analysis and extractor are:

- <https://habr.com/ru/articles/991848/>
- <https://github.com/wizzard2010/cex>

The upstream extractor had no explicit license when inspected. Local research
clones live under ignored `references/` and are not part of this repository.
Original game code, graphics, music, and room data remain property of their
respective rights holders.
