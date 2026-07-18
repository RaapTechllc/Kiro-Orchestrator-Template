# Modern coding-agent CLIs and multi-agent orchestration

**Research date:** 2026-07-16
**Scope:** Claude Code, OpenAI Codex CLI, OpenCode, Kiro CLI, and Hermes Agent, with emphasis on what a shell-based, open-source orchestrator can support honestly.
**Repository context:** RaapTechllc/Kiro-Orchestrator-Template

## Evidence labels

- **Implemented** — documented by the vendor and/or present in first-party source.
- **Tested locally** — a command or version probe was executed on this Windows host during this research. This does not imply that authenticated agent work was run.
- **Intended** — a sound design for this template, but not demonstrated here as implemented.
- **Experimental** — the vendor explicitly labels the feature experimental or exposes it behind an experiment flag.
- **Unknown** — no stable first-party interface was found; the report does not infer one.

## Executive conclusions

1. **The stable common denominator is a process contract, not an agent contract.** Every covered tool can be launched in a chosen working directory with a prompt and an exit status. Most can run noninteractively. Their event schemas, session identifiers, permission models, subagents, hooks, and worktree behavior are not interchangeable.
2. **Use shell-owned Git worktrees as the isolation layer.** Native worktree conveniences are useful where present, but external `git worktree add/remove` works across all CLIs and makes ownership, cleanup, and branch integration auditable.
3. **Make adapters capability-driven.** An adapter should declare features such as `json_events`, `resume_by_id`, `tool_allowlist`, and `native_stop_hook`; the orchestrator must never silently emulate or claim an unavailable capability.
4. **Keep verification outside the model loop.** The shell should run deterministic lint, typecheck, test, build, diff, and policy gates after an agent exits. A model's `<promise>DONE</promise>` is text, not evidence.
5. **Kiro is active.** Its public repository had activity through June 2026, and first-party CLI docs were updated through July 2, 2026. It now documents headless execution, session resume, custom agents, Agent Skills, lifecycle hooks, and an experimental delegate facility.[^kiro-repo][^kiro-headless][^kiro-agent-config]
6. **Do not market this as one universal multi-agent runtime.** Claude agent teams, Codex subagents, OpenCode child sessions, Kiro Delegate, and Hermes delegation/Kanban have materially different durability and control semantics.

## Research method and local baseline

Primary sources were preferred: vendor documentation, public repositories, and first-party reference pages. No secondary comparison article is used as evidence.

Local version probes on 2026-07-16 returned:

| CLI | Local status | Version |
|---|---|---:|
| Claude Code | **Tested locally: installed** | `2.1.210` |
| Codex CLI | **Tested locally: installed** | `0.117.0` |
| OpenCode | **Tested locally: installed** | `1.14.33` |
| Kiro CLI | **Tested locally: not installed** | n/a |
| Hermes Agent | **Tested locally: installed** | `0.18.2 (2026.7.7.2)` |

These installed versions are not treated as the latest upstream versions. For example, the Codex repository showed release `0.144.5` and OpenCode showed `1.18.3` on the research date.[^codex-repo][^opencode-repo]

## Capability matrix

`Yes` means a documented stable surface was found. `Partial` means the outcome is possible but the interface is weaker or materially different. `Exp.` means experimental. `Unknown` means the report found no documented stable equivalent.

