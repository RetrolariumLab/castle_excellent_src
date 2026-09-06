# Contributing

The permanent target is a byte-identical reconstruction of the Japanese
`HSP-05` release. Before and after any byte-emitting source change, run:

```bash
make format
make release-check REFERENCE_ROM="Castle Excellent (J).nes"
```

Until private assets have been initialized, use `make scaffold-check`.

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

Codecs must reject truncated data and include focused unit tests. Generated PRG
labels must be changed through `config/symbols.json`, followed by
`make disassemble`; do not hand-edit the generated address structure. A future room
encoder must prove decode/encode equality for every one of the 100 rooms before
authored data can replace raw CHR ranges.
