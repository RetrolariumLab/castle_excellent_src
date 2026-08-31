# Code quality

The quality targets follow the same contract as the sibling
`solomon_no_kagi_src` preservation project.

- `make format` normalizes every ca65 `.asm` and `.inc` source, then runs all
  linters
- `make format-check` checks assembly formatting without changing files
- `make lint-asm` checks the shared assembly style contract
- `make lint-source` checks repository structure, manifests, source contracts,
  debugger JSON, and the tracked-binary policy
- `make lint-project` is a compatibility alias for `make lint-source`
- `make lint` runs every linter
- `make test` runs the Python unit-test suite
- `make quality-check` runs lint and tests without requiring a reference ROM
- `make release-check` adds deterministic disassembly, byte-identical ROM,
  room-data, room-screen-data, controller-input, and audio-data verification
- `make check` is the full release check

The address-ordered PRG translation unit is split only at boundaries recorded
in `config/source_layout.json`. Proven ranges move into named modules while
unknown ranges retain `preservation` ownership. The layout validator requires
contiguous coverage of `$8000-$FFFF` and rejects boundaries that split an
instruction. Formatting is safe because the release check rebuilds the ROM and
compares every byte with the reference.

Comments that contain only an address, optionally followed by encoded bytes,
such as `; $B173` or `; $82AD D0 01`, are rejected as
`machine-code-comment`. They duplicate the assembler listing without
explaining behavior. `make format` removes these pure address/byte dumps; a
comment that also explains the code is kept.
