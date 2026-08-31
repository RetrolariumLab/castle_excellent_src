# Local disassembly toolchain

`disassembly.lock.json` pins the exact official Ghidra archive and the matching
GhidraNes extension used by the headless pipeline. Downloaded archives and the
expanded installation are intentionally ignored by Git.

Install or verify them with:

```text
python scripts/bootstrap_ghidra.py install
python scripts/bootstrap_ghidra.py status
```

The pinned versions are:

- Ghidra 12.1.3 from `NationalSecurityAgency/ghidra`;
- GhidraNes `v20260531`, revision `4c41964`, built for Ghidra 12.1.

The extension supports iNES mapper 3/CNROM. Java 21 is required and is not
copied into this repository.

Upstream sources:

- <https://github.com/NationalSecurityAgency/ghidra>
- <https://github.com/kylewlacy/GhidraNes>

## Runtime verification

`runtime.lock.json` pins the exact Windows x64 executable and Lua DLLs from the
local `oranguthang/fceux_automation` fork at revision
`ec507d86c57acd8979547bc35e9627fb199fac9a`. That fork supplies deterministic
frame limits and exposes FCEUX's native Code/Data Logger to Lua.

The default bootstrap source is the sibling directory `../fceux_automation`:

```text
python scripts/bootstrap_fceux.py install
python scripts/bootstrap_fceux.py status
```

Every copied artifact is checked for exact size and SHA-256 before and after
installation. The installed files live in ignored `tools/fceux/`; no emulator
binary is committed here.

Upstream fork:

- <https://github.com/oranguthang/fceux_automation>