| Capability | Claude Code | Codex CLI | OpenCode | Kiro CLI | Hermes Agent |
|---|---|---|---|---|---|
| Noninteractive invocation | Yes: `claude -p` | Yes: `codex exec` | Yes: `opencode run` | Yes: `kiro-cli chat --no-interactive` | Yes: `hermes chat -q` |
| Machine-readable run stream | Yes: JSON or stream-JSON | Yes: JSONL with `--json` | Yes: raw JSON events with `--format json`; HTTP/SSE also available | **Unknown**: documented headless output is stdout, not a stable event schema | **Partial/unknown**: session export is JSONL, but no documented structured live-run stream comparable to Codex/OpenCode |
| Schema-constrained final output | Yes: `--json-schema` | Yes: `--output-schema` | Yes through SDK structured output | Unknown | Unknown |
| Resume latest/current directory | Yes: `--continue` | Yes: `codex exec resume --last` | Yes: `--continue` | Yes: `--resume` | Yes: `--continue` |
| Resume by stable ID | Yes: `--resume <id>` | Yes: `codex exec resume <id>` | Yes: `--session <id>` | Yes: `--resume-id <id>` | Yes: `--resume <id-or-title>` |
| Fork conversation/session | Yes: `--fork-session` | Partial: new thread/session facilities; do not assume a universal fork flag | Yes: `--fork` and server fork endpoint | Unknown | Yes interactively: `/branch`/`/fork`; shell resume remains a separate surface |
| Tool permission allow/deny | Yes: allowed/disallowed tools and permission modes | Yes: approval policy plus sandbox configuration | Yes: allow/ask/deny, pattern rules, per-agent overrides | Yes: trusted tools, allowed tools, and per-tool settings | Partial: toolsets plus dangerous-command approval; not an equivalent per-command sandbox DSL |
| OS/filesystem sandbox | Documented permissions; isolation strength depends on environment | Yes: explicit read-only/workspace-write/danger-full-access sandbox modes | Permission gate; no claim here of Codex-equivalent OS sandbox | Docs warn enabled write tools have the user's filesystem permissions; use path settings/hooks | Backend-dependent; terminal can be local/container/SSH/etc.; approvals are not a filesystem sandbox |
| Project instruction file | `CLAUDE.md` and `.claude/rules/` | Hierarchical `AGENTS.md` | `AGENTS.md`; `CLAUDE.md` fallback | `.kiro/steering/*.md` and `AGENTS.md` | Loads repository `AGENTS.md`/`CLAUDE.md` in documented workdir flows; skills are the stronger native convention |
| Skills | Yes | Yes | Yes, Agent Skills-compatible | Yes, Agent Skills-compatible | Yes, first-class managed skills |
| Native subagents | Yes | Yes | Yes | **Experimental** Delegate for background tasks; custom agents themselves are stable | Yes: synchronous delegated children; durable Kanban is separate |
| Lifecycle hooks | Yes | Yes | Yes through JS/TS plugins/events | Yes, including blocking Stop hooks | Partial: no claim of a drop-in Claude/Kiro hook schema; use shell gates/plugins/cron as appropriate |
| Native worktree convenience | Yes | Product surfaces support worktrees, but shell-owned worktrees remain the portable contract | Worktree-aware runtime/plugin context; workspace support includes experimental areas | No stable native worktree contract found | Yes: `--worktree` |
| Deterministic verification loop | External shell and/or hooks | External shell and/or hooks | External shell and/or plugins | External shell and/or Stop hook | External shell; agent tool loop and Kanban do not replace gates |

Sources for invocation and session rows: Claude CLI reference,[^claude-cli] Codex noninteractive/reference docs,[^codex-noninteractive][^codex-cli] OpenCode CLI,[^opencode-cli] Kiro headless/chat/CLI reference,[^kiro-headless][^kiro-chat][^kiro-cli-ref] and Hermes CLI reference.[^hermes-cli]

## Harness profiles

### 1. Claude Code

**Stable invocation.** `claude -p "…"` is the scriptable one-shot interface. It supports text, JSON, and streaming JSON output, piped input, turn and budget limits, custom system-prompt additions, JSON Schema output, tool allow/deny lists, and explicit permission modes.[^claude-cli]

**Sessions.** `--continue` resumes the recent conversation for the current project; `--resume` selects an ID/name; `--fork-session` creates a new session ID while retaining history. JSON results include a `session_id`, which makes orchestration substantially cleaner than scraping terminal text.[^claude-cli]

**Permissions.** Claude exposes permission modes plus `--allowedTools` and `--disallowedTools`. `--dangerously-skip-permissions` is intentionally dangerous and should not be the template default. Project settings can encode allow/ask/deny policies.[^claude-permissions]

**Instructions and extensions.** `CLAUDE.md`, modular `.claude/rules/`, custom agents, skills, plugins, MCP, and lifecycle hooks are documented first-class surfaces.[^claude-memory][^claude-subagents][^claude-hooks][^claude-skills]

