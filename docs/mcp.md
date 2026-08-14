# Agent-first MCP wrapper

The supported product remains `bin/orch`. `orch mcp` is a stdio JSON-RPC skin so a third-party coding agent can call `doctor`, `run`, `loop`, and `verify` without parsing `summary.env` by hand.

This is not a dashboard, not a second orchestrator, and not a completion authority. A loop is complete only when the configured external verification command exits 0.

## Start

```bash
./bin/orch mcp --help
./bin/orch mcp
```

Wire it as a local stdio server. Use an absolute path in desktop clients:

```json
{
  "mcpServers": {
    "orch": {
      "command": "bash",
      "args": ["/absolute/path/to/bin/orch", "mcp"]
    }
  }
}
```

A repository-relative example lives at `examples/mcp/mcp.json`. Python 3 is required for the wrapper; the CLI itself stays Bash.

## Tools

| Tool | Maps to | Notes |
|---|---|---|
| `orch_doctor` | `orch doctor` | Availability probe. Not completion evidence. |
| `orch_run` | `orch run` | Zero provider exit is `unverified`. Never `verified`. |
| `orch_loop` | `orch loop` | Requires `verify`. `verified` only after the gate exits 0. |
| `orch_verify` | `orch verify` | Append-only evidence against a marked run directory. |

`--unsafe` is omitted unless the tool argument `unsafe` is explicitly true. Prompts travel as argv data; the wrapper never uses `eval` or `shell=True`.

## JSON envelope

Successful tool results include `structuredContent` and the same object as text JSON:

```json
{
  "schema": 1,
  "source": "bin/orch",
  "command": "loop",
  "ok": true,
  "exit_code": 0,
  "orch_argv": ["loop", "--cli", "claude", "--verify", "bash tests/run.sh"],
  "run_id": "20260813T142800Z-12345-loop",
  "run_dir": "/home/user/.local/state/orch/runs/20260813T142800Z-12345-loop",
  "status": "verified",
  "iterations": 2,
  "ledger": {
    "dir": "/home/user/.local/state/orch/runs/20260813T142800Z-12345-loop",
    "marker": ".../.orch-run",
    "summary": ".../summary.env"
  },
  "summary": {
    "status": "verified",
    "iterations": "2"
  },
  "prose_is_not_done": true,
  "completion_policy": "Completion requires the configured external verification command to exit 0. ..."
}
```

`run` responses use `status=unverified` on a zero provider exit. Ledger `*.env` files are parsed as `key=value` data and are never sourced as shell. Provider stdout/stderr stay in the ledger; the MCP result returns paths, not log bodies or environment secrets. `cli_stderr` is omitted from the envelope so adapter tokens cannot leak. `tools/call` sets `isError` when `ok` is false or `exit_code` is non-zero.

On Windows/Git Bash, `orch mcp` probes `python3`, `python`, and `py -3`, skips Microsoft Store aliases, converts the server path with `cygpath -w` when available, and writes one UTF-8 JSON-RPC line per message. Set `ORCH_PYTHON` to pin the interpreter.

## Not in scope

- Replacing `./bin/orch doctor|run|loop|verify`
- GUI or dashboard status
- Treating model prose or `<promise>DONE</promise>` as done
- Flattening provider permission, sandbox, network, or trust flags
