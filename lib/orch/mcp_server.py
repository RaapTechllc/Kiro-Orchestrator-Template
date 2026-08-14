#!/usr/bin/env python3
"""Thin stdio MCP wrapper around bin/orch.

This process is an agent-facing skin, not a second orchestrator. It invokes the
real CLI with argv arrays, returns structured JSON, and never treats model prose
as completion evidence. Ledger .env files are read as key=value data and are
never sourced as shell.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from typing import Any, Dict, List, Mapping, Optional, Sequence, Tuple

PROTOCOL_VERSIONS = ("2025-06-18", "2025-03-26", "2024-11-05")
DEFAULT_PROTOCOL_VERSION = "2024-11-05"
SCHEMA = 1
SERVER_NAME = "orch"
SERVER_VERSION = "3.0.0-beta"

COMPLETION_POLICY = (
    "Completion requires the configured external verification command to exit 0. "
    "Model prose, progress files, and <promise>DONE</promise> are not evidence. "
    "orch run records unverified on a zero provider exit and never records verified."
)

SECRET_KEY_RE = re.compile(
    r"(password|secret|token|api[_-]?key|authorization|credential|private[_-]?key)",
    re.IGNORECASE,
)

LEDGER_FILES = (
    ("marker", ".orch-run"),
    ("prompt", "prompt.md"),
    ("stdout", "stdout.log"),
    ("stderr", "stderr.log"),
    ("meta", "meta.env"),
    ("summary", "summary.env"),
    ("task", "task.md"),
    ("feedback", "feedback.txt"),
    ("provider_timeout", "provider.timeout"),
    ("verify_command", "verify.command"),
    ("verify_env", "verify.env"),
    ("verify_stdout", "verify.stdout.log"),
    ("verify_stderr", "verify.stderr.log"),
    ("verify_timeout", "verify.timeout"),
)

SUMMARY_KEYS = {
    "run": "run_dir",
    "evidence": "evidence_dir",
    "adapter": "adapter",
    "status": "status",
    "exit_code": "exit_code",
    "iterations": "iterations",
    "command": "command_name",
    "workdir": "workdir",
    "role": "role",
    "unsafe": "unsafe",
    "timeout_seconds": "timeout_seconds",
    "max_iterations": "max_iterations",
    "verify": "verify",
    "task": "task",
    "verify_timeout_seconds": "verify_timeout_seconds",
}

RUN_ARGS = {
    "task": "--task",
    "task_file": "--task-file",
    "cli": "--cli",
    "workdir": "--workdir",
    "run_root": "--run-root",
    "role": "--role",
    "timeout": "--timeout",
}
LOOP_ARGS = dict(RUN_ARGS)
LOOP_ARGS.update(
    {
        "verify": "--verify",
        "max_iterations": "--max-iterations",
        "verify_timeout": "--verify-timeout",
    }
)
VERIFY_ARGS = {
    "run": "--run",
    "verify": "--verify",
    "workdir": "--workdir",
    "timeout": "--timeout",
}

HELP = """Usage: orch mcp

