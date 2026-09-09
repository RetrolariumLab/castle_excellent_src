# Source Reconstruction 2.1

Source Reconstruction 2.1 is a compatible minor release built on the immutable
`source-reconstruction-2.0` tag at commit
`2a6cbf211125d8ad8302191eb8396f3ef210714d`. It preserves both byte-identical
revision profiles, the complete semantic source, runtime evidence, and the
level, music, and graphics authoring contracts accepted by 2.0.

The release uses a self-contained project manifest that records its public
scope, predecessor, evidence, supported profiles, exclusions, and aggregate
verification commands. The project audit also rejects non-English public text.

## Compatible delta

The 2.1 line contains repository-quality improvements that preserve the 2.0
source, profile, runtime, and authoring architecture:

- enforce non-empty commits, release-message policy, and rewrite chronology in
  every ordinary minor audit;
- exercise real public lint and negative minor-audit commands in disposable
  repository fixtures;
- add non-mutating Python syntax/static checks and one atomic writer for ROM,
  JSON, report, debugger, analysis, generated-source, and formatter output;
- strengthen workstation editor smokes around save, build, play, preview, and
  dirty-close behavior;
- split build policy, Level Studio rendering, object-dispatch facts, and the
  disassembly CLI; machine-check the two remaining bounded GUI exceptions;
- add navigation to the resolved-evidence ledger and record all remaining
  layout deviations explicitly;
- inventory the complete documentation corpus and define one address-keyed
  old-to-new label registry without duplicating the current symbol ledger.

Additional platforms, general relocation, expanded ROM architecture, sibling
engines, and a different canonical preservation image remain outside Source
2.x. They require a later major release or a separate architectural decision.

The machine-readable delta covers 21 non-empty commits through
`4fcd5fdfcd5c898c1ea8bf470f36ef092e46fd61`. Later release-only commits may
change only this document and `config/source_reconstruction_2_1.json`; the audit
rejects any uncovered substantive path.

The manifest remains `development` for explicit owner review. A clean
`make source-2-minor-check` completed on the supported Windows x64 host with 661
unit tests, 10,489 regenerated Ghidra instructions, byte-identical builds for
both supported profiles, seven Japanese runtime scenarios, the Castlequest
runtime scenario, live debugger-symbol validation, zero-edit
level/music/graphics round trips, editor workstation actions for both profiles,
and both disposable public-command paths, including propagated rejection of a
synthetic empty commit. Branch promotion and tag validation remain separate
owner-approved actions.
