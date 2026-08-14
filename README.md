# Agent Orchestrator Template

**Kiro-first assets. One evidence-gated runner for Kiro CLI, Claude Code, Codex CLI, OpenCode, and Hermes Agent.**

[![CI](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/actions/workflows/ci.yml/badge.svg)](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Status: beta](https://img.shields.io/badge/status-beta-orange.svg)

Most coding-agent loops trust the model to say it is done. This template does not. It launches the selected CLI through a provider adapter, retains the raw output, runs a deterministic command outside the agent, and retries with bounded tail excerpts from the failure evidence until the gate passes or the budget is exhausted. Full logs remain in the run ledger.

```text
GOAL -> PROVIDER ATTEMPT -> EXTERNAL VERIFY
              ^                 |
              |--- evidence ----|

PASS -> verified     budget exhausted -> failure
```

> [!IMPORTANT]
> The new `bin/orch` kernel is beta and contract-tested with provider stubs. CI covers Windows, Linux, and macOS. Live externally verified golden paths passed on the first iteration with Claude Code, Codex 0.144.5, and Hermes Agent. OpenCode authentication failed during its live attempt, and Kiro was verified against current first-party documentation but was not installed locally. The older `.kiro/workflows/` collection is retained as an experimental pattern library unless explicitly marked otherwise.

## Why this exists

- **Avoid CLI lock-in.** Provider syntax lives behind five small adapters.
- **Stop trusting completion prose.** Exit status plus an external verification command decides completion.
- **Bound autonomous work.** Every attempt has iteration and wall-time limits.
- **Keep the evidence.** Prompts, raw stdout/stderr, verification logs, and statuses are written to a run ledger.
- **Fail closed.** Missing CLIs, provider failures, timeouts, and exhausted budgets return non-zero.

## Quick start

Requirements:

- Bash 3.2+ (Git Bash on Windows works)
- At least one supported coding-agent CLI, already installed and authenticated

```bash
git clone https://github.com/RaapTechllc/Kiro-Orchestrator-Template.git
cd Kiro-Orchestrator-Template

# See which adapters are usable on this machine.
./bin/orch doctor

# Prove selection and prompt construction without invoking an agent or writing artifacts.
./bin/orch run \
  --cli auto \
  --task "Audit this repository and name the three highest-risk gaps" \
  --dry-run
```

### Run one agent

```bash
./bin/orch run \
  --cli codex \
  --task "Review the current diff and identify correctness risks" \
  --workdir "$PWD" \
  --timeout 900
```

### Run a bounded repair loop

The verification command is the authority. The model cannot override it.

```bash
./bin/orch loop \
  --cli claude \
  --task "Make the shell test suite pass without weakening assertions" \
  --verify "bash tests/run.sh" \
  --max-iterations 3 \
  --timeout 1800 \
  --verify-timeout 300
```

Expected terminal summary:

```text
run: /home/user/.local/state/orch/runs/<run-id>
adapter: claude
iterations: 2
status: verified
```

### Five-minute golden path

This fixture asks an authenticated Codex CLI to create one exact file, then proves it with a deterministic shell gate.

```bash
demo_dir=$(mktemp -d)
cp -R examples/golden-path/. "$demo_dir"

./bin/orch loop \
  --cli codex \
  --task-file "$demo_dir/TASK.md" \
  --workdir "$demo_dir" \
  --verify "bash verify.sh" \
  --max-iterations 3 \
  --timeout 600
```

Success means `status: verified` and `$demo_dir/result.txt` contains exactly `orchestrated`. See [the fixture documentation](examples/golden-path/README.md) for cleanup and provider variants.

## Supported adapters

| Adapter | Noninteractive command | Raw output | Native role flag | Default posture | `--unsafe` mapping |
|---|---|---|---|---|---|
| Kiro | `kiro-cli chat --no-interactive` | Text | `--agent` | Trust only read/write/grep/glob tools | `--trust-all-tools` |
| Claude Code | `claude -p` | JSON | `--agent` | `dontAsk` plus explicit file-tool allowlist | `--dangerously-skip-permissions` |
| Codex CLI | `codex exec --json` | JSONL | Goal prompt only | Explicit `workspace-write` sandbox | bypass approvals and sandbox |
| OpenCode | `opencode run --format json` | JSON events | Unsafe mode only | Explicit deny-by-default file-tool policy; role remains prompt context | locally observed `--dangerously-skip-permissions` |
| Hermes Agent | `hermes chat --quiet --query` | Text | Goal prompt only | Existing approval policy; no OS sandbox | `--yolo` |

These are process adapters, not a fictional universal agent API. Tool approval is not an OS sandbox: Kiro and Hermes tools still run with the user's filesystem permissions, while Codex's workspace sandbox is a separate control. Sessions, subagents, hooks, network controls, JSON schemas, and worktree features differ by vendor. See [Adapter contract and caveats](docs/adapters.md).

Kiro CLI is active: the latest official changelog entry observed in the audit was **2.12.0 on July 9, 2026**. Kiro V3 is still an opt-in early-access harness and is not claimed compatible with the included Kiro 2.x JSON agents. See [Kiro CLI status research](docs/research/kiro-cli-status-2026-07.md).

## Commands

### `doctor`

Detects all five executables and records their reported versions.

```bash
./bin/orch doctor
```

### `run`

Executes one provider attempt and records the raw result. A zero provider exit is labeled `unverified`; `run` has no external gate and therefore never claims task completion.

```bash
./bin/orch run --help
```

Important options:

- `--cli auto|kiro|claude|codex|opencode|hermes`
- `--task TEXT` or `--task-file FILE`
- `--workdir DIR`
- `--role NAME`
- `--timeout SECONDS`
- `--unsafe`
- `--dry-run`

### `loop`

Runs fresh attempts until the external gate passes or the attempt budget is exhausted.

```bash
./bin/orch loop --help
```

A loop requires `--verify`. Completion without external evidence is rejected.

### `verify`

Runs a trusted verification command against a marked orchestrator run and appends a unique evidence directory.

```bash
./bin/orch verify \
  --run "${XDG_STATE_HOME:-$HOME/.local/state}/orch/runs/<run-id>" \
  --workdir "$PWD" \
  --verify "bash tests/run.sh"
```

`--verify` is intentionally a shell command supplied by the repository operator. Never pass untrusted user input into it.

### `mcp`

Stdio MCP wrapper over the same four commands. Third-party agents get a JSON envelope (run id, status, `timed_out`, ledger paths, per-iteration status) instead of scraping `summary.env` or stat'ing watchdog markers. This does not replace the CLI and does not decide completion.

```bash
./bin/orch mcp --help
```

Example client config:

```json
{
  "mcpServers": {
    "orch": {
      "command": "bash",
      "args": ["/absolute/path/to/bin/orch", "mcp"]
    }
  }
}
```

See [Agent-first MCP wrapper](docs/mcp.md).

## Run ledger

By default, artifacts are written outside the provider worktree under `${XDG_STATE_HOME:-$HOME/.local/state}/orch/runs`. Pass `--run-root` to choose another location.

```text
<run-id>/
├── .orch-run              # schema/type marker required by `orch verify`
├── prompt.md
├── stdout.log
├── stderr.log
├── meta.env
├── provider.timeout       # only when the provider exceeds its limit
├── verify.command         # exact trusted operator-supplied gate
├── verify.env
├── verify.stdout.log
├── verify.stderr.log
├── verify.timeout         # only when the gate exceeds its limit
├── feedback.txt
├── <timestamp>-verification/  # append-only standalone `orch verify` evidence
└── summary.env
```

The `.env` suffix means line-oriented metadata; these files are evidence, **not shell scripts and must never be sourced**. Agents that speak MCP can read the same fields from `orch mcp` JSON instead of parsing the files by hand.

Retry prompts contain bounded 80-line tail excerpts rendered as indented evidence, so model-emitted Markdown fences cannot escape into prompt instructions. `feedback.txt` identifies the full provider and verifier logs so truncation is explicit and complete evidence remains available in the ledger.

## Safety model

- `--dry-run` invokes nothing and writes nothing.
- Provider permission bypass is never enabled implicitly.
- `--unsafe` is explicit because the mappings are materially dangerous and not equivalent.
- Provider and gate processes have outer wall-time limits.
- Prompts are passed as arguments or stdin through Bash arrays; no provider command uses `eval`.
- Raw provider output is retained instead of silently normalized or discarded.
- The portable kernel does not auto-merge branches or delete worktrees.

The watchdog starts the provider in its own Bash process group and terminates that group on timeout. A provider that deliberately creates a detached process group/session can still outlive it; use container or OS-level isolation for hostile workloads.

## Kiro-first assets

The repository still includes:

- Kiro 2.x custom agents under `.kiro/agents/`
- Steering, prompts, specs, hooks, and examples
- Historical P/C/F/B/L thread experiments
- Worktree and review prototypes

The former `ralph-kiro.sh` claimed to launch parallel Kiro workers but only logged and slept; its Kiro command was commented out and used an undocumented flag. It is now a compatibility wrapper around the real `bin/orch loop --cli kiro` seam.

Other legacy workflows are retained for research and migration, not included in the supported-core claim. See [Migration guide](docs/migration-v3.md) and [full audit](docs/audit/2026-07-16-full-audit.md).

## Architecture and research

- [Architecture](docs/architecture.md)
- [Adapter contract](docs/adapters.md)
- [Agent-first MCP wrapper](docs/mcp.md)
- [Domain vocabulary](CONTEXT.md)
- [Architecture decision record](docs/adr/0001-provider-neutral-execution.md)
- [Kiro CLI status, July 2026](docs/research/kiro-cli-status-2026-07.md)
- [Multi-CLI orchestration research](docs/research/multi-cli-orchestration-2026-07.md)
- [GitHub growth audit](docs/research/github-growth-audit-2026-07.md)
- [Roadmap](ROADMAP.md)

## Verification

```bash
bash tests/run.sh
shellcheck -x -P . bin/orch lib/orch/adapters/*.sh lib/orch/timeout.sh tests/run.sh
```

See [VERIFICATION.md](VERIFICATION.md) for the exact supported claim and current limitations.

## Use as a template

After the GitHub template setting is enabled:

```bash
gh repo create my-agent-workflow \
  --template RaapTechllc/Kiro-Orchestrator-Template \
  --private \
  --clone
```

Delete the example project state you do not need, keep `bin/`, `lib/orch/`, `tests/`, and only the provider-specific assets you intend to maintain.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Adapter changes must include contract tests and preserve safe defaults. Security reports belong in [SECURITY.md](SECURITY.md), not public issues.

## License and trademarks

MIT © [RaapTech LLC](https://github.com/RaapTechllc).

Kiro, Claude, Codex, OpenCode, and Hermes are names of their respective projects or owners. This independent template is not affiliated with or endorsed by those vendors, and it does not redistribute their CLIs.
