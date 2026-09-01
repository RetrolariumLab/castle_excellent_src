# Reverse-engineering unknowns

Statuses are `open`, `testing`, `resolved`, `unused`, and `confirmed bug`.

## Open registry

### ROM-001 - exact iNES identity

- Status: resolved
- Known: 32 KiB PRG CRC32 `9FA1C11F`, 32 KiB CHR CRC32 `04A8FF2E`, combined
  headerless CRC32 `7FA2CC55`, mapper 3, vertical mirroring; exact hashes are
  recorded in `assets/manifest.json`
- Evidence: local Japanese reference inspected on 2026-08-31

### INPUT-001 - controller serial format

- Status: resolved
- Known: both ports are strobed through `$4016`; eight reads use D0 first and
  D1 only when D0 is clear; ROR produces standard NES bit order in `$20`
- Evidence: semantic `$80FF-$8157` module, runtime execution of both pollers,
  and exhaustive reconstruction of all 256 masks on D0 and D1
- Residual: `$8135-$813A` encodes a plausible second no-NMI wrapper but remains
  raw because no call target or runtime trace reaches it

### INPUT-002 - Famicom save-data transports

- Status: resolved
- Known: sign bit of scoped `$1F` selects pulse-width signaling through `$4016`
  or expansion serial signaling through `$4016/$4017`; both serialize bytes
  MSB-first through scoped `$17`
- Pulse path: zero is one long cycle, one is two short cycles, the leader is
  33 x 256 short pairs, and carry reports invalid receive edge counts
- Expansion path: strobe `$00,$02`, preamble `00 AA 55`, output clock on bit 2,
  output data on bit 0, and input data from `$4017` bit 2
- Evidence: semantic `$8000-$80FE` and `$8180-$8224`, save/load callers,
  exhaustive 256-byte model, deterministic disassembly, and byte-identical ROM
- Residual: exact accessory identities for the two Japanese interfaces remain
  open pending hardware documentation or a focused runtime capture

### SAVE-001 - serialized game-state payload

- Status: resolved
- Known: payload length is 394 bytes with field offsets 0, 1, 2, 16, 136, 286,
  and 386; the three RAM blocks are transferred in descending address order
- Signature: ROM text `GNUTUEDEB` at `$FC99-$FCA1` is indexed 8 through 1 to
  produce the eight wire bytes `BEDEUTUN`
- Load behavior: the room, 14 runtime bytes, all three blocks, and signature
  check carry; player-lives byte at offset 1 does not check receive status
- Evidence: semantic `$FBFE-$FDC4`, symmetric send/receive loops, lossless
  394-byte codec, exact ROM signature validation, and byte-identical build

### SYS-001 - reset signature and frame gate

- Status: resolved
- Known: ROM `$82C9-$82CD` is `POWER`; Reset compares/copies `POW` at
  `$077E-$0780`, clears high score and the 16-bit reset counter only on mismatch,
  then increments the counter on every reset
- Frame gate: the foreground writes two to `$FC`; NMI decrements nonzero values,
  and the main loop waits for zero before the next update
- Evidence: semantic `$8225-$82CD`, typed ROM text, independent cold/warm/carry
  model, exact image validation, and runtime execution of Reset/NMI

### SYS-002 - NMI task scheduler

- Status: resolved
- Known: 23 high bytes at `$C88E-$C8A4` and 23 low bytes at `$C8A5-$C8BB`
  form the indirect task handlers; `$F8` selects the current task
- Scheduling: common frame completion clears the current request, scans forward
  for the next nonzero request, and wraps to task zero at index 23
- Frame work: OAM DMA/interlock, scroll latch, real/demo input, modulo counters,
  music, effects, and register restoration are all in `$C55D-$C6B8`
- Evidence: semantic module, typed tables, independent scheduler/table model,
  byte-identical build, and all three runtime CDL scenarios

### RENDER-001 - OAM staging-to-DMA order

- Status: resolved
- Known: `$0300-$03FF` is an 8x8 matrix of four-byte sprite records;
  `$C79D-$C7AB` selects a frame-rotated column for each 32-byte DMA block
- Transform: all 64 records are transposed into `$0200-$02FF`; a separate path
  reverses record order while preserving each record's four byte fields