Speak MCP JSON-RPC on stdio as a thin wrapper around doctor, run, loop, and verify.
The CLI remains the supported seam. This process does not decide completion.
"""


def orch_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def orch_bin() -> str:
    configured = os.environ.get("ORCH_BIN", "").strip()
    if configured:
        return configured
    return os.path.join(orch_root(), "bin", "orch")


def configure_stdio() -> None:
    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    os.environ.setdefault("PYTHONUTF8", "1")
    for stream, write_through in ((sys.stdin, False), (sys.stdout, True)):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is None:
            continue
        kwargs = {"encoding": "utf-8", "errors": "replace", "newline": "\n"}
        if write_through:
            kwargs["write_through"] = True
        try:
            reconfigure(**kwargs)
        except (OSError, ValueError, TypeError):
            continue


def write_message(message: Mapping[str, Any]) -> None:
    payload = json.dumps(message, separators=(",", ":"), ensure_ascii=True) + "\n"
    raw = payload.encode("utf-8")
    buffer = getattr(sys.stdout, "buffer", None)
    if buffer is not None:
        buffer.write(raw)
        buffer.flush()
        return
    sys.stdout.write(payload)
    sys.stdout.flush()


def read_message() -> Optional[Dict[str, Any]]:
    buffer = getattr(sys.stdin, "buffer", None)
    while True:
        if buffer is not None:
            raw = buffer.readline()
            if raw == b"":
                return None
            line = raw.decode("utf-8-sig", errors="replace").strip()
        else:
            line = sys.stdin.readline()
            if line == "":
                return None
            line = line.strip()
        if not line or not line.startswith("{"):
            continue
        return json.loads(line)


def jsonrpc_error(request_id: Any, code: int, message: str) -> Dict[str, Any]:
    return {
        "jsonrpc": "2.0",
        "id": request_id,
        "error": {"code": code, "message": message},
    }


def jsonrpc_result(request_id: Any, result: Mapping[str, Any]) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def tool_result(payload: Mapping[str, Any], is_error: bool = False) -> Dict[str, Any]:
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    return {
        "content": [{"type": "text", "text": text}],
        "structuredContent": payload,
        "isError": is_error,
    }


def as_bool(value: Any, name: str) -> bool:
    if value is None:
        return False
    if isinstance(value, bool):
        return value
    if isinstance(value, str) and value.lower() in ("true", "false", "1", "0", "yes", "no"):
        return value.lower() in ("true", "1", "yes")
    raise ValueError("%s must be a boolean" % name)


def as_opt_str(value: Any, name: str) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, bool) or isinstance(value, (dict, list)):
        raise ValueError("%s must be a string" % name)
    text = str(value)
    if "\n" in text or "\r" in text:
        raise ValueError("%s must not contain newlines" % name)
    return text


def unknown_keys(arguments: Mapping[str, Any], allowed: Sequence[str]) -> List[str]:
    allowed_set = set(allowed)
    return sorted(key for key in arguments if key not in allowed_set)


def build_argv(command: str, flag_map: Mapping[str, str], arguments: Mapping[str, Any]) -> List[str]:
    argv = [command]
    for key, flag in flag_map.items():
        if key not in arguments or arguments[key] in (None, ""):
            continue
        value = arguments[key]
        if isinstance(value, bool):
            raise ValueError("%s must not be a boolean" % key)
        argv.extend([flag, as_opt_str(value, key) or ""])
    if as_bool(arguments.get("unsafe"), "unsafe"):
        argv.append("--unsafe")
    if as_bool(arguments.get("dry_run"), "dry_run"):
        argv.append("--dry-run")
    return argv


def invoke_orch(argv: Sequence[str]) -> Dict[str, Any]:
    command = ["bash", orch_bin()]
    command.extend(argv)
    try:
        # Close stdin so adapter version probes cannot consume MCP JSON-RPC.
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdin=subprocess.DEVNULL,
        )
    except OSError as exc:
        return {
            "schema": SCHEMA,
            "source": "bin/orch",
            "ok": False,
            "exit_code": 127,
            "command": argv[0] if argv else "",
            "orch_argv": list(argv),
            "error": "failed to invoke orch: %s" % exc,
            "completion_policy": COMPLETION_POLICY,
        }
    return {
        "ok": completed.returncode == 0,
        "exit_code": completed.returncode,
        "cli_stdout": completed.stdout,
        "cli_stderr": completed.stderr,
        "orch_argv": list(argv),
    }


def parse_cli_summary(stdout: str) -> Dict[str, Any]:
    parsed: Dict[str, Any] = {}
    for line in stdout.splitlines():
        if line == "DRY RUN":
            parsed["dry_run"] = True
            continue
        if ": " not in line:
            continue
        key, _, value = line.partition(": ")
        mapped = SUMMARY_KEYS.get(key.strip())
        if mapped is None:
            continue
        parsed[mapped] = coerce_scalar(value)
    return parsed


def coerce_scalar(value: str) -> Any:
    if value in ("true", "false"):
        return value == "true"
    if value.isdigit():
        return int(value)
    return value


def parse_doctor(stdout: str) -> Dict[str, Any]:
    adapters = []
    detected = None
    supported = None
    for line in stdout.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("ADAPTER") or stripped.startswith("-------"):
            continue
        if stripped.startswith("Detected "):
            parts = stripped.split()
            if len(parts) >= 4:
                try:
                    detected = int(parts[1])
                    supported = int(parts[3])
                except ValueError:
                    pass
            continue
        fields = stripped.split(None, 3)
        if len(fields) < 3:
            continue
        version: Optional[str] = fields[3] if len(fields) > 3 else None
        if version == "-":
            version = None
        adapters.append(
            {
                "name": fields[0],
                "status": fields[1],
                "command": fields[2],
                "version": version,
            }
        )
    return {"adapters": adapters, "detected": detected, "supported": supported}


def read_kv_data(path: str) -> Dict[str, str]:
    data: Dict[str, str] = {}
    if os.path.islink(path) or not os.path.isfile(path):
        return data
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.rstrip("\n\r")
            if not line or "=" not in line:
                continue
            key, _, value = line.partition("=")
            if not key or any(char in key for char in " \t$`()"):
                continue
            data[key] = "<redacted>" if SECRET_KEY_RE.search(key) else value
    return data


def existing_paths(directory: str, nested_iterations: bool = True) -> Dict[str, Any]:
    ledger: Dict[str, Any] = {"dir": directory}
    for key, name in LEDGER_FILES:
        path = os.path.join(directory, name)
        if os.path.isfile(path) and not os.path.islink(path):
            ledger[key] = path
    if not nested_iterations:
        return ledger
    iterations = []
    try:
        names = sorted(os.listdir(directory))
    except OSError:
        names = []
    for name in names:
        if not name.startswith("iteration-"):
            continue
        child = os.path.join(directory, name)
        if not os.path.isdir(child) or os.path.islink(child):
            continue
        suffix = name.split("-", 1)[1]
        entry = existing_paths(child, nested_iterations=False)
        try:
            entry["index"] = int(suffix)
        except ValueError:
            entry["index"] = suffix
        iterations.append(entry)
    if iterations:
        ledger["iterations"] = iterations
    evidence = []
    for name in names:
        if "-verification" not in name:
            continue
        child = os.path.join(directory, name)
        if not os.path.isdir(child) or os.path.islink(child):
            continue
        evidence.append(existing_paths(child, nested_iterations=False))
    if evidence:
        ledger["evidence"] = evidence
    return ledger


def run_id_from(path: Optional[str]) -> Optional[str]:
    if not path:
        return None
    return os.path.basename(os.path.normpath(path))


def envelope(command: str, invoked: Mapping[str, Any], extra: Mapping[str, Any]) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "schema": SCHEMA,
        "source": "bin/orch",
        "command": command,
        "ok": invoked.get("ok"),
        "exit_code": invoked.get("exit_code"),
        "orch_argv": invoked.get("orch_argv", []),
        "completion_policy": COMPLETION_POLICY,
        "prose_is_not_done": True,
    }
    if invoked.get("error"):
        payload["error"] = invoked["error"]
    payload.update(extra)
    return payload


def attach_ledger(payload: Dict[str, Any], run_dir: Optional[str], evidence_dir: Optional[str] = None) -> None:
    if run_dir:
        payload["run_dir"] = run_dir
        payload["run_id"] = run_id_from(run_dir)
        payload["ledger"] = existing_paths(run_dir)
        meta_path = os.path.join(run_dir, "meta.env")
        summary_path = os.path.join(run_dir, "summary.env")
        meta = read_kv_data(meta_path)
        summary = read_kv_data(summary_path)
        if meta:
            payload["meta"] = meta
        if summary:
            payload["summary"] = summary
    if evidence_dir:
        payload["evidence_dir"] = evidence_dir
        payload["evidence_id"] = run_id_from(evidence_dir)
        payload["verification"] = read_kv_data(os.path.join(evidence_dir, "verify.env"))
        payload["evidence"] = existing_paths(evidence_dir, nested_iterations=False)


def handle_doctor(_arguments: Mapping[str, Any]) -> Tuple[Dict[str, Any], bool]:
    invoked = invoke_orch(["doctor"])
    extra = parse_doctor(invoked.get("cli_stdout", ""))
    payload = envelope("doctor", invoked, extra)
    return payload, False


def handle_run(arguments: Mapping[str, Any]) -> Tuple[Dict[str, Any], bool]:
    unknown = unknown_keys(arguments, list(RUN_ARGS) + ["unsafe", "dry_run"])
    if unknown:
        return error_payload("run", "unknown orch_run argument: %s" % ", ".join(unknown)), True
    argv = build_argv("run", RUN_ARGS, arguments)
    invoked = invoke_orch(argv)
    extra = parse_cli_summary(invoked.get("cli_stdout", ""))
    if extra.get("status") == "verified":
        extra["status"] = "unverified"
        extra["status_note"] = "orch run cannot record verified; only an external gate can."
    payload = envelope("run", invoked, extra)
    attach_ledger(payload, extra.get("run_dir") if isinstance(extra.get("run_dir"), str) else None)
    return payload, False


def handle_loop(arguments: Mapping[str, Any]) -> Tuple[Dict[str, Any], bool]:
    unknown = unknown_keys(arguments, list(LOOP_ARGS) + ["unsafe", "dry_run"])
    if unknown:
        return error_payload("loop", "unknown orch_loop argument: %s" % ", ".join(unknown)), True
    argv = build_argv("loop", LOOP_ARGS, arguments)
    invoked = invoke_orch(argv)
    extra = parse_cli_summary(invoked.get("cli_stdout", ""))
    payload = envelope("loop", invoked, extra)
    attach_ledger(payload, extra.get("run_dir") if isinstance(extra.get("run_dir"), str) else None)
    return payload, False


def handle_verify(arguments: Mapping[str, Any]) -> Tuple[Dict[str, Any], bool]:
    unknown = unknown_keys(arguments, list(VERIFY_ARGS) + ["dry_run"])
    if unknown:
        return error_payload("verify", "unknown orch_verify argument: %s" % ", ".join(unknown)), True
    argv = build_argv("verify", VERIFY_ARGS, arguments)
    invoked = invoke_orch(argv)
    extra = parse_cli_summary(invoked.get("cli_stdout", ""))
    payload = envelope("verify", invoked, extra)
    run_dir = extra.get("run_dir") if isinstance(extra.get("run_dir"), str) else None
    evidence_dir = extra.get("evidence_dir") if isinstance(extra.get("evidence_dir"), str) else None
    attach_ledger(payload, run_dir, evidence_dir)
    return payload, False


def error_payload(command: str, message: str) -> Dict[str, Any]:
    return {
        "schema": SCHEMA,
        "source": "bin/orch",
        "command": command,
        "ok": False,
        "exit_code": 2,
        "error": message,
        "completion_policy": COMPLETION_POLICY,
        "prose_is_not_done": True,
    }


TOOLS = {
    "orch_doctor": {
        "description": (
            "Probe supported coding-agent CLIs via `orch doctor`. "
            "This is an availability probe, not completion evidence."
        ),
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        "handler": handle_doctor,
    },
    "orch_run": {
        "description": (
            "Execute one normalized goal via `orch run`. A zero provider exit is "
            "unverified. This tool never claims task completion; only orch_loop or "
            "orch_verify plus an external gate can produce verified."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "task": {"type": "string", "description": "Goal text. Mutually exclusive with task_file."},
                "task_file": {"type": "string", "description": "Path to a goal file. Mutually exclusive with task."},
                "cli": {
                    "type": "string",
                    "description": "auto, kiro, claude, codex, opencode, or hermes",
                },
                "workdir": {"type": "string"},
                "run_root": {"type": "string", "description": "Artifact root; defaults to the user state ledger."},
                "role": {"type": "string"},
                "timeout": {"type": "integer", "exclusiveMinimum": 0},
                "unsafe": {
                    "type": "boolean",
                    "default": False,
                    "description": "Explicit permission-bypass opt-in. Default false.",
                },
                "dry_run": {"type": "boolean", "default": False},
            },
            "additionalProperties": False,
        },
        "handler": handle_run,
    },
    "orch_loop": {
        "description": (
            "Iterate via `orch loop` until the operator-supplied verify command exits 0 "
            "or the attempt budget is exhausted. Model prose is not done."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "task": {"type": "string"},
                "task_file": {"type": "string"},
                "verify": {
                    "type": "string",
                    "description": "External evidence gate. Exit 0 means pass. Required.",
                },
                "cli": {"type": "string"},
                "workdir": {"type": "string"},
                "run_root": {"type": "string"},
                "role": {"type": "string"},
                "timeout": {"type": "integer", "exclusiveMinimum": 0},
                "verify_timeout": {"type": "integer", "exclusiveMinimum": 0},
                "max_iterations": {"type": "integer", "exclusiveMinimum": 0},
                "unsafe": {"type": "boolean", "default": False},
                "dry_run": {"type": "boolean", "default": False},
            },
            "required": ["verify"],
            "additionalProperties": False,
        },
        "handler": handle_loop,
    },
    "orch_verify": {
        "description": (
            "Re-run a deterministic evidence command via `orch verify` against a marked "
            "orchestrator run directory. Append-only; does not overwrite prior evidence."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "run": {"type": "string", "description": "Existing orchestrator run directory."},
                "verify": {"type": "string", "description": "External evidence gate. Exit 0 means pass."},
                "workdir": {"type": "string"},
                "timeout": {"type": "integer", "exclusiveMinimum": 0},
                "dry_run": {"type": "boolean", "default": False},
            },
            "required": ["run", "verify"],
            "additionalProperties": False,
        },
        "handler": handle_verify,
    },
}


def tools_list() -> List[Dict[str, Any]]:
    listed = []
    for name, spec in TOOLS.items():
        listed.append(
            {
                "name": name,
                "description": spec["description"],
                "inputSchema": spec["inputSchema"],
            }
        )
    return listed


def payload_is_error(payload: Mapping[str, Any], flagged: bool) -> bool:
    if flagged:
        return True
    if payload.get("ok") is False:
        return True
    exit_code = payload.get("exit_code")
    return isinstance(exit_code, int) and exit_code != 0


def call_tool(name: str, arguments: Mapping[str, Any]) -> Dict[str, Any]:
    spec = TOOLS.get(name)
    if spec is None:
        return tool_result(
            error_payload("unknown", "unknown tool: %s" % name),
            is_error=True,
        )
    try:
        payload, is_error = spec["handler"](arguments)
    except ValueError as exc:
        return tool_result(error_payload(name.replace("orch_", "", 1), str(exc)), is_error=True)
    return tool_result(payload, is_error=payload_is_error(payload, is_error))


def handle_request(message: Mapping[str, Any]) -> Optional[Dict[str, Any]]:
    if message.get("jsonrpc") != "2.0":
        return jsonrpc_error(message.get("id"), -32600, "invalid JSON-RPC version")
    method = message.get("method")
    request_id = message.get("id")
    params = message.get("params") or {}
    if not isinstance(method, str):
        return jsonrpc_error(request_id, -32600, "method is required")
    if method.startswith("notifications/") or request_id is None:
        return None
    if method == "initialize":
        requested = ""
        if isinstance(params, dict):
            requested = str(params.get("protocolVersion") or "")
        protocol = requested if requested in PROTOCOL_VERSIONS else DEFAULT_PROTOCOL_VERSION
        return jsonrpc_result(
            request_id,
            {
                "protocolVersion": protocol,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                "instructions": (
                    "Thin MCP wrapper over ./bin/orch doctor|run|loop|verify. "
                    + COMPLETION_POLICY
                ),
            },
        )
    if method == "ping":
        return jsonrpc_result(request_id, {})
    if method == "tools/list":
        return jsonrpc_result(request_id, {"tools": tools_list()})
    if method == "tools/call":
        if not isinstance(params, dict):
            return jsonrpc_error(request_id, -32602, "tools/call params must be an object")
        name = params.get("name")
        arguments = params.get("arguments") or {}
        if not isinstance(name, str) or not isinstance(arguments, dict):
            return jsonrpc_error(request_id, -32602, "tools/call requires name and object arguments")
        return jsonrpc_result(request_id, call_tool(name, arguments))
    if method in ("shutdown", "exit"):
        return jsonrpc_result(request_id, {})
    return jsonrpc_error(request_id, -32601, "method not found: %s" % method)


def serve_stdio() -> int:
    while True:
        try:
            message = read_message()
        except json.JSONDecodeError:
            write_message(jsonrpc_error(None, -32700, "parse error"))
            continue
        if message is None:
            return 0
        if not isinstance(message, dict):
            write_message(jsonrpc_error(None, -32600, "invalid request"))
            continue
        try:
            response = handle_request(message)
        except Exception as exc:
            write_message(jsonrpc_error(message.get("id"), -32603, "internal error: %s" % exc))
            continue
        if response is not None:
            write_message(response)
        if isinstance(message, dict) and message.get("method") in ("shutdown", "exit") and "id" in message:
            return 0


def main(argv: Sequence[str]) -> int:
    configure_stdio()
    if argv and argv[0] in ("-h", "--help"):
        sys.stdout.write(HELP)
        return 0
    return serve_stdio()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
