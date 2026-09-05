# Verification contract

The preservation proof has three independent inputs:

1. `assets/manifest.json`, the immutable expected identity;
2. `Castle Excellent (J).nes`, the ignored original image;
3. `build/native/castle_excellent.nes`, assembled from tracked PRG source plus
   the ignored CHR extracted by `make split`.

`make verify` validates both complete images against the manifest, then
performs direct byte comparisons of the iNES header, PRG, CHR, headerless
payload, full image, and extracted CHR.

## Targets

| Target | Contract |
| --- | --- |
| `verify-reference` | original image matches every manifest field |
| `verify-built` | built image matches every manifest field |
| `verify-header` | built and original iNES header/trainer regions match |
| `verify-prg` | built and original 32 KiB PRG match |
| `verify-chr` | CHR inside built and original images match |
| `verify-payload` | headerless PRG+CHR payloads match |
| `verify-rom` | complete headered files match |
| `verify-assets` | ignored extracted CHR matches original CHR |
| `check-assets` | alias for `verify-assets` |
| `verify` | aggregate of every target above |
| `rom-info` | print and validate identities for original and built images |
| `validate-title-sub-command` | title/menu hashes and transfer topology, eight strings, timeout/copy plans, exhaustive input priority, and room actions |
| `validate-demo-playback` | script hashes and callers, 72-command distribution, 863 expanded samples, pointer carry, input mask, and terminal reset |
| `validate-audio-track-selection` | seven selectors, eight track records, 24 stream-pointer slots, exact channel initialization, and exhaustive demo gating |
| `validate-audio-stream-engine` | exact engine partitions and callers, all 21 streams, stop/clear mutations, and exhaustive pointer, request, channel, and tick/gate domains |
| `validate-sound-effect-engine` | five starter write traces, exact call topology and NMI order, request/status arbitration, byte-wide step sequences, and table bounds |
| `validate-scroll-math-palette` | exact camera/divider/uploader partitions and callers, exhaustive camera and divider domains, and all 38 ordered PPU writes |
| `validate-unreferenced-object-clear-tail` | exact five-byte hash and boundaries, hypothetical decode, and absence of Ghidra, runtime, and PRG-pointer entries |
| `release-check` | lint, tests, source regeneration, ROM, room, screen, input, audio data/selection/stream/sound-effect engines, camera/divider/palette-upload behavior, data-I/O, save-payload, title/sub-command behavior, mutable-cell action/coordinate, castle navigation, shared room-cell sample addressing, outgoing object-state save, animated-cell displacement, collectible score/life and six-counter inventory-pickup effects, type `$9F` and `$81/$82` collision effects, typed unreferenced NMI-task and object-clear-tail bytes, unreferenced runtime-only collision sampling, game-over/completion routes, screen/room palettes, PRG-tail tile tables and vectors, player collision sampling/dispatch and hazard/protection, object proximity/span, transient-object lifecycles, object collision filters, combined and room-only point sampling, overlap scan, pause input, collision flags/dimensions, directional collision-handler matrices, frame sprites, metasprite composition/data, unified object catalog, transition, collision-cell/index, object-dispatch, new-game, room-runtime, room-cell-animation, and HUD-format checks |
| `check` | alias for `release-check` |

Focused region targets compare only their named output region. For example,
`verify-prg` can prove that the source-only PRG reconstruction is correct while
investigating an unrelated CHR issue. `verify` remains the release gate and
accepts no differences anywhere.

## Failure diagnostics

The comparison script reports the first different byte. PRG failures include
both the PRG offset and mapped CPU address; CHR failures include the 8 KiB CNROM
bank and bank-relative offset. Length differences report `EOF` on the missing
side.

## Typical workflow

```bash
make split
make verify-prg
make verify
make release-check
```

`make clean` removes only `build/`; it preserves the ignored extracted assets,
so a clean rebuild does not require repeating `make split`.