- Bound: table indexes are `frame 0-7 + block 0-7`, so 0-14 are reachable and
  the sixteenth physical byte at `$C7AC` is not
- Evidence: semantic `$C6B9-$C803`, typed table/padding byte, independent model
  of every frame and record, runtime CDL, and byte-identical build

### RENDER-002 - NMI status-tile upload

- Status: resolved
- Known: task zero writes score to `$2096`, inventory counters to `$2087`, and
  lives to `$20A8`; `$07C8` prevents reads during foreground formatting
- Transform: source orders are `0-4`, `0,1,5,4,3,2`, and `1,0`; a busy buffer
  delegates to the first 20-cell room-row task at `$C8BC`
- Evidence: semantic `$C804-$C8BB`, sized RAM buffers, exact handler tables,
  independent write-order model, runtime CDL, and byte-identical build

### RENDER-004 - foreground status formatting

- Status: resolved
- Scores: `$0001-$0002` is high score and `$000B-$000C` current player score;
  both use five decimal places `10000,1000,100,10,1`, tile base `$60`, and
  leading blank `$FF`
- Lives: three scratch digits are stored ones/tens/hundreds; NMI consumes tens
  then ones, so the physical hundreds byte is formatting-only
- Inventory: six counters at `$0005-$000A` each saturate at nine before tile
  conversion
- Interlock: `$07C8=$FF` precedes an eight-byte score-buffer clear and `$00`
  is written only after score, lives, and inventory are complete
- Evidence: semantic `$A497-$A572`, exact decimal tables, corrected score
  call/compare/update sites, all 65,536 scores, 256 life counts, 1,536 inventory
  cases, deterministic regeneration, and byte-identical build

### RENDER-003 - NMI room-row upload layout

- Status: resolved
- Known: tasks 1-20 cover rows 0-19 of the 20x20 decoded room at `$0400-$058F`
- Transform: each task expands 20 cell ids through the two 100-byte tile tables;
  14 metatiles go to the left nametable and 6 to the right
- Bound: handlers occupy `$C8BC-$E1F7`, are exactly `$143` bytes each, and write
  destinations from `$20E4/$24E0` through `$2344/$2740`
- Evidence: four semantic modules, exact independent encoder for all 6,460 code
  bytes, 400 lookups, 800 PPU tile writes, runtime CDL, and byte-identical build

### UI-001 - castle map geometry

- Status: resolved
- Known: 100 zero-based room flags map to a 10x10 grid; the current room id is
  one-based and uses the same quotient/remainder coordinates
- Output: visited rooms use 2x2 background markers; the current room uses the
  first four-byte OAM record while all remaining staging bytes are hidden
- Evidence: semantic `$EA36-$EB6B`, exhaustive 100-room coordinate model,
  runtime CDL, and byte-identical build

### DATA-001 - prefix-code table bounds

- Status: resolved
- Known: the first symbol entry begins at `$E45D`; `$FF` after the final
  codeword terminates the table; recovered codewords are prefix-free
- Evidence: independent decoder produced exactly 400 cells for all 100 rooms

### DATA-002 - room bitstream boundaries

- Status: testing
- Known: pointer table at `$E71C`, split at room index `$43`; all 100 streams
  decode without truncation
- Needed: formal overlap checks, bank-tail usage, and encoder capacity rules

### DATA-003 - room nametable attribute construction

- Status: resolved
- Known: masks at `$E913-$E916` select the four two-bit quadrants; the 100-byte
  table at `$E9D2-$EA35` supplies replicated palette values; 13 cell types
  preserve their existing quadrant
- Output: two 64-byte buffers at `$0100-$017F`; NMI task requests 21 and 22
  upload them to nametable attribute addresses `$23C8` and `$27C8`
- Evidence: semantic builder at `$E8DF-$E9D1`, semantic NMI handlers at
  `$E1F8-$E45C`, independent construction of 200 tables from all 100 decoded
  rooms, exact upload encoders, and the byte-identical source build

### OBJ-001 - six-byte runtime record

- Status: testing
- Known: type at `+0`, 16-bit scaled X at `+1/+2`, scaled Y at `+3`, loaded
  initial state at `+4`, and a six-byte stride; `+4` is the global runtime
  state byte and is zero except for encoded types `$12-$29`, which index a
  state view beginning at `$EBC0`
