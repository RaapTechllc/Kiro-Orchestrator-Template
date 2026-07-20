# Full Repository Audit: Architecture, Security, Quality, and Relaunch

**Repository:** `C:\Users\Kyle\CC\Kiro-Orchestrator-Template`
**Branch:** `feat/multi-cli-orchestrator-v3`
**HEAD:** `8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83`
**Audit date:** 2026-07-16
**Scope:** Current working tree, emphasizing `.kiro/workflows/`, `.kiro/hooks/`, `.kiro/scripts/`, and the supported `bin/orch` + `lib/orch` core.

## Executive summary

The supported shell core is **statically separated** from the legacy workflow implementation: `bin/orch` sources only `lib/orch/common.sh`, adapters are dispatched through `lib/orch/adapters/`, and no `bin/orch` or `lib/orch` file references `.kiro`, the worktree manager, or the Ralph stop hook. It also requires an external verification command for loops and contains no merge, reset, push, or worktree operation. The replacement compatibility wrapper delegates directly to the supported core. The expanded contract suite passed **20/20**, focused ShellCheck passed, and `bash -n` passed for the supported and tracked legacy shell surface.

The initial audit proved that the boundary alone did **not** make every retained legacy entry point safe. The legacy pack contained path-traversal-assisted forced deletion, force branch deletion, hard reset, token-triggered automatic merge, sourced state files, shell-string interpolation on macOS/Windows, simulated execution that reported success, global temporary-state races, and prose-based verification.

**Original finding count:** Critical 0, High 8, Medium 8, Low 3. Line references below identify the audit snapshot before quarantine guards were inserted; the vulnerable implementations remain preserved behind those guards for migration research.

## Post-audit remediation status

The modernization now fails closed on the audit's most dangerous default paths:

- Ten simulated, token-controlled, destructive worktree, and broad Git entry points refuse execution unless the operator sets the exact value `KIRO_ENABLE_UNSUPPORTED_LEGACY=I_ACCEPT_THE_RISK`.
- The active Kiro settings no longer load the Ralph stop hook, advertise `<promise>DONE</promise>`, or blanket-allow `Bash(*)`.
- The retained Ralph hook is an inert compatibility stub.
- Claude safe mode changed from `acceptEdits` to `dontAsk` with a file-tool allowlist; Codex uses explicit workspace sandboxing; Kiro uses selective file-tool trust; OpenCode receives an explicit deny-by-default policy.
- Run artifacts inherit `umask 077`.
- Run roots carry a schema marker. Standalone verification rejects arbitrary/symlinked directories and appends unique evidence instead of overwriting prior evidence.
- The test harness always creates and deletes its own private child directory, even when a caller supplies a temporary parent.

These controls reduce the default attack surface; they do **not** rehabilitate the guarded legacy implementations. Enabling the risk-acceptance variable re-exposes the findings below.

## Architecture and product assessment

### What is strong

- `bin/orch` is a defensible, narrow process-adapter boundary rather than a false universal agent API.
- Provider-specific flags remain isolated under `lib/orch/adapters/`.
- Completion authority belongs to deterministic external commands, not model prose.
- Attempts are bounded by provider timeout, verification timeout, and iteration budget.
- Raw stdout, stderr, prompts, statuses, timeout markers, and verification evidence are retained.
- Kiro remains first-class while Claude Code, Codex CLI, OpenCode, and Hermes use the same operator command surface.
- Documentation now distinguishes contract-tested behavior, live-tested behavior, unsupported legacy code, and unknowns.

### What still blocks a production-hardened claim

- The timeout wrapper creates and terminates a provider process group, and the current contract test proves ordinary descendants are removed. Deliberately detached new sessions may still survive and cross-platform CI evidence remains pending.
- Kiro is not installed on the audit host, so real hook discovery, selective trust, account/model behavior, and V3 compatibility remain untested.
- Provider contracts are stub-tested, not authenticated end-to-end across all five CLIs.
- Structured provider event schemas are retained raw but not normalized or version-pinned.
- Prompts passed as command-line arguments by Kiro, OpenCode, and Hermes can hit platform argument-size limits and may be visible to local process inspection.
- Legacy source still carries broad ShellCheck and portability debt even though hazardous entry points are quarantined by default.

### Live evidence

