# ADR-0002: MCP JSON envelope derives timeout from the watchdog marker

- **Status:** Accepted
- **Date:** 2026-08-14

## Context

`orch mcp` is an MCP skin over `bin/orch`. The first wrapper returned run id, status, and ledger paths so a third-party agent did not have to parse `summary.env`. Status still came from CLI stdout, and timeout was only visible if the caller inspected `ledger.provider_timeout` or opened an iteration `meta.env`.

The CLI already distinguishes a watchdog timeout from a natural exit 124: only the marker is proof. Copying stdout into JSON would re-open that hole for MCP callers. Asking agents to stat marker files would keep the JSON path shallow.

## Decision

1. Keep `orch mcp` a skin. It does not replace the CLI, does not add a dashboard, and does not decide completion.
2. The JSON envelope is the agent-facing result for `run`, `loop`, and `verify`.
3. `timed_out` is true only when a watchdog marker exists in the run, an iteration, or a verify evidence directory. Exit 124 without a marker is not a timeout.
4. Per-iteration `status` and `timed_out` are folded from each iteration ledger into the envelope so callers do not open `iteration-N/meta.env`.
5. `orch run` still cannot record `verified`. `--unsafe` remains omitted unless the tool argument is explicitly true. Model prose remains not done.

## Consequences

- Agents can classify timeout versus failure from the envelope alone.
- Ledger I/O stays data-only and still translates Git Bash paths for Windows Python.
- The Windows Git Bash pin (`ORCH_BASH`, reject System32/WSL `bash.exe`) is unchanged.
- Callers who only read stdout status are no longer the supported MCP path.
