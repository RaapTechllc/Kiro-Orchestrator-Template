#!/bin/bash
# .kiro/workflows/memory-bank.sh
#
# Memory Bank System - Persistent context across sessions
#
# Commands:
#   load [type]     - Load memory context (all, active, progress, decisions, patterns)
#   save <type>     - Save/update a memory file
#   handoff         - Generate session handoff prompt
#   archive         - Archive current session
#   status          - Show memory bank status

set -e

MEMORY_DIR=".kiro/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
HANDOFFS_DIR="$MEMORY_DIR/handoffs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

ensure_dirs() {
  mkdir -p "$SESSIONS_DIR" "$HANDOFFS_DIR"
}

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

datestamp() {
  date +"%Y-%m-%d"
}

session_id() {
  date +"%Y%m%d-%H%M%S"
}

# ============================================================================
# Commands
# ============================================================================

cmd_load() {
  local type="${1:-all}"

  case $type in
    all)
      echo -e "${BLUE}=== Active Context ===${NC}"
      cat "$MEMORY_DIR/activeContext.md" 2>/dev/null || echo "No active context"
      echo ""
      echo -e "${BLUE}=== Recent Progress ===${NC}"
      head -30 "$MEMORY_DIR/progress.md" 2>/dev/null || echo "No progress log"
      echo ""
      echo -e "${BLUE}=== Key Decisions ===${NC}"
      head -30 "$MEMORY_DIR/decisions.md" 2>/dev/null || echo "No decisions log"
      ;;
    active)
      cat "$MEMORY_DIR/activeContext.md" 2>/dev/null || echo "No active context"
      ;;
    progress)
      cat "$MEMORY_DIR/progress.md" 2>/dev/null || echo "No progress log"
      ;;
    decisions)
      cat "$MEMORY_DIR/decisions.md" 2>/dev/null || echo "No decisions log"
      ;;
    patterns)
      cat "$MEMORY_DIR/patterns.md" 2>/dev/null || echo "No patterns log"
      ;;
    *)
      echo "Unknown type: $type"
      echo "Valid types: all, active, progress, decisions, patterns"
      exit 1
      ;;
  esac
}

cmd_save() {
  local type="$1"
  shift
  local content="$*"

  if [ -z "$type" ]; then
    echo "Usage: memory-bank.sh save <type> <content>"
    echo "Types: active, progress, decision, pattern"
    exit 1
  fi

  case $type in
    active)
      # Update activeContext.md with new focus
      cat > "$MEMORY_DIR/activeContext.md" << EOF
# Active Context

> Current focus. Updated frequently during sessions. Keep small and focused.

## What I'm Working On

$content

## Current Files

_Update as you work_

## Key Decisions Made This Session

_Add decisions here_

## Blockers / Questions

_None_

---
*Last updated: $(timestamp)*
EOF
      echo -e "${GREEN}Updated active context${NC}"
      ;;

    progress)
      # Append to progress.md
      local temp_file=$(mktemp)
      local date=$(datestamp)
      local session=$(session_id)

      # Read existing content
      if [ -f "$MEMORY_DIR/progress.md" ]; then
        # Insert new entry after the table header
        awk -v date="$date" -v session="$session" -v content="$content" '
          /^\| Date / { print; getline; print; print "| " date " | " session " | " content " |"; next }
          { print }
        ' "$MEMORY_DIR/progress.md" > "$temp_file"
        mv "$temp_file" "$MEMORY_DIR/progress.md"
      fi
      echo -e "${GREEN}Added progress entry${NC}"
      ;;

    decision)
      # Append to decisions.md
      echo -e "${YELLOW}Opening decisions.md for editing...${NC}"
      echo "Add your decision to the appropriate section:"
      echo "  Architecture Decisions | Technology Choices | Design Decisions"
      echo ""
      echo "Entry format: | Decision | Rationale | $(datestamp) | Yes/No |"
      ;;

    pattern)
      # Append to patterns.md
      echo -e "${YELLOW}Opening patterns.md for editing...${NC}"
      echo "Add your pattern to the appropriate section"
      ;;

    *)
      echo "Unknown type: $type"
      echo "Valid types: active, progress, decision, pattern"
      exit 1
      ;;
  esac
}