**Parallelism.** Native subagents are implemented. Agent teams are explicitly **Experimental** and disabled by default, with documented limitations around resume, coordination, and shutdown. Claude also documents running parallel sessions in Git worktrees.[^claude-subagents][^claude-teams][^claude-workflows] The template should therefore regard teams as an optional optimization: their message protocol, shared task list, and lifecycle do not map to other CLIs.

**Adapter assessment:** **Implemented upstream; strong adapter target.** Prefer `-p --output-format stream-json` for event-aware runs and plain `-p --output-format json` for bounded jobs. Preserve stdout/stderr separately and retain the returned session ID.

### 2. OpenAI Codex CLI

**Stable invocation.** `codex exec "…"` is the noninteractive surface. `--json` emits JSONL events; `--output-schema` requests a schema-constrained final response; `-o/--output-last-message` can write the final message to a file. Resume uses `codex exec resume <SESSION_ID>` or `--last`.[^codex-noninteractive][^codex-cli]

**Permissions and sandbox.** Codex separates the approval policy from the execution sandbox. Documented sandbox modes include read-only, workspace-write, and danger-full-access; approval policy controls when a human/reviewer is consulted. This distinction should survive in the adapter rather than being collapsed into a generic `--yolo` boolean.[^codex-security][^codex-config]

**Instructions.** Codex composes hierarchical `AGENTS.md` files from the repository root toward the working directory, subject to documented size and fallback controls.[^codex-agents]

**Subagents, skills, and hooks.** Current first-party documentation includes subagents, Agent Skills, and lifecycle hooks. Subagents can be configured by role; hooks can be loaded from managed, user, project, session, and plugin layers.[^codex-multi][^codex-skills][^codex-hooks] These are Codex-native capabilities, not a portable orchestration protocol.

**Programmatic alternative.** The open-source repository includes an app-server using a bidirectional JSON-RPC-like protocol. It is a richer integration than scraping the TUI, but it increases adapter complexity and ties the orchestrator to Codex protocol versions.[^codex-app-server]

**Adapter assessment:** **Implemented upstream; strong adapter target.** Use `codex exec --json` and parse JSONL by event type. Pin and test the event parser against supported Codex versions. Treat app-server as a separate, optional adapter, not as the implementation of the basic CLI adapter.

### 3. OpenCode

**Stable invocation.** `opencode run` is noninteractive and accepts `--format json`, `--continue`, `--session`, `--fork`, model/agent selection, files, and directory options. OpenCode also exposes `serve`, a documented OpenAPI 3.1 HTTP server, and `acp`, which uses nd-JSON over stdin/stdout.[^opencode-cli][^opencode-server]

**Sessions.** The CLI can resume/fork sessions. The server has explicit create, child, fork, abort, diff, revert, status, prompt, and asynchronous-prompt endpoints, with SSE events. Session export/import is also documented.[^opencode-cli][^opencode-server]

**Permissions.** OpenCode uses `allow`, `ask`, and `deny`, supports tool/input patterns, external-directory controls, per-agent overrides, and a doom-loop guard. First-party web documentation describes `--auto`, while the locally audited `opencode run --help` exposes `--dangerously-skip-permissions` for auto-approval. Treat this unsafe flag as version-sensitive and probe the installed CLI rather than assuming either spelling.[^opencode-permissions]

**Instructions and extensions.** `AGENTS.md` is native; `CLAUDE.md` and Claude skills are compatibility fallbacks. OpenCode supports Agent Skills locations, primary agents, child-session subagents, and JS/TS plugins with tool/session/permission/file events.[^opencode-rules][^opencode-skills][^opencode-agents][^opencode-plugins]

**Provider neutrality.** OpenCode's `provider/model` naming and provider catalog make it model-provider-neutral, but the OpenCode harness itself remains a specific runtime. Provider-neutral models are not the same as CLI-neutral orchestration.

**Adapter assessment:** **Implemented upstream; strongest open programmatic surface of the surveyed CLIs.** Start with `opencode run --format json`. Add an optional server adapter only if durable sessions, async prompts, cancellation, SSE, and child-session inspection justify running a daemon.

### 4. Kiro CLI

**Activity status.** **Implemented and active upstream.** Kiro's public repository describes both IDE and CLI interfaces and showed a June 22, 2026 commit at research time.[^kiro-repo]

