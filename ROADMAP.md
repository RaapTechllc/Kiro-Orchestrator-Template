# Roadmap

The project ships narrow verified increments. Items below are plans, not current capabilities.

## v3.0 beta — portable evidence kernel

- [x] Provider-neutral `doctor`, `run`, `loop`, and `verify` commands
- [x] Kiro, Claude, Codex, OpenCode, and Hermes process adapters
- [x] Explicit unsafe mappings and write-never dry-run
- [x] Iteration budgets and outer process timeouts
- [x] External evidence gate with failure feedback
- [x] Raw run ledger and contract tests
- [x] Kiro 2.x research and stale flagship-runner removal
- [ ] Cross-platform CI green on Windows, Linux, and macOS
- [ ] Authenticated golden-path runs recorded for declared providers
- [ ] First honest GitHub prerelease

## v3.1 — capability and compatibility

- [ ] Machine-readable adapter capability manifests
- [ ] Supported CLI version ranges and scheduled compatibility probes
- [ ] Structured result extraction for Claude, Codex, and OpenCode fixtures
- [ ] Session/resume support only where stable IDs can be retained
- [ ] Selective Kiro trust-tools policy instead of broad unsafe mode
- [ ] Redaction policy for raw logs

## v3.2 — isolated parallel writers

- [ ] Shell-owned Git worktree lifecycle
- [ ] One writer per worktree invariant
- [ ] Serialized integration with post-integration verification
- [ ] Stale PID/worktree reconciliation
- [ ] Fail-closed conflict and dirty-tree handling

## Experimental/vendor-specific extensions

These will remain opt-in and adapter-local:

- Kiro V3 config migration and native Delegate
- Claude agent teams
- Codex subagents and app-server
- OpenCode server/SSE child-session orchestration
- Hermes native worktrees, delegation, and Kanban

## Adoption milestones

- [ ] Three independent golden-path completions
- [ ] Three outcome-led examples
- [ ] Community profile at least 85%
- [ ] Five bounded contributor issues, with only genuine starter work marked `good first issue`
- [ ] Monthly compatibility check and documented support cadence

See `docs/research/github-growth-audit-2026-07.md` for the evidence behind this order.
