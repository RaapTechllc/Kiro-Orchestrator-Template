#!/usr/bin/env bash
# shellcheck disable=SC2034 # exported configuration consumed by bin/orch after sourcing

ORCH_ADAPTERS='kiro claude codex opencode hermes'
ORCH_CLI_PRIORITY_DEFAULT='kiro,claude,codex,opencode,hermes'
ORCH_ADAPTER_COUNT=5

say_error() {
  printf 'orch: %s\n' "$*" >&2
}

die() {
  say_error "$*"
  exit 2
}

require_single_line() {
  field_name=$1
  field_value=$2
  case "$field_value" in
    *$'\n'*|*$'\r'*) die "$field_name must not contain newlines" ;;
  esac
}

canonical_dir() {
  canonical_input=$1
  (cd "$canonical_input" && pwd -P)
}

first_line() {
  IFS= read -r line || true
  printf '%s\n' "${line:-}"
}

adapter_path() {
  printf '%s/lib/orch/adapters/%s.sh\n' "$ORCH_ROOT" "$1"
}

adapter_call() {
  adapter=$1
  shift
  path=$(adapter_path "$adapter")
  [ -x "$path" ] || die "adapter is not executable: $adapter"
  "$path" "$@"
}

adapter_command() {
  case "$1" in
    kiro) printf '%s\n' 'kiro-cli' ;;
    claude) printf '%s\n' 'claude' ;;
    codex) printf '%s\n' 'codex' ;;
    opencode) printf '%s\n' 'opencode' ;;
    hermes) printf '%s\n' 'hermes' ;;
    *) die "unsupported adapter: $1" ;;
  esac
}

is_supported_adapter() {
  case "$1" in
    kiro|claude|codex|opencode|hermes) return 0 ;;
    *) return 1 ;;
  esac
}

select_adapter() {
  requested=$1
  if [ "$requested" != auto ]; then
    is_supported_adapter "$requested" || die "unsupported adapter: $requested"
    adapter_call "$requested" available >/dev/null 2>&1 || die "adapter is not available: $requested"
    printf '%s\n' "$requested"
    return
  fi

  priority=${ORCH_CLI_PRIORITY:-$ORCH_CLI_PRIORITY_DEFAULT}
  old_ifs=$IFS
  IFS=','
  # shellcheck disable=SC2086 # comma-split operator configuration is intentional
  set -- $priority
  IFS=$old_ifs
  for candidate in "$@"; do
    candidate=$(printf '%s' "$candidate" | tr -d ' ')
    [ -n "$candidate" ] || continue
    is_supported_adapter "$candidate" || continue
    if adapter_call "$candidate" available >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  die 'no supported CLI is available; run orch doctor'
}

utc_now() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

new_run_dir() {
  root=$1
  prefix=${2:-run}
  mkdir -p "$root" || return 1
  root=$(cd "$root" && pwd -P) || return 1
  run_id=$(date -u '+%Y%m%dT%H%M%SZ')-$$-$prefix
  suffix=0
  while :; do
    if [ "$suffix" -eq 0 ]; then
      candidate="$root/$run_id"
    else
      candidate="$root/$run_id-$suffix"
    fi
    if mkdir "$candidate" 2>/dev/null; then
      {
        printf 'schema=1\n'
        printf 'type=%s\n' "$prefix"
      } > "$candidate/.orch-run" || {
        rmdir "$candidate" 2>/dev/null || true
        return 1
      }
      printf '%s\n' "$candidate"
      return 0
    fi
    if [ ! -e "$candidate" ]; then
      say_error "cannot create run directory: $candidate"
      return 1
    fi
    suffix=$((suffix + 1))
  done
}

write_goal_prompt() {
  destination=$1
  goal_task=$2
  goal_workdir=$3
  goal_role=$4
  goal_unsafe=$5
  goal_iteration=${6:-1}
  feedback_file=${7:-}

  {
    printf '# Goal Contract\n\n'
    printf -- '- Role: %s\n' "${goal_role:-general coding agent}"
    printf -- '- Working directory: %s\n' "$goal_workdir"
    printf -- '- Iteration: %s\n' "$goal_iteration"
    printf -- '- Unsafe permission bypass requested: %s\n' "$goal_unsafe"
    printf '\n## Task\n\n%s\n' "$goal_task"
    printf '\n## Completion policy\n\n'
    printf '%s\n' 'Completion requires external evidence from the orchestrator. Do not claim success from prose alone.'
    printf '%s\n' 'Make the smallest correct change, run relevant checks, and report concrete files and command results.'
    if [ -n "$feedback_file" ] && [ -f "$feedback_file" ]; then
      printf '\n## Evidence from the previous iteration\n\n```text\n'
      cat "$feedback_file"
      printf '\n```\n'
    fi
  } > "$destination"
}

