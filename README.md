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
  snapshot orchestration now form a semantic vertical slice. Pixel-to-tile
  conversion, room-cell addressing, mutable-anchor lookup, and ordinal-based
  restoration are reconstructed with their persistence/render side effects.
  The primary player collision sampler now owns its 320x160 screen-to-room
  transform, player-specific cell flags, 24-record object scan, restricted
  `$90-$95` mode, and phase-dependent type-`$86` geometry.
  A separate 115-byte runtime-object-only sampler is reconstructed as
  unreferenced code: no call, pointer table, fallthrough, or captured runtime
  path reaches it, and its Japanese/USA bytes are identical.
  The shared death handler now exposes its animated-cell phase predicate,
  invulnerability/transition guard, 128-frame transition, action reset,
  reserve-life branch, game-over latch, and death-audio selection for all 61
  collision-table identities.
  Frame-level collision orchestration now names all seven ordered player probes,
  their sample/dispatch pairs, the active-transition bypass, and the final
  protected-hazard death decision.
  Transition completion now restores saved player coordinates, extends hazard
  protection, selects game over or a complete persistent-state room reload,
  and documents the exact rendering-resume order.
  Runtime collision types `$81` and `$82` now expose their shared proximity and
  audio waits: `$81` transforms into type `$91` and creates a room-`$59` clone,
  while `$82` discards the synthetic dispatcher return and enters the terminal
  completion sequence.
  The complete game-over and type-`$82` ending paths now own their PPU/audio
  ordering, `GAME OVER` tile string, 60-vblank reset delay, terminal freeze,
  and shared unsigned high-score update.
  The remaining PRG tail is now explicit typed source: 80 padding bytes, both
  100-entry room-cell tile tables, and the NMI/reset/IRQ vectors.
  Shared screen-palette storage is typed as three overlapping 32-byte views for
  completion, title, and castle-map screens; the adjacent room palette is a
  separate semantic table.
  Six inventory-backed handlers now connect persistent cell pairs to all six
  counters, player-motion/alignment guards, boundary delay, and opening sound.
  Another six collision-table-selected handlers map runtime pickups `$90-$95`
  bijectively onto those counters, award 10 points, play their shared sound,
  and transform the collected object into its 20-frame transient state.
  Four room-transition helpers now expose the one-based 10x10 castle grid,
  including both ten-entry horizontal edge tables and boundary-safe movement.
  The four player boundary routes now preserve aligned entry coordinates,
  save outgoing object state, reload the adjacent room, update scrolling, and
  restore a mutable cell at either horizontal entrance; castle edges clamp X
  without performing a room reload.
  The complete `$82CE-$8679` player controller now owns jump/ascent/gravity,
  three-point horizontal collision probes, room-edge dispatch, the ten-frame
  B action, and its 24-record object hit scan. All three indirect collision
  calls expose their synthetic RTS continuation labels.
  The adjacent push controller now proves player-driven horizontal movement
  of runtime types `$8A-$8D/$8F`: support, player-clearance, and object-leading
  edges are sampled in order, world bounds are enforced, and obstructing
  runtime types `$84-$89` can be transformed before the two-pixel commit.
  Player protection countdowns and the exact bottom-center hazard probe now
  expose three lethal cell forms, 32-frame decay, and room-music restoration.
  Their pointer-to-row helper and current/next NMI task requests are semantic
  too. Player and runtime-object 16-bit X-coordinate helpers now have explicit
  A=high/X=low contracts. Room-transition completion now names its player/state
  mirrors and rendering-resume order; collision helpers identify runtime types
  `$90-$95`, doubled cell indexes `$8A-$91`, and four mutable visual cells. Two
  100x2 room-cell collision-flag tables and width/height tables for runtime
  types `$80-$AF` are now typed, named, and linked to all 18 consumers. The
  runtime object dispatcher and all 42 handler pointers now expose the exact
  24-record scan, type mask, visibility cutoff, and manual indirect-call return.
  Frame sprite construction now owns the 256-byte staging clear, player and
  action animation selection, 24-record object render scan, and the separate
  42-entry render-handler table. Five common metasprite render paths now own
  one-, two-, compact-two-, and four-component object composition plus the
  fixed two-component player path. Their 203 tile/attribute pairs and all 107
  statically selected descriptor references are validated independently.
  All 41 object render indexes now lead into a semantic selector module with
  named state/frame branches; the shared indexes 29/30 and seven unreachable
  code-shaped bytes after the type-09 terminator are preserved explicitly.
  New-game initialization now covers the
  starting room, lives/player state, persistent
  stores, partial snapshot invalidation, and room-palette upload. Room-runtime
  reset and the guarded room-audio restart are semantic too. The complete
  400-cell animation pass now names both opposite-direction fast phase tables,
  the intermittent four-frame family, scan pointers, cadence, and row-redraw
  requests. HUD formatting now distinguishes the persistent high score from
  the current player score and owns five-digit decimal conversion, lives,
  inventory saturation, and the foreground/NMI interlock. Controller
  polling, both Famicom save-data
  transports, PPU mode helpers, and CNROM bank
  selection are also semantic platform modules. The 394-byte save/load payload,
  its signature, validation, and room-restoration path are reconstructed too.
  Reset and the NMI-paced main loop are reconstructed with
  their cold/warm boot contract and named frame phases. The NMI handler now
  exposes its 23-task scheduler, OAM/scroll synchronization, controller paths,
  modular counters, and audio tick. OAM staging-to-DMA construction and full
  sprite-order reversal are also reconstructed. The first NMI rendering task
  now documents the status interlock and all three HUD tile uploads. Twenty
  consecutive NMI tasks reconstruct the complete 20x20 room into the two
  horizontal nametables. Every PRG byte now belongs to a semantic or explicitly
  typed-data module; no preservation range remains.
