#!/usr/bin/env bash
set -u

run_adapter() {
  prompt_file=$1
  workdir=$2
  _role=$3
  unsafe=$4
  prompt=$(<"$prompt_file")
  args=(chat --quiet)
  [ "$unsafe" = true ] && args+=(--yolo)
  args+=(--query "$prompt")
  cd "$workdir" || exit 2
  exec hermes "${args[@]}"
}

case "${1:-}" in
  available) command -v hermes >/dev/null 2>&1 ;;
  version) hermes --version ;;
  run) shift; run_adapter "$@" ;;
  *) exit 2 ;;
esac
