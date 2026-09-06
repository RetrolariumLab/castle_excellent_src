# Resolved reverse-engineering findings

This archive preserves the evidence and closure of questions removed from the
active registry in `docs/unknowns.md`.

## Resolved registry

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

### RENDER-005 - frame sprite selection and render dispatch

- Status: resolved
- Staging: all 256 bytes are set to hidden Y `$F0`; two player records and one
  optional action record reserve offsets `$00-$0B`, objects start at `$0C`
- Player: four transition phases, neutral/directional motion, action countdown,
  and mirrored `0,1,2,1` walk descriptor cycles are selected explicitly
- Action overlay: tile `$CA`, X+15/attributes `$03` to the right, and
  X-7/attributes `$43` to the left
- Objects: 24 records, six-byte stride, Y `<$A0`, raw nonzero type, then
  `(type & $7F) * 2` into 42 render pointers
- Overlap: logical entry zero at `$AD93` is `$6003`; entries 1-41 occupy the
  physical typed range `$AD95-$ADE6`, with indexes 29/30 sharing `$B089`
- Evidence: semantic `$AC13-$ADE6`, exact range hash and instruction slices,
  complete player/action/type/Y models, deterministic regeneration, and
  byte-identical build

### RENDER-006 - common metasprite renderers and descriptor data

- Status: resolved
- Selectors: all 41 indexes are semantic at `$ADE7-$B1D5`; indexes 29/30 share
  one body, and the unreachable `$AFCC-$AFD2` tail remains typed data
- Paths: one, standard two, compact two, and wide four object components plus
  the fixed two-component player renderer occupy `$B1D6-$B4B5`
- Clipping: object world X is adjusted modulo 16 bits, pending scroll is
  subtracted, and only page-zero results append to staging OAM; earlier clipped
  components do not reserve records
- Player edge: both records are fixed, but an eight-pixel X wrap hides the
  second by writing Y `$F0`
- Data: `$B4B6-$B64B` is 203 `(tile, attributes)` pairs; 107 recognizable
  selections use 98 unique aligned pointers and leave five short gaps
- Evidence: exact selector/renderer/data hashes, independent exhaustive projection
  model, descriptor-reference scan and shape validation, deterministic
  regeneration, and byte-identical build

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

### OBJ-004 - shared player/object-span overlap

- Status: resolved
- Inputs: object X low/high in `$44/$45`, object Y in `$46`, and object width
  in `$47`; player coordinates come from `$38-$3A`
- Vertical contract: accepts player Y from `objectY+1` through `objectY+16`,
  inclusive, with the original byte-width addition semantics
- Horizontal contract: accepts player X in
  `[max(0, objectX-15), objectX+width)` using full 16-bit comparisons
- Result: carry clear means overlap; all vertical, left, and right rejection
  paths return carry set
- Evidence: three direct calls, semantic `$9613-$965B`, exact routine bytes,
  every Y pair, 921,600 room-width X/width cases, deterministic regeneration,
  and byte-identical build

### OBJ-005 - transient runtime-object lifecycles

- Status: resolved
- Type index 32 is Witch summon type `$A0`, created by `UpdateWitch` with state
  16. When it reaches zero, paired values of the modulo-30 counter select one
  of 15 replacement entries containing Fighter `$84`, Bishop `$85`, and Knight
  `$87`; global frame parity selects direction zero/`$FF`
- Type index 40: increments state and clears all six record bytes when the new
  value reaches 15; byte wrap from `$FF` to zero remains active
- Type index 41: decrements Y on odd room frames when Y is nonzero, then
  decrements byte five and clears all six bytes when that countdown reaches zero
- Provenance: none of `$A0,$A8,$A9` comes directly from static room triples or
  cell markers; the Witch creates `$A0`, while other handlers create `$A8/$A9`
- Evidence: semantic `$9FF3-$A043`, exact 15-byte table, three dispatch-table
  pointers, 73,984 modeled state/frame cases, deterministic regeneration, and
  byte-identical build

### OBJ-006 - runtime-object collision filters

- Status: resolved
- Animated cells: `$35-$40` return carry set/Y zero, `$56-$61` return carry
  set/Y `$FF`, and every other byte returns carry clear