- All direct branches, jumps, and calls use labels; the first semantic names
  cover reset/interrupts, CHR switching, rooms, objects, and core data tables.
- `make symbols` validates ld65 source mappings, resolves every configured
  watch/breakpoint, and emits Mesen/FCEUX artifacts; `make validate-symbols`
  proves seven live lookups and a named NMI execution hook in pinned FCEUX.
- `make build` reconstructs a byte-identical image from the explicit iNES
  header, PRG ASM, and one ignored private CHR input; PRG is no longer included
  as a binary payload.
- `scripts/room_data.py` independently implements the published prefix-code
  room decoder; the exact local reference validates as 100 rooms, 40,000 cells,
  200 nametable attribute tables, and the exactly bounded 783-record static
  object stream. All 100 compressed rooms also re-encode byte-for-byte with
  gapless pointers and fixed 8,192/5,120-byte CHR arenas, leaving 153/671 bytes
  of proven `$FF` capacity. The object stream round-trips all 2,449 bytes and its 101
  cumulative offsets prove 141 bytes of packed object state. A second table
  proves 108 bytes of mutable-cell state across all rooms. Five cell markers
  create 176 additional runtime objects without overflowing the 24-slot pool.
- `scripts/object_catalog.py` joins all 61 encoded room types to the 42 runtime
  indexes, update handlers, sprite selectors, collision dimensions, initial
  states, room occurrence sets, and five cell-marker sources. The original
  rooms use 34 encoded values and directly source 32 runtime types.
- The 24-entry, six-byte runtime-object ABI is closed for Source 1.0: all six
  fields are named, and the five type-specific uses of auxiliary field `+5`
  have contextual source aliases. Friendly identities for every object remain
  explicitly deferred to Source 2.0.
- `scripts/player_object_span.py` proves the shared three-call overlap helper,
  including its 16-pixel Y interval, saturated `objectX-15` left boundary, and
  exclusive `objectX+width` right boundary across complete room-width domains.
- `scripts/transient_object_lifecycle.py` proves update handlers 32, 40, and
  41: the 15-entry replacement table, parity-selected replacement state,
  complete six-byte clearing, bounded state lifetime, and odd-frame Y drift.
- `scripts/object_collision_filters.py` proves both animated-cell families and
  the runtime type/filter tables used by collision samplers, including their
  intentional two-entry overlap with following instruction bytes.
- `scripts/collision_point_sample.py` proves room-cell half selection, returned
  processor flags, animation-phase suppression, and the first matching runtime
  object across the complete 320x160 room domain.
