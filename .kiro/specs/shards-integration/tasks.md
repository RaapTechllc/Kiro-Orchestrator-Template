# Shards Integration - Implementation Tasks

## Phase 1: State Infrastructure (Day 1)

### Task 1.1: Create State Directory Structure
**Agent:** orchestrator  
**Time:** 15 min

```bash
mkdir -p .kiro/state/{health,sessions,skills}
```

**Acceptance Criteria:**
- [ ] Directories created
- [ ] .gitkeep files added
- [ ] README explaining structure

---

### Task 1.2: Create Health Monitor Script
**Agent:** code-surgeon  
**Time:** 45 min

Create `.kiro/workflows/health-monitor.sh`:
- Check agent output file timestamps
- Detect stalled/crashed/complete states
- Write to `.kiro/state/health/<agent>.json`
- Run as background process or on-demand

**Acceptance Criteria:**
- [ ] Detects healthy agents (activity < threshold)
- [ ] Detects stalled agents (no activity > threshold)
- [ ] Detects complete agents (`<promise>DONE</promise>`)
- [ ] Detects failed agents (error patterns)
- [ ] Writes JSON state files

---

### Task 1.3: Create Session Manager Script
**Agent:** code-surgeon  
**Time:** 45 min

Create `.kiro/workflows/session-manager.sh`:
- `start <agent> <task>` - Create session file
- `update <agent> <field> <value>` - Update session
- `end <agent> <status>` - Close session
- `list` - Show all sessions

**Acceptance Criteria:**
- [ ] Creates session JSON on start
- [ ] Updates session fields
- [ ] Closes session with final status
- [ ] Lists sessions with filters

---

## Phase 2: Dashboard Enhancement (Day 1-2)

### Task 2.1: Add Health Display to Dashboard
**Agent:** code-surgeon  
**Time:** 30 min

Modify `dashboard.sh`:
- Read from `.kiro/state/health/`
- Color-code status (🟢🟡🔴✅❌)
- Show last activity time
- Show iteration count

**Acceptance Criteria:**
- [ ] Health section displays all agents
- [ ] Color coding matches status
- [ ] Updates on refresh

---

### Task 2.2: Add Interactive Agent Controls
**Agent:** code-surgeon  
**Time:** 45 min

Add keyboard shortcuts:
- Number keys to select agent
- `r` to restart selected
- `s` to stop selected
- `l` to view logs

**Acceptance Criteria:**
- [ ] Can select agent by number
- [ ] Restart triggers agent restart
- [ ] Stop kills agent process
- [ ] Logs opens tail -f

---

### Task 2.3: Add PR Status Display
**Agent:** code-surgeon  
**Time:** 30 min

Add worktree/PR section:
- Show branch diff stats
- Show PR status if exists
- Show CI status
- Quick actions: create PR, merge

**Acceptance Criteria:**
- [ ] Shows diff stats per branch
- [ ] Shows PR status (if gh available)
- [ ] Graceful fallback if no gh

---

## Phase 3: Auto-Recovery (Day 2)

### Task 3.1: Add Restart Policy to ralph-kiro.sh
**Agent:** code-surgeon  
**Time:** 30 min

Add flags:
- `--restart-policy=never|once|always`
- `--max-restarts=N`
- `--restart-delay=SECONDS`

**Acceptance Criteria:**
- [ ] Flags parsed correctly
- [ ] Policy stored in state
- [ ] Documented in help

---

### Task 3.2: Implement Auto-Restart Logic
**Agent:** code-surgeon  
**Time:** 45 min

In health monitor or ralph-kiro:
- Detect stalled agents
- Check restart policy
- Check circuit breaker
- Perform restart with context preservation

**Acceptance Criteria:**
- [ ] Stalled agents auto-restart per policy
- [ ] Respects max restart count
- [ ] Respects circuit breaker
- [ ] Logs restart events

---

### Task 3.3: Context Preservation on Restart
**Agent:** code-surgeon  
**Time:** 30 min

When restarting:
- Save current progress
- Preserve worktree state
- Resume from last checkpoint

**Acceptance Criteria:**
- [ ] Progress preserved
- [ ] Worktree unchanged
- [ ] Agent resumes correctly

---

## Phase 4: GitHub Integration (Day 2-3)

