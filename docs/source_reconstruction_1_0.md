# Source Reconstruction 1.0 boundary

Source Reconstruction 1.0 preserves the Japanese Famicom release of Castle
Excellent, catalog `HSP-05`, as the sole supported profile. The canonical
entrypoint is `src/main.asm`; ca65 and ld65 rebuild the 32 KiB PRG from source,
and the private 32 KiB CHR input is incorporated as data. The resulting 65,552
byte iNES image is byte-identical to the identified local reference.

The release accepts the complete address-ordered source, CNROM memory layout,
RAM and symbol contracts, source navigation, deterministic Ghidra regeneration,
format round trips, live debugger lookup, and the seven scenarios declared in
`scenarios/source_1.json`. Every PRG byte has semantic or explicitly typed-data
ownership; the active unknown registry is empty. This is stronger semantic
coverage than the minimum Preservation Source contract, without claiming that
all friendly object identities or authoring abstractions are final.

Castlequest and every other regional ROM are unsupported in this release.
Relocation, expanded ROMs, general-purpose editors, and cross-profile
authoring are also excluded. They belong to later releases and are not inferred
from matching addresses or mechanics.

The complete pre-release gate is `make release-check`. It starts from an empty
`build/`, validates private inputs and pinned build tools before use, runs lint and all unit and
contract tests, proves full image identity, regenerates debugger/runtime
evidence from the source-built image, and audits this boundary against the
release manifest. Tag creation, moving `main`, and publishing remain explicit
owner actions outside this document.