write_run_meta() {
  destination=$1
  meta_adapter=$2
  meta_command=$3
  meta_workdir=$4
  meta_role=$5
  meta_unsafe=$6
  meta_started=$7
  meta_finished=$8
  meta_exit_code=$9
  shift 9
  meta_status=$1

  {
    printf 'adapter=%s\n' "$meta_adapter"
    printf 'command=%s\n' "$meta_command"
    printf 'workdir=%s\n' "$meta_workdir"
    printf 'role=%s\n' "${meta_role:-default}"
    printf 'unsafe=%s\n' "$meta_unsafe"
    printf 'started_at=%s\n' "$meta_started"
    printf 'finished_at=%s\n' "$meta_finished"
    printf 'exit_code=%s\n' "$meta_exit_code"
    printf 'status=%s\n' "$meta_status"
  } > "$destination"
}

run_adapter_with_timeout() {
  timeout_adapter=$1
  timeout_seconds=$2
  timeout_marker=$3
  shift 3
  "$ORCH_ROOT/lib/orch/timeout.sh" "$timeout_seconds" "$timeout_marker" \
    bash "$(adapter_path "$timeout_adapter")" run "$@"
}

run_verification() {
  verification_dir=$1
  verification_workdir=$2
  verification_command=$3
  verification_timeout=$4
  verification_started=$(utc_now)

  (
    cd "$verification_workdir" || exit 2
    ORCH_RUN_DIR="$verification_dir" \
      ORCH_WORKDIR="$verification_workdir" \
      "$ORCH_ROOT/lib/orch/timeout.sh" "$verification_timeout" "$verification_dir/verify.timeout" \
      bash -c "$verification_command"
  ) > "$verification_dir/verify.stdout.log" 2> "$verification_dir/verify.stderr.log"
  verification_exit_code=$?
  verification_finished=$(utc_now)
  if [ "$verification_exit_code" -eq 0 ]; then
    verification_status=passed
  elif [ "$verification_exit_code" -eq 124 ] && [ -f "$verification_dir/verify.timeout" ]; then
    verification_status=timed_out
  else
    verification_status=failed
  fi
  printf '%s\n' "$verification_command" > "$verification_dir/verify.command"
  {
    printf 'command_file=verify.command\n'
    printf 'started_at=%s\n' "$verification_started"
    printf 'finished_at=%s\n' "$verification_finished"
    printf 'exit_code=%s\n' "$verification_exit_code"
    printf 'status=%s\n' "$verification_status"
  } > "$verification_dir/verify.env"
  return "$verification_exit_code"
}

write_feedback() {
  feedback_destination=$1
  feedback_provider_exit=$2
  feedback_dir=$3
  {
    printf 'Provider exit code: %s\n' "$feedback_provider_exit"
    printf 'Evidence mode: tail excerpts (80 lines per log)\n'
    printf 'Full provider stdout: %s/stdout.log\n' "$feedback_dir"
    printf 'Full provider stderr: %s/stderr.log\n' "$feedback_dir"
    printf 'Full verification stdout: %s/verify.stdout.log\n' "$feedback_dir"
    printf 'Full verification stderr: %s/verify.stderr.log\n' "$feedback_dir"
    printf '\nProvider stdout (last 80 lines):\n'
    tail -n 80 "$feedback_dir/stdout.log" 2>/dev/null || true
    printf '\nProvider stderr (last 80 lines):\n'
    tail -n 80 "$feedback_dir/stderr.log" 2>/dev/null || true
    printf '\nVerification stdout (last 80 lines):\n'
    tail -n 80 "$feedback_dir/verify.stdout.log" 2>/dev/null || true
    printf '\nVerification stderr (last 80 lines):\n'
    tail -n 80 "$feedback_dir/verify.stderr.log" 2>/dev/null || true
  } > "$feedback_destination"
}
