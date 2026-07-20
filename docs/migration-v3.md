# Migration to the provider-neutral kernel

## What changed

The stable execution boundary moved from ad hoc `.kiro/workflows/*.sh` scripts to:

```bash
./bin/orch doctor
./bin/orch run
./bin/orch loop
./bin/orch verify
```

Kiro remains first-class, but execution, evidence, and retry semantics no longer depend on Kiro-specific prose or flags.

## Mapping

| Historical behavior | Current path |
|---|---|
| Direct `kiro-cli` call | `bin/orch run --cli kiro` |
| Ralph retry loop | `bin/orch loop --cli kiro --verify ...` |
| `<promise>DONE</promise>` | external gate exit 0 |
| Provider-written progress as truth | raw ledger plus deterministic evidence |
| Unbounded/simulated worker | iteration and wall-time budgets |
| Inline provider flags | `lib/orch/adapters/<provider>.sh` |
| Default trust bypass | explicit `--unsafe` only |
| Fixed model ID | provider/account default or explicit vendor config |

## Ralph compatibility wrapper

`.kiro/workflows/ralph-kiro.sh` now executes:

```bash
bin/orch loop --cli kiro "$@"
```

Use modern loop arguments:

```bash
./.kiro/workflows/ralph-kiro.sh \
  --role orchestrator \
  --task-file PLAN.md \
  --verify "bash tests/run.sh" \
  --max-iterations 5
```

Historical flags such as `--parallel`, `--agents`, `--worktrees`, and hour-based simulated timeouts are not accepted by the wrapper. This is deliberate: the current portable core does not claim safe parallel write isolation.

## Migrating a workflow

1. Identify its actual goal, provider, work directory, and deterministic acceptance command.
2. Replace direct provider invocation with `bin/orch run` or `bin/orch loop`.
3. Remove self-reported completion tokens from control flow.
4. Move provider-only arguments into the corresponding adapter.
5. Set positive attempt and wall-time budgets.
6. Preserve raw outputs and non-zero statuses.
7. Add behavior tests using stub CLIs before promoting the workflow.
8. Mark vendor-only extensions explicitly instead of adding no-op compatibility flags.

## Legacy workflow status

| Area | Status | Reason |
|---|---|---|
| `bin/orch` and `lib/orch/` | Supported beta | Contract-tested portable seam |
| `ralph-kiro.sh` | Compatibility wrapper | Real Kiro path through supported core |
| `ralph-loop-v2.sh` | Disabled by default | Completion-token semantics; not adapter-backed |
| worktree manager | Disabled by default | Forced cleanup and hard-reset rollback require redesign |
| chain/fusion/dual-verify | Disabled pattern library | Simulated/prose-controlled execution, not supported contracts |
| B/L-thread runners | Disabled by default | Nested/long-running safety and durability not verified |
| hooks and legacy completion tokens | Inactive legacy | Removed from active settings; never completion authority |

Hazardous historical entry points require the exact environment value `KIRO_ENABLE_UNSUPPORTED_LEGACY=I_ACCEPT_THE_RISK`. This is a quarantine escape hatch for deliberate source research, not a safety guarantee or compatibility promise.

## Kiro agent schema

Maintained Kiro 2.x agent files no longer pin dated Claude model IDs. `orchestrator` and `ralph-master` use the current `subagent` tool name. Kiro V3 configuration must live separately until an explicit migration is implemented and tested.

## Rollback

The migration is isolated on a feature branch. To compare behavior without rewriting history:

```bash
git diff main...feat/multi-cli-orchestrator-v3
```

Do not hard-reset a working tree containing user work. Use a separate clone or worktree for historical comparison.