- Format evidence: 100 lists fill `$EF6B-$F8FB` exactly; 783 records use 34
  encoded types `$0E-$3C`; five cell markers add 176 runtime types `$A1-$A5`;
  the largest combined room uses 22 of 24 runtime slots; all 2,449 stream bytes
  round-trip exactly
- Persistence evidence: 101 offsets at `$EF06-$EF6A` match
  `ceil(objects / 8)` for every room and address 141 bytes at `$0608-$0694`
- Needed: prove field `+5`, later meanings/transitions of `+4`, and semantic
  identities for all encoded and runtime types

### OBJ-002 - shared 16-bit X-coordinate probes

- Status: resolved
- Player fields: little-endian X at `$38/$39`, Y at `$3A`
- Runtime fields: little-endian X at record `+1/+2`; record offset remains in X
  on entry and is replaced by the result low byte on return
- Return contract: A=high byte and X=low byte
- Fixed probes: player +7/+15; runtime object +0/+7/+8/+15/+17/-2
- Evidence: semantic `$94DB-$952C`, global RAM operands, collision and
  pixel-to-tile callers, exhaustive 65,536-position arithmetic model,
  deterministic regeneration, and byte-identical build

### COLLISION-001 - transition-adjacent type and cell filters

- Status: resolved
- Type predicate: carry clear exactly for runtime types `$90-$95`; carry set
  below `$90` and at or above `$96`
- Cell normalization: `$54,$55,$62,$63` become `$53` with carry clear; every
  other accumulator value and the sampler's complete status are preserved
- Transition context: `$952D-$9551` mirrors player X/Y into runtime offsets
  11-13, mirrors two scoped state bytes, restores `$FF` gameplay mode, then
  resumes rendering through scroll reset, NMI enable, and vblank wait
- Evidence: semantic `$952D-$9577`, contextual RAM aliases, all 256 runtime
  types, all 65,536 cell/status combinations, deterministic regeneration, and
  byte-identical build

### COLLISION-002 - doubled cell-pair lookup index

- Status: resolved
- Known: `$A6CA-$A6D7` returns Y zero/Z set exactly for X indexes `$8A-$91`
  and Y `$FF`/Z clear for every other byte value
- Interpretation: the match range represents both lookup phases of room-cell
  types `$45-$48`, because callers form X as twice the cell value plus one bit
- Evidence: semantic routine, three direct call sites, runtime execution of
  both return paths, exhaustive 256-value model, and byte-identical build

### OBJ-003 - runtime-object frame dispatcher

- Status: resolved
- Pool traversal: exactly 24 records at offsets `0,6,...,138`; the shared
  update flag is cleared before inspecting every record
- Selection: `type & $7F`; zero is inactive, Y at/after `$A0` is skipped, and
  valid type indexes 1-41 select one of 42 little-endian pointers at `$95BF`
- Call contract: push `AdvanceRuntimeObjectUpdate - 1`, jump indirectly through
  `$31/$32`, and let the handler's `RTS` resume the record scan
- Evidence: semantic `$9583-$9612`, exact 84-byte table decode, both high-bit
  forms for every table index, all record offsets, deterministic regeneration,
  and byte-identical build

### GAME-001 - new-game state initialization

- Status: resolved
- Initial values: one-based room `$47`, three lives, player X zero and Y `$98`,
  pause/map/game-over/transition countdown zero, status buffers busy `$FF`
- Cleared storage: 14-byte runtime state copied to load mirror and snapshot A,
  120 mutable bytes, 150 object bytes, 27 bytes spanning current room state
  through snapshot A, and all 100 visited flags
- Preserved details: load-mirror byte 14 is untouched; snapshot B bytes 1-8 are
  retained while its room id is cleared; active runtime Y changes only after
  the zero state has been mirrored
- Palette: fallthrough `$A351` uploads typed `RoomPaletteData` at `$C53D`
- Evidence: semantic `$A2B1-$A35B`, HUD/save/death uses proving `$13` as lives,
  channel-specific SFX consumers, ten exact ROM operands, independent state
  model, deterministic regeneration, and byte-identical build

### GAME-002 - room-runtime reset and audio continuity

- Status: resolved
- Reset: ten movement, NMI-task, scroll, object-update, frame, and animation
  fields are set to zero at `$A3AC-$A3C5`
