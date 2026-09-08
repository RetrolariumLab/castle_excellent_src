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

The machine-readable delta boundary remains open while this modernization
snapshot is reviewed. The release audit will close it on the final substantive
commit before the aggregate gate is accepted.

The manifest remains `development` until the reconstructed history, complete
aggregate gate, and final release boundary are accepted on the supported
Windows x64 host.
