#!/bin/bash
# worktree-manager.sh - Git worktree isolation for parallel agent development
# Creates isolated workspaces for each agent, manages branches, validates, and merges

set -e

#===============================================================================
# CONFIGURATION
#===============================================================================

PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../.worktrees"
MAIN_BRANCH=${MAIN_BRANCH:-"main"}
ACTIVITY_LOG="activity.log"
METRICS_FILE=".kiro/metrics.csv"
ROLLBACK_FILE=".kiro/state/rollback-stack.json"
ENABLE_METRICS=${ENABLE_METRICS:-true}
AUTO_COMMIT=${AUTO_COMMIT:-true}
VALIDATE_BEFORE_MERGE=${VALIDATE_BEFORE_MERGE:-true}
VALIDATION_COMMAND=${VALIDATION_COMMAND:-""}

#===============================================================================
# PARSE COMMAND LINE ARGUMENTS
#===============================================================================

show_help() {
  cat << EOF
Usage: worktree-manager.sh <command> [options]

Git worktree manager for isolated parallel agent development.

COMMANDS:
  create <name> [branch]    Create new worktree for agent
  list                      List all active worktrees
  status                    Show status of all worktrees
  validate <name>           Run validation in worktree
  commit <name> [message]   Commit changes in worktree
  merge <name>              Merge worktree branch to main
  rollback                  Undo the last merge
  rollback-list             Show merge history (rollback stack)
  cleanup <name>            Remove worktree and branch
  cleanup-all               Remove all worktrees

OPTIONS:
  --base=PATH               Worktree base directory (default: ../.worktrees)
  --main=BRANCH             Main branch name (default: main)
  --validate=CMD            Validation command before merge
  --no-validate             Skip validation before merge
  --no-metrics              Disable metrics tracking
  -h, --help                Show this help message
EOF
}

COMMAND=""
WORKTREE_NAME=""
BRANCH_NAME=""
COMMIT_MSG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    create|list|status|validate|commit|merge|rollback|rollback-list|cleanup|cleanup-all)
      COMMAND="$1"
      shift
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        WORKTREE_NAME="$1"
        shift
      fi
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        BRANCH_NAME="$1"
        shift
      fi
      ;;
    --base=*) WORKTREE_BASE="${1#*=}"; shift ;;
    --main=*) MAIN_BRANCH="${1#*=}"; shift ;;
    --validate=*) VALIDATION_COMMAND="${1#*=}"; shift ;;
    --no-validate) VALIDATE_BEFORE_MERGE=false; shift ;;
    --no-metrics) ENABLE_METRICS=false; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) COMMIT_MSG="$1"; shift ;;
  esac
done

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

SESSION_ID=$(date +%s)

log() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message"
  echo "$timestamp: [Worktree] $message" >> "$ACTIVITY_LOG"
}

log_metric() {
  if [ "$ENABLE_METRICS" = true ]; then
    echo "$(date -Iseconds),$1,$2,worktree,$SESSION_ID" >> "$METRICS_FILE"
  fi
}

get_worktree_path() {
  local name=$1
  echo "$WORKTREE_BASE/$PROJECT_NAME-$name"
}

get_branch_name() {
  local name=$1
  echo "agent/$name"
}

#===============================================================================
# ROLLBACK OPERATIONS
#===============================================================================

init_rollback_file() {
  if [ ! -f "$ROLLBACK_FILE" ]; then
    mkdir -p "$(dirname "$ROLLBACK_FILE")"
    echo '{"merges":[]}' > "$ROLLBACK_FILE"
  fi
}

save_rollback_point() {
  local name=$1
  local branch=$2
  local pre_merge_head=$3
  local merge_commit=$4
  local timestamp=$(date -Iseconds)

  init_rollback_file

  # Create JSON entry (bash-friendly approach)
  local temp_file=$(mktemp)

  # Read existing file, add new entry
  if command -v jq &> /dev/null; then
    jq --arg name "$name" \
       --arg branch "$branch" \
       --arg pre_head "$pre_merge_head" \
       --arg merge_commit "$merge_commit" \
       --arg ts "$timestamp" \
       '.merges = [{"name": $name, "branch": $branch, "pre_merge_head": $pre_head, "merge_commit": $merge_commit, "timestamp": $ts}] + .merges' \
       "$ROLLBACK_FILE" > "$temp_file" && mv "$temp_file" "$ROLLBACK_FILE"
  else
    # Fallback without jq - simpler format
    echo "{\"name\":\"$name\",\"branch\":\"$branch\",\"pre_merge_head\":\"$pre_merge_head\",\"merge_commit\":\"$merge_commit\",\"timestamp\":\"$timestamp\"}" >> "$ROLLBACK_FILE.log"
    log "INFO" "Rollback point saved (jq not available, using log format)"
  fi

  log "INFO" "Rollback point saved: $name ($pre_merge_head -> $merge_commit)"
}