- Type-84-to-89 filter: returns zero exactly for `$84-$89` in the proven
  `$00-$A7` consumer domain; all other results are nonzero
- Solidity: `$81-$83`, `$90-$9C`, and `$9F` return zero; other proven types
  return nonzero and are treated as solid by the object-overlap samplers
- Overlap: each physical table stores 38 values for `$80-$A5`; indexes
  `$A6/$A7` read the first two instruction bytes at `$A091/$A092` or
  `$A0C4/$A0C5`, yielding nonzero `$A8/$08` and `$C0/$A0`
- Evidence: semantic `$A044-$A0C3`, 76 physical and 80 logical table bytes,
  seven aligned calls, five additional opcode matches, complete cell/type
  domains, deterministic regeneration, and byte-identical build

### OBJ-007 - room/object point collision sample

- Status: resolved
- Addressing: A:X supplies a 16-bit pixel X and Y supplies pixel Y; valid
  pixels address `RoomCells[(Y >> 3) * 20 + (X >> 4)]`, with X bit 3 selecting
  one of two collision-table halves
- Room result: a nonzero flag returns the cell in A, the doubled half index in
  X, and flag bits 0/7 in C/N; `$45-$48` retain their identity but clear flags
  while the room animation counter is negative
- Object result: empty/passable cells scan 24 records, exclude
  `CurrentObjectOffset`, accept types `$80-$A7`, and return the first containing
  record with Y=1, its offset in X and `$42`, and solidity in carry
- Empty result: Y at/after 160 or scan exhaustion returns A=`$53`, Y=0, carry
  clear
- Evidence: semantic `$A0C4-$A1A2`, 30 direct calls, exact 223-byte routine,
  complete cell-half/type/slot domains, 102,864 coordinate/geometry cases,
  deterministic regeneration, and byte-identical build

### OBJ-008 - room-only collision sample

- Status: resolved
- Addressing: shares the 20x20 room-buffer address helper and X-bit-3 half
  selection with the combined point sampler
- Result: always returns the addressed cell in A and doubled half index in X;
  collision-table bit 0 becomes C and bit 7 becomes N, including zero/passable
  entries without a runtime-object fallback
- Animation: `$45-$48` return Y zero and suppress their flags while the room
  animation counter is negative; ordinary cell pairs return Y `$FF`
- Boundary: Y at/after 160 returns A=`$53`, X=0, carry clear, with input Y
  preserved
- Evidence: semantic `$A1A3-$A1D3`, four direct calls, exact 49-byte routine,
  all 51,200 room pixels and 400 cell-half/animation cases, deterministic
  regeneration, and byte-identical build

### OBJ-009 - runtime-object span overlap scan

- Status: resolved
- Traversal: starts at any caller-provided six-byte offset, tests records in
  ascending order, and stops after offset 138 in the 144-byte pool
- Type filter: only active types `$80-$A7` participate; positive/inactive types
  and transient `$A8/$A9` records are skipped
- Vertical contract: the supplied Y point must be at/after object Y and less
  than the type-specific height below it
- Horizontal contract: object X must lie in the half-open interval
  `[max(0, spanX-objectWidth+1), spanX+spanWidth)`
- Result: the first match returns its offset in X with carry clear; exhaustion
  returns X at `$90` with carry set through the shared no-op handler RTS
- Evidence: semantic `$A1D4-$A2A9`, an explicitly unreferenced runtime-only
  sibling, two direct overlap calls, exact width/height tables,
  all 24 offsets, 1,052,928 type/X/Y cases, deterministic regeneration, and
  byte-identical build

### OBJ-010 - player room/object collision sample

- Status: resolved
- Boundary: A:X screen X must be 0-319 and Y must be 16-175; Y is then rebased
  to the 160-pixel room field
- Room result: player-specific cell-half flags return before runtime objects;
  `$45-$48` preserve cell identity while a negative animation phase suppresses
  collision flags
- Object result: passable halves scan 24 records in order; a nonzero one-shot
  latch accepts only `$90-$95`, and is cleared on every return
- Special case: during the first half of the 256-frame room cycle, type `$86`
  matches only its lower eight pixels and only while player motion state is zero
- Evidence: semantic `$8DD3-$8ECA`, 28 direct calls, native runtime execution,
  exact 248-byte image, 176,888 boundary/cell/type/geometry/state/slot cases,
  deterministic regeneration, and byte-identical build

