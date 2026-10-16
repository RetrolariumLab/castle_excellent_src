# Contributing

The project reconstructs the Japanese `HSP-05` release and the US Castlequest
revision from one shared source tree; both must keep building byte for byte.
For each change:

```bash
make format
make test
```

Run `make test-full` (MAME) after changing control flow or anything
timing-sensitive. Data is edited in Retrolarium Studio
([`docs/retrolarium.md`](docs/retrolarium.md)).

Commit subjects and bodies are written in English. A subject names the completed
result and has no trailing period; after a blank line, two or three paragraphs
describe the affected boundary, the reason and the checks that passed.

Do not commit ROM images, extracted assets, build products,
emulator states, or third-party research clones. Keep `src/main.asm` in address
order.

Use confidence levels consistently:

- confirmed: directly observed in code, data, or a repeatable trace;
- high: several independent observations agree;
- tentative: a bounded working hypothesis;
- unknown: address-based identity only.

`make hooks` installs Git hooks that check commits and pushes for words that
must not be published and run `make lint` and `make format-check` before each
commit.
