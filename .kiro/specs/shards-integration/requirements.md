# Shards Integration Requirements

## Overview
Integrate Shards orchestration patterns into the existing workflow template to enable reliable 15+ agent parallel execution with health monitoring, auto-recovery, and enhanced dashboard visibility.

## Problem Statement
Current gaps identified from research:
1. **No health monitoring** - Can't detect stalled/crashed agents
2. **No auto-recovery** - Circuit breaker exists but no restart capability
3. **No PR/CI integration** - Missing GitHub workflow hooks
4. **No skill abstraction** - Agents lack formalized capability definitions
5. **No inter-agent coordination** - Agents can't communicate mid-task
6. **Dashboard is passive** - Shows status but can't take action

## User Stories

### US-1: Agent Health Monitoring
**As an** orchestrator user  
**I want** real-time health status for all running agents  
**So that** I can identify problems before they cascade

**Acceptance Criteria:**
- [ ] Heartbeat detection (last activity timestamp)
- [ ] Stall detection (configurable threshold, default 15min)
- [ ] Memory/CPU indicators (if available)
- [ ] Status: healthy | stalled | crashed | complete

### US-2: Auto-Recovery
**As an** orchestrator user  
**I want** stalled agents to automatically restart  
**So that** long-running workflows don't require babysitting

**Acceptance Criteria:**
- [ ] Configurable restart policy (never | once | always)
- [ ] Preserve agent context on restart
- [ ] Log restart events to activity log
- [ ] Respect circuit breaker (don't restart if open)

### US-3: Enhanced Dashboard
**As an** orchestrator user  
**I want** an interactive dashboard with agent control  
**So that** I can monitor and manage agents from one place

**Acceptance Criteria:**
- [ ] Real-time agent health indicators (color-coded)
- [ ] Per-agent actions: restart, stop, view logs
- [ ] Worktree status with merge/cleanup actions
- [ ] PR status integration (if GitHub configured)
- [ ] Session metrics summary
- [ ] Keyboard shortcuts for common actions

### US-4: Skill Registry
**As an** orchestrator user  
**I want** agents to declare their capabilities  
**So that** the orchestrator can assign tasks intelligently

**Acceptance Criteria:**
- [ ] Skill definition format in agent JSON
- [ ] Skill discovery command
- [ ] Task-to-agent matching based on skills
- [ ] Skill coverage report

### US-5: Session Tracking (Shards Pattern)
**As an** orchestrator user  
**I want** JSON-based session tracking for all agents  
**So that** I can resume, audit, and analyze workflows

**Acceptance Criteria:**
- [ ] Session file per agent: `.kiro/state/sessions/<agent>-<timestamp>.json`
- [ ] Track: start time, iterations, tool calls, errors, completion status
- [ ] Session list command
- [ ] Session resume capability

### US-6: PR Status Integration
**As an** orchestrator user  
**I want** to see PR status for agent branches  
**So that** I know when work is ready to merge

**Acceptance Criteria:**
- [ ] Detect if agent branch has open PR
- [ ] Show PR status: draft | review | approved | merged
- [ ] Show CI status: pending | passing | failing
- [ ] Quick action to create PR from dashboard

## Non-Functional Requirements

### Performance
- Dashboard refresh: <1s
- Health check interval: 30s (configurable)
- Max agents supported: 15+ concurrent

### Reliability
- Graceful degradation if GitHub unavailable
- Session state survives process restart
- No data loss on crash

### Compatibility
- Works without GitHub (PR features disabled)
- Works on Linux, macOS, WSL
- Minimal dependencies (bash, jq, git)

## Out of Scope (Future)
- Web-based dashboard (stick with terminal)
- Multi-machine orchestration
- Cloud session storage
- Cairo/blockchain-specific features (separate spec)

## Dependencies
- Existing: `dashboard.sh`, `worktree-manager.sh`, `ralph-kiro.sh`, `metrics-tracker.sh`
- New: `jq` (JSON processing)
- Optional: `gh` CLI (GitHub integration)

## Success Metrics
- Run 15 agents for 4+ hours without manual intervention
- Auto-recover from 90% of stall scenarios
- Dashboard shows accurate status within 30s of change
