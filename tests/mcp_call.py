#!/usr/bin/env python3
"""Contract-test helper: call one orch MCP tool and print structured JSON."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any, Callable, Dict, List, Union

Readline = Callable[[], Union[bytes, str]]


def repo_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _is_wsl_bash(path: str) -> bool:
    normalized = path.replace("/", "\\").lower()
    return normalized.endswith(r"\system32\bash.exe") or normalized.endswith(r"\sysnative\bash.exe")


def _git_bash() -> str:
    roots = [
        os.environ.get("ProgramFiles", r"C:\Program Files"),
        os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"),
    ]
    for root in roots:
        candidate = os.path.join(root, "Git", "bin", "bash.exe")
        if os.path.isfile(candidate):
            return candidate
    return ""


def orch_mcp_cmd() -> List[str]:
    orch = os.path.join(repo_root(), "bin", "orch")
    bash = os.environ.get("ORCH_BASH") or ""
    if sys.platform == "win32":
        if not bash or _is_wsl_bash(bash):
            bash = _git_bash()
        if bash and not _is_wsl_bash(bash):
            return [bash, orch, "mcp"]
        # Last resort: talk to the same Python server orch mcp would exec.
        return [sys.executable, "-u", os.path.join(repo_root(), "lib", "orch", "mcp_server.py")]
    return [bash or "bash", orch, "mcp"]


def next_jsonrpc_line(readline: Readline) -> Dict[str, Any]:
    skipped = []
    while True:
        raw = readline()
        if raw in ("", b""):
            raise RuntimeError(
                "MCP server closed stdout early; skipped non-JSON lines=%s" % skipped
            )
        if isinstance(raw, bytes):
            line = raw.decode("utf-8-sig", errors="replace").strip()
        else:
            line = raw.strip()
        if not line:
            skipped.append("<blank>")
            continue
        if not line.startswith("{"):
            skipped.append(line[:80])
            continue
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError as exc:
            raise RuntimeError("invalid MCP JSON line %r: %s" % (line[:200], exc)) from exc
        if not isinstance(parsed, dict):
            skipped.append(line[:80])
            continue
        return parsed


class McpClient:
    def __init__(self) -> None:
        env = os.environ.copy()
        env.setdefault("ORCH_PYTHON", sys.executable)
        env["PYTHONIOENCODING"] = "utf-8"
        env["PYTHONUTF8"] = "1"
        env["PYTHONUNBUFFERED"] = "1"
        self.proc = subprocess.Popen(
            orch_mcp_cmd(),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
        assert self.proc.stdin is not None
        assert self.proc.stdout is not None

    def send(self, message: Dict[str, Any]) -> None:
        assert self.proc.stdin is not None
        raw = (json.dumps(message, separators=(",", ":"), ensure_ascii=True) + "\n").encode("utf-8")
        self.proc.stdin.write(raw)
        self.proc.stdin.flush()

    def recv(self) -> Dict[str, Any]:
        assert self.proc.stdout is not None
        try:
            return next_jsonrpc_line(self.proc.stdout.readline)
        except RuntimeError as exc:
            stderr = b""
            if self.proc.stderr:
                stderr = self.proc.stderr.read() or b""
            detail = stderr.decode("utf-8", errors="replace")
            raise RuntimeError("%s; stderr=%s" % (exc, detail)) from exc

    def close(self) -> str:
        if self.proc.stdin:
            try:
                self.proc.stdin.close()
            except OSError:
                pass
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            self.proc.wait()
        stderr = ""
        if self.proc.stderr:
            raw = self.proc.stderr.read() or b""
            stderr = raw.decode("utf-8", errors="replace")
        return stderr

    def initialize(self) -> Dict[str, Any]:
        self.send(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "orch-contract-test", "version": "0"},
                },
            }
        )
        result = self.recv()
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        return result

    def call(self, name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        self.send(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {"name": name, "arguments": arguments},
            }
        )
        return self.recv()

    def list_tools(self) -> Dict[str, Any]:
        self.send({"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
        return self.recv()


def payload_from_call(response: Dict[str, Any]) -> Dict[str, Any]:
    result = response.get("result")
    if not isinstance(result, dict):
        raise RuntimeError("tools/call missing result: %s" % json.dumps(response))
    structured = result.get("structuredContent")
    if isinstance(structured, dict):
        return structured
    content = result.get("content") or []
    if content and isinstance(content[0], dict) and "text" in content[0]:
        return json.loads(content[0]["text"])
    raise RuntimeError("tools/call missing structured JSON: %s" % json.dumps(response))


def main(argv: List[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        sys.stdout.write("Usage: mcp_call.py [--list|--initialize|--raw] TOOL [JSON_ARGS]\n")
        return 0
    client = McpClient()
    try:
        initialize = client.initialize()
        if argv[0] == "--initialize":
            json.dump(initialize, sys.stdout, indent=2, sort_keys=True)
            sys.stdout.write("\n")
            return 0
        if argv[0] == "--list":
            response = client.list_tools()
            json.dump(response, sys.stdout, indent=2, sort_keys=True)
            sys.stdout.write("\n")
            return 0
        if argv[0] == "--raw":
            if len(argv) < 2:
                raise RuntimeError("--raw requires a tool name")
            tool = argv[1]
            arguments = json.loads(argv[2]) if len(argv) > 2 else {}
            if not isinstance(arguments, dict):
                raise RuntimeError("JSON_ARGS must be an object")
            response = client.call(tool, arguments)
            json.dump(response, sys.stdout, indent=2, sort_keys=True)
            sys.stdout.write("\n")
            return 0
        tool = argv[0]
        arguments = json.loads(argv[1]) if len(argv) > 1 else {}
        if not isinstance(arguments, dict):
            raise RuntimeError("JSON_ARGS must be an object")
        response = client.call(tool, arguments)
        payload = payload_from_call(response)
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0
    except Exception as exc:  # pragma: no cover - contract helper surfaces the error
        sys.stderr.write("%s\n" % exc)
        return 1
    finally:
        stderr = client.close()
        if stderr:
            sys.stderr.write(stderr)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
