# RAM map

| Range | Size | Working name | Confidence | Evidence |
| --- | ---: | --- | --- | --- |
| `$0000` | 1 | global NMI frame counter | high | increment in common NMI frame path and OAM order selection |
| `$0001-$0002` | 2 | player score, little-endian | high | cold-boot clear and score formatter |
| `$0020` | 1 | polled controller buttons, scoped to `$80FF-$8157` | confirmed | both eight-bit serial pollers |
| `$00F8` | 1 | current NMI task index | confirmed | high/low handler dispatch and request scan |
| `$00F9-$00FA` | 2 | NMI task handler pointer, little-endian | confirmed | indirect NMI jump |
| `$00FB` | 1 | OAM staging busy flag | high | foreground sprite build and NMI DMA-buffer rebuild interlock |
| `$00FC` | 1 | NMI frame countdown | confirmed | main-loop load/wait and saturating NMI decrement |
| `$0037` | 1 | current room index | high | object-loader trace |
| `$0041` | 1 | current object-record offset | high | sprite dispatch trace |
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
| `$0775-$0776` | 2 | controller 1/2 button masks | confirmed | NMI polling and named controller bit order |
| `$0777-$0778` | 2 | previous controller 1/2 masks | high | edge-triggered input consumers |
| `$077E-$0780` | 3 | power-on signature RAM (`POW`) | confirmed | reset compare/copy loop and ROM signature |
| `$0783-$0784` | 2 | reset counter, little-endian | confirmed | cold-boot clear and carry increment on every reset |
| `$0785-$079B` | 23 | NMI task requests | confirmed | reset loop and indexed NMI dispatch |
| `$079D-$07A1` | 5 | formatted score tiles | high | room status pointer and formatter |
| `$07A2` | 1 | score tile terminator during room load | confirmed | explicit zero before PPU copy |
| `$07A5-$07A7` | 3 | formatted lives tiles | confirmed | lives formatter and two-tile NMI upload |
| `$07C4` | 1 | pause mode | confirmed | Start edge toggles simulation and audio updates |
| `$07C5` | 1 | castle-map mode | confirmed | Select opens map and suppresses normal NMI/main-loop work |
| `$07C7` | 1 | demo playback active | high | title loop, alternate NMI input, and physical Start exit |
| `$07C8` | 1 | status-tile formatter busy flag | confirmed | formatter interlock and NMI fallback to room-row upload |
| `$07CE` | 1 | physical controller 1 buttons | confirmed | unconditional NMI poll used to exit demo playback |

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

The object loader and state-application path prove the first five bytes of each
six-byte record: `+0` runtime type, `+1/+2` little-endian X in pixels, `+3` Y in
pixels, and `+4` runtime state. They use contextual aliases for `$1A` as the X
high-byte scratch and `$21-$22` as the static-object stream pointer within
`$EBE9-$EC62`. Record `+5` is named only as `RuntimeObjectByte5`; its semantic
meaning remains intentionally open.

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
