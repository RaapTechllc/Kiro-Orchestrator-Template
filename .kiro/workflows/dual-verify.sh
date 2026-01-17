#!/bin/bash
# .kiro/workflows/dual-verify.sh
#
# Dual-Agent Verification Pattern
# One agent implements, another verifies before claiming DONE.
#
# This catches:
# - Logic errors the writer missed (confirmation bias)
# - Misinterpretation of requirements
# - Over/under-engineering
# - Security issues
#
# Usage:
#   dual-verify.sh --task "implement feature X"
#   dual-verify.sh --task .kiro/specs/plans/feature.plan.md --writer code-surgeon

set -e

#===============================================================================
# CONFIGURATION
#===============================================================================

STATE_DIR=".kiro/state"
VERIFICATION_LOG="$STATE_DIR/dual-verify.log"
MEMORY_DIR=".kiro/memory"

# Default agents
DEFAULT_WRITER="orchestrator"
DEFAULT_VERIFIER="code-surgeon"  # Good at code review

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

usage() {
  cat << EOF
Usage: dual-verify.sh --task <description> [options]

Dual-Agent Verification: One agent implements, another verifies.

OPTIONS:
  --task <desc>       Task description or path to plan file (required)
  --writer <agent>    Agent for implementation (default: $DEFAULT_WRITER)
  --verifier <agent>  Agent for verification (default: $DEFAULT_VERIFIER)
  --max-iterations    Max iterations for writer agent (default: 20)
  --strict            Require verification pass (fail-fast)
  --dry-run           Show what would be done
  -h, --help          Show this help

EXAMPLES:
  # Basic usage
  dual-verify.sh --task "implement user authentication"

  # With specific agents
  dual-verify.sh --task "add API endpoint" --writer code-surgeon --verifier security-specialist

  # From plan file
  dual-verify.sh --task .kiro/specs/plans/feature.plan.md --strict
EOF
}

TASK=""
WRITER_AGENT="$DEFAULT_WRITER"
VERIFIER_AGENT="$DEFAULT_VERIFIER"
MAX_ITERATIONS=20
STRICT_MODE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --task)
      TASK="$2"
      shift 2
      ;;
    --writer)
      WRITER_AGENT="$2"
      shift 2
      ;;
    --verifier)
      VERIFIER_AGENT="$2"
      shift 2
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --strict)
      STRICT_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$TASK" ]; then
  echo "Error: --task is required"
  usage
  exit 1
fi

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local level=$1
  local message=$2
  echo -e "[$level] $message"
  echo "$(timestamp): [$level] $message" >> "$VERIFICATION_LOG"
}

get_task_content() {
  if [ -f "$TASK" ]; then
    cat "$TASK"
  else
    echo "$TASK"
  fi
}