- Audio guard: game over or any nonzero byte in the current 16-bit stream
  pointer returns immediately; normal play with a null pointer tail-calls
  `SelectRoomAudio`
- Evidence: semantic `$A3AC-$A3D1`, scoped RAM aliases, all 65,536 pointer
  values, every nonzero game-over byte, unrelated-state preservation,
  deterministic regeneration, and byte-identical build

### GAME-003 - room-cell animation families and cadence

- Status: resolved
- Fast pass: every odd room simulation frame scans all 400 cells; `$35-$40`
  contains three phase-decrementing groups and `$56-$61` three
  phase-incrementing groups
- Slow pass: `$45-$48` advances when the incremented 8-bit animation counter
  is nonnegative and divisible by four; negative counter values pause it
- Rendering: every slow cell queues its row; only `$35-$38` and `$56-$59`
  queue rows for the grouped fast families
- Evidence: semantic `$A3D2-$A496`, three typed tables totaling 28 bytes,
  scoped scan/update pointers, all 256 cell values, 65,536 frame/counter cases,
  all 20 redraw rows, deterministic regeneration, and byte-identical build

### GAME-004 - inventory-backed persistent-cell actions

- Status: resolved
- Dispatch: collision table `$9155` maps cell pairs
  `$19/$1A,$1C/$1D,$1F/$20,$22/$23,$25/$26,$29/$2A` to six handlers and
  inventory indexes `4,3,5,2,0,1`
- Guard: the selected count must be nonzero, normalized motion and its phase
  must both be zero, and player Y must equal eight modulo 16; failure unwinds
  both the helper and indirect collision-handler return addresses
- Success: decrements only the selected count, moves probe Y up 16 pixels,
  opens/persists the mutable-cell ordinal, and starts one triangle/noise effect
- Boundary: facing left below X `$0011` or nonnegative at/above `$0120` installs
  a nine-frame movement delay; all other successful actions preserve the delay
- Evidence: 12 pointer-table entries, six exact handler templates, separate
  static code provenance, semantic `$A5DD-$A66C`, exhaustive byte-domain model,
  deterministic regeneration, and byte-identical build

### GAME-005 - castle room navigation

- Status: resolved
- Layout: one-based rooms 1-100 form a 10x10 row-major grid; vertical movement
  changes the room number by ten and horizontal movement changes it by one
- Boundaries: rooms 1-10 stop upward movement, rooms 91-100 stop downward
  movement, and exact tables `$A821-$A82A` / `$A82B-$A834` contain every
  rightmost / leftmost room number
- Search contract: the descending table helper returns the zero-based row in X
  with Z set on a match, or X `$FF` with Z clear otherwise
- Evidence: six direct transition call sites, semantic `$A7DB-$A834`, exact
  routine bytes and ROM tables, all four directions from all 100 rooms,
  deterministic regeneration, and byte-identical build

### GAME-006 - player protection and hazard-cell contact

- Status: resolved
- Timers: `$000D` protects against the room-cell hazard and `$000E` guards the
  shared death entry; each nonzero value decrements when room frame modulo 32
  is zero and independently calls `SelectRoomAudio` when it reaches zero
- Probe: `(PlayerX+7,PlayerY+8)` uses 16-bit/8-bit wrapping, accepts probe Y
  `$10-$AF` and X below `$0140`, then samples the rebased 20x20 room grid
- Cells: `$16,$62,$63` write active `$FF` to `$077C`; every other cell and
  out-of-room coordinate writes zero
- Dead read: `$A859` reads the previous `$077C` value, but the immediately
  following player-Y load replaces both A and flags before any consumer
- Evidence: collision/death consumers, semantic `$A835-$A8A8`, exact routine
  bytes, all countdown/frame, X, Y, cell-value, and 400 cell-index domains,
  deterministic regeneration, and byte-identical build

### GAME-007 - runtime-object/player interaction proximity

- Status: resolved
- Point: compares player coordinates with `(RuntimeObjectX,RuntimeObjectY+16)`
- Result: carry clear only for vertical distance `<4` and normalized X distance
  `<5`; all 15 direct callers branch on this contract
- Compatibility: the original negative X normalization omits high-byte carry,
  so `object X - player X == -$0100` normalizes to zero