### OBJ-011 - player collision-result dispatch

- Status: resolved
- Selection: `ASL` doubles the sample identity and moves its high bit to carry;
  carry clear selects 100 room-cell pointers, carry set selects 41 runtime-type
  pointers indexed by the low seven bits
- Call contract: the dispatcher pushes `$949A`, jumps through `$31-$32`, and
  the selected handler's `RTS` resumes at the local `$949B` return
- Tables: `$926C-$9333` has three unique room targets; `$9334-$9385` has 18
  unique runtime targets, with the final physical entry outside the sampler's
  consumed `$80-$A7` type domain
- Evidence: semantic `$926B-$9385` and `$9477-$949B`, seven direct calls,
  native runtime coverage, exact 37-byte code and 282 table bytes, all 140
  consumed identities, deterministic regeneration, and byte-identical build

### PLAYER-001 - player death transition

- Status: resolved
- Entry guards: either nonzero invulnerability at `$0E` or an active transition
  at `$0772` returns without changing player state
- Start: installs transition countdown `$80`, clears the action countdown, and
  selects audio track set 2
- Lives: a nonzero reserve count is decremented; zero instead latches
  `GameOverActive=$FF` without wrapping the reserve count
- Sources: 39 room-cell types, 18 runtime-object types, and the direct
  hazard-contact jump at `$93F2` all select the same handler
- Animated source: room-cell types `$45-$48` first test the animation-counter
  sign; its negative phase returns, while its nonnegative phase enters death
- Evidence: semantic `$8DAB-$8DD2`, exact 40 bytes and 61 table references,
  complete animation/guard/life domains, deterministic regeneration, and
  byte-identical build

### PLAYER-002 - frame-level player collision probes

- Status: resolved
- Order: top-left, top-right, bottom-left, bottom-right, center, top-center,
  then top-right again; each point is sampled and immediately dispatched
- Transition: nonzero `$0772` bypasses all probes and enters the transition
  countdown/reload path at `$93F6`
- Hazard: after the seven handlers, nonzero `$077C` with zero protection `$0D`
  jumps to `StartPlayerDeathTransition`
- Evidence: sole main-loop call at `$82A5`, native execution through `$93ED`,
  semantic `$9386-$93F5`, exact 112 bytes, complete coordinate/state boundary
  model, deterministic regeneration, and byte-identical build

### PLAYER-003 - death-transition room reload

- Status: resolved
- Countdown: `$0772` decrements each frame; only `1 -> 0` completes, while an
  unexpected zero input wraps to `$FF`
- Restore: saved `$10-$12` replace player X/Y; hazard protection is unchanged
  when both transition inputs are zero, otherwise it becomes `max(mirror,
  current)+10`, except nonzero `$07CD` forces `$28+10=$32`
- Game over: zero reserve lives and nonzero `GameOverActive` enter the terminal
  game-over sequence instead of reloading the room
- Reload: save current object state, decode `room-1`, load objects, copy/apply
  the 3-byte object and 5-byte mutable-cell bitmaps, reset runtime/render state,
  rebuild attributes/scroll, enable rendering, then enable NMI
- Evidence: semantic `$93F6-$9476`, direct flow from the proven frame updater,
  exact 129 bytes, exhaustive countdown/protection model, deterministic
  regeneration, and byte-identical build

### PLAYER-004 - input, movement, and action-hit controller

- Status: resolved
- Input: A gates grounded jump transitions; a fresh B press starts a ten-frame
  action, holding B decrements it without restart, and release clears both
  action fields
- Motion: ascent and gravity use three collision samples; horizontal movement
  advances two pixels and dispatches the established left/right room routes at
  the world boundaries
- Dispatch: upward, downward, and horizontal collision paths each select a
  room-cell or runtime-object handler and push an explicit synthetic RTS return
- Action hit: the first overlapping active object stops the 24-record scan;
  only types `$84,$87,$88` transform to `$A8`, clear state, and request sound
- Evidence: semantic `$82CE-$8679`, direct main-loop call, three exact indirect
  continuation shims, exact 940-byte hash, exhaustive input/action/X/type
  models, deterministic regeneration, and byte-identical build

### PLAYER-005 - player-driven runtime-object pushing

