# Symbol maps and label provenance

The canonical routine, label, RAM, and I/O maps are machine-readable rather
than duplicated as a manually maintained address appendix.

## PRG routine and label map

`config/reconstruction/symbols.json` is the complete current PRG symbol ledger. Its 1,232
records contain an immutable CPU address, current ca65 name, semantic kind, and
evidence confidence. Source 1.0 contains 295 routine entries, 755 local control
labels, 127 data labels, 48 general labels, and 7 tables. Every record belongs
to exactly one of the 124 contiguous ranges in `config/reconstruction/source_layout.json`.

`docs/source_layout.md` supplies the address-to-module and subsystem view;
`config/reconstruction/symbols.json` supplies the exact address-to-name and kind view. Together
they are the complete routine map without maintaining a second 1,232-row copy.

## Original-to-current provenance

The join key is the CPU address. Headless Ghidra exports its original `symbol`
and `function` columns to `build/ghidra/instructions.tsv`; the current name at
the same address is in `config/reconstruction/symbols.json`. For example:

| Address | Original Ghidra identity | Current source name |
| ---: | --- | --- |
| `$8000` | `FUN_PRG0__8000` | `DelayLongPulseHalf` |
| `$8225` | `reset` | `Reset` |
| `$9583` | `FUN_PRG0__9583` | `UpdateRuntimeObjects` |
| `$C569` | `vblank` | `Nmi` |
| `$E830` | `FUN_PRG0__e830` | `DecodeRoom` |
| `$EBE9` | `FUN_PRG0__ebe9` | `LoadStaticRoomObjects` |
| `$FE31` | `FUN_PRG0__fe31` | `RunGameOverSequence` |

Labels introduced for typed data or for control-flow targets that Ghidra did
not name use `PRG0:$address` as their original identity. Address is deliberately
the authority: names can improve without losing the link to the imported ROM,
and moving code cannot silently masquerade as a rename.

`make disassembly-check` regenerates the Ghidra facts and applies the ledger to
every source range. `make reconstruction-audit` additionally verifies symbol
metadata, unique source ownership, and the RAM map. The Source 1.0 manifest
freezes the exact map counts, so additions or removals require an explicit
release-contract update.

## RAM and I/O map

`config/reconstruction/memory_symbols.json` is the complete assembly-facing RAM/I/O ledger:
495 aliases, of which 368 are restricted to a proven PRG consumer range. A
global alias states a stable game-wide meaning; a scoped alias records scratch
reuse without claiming false global ownership. Array records also carry their
validated size so indexed operands remain relocatable.

`src/memory/ram.inc` exposes those addresses plus evidence-backed constants to
ca65. `docs/ram_map.md` is the human-oriented description of lifetimes,
overlaps, and subsystem contracts. Unnamed bytes are not hidden unknown ABI:
they are outside the Source 1.0 public contract until a proven consumer gives
them a stable or scoped meaning.
