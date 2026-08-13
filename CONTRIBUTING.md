# Contributing

Thanks for improving the portable orchestration seam.

## Before opening an issue

- Use `./bin/orch doctor` to capture CLI availability and version text.
- Search existing issues.
- Remove secrets and sensitive provider output.
- For security problems, follow `SECURITY.md` instead of filing publicly.

## Development setup

```bash
git clone https://github.com/RaapTechllc/Kiro-Orchestrator-Template.git
cd Kiro-Orchestrator-Template
bash tests/run.sh
```

Install ShellCheck using your operating system package manager, then run:

```bash
bash -n bin/orch lib/orch/common.sh lib/orch/timeout.sh lib/orch/adapters/*.sh tests/run.sh
shellcheck -x -P . bin/orch lib/orch/common.sh lib/orch/timeout.sh lib/orch/adapters/*.sh tests/run.sh
```

MCP wrapper tests require Python 3. They invoke `./bin/orch mcp` and assert that tool calls map to the real CLI.

## Pull request rules

1. Keep provider-specific flags inside `lib/orch/adapters/`.
2. Add or change a behavior test first and observe it fail.
3. Preserve safe defaults; new bypasses require explicit `--unsafe` mapping and negative/positive tests.
4. Preserve raw stdout, stderr, exit status, prompt, and timeout evidence.
5. Do not use provider prose or a magic token as completion authority.
6. Avoid hard-coded provider model IDs.
7. Update `README.md`, `docs/adapters.md`, `CHANGELOG.md`, and `VERIFICATION.md` when claims change.
8. Do not include `.orchestrator/`, credentials, generated reports, or unrelated reformatting.

## Adapter changes

Include:

- the first-party documentation or source URL for the invocation;
- observed CLI version, if available;
- safe/default argument fixture;
- unsafe argument fixture;
- prompt transport test;
- non-zero and timeout behavior;
- an honest label: contract-tested, locally probed, authenticated live-tested, experimental, or unknown.

## Legacy workflows

The `.kiro/workflows/` collection is experimental unless explicitly promoted. A pull request that promotes one must remove simulated execution, replace completion tokens with external verification, pass ShellCheck for the touched path, and document destructive Git/filesystem behavior.

## Commit and review scope

Prefer small commits that separate:

1. behavior tests;
2. kernel or adapter change;
3. documentation/claim update.

Maintainers may close broad feature requests that do not include a reproducible outcome or that erase meaningful provider differences.

## Code of conduct

Participation is governed by `CODE_OF_CONDUCT.md`.
