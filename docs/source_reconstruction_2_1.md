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

- enforce non-empty commits, release-message policy, and rewrite chronology;
- exercise a real public release command in a disposable repository fixture;
- add non-mutating Python syntax/static checks and one atomic writer for ROM,
  JSON, report, debugger, analysis, generated-source, and formatter output;
- strengthen workstation editor smokes around save, build, play, preview, and
  dirty-close behavior;
- split build policy, Level Studio rendering, object-dispatch facts, and the
  disassembly CLI; machine-check the two remaining bounded GUI exceptions;
- add navigation to the resolved-evidence ledger and record all remaining
  layout deviations explicitly.

Additional platforms, general relocation, expanded ROM architecture, sibling
engines, and a different canonical preservation image remain outside Source
2.x. They require a later major release or a separate architectural decision.

The machine-readable delta covers 13 non-empty implementation and scope commits
through `009cc2759ca82e6f20d573f86637fb2e94a76df4`. Later release-only commits may
change only this document and `config/source_reconstruction_2_1.json`; the audit
rejects any uncovered substantive path.

The manifest remains `development` for explicit owner review. A clean
`make source-2-minor-check` completed on the supported Windows x64 host with 657
unit tests, 10,489 regenerated Ghidra instructions, byte-identical builds for
both supported profiles, seven Japanese runtime scenarios, the Castlequest
runtime scenario, live debugger-symbol validation, zero-edit
level/music/graphics round trips, editor workstation actions for both profiles,
and the disposable public-command smoke. Branch promotion and tag validation
remain separate owner-approved actions.
