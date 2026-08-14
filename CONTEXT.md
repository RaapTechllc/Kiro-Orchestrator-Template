# Domain Context

A portable coding-agent orchestration harness. Kiro is a first-class adapter. No provider owns the workflow model.

## Language

**Goal contract**:
The operator-supplied task, working directory, role, budget, acceptance checks, and exit policy for a run.

**Run**:
One durable execution record: prompt, selected adapter, CLI output, exit status, and verification evidence.

**Iteration**:
One fresh CLI invocation inside a bounded loop.
_Avoid_: session resume, vendor thread, conversation continuation

**Evidence gate**:
An operator-defined deterministic command whose exit code decides whether a goal is satisfied.
_Avoid_: completion token, `<promise>DONE</promise>`, model prose, progress file

**Adapter**:
A provider-specific implementation of the common execution interface. Supported adapters are Kiro CLI, Claude Code, Codex CLI, OpenCode, and Hermes Agent.

**Role**:
An optional provider-native agent name where supported, and prompt context everywhere else.

**Safe mode**:
The default adapter posture: no provider-specific permission-bypass flag is added.

**Unsafe mode**:
An explicit operator opt-in that enables a provider's unattended permission-bypass flag where available.
_Avoid_: treating approval policy, filesystem sandboxing, network access, and tool trust as the same thing

**Legacy pack**:
The existing `.kiro/` agents, prompts, steering, and workflow scripts retained for Kiro compatibility while the portable kernel is the primary interface.

**MCP skin**:
Optional stdio JSON-RPC wrapper (`orch mcp`) over the same `doctor`, `run`, `loop`, and `verify` commands. It is not a second orchestrator and not a source of completion truth.
_Avoid_: dashboard, control plane, completion authority

**JSON envelope**:
The structured MCP tool result: command, ok, exit code, argv, run id, status, `timed_out`, ledger paths, and the completion policy. Third-party agents read this instead of parsing `summary.env`.
_Avoid_: scraping ledger files, treating envelope text as done

**Ledger**:
Durable artifacts for a run or iteration. Line-oriented `*.env` files are data and must never be sourced as shell.

**Watchdog marker**:
Proof that the outer timeout fired (`provider.timeout` or `verify.timeout`). Exit 124 without a marker is a provider or gate failure, not a timeout.

**Verified**:
Loop or verify status recorded only after the evidence gate exits 0. `orch run` never records verified.

**Unverified**:
A zero provider exit on `orch run`. Not completion.

**Exhausted**:
A loop that used its iteration budget without a passing evidence gate.

## Source of truth

1. Executable behavior and tests
2. `docs/architecture.md` and accepted ADRs
3. Root `AGENTS.md`
4. Provider-specific legacy documentation

README claims must not exceed what the executable tests demonstrate.