- Claude Code completed the isolated golden path in safe mode on the first iteration; provider exit, exact `result.txt`, verification output, and `status=verified` were read back from the ledger.
- OpenCode reached its configured provider but received HTTP 401 for an expired/invalid token. It returned process exit 0 while emitting a JSON API error; the external gate rejected the attempt and the loop exhausted. The kernel now labels zero-exit attempts `unverified` to avoid implying completion.
- Codex 0.144.5 and Hermes completed isolated live golden paths on iteration 1. The globally installed Codex 0.117.0 remains stale, OpenCode authentication failed, and Kiro was not installed.

### Relaunch assessment

At audit time the GitHub repository was public but archived, had 2 stars and 0 forks, no description/homepage/topics, no release, and a 28% community profile. Promotion while archived is a weak idea: GitHub presents archived repositories as read-only and no longer maintained. The highest-leverage relaunch order is:

1. finish local validation and at least one authenticated golden path;
2. unarchive and enable Template mode;
3. add the tested description and accurate topics;
4. publish an honest prerelease with the CI-backed golden path;
5. demonstrate the evidence ledger in a short launch asset.

Recommended description: **Multi-CLI coding-agent orchestration with provider adapters, bounded loops, external verification, and reproducible run artifacts.**

## Threat model and severity

- Inputs passed by a human or coding agent, mutable repository files, generated agent output, and concurrent runs are treated as potentially malformed or adversarial.
- **Critical:** direct, likely compromise or broad irreversible loss without meaningful operator action.
- **High:** arbitrary command execution, destructive loss, unauthorized merge/push, or false completion likely to drive destructive follow-up.
- **Medium:** material integrity/confidentiality risk requiring additional conditions or explicit operator invocation.
- **Low:** hardening, portability, or assurance defect with limited immediate impact.
- No destructive proof-of-concept was executed. Path normalization and static data flow were inspected without deleting, resetting, merging, or pushing anything.

# Findings

## Critical

No Critical finding was established from the current working tree.

## High

### H-1 — Worktree names can escape the worktree root and reach forced recursive deletion

**Evidence**

- `WORKTREE_NAME` and `WORKTREE_BASE` are accepted without an identifier/canonical-path policy (`.kiro/workflows/worktree-manager.sh:59-79`).
- A path is formed by concatenating those values (`.kiro/workflows/worktree-manager.sh:103-110`).
- Cleanup force-removes the computed worktree; if Git refuses it, the fallback is `rm -rf`, followed by branch deletion that escalates from `-d` to `-D` (`.kiro/workflows/worktree-manager.sh:501-523`).
- `cleanup-all` relies on substring matching instead of canonical containment (`.kiro/workflows/worktree-manager.sh:531-543`).

For example, static normalization of the default-base expression for a name containing enough `../` segments escapes `../.worktrees` (the audit normalized `../.worktrees/Kiro-Orchestrator-Template-../../../victim` to `../victim`). The existence check at line 506 does not establish that the target is a registered worktree or remains under an approved root.

**Impact:** A malformed or model-generated name can delete an unrelated directory, and `git branch -D` can discard unmerged commits.

**Remediation:** Restrict names to a conservative pattern such as `^[A-Za-z0-9][A-Za-z0-9._-]*$`; canonicalize the base and candidate; require the candidate to be a strict descendant; confirm it appears exactly in `git worktree list --porcelain`; remove the `rm -rf` fallback; never fall back to `git branch -D`; refuse cleanup when dirty or unmerged; add adversarial path tests.

### H-2 — A model-controlled completion token can trigger unattended commit and merge

**Evidence**

- The dashboard's `m` action treats `<promise>DONE</promise>` in an agent log as authorization to merge (`.kiro/workflows/dashboard.sh:180-186`).
- The merge path auto-stages and commits all worktree changes (`.kiro/workflows/worktree-manager.sh:464-470`), checks out the configured main branch, and merges without an approval prompt (`.kiro/workflows/worktree-manager.sh:473-491`).
- The same repository explicitly says model prose/tokens are not completion evidence and supported-core automation must not auto-merge (`AGENTS.md:25-34`).

**Impact:** Prompt injection, stale output, or an accidental token can cause unreviewed code to be committed and merged to the main branch.

**Remediation:** Delete token-driven merge behavior. Require immutable external evidence, a clean/expected worktree and base SHA, required checks, an explicit per-branch operator confirmation, and preferably a PR/review workflow. Do not auto-commit as part of merge.

### H-3 — Rollback performs a hard reset of the configured main branch from mutable local state

**Evidence**