- Status: resolved
- Dispatch: horizontal runtime types `$8A-$8D/$8F` select the shared routine;
  type `$8E` calls it directly before continuing into linked-object behavior
- Preconditions: player vertical motion/phase must be inactive and at least
  one of three points 17 pixels below the object must report collision
- Clearance: directional player probes may rediscover the pushed record but
  any other room/object obstruction stops the operation
- Commit: the leading object edge must remain inside world X `$0000-$013F`;
  player and object then move two pixels together and `$0773` records direction
- Destruction: a leading collision value in `$84-$89` becomes type `$A8` with
  state zero and a sound request before movement continues
- Evidence: semantic `$881A-$89E0`, six exact pointer entries, direct `$89E6`
  call, exact 455-byte hash, twelve collision call sites, exhaustive X/motion/
  type/order models, deterministic regeneration, and byte-identical build

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

### DATA-006 - collision flag and object-dimension tables

- Status: resolved
- Cell flags: two 200-byte tables index 100 room-cell types by left/right half;
  player values are `$00,$01,$80` and object values are `$00,$01,$81`
- Flag contract: bit 7 becomes N and bit 0 becomes C in the consuming paths
- Dimensions: two 48-byte tables provide width and height for runtime types
  `$80-$AF`; `$AA6A/$AA9A` are physical bases minus `$80`, not extra tables
- Boundary: `$AB49` is both the final height byte and `RoomObjectCounts - 1`
- Evidence: semantic `$A95A-$AB49`, all four exact table images, exhaustive
  100x2/48-entry indexing, 18 exact consumers, deterministic regeneration, and
  byte-identical build

### DATA-007 - encoded-to-runtime object catalog

- Status: resolved
- Join: encoded `$00-$3C` through `$EB8F` to runtime `$80-$A9`, then by low
  seven bits to update `$95BF`, sprite `$AD93`, and collision dimensions
- Sources: 34 encoded values produce 783 static objects of 27 runtime types;
  five cell markers produce 176 objects of types `$A1-$A5`
- Dispatch: 16 unique update targets, 23 no-op indexes, and 40 unique nonzero
  sprite selectors; indexes 29/30 share their selector
- Residual: ten runtime indexes have no direct room-data source and remain
  numeric until dynamic transitions or behavior establish their identities
- Evidence: all 100 object lists and decoded rooms, exact handler tables,
  initial-state overlap, dimension tables, occurrence/room aggregation, and
  byte-identical build

### DATA-008 - room-cell sample address builder

- Status: resolved
- Address: semantic `$8ECB-$8F0F`, called directly at seven collision and
  hazard sites
- Contract: A:X is a 16-bit pixel X and Y is byte-wide pixel Y; the helper
  returns row pointer `$0400 + (Y >> 3) * 20`, column `X >> 4`, and original X
  bit 3 in carry for selecting a cell's horizontal half
- Evidence: exact 69-byte routine image, all seven direct call instructions,
  exhaustive 65,792 X/Y machine-value cases, deterministic regeneration, and
  byte-identical build

### DATA-009 - horizontal runtime collision type `$A7`

- Status: resolved
- Known: the directional dispatch block contains six physical LE16 tables;
  each runtime table represents `$80-$A6`, while downward/upward `$A7`
  deliberately alias the following room table's first no-op pointer
- Hazard: the horizontal block has no following room table; indexing `$A7`
  crosses into `$926B-$926C` and produces the invalid pointer `$B060`
- Current sources: no static room object, cell-derived object, immediate load,
  or known transition creates runtime type `$A7`; `$A6` is created dynamically
- Closure: every PRG byte now belongs to a semantic or typed-data module; the
  complete loader, cell-derived creation, and dynamic object state machines
  create `$A0`, `$A1-$A6`, `$A8`, or `$A9`, never `$A7`
- Evidence: exact six-table decode, 12 consumers, three synthetic calls,
  complete object catalog and handler reconstruction, absence of a `$A7`
  runtime-type write, explicit validator rejection, and byte-identical build

### DATA-010 - code-shaped bytes at `$A2AA-$A2B0`

- Status: classified as unreferenced data
- Bytes: `98 4A 4A 4A 85 F8 60`, resembling `NmiTaskIndex = Y >> 3`
- Non-claim: no routine name is assigned because there is no direct, indirect,
  table, fallthrough, or runtime entry into the range
