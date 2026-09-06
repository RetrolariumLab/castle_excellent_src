# Open reverse-engineering questions

Only questions that can still change a Source Reconstruction 1.0 contract live
here. Resolved and classified findings are archived in
`docs/resolved_unknowns.md`.

Statuses are `open`, `testing`, `partially resolved`, and `blocked`.

## Open registry

### DATA-002 - room bitstream boundaries

- Status: testing
- Known: pointer table at `$E71C`, split at room index `$43`; all 100 streams
  decode without truncation
- Needed: formal overlap checks, bank-tail usage, and encoder capacity rules
- Source 1.0 impact: document the exact physical capacity contract; a general
  room editor remains Source Reconstruction 2.0 scope

### OBJ-001 - six-byte runtime record

- Status: testing
- Known: type at `+0`, 16-bit scaled X at `+1/+2`, scaled Y at `+3`, loaded
  initial state at `+4`, and a six-byte stride; `+4` is the global runtime
  state byte and is zero except for encoded types `$12-$29`, which index a
  state view beginning at `$EBC0`
- Format evidence: 100 lists fill `$EF6B-$F8FB` exactly; 783 records use 34
  encoded types `$0E-$3C`; five cell markers add 176 runtime types `$A1-$A5`;
  the largest combined room uses 22 of 24 runtime slots; all 2,449 stream bytes
  round-trip exactly
- Persistence evidence: 101 offsets at `$EF06-$EF6A` match
  `ceil(objects / 8)` for every room and address 141 bytes at `$0608-$0694`
- Needed for Source 1.0: register proven `+4/+5` meanings by consumer and keep
  genuinely type-specific interpretations explicit
- Deferred to Source 2.0: friendly identities for every encoded/runtime type
