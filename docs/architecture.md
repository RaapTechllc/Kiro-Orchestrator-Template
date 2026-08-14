# Architecture

## Supported boundary

The supported product is a small Bash process orchestrator. It owns selection, prompt construction, wall-time budgets, raw run artifacts, deterministic verification, retries, and final status. Provider CLIs own model behavior, vendor sessions, native tools, and vendor-specific extensions.

```text
bin/orch
  |
  +-- mcp: stdio JSON-RPC skin over the same doctor/run/loop/verify commands
  +-- common.sh: validation, selection, run ledger, evidence capture
  +-- timeout.sh: portable outer watchdog
  +-- adapters/
       +-- kiro.sh
       +-- claude.sh
       +-- codex.sh
       +-- opencode.sh
       +-- hermes.sh
```

## Command flow

### Run

```text
parse -> validate -> select adapter -> build goal contract
      -> invoke with timeout -> retain raw output -> write status
```

### Loop

```text
PREPARE
  -> RUN_PROVIDER(attempt N, timeout)
  -> VERIFY(external command, timeout)
      -> PASS: status=verified
      -> FAIL: save bounded evidence -> next fresh provider attempt
      -> N exhausted: status=exhausted
```

The provider never decides whether verification passed. The verification command is supplied by the repository operator and executes from the requested working directory.

A provider process that exits 0 is recorded as `unverified`, not `completed`. This distinction is deliberate: some CLIs can emit a structured API error and still return process status 0. Only an external gate can produce `verified`.

## Stable process contract

Each adapter handles:

1. executable detection;
2. version reporting;
3. noninteractive invocation;
4. working-directory placement;
5. provider-native role selection where supported;
6. safe/default versus explicit unsafe arguments;
7. prompt transport;
8. raw stdout/stderr and exit status.

The core normalizes only the small envelope it can prove. It does not pretend session IDs, JSON event types, subagents, hooks, worktrees, or sandboxes are equivalent.

## Goal contract

Every attempt receives a generated `prompt.md` containing:

- role;
- working directory;
- iteration number;
- unsafe-mode disclosure;
- task;
- completion policy;
- bounded evidence from the previous failed attempt.

This makes the loop portable without relying on a vendor-specific completion token.

## Run ledger

Single runs and loop iterations preserve:

- normalized prompt;
- raw provider stdout/stderr;
- adapter command and exit status;
- timestamps;
- timeout marker where applicable;
- verification command artifact, status, and raw output;
- bounded feedback supplied to the next attempt;
- final `verified` or `exhausted` summary.

The default ledger root is `${XDG_STATE_HOME:-$HOME/.local/state}/orch/runs`, outside the usual provider worktree. Retry feedback is rendered as indented evidence so model-emitted Markdown fences remain data.

Every root created by the kernel has a versioned `.orch-run` marker. Standalone `orch verify` refuses arbitrary or symlinked directories and writes each attempt to a fresh child evidence directory instead of overwriting prior evidence. Line-oriented `*.env` artifacts are not sourced by the implementation and must be treated as data.

## Agent-first MCP skin

`orch mcp` speaks MCP JSON-RPC on stdio and invokes the same `doctor`, `run`, `loop`, and `verify` commands. It returns a JSON envelope (run id, status, `timed_out`, ledger paths, per-iteration status) so a third-party agent does not have to parse `summary.env` or stat watchdog markers. `timed_out` follows the same marker rule as the CLI. It does not replace the CLI, does not add a dashboard, and does not decide completion. See [docs/mcp.md](mcp.md).

## Safety properties

- no `eval` in provider execution;
- MCP wrapper invokes `bin/orch` through argv arrays and reads ledger `.env` files as data;
- no implicit provider permission bypass;
- no writes or provider invocation in dry-run mode;
- positive integer iteration/time budgets;
- non-zero propagation for missing providers, provider failures, gate failures, and exhaustion;
- no supported-core auto-merge or destructive Git cleanup;
- process `umask 077` for private run artifacts by default;
- raw evidence retained for audit.

The watchdog creates a Bash process group and terminates the group on timeout; the contract suite verifies ordinary descendants are removed. This is still not a container sandbox. A provider that deliberately creates a new detached process group/session may require OS/container-level cleanup.

## Legacy boundary

The historical `.kiro/` tree contains useful prompt, agent, thread, worktree, and review prototypes. It also contained simulated execution, completion-token control flow, forced worktree deletion, hard-reset rollback, and broad Git automation. The former flagship `ralph-kiro.sh` is now a compatibility wrapper around the supported kernel. Unsafe, simulated, and token-controlled legacy entry points are disabled by default behind the exact `KIRO_ENABLE_UNSUPPORTED_LEGACY=I_ACCEPT_THE_RISK` opt-in; that switch does not make them supported or safe. The legacy stop hook and blanket `Bash(*)` allowance were removed from active Kiro settings.

## Planned extensions

- explicit capability manifests exposed through `doctor`;
- adapter version ranges and fixture parsers;
- structured Claude/Codex/OpenCode result extraction while retaining raw events;
- shell-owned worktree isolation for parallel writers;
- policy fields that separate approval, sandbox, network, and external-directory access;
- stale process/worktree reconciliation.

See `ROADMAP.md`; these are not current claims.