- Rollback trusts `pre_merge_head` from `.kiro/state/rollback-stack.json` (or a fallback log) (`.kiro/workflows/worktree-manager.sh:154-183`).
- After a simple `y/N` prompt it checks out `MAIN_BRANCH` and runs `git reset --hard "$pre_merge_head"` (`.kiro/workflows/worktree-manager.sh:190-217`).
- There is no clean-tree check, no assertion that `HEAD` is the recorded merge commit, no ancestry check, no remote-divergence check, and no backup ref.

**Impact:** Concurrent work, uncommitted files, later commits, or tampered rollback state can be irreversibly discarded.

**Remediation:** Replace hard reset with a revert of the exact verified merge commit. Refuse unless the current branch, HEAD, cleanliness, ancestry, and repository identity all match the recorded transaction; create a backup ref; lock rollback state; use a structured journal with atomic writes.

### H-4 — Resuming a chain sources generated state as shell code

**Evidence**

- Workflow names and custom phases come directly from CLI values (`.kiro/workflows/chain-workflow.sh:87-119`).
- Those values are emitted unescaped into an assignment-form state file (`.kiro/workflows/chain-workflow.sh:238-249`).
- Resume executes that file with `source` (`.kiro/workflows/chain-workflow.sh:252-255,520-529`).

A phase such as `$(command ...)` or shell metacharacters embedded in a workflow name becomes executable syntax on resume.

**Impact:** Arbitrary command execution under the operator's account when a crafted or tampered workflow is resumed.

**Remediation:** Never source runtime state. Store JSON with `jq --arg`, parse fixed fields with `jq -er`, validate all identifiers, reject unknown keys/types, and atomically replace state files created with owner-only permissions.

### H-5 — Cross-platform notification fallback interpolates untrusted text into shell-language source

**Evidence**

- `AGENT_TYPE` is CLI-controlled (`.kiro/workflows/l-thread-runner.sh:80-96`) and later appears in a notification message (`.kiro/workflows/l-thread-runner.sh:565-566`).
- The macOS and Windows fallbacks construct AppleScript/PowerShell source by interpolation (`.kiro/workflows/l-thread-runner.sh:215-230`).
- Chain workflow uses the same pattern (`.kiro/workflows/chain-workflow.sh:222-235`) and passes phase text into it (`.kiro/workflows/chain-workflow.sh:439-452`).

**Impact:** Quotes or script fragments in names/messages can break out of the intended string and execute AppleScript or PowerShell commands, especially on the stated Windows host where `powershell.exe` is the expected fallback.

**Remediation:** Pass data as positional arguments/environment variables to fixed scripts and read it as data; do not generate `-e`/`-Command` source. Strictly validate identifiers even after switching transport.

### H-6 — Several advertised workflows simulate execution and manufacture success

**Evidence**

- Chain execution comments out the real Kiro call, sleeps, writes fabricated work, and emits a checkpoint token (`.kiro/workflows/chain-workflow.sh:317-385`); phase validation is explicitly ignored (`.kiro/workflows/chain-workflow.sh:553-556`).
- Fusion comments out real Kiro execution, generates random findings/confidence, and writes `<promise>DONE</promise>` (`.kiro/workflows/fusion.sh:180-250`).
- L-thread comments out real Kiro execution, fabricates progress, and randomly emits completion (`.kiro/workflows/l-thread-runner.sh:340-388`).

**Impact:** Operators and parent workflows can receive convincing but false completion, validation, and security-review claims. This can authorize deployment, merge, or cleanup decisions with no real work performed.

**Remediation:** Make these commands fail closed with a clear “unsupported legacy prototype” error until they are wired through `bin/orch`, use deterministic external gates, and have behavioral tests. Never ship random simulated success in an operational command.

### H-7 — The configured stop hook uses shared predictable temporary files and prose completion

**Evidence**

- Ralph v2 and the hook use a repository-global state file and a global `/tmp/kiro-ralph-last-output.txt` (`.kiro/workflows/ralph-loop-v2.sh:16-22`; `.kiro/hooks/ralph-stop.sh:13-18`).
- State updates write through predictable `/tmp/ralph-state-tmp.json` with no exclusive creation or lock (`.kiro/hooks/ralph-stop.sh:21-26`).
- Completion is accepted by grepping model output for `<promise>DONE</promise>` (`.kiro/hooks/ralph-stop.sh:98-117`).
- Iteration updates are unlocked read-modify-write operations (`.kiro/hooks/ralph-stop.sh:124-130`).

