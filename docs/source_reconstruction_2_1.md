# Source Reconstruction 2.1

Source Reconstruction 2.1 is a compatible minor release built on the immutable
`source-reconstruction-2.0` tag at commit
`2a6cbf211125d8ad8302191eb8396f3ef210714d`. It preserves both byte-identical
revision profiles, the complete semantic source, runtime evidence, and the
level, music, and graphics authoring contracts accepted by 2.0.

The release uses a self-contained project manifest that records its public
scope, predecessor, evidence, supported profiles, exclusions, and aggregate
verification commands.

## Planned compatible delta

The 2.1 line is limited to repository-quality improvements that preserve the
2.0 source, profile, runtime, and authoring architecture:

- enforce non-empty commits, release-message policy, and rewrite chronology;
- exercise a real public release command in a disposable repository fixture;
- add Python syntax/static checks and atomic report writes;
- strengthen workstation editor smokes around save, build, play, preview, and
  dirty-close behavior;
- review Python file-size exceptions and split mixed responsibilities where it
  improves the public API;
- add navigation to the resolved-evidence ledger and record all remaining
  layout deviations explicitly.

Additional platforms, general relocation, expanded ROM architecture, sibling
engines, and a different canonical preservation image remain outside Source
2.x. They require a later major release or a separate architectural decision.

The manifest remains `development` until every planned requirement has concrete
evidence, the complete 2.0 baseline gate runs first, the 2.1 delta gate passes
from a clean build on the supported Windows x64 host, and the exact Git history
is recorded.