- `scripts/room_collision_sample.py` proves the room-only four-call variant
  across every room pixel, cell half, and animation-counter sign.
- `scripts/room_cell_sample_address.py` proves the shared seven-call address
  builder, including its row pointer, full 16-bit column shift, and half-cell
  carry across every possible X/Y machine-value combination.
- `scripts/player_collision_sample.py` proves the 28-call player sampler,
  including screen bounds, cell flags, runtime geometry/type filtering, scan
  order, and the special type-`$86` phase and motion behavior.
- `scripts/player_collision_dispatch.py` proves the seven-call result
  dispatcher, both 100/41-entry handler tables, room/runtime selection, and
  its synthetic indirect-call return address.
- `scripts/runtime_object_overlap.py` proves the 24-record active-object scan,
  asymmetric width bounds, vertical dimension test, first-match/resume order,
  and the carry-clear match versus carry-set exhaustion contract.
- `scripts/audio_data.py` validates the eight-set music table and all 21
  textual command streams, including their terminators and restart pointers.
- `scripts/audio_stream_engine.py` pins the interpreter's code/data boundaries
  and callers, walks every MML stream, and exhaustively models pointer advance,
  sound-effect arbitration, channel setup, countdown expiry, and APU gating.
- `scripts/sound_effect_engine.py` validates five starter write traces, the NMI
  updater's request/status arbitration, byte-wide step sequences, and all five
  period/envelope tables.
- `scripts/scroll_math_palette.py` validates the horizontal camera curve, the
  shared unsigned 16-bit divider, and the exact 32-byte PPU palette upload.
- `scripts/unreferenced_runtime_object_clear_tail.py` proves that the five
  code-shaped bytes at `$8C7B` have no Ghidra, runtime, or PRG-pointer entry.
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
- `scripts/status_format.py` exhaustively validates all 65,536 score values,
  all 256 life counts, 1,536 inventory position/value cases, and the exact
  decimal/bit-mask/helper bytes interleaved with the formatter.
- `scripts/room_row_upload.py` validates all 20 unrolled handlers, 400 cell
  lookups, and 800 left/right metatile writes byte-for-byte against the ROM.
- `scripts/room_attribute_upload.py` validates both final NMI tasks, including
  the right-nametable edge expansion and timing delay.
- `scripts/castle_map.py` validates the complete 10x10 visited-room and current
  room marker geometry.
- `scripts/famicom_data_io.py` exhaustively validates all 256 expansion-port
  byte transfers plus the pulse symbols, leader, and shared preamble contract.
- `scripts/save_data.py` losslessly encodes and decodes the 394-byte save
  payload and validates the exact `GNUTUEDEB`/`BEDEUTUN` ROM/wire signature.
- `scripts/room_cell_coordinates.py` models the 40x20 tile-to-cell mapping,
  mutable ordinals, restored forms, and persistent-state bit selection.
- `scripts/mutable_cell_actions.py` proves all 12 collision-table pointers,
  six inventory-slot mappings, handler templates, readiness guards, probe
  adjustment, and signed-direction horizontal boundary behavior.
- `scripts/room_navigation.py` proves the exact navigation machine code and
  both edge tables, then checks every direction from all 100 one-based rooms.
- `scripts/room_boundary_transitions.py` proves all four boundary routes,
  vertical X alignment, horizontal edge clamps, and entrance-cell restoration.
- `scripts/player_hazard_state.py` proves both protection countdowns, exact
  routine bytes, all 400 room-cell probes, and full X/Y/cell input domains.
- `scripts/object_player_proximity.py` proves the shared 15-call interaction
  predicate, both exclusive distance limits, and its original page-delta alias.
- `scripts/pause_input.py` proves pause/resume edges, APU shutdown, paused
  scroll priority and saturation across complete button and byte domains.
- `scripts/collision_tables.py` validates both 100x2 flag tables, all 48 object
  dimensions, their processor-flag encoding, and all 18 exact consumers.
- `scripts/frame_sprites.py` validates player/action frame selection, the full
  staging clear and object scan, and all 42 object render pointers.
