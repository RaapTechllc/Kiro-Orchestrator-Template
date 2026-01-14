# Kiro Orchestrator Improvement Plan

Roadmap for enhancing the agent system based on Thread-Based Engineering principles.

## Current State Assessment

| Thread Type | Status | Implementation |
|-------------|--------|----------------|
| Base Thread | **Complete** | SPEC workflow in orchestrator |
| P-Thread | **Complete** | ralph-kiro.sh (5 parallel agents) |
| C-Thread | **Partial** | Ralph Loop iterations |
| F-Thread | **Missing** | No fusion capability |
| B-Thread | **Partial** | Orchestrator delegates but shallow |
| L-Thread | **Partial** | Limited to ~50 iterations |

## Phase 1: Enhance P-Threads (High Priority)

**Goal**: Scale parallel compute from 5 to 10-15 agents dynamically.

### Tasks
- [ ] Add `--parallel=N` flag to ralph-kiro.sh
- [ ] Implement resource monitoring (prevent overload)
- [ ] Add agent pooling (reuse completed agents)
- [ ] Create parallel efficiency metrics

### Implementation
```bash
# Enhanced ralph-kiro.sh
PARALLEL_COUNT=${1:-5}  # Default 5, configurable

for i in $(seq 1 $PARALLEL_COUNT); do
  run_agent_loop "agent-$i" &
done
```

### Success Criteria
- Can run 10+ parallel agents without system strain
- 50% faster completion for multi-agent tasks
- Metrics show parallel efficiency ratio

---

## Phase 2: Implement F-Threads (High Priority)

**Goal**: Add fusion capabilities for result consolidation and confidence.

### Tasks
- [ ] Create `workflows/fusion.sh` script
- [ ] Implement majority-vote fusion for reviews
- [ ] Implement best-of-N selection for prototyping
- [ ] Add merge mode for combining ideas
- [ ] Integrate with RBT for validation

### Implementation
```bash
# workflows/fusion.sh
MODE=${1:-"majority"}  # majority, best, merge

case $MODE in
  majority)
    # Count consensus across agent outputs
    ;;
  best)
    # Score and select highest quality
    ;;
  merge)
    # Combine unique elements from all
    ;;
esac
```

### Success Criteria
- Can run 3-5 agents on same task and fuse results
- Confidence score increases with agent agreement
- Prototyping speed 3x faster with best-of-N

---

## Phase 3: Add C-Threads (Medium Priority)

**Goal**: Enable multi-phase workflows with human checkpoints.

### Tasks
- [ ] Create `workflows/chain-workflow.sh`
- [ ] Add `<promise>CHECKPOINT</promise>` signal
- [ ] Implement pause/resume functionality
- [ ] Add system notifications for phase completion
- [ ] Create phase templates for common workflows

### Implementation
```bash
# workflows/chain-workflow.sh
PHASES=("requirements" "design" "implement" "test" "deploy")

for phase in "${PHASES[@]}"; do
  echo "Starting phase: $phase"
  run_phase "$phase"
  
  if grep -q "<promise>CHECKPOINT</promise>" output.log; then
    notify-send "Phase $phase complete - Review required"
    read -p "Press Enter to continue to next phase..."
  fi
done
```

### Success Criteria
- Can pause between phases for human review
- Notifications work on Windows/Mac/Linux
- Resume doesn't lose context

---

## Phase 4: Develop B-Threads (Medium Priority)

**Goal**: Make orchestrator a true meta-thread manager with nested composition.

### Tasks
- [ ] Enhance orchestrator to spawn "thread teams"
- [ ] Add sub-orchestrators (e.g., security-orchestrator)
- [ ] Implement recursive spawning (agents spawn agents)
- [ ] Create thread composition DSL
- [ ] Add B-thread visualization

### Implementation
```json
// Enhanced ralph-master.json
{
  "thread_composition": {
    "type": "B-thread",
    "children": [
      {
        "type": "P-thread",
        "agents": ["security-specialist", "test-architect"]
      },
      {
        "type": "F-thread",
        "fusion_mode": "best"
      }
    ]
  }
}
```

### Success Criteria
- Orchestrator can manage nested thread structures
- Sub-orchestrators work independently
- Total tool calls increase 5x with composition

---

## Phase 5: Extend L-Threads (Medium Priority)

**Goal**: Enable hours/days-long autonomous runs with self-validation.

### Tasks
- [ ] Add "long mode" to Ralph Loop (remove fixed iterations)
- [ ] Implement stop hooks for validation
- [ ] Add background verification agents
- [ ] Create checkpoint/resume for long runs
- [ ] Add timeout and safety limits

### Implementation
```bash
# Long-running mode
MAX_DURATION=${1:-"4h"}  # Default 4 hours
VALIDATE_INTERVAL="30m"  # Check every 30 minutes

while ! is_complete; do
  run_iteration
  
  if time_elapsed > $VALIDATE_INTERVAL; then
    run_background_validator
    reset_timer
  fi
  
  if time_elapsed > $MAX_DURATION; then
    echo "Max duration reached, pausing for review"
    break
  fi
done
```

### Success Criteria
- Agents can run 4+ hours autonomously
- Self-validation catches 90% of errors
- Checkpoint/resume works across sessions

---

## Phase 6: Add Metrics Tracking (Low Priority)

**Goal**: Quantify improvement with tool call and thread metrics.

### Tasks
- [ ] Create `workflows/metrics-tracker.sh`
- [ ] Track: tool calls, duration, parallel count, success rate
- [ ] Add dashboard script for visualization
- [ ] Integrate with PROGRESS.md
- [ ] Create weekly improvement reports

### Implementation
```bash
# workflows/metrics-tracker.sh
log_metric() {
  local metric=$1
  local value=$2
  echo "$(date),$metric,$value" >> .kiro/metrics.csv
}

# Track during execution
log_metric "tool_calls" $TOOL_COUNT
log_metric "duration" $DURATION
log_metric "parallel_agents" $PARALLEL_COUNT
log_metric "success_rate" $SUCCESS_RATE
```

### Success Criteria
- CSV log captures all key metrics
- Dashboard shows trends over time
- Can prove improvement week-over-week

---

## Timeline

| Phase | Priority | Estimated Time | Dependencies |
|-------|----------|----------------|--------------|
| Phase 1 (P-threads) | High | 2-3 days | None |
| Phase 2 (F-threads) | High | 3-4 days | None |
| Phase 3 (C-threads) | Medium | 2-3 days | None |
| Phase 4 (B-threads) | Medium | 4-5 days | Phases 1-2 |
| Phase 5 (L-threads) | Medium | 3-4 days | Phases 1-3 |
| Phase 6 (Metrics) | Low | 2-3 days | All phases |

**Total**: ~3-4 weeks for full implementation

## Success Metrics

Track these to know you're improving:

1. **Thread count**: 5 -> 15 parallel agents
2. **Thread duration**: 30min -> 4+ hours autonomous
3. **Thread depth**: 1 level -> 3+ nested levels
4. **Checkpoint frequency**: Every task -> Every phase
5. **Tool calls per session**: Track trend upward

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Resource overload | High | Start with conservative limits, monitor |
| Fusion conflicts | Medium | Clear merge strategies, human fallback |
| Long-run drift | Medium | Regular checkpoints, validation |
| Complexity creep | Low | Keep thread types modular |

---

*Update this plan as phases complete. Track progress in PROGRESS.md.*
