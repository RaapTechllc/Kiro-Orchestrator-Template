#!/usr/bin/env bash
set -u

run_adapter() {
  prompt_file=$1
  workdir=$2
  role=$3
  unsafe=$4
  prompt=$(<"$prompt_file")
  args=(run --format json)
  if [ "$unsafe" = true ]; then
    [ -n "$role" ] && args+=(--agent "$role")
    args+=(--dangerously-skip-permissions)
  else
    export OPENCODE_PERMISSION='{"*":"deny","read":"allow","edit":"allow","glob":"allow","grep":"allow","list":"allow"}'
  fi
  args+=("$prompt")
  cd "$workdir" || exit 2
  exec opencode "${args[@]}"
}

case "${1:-}" in
  available) command -v opencode >/dev/null 2>&1 ;;
  version) opencode --version ;;
  run) shift; run_adapter "$@" ;;
  *) exit 2 ;;
esac
