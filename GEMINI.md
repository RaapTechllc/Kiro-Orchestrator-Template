# Orchestrator Template - Gemini Instructions

Multi-agent AI development workflows. Drop `.kiro/` into any project.

> **Note**: This file mirrors CLAUDE.md for Gemini model compatibility. Both files should be kept in sync.

## Commands
```bash
# PRD → Plan → Implement (RECOMMENDED)
@create-prd "feature"           # Creates phased PRD
@create-plan .kiro/specs/prds/X.prd.md  # Creates plan
@implement-plan .kiro/specs/plans/X.plan.md  # Executes

# Ralph Loop (autonomous iteration)
./.kiro/workflows/ralph-loop-v2.sh --task "description" --max-iterations 20

# Parallel agents (worktree isolation)
./.kiro/workflows/ralph-kiro.sh --worktrees --auto-merge

# Monitoring
./.kiro/workflows/dashboard.sh              # All agents
./.kiro/workflows/health-monitor.sh watch 30  # Continuous
```

## Critical Rules

**MANDATORY:**
- Execute ONE task at a time
- STOP and wait for approval between phases
- Validate before merge: `worktree-manager.sh validate <agent>`
- Output `<promise>DONE</promise>` ONLY when validation passes

**CRITICAL:** The stop hook validates completion claims. Saying DONE without passing lint/typecheck/tests continues the loop.

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

## Agent Delegation
| Task Type | Agent |
|-----------|-------|
| Planning/Orchestration | `orchestrator` |
| Code review/Refactoring | `code-surgeon` |
| Tests | `test-architect` |
| CI/CD | `devops-automator` |
| Schema/DB | `db-wizard` |
| UI/UX | `frontend-designer` |
| Documentation | `doc-smith` |
| Security | `security-specialist` |
| Context efficiency | `strands-agent` |

## Efficiency Directive

**Primary Rule: 1 MESSAGE = ALL RELATED OPERATIONS**
- Batch tool calls when independent
- Never make a tool call without a clear purpose
- Prefer reading existing code before writing new

## Gemini-Specific Guidelines

### Tool Usage
When using function calling:
- Provide all required parameters explicitly
- Use structured JSON for complex inputs
- Handle tool errors gracefully with retry logic

### Context Management
- Gemini has a 1M+ token context window
- Still prefer progressive disclosure over loading everything
- Reference files by path rather than including full content

### Code Generation
- Be explicit about language and framework versions
- Include type annotations for TypeScript/Python
- Follow existing patterns in the codebase

### Output Format
- Use markdown for structured responses
- Code blocks with language tags: ```typescript, ```python, etc.
- Tables for comparing options or listing items

## Self-Improvement
When corrected: `./.kiro/workflows/self-improve.sh add correction "description"`
At session end: `@reflect`

## Deep Docs (load on-demand)
- `.kiro/docs/thread-engineering-guide.md` - Full framework
- `.kiro/steering/ralph-loop.md` - Autonomous iteration
- `.kiro/steering/agent-evolution.md` - Self-improvement

## Model Selection

This template is designed for:
- **Primary**: Gemini 2.0 Pro / Flash for general tasks
- **Complex reasoning**: Gemini 2.0 Pro with thinking
- **Fast iteration**: Gemini 2.0 Flash

Adjust agent configurations in `.kiro/agents/*.json` to use Gemini model IDs when running outside Claude Code.
