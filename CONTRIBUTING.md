# Contributing

The project reconstructs the Japanese `HSP-05` release and the US Castlequest
revision from one shared source tree. Before and after a byte-emitting source
change, run the complete Japanese gate:

```bash
make format
make release-check REFERENCE_ROM="Castle Excellent (J).nes"
```

Changes that affect revision overlays or shared authoring data must also pass:

```bash
make verify-profile REVISION_PROFILE=castlequest-usa
```

Until private assets have been initialized, use `make scaffold-check`. It runs
the repository policy and synthetic format/release tests without a ROM;
`make quality-check`, `make check`, and release gates require private assets.
See the [development guide](docs/development.md) and
[verification contract](docs/verification.md) for the complete command model.

Commit subjects and bodies are written in English. A subject names the completed
result and has no trailing period; after a blank line, two or three paragraphs
describe the affected boundary, the reason and evidence, and the checks that
passed. A Codex-assisted commit ends, after another blank line, with exactly:

```text
Co-Authored-By: Codex <noreply@openai.com>
```

Do not rewrite `main`. Any draft-history rewrite is prepared on `rewrite/*`
only after the owner approves an explicit old-to-new commit map, and promotion
or tag publication requires a second explicit approval.

Do not commit ROM images, extracted header/PRG/CHR regions, build products,
emulator states, or third-party research clones. Keep address order until a
module split has passed byte verification.

Use confidence levels consistently:

- confirmed: directly observed in code, data, or a repeatable trace;
- high: several independent observations agree;
- tentative: a bounded working hypothesis;
- unknown: address-based identity only.

Codecs must reject truncated or over-capacity data, preserve a zero-edit
round-trip, and include focused unit tests. Headless build commands are the
canonical authoring path; visual editors must produce the same workspace
documents. Generated PRG labels must be changed through
`config/reconstruction/symbols.json`, followed by `make disassemble`; do not
hand-edit generated address structure.
