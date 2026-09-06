# Revision profiles

`config/revision_profiles.json` owns the identity, build selection, container,
private-input policy, and runtime status of each declared NES revision. Source
Reconstruction 2.0 currently declares the Japanese HSP-05 baseline and the USA
Castlequest localization. No other regional or platform profile is implied.

## Reference identities

| Profile | Status | ROM SHA-1 | PRG SHA-1 | CHR SHA-1 |
| --- | --- | --- | --- | --- |
| `castle-excellent-japan-hsp-05` | supported by 1.0 | `42f7975d...` | `099b3b7e...` | `e6c57329...` |
| `castlequest-usa` | byte-identical build; runtime pending | `600b0d2a...` | `9acc75ff...` | `7640fc1b...` |

Both images are 65,552-byte iNES mapper-3 containers with vertical mirroring,
32 KiB of fixed PRG, and four switchable 8 KiB CHR banks. The complete hashes
are machine-readable in the profile manifest. Both ROMs remain ignored,
private user-supplied inputs.

## Castlequest difference survey

The USA PRG differs in only 26 bytes across 11 contiguous runs. Each run falls
inside an already reconstructed semantic module:

| CPU range | Bytes | Owner | Current interpretation |
| --- | ---: | --- | --- |
| `$A2B6` | 1 | `src/game/new_game.asm` | initial lives: 3 versus 50 |
| `$C50E-$C510` | 3 | `src/rendering/screen_palette_data.asm` | localized title palette |
| `$C513-$C514` | 2 | `src/rendering/screen_palette_data.asm` | localized title palette |
| `$C516-$C518` | 3 | `src/rendering/screen_palette_data.asm` | localized title palette |
| `$C51A-$C51C` | 3 | `src/rendering/screen_palette_data.asm` | localized title palette |
| `$FB18` | 1 | `src/ui/sub_command_menu.asm` | three versus five menu selections |
| `$FB4B` | 1 | `src/ui/sub_command_menu.asm` | final selection index 2 versus 4 |
| `$FB69-$FB6E` | 6 | `src/ui/sub_command_menu.asm` | disabled load/save dispatch branches |
| `$FB83-$FB86` | 4 | `src/data/sub_command_text.asm` | third menu label becomes `GAME` |
| `$FB88` | 1 | `src/data/sub_command_text.asm` | fourth menu label becomes empty |
| `$FB98` | 1 | `src/data/sub_command_text.asm` | fifth menu label becomes empty |

The CHR regions differ in 3,567 bytes across 323 runs. Banks 0 and 2 are fully
identical. Bank 1 differs in 2,664 bytes from bank offset `$13F0` onward, and
bank 3 differs in 903 bytes from `$180A` onward. The compressed room arenas are
therefore identical: all bank-2 room data and the bank-3 room stream below
`$1161` are shared between revisions.

`make castlequest-check` validates the private reference, extracts only its CHR
payload into the ignored profile cache, builds the shared entrypoint with
`CASTLEQUEST_USA=1`, and compares the complete output with the reference byte
for byte. The Japanese default remains unchanged and continues to pass
`make verify`.

The USA profile remains `partial` until its direct runtime scenario gate is
recorded. No runtime equivalence is inferred from static similarity.