**Impact:** Concurrent repositories/sessions can cross-contaminate completion, lose state updates, or follow a pre-created temporary symlink. Model prose remains a controlling input.

**Remediation:** Remove this hook from active configuration. If retained experimentally, use `mktemp -d` with mode 0700, per-run IDs and absolute paths, atomic same-directory replacement, advisory locking, schema validation, and external exit-code evidence instead of tokens.

### H-8 — PR creation silently commits the entire working tree and pushes it

**Evidence**

- Any dirty working tree triggers `git add -A` and an automatic commit (`.kiro/scripts/create-pr.sh:15-19`).
- The branch is then pushed to `origin` (`.kiro/scripts/create-pr.sh:21-25`).

**Impact:** Unrelated changes, generated artifacts, or secrets not covered by `.gitignore` can be committed and exfiltrated to the remote without review.

**Remediation:** Refuse a dirty tree by default. Require an explicit path allowlist or pre-existing reviewed commits; run secret scanning; show the exact staged diff; require confirmation before push; never combine staging, committing, pushing, and PR creation implicitly.

## Medium

### M-1 — Legacy validation executes arbitrary shell strings with `eval`

**Evidence:** CLI/environment values populate `VALIDATION_COMMAND` (`.kiro/workflows/l-thread-runner.sh:17,130-136`; `.kiro/workflows/worktree-manager.sh:20,73-76`) and are executed using `eval` (`.kiro/workflows/l-thread-runner.sh:253-270`; `.kiro/workflows/worktree-manager.sh:361-380`).

**Risk:** Although these options are documented as commands, `eval` adds a second parse and makes accidental interpolation/injection more likely when values are forwarded from agents or configuration.

**Remediation:** Accept a script path plus argument array, or clearly define an explicit shell-command boundary and execute `bash -c -- "$command"` only after an unsafe/explicit opt-in. Never compose the command from lower-trust fragments.

### M-2 — Prose-only dual verification is spoofable and failures often return success

**Evidence:** Verifier output is parsed by grepping `VERIFICATION: PASS` before `FAIL` (`.kiro/workflows/dual-verify.sh:269-291`). A FAIL exits nonzero only in strict mode; UNKNOWN also falls through, and `main` completes successfully (`.kiro/workflows/dual-verify.sh:303-350`). The writer/verifier pipelines do not enable `pipefail`, so `tee` can mask CLI failure (`.kiro/workflows/dual-verify.sh:17,240-249,269-278`).

**Risk:** Prompt injection, echoed instructions, output containing both tokens, or a failed CLI can yield a success exit or “ready for merge” message.

**Remediation:** Replace prose parsing with `bin/orch verify` and a deterministic command; fail closed on unknown/nonzero; if pipelines remain, enable and test `set -o pipefail` and inspect the provider exit explicitly.

### M-3 — Legacy callers of the replaced Ralph entry point are incompatible and may still record success

**Evidence:** The wrapper forwards every argument to `orch loop --cli kiro` (`.kiro/workflows/ralph-kiro.sh:4-12`), but callers still pass removed options such as `--agents`, `--parallel`, `--max-iter`, and omit mandatory `--verify` (`.kiro/workflows/b-thread-orchestrator.sh:201-218,297-314`). Those calls are piped to `tee` without `pipefail`, and `$?` therefore reflects `tee` (`.kiro/workflows/b-thread-orchestrator.sh:215-228,309-324`).

**Risk:** The supported core fails safely, but the legacy parent can mark the failed invocation complete.

**Remediation:** Make legacy callers fail closed immediately or translate old arguments deliberately and require a verification command. Enable `pipefail`; add compatibility tests that assert obsolete invocations fail visibly.

### M-4 — Merge/cleanup/PR scripts lack transaction, ownership, and policy checks

**Evidence:** Merge checks only local validation and then mutates the current main worktree (`.kiro/workflows/worktree-manager.sh:443-498`). `merge-pr.sh` checks only GitHub's `mergeable` field before merge and remote branch deletion (`.kiro/scripts/merge-pr.sh:5-20`).

**Risk:** Required CI/reviews, repository identity, expected base SHA, protected-branch policy, dirty state, and concurrent updates are not verified.

**Remediation:** Require repository/remote identity, expected head/base SHAs, clean status, required checks and approvals, protected-branch policy, and explicit confirmation. Prefer GitHub branch protection and PR merge queues.

### M-5 — Session and health state are not safely encoded or synchronized

