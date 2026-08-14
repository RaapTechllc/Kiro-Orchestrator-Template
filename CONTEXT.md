# Domain Context

The repository is a **portable coding-agent orchestration harness**. Kiro remains a first-class adapter, but no provider owns the workflow model.

## Ubiquitous language

- **Goal contract** — the operator-supplied task, working directory, role, budget, acceptance checks, and exit policy for a run.
- **Run** — one durable execution record containing the prompt, selected adapter, CLI output, exit status, and verification evidence.
- **Iteration** — one fresh CLI invocation inside a bounded loop. Iterations do not depend on provider-specific session resume semantics.
- **Evidence gate** — an operator-defined deterministic command whose exit code decides whether a goal is satisfied. Model completion prose is never sufficient evidence.
- **Adapter** — a provider-specific implementation of the common execution interface. Supported adapters are Kiro CLI, Claude Code, Codex CLI, OpenCode, and Hermes Agent.
- **Role** — an optional provider-native agent name where supported, and prompt context everywhere else.
- **Safe mode** — the default adapter posture: no provider-specific permission-bypass flag is added.
- **Unsafe mode** — an explicit operator opt-in that enables a provider's unattended permission-bypass flag where available.
- **Legacy pack** — the existing `.kiro/` agents, prompts, steering, and workflow scripts retained for Kiro compatibility while the portable kernel becomes the primary interface.
- **MCP skin** — optional stdio JSON-RPC wrapper (`orch mcp`) over the same CLI commands. It returns structured run metadata; it is not a dashboard and not a source of completion truth.

## Source of truth

1. Executable behavior and tests
2. `docs/architecture.md` and accepted ADRs
3. Root `AGENTS.md`
4. Provider-specific legacy documentation

README claims must not exceed what the executable tests demonstrate.
