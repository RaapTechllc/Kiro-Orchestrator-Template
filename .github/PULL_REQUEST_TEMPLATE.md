## Outcome

Describe the operator-visible outcome and why this is the smallest useful change.

## Evidence

- [ ] I added or updated a behavior test and observed the pre-fix failure.
- [ ] `bash tests/run.sh` passes.
- [ ] Supported-core Bash syntax passes.
- [ ] Supported-core ShellCheck passes.
- [ ] Tracked JSON parses.
- [ ] I included an authenticated live run only if I actually performed one.

Paste concise redacted evidence:

```text

```

## Safety and provider contract

- [ ] Provider-specific flags remain inside an adapter.
- [ ] Permission/sandbox/trust bypasses require explicit `--unsafe`.
- [ ] Prompts are data; no command is constructed with `eval`.
- [ ] Raw output and non-zero status are preserved.
- [ ] No secrets or `.orchestrator/` artifacts are included.

## Claims and docs

- [ ] README, adapter docs, changelog, and verification claims match the evidence.
- [ ] Implemented, contract-tested, live-tested, experimental, and unknown states are distinguished.

## Scope

List intentionally deferred work and any legacy paths touched.