**Stable invocation.** Headless mode is `kiro-cli chat --no-interactive "…"`, authenticated with `KIRO_API_KEY`. A pipeline grants tools upfront with `--trust-tools=<categories>` or the broader `--trust-all-tools`; `--require-mcp-startup` fails fast when required MCP servers do not initialize.[^kiro-headless]

**Machine output limitation.** The headless documentation promises the first response on stdout and documents exit codes, but no JSON/JSONL live event schema was found. Therefore the adapter should classify Kiro output as **text**, capture stderr and exit code, and never advertise token/tool/session event parsing unless Kiro documents such a format later.[^kiro-headless][^kiro-cli-ref]

**Sessions.** Kiro supports directory-based resume (`--resume`), explicit IDs (`--resume-id`), a picker, and JSON save/load from interactive chat.[^kiro-chat]

**Permissions.** Custom agents specify available `tools`, auto-approved `allowedTools`, and tool-specific settings such as allowed paths or shell command allow/deny patterns. Kiro explicitly states that enabled write/shell tools run with the user's filesystem permissions; this is not an OS sandbox.[^kiro-agent-config]

**Instructions and extensions.** Workspace/global steering lives under `.kiro/steering/`; Kiro also always includes supported `AGENTS.md` files. Custom agents live in `.kiro/agents/` or `~/.kiro/agents/`. Skills implement the open Agent Skills format and are progressively loaded. Hooks cover AgentSpawn, UserPromptSubmit, PreToolUse, PostToolUse, and Stop.[^kiro-steering][^kiro-agent-config][^kiro-skills][^kiro-hooks]

**Verification loop.** Kiro's Stop hook can return `{"decision":"block","reason":"…"}` to continue the agent instead of stopping. This is a useful native feedback mechanism, but the shell must cap attempts and still run the authoritative final gate.[^kiro-hooks]

**Multi-agent status.** Delegate launches parallel background Kiro sessions and reports progress, but it is explicitly **Experimental**, requires enablement, is session-scoped, may not survive restarts, and tasks cannot communicate directly with the main conversation.[^kiro-delegate] Do not make it the foundation of a portable stable orchestrator.

**Adapter assessment:** **Implemented upstream; medium adapter target.** Support headless text runs, explicit tool trust, agent selection, resume flags, and exit codes. Label JSON events, durable delegation, and native worktree orchestration **unknown/unsupported** until first-party docs establish them.

### 5. Hermes Agent

**Stable invocation.** `hermes chat -q "…"` runs one query without the interactive CLI. Global flags include provider/model selection, profile, skills, resume/continue, worktree, and `--yolo`.[^hermes-cli]

**Sessions.** Hermes has persistent sessions in SQLite, resume by ID/title, recent-session continuation, session export to JSONL, and branch/fork commands inside a session.[^hermes-cli]

**Machine output limitation.** The documented query interface is optimized for human-readable output. JSONL session export is useful after a run but is not documented as a stable live execution-event stream. The basic adapter should therefore use text plus exit code and mark streaming tool-event normalization **unsupported**.

**Permissions and isolation.** Hermes exposes toolsets and dangerous-command approvals, with manual/smart/off modes and `--yolo`; terminal execution may target local, Docker, SSH, Modal, or other backends. Approval bypass, tool availability, and backend isolation are separate concepts.[^hermes-config]

**Instructions, skills, and extensions.** Hermes has first-class skills, plugins, MCP, memory, profiles, cron, and messaging gateways. Its skills are procedural memory loaded on demand and can be managed from the CLI.[^hermes-skills][^hermes-repo]

**Multi-agent semantics.** `delegate_task` creates isolated child contexts and terminal sessions; the parent receives only final summaries. Parallel batches are supported. These children are synchronous and are cancelled if the parent is interrupted. For durable collaboration, Hermes separately provides a shared SQLite Kanban board and dispatcher across profiles.[^hermes-delegation][^hermes-kanban]

**Worktrees.** `hermes --worktree` creates an isolated Git worktree/branch for parallel-agent sessions.[^hermes-config]

**Adapter assessment:** **Implemented upstream; medium adapter target.** Use `hermes chat -q`, explicit workdir/profile/skills/toolsets, process timeouts, and text result capture. Do not pretend Hermes delegated children, cron jobs, or Kanban tasks are interchangeable with a one-shot CLI process.

