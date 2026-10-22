# RAM map

| Range                     |   Size | Working name                                                        | Confidence | Evidence                                                                                             |
| ------------------------- | -----: | ------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------- |
| `$0000`                   |      1 | global NMI frame counter                                            | high       | increment in common NMI frame path and OAM order selection                                           |
| `$0001-$0002`             |      2 | high score, little-endian                                           | confirmed  | cold-boot clear, formatter, and conditional update from current score                                |
| `$0005-$000A`             |      6 | player inventory counters                                           | confirmed  | new-game clear and six-tile saturating HUD formatter                                                 |
| `$000B-$000C`             |      2 | current player score, little-endian                                 | confirmed  | new-game clear, point awards, formatter, and high-score comparison                                   |
| `$000D`                   |      1 | hazard-protection countdown, 32-frame units                         | confirmed  | hazard death guard, audio selection, transition carryover, and `$A847` decay                         |
| `$000E`                   |      1 | general invulnerability countdown, 32-frame units                   | confirmed  | death guard, audio selection, and `$A835` decay                                                      |
| `$0005-$0012`             |     14 | save/load runtime state, scoped to `$FBFE-$FDC4`                    | confirmed  | symmetric payload send/receive                                                                       |
| `$0013`                   |      1 | player lives                                                        | confirmed  | new-game value 3, HUD decimal formatter, save/load, save cost, death decrement, and game-over branch |
| `$0017`                   |      1 | data-I/O shift byte, scoped to `$8000-$8224`                        | confirmed  | both transmitters and receivers                                                                      |
| `$001A`                   |      1 | saved X for data-I/O wrappers, scoped to `$8000-$8224`              | confirmed  | byte send/receive entry points                                                                       |
| `$001F`                   |      1 | data transport selector, scoped to `$8000-$8224`                    | confirmed  | sign dispatches pulse vs expansion path                                                              |
| `$0020`                   |      1 | polled controller buttons, scoped to `$80FF-$8157`                  | confirmed  | both eight-bit serial pollers                                                                        |
| `$0034`                   |      1 | pending horizontal scroll X                                         | confirmed  | paused four-pixel adjustment and NMI latch application                                               |
| `$0035`                   |      1 | applied horizontal scroll X                                         | confirmed  | NMI copy from pending latch and PPU scroll write                                                     |
| `$0036`                   |      1 | horizontal-scroll update pending                                    | confirmed  | pause/OAM producers and NMI clear after application                                                  |
| `$0038-$0039`             |      2 | player X in pixels, little-endian                                   | confirmed  | movement, collision probes, save/load restoration, and 16-bit helpers                                |
| `$003A`                   |      1 | player Y in pixels                                                  | confirmed  | movement, collision probes, and save/load restoration                                                |
| `$003B-$003F`             |      5 | mutable-cell action direction/motion/delay view                     | high       | `$A5DD-$A66C` guard and horizontal-boundary behavior                                                 |
| `$00F8`                   |      1 | current NMI task index                                              | confirmed  | high/low handler dispatch and request scan                                                           |
| `$00F9-$00FA`             |      2 | NMI task handler pointer, little-endian                             | confirmed  | indirect NMI jump                                                                                    |
| `$00FB`                   |      1 | OAM staging busy flag                                               | high       | foreground sprite build and NMI DMA-buffer rebuild interlock                                         |
| `$00FC`                   |      1 | NMI frame countdown                                                 | confirmed  | main-loop load/wait and saturating NMI decrement                                                     |
| `$0037`                   |      1 | current one-based room number                                       | confirmed  | loader indexing, visited flags, transition helpers, and all 100 navigation cases                     |
| `$0041`                   |      1 | current object-record offset                                        | high       | sprite dispatch trace                                                                                |
| `$0043`                   |      1 | current runtime-object update offset                                | confirmed  | `$9583` initializes it and advances by six through all 24 records; handlers reuse it                 |
| `$004A-$00D9`             |  `$90` | 24 six-byte runtime object records                                  | confirmed  | loader, all update/render consumers, and full-record clear paths                                     |
| `$00DA`                   |      1 | shared audio tempo-table offset                                     | confirmed  | `t` command and all three streamed-note duration lookups                                             |
| `$00DB-$00E6`             |     12 | three four-byte audio stream states                                 | confirmed  | pointer, countdown, and octave fields indexed by X=`0,4,8`                                           |
| `$00E7-$00E8`             |      2 | pulse 1/2 streamed-note parameters                                  | confirmed  | track records and pulse channel setup                                                                |
| `$00E9-$00EB`             |      3 | pulse 1, pulse 2, and triangle default-length indexes               | confirmed  | `l` command and note/rest duration selection                                                         |
| `$00EC,$00EF,$00F2,$00F5` |      4 | pulse 1, pulse 2, triangle, and noise sound-effect requests         | confirmed  | request clear, channel arbitration, and sound-effect starters                                        |
| `$00F0,$00F3,$00F6`       |      3 | pulse 2, triangle, and noise sound-effect steps                     | confirmed  | per-frame effect sequences and starter resets                                                        |
| `$0100-$017F`             |  `$80` | left/right room attribute buffers                                   | confirmed  | builder + NMI uploads to `$23C8/$27C8`                                                               |
| `$0200-$02FF`             | `$100` | final OAM DMA buffer                                                | confirmed  | `$4014 = $02`                                                                                        |
| `$0300-$03FF`             | `$100` | OAM staging buffer                                                  | confirmed  | copy into `$0200`                                                                                    |
| `$0400-$058F`             | `$190` | 20x20 decoded room cells                                            | confirmed  | decoder output                                                                                       |
| `$0590-$05FB`             |  `$6C` | packed persistent mutable-cell bits                                 | confirmed  | 101 offsets + symmetric load/save + all-room cell check                                              |
| `$0608-$0694`             |  `$8D` | one packed persistent bit per static room object                    | confirmed  | 101 offsets + load/save routines + all-room count check                                              |
| `$069E-$0701`             |  `$64` | one-byte visited flag per one-based room                            | confirmed  | initialization and `LoadRoom` indexed write                                                          |
| `$0702-$0711`             |  `$10` | ASCII bit lookahead                                                 | confirmed  | room decoder                                                                                         |
| `$0712-$071A`             |      9 | active room id + object/cell state bitmaps                          | confirmed  | persistent loader and snapshot restore                                                               |
| `$071B-$0723`             |      9 | room-state load mirror                                              | confirmed  | snapshot rotation and selected-state copy                                                            |
| `$0724-$072C`             |      9 | room-state snapshot A                                               | confirmed  | transition save/restore paths                                                                        |
| `$072D-$0735`             |      9 | room-state snapshot B                                               | confirmed  | transition restore + persistent saver                                                                |
| `$0736-$0744`             |     15 | room runtime load mirror                                            | confirmed  | state-selection copy                                                                                 |
| `$0745-$0752`             |     14 | room runtime snapshot A                                             | confirmed  | snapshot rotation                                                                                    |
| `$0754-$0761`             |     14 | room runtime snapshot B                                             | confirmed  | snapshot rotation                                                                                    |
| `$0763-$076A`             |      8 | frame counters modulo `3,5,6,7,3,10,11,30`                          | confirmed  | common NMI counter chain                                                                             |
| `$076B`                   |      1 | room frame counter                                                  | high       | one increment per unpaused simulation update and animation consumers                                 |
| `$076C-$0771`             |      6 | formatted inventory counter tiles                                   | confirmed  | formatter and NMI upload to `$2087-$208C`                                                            |
| `$0772`                   |      1 | player transition/respawn countdown                                 | confirmed  | death loads `$80`, frame update decrements to player/room restoration, load/new-game clear it        |
| `$0775-$0776`             |      2 | controller 1/2 button masks                                         | confirmed  | NMI polling and named controller bit order                                                           |
| `$0777-$0778`             |      2 | previous controller 1/2 masks                                       | high       | edge-triggered input consumers                                                                       |
| `$077C`                   |      1 | player touching hazard cell `$16/$62/$63`                           | confirmed  | bottom-center room probe and collision-to-death path                                                 |
| `$077E-$0780`             |      3 | power-on signature RAM (`POW`)                                      | confirmed  | reset compare/copy loop and ROM signature                                                            |
| `$0783-$0784`             |      2 | reset counter, little-endian                                        | confirmed  | cold-boot clear and carry increment on every reset                                                   |
| `$0785-$079B`             |     23 | NMI task requests                                                   | confirmed  | reset loop and indexed NMI dispatch                                                                  |
| `$079D-$07A4`             |      8 | score-format buffer: five tiles, terminator, two cleared tail bytes | confirmed  | formatter lock/clear and score conversion                                                            |
| `$07A2`                   |      1 | score tile terminator during room load                              | confirmed  | explicit zero before PPU copy                                                                        |
| `$07A5-$07A7`             |      3 | formatted lives tiles                                               | confirmed  | lives formatter and two-tile NMI upload                                                              |
| `$07C4`                   |      1 | pause mode                                                          | confirmed  | Start edge toggles, A/B resumes, and nonzero suppresses simulation/audio updates                     |
| `$07C5`                   |      1 | castle-map mode                                                     | confirmed  | Select opens map and suppresses normal NMI/main-loop work                                            |
| `$07C7`                   |      1 | demo playback active                                                | high       | title loop, alternate NMI input, and physical Start exit                                             |
| `$07C8`                   |      1 | status-tile formatter busy flag                                     | confirmed  | formatter interlock and NMI fallback to room-row upload                                              |
| `$07CC`                   |      1 | game-over active                                                    | confirmed  | set when death consumes the final life; blocks sub-command/audio paths and selects ending behavior   |
| `$07CE`                   |      1 | physical controller 1 buttons                                       | confirmed  | unconditional NMI poll used to exit demo playback                                                    |
| `$07D0-$07D3`             |      4 | pulse 1, pulse 2, triangle, and noise sound-effect busy flags       | confirmed  | channel-specific SFX starters and common sound-effect updater                                        |

