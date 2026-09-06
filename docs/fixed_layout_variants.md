# Fixed-layout variants

Source Reconstruction 2.0 includes one deliberately small variant to prove a
safe edit without claiming general relocation. `start-room-1` changes the
Japanese new-game room from 71 to 1. Its only modified byte is the immediate
operand at PRG offset `$22B2`, CPU `$A2B2`, owned by
`src/game/new_game.asm`.

`config/fixed_layout_variants.json` pins the base and output hashes, original
and replacement bytes, region offset, CPU address, semantic owner, output path,
and runtime RAM observation. The builder refuses length changes, overlapping
edits, an unexpected original byte, any changed byte outside the manifest
allowlist, or a final hash mismatch.

```console
make build-fixed-layout
make verify-fixed-layout
make check-fixed-layout
```

The final target boots the isolated output with pinned FCEUX, presses Start,
waits for the first `MainFrameLoop` entry, and requires `CurrentRoomNumber` at
RAM `$0037` to equal 1. The canonical Japanese build and private reference are
never modified. This demonstrates fixed-layout source editing only; expanded
ROMs and systematic relocation remain outside Source 2.0.
