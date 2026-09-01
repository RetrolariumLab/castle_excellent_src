# Runtime verification

Static disassembly is necessary but not sufficient to distinguish code from
data in a 6502 image. This project therefore has an independent execution
evidence layer based on the native FCEUX Code/Data Logger (CDL).

## Pinned emulator

`tools/runtime.lock.json` identifies the exact local x64 build of the
`oranguthang/fceux_automation` fork by source revision, artifact size, and
SHA-256. `make fceux-bootstrap` verifies the sibling build before copying the
executable and its Lua DLLs into ignored `tools/fceux/`.

The lock is an artifact identity contract. Rebuilding the emulator is a
separate source-toolchain concern: a replacement artifact must be reviewed and
its hashes deliberately updated before this project will execute it.

## Runtime scenarios

`make trace-boot` runs a 900-frame controller-driven boot/gameplay path.
`make trace-title` independently leaves the title screen untouched for 1,800
frames so delayed title or attract-mode paths can execute. `make trace-timeout`
starts a game and supplies no further input for 15,000 frames, exercising the
natural timer, death, and post-death paths without patching RAM. `make
trace-suite` runs all scenarios, bitwise-unions their native CDL files, and
analyzes the combined evidence. More scenarios can be added without changing
the tracked evidence format.

Each capture performs these steps:

1. verify and install the pinned FCEUX artifacts;
2. regenerate the Ghidra instruction-fact table;
3. validate the Japanese reference ROM SHA-1;
4. run its deterministic frame/controller script;
5. save FCEUX's native 64 KiB CDL under `build/runtime/`;
6. compare the 32 KiB PRG half against every byte covered by a Ghidra
   instruction;
7. emit a JSON summary with coverage counts and hit semantic routines.

The CDL includes 32 KiB of CHR evidence because that is FCEUX's file format.
The reconciliation deliberately considers only PRG bytes; CHR data never enters
the generated assembly source.

`make runtime-promote` converts the ignored binary CDL into tracked address
ranges in `config/runtime_evidence.txt`. These ranges contain no ROM bytes.
Headless Ghidra applies them after the independent pointer/control-flow ranges
in `config/static_code_evidence.txt`, then clears separately proven data ranges
before exporting its facts. This keeps the refined classification reproducible
from a clean checkout without misrepresenting static proof as execution.
Repository lint rejects typed-data overlap with either code-evidence class.

The Lua scenario initializes the Win32 logger window before resetting its
buffers. This ordering is required by the FCEUX backend: `DoCDLogger()` owns the
allocation performed by `InitCDLog()`.

The check fails if FCEUX executes even one PRG byte outside Ghidra's static code
classification. The reverse is not treated as failure: an instruction not hit
by one short scenario may be valid code on another room, ending, save/load, or
error path.

`make runtime-check` repeats analysis of the existing merged CDL without
launching the emulator. `make reconstruction-check` runs the complete static
gate followed by the full fresh scenario suite.

## Evidence limits

CDL proves that a byte was used as code or data during a particular execution;
it does not prove that unobserved bytes are unused. Later scenarios should be
merged across title, room transitions, death, ending, save/load, enemies, and
objects before source modules are classified exhaustively.