The room decoder also gives contextual names to shared zero-page scratch: `$16`
bit index, `$17` lookahead write index, `$19` decoded cell, `$21-$22` CHR stream
pointer, `$23-$24` codebook pointer, `$25-$26` output offset, and `$29-$2A`
output pointer. These aliases are scoped to `$E7EC-$E8DE` in the RAM aliases of
releases 1.0 to 3.0; they do not claim that the bytes have the same meaning
elsewhere.

Controller polling contextually names `$20` as `PolledControllerButtons`. After
eight ROR operations it contains A/B/Select/Start/Up/Down/Left/Right in bits
0-7. This scoped name does not claim the same meaning for unrelated uses of
`$20` elsewhere in the PRG.

Famicom data I/O contextually names `$17` as the byte shift buffer, `$1A` as the
preserved X register, and `$1F` as the transport selector. The pulse path also
owns `$2D-$30` as accumulated width, remaining-bit count, leader-page count, and
sampled input level. These aliases are restricted to `$8000-$8224`; the same
zero-page bytes have unrelated meanings elsewhere.

Save/load orchestration contextually views `$05-$12` as the 14-byte runtime
payload and `$13` as its separate tail byte. Runtime offsets 11-13 restore the
global player X/Y fields before the loaded room and player-adjacent mutable cell
are rebuilt.

