# Reverse-engineering unknowns

Statuses are `open`, `testing`, `resolved`, `unused`, and `confirmed bug`.

## Open registry

### ROM-001 - exact iNES identity

- Status: resolved
- Known: 32 KiB PRG CRC32 `9FA1C11F`, 32 KiB CHR CRC32 `04A8FF2E`, combined
  headerless CRC32 `7FA2CC55`, mapper 3, vertical mirroring; exact hashes are
  recorded in `assets/manifest.json`
- Evidence: local Japanese reference inspected on 2026-08-31

### DATA-001 - prefix-code table bounds

- Status: resolved
- Known: the first symbol entry begins at `$E45D`; `$FF` after the final
  codeword terminates the table; recovered codewords are prefix-free
- Evidence: independent decoder produced exactly 400 cells for all 100 rooms

### DATA-002 - room bitstream boundaries

- Status: testing
- Known: pointer table at `$E71C`, split at room index `$43`; all 100 streams
  decode without truncation
- Needed: formal overlap checks, bank-tail usage, and encoder capacity rules

### DATA-003 - room nametable attribute construction

- Status: resolved
- Known: masks at `$E913-$E916` select the four two-bit quadrants; the 100-byte
  table at `$E9D2-$EA35` supplies replicated palette values; 13 cell types
  preserve their existing quadrant
- Output: two 64-byte buffers at `$0100-$017F`; NMI task requests 21 and 22
  upload them to nametable attribute addresses `$23C8` and `$27C8`
- Evidence: static builder at `$E8DF-$E9D1`, NMI handlers at `$E1F8/$E358`,
  independent construction of 200 tables from all 100 decoded rooms, and the
  byte-identical source build

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
- Needed: prove field `+5`, later meanings/transitions of `+4`, and semantic
  identities for all encoded and runtime types

### DATA-004 - persistent room-state bitmaps

- Status: resolved
- Record: one-byte room id, three static-object bitmap bytes, five mutable-cell
  bitmap bytes; active state at `$0712`, snapshots at `$0724` and `$072D`
- Object persistence: 101 offsets at `$EF06-$EF6A`, 141 bytes at `$0608-$0694`,
  one bit per static object
- Mutable-cell persistence: 101 offsets at `$ABAE-$AC12`, 108 bytes at
  `$0590-$05FB`; rooms 1-99 derive from seven candidate cell values, while
  room 100 reserves three bytes
- Application: set object bits clear runtime records; mutable bits select
  one-based candidate ordinals 1-39 and restore one of two two-cell forms
- Evidence: semantic load/save/apply modules, exact object-count and six-byte
  offset tables, and independent validation of every object list, all 40,000
  decoded cells, and all 176 cell-derived objects

### ROOM-001 - room-loading orchestration

- Status: resolved
- Order: mark visited, clear the object pool, decode, load/apply objects and
  state, reset NMI tasks, initialize the screen and OAM, write status data,
  build/upload attributes, reset runtime variables, select room audio
- Snapshot selection: matching snapshot-B room id restores that snapshot;
  otherwise the persistent stores are loaded; selected state is mirrored before
  bitmap application
- Evidence: semantic `$9578-$9582`, `$A35C-$A3AB`, `$B64C-$B7FC`, and
  `$EC63-$ECB6` modules; boot/gameplay CDL execution; independent status-data
  bounds and pointer validation; byte-identical build

### AUDIO-001 - alleged textual MML region

- Status: resolved
- Known: eight 8-byte records at `$B8C6` select three stream pointers and two
  channel parameters; 21 terminated ASCII command streams cover
  `$BBE7-$C20C` without gaps
- Grammar: `o`, `t`, `l`, and `v` commands; notes `a-g`, rest `r`, accidentals,
  explicit lengths, and dotted lengths; `$00` is followed by a little-endian
  restart address or `$0000`
- Evidence: static consumers in `$B895-$BB15`, exact-ROM validation by
  `scripts/audio_data.py`, and FCEUX CDL data reads with no executions in the
  stream range
