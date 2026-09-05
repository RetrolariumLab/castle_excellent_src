# RAM map

| Range | Size | Working name | Confidence | Evidence |
| --- | ---: | --- | --- | --- |
| `$0000` | 1 | global NMI frame counter | high | increment in common NMI frame path and OAM order selection |
| `$0001-$0002` | 2 | high score, little-endian | confirmed | cold-boot clear, formatter, and conditional update from current score |
| `$0005-$000A` | 6 | player inventory counters | confirmed | new-game clear and six-tile saturating HUD formatter |
| `$000B-$000C` | 2 | current player score, little-endian | confirmed | new-game clear, point awards, formatter, and high-score comparison |
| `$000D` | 1 | hazard-protection countdown, 32-frame units | confirmed | hazard death guard, audio selection, transition carryover, and `$A847` decay |
| `$000E` | 1 | general invulnerability countdown, 32-frame units | confirmed | death guard, audio selection, and `$A835` decay |
| `$0005-$0012` | 14 | save/load runtime state, scoped to `$FBFE-$FDC4` | confirmed | symmetric payload send/receive |
| `$0013` | 1 | player lives | confirmed | new-game value 3, HUD decimal formatter, save/load, save cost, death decrement, and game-over branch |
| `$0017` | 1 | data-I/O shift byte, scoped to `$8000-$8224` | confirmed | both transmitters and receivers |
| `$001A` | 1 | saved X for data-I/O wrappers, scoped to `$8000-$8224` | confirmed | byte send/receive entry points |
| `$001F` | 1 | data transport selector, scoped to `$8000-$8224` | confirmed | sign dispatches pulse vs expansion path |
| `$0020` | 1 | polled controller buttons, scoped to `$80FF-$8157` | confirmed | both eight-bit serial pollers |
| `$0034` | 1 | pending horizontal scroll X | confirmed | paused four-pixel adjustment and NMI latch application |
| `$0035` | 1 | applied horizontal scroll X | confirmed | NMI copy from pending latch and PPU scroll write |
| `$0036` | 1 | horizontal-scroll update pending | confirmed | pause/OAM producers and NMI clear after application |
| `$0038-$0039` | 2 | player X in pixels, little-endian | confirmed | movement, collision probes, save/load restoration, and 16-bit helpers |
| `$003A` | 1 | player Y in pixels | confirmed | movement, collision probes, and save/load restoration |
| `$003B-$003F` | 5 | mutable-cell action direction/motion/delay view | high | `$A5DD-$A66C` guard and horizontal-boundary behavior |
| `$00F8` | 1 | current NMI task index | confirmed | high/low handler dispatch and request scan |
| `$00F9-$00FA` | 2 | NMI task handler pointer, little-endian | confirmed | indirect NMI jump |
| `$00FB` | 1 | OAM staging busy flag | high | foreground sprite build and NMI DMA-buffer rebuild interlock |
| `$00FC` | 1 | NMI frame countdown | confirmed | main-loop load/wait and saturating NMI decrement |
| `$0037` | 1 | current one-based room number | confirmed | loader indexing, visited flags, transition helpers, and all 100 navigation cases |
| `$0041` | 1 | current object-record offset | high | sprite dispatch trace |
| `$0043` | 1 | current runtime-object update offset | confirmed | `$9583` initializes it and advances by six through all 24 records; handlers reuse it |
| `$004A-$00D9` | `$90` | 24 six-byte object records | confirmed | clear/load loops |
| `$0100-$017F` | `$80` | left/right room attribute buffers | confirmed | builder + NMI uploads to `$23C8/$27C8` |
| `$0200-$02FF` | `$100` | final OAM DMA buffer | confirmed | `$4014 = $02` |
| `$0300-$03FF` | `$100` | OAM staging buffer | confirmed | copy into `$0200` |
| `$0400-$058F` | `$190` | 20x20 decoded room cells | confirmed | decoder output |
| `$0590-$05FB` | `$6C` | packed persistent mutable-cell bits | confirmed | 101 offsets + symmetric load/save + all-room cell check |
| `$0608-$0694` | `$8D` | one packed persistent bit per static room object | confirmed | 101 offsets + load/save routines + all-room count check |
| `$069E-$0701` | `$64` | one-byte visited flag per one-based room | confirmed | initialization and `LoadRoom` indexed write |
| `$0702-$0711` | `$10` | ASCII bit lookahead | confirmed | room decoder |
| `$0712-$071A` | 9 | active room id + object/cell state bitmaps | confirmed | persistent loader and snapshot restore |
| `$071B-$0723` | 9 | room-state load mirror | confirmed | snapshot rotation and selected-state copy |
| `$0724-$072C` | 9 | room-state snapshot A | confirmed | transition save/restore paths |
| `$072D-$0735` | 9 | room-state snapshot B | confirmed | transition restore + persistent saver |
| `$0736-$0744` | 15 | room runtime load mirror | confirmed | state-selection copy |
| `$0745-$0752` | 14 | room runtime snapshot A | confirmed | snapshot rotation |
| `$0754-$0761` | 14 | room runtime snapshot B | confirmed | snapshot rotation |
| `$0763-$076A` | 8 | frame counters modulo `3,5,6,7,3,10,11,30` | confirmed | common NMI counter chain |
| `$076B` | 1 | room frame counter | high | one increment per unpaused simulation update and animation consumers |
| `$076C-$0771` | 6 | formatted inventory counter tiles | confirmed | formatter and NMI upload to `$2087-$208C` |
| `$0772` | 1 | player transition/respawn countdown | confirmed | death loads `$80`, frame update decrements to player/room restoration, load/new-game clear it |
| `$0775-$0776` | 2 | controller 1/2 button masks | confirmed | NMI polling and named controller bit order |
| `$0777-$0778` | 2 | previous controller 1/2 masks | high | edge-triggered input consumers |
| `$077C` | 1 | player touching hazard cell `$16/$62/$63` | confirmed | bottom-center room probe and collision-to-death path |
| `$077E-$0780` | 3 | power-on signature RAM (`POW`) | confirmed | reset compare/copy loop and ROM signature |
| `$0783-$0784` | 2 | reset counter, little-endian | confirmed | cold-boot clear and carry increment on every reset |
| `$0785-$079B` | 23 | NMI task requests | confirmed | reset loop and indexed NMI dispatch |
| `$079D-$07A4` | 8 | score-format buffer: five tiles, terminator, two cleared tail bytes | confirmed | formatter lock/clear and score conversion |
| `$07A2` | 1 | score tile terminator during room load | confirmed | explicit zero before PPU copy |
| `$07A5-$07A7` | 3 | formatted lives tiles | confirmed | lives formatter and two-tile NMI upload |
| `$07C4` | 1 | pause mode | confirmed | Start edge toggles, A/B resumes, and nonzero suppresses simulation/audio updates |
| `$07C5` | 1 | castle-map mode | confirmed | Select opens map and suppresses normal NMI/main-loop work |
| `$07C7` | 1 | demo playback active | high | title loop, alternate NMI input, and physical Start exit |
| `$07C8` | 1 | status-tile formatter busy flag | confirmed | formatter interlock and NMI fallback to room-row upload |
| `$07CC` | 1 | game-over active | confirmed | set when death consumes the final life; blocks sub-command/audio paths and selects ending behavior |
| `$07CE` | 1 | physical controller 1 buttons | confirmed | unconditional NMI poll used to exit demo playback |
| `$07D0-$07D3` | 4 | pulse 1, pulse 2, triangle, and noise sound-effect busy flags | confirmed | channel-specific SFX starters and common sound-effect updater |

