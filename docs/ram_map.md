# RAM map

| Range | Size | Working name | Confidence | Evidence |
| --- | ---: | --- | --- | --- |
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
| `$0785-$079B` | 23 | NMI task requests | confirmed | reset loop and indexed NMI dispatch |
| `$079D-$07A1` | 5 | formatted score tiles | high | room status pointer and formatter |
| `$07A2` | 1 | score tile terminator during room load | confirmed | explicit zero before PPU copy |

The room decoder also gives contextual names to shared zero-page scratch:
`$16` bit index, `$17` lookahead write index, `$19` decoded cell, `$21-$22`
CHR stream pointer, `$23-$24` codebook pointer, `$25-$26` output offset, and
`$29-$2A` output pointer. These aliases are scoped to `$E7EC-$E8DE` in
`config/memory_symbols.json`; they do not claim that the bytes have the same
meaning elsewhere.

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