- Evidence: semantic `$A8A9-$A8E2`, exact routine and call-site bytes, every Y
  pair, every negative 16-bit X delta, all 102,400 room-width X pairs, all 64
  page-alias pairs, deterministic regeneration, and byte-identical build

### GAME-008 - pause input and paused scrolling

- Status: resolved
- Toggle: a new Start edge enters or leaves pause; a new A/B edge resumes only
- Audio: entering pause writes zero to `$4015`; NMI also skips stream/SFX
  updates while `$07C4` is nonzero
- Scroll: paused Left/Right changes `$34` by four, Left first, with the valid
  domain saturated to `$00-$80`; movement writes `$FF` to `$36` for NMI
- Edge history: toggle and paused paths copy current buttons to `$0777`, while
  an unpaused idle return intentionally preserves the previous mask
- Evidence: semantic `$A8E3-$A959`, main-loop and NMI consumers, exact routine
  bytes, 131,072 button pairs, all pause-mode and scroll bytes, deterministic
  regeneration, and byte-identical build

### DATA-004 - persistent room-state bitmaps

- Status: resolved
- Record: one-byte room id, three static-object bitmap bytes, five mutable-cell
  bitmap bytes; active state at `$0712`, snapshots at `$0724` and `$072D`
- Object persistence: 101 offsets at `$EF06-$EF6A`, 141 bytes at `$0608-$0694`,
  one bit per static object
- Mutable-cell persistence: 101 offsets at `$ABAE-$AC12`, 108 bytes at
  `$0590-$05FB`; rooms 1-99 derive from seven candidate cell values, while
  room 100 reserves three bytes
- Application: set object bits clear runtime records; mutable bits select
  one-based candidate ordinals 1-39 and restore one of two two-cell forms
- Evidence: semantic load/save/apply modules, exact object-count and six-byte
  offset tables, and independent validation of every object list, all 40,000
  decoded cells, and all 176 cell-derived objects

### DATA-005 - mutable-cell coordinate and ordinal pipeline

- Status: resolved
- Coordinates: A:X is 16-bit pixel X and Y is pixel Y; division by eight
  yields tiles, and `$0400 + tile_y * 20 + floor(tile_x / 2)` yields the cell
- Lookup: lower/right forms move one row upward; anchors are numbered from one
  by a row-major backward count
- Restoration: horizontal neighbor `$16` selects `$62/$63`; all other anchors
  become `$54/$55`; the ordinal also selects its persistent-state byte/mask
- Side effects: the affected room row and successor task are queued; mutable
  restoration separately requests both attribute NMI tasks
- Evidence: semantic `$949C-$94DA`, `$A58A-$A5DC`, `$A66D-$A6C9`,
  `$A70A-$A7DA`, independent
  coordinate/ordinal/restoration model, deterministic regeneration, and
  byte-identical build
- Residual: `$A596-$A5A3` resembles the inverse tile-to-pixel conversion but
  remains typed unreferenced data pending an observed entry; the same policy
  covers code-shaped shims at `$94A5-$94AB` and `$94BC-$94C2`

### ROOM-001 - room-loading orchestration

- Status: resolved
- Order: mark visited, clear the object pool, decode, load/apply objects and
  state, reset NMI tasks, initialize the screen and OAM, write status data,
  build/upload attributes, reset runtime variables, select room audio
- Snapshot selection: matching snapshot-B room id restores that snapshot;
  otherwise the persistent stores are loaded; selected state is mirrored before
  bitmap application
- Evidence: semantic `$9578-$9582`, `$A35C-$A3AB`, `$B64C-$B7FC`, and
  `$EC63-$ECB6` modules; boot/gameplay CDL execution; independent status-data
  bounds and pointer validation; byte-identical build

### AUDIO-001 - alleged textual MML region

- Status: resolved
- Known: eight 8-byte records at `$B8C6` select three stream pointers and two
  channel parameters; 21 terminated ASCII command streams cover
  `$BBE7-$C20C` without gaps
- Grammar: `o`, `t`, `l`, and `v` commands; notes `a-g`, rest `r`, accidentals,
  explicit lengths, and dotted lengths; `$00` is followed by a little-endian
  restart address or `$0000`
- Evidence: static consumers in `$B895-$BB15`, exact-ROM validation by
  `scripts/audio_data.py`, and FCEUX CDL data reads with no executions in the
  stream range
