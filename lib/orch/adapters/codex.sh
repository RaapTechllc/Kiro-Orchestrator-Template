#!/usr/bin/env bash
set -u

run_adapter() {
  prompt_file=$1
  workdir=$2
  _role=$3
  unsafe=$4
  codex_workdir=$workdir
  case $(uname -s 2>/dev/null || true) in
    CYGWIN*|MINGW*|MSYS*)
      command -v cygpath >/dev/null 2>&1 && codex_workdir=$(cygpath -w "$workdir")
      ;;
  esac
  if [ "$unsafe" = true ]; then
    args=(exec --json --dangerously-bypass-approvals-and-sandbox -C "$codex_workdir" --color never -)
  else
    args=(exec --json --sandbox workspace-write -C "$codex_workdir" --color never -)
  fi
  exec codex "${args[@]}" < "$prompt_file"
}

case "${1:-}" in
  available) command -v codex >/dev/null 2>&1 ;;
  version) codex --version ;;
  run) shift; run_adapter "$@" ;;
  *) exit 2 ;;
esac
