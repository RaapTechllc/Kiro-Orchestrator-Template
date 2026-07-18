# ADR-0001: Provider-neutral execution and evidence-gated completion

- **Status:** Accepted
- **Date:** 2026-07-16

## Context

The repository models useful orchestration patterns but spreads Kiro-specific command syntax across workflow scripts. Several flagship workflows substitute random or fabricated output for real CLI execution. Completion is often inferred from model prose such as `<promise>DONE</promise>`, while validation silently succeeds when expected npm scripts are absent.

Kiro CLI remains active. Kiro 2.0 added native Windows and headless execution in April 2026; Kiro 2.8 introduced a v3 early-access harness in June 2026. The product problem is therefore not Kiro's disappearance. It is provider coupling and an execution story that cannot be verified.

## Decision

1. Keep Kiro as a first-class adapter.
2. Put Kiro, Claude Code, Codex CLI, OpenCode, and Hermes Agent behind one normalized execution seam.
3. Use fresh CLI invocations as the portable iteration primitive; do not require cross-provider session semantics.
4. Treat deterministic command exit status and captured output as completion evidence.
5. Never treat model completion prose as sufficient evidence.
6. Default to provider-safe flags and require an explicit `--unsafe` opt-in for permission bypass.
7. Retain `.kiro/` as a legacy compatibility pack until its useful workflows are migrated or removed.

## Consequences

- Provider differences remain visible in an adapter capability matrix rather than being flattened into false equivalence.
- Loops can run across providers, but session resume, native subagents, structured JSON, and permission models remain adapter-specific.
- Existing legacy workflows are no longer advertised as production execution paths until migrated.
- Tests can verify argument mapping and orchestration behavior with stub binaries and no model spend.
