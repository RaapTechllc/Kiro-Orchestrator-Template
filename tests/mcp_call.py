#!/usr/bin/env python3
"""Contract-test helper: call one orch MCP tool and print structured JSON."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any, Dict, List


def repo_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def orch_mcp_cmd() -> List[str]:
    return ["bash", os.path.join(repo_root(), "bin", "orch"), "mcp"]


class McpClient:
    def __init__(self) -> None:
        self.proc = subprocess.Popen(
            orch_mcp_cmd(),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        assert self.proc.stdin is not None
        assert self.proc.stdout is not None

    def send(self, message: Dict[str, Any]) -> None:
        assert self.proc.stdin is not None
        self.proc.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
        self.proc.stdin.flush()

    def recv(self) -> Dict[str, Any]:
        assert self.proc.stdout is not None
        line = self.proc.stdout.readline()
        if line == "":
            stderr = self.proc.stderr.read() if self.proc.stderr else ""
            raise RuntimeError("MCP server closed stdout early: %s" % stderr)
        return json.loads(line)

    def close(self) -> str:
        if self.proc.stdin:
            self.proc.stdin.close()
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            self.proc.wait()
        stderr = ""
        if self.proc.stderr:
            stderr = self.proc.stderr.read()
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
        sys.stdout.write("Usage: mcp_call.py [--list|--initialize] TOOL [JSON_ARGS]\n")
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
