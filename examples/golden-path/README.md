# Golden path: deterministic file creation

This fixture proves the complete loop without depending on a language toolchain.

## Acceptance contract

The agent must create `result.txt` in the fixture working directory with exactly:

```text
orchestrated
```

`verify.sh` is the external authority. Agent prose is ignored.

## Run

From the repository root:

```bash
demo_dir=$(mktemp -d)
cp -R examples/golden-path/. "$demo_dir"

./bin/orch loop \
  --cli codex \
  --task-file "$demo_dir/TASK.md" \
  --workdir "$demo_dir" \
  --verify "bash verify.sh" \
  --max-iterations 3 \
  --timeout 600
```

Use `claude`, `opencode`, or `hermes` after `bin/orch doctor` reports the CLI available. Kiro headless tool writes require an explicit trust policy; configure a least-privilege agent rather than blindly enabling broad trust.

## Expected evidence

- terminal summary: `status: verified`
- `$demo_dir/result.txt`: exactly `orchestrated`
- `.orchestrator/runs/<run-id>/`: provider and verification evidence

Clean up:

```bash
rm -rf "$demo_dir"
```
