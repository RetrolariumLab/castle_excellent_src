# Code quality

The quality targets follow the same contract as the sibling
`solomon_no_kagi_src` preservation project.

- `make format` normalizes every ca65 `.asm` and `.inc` source, then runs all
  linters
- `make format-check` checks assembly formatting without changing files
- `make lint-asm` checks the shared assembly style contract
- `make lint-source` checks repository structure, manifests, source contracts,
  debugger JSON, typed-data/static/runtime evidence separation, and the
  tracked-binary policy
- `make lint-project` is a compatibility alias for `make lint-source`
- `make lint` runs every linter
- `make test` regenerates pinned Ghidra instruction facts, then runs the Python
  unit-test suite; tests never consume a stale `build/` fact table
- `make quality-check` runs lint and tests without requiring a reference ROM
- `make check` adds deterministic disassembly, byte-identical ROM,
  room-data, room-screen-data, controller-input, audio-data, and Famicom
  data-I/O, save-payload, mutable-room-cell, and exhaustive coordinate-helper
  verification, plus transition-state, collision-cell/index flag, and runtime-object
  dispatcher contracts, exact new-game initialization, room-runtime reset,
  exhaustive room-cell animation mapping/cadence checks, and exhaustive HUD
  decimal/life/inventory formatting, plus inventory-backed mutable-cell action
  pointer, guard, and boundary checks, all 100 castle-room navigation cases,
  exhaustive player protection/hazard-probe domains, and the shared
  object/player proximity predicate across all proven coordinate domains, plus
  the shared player/object-span predicate across every Y pair and representative
  widths over the complete room X domain, plus
  all state/frame domains for transient runtime-object types 32, 40, and 41,
  their exact replacement table, and shared six-byte clearing path, plus
  animated-cell classification and both overlapping runtime-type filter tables
  across their complete proven byte domains, plus
  room/object point sampling across all cell halves, animation phases, runtime
  slots and the complete 320x160 coordinate domain, plus
  the room-only four-call sampler across every pixel, cell half, and animation
  sign, plus the shared seven-call row/column address helper across all 65,792
  possible 16-bit X and byte-wide Y machine-value combinations, plus
  the 28-call player sampler across screen bounds, player cell flags, all
  runtime types and slots, restricted filtering, and type-`$86` phase/motion
  geometry, plus
  the seven-call player collision dispatcher, both handler tables, all 140
  consumed identities, and its synthetic return address, plus
  the resumable runtime-object overlap scan across all pool offsets and more
  than one million active-type and dimension-boundary cases, plus
  pause edges and paused scrolling across complete button/state byte domains,
  plus both 100x2 collision-flag tables, all 48 runtime-object dimensions, and
  all 18 exact table consumers, plus player/action frame selection and the
  complete 24-record/42-pointer object render dispatch, plus all five common
  metasprite render paths, page clipping/OAM compaction, 203 descriptor pairs,
  and 107 statically recognizable descriptor selections, plus the complete
  encoded/runtime/update/sprite/collision object-type correlation across all
  783 static and 176 cell-derived room objects
- `make release-check` performs a clean build, then adds live debugger symbols,
  fresh Source 1.0 runtime evidence, and the revision 3 release audit

The address-ordered PRG translation unit is split only at boundaries recorded
in `config/source_layout.json`. Proven ranges move into named modules while
unknown ranges retain `preservation` ownership. The layout validator requires
contiguous coverage of `$8000-$FFFF` and rejects boundaries that split an
instruction. Formatting is safe because the release check rebuilds the ROM and
compares every byte with the reference.

The Ghidra gate also applies an explicit false-instruction-start registry
before evidence disassembly. This prevents an analyzer switch-table overreach
from splitting a proven linear instruction while keeping the correction
reviewable and reproducible.

Comments that contain only an address, optionally followed by encoded bytes,
such as `; $B173` or `; $82AD D0 01`, are rejected as
`machine-code-comment`. They duplicate the assembler listing without
explaining behavior. `make format` removes these pure address/byte dumps; a
comment that also explains the code is kept.