Within `$867A-$8757`, `$10-$12` hold the destination player X low/high and Y
saved into transition state before the outgoing room is serialized. `$07CD` is
cleared before each real room reload. Vertical paths align the low X byte with
`$F8`; horizontal paths use the exact entrance/clamp coordinates `$0000` and
`$0130`. These aliases are scoped separately from the later transition reload
view of the same zero-page bytes.

Within `$93F6-$9551`, zero-page `$10-$12` are the saved player X low/high and Y
bytes restored after death and later copied into
`RoomRuntimeLoadMirror + $0B..$0D`. Bytes `$0D-$0E` are two additional
transition-state values copied to `$14-$15`; `$14` feeds the protection
extension on death reload. `$16-$18` and `$19-$1D` temporarily carry the
three-byte object and five-byte mutable-cell persistent state into the apply
routine. `$07CD` selects the fixed protection base during transition reload.
These names remain scoped because the same scratch addresses serve unrelated
code elsewhere.

Within `$8758-$8784`, the same zero-page `$16-$18` bytes are the outgoing room
object-state accumulator. Each of the 24 runtime-record type bytes contributes
one bit before the completed three-byte value is copied to `$0713-$0715`.

Within `$8785-$8819`, `$21-$22` hold the candidate player X and `$23-$24` hold
the right-edge collision probe. A successful animated-cell displacement sets the
contextual movement latch at `$0774`; blocked paths preserve it.