The room decoder also gives contextual names to shared zero-page scratch:
`$16` bit index, `$17` lookahead write index, `$19` decoded cell, `$21-$22`
CHR stream pointer, `$23-$24` codebook pointer, `$25-$26` output offset, and
`$29-$2A` output pointer. These aliases are scoped to `$E7EC-$E8DE` in
`config/memory_symbols.json`; they do not claim that the bytes have the same
meaning elsewhere.

Controller polling contextually names `$20` as `PolledControllerButtons`.
After eight ROR operations it contains A/B/Select/Start/Up/Down/Left/Right in
bits 0-7. This scoped name does not claim the same meaning for unrelated uses
of `$20` elsewhere in the PRG.

Famicom data I/O contextually names `$17` as the byte shift buffer, `$1A` as
the preserved X register, and `$1F` as the transport selector. The pulse path
also owns `$2D-$30` as accumulated width, remaining-bit count, leader-page
count, and sampled input level. These aliases are restricted to
`$8000-$8224`; the same zero-page bytes have unrelated meanings elsewhere.

Save/load orchestration contextually views `$05-$12` as the 14-byte runtime
payload and `$13` as its separate tail byte. Runtime offsets 11-13 restore the
global player X/Y fields before the loaded room and player-adjacent mutable cell
are rebuilt.

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

Within `$8785-$8819`, `$21-$22` hold the candidate player X and `$23-$24`
hold the right-edge collision probe. A successful animated-cell displacement
sets the contextual movement latch at `$0774`; blocked paths preserve it.

Within `$9583-$95BE`, `$31-$32` are the little-endian runtime-object handler
pointer and `$07C6` is the shared update flag cleared before each record. The
pointer aliases remain scoped to the dispatcher; `$0043` is global because the
selected handlers repeatedly recover the same current six-byte record offset.