- Evidence: exact hash, all known dispatch tables, zero runtime code coverage,
  absence of a `$A2AA` pointer in PRG, typed-data Ghidra clearing, and exhaustive
  hypothetical Y-domain model

### DATA-011 - code-shaped bytes at `$8C7B-$8C7F`

- Status: classified as unreferenced data
- Bytes: `A6 41 4C 24 A0`, resembling `LDX CurrentObjectOffset` followed by a
  jump to the proven six-byte runtime-object clear tail at `$A024`
- Non-claim: no routine name is assigned; the preceding collectible handler
  ends in `RTS`, the next routine starts independently at `$8C80`, and no PRG
  word, Ghidra instruction, or captured runtime range enters any of the bytes
- Evidence: exact hash and boundary bytes, exhaustive whole-PRG pointer scan,
  zero static/runtime instruction starts, deterministic regeneration, and
  byte-identical build

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

### ROOM-002 - player room-boundary transitions

- Status: resolved
- Vertical: `$867A/$86A0` align player X down to eight pixels, set destination
  Y to `$98/$10`, save outgoing objects, move by ten rooms, reload, update the
  camera, and tail-call transition completion
- Horizontal: `$86C6/$870F` clamp X to `$0000/$0130` on the ten outer edges;
  interior crossings save state, move one room, reload, then probe 16 pixels
  above the new entrance and restore a matching mutable cell before completion
- Evidence: exact 222-byte hash, four direct jump sites, established navigation
  and mutable-cell helpers, 131,072 X-alignment cases, every room and Y value,
  both mutable-lookup outcomes, deterministic regeneration, and byte-identical
  build

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

### AUDIO-002 - textual MML interpreter boundaries and behavior

- Status: resolved
- Known: `$B906-$BADD` updates three four-byte stream states at X=`0,4,8`,
  parses octave/tempo/default-length/volume commands, emits notes and rests,
  and consumes zero terminators followed by little-endian restart pointers
- Arbitration: active sound effects suppress streamed APU writes; idle channels
  are gated when their countdown reaches three, using `$4015` masks
  `$0E/$0D/$0B`
- Boundary: `$BADE-$BAE8` is an 11-byte lowercase-hex-decoder-shaped sequence
  with no static or runtime entry; `$BAE9-$BB15` is the separately proven APU
  channel configurator
- Evidence: two static code ranges, one typed-data range, exact caller/hash
  validation, complete MML walk, exhaustive machine-width model, deterministic
  regeneration, and byte-identical build

### AUDIO-003 - sound-effect request engine

- Status: resolved
- Known: five entry points at `$C20D-$C2F8` synchronously configure pulse,
  triangle, and noise registers, then leave request IDs for the NMI updater at
  `$C2F9-$C428`
- Arbitration: each channel waits for both its setup-busy byte and corresponding
  APU length-counter status bit to clear; types 2, 3, 4, and 5 either clear or
  advance byte-wide step counters before completing
- Data: five tables at `$C429-$C43C` provide triangle/inventory periods and the
  three-byte noise envelope; sequence indexes include the `$FF -> 0` wrap case
- Naming: request types 1, 2, and 4 stay numeric because their gameplay callers
  remain inside preservation modules
- Evidence: exact hashes and call topology, starter write traces, exhaustive
  request/step arbitration, typed table bounds, NMI update order, deterministic
  regeneration, and byte-identical build

### SYS-003 - camera, unsigned division, and palette upload

- Status: resolved
- Camera: `$C43D-$C479` maps player X to pending scroll `$00-$80`, with a
  64-pixel left margin, a `2/3` middle slope, and saturation after delta `$C0`
- Division: `$C47A-$C4CC` is a destructive unsigned 16-bit divider; quotient
  occupies `$27-$28`, the dividend becomes the remainder, and zero divisor
  returns before scratch initialization
- Palette: `$C4CD-$C4FC` waits for vblank and emits 32 source bytes plus the
  final `$3F00` PPU address-latch reset, for 38 ordered `$2006/$2007` writes
- Evidence: three exact code hashes, all 15 direct callers, exhaustive camera
  and divider domains, exact PPU trace, deterministic regeneration, and
  byte-identical build