Within `$9583-$95BE`, `$31-$32` are the little-endian runtime-object handler
pointer and `$07C6` is the shared update flag cleared before each record. The
pointer aliases remain scoped to the dispatcher; `$0043` is global because the
selected handlers repeatedly recover the same current six-byte record offset.

Within `$965C-$9795`, `$21-$22` hold the pushable candidate X and `$23-$24` hold
its right entering edge. `$16` first stores support Y and then the selected
collision identity; `$1E-$1F` retain the prior support identity and hit count.
The collision sampler supplies the contacted runtime-record offset in `$42`.
Successful conveyor motion writes `$7F/$FF` to contextual latch `$0773`; lift-
control type `$8E` consumes the same latch after the shared physics returns.

Within `$89E1-$8C11`, `$1E/$1F` retain the runtime offsets of the cell-derived
`$A4/$A5` linked-lift pair and `$1C` retains the secondary clearance Y. The
room-cell phase uses `$29` and `$2B/$2C`; `$44/$45` then carry its row-update
address. During raising, `$44-$47` become the overlap span, `$16/$17` drive the
closure scan, and `$16` is reused as the movement slot. `$07AB-$07C3` is the
same 24-object-plus-player occupant set shared with the autonomous lift code.

Within `$9796-$9A36`, `$2B-$2C` point into the 20x20 room cell buffer and
`$44-$47` alternate between row-update addresses and lift/occupant collision
spans. `$16-$17` are closure and scan indexes before `$16` becomes the movement
slot. `$07AB-$07C3` is a 25-byte occupant flag set: 24 runtime-object slots
followed by the player flag. The helper at `$9A1F` maps six-byte record offsets
to these slots, and `$9A2C` clears the complete set.

Within `$9A37-$9AAC`, `$44-$45` expose the Flying Block contact X after a
successful two-pixel move. The rightward path stores new X plus five; the
leftward path preserves the previous origin. This contextual output remains
scoped because later object handlers reuse both scratch bytes.

Within `$9B00-$9C3A`, `$22` extends the walking enemy's probe X, while `$29` and
`$2B` consume the room-cell address prepared for the hazard probe. `$07C6` is
the shared per-object update flag: falling and completed patrol motion clear it,
while a set value suppresses the ledge probe for the current update.

At `$9CC6-$9D64`, `$16` stores the Fairy's frame-derived low Y bit. Fighter
consumes the biased player-X separation in `$21-$22` and uses `$07C6` to pass
near-player and active-jump state into the shared walking-enemy update.

At `$9EA8-$9ECA`, `$21-$22` receive the biased 16-bit player-X separation and
`$24` preserves the signed high byte before magnitude conversion. Consumers can
therefore use both distance-like magnitude and original side information.

Within `$9ECB-$9F73`, `$21-$22` hold the Witch's candidate summon X and `$16`
holds its Y while four collision corners are sampled and the first free runtime
record is located. Those values are copied unchanged into summon type `$A0`.

Within `$9F74-$9FF2`, `$21-$22` hold the Knight arrow's leading-edge X and `$16`
holds its Y across the two collision samples. The left-moving path keeps the
candidate X there until both probes succeed, then commits it to the record.

Within `$8DD3-$8ECA`, `$1B` and `$27-$28` retain the rebased Y and 16-bit X
sample. `$1D` scans the 24 runtime records; `$29` selects the room-cell column;
and `$2B-$2C` first address the room row, then hold the object-relative X delta.
Scoped `$07CB` is a one-shot nonzero request to accept only runtime types
`$90-$95`, and is cleared on every return. `$3C` and `$40` provide the player
motion and room-cell animation phases used by the two special cases.

Within `$9477-$949B`, `$31-$32` are the selected player collision-handler
pointer. The dispatcher fills them from the room-cell or runtime-object table,
then consumes them in a synthetic indirect call.

