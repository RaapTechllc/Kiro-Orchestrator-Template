# Project Context

## What This Is
Orchestrator template for multi-agent AI development workflows. Drop `.kiro/` into any project.

## Tech Stack
- Kiro CLI / Claude Code for agent execution
- Shell scripts for parallel orchestration (Ralph Loop)
- Git worktrees for isolated parallel development
- Markdown for specs, plans, and progress tracking

## Key Commands
```bash
# Start orchestrator
kiro-cli --agent orchestrator

# Run parallel agents (with worktree isolation)
./.kiro/workflows/ralph-kiro.sh --worktrees --auto-merge

# Monitor agents
./.kiro/workflows/dashboard.sh

# Manage worktrees
./.kiro/workflows/worktree-manager.sh status
./.kiro/workflows/worktree-manager.sh merge <agent>
```

## Critical Files
- `PLAN.md` - Task checklist (create per-project)
- `PROGRESS.md` - Real-time status (create per-project)
- `.kiro/steering/` - Project context (fill in templates)

## Completion Protocol
Agents MUST output when done:
```
<promise>DONE</promise>
```

## Quality Gates
Before completing, verify:
1. `npm run lint` passes (if applicable)
2. `npm run typecheck` passes (if applicable)
3. All acceptance criteria met

## Git Workflow
- Parallel agents work in isolated worktrees (branches)
- Validate before merge: `worktree-manager.sh validate <agent>`
- Merge completed work: `worktree-manager.sh merge <agent>`
- Clean up: `worktree-manager.sh cleanup <agent>`

## Detailed Docs
Read on-demand (don't load all at once):
- `.kiro/docs/thread-engineering-guide.md` - Full framework
- `.kiro/docs/setup-guide.md` - Installation
- `.kiro/steering/ralph-loop.md` - Autonomous iteration
- `.kiro/steering/agent-evolution.md` - Self-improvement

## Constraints
- Execute ONE task at a time
- STOP and wait for approval between phases
- Use worktrees for parallel agent work
- Validate and merge before moving on

## Self-Improvement
When corrected, capture the learning:
```bash
./.kiro/workflows/self-improve.sh add correction "description"
```

At session end, use `@reflect` to analyze and capture learnings.

Review `LEARNINGS.md` periodically and promote patterns to this file.
