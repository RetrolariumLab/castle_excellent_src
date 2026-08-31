# Provenance

## Cartridge identity

- Castle Excellent cartridge profile: <https://nescartdb.com/profile/view/3771/castle-excellent>
- Role: board, mapper, mirroring, chip sizes, and chip CRC32 values

The manifest records both the public headerless CRC baseline and complete
hashes calculated from the user's legally obtained Japanese reference image on
2026-08-31. It also records the observed USA `Castlequest` image separately;
the Japanese image remains the build baseline.

## Room and object analysis

- Article: <https://habr.com/ru/articles/991848/>
- Extractor: <https://github.com/wizzard2010/cex>
- Locally inspected upstream revision: `51aea680d28b31ed6c06a216502db86a467a44a4`
- Author attribution: Habr user `wizzard_2`, GitHub user `wizzard2010`
- Role: room decode, CHR-backed data, attributes, object streams, dispatcher,
  and sprite composition
- License state: no explicit repository license observed during research

The published code is evidence, not a source import. Reimplementations in this
repository should be independently written and tested against the ROM.

## ROM-hacking research trail

- Forum: <https://www.emu-land.net/forum/index.php?topic=83723.0>
- Role: mapper conversion, hack history, maps, bug reports, and behavioral
  observations

Forum attachments and patched ROM images are not project inputs and must not be
committed.

## Related MSX project

- Repository: <https://github.com/machado2/castle>
- Role: conceptual comparison with The Castle for MSX only

This is a different game binary and platform. It contains ROM-derived material,
has no selected license, and is not a source for NES implementation claims.

Local research clones live beneath ignored `references/`.

## Disassembly toolchain

- Ghidra 12.1.3: <https://github.com/NationalSecurityAgency/ghidra/releases/tag/Ghidra_12.1.3_build>
- GhidraNes `v20260531`: <https://github.com/kylewlacy/GhidraNes/releases/tag/v20260531>
- Role: iNES/CNROM import, 6502 recursive analysis, functions, instruction
  boundaries, and static flow targets

Exact archive names, sizes, URLs, and SHA-256 values are recorded in
`tools/disassembly.lock.json`. Downloaded tools are ignored. The tracked Java
scripts export analysis facts; the project-owned Python generator converts
those facts and the private PRG into canonical ca65 source.