**Evidence:** Session names/tasks are interpolated into paths and JSON (`.kiro/workflows/session-manager.sh:8-15`); jq field/filter text is built from untrusted arguments (`.kiro/workflows/session-manager.sh:18-32`). Health JSON embeds an unescaped last log line (`.kiro/workflows/health-monitor.sh:24-35`). Shared state and metric files are written with no lock across parallel workflows (for example `.kiro/workflows/fusion.sh:537-546` and `.kiro/workflows/b-thread-orchestrator.sh:151-173`).

**Risk:** Path traversal, malformed JSON, arbitrary jq transformations, lost updates, and mixed-session status are possible.

**Remediation:** Validate IDs, use `jq --arg/--argjson`, use one per-run state directory, lock shared indexes, and write atomically to a same-directory temporary file.

### M-6 — Raw prompts/output/verification evidence can persist secrets with default permissions

**Evidence:** The core stores task text, normalized prompts, provider stdout/stderr, verification command/output, and feedback (`bin/orch:109-127,223-253`; `lib/orch/common.sh:98-123,160-207`). `.orchestrator/` is Git-ignored (`.gitignore:5-12`), but no code sets a restrictive umask, permissions, retention period, or redaction policy.

**Risk:** Credentials or sensitive source/context emitted by an agent or verification command remain readable to other local principals according to the process umask and can be copied/backed up despite not being staged.

**Remediation:** Create run roots with umask 077 and directories 0700; document retention and deletion; warn that tasks/verification commands are recorded; provide opt-in redaction for known secret patterns while preserving a secure raw-evidence mode.

### M-7 — The supported timeout kills one PID, not a process group, and has a PID-reuse race

**Evidence:** The watchdog records a child PID, checks it, then sends TERM and later KILL to that PID only (`lib/orch/timeout.sh:14-39`). The architecture acknowledges detached descendants may survive (`docs/architecture.md:96`).

**Risk:** Provider descendants can outlive timeout. If the watched process exits between `kill -0` and the later signals and the OS reuses the PID, an unrelated process could receive a signal.

**Remediation:** Start providers in a dedicated process group/session and terminate the group; re-check process identity before escalation; use native job objects on Windows where available; add descendant-survival and boundary-race tests.

### M-8 — Runtime isolation from Kiro hooks is not live-proven

**Evidence:** The Kiro adapter changes into the requested repository and executes `kiro-cli` (`lib/orch/adapters/kiro.sh:4-15`), while repository-local configuration declares the legacy stop hook (`.kiro/settings.local.json:5-16`). The adapter documentation states Kiro was not installed during local audit and tests use stubs (`docs/adapters.md:70-82`).

**Risk:** Static shell dependencies are isolated, but it is unverified whether a real Kiro invocation in this repository auto-discovers and runs the legacy hook, which would reintroduce H-7 into the supported path.

**Remediation:** Add a live Kiro smoke test that records hook discovery behavior; move legacy hook configuration under an explicitly experimental profile; ensure supported invocation disables legacy hooks if the CLI supports that policy.

## Low

### L-1 — Global `Bash(*)` approval undermines narrow deny patterns

**Evidence:** `.kiro/settings.local.json` allows `Bash(*)` while denying only textual `Bash(rm -rf *)` and selected writes (`.kiro/settings.local.json:31-45`).

**Risk:** Equivalent destructive commands (`git reset --hard`, `git clean`, scripts, alternate `rm` syntax) remain pre-approved if this schema is honored.

**Remediation:** Remove the wildcard; allow only specific commands/argument patterns; enforce destructive-operation policy outside prompt text.

### L-2 — Direct-entry scripts are not executable in the current tree/index

**Evidence:** `bin/orch:1` and `.kiro/workflows/ralph-kiro.sh:1` are shebang entry points and docs instruct `./bin/orch` (`AGENTS.md:14-20`), but audit-time mode inspection reported `0666` in the working tree and tracked legacy scripts are mode `100644`.

**Risk:** Git Bash on Windows can mask this; a POSIX clone may return “permission denied,” including when the compatibility wrapper executes `bin/orch` directly.

**Remediation:** Stage executable mode `100755` for entry points/adapters or consistently invoke them via `bash`; add a POSIX checkout test.

### L-3 — Cross-platform utilities and quoting are inconsistent in legacy workflows

