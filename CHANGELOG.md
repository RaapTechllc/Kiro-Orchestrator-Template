# Changelog

All notable changes to the Orchestrator Template will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
