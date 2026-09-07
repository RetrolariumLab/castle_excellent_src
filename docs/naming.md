# Naming

The generated source uses two explicit naming layers:

- evidence-backed PascalCase names such as `DecodeRoom` and
  `RoomPointerTable`, maintained in `config/reconstruction/symbols.json`;
- stable address names `Func_XXXX` and `Label_XXXX` only as temporary names in
  ranges that have not yet passed the semantic naming gate.

An overlapping entry uses the same address name but is defined as an offset
symbol at its containing instruction. Renames belong in `config/reconstruction/symbols.json`;
do not hand-edit generated generic labels.

RAM and I/O operands use `config/reconstruction/memory_symbols.json`. Global entries name
stable storage or hardware registers. Address-scoped entries name shared
scratch only inside a statically proven routine range; their matching ca65
aliases live in `src/memory/ram.inc`.

When an immediate address byte or a table-plus-offset operand cannot be derived
from a plain address symbol, `config/reconstruction/operand_overrides.json` supplies the ca65
expression. Every override pins its original numeric operand and evidence; it
is rejected if a new ROM or analysis fact no longer matches that precondition.

Each semantic entry records a confidence. Do not convert a plausible
interpretation into a fact. Keep uncertainty in `docs/unknowns.md` until a
static consumer, format proof, or runtime trace resolves it.
