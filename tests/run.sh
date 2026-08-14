#!/usr/bin/env bash
# shellcheck disable=SC2016 # stub bodies are intentionally passed as literal script text
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEST_PYTHON=$(command -v python3 2>/dev/null || true)
[ -n "$TEST_PYTHON" ] || TEST_PYTHON=$(command -v python 2>/dev/null || true)
# Windows Python's PATH prefers System32\bash.exe (WSL). Pin the Git Bash that
# is already running this suite so mcp_call does not get a UTF-16 WSL banner.
ORCH_BASH=$(command -v bash 2>/dev/null || true)
if command -v cygpath >/dev/null 2>&1 && [ -n "$ORCH_BASH" ]; then
  ORCH_BASH=$(cygpath -w "$ORCH_BASH")
fi
export ORCH_BASH
TEST_TMP_PARENT=${TEST_TMP:-${TMPDIR:-/tmp}}
mkdir -p "$TEST_TMP_PARENT"
TEST_TMP=$(mktemp -d "$TEST_TMP_PARENT/orch-tests.XXXXXX")
TEST_TMP=$(cd "$TEST_TMP" && pwd -P)
trap 'rm -rf "$TEST_TMP"' EXIT INT TERM
mkdir -p "$TEST_TMP/bin"

pass=0
fail=0

ok() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}

not_ok() {
  fail=$((fail + 1))
  printf 'not ok %d - %s\n' "$((pass + fail))" "$1" >&2
  return 1
}

assert_contains() {
  haystack=$1
  needle=$2
  label=$3
  case "$haystack" in
    *"$needle"*) return 0 ;;
    *) printf 'expected output to contain: %s\nactual output:\n%s\n' "$needle" "$haystack" >&2; not_ok "$label" ;;
  esac
}

assert_not_contains() {
  haystack=$1
  needle=$2
  label=$3
  case "$haystack" in
    *"$needle"*) printf 'expected output not to contain: %s\nactual output:\n%s\n' "$needle" "$haystack" >&2; not_ok "$label" ;;
    *) return 0 ;;
  esac
}

assert_file_contains() {
  file=$1
  needle=$2
  label=$3
  [ -f "$file" ] || { printf 'missing file: %s\n' "$file" >&2; not_ok "$label"; return; }
  content=$(<"$file")
  assert_contains "$content" "$needle" "$label"
}

make_stub() {
  name=$1
  body=$2
  stub="$TEST_TMP/bin/$name"
  printf '#!/usr/bin/env bash\n%s\n' "$body" > "$stub"
  chmod +x "$stub"
}

write_run_marker() {
  marker_dir=$1
  printf 'schema=1\ntype=test\n' > "$marker_dir/.orch-run"
}

python_bin() {
  if [ -n "${TEST_PYTHON:-}" ]; then
    printf '%s\n' "$TEST_PYTHON"
    return 0
  fi
  printf '%s\n' 'python3 is required for MCP tests' >&2
  return 1
}

mcp_call() {
  "$(python_bin)" "$ROOT/tests/mcp_call.py" "$@"
}

json_get() {
  json=$1
  path=$2
  printf '%s\n' "$json" | "$(python_bin)" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    cur = data
    for part in sys.argv[1].split("."):
        cur = cur[int(part)] if isinstance(cur, list) else cur[part]
    if isinstance(cur, (dict, list)):
        json.dump(cur, sys.stdout)
        sys.stdout.write("\n")
    elif cur is None:
        sys.stdout.write("\n")
    elif isinstance(cur, bool):
        sys.stdout.write("true\n" if cur else "false\n")
    else:
        sys.stdout.write(str(cur) + "\n")
except Exception:
    sys.stdout.write("\n")
' "$path"
}

json_argv_has() {
  json=$1
  needle=$2
  printf '%s\n' "$json" | "$(python_bin)" -c '
import json, sys
data = json.load(sys.stdin)
sys.exit(0 if sys.argv[1] in (data.get("orch_argv") or []) else 1)
' "$needle"
}

make_orch_proxy() {
  make_stub orch-proxy 'printf "ARGV:" >> "$ORCH_TEST_ARGV_LOG"
printf " <%s>" "$@" >> "$ORCH_TEST_ARGV_LOG"
printf "\n" >> "$ORCH_TEST_ARGV_LOG"
exec "$ORCH_REAL_BIN" "$@"'
}

mcp_path() {
  printf '%s\n' "$TEST_TMP/bin:$(dirname "$TEST_PYTHON"):/usr/bin:/bin"
}

test_doctor_reports_supported_adapters() {
  make_stub claude 'printf "stub-claude 1.0\\n"'
  output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" doctor 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'doctor exits successfully when one adapter is available'
    return
  }
  assert_contains "$output" 'kiro' 'doctor lists Kiro' || return
  assert_contains "$output" 'claude' 'doctor lists Claude Code' || return
  assert_contains "$output" 'codex' 'doctor lists Codex CLI' || return
  assert_contains "$output" 'opencode' 'doctor lists OpenCode' || return
  assert_contains "$output" 'hermes' 'doctor lists Hermes Agent' || return
  assert_contains "$output" 'claude      available' 'doctor marks detected adapter available' || return
  ok 'doctor reports all supported adapters'
}

test_doctor_reports_supported_adapters || true

test_dry_run_is_write_never() {
  call_log="$TEST_TMP/dry-run-calls.log"
  run_root="$TEST_TMP/dry-run-artifacts"
  make_stub claude 'printf "called\\n" >> "$ORCH_TEST_CALL_LOG"'

  output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" run \
      --cli auto \
      --task 'Create a file named should-not-exist' \
      --workdir "$TEST_TMP" \
      --run-root "$run_root" \
      --dry-run 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'dry-run exits successfully'
    return
  }

  [ ! -e "$call_log" ] || { not_ok 'dry-run does not invoke provider CLI'; return; }
  [ ! -e "$run_root" ] || { not_ok 'dry-run creates no run artifacts'; return; }
  assert_contains "$output" 'DRY RUN' 'dry-run labels output' || return
  assert_contains "$output" 'adapter: claude' 'auto selection chooses available adapter' || return
  assert_contains "$output" 'unsafe: false' 'dry-run reports safe permission posture' || return
  ok 'dry-run selects an adapter without writes or invocation'
}

test_dry_run_is_write_never || true