## What a shell template can support honestly

### Portable, recommended core (**Intended**)

1. **Preflight**
   - Detect executable and record `--version`.
   - Verify the repository root and clean/expected Git state.
   - Check authentication with a non-mutating vendor command where one exists.
   - Validate that requested adapter capabilities are actually available.
2. **Isolation**
   - Create one branch and Git worktree per task.
   - Give each process exactly one worktree as its cwd.
   - Never launch two writing agents in one worktree.
3. **Invocation**
   - Pass prompts via an argument, stdin, or temporary prompt file according to the adapter.
   - Capture stdout, stderr, exit code, wall time, PID, CLI version, adapter version, worktree, branch, and attempt number.
   - Apply an outer timeout independent of model-side turn limits.
4. **Result normalization**
   - Normalize only a small envelope: `status`, `exit_code`, `started_at`, `ended_at`, `session_id?`, `final_text?`, `events_path?`, `artifacts`, and `diagnostics`.
   - Retain raw output verbatim. Never discard unknown events.
5. **Verification**
   - Run configured format/lint/typecheck/unit/integration/build/security commands outside the agent.
   - Save each command, exit code, and log.
   - Permit bounded repair attempts, each with the prior gate failure injected as context.
6. **Integration**
   - Refuse integration on dirty unexpected files, failed gates, missing commits (when commits are required), or unresolved conflicts.
   - Merge/cherry-pick only after deterministic verification.
   - Re-run affected gates on the integration branch.
7. **Cleanup and recovery**
   - Keep failed worktrees by default for inspection.
   - Remove worktrees only after results and logs are durable.
   - Reconcile stale PIDs/worktrees on startup.

### Optional adapter capabilities

An adapter manifest should declare, rather than imply, capabilities:

```yaml
id: codex
executable: codex
protocol_version: 1
capabilities:
  noninteractive: true
  json_events: true
  structured_final: true
  resume_latest: true
  resume_by_id: true
  fork_session: false
  model_select: true
  agent_select: false
  tool_allowlist: false
  approval_policy: true
  os_sandbox: true
  native_worktree: false
  native_subagents: true
  native_hooks: true
  server_mode: optional
```

The values above are illustrative for schema shape; adapter tests must establish the exact flags for every supported CLI version.

### Suggested shell adapter interface

```bash
adapter_probe                     # JSON: executable, version, capabilities
adapter_build_argv RUN_JSON       # NUL-safe argv, never eval a shell string
adapter_run RUN_JSON RAW_DIR      # process execution; raw stdout/stderr retained
adapter_extract_result RAW_DIR    # normalized result envelope
adapter_resume RUN_JSON SESSION_ID
adapter_cancel PID
```

Use arrays in Bash (or a small cross-platform launcher in Python) instead of `eval`. Prompts, branch names, paths, and model names are untrusted strings. Redact secrets from logs, but preserve an unredacted local log only if explicitly configured and access-controlled.

## What must not be flattened into fake equivalence

| Tempting abstraction | Why it is false | Correct approach |
|---|---|---|
| `--json` means the same thing | Claude emits result/stream formats, Codex emits JSONL events, OpenCode emits its own events, Kiro/Hermes lack a documented equivalent | Per-adapter parsers plus raw logs |
| One `session_id` model | Scope, persistence, fork semantics, storage, and directory binding differ | Store `{adapter, cli_version, session_id, cwd, parent_id?}` |
| One `yolo` switch | Tool auto-approval, command approval, filesystem sandboxing, network access, and external-directory access are separate | Policy object mapped conservatively per adapter |
| One subagent API | Native agents differ in context inheritance, durability, communication, concurrency, and cancellation | Treat native multi-agent as optional accelerators; shell processes remain the portable unit |
| One hook schema | Event names overlap, but payloads, blocking codes, timeout behavior, and scope differ | Keep hooks adapter-local; put portable gates in the shell |
| Native worktrees everywhere | Some CLIs create/manage them, others only understand cwd/worktree context | Shell owns Git lifecycle |
| `DONE` means verified | It is model-generated text | Gate on commands and repository state |
| Same instruction file | Claude prioritizes CLAUDE.md; Codex/OpenCode use AGENTS.md; Kiro adds steering; Hermes emphasizes skills and may consume repo guidance | Keep a canonical neutral policy and generate thin tool-specific shims; test precedence |
| Same model/provider controls | OpenCode and Hermes are provider-neutral runtimes; Claude/Kiro are product-specific; Codex has its own model/provider configuration | Adapter passes opaque model identifiers and reports unsupported combinations |

