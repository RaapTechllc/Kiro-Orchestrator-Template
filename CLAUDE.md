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

# PRD → Plan → Implement workflow (RECOMMENDED)
@create-prd "feature description"     # Creates PRD with phases
@create-plan .kiro/specs/prds/X.prd.md  # Creates plan for next phase
@implement-plan .kiro/specs/plans/X.plan.md  # Executes with validation

# Ralph Loop v2 (with stop hook + validation)
./.kiro/workflows/ralph-loop-v2.sh --task "description" --max-iterations 20

# Run parallel agents (with worktree isolation)
./.kiro/workflows/ralph-kiro.sh --worktrees --auto-merge

# Monitor agents
./.kiro/workflows/dashboard.sh

# Manage worktrees
./.kiro/workflows/worktree-manager.sh status
./.kiro/workflows/worktree-manager.sh merge <agent>
```

## Critical Files
- `.kiro/specs/prds/` - Product requirement documents
- `.kiro/specs/plans/` - Implementation plans (completed/ for archives)
- `.kiro/state/ralph-state.json` - Loop state tracking
- `PROGRESS.md` - Real-time status
- `.kiro/steering/` - Project context

## Completion Protocol
Agents MUST output when done:
```
<promise>DONE</promise>
```

**IMPORTANT:** The stop hook validates this claim. Saying DONE without passing validation will continue the loop.

## Validation Gates (Enforced by Stop Hook)
Before `<promise>DONE</promise>` is accepted:

```bash
# Level 1: Syntax (REQUIRED)
npm run lint && npm run typecheck

# Level 2: Unit Tests (REQUIRED)
npm run test:unit

# Level 3: Integration (optional, final check)
npm run test:integration
```

See `.kiro/validation/levels.yaml` for multi-language config.

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