- `scripts/metasprites.py` validates all 41 selector indexes, five composition
  paths, page-zero horizontal clipping and OAM compaction, 203 descriptor
  pairs, and all 107 statically selected descriptor references.
- `scripts/x_coordinates.py` exhaustively validates all player/object X helper
  offsets, carry, borrow, register order, and 16-bit wrapping.
- `scripts/room_transition.py` validates transition mirroring and the exact
  rendering-resume call order.
- `scripts/collision_cells.py` exhaustively validates all runtime-type and
  doubled cell-index bytes plus all 65,536 room-cell/status combinations
  without losing sampler flags.
- `scripts/runtime_object_dispatch.py` verifies all 42 handler pointers and
  models selection across the complete 24-record runtime pool.
- `scripts/new_game_state.py` validates starting state, exact clear ranges,
  preserved mirror/snapshot tails, and the `$C53D` room-palette pointer.
- `scripts/room_runtime_reset.py` validates ten reset fields and exhaustively
  checks the game-over/audio-pointer restart guard.
- `scripts/room_cell_animation.py` validates all 256 cell values, the three
  exact ROM frame tables, all 65,536 frame/counter cadence cases, and redraw
  coverage across all 20 room rows.
- `make format`, `make lint`, 549 unit tests, reproducible disassembly checks,
  byte identity, and decoding all rooms form the `make check` gate.
- A pinned local FCEUX fork captures native code/data logs; `make trace-boot`
  rejects runtime-executed PRG bytes that Ghidra failed to classify as code.