### Task 4.1: Add PR Creation to worktree-manager.sh
**Agent:** code-surgeon  
**Time:** 30 min

Add `--create-pr` flag:
- Create PR from agent branch
- Set title from task
- Add labels

**Acceptance Criteria:**
- [ ] Creates PR via gh CLI
- [ ] Sets appropriate title
- [ ] Works without gh (skip gracefully)

---

### Task 4.2: Add CI Status Check
**Agent:** code-surgeon  
**Time:** 30 min

Add `--check-ci` flag:
- Query PR status checks
- Return pass/fail/pending

**Acceptance Criteria:**
- [ ] Returns CI status
- [ ] Handles no PR case
- [ ] Handles no gh case

---

### Task 4.3: Dashboard PR Integration
**Agent:** code-surgeon  
**Time:** 30 min

Wire up PR status to dashboard:
- Show PR number and status
- Show CI status icon
- Quick merge action

**Acceptance Criteria:**
- [ ] PR status visible
- [ ] CI status visible
- [ ] Merge action works

---

## Phase 5: Skill Registry (Day 3)

### Task 5.1: Define Skill Schema
**Agent:** orchestrator  
**Time:** 20 min

Create `.kiro/state/skills/registry.json`:
- Agent skill definitions
- Skill index for lookup

**Acceptance Criteria:**
- [ ] Schema documented
- [ ] Initial registry created
- [ ] All existing agents have skills

---

### Task 5.2: Enhance Agent JSON Files
**Agent:** code-surgeon  
**Time:** 30 min

Add skills to each agent JSON:
- Primary skills
- Secondary skills
- Avoid list

**Acceptance Criteria:**
- [ ] All agents have skills defined
- [ ] Skills are meaningful
- [ ] Backward compatible

---

### Task 5.3: Add Skill Discovery Command
**Agent:** code-surgeon  
**Time:** 30 min

Create command to:
- List all skills
- Find agents by skill
- Show skill coverage

**Acceptance Criteria:**
- [ ] Can list all skills
- [ ] Can find agents for skill
- [ ] Shows coverage gaps

---

## Phase 6: Integration Testing (Day 3)

### Task 6.1: Test 5-Agent Parallel Run
**Agent:** test-architect  
**Time:** 45 min

Run 5 agents with:
- Worktree isolation
- Health monitoring
- Auto-restart (once)

**Acceptance Criteria:**
- [ ] All agents start correctly
- [ ] Health status accurate
- [ ] Stalled agent restarts
- [ ] Dashboard shows all

---

### Task 6.2: Test 15-Agent Stress Test
**Agent:** test-architect  
**Time:** 60 min

Run 15 agents for 1 hour:
- Monitor resource usage
- Track restart events
- Verify no data loss

**Acceptance Criteria:**
- [ ] System remains stable
- [ ] Memory usage acceptable
- [ ] All sessions tracked
- [ ] Recovery works

---

### Task 6.3: Document and Finalize
**Agent:** doc-smith  
**Time:** 30 min

Update documentation:
- README with new features
- CLAUDE.md with new commands
- Help text in scripts

**Acceptance Criteria:**
- [ ] All new features documented
- [ ] Examples provided
- [ ] Help text accurate

---

## Summary

| Phase | Tasks | Est. Time | Dependencies |
|-------|-------|-----------|--------------|
| 1. State Infrastructure | 3 | 1.75h | None |
| 2. Dashboard Enhancement | 3 | 1.75h | Phase 1 |
| 3. Auto-Recovery | 3 | 1.75h | Phase 1, 2 |
| 4. GitHub Integration | 3 | 1.5h | Phase 2 |
| 5. Skill Registry | 3 | 1.25h | Phase 1 |
| 6. Integration Testing | 3 | 2.25h | All |

**Total: 18 tasks, ~10 hours**

## Execution Order

Can run in parallel:
- Phase 1 → Phase 2 → Phase 3 (sequential)
- Phase 4 (after Phase 2)
- Phase 5 (after Phase 1)
- Phase 6 (after all)

**Recommended:** Use P-Thread with 3 agents:
1. `code-surgeon` - Core implementation (Phases 1-3)
2. `code-surgeon` - GitHub integration (Phase 4)
3. `doc-smith` - Documentation (Phase 5, 6.3)
