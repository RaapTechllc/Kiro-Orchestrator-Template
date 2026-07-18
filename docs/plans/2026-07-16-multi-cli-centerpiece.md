# Multi-CLI Centerpiece Implementation Plan

> **For Hermes:** Implement task-by-task with behavior tests at the `bin/orch` seam.

**Goal:** Replace the repository's simulated, Kiro-only execution story with a tested multi-CLI execution kernel and an evidence-gated loop.

**Architecture:** `bin/orch` is the small public interface. It delegates provider-specific invocation to executable adapters under `lib/orch/adapters/`; run state and evidence are durable artifacts under a configurable run root. Existing `.kiro/` assets remain a compatibility pack, not the primary runtime.

**Tech stack:** Bash 3.2+ compatible shell, Git, optional provider CLIs, ShellCheck, GitHub Actions.

---

## Locked test seams

1. `bin/orch doctor` — discovers supported adapters and reports availability without mutation.
2. `bin/orch run` — selects an adapter, passes the normalized goal, and records a run artifact.
3. `bin/orch run --dry-run` — prints the decision and performs no writes or provider invocation.
4. `bin/orch loop` — creates fresh bounded iterations and completes only when a deterministic evidence command exits zero.
5. `bin/orch verify` — re-runs an evidence gate against a recorded run.
6. Adapter executables — map the normalized invocation to Kiro CLI, Claude Code, Codex CLI, OpenCode, and Hermes Agent flags; tests use stub binaries and spend no model quota.

## Acceptance criteria

- [ ] Kiro is described accurately as active, including 2.x headless mode and v3 early access.
- [ ] Five adapters are supported: `kiro`, `claude`, `codex`, `opencode`, `hermes`.
- [ ] `auto` chooses the first available CLI from a configurable priority list.
- [ ] Safe mode never adds a provider's permission-bypass flag.
- [ ] `--unsafe` is explicit and adapter-specific; generated dry-run output labels it.
- [ ] Prompts are passed without `eval` and task text cannot become shell syntax.
- [ ] Dry-run is write-never and does not call a CLI.
- [ ] A run records prompt, stdout, stderr, adapter, timestamps, and exit status.
- [ ] Loop success requires evidence exit code 0; `<promise>DONE</promise>` is ignored.
- [ ] Failed evidence is fed into the next fresh iteration and max iterations are enforced.
- [ ] Tests use stub binaries and pass on Windows Git Bash, Linux, and macOS.
- [ ] Shell files use LF and the new kernel passes ShellCheck.
- [ ] README first screen gives a five-minute proof path and makes no simulated capability claims.
- [ ] CI, contributing guide, issue forms, PR template, security policy, and release notes exist.

## Tasks

### 1. Add the doctor tracer bullet

- Create `tests/run.sh` and behavior assertions for adapter discovery.
- Run tests and confirm failure because `bin/orch` does not exist.
- Implement only `doctor`, adapter discovery, and help.
- Run tests and ShellCheck.

### 2. Add safe, write-never dry-run

- Add a failing test that places a trap CLI on PATH and asserts no invocation and no run directory.
- Implement argument parsing, task normalization, adapter selection, and dry-run output.
- Verify the test passes.

### 3. Add real one-shot execution and artifacts

- Add failing tests with stub binaries for all five adapters.
- Assert provider-specific argument mapping, output capture, exit propagation, and artifact fields.
- Implement adapter scripts and run artifact helpers.
- Verify all adapter slices pass.

### 4. Add the evidence-gated loop

- Add a failing test where evidence fails once and passes on the second iteration.
- Add a failing exhaustion test where evidence never passes.
- Implement fresh iteration prompts, evidence output capture, bounded retry, and final status.
- Verify model completion prose does not affect the result.

### 5. Add standalone verification

- Add a failing test that re-verifies a recorded run.
- Implement `verify --run` with path validation and durable evidence output.
- Verify pass/fail exit propagation.

### 6. Productize the repository

- Rewrite `README.md`, `AGENTS.md`, and `CLAUDE.md` around the portable interface.
- Add `docs/architecture.md`, `docs/adapters.md`, migration notes, audit/research reports, and v3 changelog.
- Mark simulated legacy workflows honestly.
- Add `.gitattributes`, CI matrix, contribution templates, security policy, and release checklist.

### 7. Validate and publish

- Run Bash syntax, JSON parse, behavior tests, ShellCheck, link/path checks, and dry-run E2E.
- Run independent code review and fix blocking findings.
- Commit the verified branch.
- Unarchive the repository, push a branch, open a PR, and prepare repository metadata/release assets.