Within `$8ECB-$8F0F`, `$27-$28` and `$1B` retain the caller's 16-bit X and byte
Y. `$29-$2A` become X shifted right four places, while `$2B-$2C` hold the first
room-cell address for row `Y >> 3`. These aliases are scoped to the shared
sample-address builder.

Within `$A0C4-$A1A2`, `$1B` and `$27-$28` retain the sampled Y and 16-bit X,
while `$1D` indexes the 24-slot runtime pool. During room lookup `$29-$2C` form
the cell column and pointer; during object lookup `$2B-$2C` become the 16-bit X
delta. `$40` is the shared room-cell animation counter whose sign suppresses
`$45-$48` collision flags, and `$42` receives the matched object offset. The
adjacent room-only sampler reuses the coordinate, pointer, and animation fields
through `$A1D3`; all aliases remain scoped to these samplers.

Within `$A2B1-$A350`, `$05-$12` are treated as one 14-byte new-game runtime
record. Scoped names also cover its transition byte, player motion/cell state,
collision probe state, and two motion counters without asserting those scratch
meanings outside initialization. The routine copies the 14-byte record before
writing initial Y `$98`, preserves load-mirror byte 14, and invalidates snapshot
B by clearing only `$072D`. `$21-$22` are separately scoped to the `$A351`
room-palette pointer setup.

Within `$A3AC-$A3C5`, scoped aliases identify two player movement state bytes, a
movement delay and latch, both scroll reset bytes, the object-update shared
flag, and the room animation counter. The routine also clears the global NMI
task index and room frame counter. These reset names describe proven ownership
without claiming complete semantics for the movement fields elsewhere.

Within `$82CE-$8679`, `$3B` is the signed horizontal direction (`$FF` left,
`$7F` right), `$3C` is the vertical motion state, `$3E` is its rendering phase,
and `$3F` is the horizontal delay. `$0774` carries forced movement from an
animated cell; `$0779-$077A` hold action countdown/latch state; `$07C9-$07CA`
gate grounded direction and jump changes; `$07CB` enables object filtering for
horizontal probes. Scoped scratch names separate upward Y, downward collision
samples, horizontal probe/candidate X, action probe/delta X, and the shared
collision-handler pointer at `$31-$32`.

Within `$881A-$89E0`, `$1C` preserves the pushed runtime-record offset while
player collision sampling reuses the global current-object field. `$25-$26` hold
the pushed object's leading-edge X, `$42` identifies a destroyable object
returned by the point sampler, and `$0773` receives `$7F/$FF` after a successful
right/left push. Scoped `$3B/$3C/$3E` aliases expose direction and the motion
guard without extending those meanings into unrelated object handlers.

Within `$C43D-$C479`, `$27` receives the low byte of the camera quotient,
`$29-$2A` hold the fixed divisor three, and `$2B-$2C` hold twice the player X
offset from the 64-pixel left margin. The result is clamped to `$00-$80` and
stored in the global pending-scroll byte. The adjacent divider at `$C47A-$C4CC`
expands that view to `$25-$26` for the shifting bit, `$27-$28` for the quotient,
`$29-$2A` for the destructive divisor, and `$2B-$2C` for the dividend that
becomes the remainder. All arithmetic aliases remain scoped.

Within `$C4CD-$C4FC`, `$21-$22` are the source pointer for the 32-byte palette
copied to PPU `$3F00`. The uploader consumes Y=`$00-$1F`, then rewrites the PPU
address latch to `$3F00`; the pointer meaning is limited to this routine.

Within `$A3D2-$A47E`, `$21-$22` are the pointer that scans `RoomCells`, `$40` is
the intermittent room-cell animation counter, and `$44-$45` receive the current
cell address before the row-update helper consumes them. The animation counter
advances only on odd room simulation frames; its sign bit gates the slow
`$45-$48` family.

Within `$A497-$A4DA`, `$03-$04` are the 16-bit remainder consumed by repeated
decimal-place subtraction. The status formatter proves `$05-$0A` as six
inventory counters in its own scoped operand view and uses `$07C8=$FF/$00` as
the foreground/NMI lock/ready protocol.

