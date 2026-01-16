# Shards Integration - Technical Design

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ENHANCED DASHBOARD                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Health   │ │ Agents   │ │ Worktrees│ │ PRs/CI   │ │ Metrics  │  │
│  │ Monitor  │ │ Control  │ │ Status   │ │ Status   │ │ Summary  │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │
└───────┼────────────┼────────────┼────────────┼────────────┼─────────┘
        │            │            │            │            │
        ▼            ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      STATE LAYER (.kiro/state/)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ sessions/   │  │ health/     │  │ skills/     │                  │
│  │ <agent>.json│  │ <agent>.json│  │ registry.json│                 │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
        │            │            │
        ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION LAYER                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ ralph-kiro  │  │ health-     │  │ session-    │                  │
│  │ .sh         │  │ monitor.sh  │  │ manager.sh  │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      AGENT EXECUTION                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Agent 1 │  │ Agent 2 │  │ Agent 3 │  │  ...    │  │ Agent N │   │
│  │(worktree)│ │(worktree)│ │(worktree)│ │         │  │(worktree)│  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. Health Monitor (`health-monitor.sh`)

**Purpose:** Background process that checks agent health every N seconds.

**State File:** `.kiro/state/health/<agent>.json`
```json
{
  "agent": "code-surgeon",
  "status": "healthy",
  "last_heartbeat": "2026-01-15T21:00:00Z",
  "last_output_line": "Implementing auth module...",
  "stall_minutes": 0,
  "restart_count": 0,
  "pid": 12345,
  "worktree": "../.worktrees/project-code-surgeon"
}
```

**Status Values:**
- `healthy` - Active within threshold
- `stalled` - No activity > threshold
- `crashed` - Process not running
- `complete` - Finished successfully
- `failed` - Finished with error

**Health Check Logic:**
```bash
check_agent_health() {
  local agent=$1
  local output_file="agents/$agent/output.log"
  local threshold_sec=$((STALL_THRESHOLD_MINUTES * 60))
  
  # Check if output file exists
  if [ ! -f "$output_file" ]; then
    echo "crashed"
    return
  fi
  
  # Check completion
  if grep -q "<promise>DONE</promise>" "$output_file"; then
    echo "complete"
    return
  fi
  
  # Check for errors
  if grep -q "FATAL\|PANIC\|Traceback" "$output_file"; then
    echo "failed"
    return
  fi
  
  # Check staleness
  local mod_time=$(stat -c %Y "$output_file" 2>/dev/null)
  local now=$(date +%s)
  local age=$((now - mod_time))
  
  if [ $age -gt $threshold_sec ]; then
    echo "stalled"
  else
    echo "healthy"
  fi
}
```

### 2. Session Manager (`session-manager.sh`)

**Purpose:** Track agent sessions with full audit trail.

**Session File:** `.kiro/state/sessions/<agent>-<timestamp>.json`
```json
{
  "session_id": "code-surgeon-1705362000",
  "agent": "code-surgeon",
  "task": "Implement user authentication",
  "started_at": "2026-01-15T21:00:00Z",
  "ended_at": null,
  "status": "running",
  "iterations": 5,
  "tool_calls": 47,
  "errors": [],
  "checkpoints": [
    {"iteration": 3, "timestamp": "2026-01-15T21:15:00Z", "note": "Auth routes complete"}
  ],
  "worktree": {
    "path": "../.worktrees/project-code-surgeon",
    "branch": "agent/code-surgeon",
    "commits": 3
  },
  "metrics": {
    "files_created": 5,
    "files_modified": 12,
    "lines_added": 450,
    "lines_removed": 23
  }
}
```

**Commands:**
```bash
session-manager.sh start <agent> <task>    # Create new session
session-manager.sh update <agent> <field> <value>  # Update session
session-manager.sh end <agent> <status>    # Close session
session-manager.sh list [--active|--completed|--failed]
session-manager.sh resume <session-id>     # Resume interrupted session
session-manager.sh export <session-id>     # Export for analysis
```

### 3. Skill Registry

**Purpose:** Formalize agent capabilities for intelligent task routing.

**Registry File:** `.kiro/state/skills/registry.json`
```json
{
  "agents": {
    "code-surgeon": {
      "skills": ["refactoring", "debugging", "code-review", "typescript", "python"],
      "max_parallel": 3,
      "avg_task_minutes": 45,
      "success_rate": 0.92
    },
    "test-architect": {
      "skills": ["unit-testing", "integration-testing", "e2e-testing", "coverage"],
      "max_parallel": 2,
      "avg_task_minutes": 30,
      "success_rate": 0.95
    }
  },
  "skill_index": {
    "typescript": ["code-surgeon", "frontend-designer"],
    "security": ["security-specialist"],
    "testing": ["test-architect"]
  }
}
```

**Agent JSON Enhancement:**
```json
{
  "name": "code-surgeon",
  "skills": {
    "primary": ["refactoring", "debugging"],
    "secondary": ["typescript", "python", "code-review"],
    "avoid": ["deployment", "infrastructure"]
  }
}
```

### 4. Enhanced Dashboard

**New Sections:**

