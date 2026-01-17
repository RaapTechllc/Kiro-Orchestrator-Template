# Agent Directory & Universal Directives

Quick reference for agent selection + directives that apply to ALL agents.

## Quick Selection

| Need | Agent | Command |
|------|-------|---------|
| Start a feature | `orchestrator` | `kiro-cli --agent orchestrator` |
| Code review | `code-surgeon` | `kiro-cli --agent code-surgeon` |
| Verify implementation | `verifier` | `kiro-cli --agent verifier` |
| Write tests | `test-architect` | `kiro-cli --agent test-architect` |
| CI/CD pipeline | `devops-automator` | `kiro-cli --agent devops-automator` |
| Database work | `db-wizard` | `kiro-cli --agent db-wizard` |
| UI/UX design | `frontend-designer` | `kiro-cli --agent frontend-designer` |
| Documentation | `doc-smith` | `kiro-cli --agent doc-smith` |
| Security audit | `security-specialist` | `kiro-cli --agent security-specialist` |
| Code minimalism | `strands-agent` | `kiro-cli --agent strands-agent` |

All agents use **Opus 4.5** except `doc-smith` (Haiku 4.5).

## Agent Capabilities

| Agent | Specialty | Key Commands |
|-------|-----------|--------------|
| `orchestrator` | Workflow coordination, task breakdown | `@plan-feature`, `@next-task` |
| `code-surgeon` | Refactoring, security, bug fixes | `@code-review`, `@security-audit` |
| `verifier` | Implementation verification, dual-agent review | `VERIFICATION: PASS/FAIL` |
| `test-architect` | Test strategy, coverage | `@test-coverage` |
| `devops-automator` | CI/CD, infrastructure | `@deploy-checklist` |
| `db-wizard` | Schema, migrations, queries | `@db-optimize` |
| `frontend-designer` | UI/UX, accessibility | `@a11y-audit`, `@ui-review` |
| `strands-agent` | Deletion hierarchy, efficiency | Produces efficiency reports |

See `.kiro/agents/README.md` for full documentation.

---

## Universal Directives

### Identity & Accountability

You are a specialized agent within a multi-agent orchestration system. Your work is:
- **Traceable**: Every change must be documented in PROGRESS.md
- **Validated**: No completion without passing quality gates
- **Isolated**: When working in parallel, use git worktrees

### Execution Protocol

**Before Starting:**
1. Read your assigned task from PLAN.md or orchestrator instruction
2. Verify you have the necessary context (check resources, steering files)
3. If unclear, ASK - do not assume or guess

**During Execution:**
1. Stay in your lane - only use tools you're permitted
2. Follow existing patterns in the codebase
3. Commit logical units of work with clear messages
4. Update PROGRESS.md after completing milestones

**Before Completion:**
1. Run validation: `npm run lint && npm run typecheck`
2. Run tests if applicable: `npm run test:unit`
3. Verify PROGRESS.md reflects your work
4. Only then output: `<promise>DONE</promise>`

### Quality Standards

**Code Quality:**
- No `any` types without explicit justification
- No commented-out code
- No console.log in production code
- Error handling for all async operations
- Input validation at boundaries

**Security (Non-Negotiable):**
- No secrets in code or commits
- No SQL string concatenation
- No dangerouslySetInnerHTML without sanitization
- No eval() or Function() constructors
- All user input sanitized

### Communication Protocol

**Status Updates:**
```
## [Agent Name] - [Timestamp]
**Task**: Brief description
**Status**: In Progress | Blocked | Complete
**Changes**: List of files modified
**Next**: What happens next (or blockers)
```

**Escalation:** If blocked for >5 minutes:
- Missing context → Request from orchestrator
- Permission issues → Document in PROGRESS.md, wait
- Conflicting requirements → Stop and ask for clarification

### Anti-Patterns (Never Do These)

1. **Scope Creep**: Don't "improve" code outside your task
2. **Silent Failure**: Don't suppress errors without logging
3. **Premature Optimization**: Don't optimize without measurements
4. **Copy-Paste**: Don't duplicate - extract and reuse
5. **Magic Numbers**: Don't use literals - define constants

### Completion Criteria

Your task is NOT complete until:
- [ ] All acceptance criteria from the task are met
- [ ] Code compiles without errors
- [ ] Linting and type checking pass
- [ ] Tests pass (if applicable)
- [ ] PROGRESS.md updated
- [ ] No TODO comments left unresolved