Within `$A5DD-$A66C`, `$05-$0A` are the same six inventory counters. `$1E` is
the collision probe Y moved upward by 16 pixels; `$21-$22` are its 16-bit X;
`$3B` supplies signed facing direction; `$3C/$3E` gate active motion; and `$3F`
receives a nine-frame movement delay only at the outward horizontal bounds.
These scratch names remain scoped because their broader player-movement roles
are not yet fully reconstructed.

Within `$AC13-$ADE6`, `$16` is the next free byte offset in staging OAM and
starts at `$0C`; `$31-$32` hold the selected object render-handler pointer.
Scoped views name `$3B` as signed player direction, `$3C/$3E` as the motion
state/phase used for frame selection, and `$0779` as the action countdown. The
selector clears the phase after emitting the player metasprite.

Within `$B1D6-$B4B5`, `$21-$22` hold the selected tile/attribute descriptor,
`$2B-$2C` hold a component's 16-bit world X, and `$1B` receives its low-byte
screen X after subtracting pending scroll `$34`. Object paths append through
`$16`; the player path writes fixed records zero and one. `$18` is named only as
the player renderer's dead-read state because two shifts and `TXA` discard it
before any observable use.

Room-cell lookup contextually names `$2B-$2C` as the pointer into the 400-byte
matrix and `$21-$22` as the saved tile column/row. Mutable-cell restoration uses
`$1F` for the original ordinal, `$29-$2A` for its scan pointer, and `$44-$45`
for the selected cell address passed to the row-update helper. Each alias is
restricted to its `$A5A4-$A7DA` consumer range.

Within `$949C-$94DA`, `$44-$45` is independently named as the destructive
room-cell update pointer. The helper shifts it twice before deriving the row;
callers must treat the pair as consumed. `NmiTaskRequests` is sized to all 23
bytes, so generated indexed operands use relocatable `+1` and `+2` expressions.

The object loader and all update/render consumers prove the complete six-byte
record contract: `+0` runtime type, `+1/+2` little-endian X in pixels, `+3` Y in
pixels, `+4` polymorphic primary state, and `+5` polymorphic auxiliary state.
Field `+5` has contextual source aliases for Fighter jump countdown, Knight
arrow cooldown, Flame movement mode, Flying Block stop state, and
collected-object lifetime; generic lifecycle code names it `RuntimeObjectAux`.
The complete per-consumer interpretation is recorded in `docs/data_formats.md`.
The loader uses contextual aliases for `$1A` as the X high-byte scratch and
`$21-$22` as the static-object stream pointer within `$EBE9-$EC62`.

The type `$81` collision handler uses `$D4-$D7`, the first four bytes of the
24th and final runtime record (`RuntimeObjectRecords + $8A`), as a clone slot in
room `$59`. It deliberately leaves that record's state and auxiliary byte
untouched; the scoped names claim only the four fields actually written.

Ending code contextually names `$21-$22` as the game-over message pointer at
`$FE31-$FE54` and as the completion palette pointer at `$FE8E-$FEA0`. `$0B-$0C`
are separately scoped as the player score in the shared high-score update at
`$FED5-$FEE7`.

Within `$A8A9-$A8E2`, `$25-$26` are the low/high scratch pair holding the
normalized runtime-object/player X delta. The aliases are scoped to the shared
proximity predicate because both bytes have unrelated uses elsewhere.

`$079A` and `$079B` are the NMI task requests for the left and right room
attribute uploads. They are entries 21 and 22 of the task-request array at
`$0785`; the NMI dispatcher resolves them to handlers at `$E1F8` and `$E358`.

The remaining zero page and RAM fields are intentionally unnamed until the
matching PRG listing and runtime traces provide evidence.

Both OAM arrays and the 400-byte `RoomCells` matrix are sized memory symbols.
Generated operands inside their ranges therefore use relocatable expressions
such as `OamStagingBuffer + $21,Y` and `RoomCells + $18F`, while ca65 still
selects the original absolute addressing mode and the reconstructed ROM remains
byte-identical.

Within `$EA36-$EB6B`, scoped zero-page aliases identify the map-availability
flag at `$0F`, the zero-based room iterator at `$1F`, and the computed PPU
address at `$21-$22`. Their meanings are not asserted outside the map module.
