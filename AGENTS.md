# Agent instructions

This repository is a provider-neutral orchestration harness with Kiro-first configuration assets.

## Read first

1. `CONTEXT.md` — domain vocabulary and boundaries
2. `docs/architecture.md` — supported architecture
3. `docs/adapters.md` — provider capability differences
4. `VERIFICATION.md` — what is and is not verified

## Supported core

The maintained seam is `bin/orch` with:

```bash
./bin/orch doctor
./bin/orch run --help
./bin/orch loop --help
./bin/orch verify --help
./bin/orch mcp --help
```

`orch mcp` is a stdio MCP wrapper over those four commands. It does not replace the CLI and it is not completion evidence.

Treat other `.kiro/workflows/` scripts as legacy/experimental unless a document explicitly promotes one.

## Non-negotiable rules

- Do not use model-generated prose or `<promise>DONE</promise>` as completion evidence.
- A loop is complete only when its configured external verification command exits 0.
- Keep provider-specific flags inside `lib/orch/adapters/`.
- Do not flatten approval policy, filesystem sandboxing, network access, and tool trust into equivalent concepts.
- Never add permission-bypass flags to a default path. They require explicit `--unsafe` behavior and tests.
- Preserve raw stdout, stderr, exit status, timeout evidence, and the normalized prompt.
- Use Bash arrays or stdin for prompts. Never construct provider commands with `eval`.
- Do not auto-merge, hard-reset, force-push, or delete worktrees in the supported core.
- Do not hard-code provider model IDs. Availability changes by product, account, and date.
- Keep Kiro 2.x JSON separate from Kiro V3 permissions/tag configuration.

## Change protocol

1. Add or change a behavior test in `tests/run.sh`.
2. Observe the failure when implementing new behavior.
3. Make the smallest adapter or kernel change.
4. Run:

```bash
bash tests/run.sh
bash -n bin/orch lib/orch/common.sh lib/orch/timeout.sh lib/orch/adapters/*.sh tests/run.sh
shellcheck -x -P . bin/orch lib/orch/adapters/*.sh lib/orch/timeout.sh tests/run.sh
```

5. Validate every tracked JSON file.
6. Update README, adapter docs, changelog, and verification claims when behavior changes.

## Definition of done

- Acceptance behavior is covered by tests.
- The external gate passes.
- New shell code passes ShellCheck.
- JSON parses.
- Unsafe mappings remain explicit.
- Documentation distinguishes implemented, contract-tested, live-tested, experimental, and unknown behavior.
- No secrets or generated `.orchestrator/` artifacts are staged.
