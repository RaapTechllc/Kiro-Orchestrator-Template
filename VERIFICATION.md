# Verification status

**Last updated:** 2026-07-16
**Scope:** provider-neutral beta kernel on `feat/multi-cli-orchestrator-v3`

## Verified locally

| Claim | Evidence |
|---|---|
| Baseline tracked shell parses | 23 tracked shell scripts passed `bash -n` before modernization |
| Baseline tracked JSON parses | 19 tracked JSON files parsed before modernization |
| Five adapters share one command seam | stub-backed behavior tests invoke Kiro, Claude, Codex, OpenCode, and Hermes adapters |
| Prompt text is not evaluated as shell source | test task contains literal command substitution syntax and creates no injected file |
| Dry-run invokes nothing and writes nothing | `run`, `loop`, and `verify` behavior tests check provider-call logs and ledger/evidence paths |
| Safe mode omits broad bypass flags | per-provider negative argument assertions |
| Unsafe mode is explicit | per-provider positive argument assertions |
| Provider failures fail closed | raw non-zero exit, stderr, metadata, and status retained |
| Provider wall-time is bounded | timeout fixture exits 124, writes a timeout marker, and records `timed_out` |
| Natural exit 124 is not a timeout | run, loop, and verify require the watchdog marker before recording `timed_out` |
| Relative paths remain stable | run roots and workdirs are canonicalized; Codex receives one absolute `-C` path |
| Loop completion is external | loop retries until the configured shell gate exits 0 |
| Loop exhaustion fails | bounded failing gate returns non-zero with `status=exhausted` |
| Zero provider exit is not completion | attempt metadata records `unverified`; only an external gate can record `verified` |
| Verification is reusable and append-only | `orch verify` requires a schema marker, rejects arbitrary/symlinked directories, and creates a unique evidence child |
| Legacy hazards fail closed | behavior test invokes ten simulated, token-controlled, or destructive entry points and requires default refusal |
| Run artifacts are private by default | adapter stubs observe inherited process `umask 0077` |
| Current contract suite passes | 24 tests pass on Windows/Git Bash |
| New supported shell is lint-clean | focused ShellCheck exits 0 |
| Claude golden path works live | authenticated Claude Code created exact fixture output; external gate passed on iteration 1 |
| Codex golden path works live on a current CLI | isolated Codex 0.144.5 created exact fixture output; external gate passed on iteration 1 |
| Hermes golden path works live | authenticated Hermes created exact fixture output; external gate passed on iteration 1 |

Canonical local commands:

```bash
bash tests/run.sh
bash -n bin/orch lib/orch/common.sh lib/orch/timeout.sh lib/orch/adapters/*.sh tests/run.sh
shellcheck -x -P . bin/orch lib/orch/adapters/*.sh lib/orch/timeout.sh tests/run.sh
```

## Contract-tested versus authenticated end-to-end

Provider tests use temporary stub binaries. They verify executable selection, argument boundaries, stdin/argument prompt transport, safe/unsafe mappings, raw output capture, status propagation, and artifacts without spending quota or granting tool access.

This is strong evidence for the shell contract. Claude Code additionally completed the isolated golden path through the real adapter and external gate. That one run is not evidence that every vendor account, CLI version, model, authentication path, or permission policy will complete a real coding task. The GitHub Actions matrix is configured but has not yet executed remotely for this branch.

## Environment probes during audit

- Claude Code completed the authenticated golden path in safe mode; provider exit was 0 and the deterministic gate passed on iteration 1.
- The globally installed Codex 0.117.0 was blocked by stale `service_tier` and model-cache configuration. An isolated current Codex 0.144.5 invocation with a non-persistent `service_tier="fast"` override completed the golden path in safe mode and passed the gate on iteration 1.
- OpenCode reached its configured provider but received HTTP 401 for an expired/invalid access token. OpenCode itself returned process exit 0 with a JSON error; the external gate correctly rejected completion and the loop exhausted.
- Hermes Agent completed the authenticated golden path in safe mode and passed the gate on iteration 1.
- Kiro CLI was **not installed locally**; only first-party docs and changelogs were verified.

See `docs/adapters.md` for observed version evidence and `docs/research/` for citations.

## Not yet verified

- Authenticated golden-path completion for Kiro and OpenCode
- Kiro agent/model compatibility on the audit host
- Kiro V3 configuration or execution
- Resume/session portability
- Native subagent/team semantics
- Safe parallel write isolation and worktree integration
- Deliberately detached descendants that create a new process group/session after provider launch
- Repository-wide ShellCheck cleanliness for legacy workflows
- Real deployment or package installation into another repository

## Legacy status

All tracked shell scripts parse, but parsing is not hardening. A repository-wide ShellCheck audit still reports substantial debt in historical `.kiro/workflows/` scripts. Ten simulated, token-controlled, or destructive legacy entry points now refuse execution by default, the old Ralph stop hook is inactive, and active Kiro settings no longer blanket-allow `Bash(*)`. The opt-in escape hatch preserves historical reference behavior for deliberate research; it is not a supported or hardened path. The supported beta claim excludes those legacy paths except for the rewritten `ralph-kiro.sh` compatibility wrapper.

## Completion policy

A model response, progress file, hook message, or `<promise>DONE</promise>` never proves completion. For the supported core:

1. the provider process must return evidence;
2. the configured external verification command must exit 0;
3. the run ledger must record `status=verified`;
4. publication claims must stay within the evidence above.