**Evidence:** Legacy scripts depend on GNU/BSD-specific combinations (`date -Iseconds`, `date -d`/`date -r`, `stat -c`/`stat -f`, `bc`, `read -t -n`) across, for example, `.kiro/workflows/chain-workflow.sh:202-218,605`, `.kiro/workflows/health-monitor.sh:18-29`, and `.kiro/workflows/l-thread-runner.sh:174-180,446-545`. ShellCheck also reports syntax errors in `.kiro/workflows/metrics-tracker.sh:297-302`.

**Risk:** Behavior differs or fails on Windows Git Bash, macOS, and minimal Linux systems, potentially skipping status/validation logic.

**Remediation:** Declare supported platforms, centralize portability helpers, check dependencies up front, and run legacy syntax/behavior tests on Windows Git Bash, macOS, and Linux before promoting any workflow.

# Supported-core isolation assessment

## Positive controls observed

1. **No legacy import or Git mutation:** No `.kiro`, merge, reset, push, clean, branch deletion, or worktree operation occurs in `bin/orch`/`lib/orch`; architecture explicitly forbids supported-core destructive Git cleanup (`docs/architecture.md:86-100`).
2. **No `eval` for provider invocation:** Adapters use arrays and stdin/quoted arguments (`lib/orch/adapters/claude.sh:4-13`; `lib/orch/adapters/codex.sh:4-15`; `lib/orch/adapters/kiro.sh:4-15`).
3. **Explicit unsafe mappings:** Permission bypass flags are conditional on `--unsafe` in every adapter (`lib/orch/adapters/kiro.sh:10-15`; `lib/orch/adapters/claude.sh:9-13`; `lib/orch/adapters/codex.sh:9-15`; `lib/orch/adapters/opencode.sh:9-15`; `lib/orch/adapters/hermes.sh:9-14`).
4. **External evidence gate:** Loop parsing requires `--verify`, and only its exit code yields `status=verified` (`bin/orch:150-178,194-207,248-269`). There is no completion-token parser.
5. **Bounded execution and evidence:** Positive integer budgets are validated (`bin/orch:196-207`), provider/verification output and status are retained (`bin/orch:223-264`; `lib/orch/common.sh:160-207`), and dry-run returns before writes/invocation (`bin/orch:97-107,209-221,327-334`).

## Remaining supported-core caveats

- `--verify` is intentionally an operator-supplied shell command executed with `bash -c` (`lib/orch/common.sh:160-173`). This is an explicit command-execution boundary, not safe input for untrusted data; documentation should say so plainly.
- Artifact creation now inherits `umask 077`, and supported entry points are staged with executable mode `100755`, but retention/redaction remains an operator concern. Deliberately detached-session timeout behavior, remote cross-platform CI, and real Kiro hook discovery still need closure before describing the core as production-hardened.
- The tests are strong contract tests plus live Claude, Codex, and Hermes golden paths, not a complete live-provider security matrix. The current local evidence is 24/24 contract tests passing, supported/legacy `bash -n` passing, and focused supported-core ShellCheck passing.

# Verification performed

- Inspected every shell file under `.kiro/workflows/`, `.kiro/hooks/`, `.kiro/scripts/`, `bin/`, and `lib/orch/`, plus repository guidance/configuration.
- Ran targeted searches for `eval`, `source`, shell-command construction, completion tokens, PID/temp state, secrets/logging, and destructive Git operations.
- Ran repository-wide ShellCheck for audit evidence; legacy source retained multiple correctness/portability findings. Focused ShellCheck for the supported core passed after documenting the trap-invoked cleanup function.
- Ran `bash tests/run.sh`: **24 passed, 0 failed**.
- Ran `bash -n` across the supported core, compatibility paths, hooks, workflows, and scripts: **passed**.
- Parsed **19 JSON** and **6 YAML** files successfully.
- Validated live Claude, Codex 0.144.5, and Hermes golden paths and read back exact results, provider metadata, gate output, and `status=verified`.
- Searched the supported core for references to `.kiro`, legacy hook/worktree names, `eval`, and destructive Git commands: **none found**.
- No actual credential was identified in executable/configuration scope; examples contain documented placeholders. The persistence risk in M-6 remains.

# Remediation priority

1. Keep the quarantined legacy entry points disabled until their internals are redesigned; do not treat the risk-acceptance escape hatch as support.
2. Replace sourced state and notification source interpolation before any legacy workflow is re-enabled.
3. Add concurrency-safe per-run state to any legacy concept promoted into the core.
4. Validate the new process-group timeout behavior on Linux/macOS CI and document the detached-session limit.
5. Live-test Kiro hook isolation and selective trust, then complete the remaining provider matrix.
