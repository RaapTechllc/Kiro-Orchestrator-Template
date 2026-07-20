#!/usr/bin/env bash
set -u

seconds=${1:-}
marker=${2:-}
shift 2 || true

case "$seconds" in
  ''|*[!0-9]*) printf 'timeout: seconds must be a positive integer\n' >&2; exit 2 ;;
esac
[ "$seconds" -gt 0 ] || { printf 'timeout: seconds must be greater than zero\n' >&2; exit 2; }
[ "$#" -gt 0 ] || { printf 'timeout: command is required\n' >&2; exit 2; }

child_pid=''
watchdog_pid=''

signal_child_group() {
  signal=$1
  [ -n "$child_pid" ] || return 0
  kill "-$signal" -- "-$child_pid" 2>/dev/null || \
    kill "-$signal" "$child_pid" 2>/dev/null || true
}

# Invoked indirectly by the INT/TERM/HUP traps below.
# shellcheck disable=SC2317,SC2329
handle_signal() {
  signal_exit_code=$1
  [ -z "$watchdog_pid" ] || kill "$watchdog_pid" 2>/dev/null || true
  signal_child_group TERM
  sleep 1
  signal_child_group KILL
  [ -z "$child_pid" ] || wait "$child_pid" 2>/dev/null || true
  [ -z "$watchdog_pid" ] || wait "$watchdog_pid" 2>/dev/null || true
  trap - INT TERM HUP
  exit "$signal_exit_code"
}
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM
trap 'handle_signal 129' HUP

rm -f "$marker"
# Job control gives the provider its own process group on Bash platforms that do
# not ship `setsid` (notably Git Bash). Descendants inherit that group.
set -m
"$@" &
child_pid=$!
set +m
(
  sleep "$seconds"
  if kill -0 "$child_pid" 2>/dev/null; then
    printf 'timed_out_after_seconds=%s\n' "$seconds" > "$marker"
    signal_child_group TERM
    sleep 1
    signal_child_group KILL
  fi
) &
watchdog_pid=$!

wait "$child_pid" 2>/dev/null
exit_code=$?
kill "$watchdog_pid" 2>/dev/null || true
wait "$watchdog_pid" 2>/dev/null || true
trap - INT TERM HUP

if [ -f "$marker" ]; then
  exit 124
fi
exit "$exit_code"