```
╔══════════════════════════════════════════════════════════════════╗
║           🎯 ORCHESTRATOR DASHBOARD - my-project                  ║
║           2026-01-15 21:54:19                                     ║
╚══════════════════════════════════════════════════════════════════╝

🔴 CIRCUIT BREAKER: CLOSED

🏥 AGENT HEALTH
────────────────────────────────────────────────────────────────────
  🟢 code-surgeon      healthy   iter:5   last:2m ago   [r]estart [s]top [l]ogs
  🟡 test-architect    stalled   iter:3   last:18m ago  [r]estart [s]top [l]ogs
  🟢 doc-smith         healthy   iter:7   last:1m ago   [r]estart [s]top [l]ogs
  ✅ security-spec     complete  iter:4   duration:23m  [l]ogs [m]erge
  ❌ frontend-design   failed    iter:2   error:timeout [r]etry [l]ogs

📁 WORKTREES & PRs
────────────────────────────────────────────────────────────────────
  agent/code-surgeon     +145 -23   No PR          [c]reate PR
  agent/test-architect   +67 -5     PR #42 ⏳ CI   [v]iew PR
  agent/doc-smith        +234 -12   PR #41 ✅      [m]erge
  agent/security-spec    +89 -34    PR #40 ✅      [m]erge

📊 SESSION METRICS (last 4h)
────────────────────────────────────────────────────────────────────
  Active: 3 | Complete: 2 | Failed: 1 | Stalled: 1
  Tool calls: 234 | Avg iteration: 4.2 | Success rate: 71%

────────────────────────────────────────────────────────────────────
[1-5] Select agent | [a]ll restart stalled | [M]erge all ready
[r]efresh | [q]uit | [?] help
```

**Keyboard Shortcuts:**
| Key | Action |
|-----|--------|
| 1-9 | Select agent by number |
| r | Restart selected/stalled agent |
| s | Stop selected agent |
| l | View agent logs (tail -f) |
| m | Merge selected agent's PR |
| M | Merge all approved PRs |
| c | Create PR for selected agent |
| a | Auto-restart all stalled agents |
| p | Show PR details |
| q | Quit dashboard |

### 5. Auto-Recovery System

**Restart Policy Configuration:**
```bash
# In ralph-kiro.sh or per-agent
RESTART_POLICY="once"  # never | once | always
MAX_RESTARTS=3
RESTART_DELAY_SECONDS=30
```

**Recovery Logic:**
```bash
handle_stalled_agent() {
  local agent=$1
  local health_file=".kiro/state/health/$agent.json"
  local restart_count=$(jq -r '.restart_count' "$health_file")
  
  case $RESTART_POLICY in
    never)
      log "WARN" "$agent stalled - manual intervention required"
      return 1
      ;;
    once)
      if [ "$restart_count" -ge 1 ]; then
        log "WARN" "$agent already restarted once - skipping"
        return 1
      fi
      ;;
    always)
      if [ "$restart_count" -ge "$MAX_RESTARTS" ]; then
        log "ERROR" "$agent hit max restarts ($MAX_RESTARTS)"
        return 1
      fi
      ;;
  esac
  
  # Check circuit breaker
  if ! check_circuit_breaker; then
    log "WARN" "Circuit breaker open - not restarting $agent"
    return 1
  fi
  
  # Perform restart
  log "INFO" "Restarting $agent (attempt $((restart_count + 1)))"
  restart_agent "$agent"
  
  # Update health state
  jq ".restart_count = $((restart_count + 1))" "$health_file" > /tmp/h.json
  mv /tmp/h.json "$health_file"
}
```

### 6. GitHub Integration

**PR Status Check:**
```bash
get_pr_status() {
  local branch=$1
  
  if ! command -v gh &> /dev/null; then
    echo "no-gh"
    return
  fi
  
  local pr_json=$(gh pr view "$branch" --json state,reviewDecision,statusCheckRollup 2>/dev/null)
  
  if [ -z "$pr_json" ]; then
    echo "no-pr"
    return
  fi
  
  local state=$(echo "$pr_json" | jq -r '.state')
  local review=$(echo "$pr_json" | jq -r '.reviewDecision')
  local ci=$(echo "$pr_json" | jq -r '.statusCheckRollup[0].conclusion // "pending"')
  
  echo "$state|$review|$ci"
}
```

## File Structure

```
.kiro/
├── state/
│   ├── health/
│   │   ├── code-surgeon.json
│   │   ├── test-architect.json
│   │   └── ...
│   ├── sessions/
│   │   ├── code-surgeon-1705362000.json
│   │   ├── code-surgeon-1705348000.json
│   │   └── ...
│   ├── skills/
│   │   └── registry.json
│   └── ralph-state.json (existing)
├── workflows/
│   ├── dashboard.sh (enhanced)
│   ├── health-monitor.sh (new)
│   ├── session-manager.sh (new)
│   ├── ralph-kiro.sh (enhanced)
│   └── ... (existing)
└── agents/
    ├── code-surgeon.json (enhanced with skills)
    └── ...
```

## Integration Points

### 1. ralph-kiro.sh Changes
- Call `session-manager.sh start` before agent launch
- Start `health-monitor.sh` as background process
- Call `session-manager.sh end` on completion
- Add `--restart-policy` flag

### 2. dashboard.sh Changes
- Import health data from `.kiro/state/health/`
- Add interactive agent control
- Add PR status display
- Add keyboard shortcuts

### 3. worktree-manager.sh Changes
- Track commits in session
- Add `--create-pr` flag
- Add `--check-ci` flag

## Migration Path

1. **Phase 1:** Add state directory structure + health monitor
2. **Phase 2:** Enhance dashboard with health display
3. **Phase 3:** Add session tracking
4. **Phase 4:** Add auto-recovery
5. **Phase 5:** Add GitHub integration
6. **Phase 6:** Add skill registry

Each phase is independently deployable and backward compatible.