cmd_handoff() {
  local handoff_file="$HANDOFFS_DIR/handoff-$(session_id).md"

  # Generate handoff prompt
  cat > "$handoff_file" << EOF
# Session Handoff: $(datestamp)

## Context

$(cat "$MEMORY_DIR/activeContext.md" 2>/dev/null | grep -A 20 "## What I'm Working On" | head -20)

## Completed This Session

$(cat "$MEMORY_DIR/progress.md" 2>/dev/null | grep "$(datestamp)" | head -10 || echo "No entries for today")

## Key Decisions Made

$(cat "$MEMORY_DIR/decisions.md" 2>/dev/null | grep "$(datestamp)" | head -10 || echo "No decisions recorded today")

## Current State

### Git Status
\`\`\`
$(git status --short 2>/dev/null || echo "Not a git repository")
\`\`\`

### Recent Commits
\`\`\`
$(git log --oneline -5 2>/dev/null || echo "No commits")
\`\`\`

## Files Modified

$(git diff --name-only 2>/dev/null | head -20 || echo "None")

## Next Steps

_To be filled in before handoff_

## Blockers / Questions

_To be filled in before handoff_

---
*Generated: $(timestamp)*
EOF

  echo -e "${GREEN}Handoff generated: $handoff_file${NC}"
  echo ""
  echo "Edit the file to add Next Steps and Blockers before sharing."
  cat "$handoff_file"
}

cmd_archive() {
  local archive_file="$SESSIONS_DIR/session-$(session_id).md"

  # Create session archive
  cat > "$archive_file" << EOF
# Session Archive: $(timestamp)

## Active Context at End of Session

$(cat "$MEMORY_DIR/activeContext.md" 2>/dev/null)

## Progress Made

$(cat "$MEMORY_DIR/progress.md" 2>/dev/null | grep "$(datestamp)" || echo "No entries for today")

## Decisions Made

$(cat "$MEMORY_DIR/decisions.md" 2>/dev/null | grep "$(datestamp)" || echo "No decisions recorded today")

## Git State

### Status
\`\`\`
$(git status 2>/dev/null || echo "Not a git repository")
\`\`\`

### Diff Summary
\`\`\`
$(git diff --stat 2>/dev/null || echo "No changes")
\`\`\`

---
*Archived: $(timestamp)*
EOF

  echo -e "${GREEN}Session archived: $archive_file${NC}"

  # Reset active context
  cat > "$MEMORY_DIR/activeContext.md" << EOF
# Active Context

> Current focus. Updated frequently during sessions. Keep small and focused.

## What I'm Working On

_No active task_

## Current Files

_None loaded_

## Key Decisions Made This Session

_None yet_

## Blockers / Questions

_None_

---
*Last updated: $(timestamp)*
EOF

  echo -e "${YELLOW}Active context has been reset${NC}"
}

cmd_status() {
  echo -e "${BLUE}=== Memory Bank Status ===${NC}"
  echo ""

  # Active context
  if [ -f "$MEMORY_DIR/activeContext.md" ]; then
    local active_updated=$(grep "Last updated:" "$MEMORY_DIR/activeContext.md" | head -1)
    echo -e "Active Context: ${GREEN}exists${NC} ($active_updated)"
  else
    echo -e "Active Context: ${RED}missing${NC}"
  fi

  # Progress entries
  local progress_count=$(grep -c "^|" "$MEMORY_DIR/progress.md" 2>/dev/null || echo "0")
  echo -e "Progress Entries: ${GREEN}$progress_count${NC}"

  # Decision entries
  local decision_count=$(grep -c "^|" "$MEMORY_DIR/decisions.md" 2>/dev/null || echo "0")
  echo -e "Decision Entries: ${GREEN}$decision_count${NC}"

  # Session archives
  local session_count=$(ls -1 "$SESSIONS_DIR"/*.md 2>/dev/null | wc -l || echo "0")
  echo -e "Session Archives: ${GREEN}$session_count${NC}"

  # Handoffs
  local handoff_count=$(ls -1 "$HANDOFFS_DIR"/*.md 2>/dev/null | wc -l || echo "0")
  echo -e "Handoff Files: ${GREEN}$handoff_count${NC}"
}

cmd_help() {
  echo "Memory Bank - Persistent context across sessions"
  echo ""
  echo "Usage: memory-bank.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  load [type]        Load memory context (all, active, progress, decisions, patterns)"
  echo "  save <type> <msg>  Save/update a memory file (active, progress, decision, pattern)"
  echo "  handoff            Generate session handoff prompt"
  echo "  archive            Archive current session and reset active context"
  echo "  status             Show memory bank status"
  echo "  help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  memory-bank.sh load active"
  echo "  memory-bank.sh save active 'Working on user authentication feature'"
  echo "  memory-bank.sh save progress 'Completed login form implementation'"
  echo "  memory-bank.sh handoff"
  echo "  memory-bank.sh archive"
}

# ============================================================================
# Main
# ============================================================================

ensure_dirs

case "${1:-help}" in
  load)
    shift
    cmd_load "$@"
    ;;
  save)
    shift
    cmd_save "$@"
    ;;
  handoff)
    cmd_handoff
    ;;
  archive)
    cmd_archive
    ;;
  status)
    cmd_status
    ;;
  help|--help|-h)
    cmd_help
    ;;
  *)
    echo "Unknown command: $1"
    cmd_help
    exit 1
    ;;
esac