## Verification-loop design

A reliable loop is a bounded state machine:

```text
PREPARE -> RUN_AGENT -> INSPECT_DIFF -> VERIFY
                              ^           |
                              |           v
                         REPAIR (N max) <- FAIL
                                          |
                                          v
                              PASS -> REVIEW -> INTEGRATE -> VERIFY_INTEGRATION
```

Recommended invariants:

- The agent never decides whether the gate passed.
- Gate commands come from repository configuration, not agent output.
- A repair attempt receives exact failing command, exit code, and a bounded log tail/full artifact path.
- Maximum attempts, time, and cost are policy inputs.
- The verifier can be a second read-only agent, but its opinion is advisory unless backed by deterministic checks.
- Diff size, forbidden paths, generated-file policies, secrets scanning, and lockfile changes are explicit checks.
- Integration is serialized even when implementation is parallel.

Native Stop hooks can shorten the loop for Claude/Kiro/OpenCode/Codex, but shell verification remains the source of truth. If a hook fails to run, the outer gate still executes.

## Recommended changes for this template

1. **Rename the architecture, not necessarily the repository:** describe it as a *multi-CLI worktree orchestrator with Kiro-first assets*, not a universal native-agent layer.
2. **Add `adapters/` with capability manifests** for `kiro`, `claude`, `codex`, `opencode`, and `hermes`; fail closed on unsupported requested features.
3. **Make external worktrees mandatory for parallel writers.** Keep Kiro/Claude/Hermes native worktree switches as optional conveniences only when the adapter can prove and discover the resulting path.
4. **Replace completion-token control flow.** `<promise>DONE</promise>` may remain a hint for backward compatibility, but completion must derive from process exit, expected artifacts, Git diff, and gate results.
5. **Add a portable run ledger** under `artifacts/runs/<run-id>/` with `request.json`, `adapter.json`, raw logs/events, `result.json`, `git.diff`, and `verification.json`.
6. **Use an explicit policy object:** read/write/network/external-directory/command approval are separate fields. Map each CLI conservatively; reject impossible policies rather than weakening them silently.
7. **Bound every loop:** process timeout, maximum repair attempts, maximum parallel workers, and optional budget/turn limits where supported.
8. **Keep native orchestration opt-in:** Claude teams, Codex subagents, OpenCode child sessions, Kiro Delegate, and Hermes delegation/Kanban should be documented as adapter-specific modes with separate status/durability expectations.
9. **Add contract tests:** fixture-test JSON/JSONL parsers, spaces/unicode in paths, missing auth, timeouts, partial output, resume failure, agent crash, verification failure, and stale worktree cleanup.
10. **Correct stale product claims:** do not hard-code model names such as “all agents use Opus 4.5”; models available to a product/account change independently of the template.

## Minimal rollout

- **Phase 1 — Intended portable baseline:** Kiro text adapter plus external worktree manager, run ledger, timeout, and deterministic gate runner.
- **Phase 2 — Intended structured adapters:** Claude JSON, Codex JSONL, and OpenCode JSON event parsers with versioned fixtures.
- **Phase 3 — Intended Hermes adapter:** text mode first; profile/skills/worktree options; no invented live event stream.
- **Phase 4 — Intended optional native extensions:** Kiro Stop-hook repair, experimental Claude teams, Codex app-server/subagents, OpenCode server/SSE, Hermes Kanban. Keep each behind a capability flag and maturity label.

## Sources

