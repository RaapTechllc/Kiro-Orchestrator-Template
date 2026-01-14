#!/bin/bash
# dashboard.sh - Real-time agent activity dashboard
# Shows worktree status, agent progress, and metrics

set -e

PROJECT_NAME=$(basename "$(pwd)")
ACTIVITY_LOG="activity.log"
PROGRESS_FILE="PROGRESS.md"
METRICS_FILE=".kiro/metrics.csv"
REFRESH_INTERVAL=${1:-5}

#===============================================================================
# DISPLAY FUNCTIONS
#===============================================================================

clear_screen() {
  clear
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║           🎯 ORCHESTRATOR DASHBOARD - $PROJECT_NAME"
  echo "║           $(date '+%Y-%m-%d %H:%M:%S')"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
}

show_worktree_status() {
  echo "📁 GIT WORKTREES"
  echo "────────────────────────────────────────────────────────────────────"
  
  if ! git worktree list 2>/dev/null | grep -v "$(pwd)" | head -5; then
    echo "   No active worktrees (agents working in main directory)"
  fi
  echo ""
}

show_agent_status() {
  echo "🤖 AGENT STATUS"
  echo "────────────────────────────────────────────────────────────────────"
  
  if [ -d "agents" ]; then
    for agent_dir in agents/*/; do
      if [ -d "$agent_dir" ]; then
        local agent=$(basename "$agent_dir")
        local output_file="$agent_dir/output.log"
        local status="⏳ Running"
        
        if [ -f "$output_file" ]; then
          if grep -q "<promise>DONE</promise>" "$output_file" 2>/dev/null; then
            status="✅ Complete"
          elif grep -q "ERROR\|FAILED" "$output_file" 2>/dev/null; then
            status="❌ Error"
          fi
          
          local last_line=$(tail -1 "$output_file" 2>/dev/null | cut -c1-50)
          local mod_time=$(stat -c %Y "$output_file" 2>/dev/null || stat -f %m "$output_file" 2>/dev/null)
          local now=$(date +%s)
          local age=$(( (now - mod_time) / 60 ))
          
          printf "   %-20s %s (last update: %dm ago)\n" "$agent" "$status" "$age"
          [ -n "$last_line" ] && echo "      └─ $last_line..."
        fi
      fi
    done
  else
    echo "   No agents running"
  fi
  echo ""
}

show_recent_activity() {
  echo "📋 RECENT ACTIVITY"
  echo "────────────────────────────────────────────────────────────────────"
  
  if [ -f "$ACTIVITY_LOG" ]; then
    tail -8 "$ACTIVITY_LOG" | while read -r line; do
      echo "   $line"
    done
  else
    echo "   No activity logged yet"
  fi
  echo ""
}

show_progress() {
  echo "📊 PROGRESS"
  echo "────────────────────────────────────────────────────────────────────"
  
  if [ -f "$PROGRESS_FILE" ]; then
    # Count completed vs total tasks
    local completed=$(grep -c "\[x\]" "$PROGRESS_FILE" 2>/dev/null || echo 0)
    local total=$(grep -c "\[.\]" "$PROGRESS_FILE" 2>/dev/null || echo 0)
    
    if [ "$total" -gt 0 ]; then
      local pct=$((completed * 100 / total))
      local bar_len=$((pct / 2))
      local bar=$(printf '%*s' "$bar_len" | tr ' ' '█')
      local empty=$(printf '%*s' "$((50 - bar_len))" | tr ' ' '░')
      
      echo "   [$bar$empty] $pct% ($completed/$total tasks)"
    fi
    
    # Show current task
    local current=$(grep -m1 "\[ \]" "$PROGRESS_FILE" 2>/dev/null | head -1)
    [ -n "$current" ] && echo "   Current: $current"
  else
    echo "   No PROGRESS.md found"
  fi
  echo ""
}

show_metrics_summary() {
  echo "📈 SESSION METRICS"
  echo "────────────────────────────────────────────────────────────────────"
  
  if [ -f "$METRICS_FILE" ]; then
    local sessions=$(grep -c "session_start" "$METRICS_FILE" 2>/dev/null || echo 0)
    local iterations=$(tail -100 "$METRICS_FILE" | grep "iteration" | wc -l)
    local merges=$(grep -c "worktree_merged" "$METRICS_FILE" 2>/dev/null || echo 0)
    
    echo "   Sessions: $sessions | Iterations: $iterations | Merges: $merges"
  else
    echo "   No metrics collected yet"
  fi
  echo ""
}

show_circuit_breaker() {
  local cb_file=".kiro/.circuit_breaker"
  if [ -f "$cb_file" ]; then
    local state=$(grep -o '"state":"[^"]*"' "$cb_file" | cut -d'"' -f4)
    local failures=$(grep -o '"failures":[0-9]*' "$cb_file" | cut -d':' -f2)
    
    if [ "$state" = "open" ]; then
      echo "⚠️  CIRCUIT BREAKER: OPEN (failures: $failures)"
    elif [ "$state" = "half-open" ]; then
      echo "🔶 CIRCUIT BREAKER: HALF-OPEN (testing)"
    else
      echo "🟢 CIRCUIT BREAKER: CLOSED"
    fi
  fi
  echo ""
}

show_commands() {
  echo "────────────────────────────────────────────────────────────────────"
  echo "Commands: [q]uit | [r]efresh | [w]orktree status | [m]erge all"
  echo ""
}

#===============================================================================
# MAIN LOOP
#===============================================================================

run_dashboard() {
  while true; do
    clear_screen
    show_circuit_breaker
    show_worktree_status
    show_agent_status
    show_progress
    show_recent_activity
    show_metrics_summary
    show_commands
    
    # Wait for input or timeout
    read -t "$REFRESH_INTERVAL" -n 1 input 2>/dev/null || input=""
    
    case "$input" in
      q|Q) echo "Exiting dashboard..."; exit 0 ;;
      r|R) continue ;;
      w|W) ./.kiro/workflows/worktree-manager.sh status; read -p "Press Enter..." ;;
      m|M) 
        echo "Merging all completed worktrees..."
        for agent_dir in agents/*/; do
          agent=$(basename "$agent_dir")
          if grep -q "<promise>DONE</promise>" "$agent_dir/output.log" 2>/dev/null; then
            ./.kiro/workflows/worktree-manager.sh merge "$agent" || true
          fi
        done
        read -p "Press Enter..."
        ;;
    esac
  done
}

# Show help or run dashboard
case "${1:-}" in
  -h|--help)
    echo "Usage: dashboard.sh [refresh_interval]"
    echo ""
    echo "Real-time monitoring dashboard for orchestrator agents."
    echo ""
    echo "Options:"
    echo "  refresh_interval  Seconds between updates (default: 5)"
    echo ""
    echo "Interactive commands:"
    echo "  q - Quit dashboard"
    echo "  r - Force refresh"
    echo "  w - Show detailed worktree status"
    echo "  m - Merge all completed agent worktrees"
    ;;
  *)
    run_dashboard
    ;;
esac
