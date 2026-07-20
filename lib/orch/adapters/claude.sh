#!/usr/bin/env bash
set -u

run_adapter() {
  prompt_file=$1
  workdir=$2
  role=$3
  unsafe=$4
  if [ "$unsafe" = true ]; then
    args=(-p --output-format json --dangerously-skip-permissions)
  else
    args=(-p --output-format json --permission-mode dontAsk)
    args+=(--allowedTools Read Edit Write Glob Grep)
  fi
  [ -n "$role" ] && args+=(--agent "$role")
  cd "$workdir" || exit 2
  exec claude "${args[@]}" < "$prompt_file"
}

case "${1:-}" in
  available) command -v claude >/dev/null 2>&1 ;;
  version) claude --version ;;
  run) shift; run_adapter "$@" ;;
  *) exit 2 ;;
esac