[^claude-cli]: Anthropic, [Claude Code CLI reference](https://code.claude.com/docs/en/cli-reference).
[^claude-permissions]: Anthropic, [Claude Code permissions](https://code.claude.com/docs/en/permissions).
[^claude-memory]: Anthropic, [Claude Code memory and instruction files](https://code.claude.com/docs/en/memory).
[^claude-subagents]: Anthropic, [Claude Code subagents](https://code.claude.com/docs/en/sub-agents).
[^claude-hooks]: Anthropic, [Claude Code hooks guide](https://code.claude.com/docs/en/hooks-guide).
[^claude-skills]: Anthropic, [Claude Code skills](https://code.claude.com/docs/en/skills).
[^claude-teams]: Anthropic, [Claude Code agent teams](https://code.claude.com/docs/en/agent-teams).
[^claude-workflows]: Anthropic, [Claude Code common workflows](https://code.claude.com/docs/en/common-workflows).
[^codex-repo]: OpenAI, [openai/codex repository](https://github.com/openai/codex) (repository and release activity observed 2026-07-16).
[^codex-noninteractive]: OpenAI, [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive).
[^codex-cli]: OpenAI, [Codex CLI reference](https://developers.openai.com/codex/cli/reference).
[^codex-security]: OpenAI, [Codex agent approvals and security](https://developers.openai.com/codex/agent-approvals-security).
[^codex-config]: OpenAI, [Codex advanced configuration](https://developers.openai.com/codex/config-advanced).
[^codex-agents]: OpenAI, [Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md).
[^codex-multi]: OpenAI, [Codex subagents](https://developers.openai.com/codex/multi-agent).
[^codex-skills]: OpenAI, [Codex Agent Skills](https://developers.openai.com/codex/skills).
[^codex-hooks]: OpenAI, [Codex hooks](https://developers.openai.com/codex/hooks).
[^codex-app-server]: OpenAI, [Codex app-server protocol README](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md).
[^opencode-repo]: Anomaly, [anomalyco/opencode repository](https://github.com/anomalyco/opencode) (repository and release activity observed 2026-07-16).
[^opencode-cli]: OpenCode, [CLI reference](https://opencode.ai/docs/cli/).
[^opencode-server]: OpenCode, [server/OpenAPI reference](https://opencode.ai/docs/server/).
[^opencode-permissions]: OpenCode, [permissions](https://opencode.ai/docs/permissions/).
[^opencode-rules]: OpenCode, [rules and AGENTS.md](https://opencode.ai/docs/rules/).
[^opencode-skills]: OpenCode, [Agent Skills](https://opencode.ai/docs/skills/).
[^opencode-agents]: OpenCode, [agents and subagents](https://opencode.ai/docs/agents/).
[^opencode-plugins]: OpenCode, [plugins and events](https://opencode.ai/docs/plugins/).
[^kiro-repo]: AWS/Kiro, [kirodotdev/Kiro repository](https://github.com/kirodotdev/Kiro).
[^kiro-headless]: Kiro, [Headless mode](https://kiro.dev/docs/cli/headless/), updated 2026-06-04.
[^kiro-cli-ref]: Kiro, [CLI commands](https://kiro.dev/docs/cli/reference/cli-commands/).
[^kiro-chat]: Kiro, [Chat and conversation persistence](https://kiro.dev/docs/cli/chat/), updated 2026-05-19.
[^kiro-agent-config]: Kiro, [Custom agent configuration reference](https://kiro.dev/docs/cli/custom-agents/configuration-reference/), updated 2026-07-02.
[^kiro-steering]: Kiro, [Steering and AGENTS.md](https://kiro.dev/docs/cli/steering/), updated 2026-01-08.
[^kiro-skills]: Kiro, [Agent Skills](https://kiro.dev/docs/cli/skills/), updated 2026-05-12.
[^kiro-hooks]: Kiro, [Hooks](https://kiro.dev/docs/cli/hooks/), updated 2026-06-05.
[^kiro-delegate]: Kiro, [Experimental Delegate](https://kiro.dev/docs/cli/experimental/delegate/).
[^hermes-repo]: Nous Research, [NousResearch/hermes-agent repository](https://github.com/NousResearch/hermes-agent).
[^hermes-cli]: Nous Research, [Hermes CLI commands reference](https://hermes-agent.nousresearch.com/docs/reference/cli-commands).
[^hermes-config]: Nous Research, [Hermes configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration).
[^hermes-skills]: Nous Research, [Hermes skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills).
[^hermes-delegation]: Nous Research, [Hermes subagent delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation).
[^hermes-kanban]: Nous Research, [Hermes Kanban multi-agent board](https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban).
