# Changelog

All notable changes to the Orchestrator Template will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Provider-neutral `bin/orch` command surface with `doctor`, `run`, `loop`, and `verify`.
- Process adapters for Kiro CLI, Claude Code, Codex CLI, OpenCode, and Hermes Agent.
- External evidence gates, bounded retries, provider/verification wall-time limits, and reproducible run ledgers.
- Stub-backed contract tests for safe/unsafe mappings, prompt transport, raw output capture, failures, timeouts, and exhaustion.
- Multi-platform GitHub Actions workflow for Bash syntax, JSON validation, contract tests, and supported-core ShellCheck.
- Architecture, adapter, migration, research, roadmap, security, contribution, and community-health documentation.
- Deterministic golden-path fixture.
- Live externally verified golden-path evidence for Claude Code, current Codex CLI, and Hermes Agent.

### Changed

- Repositioned the repository from a Kiro-only workflow collection to a Kiro-first, provider-neutral orchestration harness.
- Replaced the simulated `ralph-kiro.sh` runner with a compatibility wrapper around `bin/orch loop --cli kiro`.
- Updated maintained Kiro agents from historical `use_subagent` references to `subagent`.
- Removed top-level fixed provider model IDs from Kiro agent configurations.
- Enforced LF endings for shell automation.
- Canonicalized working directories and run roots so relative paths survive provider directory changes without Codex double-resolution, including native path translation under Git Bash/Cygwin.
- Moved default run ledgers to the user's XDG state directory and rendered retry feedback as indented evidence.

### Security

- Permission, sandbox, auto-approval, tool-trust, and yolo bypass mappings now require explicit `--unsafe`.
- Conservative defaults now use selective Kiro file-tool trust, Claude `dontAsk` with a file-tool allowlist, explicit Codex workspace sandboxing, and an OpenCode deny-by-default policy.
- Dry-run is invocation-free and write-free.
- Prompts are transported as data through arrays or stdin; provider commands do not use `eval`.
- Generated `.orchestrator/` evidence is excluded from Git.
- Run roots carry a schema marker, standalone verification is append-only, arbitrary verification directories are rejected, and artifacts inherit `umask 077`.
- Timeout handling creates a provider process group, terminates ordinary descendants, and escalates/reaps on INT, TERM, or HUP, with a documented limit for deliberately detached sessions.
- Watchdog timeout markers distinguish real timeouts from providers or verification commands that naturally return exit 124.
- OpenCode unsafe mode follows the locally audited `--dangerously-skip-permissions` surface and documents upstream flag drift.
- OpenCode safe mode keeps roles as prompt context instead of selecting native agents that can override the deny-by-default permission policy.
- Zero-exit provider attempts are recorded as `unverified`, preventing provider-specific API errors hidden behind exit 0 from being mislabeled as completion.
- Simulated, completion-token-controlled, destructive worktree, and broad Git automation entry points fail closed by default; active Kiro settings no longer load the legacy stop hook or allow `Bash(*)`.

### Deprecated

- `<promise>DONE</promise>` and provider-written progress files as completion authority.
- Legacy `.kiro/workflows/` paths as supported production execution; hazardous entry points are quarantined behind an explicit risk-acceptance environment value until individually redesigned and hardened.

## [2.0.0] - 2026-01-19

### Changed
- **BREAKING**: Replaced Playwright MCP with Vercel Labs agent-browser for browser automation
  - agent-browser provides snapshot-first workflow optimized for AI agents
  - Deterministic refs for stable element selection
  - JSON output mode for machine-readable results
  - Session isolation for parallel testing
  - No config files required

### Added
- Comprehensive agent-browser documentation (`.kiro/docs/agent-browser-guide.md`)
- Migration examples (`.kiro/examples/agent-browser-examples.md`)
- Quick setup guide (`.kiro/docs/agent-browser-setup.md`)
- Browser automation commands in CLAUDE.md
- Browser automation patterns in LEARNINGS.md

### Updated
- test-architect agent: Added `shell:agent-browser` to allowed tools
- frontend-designer agent: Added `shell:agent-browser` to allowed tools
- All testing documentation to reference agent-browser
- Accessibility audit prompts to use agent-browser snapshots
- Testing standards with agent-browser patterns

### Deprecated
- Playwright MCP server (disabled in `.kiro/settings/mcp.json`)

### Migration
- See `.kiro/docs/archive/migration-plan.md` for detailed migration guide
- Playwright MCP is disabled but not removed for easy rollback
- Install agent-browser: `npm install -g agent-browser`

---

## [1.0.0] - 2026-01-01

### Added
- Initial release of Orchestrator Template
- 10 specialist agents (orchestrator, code-surgeon, test-architect, etc.)
- 5 thread types (P-Thread, C-Thread, F-Thread, B-Thread, L-Thread)
- Ralph Loop autonomous iteration pattern
- Spec-driven development workflow
- Git worktree isolation for parallel agents
- Self-improvement system with LEARNINGS.md
- Comprehensive documentation and guides

---

[Unreleased]: https://github.com/RaapTechllc/Kiro-Orchestrator-Template/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/RaapTechllc/Kiro-Orchestrator-Template/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/RaapTechllc/Kiro-Orchestrator-Template/releases/tag/v1.0.0