rollback_last_merge() {
  init_rollback_file

  local last_entry=""
  local pre_merge_head=""
  local merge_commit=""
  local name=""

  if command -v jq &> /dev/null; then
    last_entry=$(jq -r '.merges[0] // empty' "$ROLLBACK_FILE" 2>/dev/null)
    if [ -z "$last_entry" ]; then
      echo "❌ No merges to rollback"
      return 1
    fi

    pre_merge_head=$(echo "$last_entry" | jq -r '.pre_merge_head')
    merge_commit=$(echo "$last_entry" | jq -r '.merge_commit')
    name=$(echo "$last_entry" | jq -r '.name')
  else
    # Fallback - read from log file
    if [ -f "$ROLLBACK_FILE.log" ]; then
      last_entry=$(tail -1 "$ROLLBACK_FILE.log")
      pre_merge_head=$(echo "$last_entry" | grep -o '"pre_merge_head":"[^"]*"' | cut -d'"' -f4)
      merge_commit=$(echo "$last_entry" | grep -o '"merge_commit":"[^"]*"' | cut -d'"' -f4)
      name=$(echo "$last_entry" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    else
      echo "❌ No merges to rollback"
      return 1
    fi
  fi

  if [ -z "$pre_merge_head" ]; then
    echo "❌ No merges to rollback"
    return 1
  fi

  echo "⚠️  About to rollback merge:"
  echo "   Agent: $name"
  echo "   Merge commit: $merge_commit"
  echo "   Will reset to: $pre_merge_head"
  echo ""
  echo "This will:"
  echo "   - Reset $MAIN_BRANCH to pre-merge state"
  echo "   - Keep the agent branch intact for re-merge"
  echo ""
  read -p "Continue? [y/N] " confirm

  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Rollback cancelled"
    return 0
  fi

  # Ensure we're on main branch
  git checkout "$MAIN_BRANCH"

  # Reset to pre-merge state
  git reset --hard "$pre_merge_head"

  log "INFO" "Rolled back merge: $name ($merge_commit -> $pre_merge_head)"
  log_metric "worktree_rollback" "$name"

  # Remove entry from rollback stack
  if command -v jq &> /dev/null; then
    jq 'del(.merges[0])' "$ROLLBACK_FILE" > "$ROLLBACK_FILE.tmp" && mv "$ROLLBACK_FILE.tmp" "$ROLLBACK_FILE"
  else
    # Remove last line from log
    head -n -1 "$ROLLBACK_FILE.log" > "$ROLLBACK_FILE.log.tmp" && mv "$ROLLBACK_FILE.log.tmp" "$ROLLBACK_FILE.log"
  fi

  echo "✅ Rolled back merge for '$name'"
  echo "   $MAIN_BRANCH is now at: $pre_merge_head"
  echo ""
  echo "The agent branch 'agent/$name' is still available."
  echo "To re-merge after fixes: worktree-manager.sh merge $name"
}

list_rollback_history() {
  init_rollback_file

  echo "Merge History (Rollback Stack)"
  echo "=============================="
  echo ""

  if command -v jq &> /dev/null; then
    local count=$(jq '.merges | length' "$ROLLBACK_FILE" 2>/dev/null || echo "0")

    if [ "$count" -eq 0 ]; then
      echo "No merges recorded."
      return 0
    fi

    echo "Most recent first:"
    echo ""
    jq -r '.merges[] | "[\(.timestamp)] \(.name)\n   Branch: \(.branch)\n   Pre-merge: \(.pre_merge_head | .[0:8])\n   Merge commit: \(.merge_commit | .[0:8])\n"' "$ROLLBACK_FILE" 2>/dev/null
  else
    if [ -f "$ROLLBACK_FILE.log" ]; then
      echo "Most recent first:"
      echo ""
      tac "$ROLLBACK_FILE.log" 2>/dev/null | head -10 | while read -r line; do
        local name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        local ts=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local pre=$(echo "$line" | grep -o '"pre_merge_head":"[^"]*"' | cut -d'"' -f4 | cut -c1-8)
        local merge=$(echo "$line" | grep -o '"merge_commit":"[^"]*"' | cut -d'"' -f4 | cut -c1-8)
        echo "[$ts] $name"
        echo "   Pre-merge: $pre  Merge: $merge"
        echo ""
      done
    else
      echo "No merges recorded."
    fi
  fi
}

#===============================================================================
# WORKTREE OPERATIONS
#===============================================================================

create_worktree() {
  local name=$1
  local branch=${2:-$(get_branch_name "$name")}
  local worktree_path=$(get_worktree_path "$name")
  
  if [ -d "$worktree_path" ]; then
    log "WARN" "Worktree already exists: $worktree_path"
    echo "Worktree '$name' already exists at $worktree_path"
    return 1
  fi
  
  log "INFO" "Creating worktree: $name (branch: $branch)"
  
  # Create base directory if needed
  mkdir -p "$WORKTREE_BASE"
  
  # Create worktree with new branch from main
  git worktree add -b "$branch" "$worktree_path" "$MAIN_BRANCH" 2>/dev/null || \
  git worktree add "$worktree_path" "$branch" 2>/dev/null || {
    log "ERROR" "Failed to create worktree"
    return 1
  }
  
  # Create context file for the agent
  cat > "$worktree_path/.agent-context" << EOF
# Agent Worktree Context
AGENT_NAME=$name
BRANCH=$branch
CREATED=$(date -Iseconds)
MAIN_BRANCH=$MAIN_BRANCH
PROJECT=$PROJECT_NAME

# Instructions for agent:
# - Work only in this directory
# - Commit frequently with descriptive messages
# - Run validation before signaling completion
EOF
  
  log "INFO" "Worktree created: $worktree_path"
  log_metric "worktree_created" "$name"
  
  echo "✅ Created worktree '$name'"
  echo "   Path: $worktree_path"
  echo "   Branch: $branch"
  echo ""
  echo "To start agent in this worktree:"
  echo "   cd $worktree_path && kiro-cli --agent $name"
}

list_worktrees() {
  echo "Active Worktrees for $PROJECT_NAME:"
  echo "======================================"
  git worktree list | while read -r line; do
    echo "  $line"
  done
  echo ""
}

status_worktrees() {
  echo "Worktree Status for $PROJECT_NAME"
  echo "======================================"
  
  git worktree list --porcelain | while read -r line; do
    if [[ "$line" =~ ^worktree ]]; then
      local path="${line#worktree }"
      local name=$(basename "$path")
      
      if [ -d "$path" ]; then
        cd "$path" 2>/dev/null || continue
        local branch=$(git branch --show-current 2>/dev/null)
        local changes=$(git status --porcelain 2>/dev/null | wc -l)
        local ahead=$(git rev-list --count "$MAIN_BRANCH..$branch" 2>/dev/null || echo "0")
        
        echo ""
        echo "📁 $name"
        echo "   Branch: $branch"
        echo "   Uncommitted changes: $changes"
        echo "   Commits ahead of $MAIN_BRANCH: $ahead"
        
        if [ -f ".agent-context" ]; then
          local created=$(grep "CREATED=" .agent-context | cut -d= -f2)
          echo "   Created: $created"
        fi
        cd - > /dev/null
      fi
    fi
  done
  echo ""
}

validate_worktree() {
  local name=$1
  local worktree_path=$(get_worktree_path "$name")
  
  if [ ! -d "$worktree_path" ]; then
    log "ERROR" "Worktree not found: $name"
    return 1
  fi
  
  log "INFO" "Validating worktree: $name"
  cd "$worktree_path"
  
  local validation_passed=true
  
  # Run custom validation if specified
  if [ -n "$VALIDATION_COMMAND" ]; then
    echo "Running: $VALIDATION_COMMAND"
    if ! eval "$VALIDATION_COMMAND"; then
      validation_passed=false
    fi
  fi
  
  # Check for common validation commands
  if [ -f "package.json" ]; then
    if grep -q '"lint"' package.json; then
      echo "Running: npm run lint"
      npm run lint --silent 2>/dev/null || validation_passed=false
    fi
    if grep -q '"typecheck"' package.json; then
      echo "Running: npm run typecheck"
      npm run typecheck --silent 2>/dev/null || validation_passed=false
    fi
    if grep -q '"test"' package.json; then
      echo "Running: npm test"
      npm test --silent 2>/dev/null || validation_passed=false
    fi
  fi
  
  cd - > /dev/null
  
  if $validation_passed; then
    log "INFO" "Validation passed: $name"
    echo "✅ Validation passed"
    return 0
  else
    log "WARN" "Validation failed: $name"
    echo "❌ Validation failed"
    return 1
  fi
}

commit_worktree() {
  local name=$1
  local message=${2:-"Agent $name: Work completed"}
  local worktree_path=$(get_worktree_path "$name")
  
  if [ ! -d "$worktree_path" ]; then
    log "ERROR" "Worktree not found: $name"
    return 1
  fi
  
  cd "$worktree_path"
  
  # Check for changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit in $name"
    cd - > /dev/null
    return 0
  fi
  
  log "INFO" "Committing changes in: $name"
  
  git add -A
  git commit -m "$message"
  
  log "INFO" "Committed: $name"
  log_metric "worktree_commit" "$name"
  
  cd - > /dev/null
  echo "✅ Committed changes in '$name'"
}

merge_worktree() {
  local name=$1
  local worktree_path=$(get_worktree_path "$name")
  local branch=$(get_branch_name "$name")
  
  if [ ! -d "$worktree_path" ]; then
    log "ERROR" "Worktree not found: $name"
    return 1
  fi
  
  # Validate before merge if enabled
  if [ "$VALIDATE_BEFORE_MERGE" = true ]; then
    echo "Running validation before merge..."
    if ! validate_worktree "$name"; then
      log "ERROR" "Validation failed - merge aborted"
      echo "❌ Merge aborted: validation failed"
      echo "   Fix issues and try again, or use --no-validate"
      return 1
    fi
  fi
  
  # Commit any uncommitted changes
  cd "$worktree_path"
  if [ -n "$(git status --porcelain)" ]; then
    log "INFO" "Auto-committing uncommitted changes"
    git add -A
    git commit -m "Agent $name: Final changes before merge"
  fi
  cd - > /dev/null
  
  log "INFO" "Merging $branch into $MAIN_BRANCH"

  # Switch to main and merge
  git checkout "$MAIN_BRANCH"

  # Save pre-merge state for rollback
  local pre_merge_head=$(git rev-parse HEAD)

  if git merge "$branch" --no-ff -m "Merge agent/$name: Completed work"; then
    local merge_commit=$(git rev-parse HEAD)

    # Save rollback point
    save_rollback_point "$name" "$branch" "$pre_merge_head" "$merge_commit"

    log "INFO" "Merge successful: $name"
    log_metric "worktree_merged" "$name"
    echo "✅ Merged '$name' into $MAIN_BRANCH"
    echo "   Rollback available: worktree-manager.sh rollback"
    return 0
  else
    log "ERROR" "Merge conflict in: $name"
    echo "❌ Merge conflict detected"
    echo "   Resolve conflicts manually, then run:"
    echo "   git add . && git commit"
    return 1
  fi
}

cleanup_worktree() {
  local name=$1
  local worktree_path=$(get_worktree_path "$name")
  local branch=$(get_branch_name "$name")
  
  if [ ! -d "$worktree_path" ]; then
    log "WARN" "Worktree not found: $name"
    return 0
  fi
  
  log "INFO" "Cleaning up worktree: $name"
  
  # Remove worktree
  git worktree remove "$worktree_path" --force 2>/dev/null || {
    rm -rf "$worktree_path"
    git worktree prune
  }
  
  # Delete branch if it exists and is merged
  if git branch --list "$branch" | grep -q "$branch"; then
    git branch -d "$branch" 2>/dev/null || \
    git branch -D "$branch" 2>/dev/null || true
  fi
  
  log "INFO" "Cleaned up: $name"
  log_metric "worktree_cleanup" "$name"
  
  echo "✅ Cleaned up worktree '$name'"
}

cleanup_all_worktrees() {
  echo "Cleaning up all worktrees..."
  
  git worktree list --porcelain | grep "^worktree " | while read -r line; do
    local path="${line#worktree }"
    if [[ "$path" == *"$WORKTREE_BASE"* ]]; then
      local name=$(basename "$path" | sed "s/$PROJECT_NAME-//")
      cleanup_worktree "$name"
    fi
  done
  
  # Prune any stale worktrees
  git worktree prune
  
  echo "✅ All worktrees cleaned up"
}

#===============================================================================
# MAIN
#===============================================================================

case "$COMMAND" in
  create)
    [ -z "$WORKTREE_NAME" ] && { echo "Error: name required"; show_help; exit 1; }
    create_worktree "$WORKTREE_NAME" "$BRANCH_NAME"
    ;;
  list)
    list_worktrees
    ;;
  status)
    status_worktrees
    ;;
  validate)
    [ -z "$WORKTREE_NAME" ] && { echo "Error: name required"; exit 1; }
    validate_worktree "$WORKTREE_NAME"
    ;;
  commit)
    [ -z "$WORKTREE_NAME" ] && { echo "Error: name required"; exit 1; }
    commit_worktree "$WORKTREE_NAME" "$COMMIT_MSG"
    ;;
  merge)
    [ -z "$WORKTREE_NAME" ] && { echo "Error: name required"; exit 1; }
    merge_worktree "$WORKTREE_NAME"
    ;;
  rollback)
    rollback_last_merge
    ;;
  rollback-list)
    list_rollback_history
    ;;
  cleanup)
    [ -z "$WORKTREE_NAME" ] && { echo "Error: name required"; exit 1; }
    cleanup_worktree "$WORKTREE_NAME"
    ;;
  cleanup-all)
    cleanup_all_worktrees
    ;;
  *)
    show_help
    exit 1
    ;;
esac