test_loop_and_verify_dry_runs_are_write_never() {
  call_log="$TEST_TMP/dry-run-loop-calls.log"
  loop_root="$TEST_TMP/dry-run-loop-artifacts"
  marked_run="$TEST_TMP/dry-run-marked-run"
  mkdir "$marked_run"
  write_run_marker "$marked_run"
  make_stub claude 'printf "called\\n" >> "$ORCH_TEST_CALL_LOG"'

  loop_output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" loop --cli claude --task 'Do not execute' --verify 'false' \
      --workdir "$TEST_TMP" --run-root "$loop_root" --dry-run 2>&1) || {
    not_ok 'loop dry-run exits successfully'
    return
  }
  verify_output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" verify \
    --run "$marked_run" --workdir "$TEST_TMP" --verify 'false' --dry-run 2>&1) || {
    not_ok 'verify dry-run exits successfully'
    return
  }
  [ ! -e "$call_log" ] || { not_ok 'loop dry-run does not invoke provider CLI'; return; }
  [ ! -e "$loop_root" ] || { not_ok 'loop dry-run creates no ledger'; return; }
  set -- "$marked_run"/*-verification*
  [ "$1" = "$marked_run/*-verification*" ] || { not_ok 'verify dry-run creates no evidence'; return; }
  assert_contains "$loop_output" 'DRY RUN' 'loop dry-run labels output' || return
  assert_contains "$verify_output" 'DRY RUN' 'verify dry-run labels output' || return
  ok 'loop and verify dry-runs invoke nothing and write no artifacts'
}

test_loop_and_verify_dry_runs_are_write_never || true

test_unsupported_provider_fails_before_writes() {
  run_root="$TEST_TMP/unsupported-provider-runs"

  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
    --cli not-a-cli \
    --task 'Must not run' \
    --workdir "$TEST_TMP" \
    --run-root "$run_root" 2>&1); then
    not_ok 'unsupported provider returns non-zero'
    return
  fi
  [ ! -e "$run_root" ] || { not_ok 'unsupported provider creates no run ledger'; return; }
  assert_contains "$output" 'unsupported adapter: not-a-cli' 'unsupported provider names the invalid adapter' || return
  ok 'run fails before writing when the selected provider is unsupported'
}

test_unsupported_provider_fails_before_writes || true

test_invalid_inputs_fail_before_provider_execution() {
  call_log="$TEST_TMP/invalid-input-provider.log"
  make_stub claude 'printf called > "$ORCH_TEST_CALL_LOG"'

  expect_input_failure() {
    expected=$1
    shift
    if output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" "$@" 2>&1); then
      not_ok "invalid input fails: $expected"
      return 1
    fi
    assert_contains "$output" "$expected" "invalid input explains: $expected"
  }

  expect_input_failure 'task file does not exist' run --cli claude --task-file "$TEST_TMP/missing-task.md" --workdir "$TEST_TMP" || return
  expect_input_failure 'workdir does not exist' run --cli claude --task x --workdir "$TEST_TMP/missing-workdir" || return
  expect_input_failure '--timeout must be greater than zero' run --cli claude --task x --timeout 0 --workdir "$TEST_TMP" || return
  expect_input_failure 'unknown run option' run --cli claude --task x --bogus --workdir "$TEST_TMP" || return
  expect_input_failure '--role must not contain newlines' run --cli claude --task x --role $'reviewer\nspoofed=1' --workdir "$TEST_TMP" || return
  [ ! -e "$call_log" ] || { not_ok 'invalid inputs never invoke a provider'; return; }
  ok 'malformed options, paths, budgets, and metadata fail before provider execution'
}

test_invalid_inputs_fail_before_provider_execution || true

test_run_root_failures_propagate() {
  make_stub claude 'exit 0'
  blocked_parent="$TEST_TMP/run-root-blocker"
  printf 'not a directory\n' > "$blocked_parent"

  if PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
    --cli claude --task 'Must not run' --workdir "$TEST_TMP" \
    --run-root "$blocked_parent/runs" >/dev/null 2>&1; then
    not_ok 'run propagates run-root creation failure'
    return
  fi
  if PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" loop \
    --cli claude --task 'Must not run' --verify 'true' --workdir "$TEST_TMP" \
    --run-root "$blocked_parent/runs" >/dev/null 2>&1; then
    not_ok 'loop propagates run-root creation failure'
    return
  fi
  ok 'run and loop fail closed when their ledger root cannot be created'
}

test_run_root_failures_propagate || true

test_default_run_root_is_outside_workspace_and_survives_adapter_chdir() {
  caller_dir="$TEST_TMP/relative-caller"
  workdir="$TEST_TMP/relative-provider-workdir"
  home_dir="$TEST_TMP/home"
  expected_run_root="$home_dir/.local/state/orch/runs"
  prompt_capture="$TEST_TMP/relative-prompt-capture"
  mkdir -p "$caller_dir" "$workdir" "$home_dir"
  make_stub claude 'cat > "$ORCH_TEST_PROMPT_CAPTURE"
printf "provider read prompt\\n"'

  output=$(cd "$caller_dir" && HOME="$home_dir" XDG_STATE_HOME='' \
    ORCH_TEST_PROMPT_CAPTURE="$prompt_capture" \
    PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
      --cli claude --task 'Read this after changing directories' --workdir "$workdir" 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'default relative run root remains readable after adapter chdir'
    return
  }
  assert_file_contains "$prompt_capture" 'Read this after changing directories' 'stdin adapter reads the normalized prompt after chdir' || return
  assert_contains "$output" "run: $expected_run_root/" 'run reports its external default ledger path' || return
  output=$(cd "$caller_dir" && HOME="$home_dir" XDG_STATE_HOME='' \
    PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" loop \
      --cli claude --task 'Keep loop evidence external' --verify true \
      --workdir "$workdir" 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'loop uses its external default ledger path'
    return
  }
  assert_contains "$output" "run: $expected_run_root/" 'loop reports its external default ledger path' || return
  [ ! -e "$caller_dir/.orchestrator" ] || { not_ok 'default run root stays outside the editable workspace'; return; }
  ok 'default run root stays outside the workspace and survives adapter chdir'
}

test_default_run_root_is_outside_workspace_and_survives_adapter_chdir || true

test_relative_codex_workdir_is_canonicalized_once() {
  caller_dir="$TEST_TMP/relative codex caller"
  workdir="$caller_dir/project dir"
  run_root="$caller_dir/run root"
  call_log="$TEST_TMP/relative-codex-call.log"
  prompt_capture="$TEST_TMP/relative-codex-prompt.log"
  mkdir -p "$workdir"
  make_stub codex 'printf "PWD=<%s>\\n" "$PWD" > "$ORCH_TEST_CALL_LOG"
printf "ARG=<%s>\\n" "$@" >> "$ORCH_TEST_CALL_LOG"
cat > "$ORCH_TEST_PROMPT_CAPTURE"'

  output=$(cd "$caller_dir" && ORCH_TEST_CALL_LOG="$call_log" ORCH_TEST_PROMPT_CAPTURE="$prompt_capture" \
    PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
      --cli codex --task $'Preserve line one.\nPreserve line two.' \
      --workdir 'project dir' --run-root 'run root' 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'Codex accepts a relative working directory with spaces'
    return
  }
  expected_codex_workdir=$workdir
  command -v cygpath >/dev/null 2>&1 && expected_codex_workdir=$(cygpath -w "$workdir")
  assert_file_contains "$call_log" "ARG=<$expected_codex_workdir>" 'Codex receives one canonical platform-native -C path' || return
  assert_file_contains "$call_log" "PWD=<$caller_dir>" 'Codex adapter does not pre-change into the relative workdir' || return
  assert_file_contains "$prompt_capture" 'Preserve line one.' 'Codex receives first prompt line on stdin' || return
  assert_file_contains "$prompt_capture" 'Preserve line two.' 'Codex receives second prompt line on stdin' || return
  set -- "$run_root"/*
  run_dir=$1
  assert_file_contains "$run_dir/meta.env" "workdir=$workdir" 'metadata records canonical working directory' || return
  ok 'relative Codex workdirs and multiline prompts are canonicalized and translated without double resolution'
}

test_relative_codex_workdir_is_canonicalized_once || true

test_run_executes_all_adapters_and_records_artifacts() {
  for adapter in kiro claude codex opencode hermes; do
    case "$adapter" in
      kiro) binary=kiro-cli ;;
      *) binary=$adapter ;;
    esac
    call_log="$TEST_TMP/$adapter-args.log"
    run_root="$TEST_TMP/$adapter-runs"
    injected="$TEST_TMP/injected-by-task"
    make_stub "$binary" 'printf "ARG=<%s>\\n" "$@" > "$ORCH_TEST_CALL_LOG"
printf "UMASK=<%s>\\n" "$(umask)" >> "$ORCH_TEST_CALL_LOG"
printf "OPENCODE_PERMISSION=<%s>\\n" "${OPENCODE_PERMISSION:-}" >> "$ORCH_TEST_CALL_LOG"
cat >/dev/null || true
printf "stub provider output\\n"'

    task="Review the repository; preserve literal \$(touch $injected)"
    output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
      "$ROOT/bin/orch" run \
        --cli "$adapter" \
        --task "$task" \
        --role reviewer \
        --workdir "$TEST_TMP" \
        --run-root "$run_root" 2>&1) || {
      printf '%s\n' "$output" >&2
      not_ok "$adapter adapter executes successfully"
      return
    }

    set -- "$run_root"/*
    run_dir=$1
    [ -d "$run_dir" ] || { not_ok "$adapter creates a run directory"; return; }
    [ ! -e "$injected" ] || { not_ok "$adapter passes task as data, not shell syntax"; return; }
    assert_file_contains "$run_dir/meta.env" "adapter=$adapter" "$adapter records selected adapter" || return
    assert_file_contains "$run_dir/meta.env" 'exit_code=0' "$adapter records exit code" || return
    assert_file_contains "$run_dir/meta.env" 'status=unverified' "$adapter never treats a zero process exit as task completion" || return
    assert_file_contains "$run_dir/prompt.md" 'Review the repository; preserve literal' "$adapter records normalized prompt" || return
    assert_file_contains "$run_dir/prompt.md" 'Completion requires external evidence' "$adapter prompt rejects prose-only completion" || return
    assert_file_contains "$run_dir/stdout.log" 'stub provider output' "$adapter captures stdout" || return
    assert_contains "$output" "adapter: $adapter" "$adapter reports selected adapter" || return
    call_args=$(<"$call_log")
    assert_contains "$call_args" 'UMASK=<0077>' "$adapter inherits private artifact permissions" || return

    case "$adapter" in
      kiro)
        assert_file_contains "$call_log" 'ARG=<chat>' 'Kiro uses chat command' || return
        assert_file_contains "$call_log" 'ARG=<--no-interactive>' 'Kiro uses headless mode' || return
        assert_file_contains "$call_log" 'ARG=<--agent>' 'Kiro passes native role' || return
        assert_file_contains "$call_log" 'ARG=<--trust-tools=read,write,grep,glob>' 'Kiro safe mode trusts only file-oriented tools' || return
        assert_not_contains "$call_args" 'ARG=<--trust-all-tools>' 'Kiro does not bypass permissions by default' || return
        ;;
      claude)
        assert_file_contains "$call_log" 'ARG=<-p>' 'Claude uses print mode' || return
        assert_file_contains "$call_log" 'ARG=<--output-format>' 'Claude requests structured output' || return
        assert_file_contains "$call_log" 'ARG=<json>' 'Claude requests JSON output' || return
        assert_file_contains "$call_log" 'ARG=<dontAsk>' 'Claude fails closed on unapproved tools' || return
        assert_file_contains "$call_log" 'ARG=<--allowedTools>' 'Claude receives an explicit safe tool allowlist' || return
        assert_file_contains "$call_log" 'ARG=<--agent>' 'Claude passes native role' || return
        assert_not_contains "$call_args" 'ARG=<acceptEdits>' 'Claude does not auto-approve edits through acceptEdits' || return
        assert_not_contains "$call_args" 'ARG=<--dangerously-skip-permissions>' 'Claude does not bypass permissions by default' || return
        ;;
      codex)
        assert_file_contains "$call_log" 'ARG=<exec>' 'Codex uses exec mode' || return
        assert_file_contains "$call_log" 'ARG=<--json>' 'Codex requests JSONL output' || return
        assert_file_contains "$call_log" 'ARG=<--sandbox>' 'Codex selects its sandbox explicitly' || return
        assert_file_contains "$call_log" 'ARG=<workspace-write>' 'Codex uses the workspace-write sandbox' || return
        assert_not_contains "$call_args" 'ARG=<--full-auto>' 'Codex avoids the deprecated full-auto alias' || return
        assert_file_contains "$call_log" 'ARG=<-C>' 'Codex receives working directory' || return
        assert_not_contains "$call_args" 'ARG=<--dangerously-bypass-approvals-and-sandbox>' 'Codex keeps its sandbox by default' || return
        ;;
      opencode)
        assert_file_contains "$call_log" 'ARG=<run>' 'OpenCode uses run mode' || return
        assert_file_contains "$call_log" 'ARG=<--format>' 'OpenCode requests explicit output format' || return
        assert_file_contains "$call_log" 'ARG=<json>' 'OpenCode requests JSON event output' || return
        assert_not_contains "$call_args" 'ARG=<--agent>' 'OpenCode safe mode keeps role as prompt context only' || return
        assert_file_contains "$run_dir/prompt.md" 'Role: reviewer' 'OpenCode safe mode preserves role in the goal contract' || return
        assert_file_contains "$call_log" 'OPENCODE_PERMISSION=<{"*":"deny"' 'OpenCode receives a fail-closed permission policy' || return
        assert_not_contains "$call_args" 'ARG=<--auto>' 'OpenCode does not use the obsolete auto flag' || return
        assert_not_contains "$call_args" 'ARG=<--dangerously-skip-permissions>' 'OpenCode does not auto-approve permissions by default' || return
        ;;
      hermes)
        assert_file_contains "$call_log" 'ARG=<chat>' 'Hermes uses the policy-aware chat command' || return
        assert_file_contains "$call_log" 'ARG=<--quiet>' 'Hermes uses quiet chat rather than implicit-yolo one-shot mode' || return
        assert_file_contains "$call_log" 'ARG=<--query>' 'Hermes uses single-query mode' || return
        assert_not_contains "$call_args" 'ARG=<--yolo>' 'Hermes does not bypass permissions by default' || return
        ;;
    esac
  done
  ok 'run executes five adapters through one seam and records evidence artifacts'
}

test_run_executes_all_adapters_and_records_artifacts || true

test_task_files_and_paths_with_spaces_are_preserved() {
  workdir="$TEST_TMP/work dir with spaces"
  run_root="$TEST_TMP/run root with spaces"
  task_file="$workdir/task file.md"
  call_log="$TEST_TMP/spaces-call.log"
  mkdir -p "$workdir"
  printf 'Create a literal file in the spaced work directory.\n' > "$task_file"
  make_stub opencode 'pwd > "$ORCH_TEST_PWD_LOG"
printf "ARG=<%s>\\n" "$@" > "$ORCH_TEST_CALL_LOG"'

  output=$(ORCH_TEST_CALL_LOG="$call_log" ORCH_TEST_PWD_LOG="$TEST_TMP/spaces-pwd.log" \
    PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
      --cli opencode \
      --task-file "$task_file" \
      --workdir "$workdir" \
      --run-root "$run_root" 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'run accepts task and path arguments containing spaces'
    return
  }
  set -- "$run_root"/*
  run_dir=$1
  assert_file_contains "$run_dir/prompt.md" 'Create a literal file in the spaced work directory.' 'task-file content survives prompt construction' || return
  assert_file_contains "$run_dir/meta.env" "workdir=$workdir" 'metadata preserves spaced working directory' || return
  assert_file_contains "$TEST_TMP/spaces-pwd.log" "$workdir" 'adapter executes inside spaced working directory' || return
  ok 'run preserves task files and working paths containing spaces'
}

test_task_files_and_paths_with_spaces_are_preserved || true

test_unsafe_permission_bypass_is_explicit() {
  for adapter in kiro claude codex opencode hermes; do
    case "$adapter" in
      kiro) binary=kiro-cli; expected='ARG=<--trust-all-tools>' ;;
      claude) binary=claude; expected='ARG=<--dangerously-skip-permissions>' ;;
      codex) binary=codex; expected='ARG=<--dangerously-bypass-approvals-and-sandbox>' ;;
      opencode) binary=opencode; expected='ARG=<--dangerously-skip-permissions>' ;;
      hermes) binary=hermes; expected='ARG=<--yolo>' ;;
    esac
    call_log="$TEST_TMP/$adapter-unsafe-args.log"
    make_stub "$binary" 'for arg in "$@"; do
  [ "$arg" != "--auto" ] || exit 64
done
printf "ARG=<%s>\\n" "$@" > "$ORCH_TEST_CALL_LOG"
cat >/dev/null || true'
    ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
      "$ROOT/bin/orch" run \
        --cli "$adapter" \
        --task 'Exercise explicit unsafe mode' \
        --role reviewer \
        --workdir "$TEST_TMP" \
        --run-root "$TEST_TMP/$adapter-unsafe-runs" \
        --unsafe >/dev/null 2>&1 || {
      not_ok "$adapter explicit unsafe invocation succeeds"
      return
    }
    assert_file_contains "$call_log" "$expected" "$adapter only receives permission bypass after --unsafe" || return
    if [ "$adapter" = opencode ]; then
      assert_file_contains "$call_log" 'ARG=<--agent>' 'OpenCode only selects native agents in unsafe mode' || return
    fi
  done
  ok 'unsafe provider permission bypasses require an explicit flag'
}

test_unsafe_permission_bypass_is_explicit || true

test_run_propagates_provider_failure() {
  call_log="$TEST_TMP/provider-failure-args.log"
  run_root="$TEST_TMP/provider-failure-runs"
  make_stub claude 'printf "provider failed\\n" >&2
exit 7'

  if output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" run \
      --cli claude \
      --task 'Expected failure' \
      --workdir "$TEST_TMP" \
      --run-root "$run_root" 2>&1); then
    not_ok 'run propagates provider failure'
    return
  else
    provider_status=$?
  fi
  set -- "$run_root"/*
  run_dir=$1
  assert_file_contains "$run_dir/meta.env" 'exit_code=7' 'run records provider failure code' || return
  assert_file_contains "$run_dir/meta.env" 'status=failed' 'run records provider failure status' || return
  assert_file_contains "$run_dir/stderr.log" 'provider failed' 'run preserves provider failure output' || return
  assert_contains "$output" 'status: failed' 'run reports provider failure' || return
  [ "$provider_status" -eq 7 ] || { not_ok 'run returns the raw provider failure code'; return; }
  ok 'run propagates the raw provider failure and preserves diagnostics'
}

test_run_propagates_provider_failure || true

test_run_enforces_outer_timeout() {
  run_root="$TEST_TMP/provider-timeout-runs"
  descendant_pid_file="$TEST_TMP/provider-descendant.pid"
  make_stub claude 'sleep 30 &
descendant_pid=$!
printf "%s\\n" "$descendant_pid" > "$ORCH_TEST_DESCENDANT_PID_FILE"
wait "$descendant_pid"
printf "should not finish\\n"'

  if output=$(ORCH_TEST_DESCENDANT_PID_FILE="$descendant_pid_file" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" run \
      --cli claude \
      --task 'Expected timeout' \
      --timeout 1 \
      --workdir "$TEST_TMP" \
      --run-root "$run_root" 2>&1); then
    not_ok 'run returns failure after provider timeout'
    return
  fi
  set -- "$run_root"/*
  run_dir=$1
  assert_file_contains "$run_dir/meta.env" 'exit_code=124' 'run records conventional timeout exit code' || return
  assert_file_contains "$run_dir/meta.env" 'status=timed_out' 'run records timeout status' || return
  [ -f "$run_dir/provider.timeout" ] || { not_ok 'run records timeout evidence marker'; return; }
  assert_contains "$output" 'status: timed_out' 'run reports timeout status' || return
  descendant_pid=$(<"$descendant_pid_file")
  if kill -0 "$descendant_pid" 2>/dev/null; then
    kill -KILL "$descendant_pid" 2>/dev/null || true
    not_ok 'provider timeout terminates descendant processes'
    return
  fi
  ok 'run bounds provider wall time and terminates its process group'
}

test_run_enforces_outer_timeout || true

test_timeout_wrapper_reaps_descendants_on_signal() {
  marker="$TEST_TMP/interrupted.timeout"
  descendant_pid_file="$TEST_TMP/interrupted-descendant.pid"

  ORCH_TEST_DESCENDANT_PID_FILE="$descendant_pid_file" \
    "$ROOT/lib/orch/timeout.sh" 30 "$marker" bash -c \
      'sleep 30 & child=$!; printf "%s\n" "$child" > "$ORCH_TEST_DESCENDANT_PID_FILE"; wait "$child"' \
      >"$TEST_TMP/interrupted.stdout" 2>"$TEST_TMP/interrupted.stderr" &
  wrapper_pid=$!

  attempts=0
  while [ ! -s "$descendant_pid_file" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
  done
  [ -s "$descendant_pid_file" ] || { kill -KILL "$wrapper_pid" 2>/dev/null || true; not_ok 'signal cleanup fixture starts descendant'; return; }

  kill -TERM "$wrapper_pid"
  if wait "$wrapper_pid"; then
    not_ok 'signaled timeout wrapper returns non-zero'
    return
  else
    wrapper_status=$?
  fi
  [ "$wrapper_status" -eq 143 ] || { not_ok 'TERM maps to exit 143'; return; }
  descendant_pid=$(<"$descendant_pid_file")
  if kill -0 "$descendant_pid" 2>/dev/null; then
    kill -KILL "$descendant_pid" 2>/dev/null || true
    not_ok 'signal trap reaps timeout descendants'
    return
  fi
  [ ! -e "$marker" ] || { not_ok 'operator signal is not mislabeled as watchdog timeout'; return; }
  ok 'timeout wrapper escalates and reaps its process group on TERM'
}

test_timeout_wrapper_reaps_descendants_on_signal || true

test_natural_exit_124_is_not_misclassified_as_timeout() {
  run_root="$TEST_TMP/natural-124-runs"
  make_stub claude 'cat >/dev/null || true
exit 124'

  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
    --cli claude --task 'Return 124 naturally' --workdir "$TEST_TMP" \
    --run-root "$run_root" 2>&1); then
    not_ok 'natural provider exit 124 returns non-zero'
    return
  else
    run_status=$?
  fi
  [ "$run_status" -eq 124 ] || { not_ok 'run preserves natural provider exit 124'; return; }
  set -- "$run_root"/*
  run_dir=$1
  assert_file_contains "$run_dir/meta.env" 'exit_code=124' 'run records natural exit 124' || return
  assert_file_contains "$run_dir/meta.env" 'status=failed' 'run classifies unmarked natural 124 as failed' || return
  [ ! -e "$run_dir/provider.timeout" ] || { not_ok 'natural provider exit 124 creates no timeout marker'; return; }
  assert_contains "$output" 'status: failed' 'run reports natural exit 124 as failure' || return

  loop_root="$TEST_TMP/natural-124-loop-runs"
  PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" loop \
    --cli claude --task 'Gate is authoritative' --verify 'true' --max-iterations 1 \
    --workdir "$TEST_TMP" --run-root "$loop_root" >/dev/null 2>&1 || {
    not_ok 'loop permits external evidence to pass after natural provider exit 124'
    return
  }
  set -- "$loop_root"/*
  loop_dir=$1
  assert_file_contains "$loop_dir/iteration-1/meta.env" 'status=failed' 'loop does not misclassify natural provider 124 as timeout' || return

  marked_run="$TEST_TMP/natural-124-verify-run"
  mkdir "$marked_run"
  write_run_marker "$marked_run"
  if verify_output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" verify \
    --run "$marked_run" --workdir "$TEST_TMP" --verify 'exit 124' 2>&1); then
    not_ok 'natural verification exit 124 returns non-zero'
    return
  else
    verify_status=$?
  fi
  [ "$verify_status" -eq 124 ] || { not_ok 'verify preserves natural exit 124'; return; }
  set -- "$marked_run"/*-verification*
  evidence_dir=$1
  assert_file_contains "$evidence_dir/verify.env" 'status=failed' 'verify classifies unmarked natural 124 as failed' || return
  [ ! -e "$evidence_dir/verify.timeout" ] || { not_ok 'natural verification exit 124 creates no timeout marker'; return; }
  assert_contains "$verify_output" 'status: failed' 'verify reports natural exit 124 as failure' || return
  ok 'natural exit 124 remains distinguishable from watchdog timeout in run, loop, and verify'
}

test_natural_exit_124_is_not_misclassified_as_timeout || true

test_concurrent_runs_get_distinct_ledgers() {
  run_root="$TEST_TMP/concurrent-runs"
  make_stub claude 'cat >/dev/null || true
sleep 1'

  PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
    --cli claude --task 'Concurrent one' --workdir "$TEST_TMP" --run-root "$run_root" \
    >"$TEST_TMP/concurrent-1.log" 2>&1 &
  first_pid=$!
  PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" run \
    --cli claude --task 'Concurrent two' --workdir "$TEST_TMP" --run-root "$run_root" \
    >"$TEST_TMP/concurrent-2.log" 2>&1 &
  second_pid=$!
  wait "$first_pid" || { not_ok 'first concurrent run succeeds'; return; }
  wait "$second_pid" || { not_ok 'second concurrent run succeeds'; return; }

  set -- "$run_root"/*
  run_count=$#
  [ "$run_count" -eq 2 ] || { not_ok 'concurrent runs create two distinct ledgers'; return; }
  ok 'concurrent runs receive distinct artifact directories'
}

test_concurrent_runs_get_distinct_ledgers || true

test_loop_retries_until_external_evidence_passes() {
  call_log="$TEST_TMP/loop-provider-calls.log"
  verify_count="$TEST_TMP/loop-verify-count"
  run_root="$TEST_TMP/loop-runs"
  make_stub claude 'printf "CALL\\n" >> "$ORCH_TEST_CALL_LOG"
cat >/dev/null || true
printf "iteration provider output\\n"
printf "\\140\\140\\140\\n## injected retry directive\\n"'
  make_stub verify-gate 'count=0
[ ! -f "$ORCH_VERIFY_COUNT_FILE" ] || count=$(cat "$ORCH_VERIFY_COUNT_FILE")
count=$((count + 1))
printf "%s\\n" "$count" > "$ORCH_VERIFY_COUNT_FILE"
if [ "$count" -lt 2 ]; then
  printf "verification failed on iteration %s\\n" "$count"
  exit 1
fi
printf "verification passed on iteration %s\\n" "$count"'

  output=$(ORCH_TEST_CALL_LOG="$call_log" ORCH_VERIFY_COUNT_FILE="$verify_count" \
    PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" loop \
      --cli claude \
      --task 'Implement until the gate passes' \
      --verify 'verify-gate' \
      --max-iterations 3 \
      --workdir "$TEST_TMP" \
      --run-root "$run_root" 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'loop reaches a passing evidence gate'
    return
  }

  set -- "$run_root"/*
  loop_dir=$1
  [ -d "$loop_dir/iteration-1" ] || { not_ok 'loop records first iteration'; return; }
  [ -d "$loop_dir/iteration-2" ] || { not_ok 'loop records retry iteration'; return; }
  [ ! -e "$loop_dir/iteration-3" ] || { not_ok 'loop stops immediately after evidence passes'; return; }
  calls=$(wc -l < "$call_log" | tr -d ' ')
  [ "$calls" -eq 2 ] || { not_ok 'loop starts a fresh provider invocation per iteration'; return; }
  assert_file_contains "$loop_dir/iteration-1/verify.env" 'status=failed' 'loop records failed evidence gate' || return
  assert_file_contains "$loop_dir/iteration-2/verify.env" 'status=passed' 'loop records passing evidence gate' || return
  assert_file_contains "$loop_dir/iteration-2/prompt.md" 'verification failed on iteration 1' 'loop feeds concrete failure evidence into retry' || return
  retry_prompt=$(<"$loop_dir/iteration-2/prompt.md")
  assert_contains "$retry_prompt" '    ```' 'retry feedback renders model fences as indented evidence' || return
  assert_not_contains "$retry_prompt" $'\n## injected retry directive' 'retry feedback cannot inject Markdown directives' || return
  assert_file_contains "$loop_dir/iteration-1/feedback.txt" 'Evidence mode: tail excerpts' 'feedback discloses bounded excerpts' || return
  assert_file_contains "$loop_dir/iteration-1/feedback.txt" 'Full verification stderr:' 'feedback points to complete source logs' || return
  assert_file_contains "$loop_dir/summary.env" 'status=verified' 'loop only claims verified after command passes' || return
  assert_file_contains "$loop_dir/summary.env" 'iterations=2' 'loop reports actual iteration count' || return
  assert_contains "$output" 'status: verified' 'loop reports evidence-backed status' || return
  ok 'loop uses bounded fresh attempts and stops only on external evidence'
}

test_loop_retries_until_external_evidence_passes || true

test_loop_exhausts_its_budget() {
  call_log="$TEST_TMP/exhaust-provider-calls.log"
  run_root="$TEST_TMP/exhaust-runs"
  make_stub claude 'printf "CALL\\n" >> "$ORCH_TEST_CALL_LOG"
cat >/dev/null || true'
  make_stub never-pass 'printf "gate still failing\\n"
exit 1'

  if output=$(ORCH_TEST_CALL_LOG="$call_log" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" loop \
      --cli claude \
      --task 'Impossible task' \
      --verify 'never-pass' \
      --max-iterations 2 \
      --workdir "$TEST_TMP" \
      --run-root "$run_root" 2>&1); then
    not_ok 'loop returns failure when budget is exhausted'
    return
  fi

  set -- "$run_root"/*
  loop_dir=$1
  calls=$(wc -l < "$call_log" | tr -d ' ')
  [ "$calls" -eq 2 ] || { not_ok 'exhausted loop honors maximum iteration count'; return; }
  assert_file_contains "$loop_dir/summary.env" 'status=exhausted' 'loop records exhausted status' || return
  assert_file_contains "$loop_dir/summary.env" 'iterations=2' 'loop records full budget use' || return
  assert_contains "$output" 'status: exhausted' 'loop reports exhausted status' || return
  ok 'loop fails closed when its iteration budget is exhausted'
}

test_loop_exhausts_its_budget || true

test_verify_rejects_unmarked_directories() {
  run_dir="$TEST_TMP/not-an-orchestrator-run"
  mkdir "$run_dir"

  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" verify \
    --run "$run_dir" --workdir "$TEST_TMP" --verify 'true' 2>&1); then
    not_ok 'verify rejects an unmarked arbitrary directory'
    return
  fi
  assert_contains "$output" 'not an orchestrator run directory' 'verify explains the run-marker requirement' || return
  [ ! -e "$run_dir/verify.env" ] || { not_ok 'verify does not overwrite an unmarked directory'; return; }

  printf 'schema=10\ntype=forged\n' > "$run_dir/.orch-run"
  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" verify \
    --run "$run_dir" --workdir "$TEST_TMP" --verify 'true' 2>&1); then
    not_ok 'verify rejects an unsupported run-marker schema'
    return
  fi
  assert_contains "$output" 'unsupported orchestrator run marker' 'verify validates the exact marker schema' || return
  ok 'verify refuses arbitrary existing directories without a valid orchestrator marker'
}

test_verify_rejects_unmarked_directories || true

test_verify_records_standalone_evidence() {
  run_dir="$TEST_TMP/manual-run"
  mkdir "$run_dir"
  write_run_marker "$run_dir"
  make_stub pass-check 'printf "standalone evidence passed\\n"'

  output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" verify \
      --run "$run_dir" \
      --workdir "$TEST_TMP" \
      --verify 'pass-check' 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'standalone verification accepts passing evidence'
    return
  }
  set -- "$run_dir"/*-verification*
  pass_evidence=$1
  assert_file_contains "$pass_evidence/verify.env" 'status=passed' 'verify records passing status' || return
  assert_file_contains "$pass_evidence/verify.env" 'command_file=verify.command' 'verify metadata points to the raw command artifact' || return
  assert_file_contains "$pass_evidence/verify.command" 'pass-check' 'verify preserves the exact command separately from line metadata' || return
  assert_file_contains "$pass_evidence/verify.stdout.log" 'standalone evidence passed' 'verify captures evidence output' || return
  assert_contains "$output" 'status: passed' 'verify reports passing status' || return
  assert_contains "$output" 'evidence:' 'verify reports its unique evidence directory' || return

  make_stub fail-check 'printf "standalone evidence failed\\n"
exit 9'
  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    "$ROOT/bin/orch" verify \
      --run "$run_dir" \
      --workdir "$TEST_TMP" \
      --verify 'fail-check' 2>&1); then
    not_ok 'standalone verification propagates a failing gate'
    return
  fi
  set -- "$run_dir"/*-verification*
  fail_evidence=$2
  assert_file_contains "$fail_evidence/verify.env" 'exit_code=9' 'verify records failing exit code' || return
  assert_file_contains "$fail_evidence/verify.env" 'status=failed' 'verify records failing status' || return
  assert_contains "$output" 'status: failed' 'verify reports failing status' || return
  ok 'verify exposes append-only deterministic evidence as a reusable seam'
}

test_verify_records_standalone_evidence || true

test_verify_enforces_outer_timeout() {
  run_dir="$TEST_TMP/verify-timeout-run"
  mkdir "$run_dir"
  write_run_marker "$run_dir"

  if output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/bin/orch" verify \
    --run "$run_dir" \
    --workdir "$TEST_TMP" \
    --verify 'sleep 5' \
    --timeout 1 2>&1); then
    not_ok 'verification timeout returns non-zero'
    return
  fi
  set -- "$run_dir"/*-verification*
  timeout_evidence=$1
  assert_file_contains "$timeout_evidence/verify.env" 'exit_code=124' 'verify records timeout exit code' || return
  assert_file_contains "$timeout_evidence/verify.env" 'status=timed_out' 'verify records timeout status' || return
  [ -f "$timeout_evidence/verify.timeout" ] || { not_ok 'verify writes timeout evidence marker'; return; }
  assert_contains "$output" 'status: timed_out' 'verify reports timeout status' || return
  ok 'verify bounds external evidence commands with an outer watchdog'
}

test_verify_enforces_outer_timeout || true

test_unsafe_legacy_entry_points_are_quarantined() {
  unset KIRO_ENABLE_UNSUPPORTED_LEGACY
  legacy_entry_points='
.kiro/workflows/worktree-manager.sh
.kiro/workflows/dashboard.sh
.kiro/workflows/chain-workflow.sh
.kiro/workflows/fusion.sh
.kiro/workflows/l-thread-runner.sh
.kiro/workflows/b-thread-orchestrator.sh
.kiro/workflows/dual-verify.sh
.kiro/workflows/ralph-loop-v2.sh
.kiro/scripts/create-pr.sh
.kiro/scripts/merge-pr.sh'

  while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue
    if output=$(bash "$ROOT/$relative_path" 2>&1); then
      not_ok "legacy entry point is disabled by default: $relative_path"
      return
    fi
    assert_contains "$output" 'disabled' "legacy quarantine explains why $relative_path cannot run" || return
  done <<EOF
$legacy_entry_points
EOF
  settings=$(<"$ROOT/.kiro/settings.local.json")
  allow_block=${settings%%\"deny\"*}
  assert_not_contains "$settings" '"hooks"' 'active Kiro settings no longer load legacy hooks' || return
  assert_not_contains "$allow_block" '"Bash(*)"' 'active Kiro settings no longer blanket-allow shell commands' || return
  assert_not_contains "$settings" '<promise>DONE</promise>' 'active Kiro settings no longer advertise prose completion tokens' || return
  ok 'unsafe, simulated, and token-controlled legacy entry points fail closed by default'
}

test_unsafe_legacy_entry_points_are_quarantined || true

test_kiro_compatibility_wrapper_uses_supported_core() {
  make_stub kiro-cli 'exit 0'
  output=$(PATH="$TEST_TMP/bin:/usr/bin:/bin" "$ROOT/.kiro/workflows/ralph-kiro.sh" \
    --task 'Compatibility task' \
    --verify 'true' \
    --dry-run 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'Kiro compatibility wrapper accepts modern loop arguments'
    return
  }
  assert_contains "$output" 'compatibility entry point' 'wrapper discloses migration' || return
  assert_contains "$output" 'adapter: kiro' 'wrapper selects the real Kiro adapter' || return
  assert_contains "$output" 'DRY RUN' 'wrapper preserves write-never dry-run behavior' || return
  ok 'historical Kiro entry point delegates to the supported kernel'
}

test_kiro_compatibility_wrapper_uses_supported_core || true

test_golden_path_gate_is_deterministic() {
  fixture="$TEST_TMP/golden path fixture"
  mkdir -p "$fixture"
  cp "$ROOT/examples/golden-path/verify.sh" "$fixture/verify.sh"

  printf 'wrong\n' > "$fixture/result.txt"
  if (cd "$fixture" && bash verify.sh >/dev/null 2>&1); then
    not_ok 'golden path rejects incorrect content'
    return
  fi
  printf 'orchestrated\n' > "$fixture/result.txt"
  output=$(cd "$fixture" && bash verify.sh 2>&1) || {
    printf '%s\n' "$output" >&2
    not_ok 'golden path accepts exact content'
    return
  }
  assert_contains "$output" 'golden path verified' 'golden path reports deterministic success' || return
  ok 'golden path fixture rejects wrong output and accepts the exact contract'
}

test_golden_path_gate_is_deterministic || true

test_mcp_python_parses() {
  if ! "$(python_bin)" -m py_compile "$ROOT/lib/orch/mcp_server.py" "$ROOT/tests/mcp_call.py"; then
    not_ok 'MCP python modules parse'
    return
  fi
  help_output=$("$ROOT/bin/orch" mcp --help 2>&1) || {
    not_ok 'orch mcp --help exits successfully'
    return
  }
  assert_contains "$help_output" 'Does not replace the CLI' 'mcp help keeps the CLI as the supported seam' || return
  assert_contains "$help_output" 'evidence gate' 'mcp help preserves the evidence-gate contract' || return
  ok 'MCP server parses and mcp help stays a thin CLI wrapper'
}

test_mcp_python_parses || true

test_mcp_lists_real_orch_tools() {
  list_json=$(mcp_call --list 2>"$TEST_TMP/mcp-list.err") || {
    cat "$TEST_TMP/mcp-list.err" >&2
    not_ok 'MCP tools/list handshake succeeds'
    return
  }
  assert_contains "$list_json" '"name": "orch_doctor"' 'MCP lists orch_doctor' || return
  assert_contains "$list_json" '"name": "orch_run"' 'MCP lists orch_run' || return
  assert_contains "$list_json" '"name": "orch_loop"' 'MCP lists orch_loop' || return
  assert_contains "$list_json" '"name": "orch_verify"' 'MCP lists orch_verify' || return
  init_json=$(mcp_call --initialize 2>"$TEST_TMP/mcp-init.err") || {
    cat "$TEST_TMP/mcp-init.err" >&2
    not_ok 'MCP initialize handshake succeeds'
    return
  }
  assert_contains "$init_json" 'external verification command' 'initialize states the evidence-gate contract' || return
  assert_contains "$init_json" '<promise>DONE</promise>' 'initialize rejects prose completion tokens' || return
  ok 'MCP advertises doctor, run, loop, and verify without a dashboard'
}

test_mcp_lists_real_orch_tools || true

test_mcp_doctor_maps_to_orch_doctor() {
  argv_log="$TEST_TMP/mcp-doctor-argv.log"
  make_stub kiro-cli 'printf "stub-kiro 1.0\\n"'
  make_stub claude 'printf "stub-claude 1.0\\n"'
  make_stub codex 'printf "stub-codex 1.0\\n"'
  make_stub opencode 'printf "stub-opencode 1.0\\n"'
  make_stub hermes 'printf "stub-hermes 1.0\\n"'
  make_orch_proxy

  json=$(PATH="$(mcp_path)" \
    ORCH_BIN="$TEST_TMP/bin/orch-proxy" \
    ORCH_REAL_BIN="$ROOT/bin/orch" \
    ORCH_TEST_ARGV_LOG="$argv_log" \
    mcp_call orch_doctor '{}' 2>"$TEST_TMP/mcp-doctor.err") || {
    cat "$TEST_TMP/mcp-doctor.err" >&2
    not_ok 'MCP doctor returns JSON'
    return
  }

  argv_log_text=$(<"$argv_log")
  assert_contains "$argv_log_text" 'ARGV: <doctor>' 'MCP doctor invokes the real orch doctor command' || return
  [ "$(json_get "$json" command)" = doctor ] || { not_ok 'MCP doctor JSON names the doctor command'; return; }
  [ "$(json_get "$json" ok)" = true ] || { not_ok 'MCP doctor reports ok when an adapter exists'; return; }
  assert_contains "$json" '"name": "claude"' 'MCP doctor JSON includes Claude' || return
  assert_contains "$json" '"name": "kiro"' 'MCP doctor JSON includes Kiro' || return
  assert_contains "$json" '"status": "available"' 'MCP doctor JSON reports adapter availability' || return
  [ "$(json_get "$json" prose_is_not_done)" = true ] || { not_ok 'MCP doctor keeps the prose-is-not-done contract'; return; }
  ok 'MCP doctor maps to orch doctor and returns structured JSON'
}

test_mcp_doctor_maps_to_orch_doctor || true

test_mcp_run_maps_to_orch_and_returns_ledger_json() {
  argv_log="$TEST_TMP/mcp-run-argv.log"
  run_root="$TEST_TMP/mcp-run-artifacts"
  make_stub claude 'printf "provider ran\\n"'
  make_orch_proxy

  json=$(PATH="$(mcp_path)" \
    ORCH_BIN="$TEST_TMP/bin/orch-proxy" \
    ORCH_REAL_BIN="$ROOT/bin/orch" \
    ORCH_TEST_ARGV_LOG="$argv_log" \
    OPENAI_API_KEY='sk-test-secret-should-not-leak' \
    mcp_call orch_run "$(printf '{"cli":"claude","task":"Write a tiny change","workdir":"%s","run_root":"%s"}' "$TEST_TMP" "$run_root")" \
    2>"$TEST_TMP/mcp-run.err") || {
    cat "$TEST_TMP/mcp-run.err" >&2
    not_ok 'MCP run returns JSON'
    return
  }

  argv_log_text=$(<"$argv_log")
  assert_contains "$argv_log_text" 'ARGV: <run>' 'MCP run invokes the real orch run command' || return
  json_argv_has "$json" run || { not_ok 'MCP run JSON records orch argv starting with run'; return; }
  if json_argv_has "$json" --unsafe; then
    not_ok 'MCP run omits --unsafe by default'
    return
  fi
  if json_argv_has "$json" --verify; then
    not_ok 'MCP run does not attach an evidence gate'
    return
  fi
  [ "$(json_get "$json" command)" = run ] || { not_ok 'MCP run JSON names the run command'; return; }
  [ "$(json_get "$json" status)" = unverified ] || { not_ok 'MCP run records unverified rather than verified'; return; }
  run_dir=$(json_get "$json" run_dir)
  run_id=$(json_get "$json" run_id)
  if [ -z "$run_dir" ] || [ ! -d "$run_dir" ]; then
    not_ok 'MCP run JSON includes an existing run_dir'
    return
  fi
  [ "$run_id" = "$(basename "$run_dir")" ] || { not_ok 'MCP run_id matches the ledger directory name'; return; }
  [ -f "$(json_get "$json" ledger.meta)" ] || { not_ok 'MCP run JSON points at meta.env without requiring hand parsing'; return; }
  [ -f "$(json_get "$json" ledger.prompt)" ] || { not_ok 'MCP run JSON points at prompt.md'; return; }
  [ "$(json_get "$json" meta.status)" = unverified ] || { not_ok 'MCP run parses meta.env as data'; return; }
  assert_not_contains "$json" 'sk-test-secret-should-not-leak' 'MCP JSON does not echo secrets from the environment' || return
  ok 'MCP run maps to orch run and returns run id, status, and ledger paths'
}

test_mcp_run_maps_to_orch_and_returns_ledger_json || true

test_mcp_run_dry_run_is_write_never() {
  argv_log="$TEST_TMP/mcp-dry-run-argv.log"
  run_root="$TEST_TMP/mcp-dry-run-artifacts"
  call_log="$TEST_TMP/mcp-dry-run-calls.log"
  make_stub claude 'printf "called\\n" >> "$ORCH_TEST_CALL_LOG"'
  make_orch_proxy

  json=$(PATH="$(mcp_path)" \
    ORCH_BIN="$TEST_TMP/bin/orch-proxy" \
    ORCH_REAL_BIN="$ROOT/bin/orch" \
    ORCH_TEST_ARGV_LOG="$argv_log" \
    ORCH_TEST_CALL_LOG="$call_log" \
    mcp_call orch_run "$(printf '{"cli":"claude","task":"Do not execute","workdir":"%s","run_root":"%s","dry_run":true}' "$TEST_TMP" "$run_root")" \
    2>"$TEST_TMP/mcp-dry-run.err") || {
    cat "$TEST_TMP/mcp-dry-run.err" >&2
    not_ok 'MCP dry-run run returns JSON'
    return
  }

  json_argv_has "$json" --dry-run || { not_ok 'MCP dry-run forwards --dry-run to orch'; return; }
  [ "$(json_get "$json" dry_run)" = true ] || { not_ok 'MCP dry-run JSON reports dry_run'; return; }
  [ ! -e "$call_log" ] || { not_ok 'MCP dry-run does not invoke the provider'; return; }
  [ ! -e "$run_root" ] || { not_ok 'MCP dry-run creates no ledger'; return; }
  ok 'MCP run dry-run maps to orch --dry-run without writes'
}

test_mcp_run_dry_run_is_write_never || true

test_mcp_loop_returns_verified_only_after_gate() {
  argv_log="$TEST_TMP/mcp-loop-argv.log"
  run_root="$TEST_TMP/mcp-loop-artifacts"
  verify_count="$TEST_TMP/mcp-loop-verify-count"
  make_stub claude 'printf "iteration provider output\\n"'
  make_stub verify-gate 'count=0
[ ! -f "$ORCH_VERIFY_COUNT_FILE" ] || count=$(cat "$ORCH_VERIFY_COUNT_FILE")
count=$((count + 1))
printf "%s\\n" "$count" > "$ORCH_VERIFY_COUNT_FILE"
if [ "$count" -lt 2 ]; then
  printf "verification failed on iteration %s\\n" "$count"
  exit 1
fi
printf "verification passed on iteration %s\\n" "$count"'
  make_orch_proxy

  json=$(PATH="$(mcp_path)" \
    ORCH_BIN="$TEST_TMP/bin/orch-proxy" \
    ORCH_REAL_BIN="$ROOT/bin/orch" \
    ORCH_TEST_ARGV_LOG="$argv_log" \
    ORCH_VERIFY_COUNT_FILE="$verify_count" \
    mcp_call orch_loop "$(printf '{"cli":"claude","task":"Implement until the gate passes","verify":"verify-gate","max_iterations":3,"workdir":"%s","run_root":"%s"}' "$TEST_TMP" "$run_root")" \
    2>"$TEST_TMP/mcp-loop.err") || {
    cat "$TEST_TMP/mcp-loop.err" >&2
    not_ok 'MCP loop returns JSON'
    return
  }

  argv_log_text=$(<"$argv_log")
  assert_contains "$argv_log_text" 'ARGV: <loop>' 'MCP loop invokes the real orch loop command' || return
  json_argv_has "$json" --verify || { not_ok 'MCP loop forwards --verify to orch'; return; }
  [ "$(json_get "$json" status)" = verified ] || { not_ok 'MCP loop reports verified only after the gate passes'; return; }
  [ "$(json_get "$json" iterations)" = 2 ] || { not_ok 'MCP loop JSON reports the iteration count'; return; }
  [ "$(json_get "$json" summary.status)" = verified ] || { not_ok 'MCP loop parses summary.env as data'; return; }
  [ -f "$(json_get "$json" ledger.summary)" ] || { not_ok 'MCP loop JSON points at summary.env'; return; }
  [ -d "$(json_get "$json" run_dir)" ] || { not_ok 'MCP loop JSON includes the loop ledger path'; return; }
  ok 'MCP loop maps to orch loop and returns verified only after the external gate'
}

test_mcp_loop_returns_verified_only_after_gate || true

test_mcp_verify_maps_to_orch_verify() {
  argv_log="$TEST_TMP/mcp-verify-argv.log"
  run_dir="$TEST_TMP/mcp-verify-run"
  mkdir "$run_dir"
  write_run_marker "$run_dir"
  make_stub pass-check 'printf "standalone evidence passed\\n"'
  make_orch_proxy

  json=$(PATH="$(mcp_path)" \
    ORCH_BIN="$TEST_TMP/bin/orch-proxy" \
    ORCH_REAL_BIN="$ROOT/bin/orch" \
    ORCH_TEST_ARGV_LOG="$argv_log" \
    mcp_call orch_verify "$(printf '{"run":"%s","verify":"pass-check","workdir":"%s"}' "$run_dir" "$TEST_TMP")" \
    2>"$TEST_TMP/mcp-verify.err") || {
    cat "$TEST_TMP/mcp-verify.err" >&2
    not_ok 'MCP verify returns JSON'
    return
  }

  argv_log_text=$(<"$argv_log")
  assert_contains "$argv_log_text" 'ARGV: <verify>' 'MCP verify invokes the real orch verify command' || return
  [ "$(json_get "$json" command)" = verify ] || { not_ok 'MCP verify JSON names the verify command'; return; }
  [ "$(json_get "$json" status)" = passed ] || { not_ok 'MCP verify reports passed from the gate'; return; }
  evidence_dir=$(json_get "$json" evidence_dir)
  if [ -z "$evidence_dir" ] || [ ! -d "$evidence_dir" ]; then
    not_ok 'MCP verify JSON includes the evidence directory'
    return
  fi
  [ "$(json_get "$json" verification.status)" = passed ] || { not_ok 'MCP verify parses verify.env as data'; return; }
  [ -f "$(json_get "$json" evidence.verify_env)" ] || { not_ok 'MCP verify JSON points at verify.env'; return; }
  ok 'MCP verify maps to orch verify and returns structured evidence paths'
}

test_mcp_verify_maps_to_orch_verify || true

test_mcp_reads_env_artifacts_as_data() {
  run_dir="$TEST_TMP/mcp-env-data-run"
  mkdir "$run_dir"
  write_run_marker "$run_dir"
  printf 'status=unverified\npwn=$(touch %s/mcp-env-pwned)\n' "$TEST_TMP" > "$run_dir/meta.env"
  make_stub claude 'printf "unused\\n"'

  json=$(PATH="$(mcp_path)" \
    mcp_call orch_verify "$(printf '{"run":"%s","verify":"true","workdir":"%s","dry_run":true}' "$run_dir" "$TEST_TMP")" \
    2>"$TEST_TMP/mcp-env-data.err") || {
    cat "$TEST_TMP/mcp-env-data.err" >&2
    not_ok 'MCP verify dry-run returns JSON while reading ledger metadata'
    return
  }

  [ ! -e "$TEST_TMP/mcp-env-pwned" ] || { not_ok 'MCP does not source ledger .env files as shell'; return; }
  [ "$(json_get "$json" meta.pwn)" = "$(printf '$(touch %s/mcp-env-pwned)' "$TEST_TMP")" ] || {
    not_ok 'MCP returns env values as literal data'
    return
  }
  json_argv_has "$json" --dry-run || { not_ok 'MCP verify dry-run forwards --dry-run'; return; }
  ok 'MCP treats ledger .env files as data rather than shell'
}

test_mcp_reads_env_artifacts_as_data || true

test_mcp_client_skips_stdio_banners() {
  output=$("$(python_bin)" - "$ROOT/tests/mcp_call.py" <<'PY'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("mcp_call", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
lines = [
    b"\r\n",
    b"Python was not found; run without arguments to install from the Microsoft Store\n",
    b'{"jsonrpc":"2.0","id":1,"result":{"ok":true}}\n',
]
iterator = iter(lines)
message = mod.next_jsonrpc_line(lambda: next(iterator, b""))
if message.get("id") != 1:
    raise SystemExit("did not parse the first JSON-RPC object after banners")
print("skipped-banners")
PY
  ) || {
    printf '%s\n' "$output" >&2
    not_ok 'MCP client skips Windows/Git Bash stdio banners'
    return
  }
  assert_contains "$output" 'skipped-banners' 'MCP client reports that banners were skipped' || return
  ok 'MCP client skips blank lines and Windows Python banners before JSON-RPC'
}

test_mcp_client_skips_stdio_banners || true

test_mcp_call_rejects_wsl_system32_bash() {
  output=$("$(python_bin)" - "$ROOT/tests/mcp_call.py" <<'PY'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("mcp_call", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
if not mod._is_wsl_bash(r"C:\Windows\System32\bash.exe"):
    raise SystemExit("System32 bash must be treated as WSL")
if not mod._is_wsl_bash(r"C:\WINDOWS\Sysnative\bash.exe"):
    raise SystemExit("Sysnative bash must be treated as WSL")
if mod._is_wsl_bash(r"C:\Program Files\Git\bin\bash.exe"):
    raise SystemExit("Git Bash must not be treated as WSL")
print("wsl-bash-rejected")
PY
  ) || {
    printf '%s\n' "$output" >&2
    not_ok 'MCP client classifies WSL System32 bash'
    return
  }
  assert_contains "$output" 'wsl-bash-rejected' 'MCP client reports WSL bash detection' || return
  ok 'MCP client refuses Windows System32 WSL bash for orch mcp'
}

test_mcp_call_rejects_wsl_system32_bash || true

test_mcp_marks_failed_orch_as_error_without_stderr_leak() {
  raw=$(mcp_call --raw orch_loop '{"task":"cannot self-certify"}' 2>"$TEST_TMP/mcp-iserror.err") || {
    cat "$TEST_TMP/mcp-iserror.err" >&2
    not_ok 'MCP raw loop without verify returns a protocol result'
    return
  }
  assert_contains "$raw" '"isError": true' 'MCP sets isError when orch exits non-zero' || return
  assert_contains "$raw" '"ok": false' 'failed orch payload keeps ok=false' || return
  assert_not_contains "$raw" '"cli_stderr"' 'MCP JSON envelope omits cli_stderr' || return
  ok 'MCP marks failed orch calls as isError and omits cli_stderr'
}

test_mcp_marks_failed_orch_as_error_without_stderr_leak || true

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
