#!/usr/bin/env bash
set -u

run_adapter() {
  prompt_file=$1
  workdir=$2
  role=$3
  unsafe=$4
  prompt=$(<"$prompt_file")
  args=(chat --no-interactive)
  [ -n "$role" ] && args+=(--agent "$role")
  if [ "$unsafe" = true ]; then
    args+=(--trust-all-tools)
  else
    args+=("--trust-tools=read,write,grep,glob")
  fi
  args+=("$prompt")
  cd "$workdir" || exit 2
  exec kiro-cli "${args[@]}"
}

case "${1:-}" in
  available) command -v kiro-cli >/dev/null 2>&1 ;;
  version) kiro-cli --version ;;
  run) shift; run_adapter "$@" ;;
  *) exit 2 ;;
esac
