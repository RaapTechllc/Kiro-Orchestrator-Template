# Adapter contract and compatibility

**Audit date:** 2026-07-16

The portable contract is a process boundary. It is intentionally smaller than any individual vendor's feature set.

## Implemented matrix

| Capability | Kiro | Claude | Codex | OpenCode | Hermes |
|---|---:|---:|---:|---:|---:|
| Executable/version probe | Yes | Yes | Yes | Yes | Yes |
| Noninteractive run | Yes | Yes | Yes | Yes | Yes |
| Raw stdout/stderr retention | Yes | Yes | Yes | Yes | Yes |
| Structured raw output requested | No documented stream | JSON | JSONL | JSON events | No documented live stream |
| Provider-native role flag | `--agent` | `--agent` | No | Unsafe mode only | No |
| Outer timeout | Yes | Yes | Yes | Yes | Yes |
| Explicit unsafe mapping | Yes | Yes | Yes | Yes | Yes |
| Resume/session normalization | Not implemented | Not implemented | Not implemented | Not implemented | Not implemented |
| Native subagent normalization | Unsupported | Unsupported | Unsupported | Unsupported | Unsupported |
| Native worktree normalization | Unsupported | Unsupported | Unsupported | Unsupported | Unsupported |

`Unsupported` means the portable kernel does not expose the capability. It does not mean the vendor lacks it.

## Invocation mappings

### Kiro CLI 2.x

```bash
kiro-cli chat --no-interactive [--agent NAME] --trust-tools=read,write,grep,glob "PROMPT"
```

- Output classification: text.
- The adapter does not use the historical undocumented `--prompt` flag.
- Safe mode trusts only the file-oriented tools required for coding; unknown tools, shell execution, and broader integrations remain untrusted in headless mode.
- `--unsafe` replaces the selective trust list with `--trust-all-tools`.
- Kiro tool trust controls approval, not OS isolation. Trusted tools run with the operator's filesystem permissions.
- If a workflow requires MCP servers, operators should validate startup separately; the portable contract does not currently expose `--require-mcp-startup`.
- Kiro V3 is early access and has different permission/tag/hook schemas. It is not claimed compatible with the included JSON agents.

### Claude Code

```bash
claude -p --output-format json --permission-mode dontAsk \
  --allowedTools Read Edit Write Glob Grep [--agent NAME]
```

The prompt is provided on stdin. `dontAsk` makes unapproved tools fail instead of opening an impossible headless approval prompt; the allowlist permits file-oriented implementation but denies shell and network tools. The former `acceptEdits` mapping was rejected because Anthropic documents that it automatically approves file edits and common filesystem commands. `--unsafe` instead uses `--dangerously-skip-permissions`. Claude sessions, streaming JSON, schema-constrained results, teams, and hooks remain vendor-specific extensions.

### OpenAI Codex CLI

```bash
codex exec --json --sandbox workspace-write -C WORKDIR --color never -
```

The prompt is provided on stdin. Safe mode selects the workspace-write filesystem sandbox explicitly without using the compound `--full-auto` convenience mode. `--unsafe` replaces that posture with `--dangerously-bypass-approvals-and-sandbox`. Approval policy, filesystem sandboxing, and network access are separate Codex concepts.

### OpenCode

```bash
OPENCODE_PERMISSION='{"*":"deny","read":"allow","edit":"allow","glob":"allow","grep":"allow","list":"allow"}' \
  opencode run --format json "PROMPT"
```

Safe mode overrides ambient OpenCode permission defaults with a fail-closed file-tool policy. Because native agents can override global permissions, `--role` remains goal-prompt context in safe mode; OpenCode receives `--agent NAME` only with `--unsafe`. On the audited installation, `opencode run --help` exposes `--dangerously-skip-permissions`; unsafe mode removes the restrictive environment override and adds that flag. First-party web documentation still describes `--auto`, so this mapping is version-sensitive and must be rechecked when OpenCode is upgraded. OpenCode permissions are tool policy, not an OS sandbox boundary.

### Hermes Agent

```bash
hermes chat --quiet [--yolo] --query "PROMPT"
```

The policy-aware `chat --quiet --query` surface is used instead of the bypass-oriented `hermes -q` one-shot mode. Safe mode leaves Hermes approval policy active; it is not an OS sandbox, so approved terminal or file tools still run with the user's permissions. `--unsafe` adds `--yolo`. Hermes sessions, profiles, skills, worktrees, delegation, cron, and Kanban remain optional vendor-specific capabilities.

## Version evidence

Local probes during the audit detected:

| CLI | Local probe |
|---|---:|
| Claude Code | 2.1.210 |
| Codex CLI | 0.117.0 globally installed; 0.144.5 isolated live test |
| OpenCode | 1.14.33 |
| Hermes Agent | 0.18.2 (2026.7.7.2) |
| Kiro CLI | Not installed locally |

Those versions are evidence about the audit host, not a supported-version guarantee. The contract suite uses stubs and verifies argument mapping without consuming provider credentials.

Live isolated evidence is narrower: Claude Code, Codex 0.144.5, and Hermes completed the golden path and passed their external gates on the first iteration. Codex required an isolated current CLI plus a non-persistent override because the globally installed 0.117.0 configuration contained obsolete values; no global config was changed. OpenCode reached its configured API but received HTTP 401 for an expired/invalid token; importantly, OpenCode emitted a JSON error while returning process exit 0, and the harness still exhausted because the external gate failed. Kiro was unavailable.

## Capabilities deliberately not flattened

- JSON and JSONL event schemas
- session/fork/resume semantics
- model/provider identifiers
- tool allowlists and approval DSLs
- filesystem/network sandboxing
- native subagent durability and communication
- hook payloads and blocking behavior
- native worktree ownership

The authoritative research and primary-source citations are in `docs/research/multi-cli-orchestration-2026-07.md`.
