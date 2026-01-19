<p align="center">
  <img src="https://kiro.dev/images/kiro-wordmark.png" alt="Kiro" width="200">
</p>

<h1 align="center">🎭 Orchestrator Template</h1>

<p align="center">
  <strong>Production-ready multi-agent orchestration for Kiro CLI</strong>
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-features">Features</a> •
  <a href="#-agents">Agents</a> •
  <a href="#-workflows">Workflows</a> •
  <a href="#-self-improvement">Self-Improvement</a>
</p>
a
<p align="center">
  <img src="https://img.shields.io/badge/Kiro_CLI-Compatible-blue?style=flat-square" alt="Kiro CLI Compatible">
  <img src="https://img.shields.io/badge/Agents-10-green?style=flat-square" alt="10 Agents">
  <img src="https://img.shields.io/badge/Thread_Types-5-purple?style=flat-square" alt="5 Thread Types">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT License">
</p>

---

## 🚀 Quick Start

```bash
# Clone the template
git clone https://github.com/RaapTechllc/Kiro-Orchestrator-Template.git my-project
cd my-project

# Install agent-browser for E2E testing (optional)
npm install -g agent-browser

# Start the orchestrator
kiro-cli --agent orchestrator
```

That's it. The orchestrator will guide you through spec-driven development with intelligent task delegation.

---

## ✨ Features

### 🎯 Spec-Driven Development
Structured workflow: **Requirements → Design → Tasks → Execute**

```
@plan-feature User Authentication
```

The orchestrator creates specs, waits for approval at each phase, then delegates to specialists.

### 🧵 Thread-Based Execution
Five execution patterns for any workflow:

| Thread | Pattern | Use Case |
|--------|---------|----------|
| **P-Thread** | Parallel | Multiple agents working simultaneously |
| **C-Thread** | Chained | Sequential phases with checkpoints |
| **F-Thread** | Fusion | Multiple perspectives, merged result |
| **B-Thread** | Boss | Nested orchestration of threads |
| **L-Thread** | Long-running | Extended autonomous work |

### 🌳 Git Worktree Isolation
Each agent works in its own branch. No conflicts. Clean merges.

```bash
.kiro/workflows/worktree-manager.sh create frontend-designer
# Agent works in isolated branch
.kiro/workflows/worktree-manager.sh merge frontend-designer
```

### 🧠 Self-Improving Agents
Agents learn from corrections and improve over time.

```bash
# Capture a learning
.kiro/workflows/self-improve.sh add correction "Use pnpm not npm"

# Reflect on session
@reflect
```

---

## 🤖 Agents

| Agent | Specialty |
|-------|-----------|
| `orchestrator` | Workflow coordination, SPEC pattern, task delegation |
| `ralph-master` | B-Thread meta-orchestration for complex workflows |
| `code-surgeon` | Code review, refactoring, security analysis |
| `test-architect` | Testing strategy, coverage, test generation |
| `security-specialist` | OWASP audits, vulnerability detection |
| `frontend-designer` | UI/UX, accessibility, responsive design |
| `db-wizard` | Database design, migrations, optimization |
| `devops-automator` | CI/CD, deployment, infrastructure |
| `doc-smith` | Documentation, READMEs, API docs |
| `agent-creator` | Create new custom agents |

---

## 🔄 Workflows

### The Ralph Loop
Agents work in autonomous cycles until task completion:

```
┌─────────────────────────────────────────┐
│            RALPH LOOP                   │
├─────────────────────────────────────────┤
│  1. Load task from PLAN.md              │
│  2. Execute with available tools        │
│  3. Validate (tests, lint, typecheck)   │
│  4. Update PROGRESS.md                  │
│  5. Loop until done                     │
│  6. Signal: <promise>DONE</promise>     │
└─────────────────────────────────────────┘
```

### Available Scripts

```bash
# Parallel execution with worktree isolation
.kiro/workflows/ralph-kiro.sh --worktrees

# Sequential phases with checkpoints
.kiro/workflows/chain-workflow.sh

# Multiple agents, fused results
.kiro/workflows/fusion.sh

# Real-time monitoring dashboard
.kiro/workflows/dashboard.sh
```

---

## 📁 Structure

```
.kiro/
├── agents/           # 10 specialist agents
├── prompts/          # Reusable prompts (@plan-feature, @reflect, etc.)
├── workflows/        # Execution scripts (P/C/F/B/L threads)
├── steering/         # Project context (product, tech, structure)
├── hooks/            # Automation triggers
├── specs/            # Feature specifications
└── docs/             # Extended documentation

CLAUDE.md             # Core rules for all agents
LEARNINGS.md          # Captured corrections and patterns
PLAN.md               # Current task checklist
PROGRESS.md           # Real-time status tracking
```

---

## 🧠 Self-Improvement

The template includes a self-improvement system based on the principle: **"Correct once, never again."**

### How It Works

1. **Capture** - When you correct an agent, it's logged to `LEARNINGS.md`
2. **Reflect** - Use `@reflect` at session end to analyze what worked
3. **Promote** - High-frequency learnings get added to `CLAUDE.md`
4. **Evolve** - Agents improve with each session

### Learning Types

```markdown
CORRECTION: "Use pnpm not npm"
PREFER: "Always use TypeScript strict mode"
PATTERN: "Run lint before commit"
AVOID: "Don't use any types"
```

---

## 🛠️ Customization

### Add Your Project Context

Edit the steering files:

```bash
.kiro/steering/product.md   # What you're building
.kiro/steering/tech.md      # Your tech stack
.kiro/steering/structure.md # Your file organization
```

### Create Custom Agents

```bash
kiro-cli --agent agent-creator
```

Or copy `.kiro/agents/templates/specialist-base.json` and customize.

### Add Prompts

Create `.kiro/prompts/my-prompt.md`:

```markdown
# My Custom Prompt

When invoked, ask: What specific task should I help with?

Then do the thing...
```

Use with `@my-prompt`

---

## 📚 Documentation

- [Setup Guide](.kiro/docs/setup-guide.md)
- [Thread Engineering Guide](.kiro/docs/thread-engineering-guide.md)
- [Kiro CLI Reference](.kiro/docs/kiro-cli-reference.md)
- [Agent Documentation](.kiro/agents/README.md)

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a PR

---

## 📄 License

MIT © [RaapTech LLC](https://github.com/RaapTechllc)

---

<p align="center">
  <strong>Built for developers who want AI agents that actually work together.</strong>
</p>

<p align="center">
  <a href="https://kiro.dev">Kiro</a> •
  <a href="https://github.com/RaapTechllc/Kiro-Orchestrator-Template/issues">Issues</a> •
  <a href="https://github.com/RaapTechllc/Kiro-Orchestrator-Template/discussions">Discussions</a>
</p>
