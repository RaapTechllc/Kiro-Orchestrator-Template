# Orchestrator Template

Multi-agent AI development workflows. Drop `.kiro/` into any project.

## Commands
```bash
# PRD → Plan → Implement (RECOMMENDED)
@create-prd "feature"           # Creates phased PRD
@create-plan .kiro/specs/prds/X.prd.md  # Creates plan
@implement-plan .kiro/specs/plans/X.plan.md  # Executes

# Ralph Loop (autonomous iteration)
./.kiro/workflows/ralph-loop-v2.sh --task "description" --max-iterations 20

# Dual-Agent Verification (writer + reviewer)
./.kiro/workflows/dual-verify.sh --task "description" --strict

# Parallel agents (worktree isolation)
./.kiro/workflows/ralph-kiro.sh --worktrees --auto-merge

# Worktree rollback (undo failed merges)
./.kiro/workflows/worktree-manager.sh rollback       # Undo last merge
./.kiro/workflows/worktree-manager.sh rollback-list  # View merge history

# Browser automation (agent-browser)
agent-browser open https://example.com              # Navigate
agent-browser snapshot --json                       # Get page structure
agent-browser click "ref:123"                       # Interact using refs
agent-browser screenshot --full                     # Capture screenshot

# Memory Bank (session persistence)
./.kiro/workflows/memory-bank.sh save active "Working on X"
./.kiro/workflows/memory-bank.sh save progress "Completed Y"
./.kiro/workflows/memory-bank.sh handoff   # Generate session handoff
./.kiro/workflows/memory-bank.sh load      # Load context

# Monitoring
./.kiro/workflows/dashboard.sh              # All agents
./.kiro/workflows/health-monitor.sh watch 30  # Continuous
```

## Critical Rules
**YOU MUST:**
- Execute ONE task at a time
- STOP and wait for approval between phases
- Validate before merge: `worktree-manager.sh validate <agent>`
- Output `<promise>DONE</promise>` ONLY when validation passes

**IMPORTANT:** The stop hook validates completion claims. Saying DONE without passing lint/typecheck/tests continues the loop.

## Validation Gates
```bash
npm run lint && npm run typecheck  # Level 1: REQUIRED
npm run test:unit                   # Level 2: REQUIRED
npm run test:integration            # Level 3: Optional
```

## File Reference
| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent selection guide |
| `PLAN.md` | Current task checklist |
| `PROGRESS.md` | Real-time status (agents update) |
| `LEARNINGS.md` | Corrections and patterns |
| `.kiro/specs/` | PRDs and plans |
| `.kiro/steering/` | Deep context (load on-demand) |
| `.kiro/memory/` | Session persistence (Memory Bank) |

## Agent Delegation
| Task Type | Agent |
|-----------|-------|
| Planning/Orchestration | `orchestrator` |
| Code review/Refactoring | `code-surgeon` |
| Implementation verification | `verifier` |
| Tests | `test-architect` |
| CI/CD | `devops-automator` |
| Schema/DB | `db-wizard` |
| UI/UX | `frontend-designer` |
| Documentation | `doc-smith` |
| Security | `security-specialist` |
| Context efficiency | `strands-agent` |

## Efficiency Directive
**Golden Rule: 1 MESSAGE = ALL RELATED OPERATIONS**
- Batch tool calls when independent
- Never make a tool call without a clear purpose
- Prefer reading existing code before writing new

## Self-Improvement
When corrected: `./.kiro/workflows/self-improve.sh add correction "description"`
At session end: `@reflect`

## Deep Docs (load on-demand)
- `.kiro/docs/thread-selection-guide.md` - **Choose the right thread type**
- `.kiro/docs/thread-engineering-guide.md` - Full framework
- `.kiro/docs/agent-browser-guide.md` - **Browser automation with agent-browser**
- `.kiro/steering/ralph-loop.md` - Autonomous iteration
- `.kiro/steering/agent-evolution.md` - Self-improvement
