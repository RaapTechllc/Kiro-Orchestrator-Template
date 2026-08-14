# Claude Code instructions

Read and follow [`AGENTS.md`](AGENTS.md). It is the canonical provider-neutral policy for this repository.

Claude-specific notes:

- The adapter uses `claude -p --output-format json`.
- Default execution uses `--permission-mode acceptEdits`; it does not bypass all permissions.
- `--dangerously-skip-permissions` is only mapped after the operator explicitly supplies `bin/orch --unsafe`.
- Do not replace the external evidence gate with Claude hooks or a self-reported completion message.
- Keep Claude-only sessions, subagents, teams, hooks, and rules as optional capabilities rather than requirements of the portable kernel.

Validation:

```bash
bash tests/run.sh
shellcheck -x -P . bin/orch lib/orch/adapters/*.sh lib/orch/timeout.sh tests/run.sh
```

## Agent skills

### Issue tracker

GitHub issues on `RaapTechllc/Kiro-Orchestrator-Template` via `gh`. See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context: root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.

