# Kiro CLI compatibility reference

**Verified from first-party sources:** 2026-07-16
**Local authenticated Kiro run:** not performed; Kiro CLI was not installed on the audit host

## Current status

- `kiro-cli` is active, not deprecated or renamed.
- It supersedes/rebrands Amazon Q Developer CLI; compatibility for historical `q` commands is documented, but new automation should target `kiro-cli`.
- The latest official changelog entry observed during this audit was **2.12.0 (2026-07-09)**.
- Kiro V3 is an opt-in early-access path (`kiro-cli --v3`), not the default replacement for 2.x.

Primary-source citations and uncertainty notes are maintained in `docs/research/kiro-cli-status-2026-07.md`.

## Supported repository invocation

The adapter uses:

```bash
kiro-cli chat --no-interactive [--agent NAME] "PROMPT"
```

With explicit `bin/orch --unsafe`, it adds:

```bash
--trust-all-tools
```

The adapter intentionally does not use the historical `--prompt` flag found in the old Ralph runner because that form was not documented for Kiro's headless chat surface.

## Common inspection commands

```bash
kiro-cli --version
kiro-cli chat --help
kiro-cli agent list
kiro-cli agent validate orchestrator
```

Check current first-party help before automating newer flags.

## Custom-agent notes

- Included `.kiro/agents/*.json` files target Kiro CLI 2.x.
- Provider model IDs are intentionally omitted. Model availability depends on product, account, region, and date.
- The current delegated-agent built-in is `subagent`; historical `use_subagent` references were removed from maintained agents.
- Least privilege belongs in agent `allowedTools` and `toolsSettings`, not in a global trust-all default.

## Kiro V3 migration boundary

V3 changes configuration shape materially:

- permission actions and contexts;
- tool/server identity through tags;
- agent discovery and locations;
- hook names and configuration;
- subagent orchestration.

Create separate V3 configuration and validate it under `kiro-cli --v3`. Do not mix V3 permission/tag objects into Kiro 2.x JSON.

## Historical drift corrected

- Native Windows Kiro CLI support makes WSL-only setup instructions obsolete.
- The old `ralph-kiro.sh` did not execute Kiro; its command was commented out and the script simulated work. It now delegates to `bin/orch loop --cli kiro`.
- `<promise>DONE</promise>` is no longer completion authority. The external `--verify` command is.
- Fixed Claude model IDs were removed from Kiro agent configuration.

## Unknown until live-tested

- Authenticated model compatibility for every included agent
- Account-specific tool-trust prompts and available models
- Kiro 2.x behavior on the golden-path fixture
- Kiro V3 migration behavior for this repository

Do not promote these from unknown to supported without a recorded live run and deterministic verification evidence.
