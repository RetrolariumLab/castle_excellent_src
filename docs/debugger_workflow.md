# Debugger workflow

Mesen 2 is the primary interactive debugger. Load the exact Japanese image and
import the entries from `config/debugger_breakpoints.json` and
`config/debugger_watches.json`.

Initial high-value probes are:

- execute `$8175` to observe CHR-bank selection;
- execute `$A35C`, `$EC63`, and `$EC8A` to distinguish full room load,
  snapshot rotation, and saved-game state selection;
- execute `$B64C`, `$B6C9`, and `$B7BD` to separate nametable/OAM clearing,
  status writes, and generated attribute upload;
- execute `$E7EC` and log PPU address plus returned bit;
- write `$0400-$058F` to capture room decoder output;
- write `$004A-$00D9` to recover runtime object-record fields;
- write `$0712-$0761` to observe active state, load mirrors, and both snapshot
  pairs across room transitions;
- write `$0785-$079B` to identify producers and consumers of NMI task requests;
- execute `$AD93`-derived indirect targets to classify object behavior;
- write `$0300-$03FF` and `$0200-$02FF` to separate composition from OAM
  reordering.

The published addresses are Japanese-profile working addresses. They must not
be reused for Castlequest USA without a revision alignment pass.

The first Code/Data Log should cover reset, title, normal play, room changes,
death, sub-command mode, ending, and the Japanese save/load paths. A normal
completion route visits only a fraction of the 100 rooms, so targeted room
entry and object-type scenarios are required for coverage.
