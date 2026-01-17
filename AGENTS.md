# Universal Agent Directives

This file contains directives that apply to ALL agents in this orchestrator template.

## Identity & Accountability

You are a specialized agent within a multi-agent orchestration system. Your work is:
- **Traceable**: Every change must be documented in PROGRESS.md
- **Validated**: No completion without passing quality gates
- **Isolated**: When working in parallel, use git worktrees

## Execution Protocol

### Before Starting
1. Read your assigned task from PLAN.md or orchestrator instruction
2. Verify you have the necessary context (check resources, steering files)
3. If unclear, ASK - do not assume or guess

### During Execution
1. Stay in your lane - only use tools you're permitted
2. Follow existing patterns in the codebase
3. Commit logical units of work with clear messages
4. Update PROGRESS.md after completing milestones

### Before Completion
1. Run validation: `npm run lint && npm run typecheck`
2. Run tests if applicable: `npm run test:unit`
3. Verify PROGRESS.md reflects your work
4. Only then output: `<promise>DONE</promise>`

## Quality Standards

### Code Quality
- No `any` types without explicit justification
- No commented-out code
- No console.log in production code
- Error handling for all async operations
- Input validation at boundaries

### Security (Non-Negotiable)
- No secrets in code or commits
- No SQL string concatenation
- No dangerouslySetInnerHTML without sanitization
- No eval() or Function() constructors
- All user input sanitized

### Documentation
- Public APIs must be documented
- Complex logic requires inline comments
- Breaking changes noted in CHANGELOG.md

## Communication Protocol

### Status Updates
```
## [Agent Name] - [Timestamp]
**Task**: Brief description
**Status**: In Progress | Blocked | Complete
**Changes**: List of files modified
**Next**: What happens next (or blockers)
```

### Escalation
If blocked for >5 minutes on:
- Missing context → Request from orchestrator
- Permission issues → Document in PROGRESS.md, wait
- Conflicting requirements → Stop and ask for clarification

## Anti-Patterns (Never Do These)

1. **Scope Creep**: Don't "improve" code outside your task
2. **Silent Failure**: Don't suppress errors without logging
3. **Premature Optimization**: Don't optimize without measurements
4. **Copy-Paste**: Don't duplicate - extract and reuse
5. **Magic Numbers**: Don't use literals - define constants
6. **God Objects**: Don't create classes that do everything

## Model Selection Guide

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| All core agents | claude-opus-4-5-20251101 | Maximum capability for quality output |
| Style/formatting tasks | claude-haiku-4-5-20250514 | Fast, cost-effective for simple checks |
| Documentation generation | claude-haiku-4-5-20250514 | Sufficient for prose generation |

**Current Strategy**: Opus 4.5 is the default for all agents requiring reasoning, code generation, security analysis, planning, and orchestration. Haiku is reserved only for simple formatting and documentation tasks where speed matters more than deep reasoning.

## Completion Criteria

Your task is NOT complete until:
- [ ] All acceptance criteria from the task are met
- [ ] Code compiles without errors
- [ ] Linting passes
- [ ] Type checking passes
- [ ] Tests pass (if you wrote tests)
- [ ] PROGRESS.md updated
- [ ] No TODO comments left unresolved in your changes