- `make trace-source-1` freshly captures seven deterministic paths on the
  byte-identical build: boot/gameplay, title/demo, idle timeout, room
  transition, death/game over, type-`$82` completion, and Japanese sub-command
  save plus expected no-device load failure. Rare paths use documented RAM
  state injection and must hit named debugger symbols before their CDL counts.
  A separate static registry feeds pointer-table and direct-control-flow proof
  into the same deterministic Ghidra pass without presenting it as execution.
  The boot/gameplay, title/attract, and idle-timeout suite proves 15,175 code
  bytes, 3,330 data bytes, and 6,283 instruction starts, with zero runtime/static
  disagreements. Evidence-refined Ghidra exports 10,489 instructions after 52
  static code ranges recover pointer-selected entries and 73 evidence-backed data
  ranges remove 199 false-positive instructions. A separate registry clears
  five overextended or misaligned starts embedded in real instruction operands.
  The source layout owns all 32,768 PRG bytes semantically (100%). The title and
  sub-command path now owns title palette/CHR upload, Start/attract timeout,
  controller-2 menu entry, five-entry wrapped selection, typed menu text,
  load/save dispatch, and current/previous-room restoration.

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
make trace-suite    # run and merge the baseline boot/title/timeout suite
make trace-source-1 # run the seven-scenario Source 1.0 runtime matrix
make release-audit  # reconcile the declarative Source 1.0 manifest
make source-1-check # run the complete fresh Source 1.0 candidate gate
make source-1-tag-check # require a clean tagged main after the candidate gate
make reconstruction-check # static checks plus a fresh emulator trace
make reconstruction-audit # enforce semantic-module ownership and naming
make player-input-movement # inspect player motion and action contracts
make validate-player-input-movement # validate the player controller model
make player-object-push # inspect player/object horizontal pushing
make validate-player-object-push # validate push bounds and collision topology
make runtime-types81-82-collision # inspect the type $81/$82 collision model
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
make transition-state # inspect room-transition mirrors and rendering resume
make validate-transition # validate the room-transition completion contract
make collision-state # inspect runtime-type, cell-index, and collision filters
make validate-collision # exhaustively validate collision classification
make object-dispatch-state # inspect handler pointers and record traversal
make validate-object-dispatch # validate the runtime-object frame dispatcher
make new-game-state # inspect new-game initialization as JSON
make validate-new-game # validate state ordering, clears, and room palette
make room-runtime-state # inspect reset ownership and audio restart guard
make validate-room-runtime # exhaustively validate the room-runtime contract
make room-cell-animation-state # inspect room-cell animation tables and cadence
make validate-room-cell-animation # validate every animation mapping and row
make hud-format-state # inspect decimal HUD tiles and source-buffer order
make validate-hud-format # exhaustively validate HUD formatting and ROM tables
make castle-map-state # inspect the 10x10 map marker geometry
make validate-castle-map # validate all 100 map positions
make data-io-state   # inspect pulse and expansion serial contracts as JSON
make validate-data-io # validate both Famicom data transports
make save-data       # inspect the 394-byte save-payload layout as JSON
make validate-save-data # validate payload codec and ROM signature
make room-cell-state # inspect room-cell coordinate and ordinal contracts
make validate-room-cells # validate mutable-cell lookup and restoration
make mutable-cell-action-state # inspect inventory-backed cell actions
make validate-mutable-cell-actions # validate all action mappings and guards
make room-navigation-state # inspect the one-based 10x10 castle grid
make validate-room-navigation # validate every room movement and edge table
make room-boundary-transitions # inspect entry coordinates and reload routes
make validate-room-boundary-transitions # validate every boundary path
make room-cell-sample-address # inspect shared room-cell address arithmetic
make validate-room-cell-sample-address # validate all 16-bit X and byte Y inputs
make player-death-transition # inspect death guards, lives, and game-over state
make validate-player-death-transition # validate all death guard/life domains
make player-collision-sample # inspect player cell/object collision sampling
make validate-player-collision-sample # validate all proven player sample domains
make player-collision-update # inspect the seven frame-level player probes
make validate-player-collision-update # validate probe order and hazard dispatch
make player-collision-dispatch # inspect room/runtime collision handler selection
make validate-player-collision-dispatch # validate handler tables and synthetic return
make player-transition-reload # inspect countdown, protection, and room reload
make validate-player-transition-reload # validate all countdown/protection cases
make room-object-state-save # inspect the outgoing 24-object state bitmap
make validate-room-object-state-save # validate all type and slot mappings
make player-animated-cell-displacement # inspect forced horizontal movement
make validate-player-animated-cell-displacement # validate bounds and probes
make collectible-collision-handlers # inspect six collectible effects
make validate-collectible-collision-handlers # validate pointers and state cases
make score-award     # inspect type-$97 collection and score/life transitions
make validate-score-award # validate score topology and exhaustive state cases
make runtime-type9f-collision # inspect the phase/X guarded type-$9F effect
make validate-runtime-type9f-collision # validate its pointer and state domains
make runtime-types81-82-collision # inspect transform, clone, and completion effects
make validate-runtime-types81-82-collision # validate pointers and machine-width states
make unreferenced-nmi-task-bytes # inspect the typed code-shaped byte sequence
make validate-unreferenced-nmi-task-bytes # prove it has no code/dispatch entry
make unreferenced-object-clear-tail # inspect the five-byte orphan tail
make validate-unreferenced-object-clear-tail # prove it has no reachable entry
make title-sub-command # inspect title/menu bytes, strings, and behavior
make validate-title-sub-command # exhaustively validate title/menu input and room actions
make demo-playback # inspect title-demo commands and expanded controller samples
make validate-demo-playback # validate all 863 samples and terminal reset
make audio-track-selection # inspect track records and selector behavior
make validate-audio-track-selection # validate all selectors and demo-gate cases
make audio-stream-engine # inspect interpreter partitions and behavior
make validate-audio-stream-engine # validate all stream-engine state domains
make sound-effect-engine # inspect starter and per-frame effect behavior
make validate-sound-effect-engine # validate requests, steps, and effect tables
make scroll-math-palette # inspect camera, divider, and palette-upload behavior
make validate-scroll-math-palette # validate all three exact code partitions
make end-sequences   # inspect game-over and type-$82 completion routes
make validate-end-sequences # validate ending bytes, calls, text, and score comparisons
make prg-tail-data    # inspect tail padding, tile tables, and vectors
make validate-prg-tail-data # validate 800 reads and all vector targets
make player-hazard-state # inspect protection timers and hazard contact
make validate-player-hazard # validate all timer/probe/cell input domains
make object-player-proximity # inspect the object/player carry predicate
make validate-object-player-proximity # validate every proven distance domain
make player-object-span # inspect the player/object-span carry predicate
make validate-player-object-span # validate every proven span boundary
make transient-object-state # inspect type 32/40/41 lifecycle contracts
make validate-transient-objects # validate transient-object tables and states
make object-collision-filters # inspect animated-cell and object type filters
make validate-object-collision-filters # validate filter domains and overlaps
make runtime-overlap-state # inspect the active-object overlap scan
make validate-runtime-overlap # validate type, geometry, and traversal domains
make pause-input-state # inspect pause edges and paused scrolling
make validate-pause-input # validate all pause button/mode/scroll domains
make collision-table-state # inspect room-cell flags and object dimensions
make validate-collision-tables # validate every table index and exact consumer
make collision-handler-tables # inspect directional room/runtime pointer matrices
make validate-collision-handler-tables # validate maps, consumers, and target starts
make frame-sprite-state # inspect player/action frames and object render dispatch
make validate-frame-sprites # validate the complete frame-sprite contract
make metasprite-state # inspect composition paths, descriptors, references, and gaps
make validate-metasprites # validate clipping, OAM output, and descriptor data
make object-catalog # inspect encoded/runtime/update/sprite/collision correlations
make validate-object-catalog # validate all object-type tables and room sources
make x-coordinate-state # inspect 16-bit X helper contracts as JSON
make validate-x-coordinates # exhaustively validate coordinate arithmetic
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
config/static_code_evidence.txt pointer/control-flow-proven code ranges
config/runtime_evidence.txt tracked code/data ranges observed by FCEUX
config/prg_data_ranges.txt typed data ranges removed from Ghidra code output
config/debugger_*.json     symbol-resolved Mesen/FCEUX breakpoints and watches
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
scripts/famicom_data_io.py pulse and expansion data-transport model
scripts/save_data.py     394-byte save-payload codec and validator
scripts/room_cell_coordinates.py room-cell coordinate and mutation model
scripts/room_cell_sample_address.py shared collision-sample address model
scripts/player_collision_sample.py player room-cell/object collision model
scripts/player_input_movement.py player input, motion, and action-hit model
scripts/player_object_push.py player/runtime-object push model
scripts/player_collision_dispatch.py player collision-handler dispatch model
scripts/inventory_collectible_handlers.py six-counter runtime pickup model
scripts/runtime_types81_82_collision.py type-$81/$82 transform/completion model
scripts/unreferenced_nmi_task_index_bytes.py typed orphan-byte validator
scripts/unreferenced_runtime_object_clear_tail.py five-byte orphan validator
scripts/unreferenced_runtime_only_sample.py dead runtime-only sampler model
scripts/title_sub_command.py title screen and sub-command menu model
scripts/demo_playback.py title-demo controller-script model
scripts/audio_track_selection.py track records and demo-gated selector model
scripts/audio_stream_engine.py MML interpreter and channel-arbitration model
scripts/sound_effect_engine.py sound-effect starter and updater model
scripts/scroll_math_palette.py camera, unsigned-divider, and palette-upload model
scripts/end_sequences.py game-over/completion and high-score model
scripts/prg_tail_data.py room-cell tiles, padding, and vector validator
scripts/palette_data.py overlapping screen and room palette validator
scripts/room_navigation.py one-based 10x10 castle navigation model
scripts/room_boundary_transitions.py player room-boundary transition model
scripts/player_hazard_state.py protection countdown and hazard-probe model
scripts/object_player_proximity.py runtime-object/player proximity model
scripts/player_object_span.py player/object-span overlap model
scripts/transient_object_lifecycle.py transient-object state-machine model
scripts/object_collision_filters.py animated-cell and object filter model
scripts/collision_point_sample.py room-cell/runtime-object point-sample model
scripts/room_collision_sample.py room-cell-only point-sample model
scripts/runtime_object_overlap.py runtime-pool overlap scan model
scripts/pause_input.py     pause toggle and paused-scroll model
scripts/collision_tables.py room-cell flags and object-dimension validator
scripts/frame_sprites.py   player/action and object frame-sprite validator
scripts/metasprites.py     metasprite composition and descriptor validator
scripts/object_catalog.py  unified room/runtime/update/sprite object catalog
scripts/x_coordinates.py exhaustive player/object X-coordinate model
scripts/audio_data.py      music table and textual-stream validator
src/main.asm               assembly entrypoint
src/input/famicom_data_pulse.asm PRG entry, pulse transport, and module order
src/input/famicom_data_io.asm shared dispatch and expansion serial transport
src/game/save_load.asm  save/load payload, validation, and room restoration
src/input/controllers.asm  controller wrappers and eight-bit serial polling
src/input/pause.asm        pause/resume edges and paused horizontal scrolling
src/system/ppu.asm         PPU mode helpers and CNROM bank selection
src/system/startup.asm     reset signature, initialization, and main frame loop
src/system/nmi.asm         NMI task scheduler, input, OAM, scroll, and audio tick
src/audio/stream_engine.asm textual MML interpreter and three-channel scheduler
src/audio/channel_configuration.asm streamed-note APU channel setup
src/audio/sound_effect_*.asm starters, per-frame updater, and parameter tables
src/rendering/oam_dma.asm  64-sprite DMA interleave and order transforms
src/rendering/frame_sprites.asm player/action selection and object render dispatch
src/rendering/object_sprite_selectors.asm per-type descriptor and renderer selection
src/rendering/object_metasprites.asm common object/player OAM composition paths
src/rendering/metasprite_data.asm tile/attribute descriptor data
src/rendering/status_upload.asm NMI HUD upload and task-handler tables
src/rendering/room_cell_updates.asm cell-pointer row and NMI request helpers
src/game/x_coordinates.asm player/object 16-bit X-coordinate helpers
src/rendering/room_rows_*.asm  twenty complete NMI room-row upload tasks
src/rendering/room_attribute_upload.asm final two NMI attribute tasks
src/ui/castle_map.asm      map input, visited rooms, and current-room marker
src/game/rooms/finalize_room.asm room display and 23 NMI task requests
src/game/rooms/decoder.asm proven room codebook, pointers, and decoder
src/game/rooms/load_room.asm top-level room-loading orchestration
src/game/rooms/state_orchestration.asm snapshot selection and rotation
src/game/rooms/persistent_state_*.asm offsets plus apply/load/save paths
src/game/rooms/cell_coordinates.asm pixel, tile, and room-cell addressing
src/game/rooms/sample_address.asm shared collision-sample address preparation
src/game/rooms/mutable_cell_*.asm actions, lookup, predicates, and restoration
src/game/rooms/navigation.asm boundary-safe castle room movement
src/game/player/death_transition.asm guarded death and reserve-life transition
src/game/player/transition_reload.asm countdown and persistent room reload
src/game/player/hazard_state.asm protection decay and hazard-cell contact
src/game/objects/player_proximity.asm shared object/player interaction predicate
src/game/objects/player_span_overlap.asm shared player/object-span predicate
src/game/objects/pushable_update.asm gravity, conveyors, crushing, and lift control
src/game/objects/lift_update.asm small/large lift movement and occupant closure
src/game/objects/flying_block_update.asm horizontal platform motion and reversal
src/game/objects/transient_lifecycle.asm type 32/40/41 lifecycle handlers
src/game/collision/object_filters.asm animated-cell and runtime-type filters
src/game/collision/player_sample.asm player room-cell/object collision sampler
src/game/collision/player_handler_tables.asm player collision handler pointers
src/game/collision/player_update.asm frame collision probes and hazard dispatch
src/game/collision/player_dispatch.asm player collision-handler dispatch
src/game/collision/point_sample.asm room-cell/runtime-object point sampler
src/game/collision/room_sample.asm room-cell-only point sampler
src/game/collision/runtime_overlap.asm active-object span overlap scan
src/game/collision/*.asm collision sampling, classification, flags, and dimensions
src/rendering/room_attributes.asm proven room attribute-table construction
src/rendering/room_screen.asm nametable, status, attribute, and OAM setup
src/system/nmi_tasks.asm   NMI task-request reset
src/game/objects/room_loader.asm proven static-object expansion into RAM
src/game/objects/stream_seek.asm proven terminated-list stream navigation
src/game/objects/room_data.asm typed object lists and persistent-state offsets
src/game/objects/linked_lift_control.asm type-$8E control and linked lift pair
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
