# Setup guide

This repository has two layers:

1. the supported provider-neutral kernel under `bin/` and `lib/orch/`;
2. Kiro-first agent, prompt, steering, and legacy workflow assets under `.kiro/`.

## 1. Prerequisites

- Git
- Bash 3.2+ (Git Bash on Windows is supported)
- One authenticated coding-agent CLI:
  - Kiro CLI
  - Claude Code
  - OpenAI Codex CLI
  - OpenCode
  - Hermes Agent

The repository does not install or redistribute provider CLIs. Use each vendor's current first-party installation and authentication documentation.

## 2. Clone and inspect

```bash
git clone https://github.com/RaapTechllc/Kiro-Orchestrator-Template.git
cd Kiro-Orchestrator-Template
./bin/orch doctor
```

`doctor` reports executable availability and version output. It does not authenticate or spend provider quota.

## 3. Dry-run the contract

```bash
./bin/orch run \
  --cli auto \
  --task "Inspect this repository" \
  --dry-run
```

Dry-run must not invoke a provider or create `.orchestrator/` artifacts.

## 4. Run one provider

```bash
./bin/orch run \
  --cli codex \
  --task "Review the current diff" \
  --workdir "$PWD" \
  --timeout 900
```

Replace `codex` with `kiro`, `claude`, `opencode`, or `hermes` after `doctor` reports it available.

## 5. Configure an evidence gate

Choose a deterministic command that is already meaningful in the adopting repository:

```bash
./bin/orch loop \
  --cli claude \
  --task "Make the existing checks pass without weakening them" \
  --verify "bash tests/run.sh" \
  --max-iterations 3
```

Do not copy placeholder npm commands from another project. The gate must match the repository's real language, test runner, and acceptance criteria.

## Kiro CLI 2.x

Kiro CLI remains active. The latest official changelog entry observed during the July 2026 audit was 2.12.0. Native Windows support exists; WSL is optional rather than required.

Verify your installation with:

```bash
kiro-cli --version
kiro-cli chat --help
kiro-cli agent list
```

Run the included Kiro orchestrator agent through the portable seam:

```bash
./bin/orch loop \
  --cli kiro \
  --role orchestrator \
  --task "Implement the approved task" \
  --verify "bash tests/run.sh"
```

Headless Kiro runs require an explicit tool-trust policy. The adapter does not grant blanket trust by default. Prefer a least-privilege custom agent and selective trust configuration. `--unsafe` maps to `--trust-all-tools` and should only be used in an isolated disposable workspace.

### Kiro V3

Kiro V3 is currently an opt-in early-access harness invoked with `kiro-cli --v3`. It changes agent, permission, tag, and hook configuration. Do not point V3 at the included Kiro 2.x JSON and assume compatibility. Follow `docs/research/kiro-cli-status-2026-07.md` before migrating.

## Safe and unsafe modes

`--unsafe` means a different dangerous action for every adapter. It is never enabled by auto-selection or by headless mode. Review `docs/adapters.md` before use.

For risky tasks:

1. use a disposable clone or worktree;
2. limit credentials and network access;
3. use the provider's native allowlist/sandbox controls;
4. set a short outer timeout;
5. inspect `.orchestrator/runs/<id>/` before integrating changes.

## Validate the template

```bash
bash tests/run.sh
bash -n bin/orch lib/orch/common.sh lib/orch/timeout.sh lib/orch/adapters/*.sh tests/run.sh
shellcheck -x -P . bin/orch lib/orch/adapters/*.sh lib/orch/timeout.sh tests/run.sh
python -m json.tool .kiro/agents/orchestrator.json >/dev/null
```

CI also validates every tracked JSON file and all tracked shell syntax.