generate_verification_prompt() {
  local task_content="$1"

  cat << EOF
## VERIFICATION TASK

You are reviewing code that was just written by another agent. Your job is to verify:

1. **Requirements Match**: Does the implementation satisfy all requirements?
2. **Code Quality**: Is the code clean, readable, and maintainable?
3. **Error Handling**: Are edge cases and errors handled appropriately?
4. **Security**: Are there any security vulnerabilities?
5. **Tests**: Are there adequate tests for the new code?
6. **No Regressions**: Does the change break existing functionality?

### Original Task
$task_content

### Verification Checklist

Review the git diff and recent changes. For each item, state PASS or FAIL with brief explanation:

- [ ] Requirements satisfied
- [ ] Code quality acceptable
- [ ] Error handling adequate
- [ ] No security issues
- [ ] Tests present and passing
- [ ] No regressions introduced

### Your Response

After reviewing, respond with ONE of:

**If ALL checks pass:**
\`\`\`
VERIFICATION: PASS
All requirements met. Code quality acceptable. Ready for merge.
\`\`\`

**If ANY check fails:**
\`\`\`
VERIFICATION: FAIL
Issues found:
1. [Issue description]
2. [Issue description]

Required fixes:
1. [What needs to change]
\`\`\`

Be thorough but fair. Only fail verification for genuine issues, not style preferences.
EOF
}

#===============================================================================
# MAIN WORKFLOW
#===============================================================================

main() {
  mkdir -p "$STATE_DIR"

  echo -e "${BLUE}=====================================${NC}"
  echo -e "${BLUE}  Dual-Agent Verification Workflow${NC}"
  echo -e "${BLUE}=====================================${NC}"
  echo ""

  # Display configuration
  echo -e "${YELLOW}Configuration:${NC}"
  echo "  Task: $(echo "$TASK" | head -c 60)..."
  echo "  Writer Agent: $WRITER_AGENT"
  echo "  Verifier Agent: $VERIFIER_AGENT"
  echo "  Max Iterations: $MAX_ITERATIONS"
  echo "  Strict Mode: $STRICT_MODE"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN - Would execute:${NC}"
    echo "  1. Run $WRITER_AGENT with task"
    echo "  2. Run $VERIFIER_AGENT to verify implementation"
    echo "  3. Report results"
    exit 0
  fi

  log "INFO" "Starting dual-agent verification"
  log "INFO" "Writer: $WRITER_AGENT, Verifier: $VERIFIER_AGENT"

  # Store task content for verification
  local task_content
  task_content=$(get_task_content)

  # Phase 1: Implementation
  echo -e "${BLUE}Phase 1: Implementation${NC}"
  echo "Running $WRITER_AGENT agent..."
  echo ""

  local writer_start=$(date +%s)

  # Run the writer agent
  if command -v kiro &> /dev/null; then
    kiro --agent "$WRITER_AGENT" --print --message "$task_content" 2>&1 | tee "$STATE_DIR/writer-output.log"
  else
    # Fallback to ralph-loop if kiro not available
    ./.kiro/workflows/ralph-loop-v2.sh \
      --task "$task_content" \
      --agent "$WRITER_AGENT" \
      --max-iterations "$MAX_ITERATIONS"
  fi

  local writer_end=$(date +%s)
  local writer_duration=$((writer_end - writer_start))

  log "INFO" "Writer completed in ${writer_duration}s"
  echo ""
  echo -e "${GREEN}✓ Implementation phase complete${NC}"
  echo ""

  # Phase 2: Verification
  echo -e "${BLUE}Phase 2: Verification${NC}"
  echo "Running $VERIFIER_AGENT agent..."
  echo ""

  local verification_prompt
  verification_prompt=$(generate_verification_prompt "$task_content")

  local verifier_start=$(date +%s)

  # Run the verifier agent
  if command -v kiro &> /dev/null; then
    kiro --agent "$VERIFIER_AGENT" --print --message "$verification_prompt" 2>&1 | tee "$STATE_DIR/verifier-output.log"
  else
    echo "$verification_prompt" > "$STATE_DIR/verification-prompt.md"
    ./.kiro/workflows/ralph-loop-v2.sh \
      --task "$STATE_DIR/verification-prompt.md" \
      --agent "$VERIFIER_AGENT" \
      --max-iterations 5
  fi

  local verifier_end=$(date +%s)
  local verifier_duration=$((verifier_end - verifier_start))

  log "INFO" "Verifier completed in ${verifier_duration}s"

  # Check verification result
  local verification_result="UNKNOWN"
  if grep -q "VERIFICATION: PASS" "$STATE_DIR/verifier-output.log" 2>/dev/null; then
    verification_result="PASS"
  elif grep -q "VERIFICATION: FAIL" "$STATE_DIR/verifier-output.log" 2>/dev/null; then
    verification_result="FAIL"
  fi

  echo ""
  echo -e "${BLUE}=====================================${NC}"
  echo -e "${BLUE}  Results${NC}"
  echo -e "${BLUE}=====================================${NC}"
  echo ""
  echo "  Writer duration: ${writer_duration}s"
  echo "  Verifier duration: ${verifier_duration}s"
  echo "  Total duration: $((writer_duration + verifier_duration))s"
  echo ""

  if [ "$verification_result" = "PASS" ]; then
    echo -e "${GREEN}✓ VERIFICATION PASSED${NC}"
    log "INFO" "Verification PASSED"

    # Update memory bank if available
    if [ -f ".kiro/workflows/memory-bank.sh" ]; then
      ./.kiro/workflows/memory-bank.sh save progress "Completed: $(echo "$TASK" | head -c 50) (dual-verified)"
    fi

    echo ""
    echo "Implementation verified successfully."
    echo "Ready for: commit, merge, or further work."

  elif [ "$verification_result" = "FAIL" ]; then
    echo -e "${RED}✗ VERIFICATION FAILED${NC}"
    log "WARN" "Verification FAILED"

    echo ""
    echo "Issues found during verification."
    echo "See: $STATE_DIR/verifier-output.log"
    echo ""
    echo "Next steps:"
    echo "  1. Review the verification feedback"
    echo "  2. Fix the issues"
    echo "  3. Run dual-verify.sh again"

    if [ "$STRICT_MODE" = true ]; then
      exit 1
    fi

  else
    echo -e "${YELLOW}? VERIFICATION INCONCLUSIVE${NC}"
    log "WARN" "Verification result unclear"

    echo ""
    echo "Could not determine verification result."
    echo "Please review: $STATE_DIR/verifier-output.log"
  fi

  echo ""
  log "INFO" "Dual-verify workflow complete"
}

#===============================================================================
# RUN
#===============================================================================

main
