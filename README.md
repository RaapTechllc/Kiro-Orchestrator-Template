# Kiro Orchestrator Template

A production-grade multi-agent orchestration framework implementing industry best practices from Anthropic, Claude-Flow, and Ralph Loop methodologies.

## Quick Start

```bash
# 1. Copy to your project
cp -r .kiro /path/to/your/project/
cp CLAUDE.md PLAN.md PROGRESS.md /path/to/your/project/

# 2. Fill in project context
# Edit .kiro/steering/product.md, tech.md, structure.md

# 3. Define tasks in PLAN.md

# 4. Run the orchestrator
kiro-cli --agent orchestrator
```

## What's Included

```
├── CLAUDE.md                 # Minimal context (always loaded)
├── PLAN.md                   # Task definitions
├── PROGRESS.md               # Real-time status
└── .kiro/
    ├── agents/               # 10+ specialist agents
    ├── agent_docs/           # Progressive disclosure docs
    ├── commands/             # Slash commands for workflows
    ├── hooks/                # Quality gate automation
    ├── steering/             # Project context templates
    ├── workflows/            # Ralph Loop scripts
    ├── prompts/              # Reusable prompts
    ├── specs/                # Feature specifications
    └── docs/                 # Framework documentation
```

## Key Features

### 1. Minimal CLAUDE.md
Following [HumanLayer best practices](https://www.humanlayer.dev/blog/writing-a-good-claude-md) - under 60 lines, universally applicable. Detailed docs loaded on-demand.

### 2. Completion Protocol
Agents use explicit completion signals per [Ralph Loop pattern](https://github.com/frankbria/ralph-claude-code):
```
<promise>DONE</promise>
```

### 3. Quality Gate Hooks
Automatic validation before completion:
- Lint check
- Type check
- Progress update reminder

### 4. Circuit Breaker
Prevents infinite loops and API overuse:
```bash
./ralph-kiro.sh --circuit-status
./ralph-kiro.sh --reset-circuit
```

### 5. Progressive Disclosure
Context loaded only when needed:
- `.kiro/agent_docs/testing.md` - Read when writing tests
- `.kiro/agent_docs/security.md` - Read during security audit
- `.kiro/agent_docs/database.md` - Read for schema work

## Agents

| Agent | Specialty |
|-------|-----------|
| `orchestrator` | Workflow coordination, SPEC phases |
| `ralph-master` | Parallel orchestration (B-Thread) |
| `code-surgeon` | Code review, refactoring |
| `test-architect` | Testing, coverage |
| `security-specialist` | OWASP audits |
| `frontend-designer` | UI/UX, accessibility |
| `db-wizard` | Schema, migrations |
| `devops-automator` | CI/CD, deployment |
| `doc-smith` | Documentation |

## Workflows

### Single Agent
```bash
kiro-cli --agent orchestrator
```

### Parallel Agents (P-Thread)
```bash
./.kiro/workflows/ralph-kiro.sh --parallel=5
```

### Specific Agents
```bash
./.kiro/workflows/ralph-kiro.sh --agents=code-surgeon,test-architect
```

## Slash Commands

```bash
/project:spec-workflow [feature]    # Full SPEC workflow
/project:code-review [path]         # Code review
/project:security-audit [scope]     # OWASP audit
/project:test-coverage [target]     # Coverage analysis
```

## Customization

### 1. Fill Steering Templates
```bash
# Edit these with your project details
.kiro/steering/product.md    # What you're building
.kiro/steering/tech.md       # Tech stack
.kiro/steering/structure.md  # Project layout
```

### 2. Define Tasks
Edit `PLAN.md` with your task breakdown.

### 3. Add Project-Specific Docs
Add to `.kiro/agent_docs/` for progressive disclosure.

## Architecture

Based on Thread-Based Engineering:

| Thread | Description | Implementation |
|--------|-------------|----------------|
| Base | Single agent, manual review | `kiro-cli --agent X` |
| P-Thread | Parallel agents | `ralph-kiro.sh` |
| C-Thread | Chained phases | `chain-workflow.sh` |
| F-Thread | Fused results | `fusion.sh` |
| B-Thread | Nested orchestration | `ralph-master` agent |

## Best Practices Implemented

- ✅ Minimal CLAUDE.md (<60 lines)
- ✅ Progressive disclosure for detailed docs
- ✅ Explicit completion signals
- ✅ Quality gate hooks
- ✅ Circuit breaker protection
- ✅ Trimmed agent prompts (<300 words)
- ✅ Self-evolution protocol (RBT)

## References

- [Anthropic Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Ralph Loop Implementation](https://github.com/frankbria/ralph-claude-code)
- [Claude-Flow Orchestration](https://github.com/ruvnet/claude-code-flow)

## License

MIT