Within `$8DD3-$8ECA`, `$1B` and `$27-$28` retain the rebased Y and 16-bit X
sample. `$1D` scans the 24 runtime records; `$29` selects the room-cell column;
and `$2B-$2C` first address the room row, then hold the object-relative X delta.
Scoped `$07CB` is a one-shot nonzero request to accept only runtime types
`$90-$95`, and is cleared on every return. `$3C` and `$40` provide the player
motion and room-cell animation phases used by the two special cases.

Within `$9477-$949B`, `$31-$32` are the selected player collision-handler
pointer. The dispatcher fills them from the room-cell or runtime-object table,
then consumes them in a synthetic indirect call.

Within `$8ECB-$8F0F`, `$27-$28` and `$1B` retain the caller's 16-bit X and
byte Y. `$29-$2A` become X shifted right four places, while `$2B-$2C` hold the
first room-cell address for row `Y >> 3`. These aliases are scoped to the
shared sample-address builder.

Within `$A0C4-$A1A2`, `$1B` and `$27-$28` retain the sampled Y and 16-bit X,
while `$1D` indexes the 24-slot runtime pool. During room lookup `$29-$2C`
form the cell column and pointer; during object lookup `$2B-$2C` become the
16-bit X delta. `$40` is the shared room-cell animation counter whose sign
suppresses `$45-$48` collision flags, and `$42` receives the matched object
offset. The adjacent room-only sampler reuses the coordinate, pointer, and
animation fields through `$A1D3`; all aliases remain scoped to these samplers.

Within `$A2B1-$A350`, `$05-$12` are treated as one 14-byte new-game runtime
record. Scoped names also cover its transition byte, player motion/cell state,
collision probe state, and two motion counters without asserting those scratch
meanings outside initialization. The routine copies the 14-byte record before
writing initial Y `$98`, preserves load-mirror byte 14, and invalidates snapshot
B by clearing only `$072D`. `$21-$22` are separately scoped to the `$A351`
room-palette pointer setup.

Within `$A3AC-$A3C5`, scoped aliases identify two player movement state bytes,
a movement delay and latch, both scroll reset bytes, the object-update shared
flag, and the room animation counter. The routine also clears the global NMI
task index and room frame counter. These reset names describe proven ownership
without claiming complete semantics for the movement fields elsewhere.

Within `$A3D2-$A47E`, `$21-$22` are the pointer that scans `RoomCells`, `$40`
is the intermittent room-cell animation counter, and `$44-$45` receive the
current cell address before the row-update helper consumes them. The animation
counter advances only on odd room simulation frames; its sign bit gates the
slow `$45-$48` family.

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
state/phase used for frame selection, and `$0779` as the action countdown.
The selector clears the phase after emitting the player metasprite.

Within `$B1D6-$B4B5`, `$21-$22` hold the selected tile/attribute descriptor,
`$2B-$2C` hold a component's 16-bit world X, and `$1B` receives its low-byte
screen X after subtracting pending scroll `$34`. Object paths append through
`$16`; the player path writes fixed records zero and one. `$18` is named only
as the player renderer's dead-read state because two shifts and `TXA` discard
it before any observable use.

Room-cell lookup contextually names `$2B-$2C` as the pointer into the 400-byte
matrix and `$21-$22` as the saved tile column/row. Mutable-cell restoration
uses `$1F` for the original ordinal, `$29-$2A` for its scan pointer, and
`$44-$45` for the selected cell address passed to the row-update helper. Each
alias is restricted to its `$A5A4-$A7DA` consumer range.

Within `$949C-$94DA`, `$44-$45` is independently named as the destructive
room-cell update pointer. The helper shifts it twice before deriving the row;
callers must treat the pair as consumed. `NmiTaskRequests` is sized to all 23
bytes, so generated indexed operands use relocatable `+1` and `+2` expressions.

The object loader and state-application path prove the first five bytes of each
six-byte record: `+0` runtime type, `+1/+2` little-endian X in pixels, `+3` Y in
pixels, and `+4` runtime state. They use contextual aliases for `$1A` as the X
high-byte scratch and `$21-$22` as the static-object stream pointer within
`$EBE9-$EC62`. Record `+5` is named only as `RuntimeObjectByte5`; its semantic
meaning remains intentionally open.

The type `$81` collision handler uses `$D4-$D7`, the first four bytes of the
24th and final runtime record (`RuntimeObjectRecords + $8A`), as a clone slot
in room `$59`. It deliberately leaves that record's state and byte `+5`
untouched; the scoped names claim only the four fields actually written.

Ending code contextually names `$21-$22` as the game-over message pointer at
`$FE31-$FE54` and as the completion palette pointer at `$FE8E-$FEA0`.
`$0B-$0C` are separately scoped as the player score in the shared high-score
update at `$FED5-$FEE7`.

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
