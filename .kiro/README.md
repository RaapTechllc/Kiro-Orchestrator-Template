# Kiro Orchestrator Template

A reusable agent orchestration framework based on **Thread-Based Engineering** principles. Drop this `.kiro` folder into any project to enable multi-agent workflows with parallel execution, fusion, chaining, and autonomous operation.

## Quick Start

```bash
# 1. Copy this .kiro folder to your project root
cp -r .kiro /path/to/your/project/

# 2. Initialize the orchestrator
cd /path/to/your/project
./kiro/workflows/ralph-kiro.sh

# 3. Or run individual agents
kiro-cli --agent orchestrator
```

## Thread-Based Engineering Framework

This template implements the **six thread types** for scaling agentic engineering:

| Thread | Description | Use Case |
|--------|-------------|----------|
| **Base Thread** | Single prompt -> agent work -> review | Simple tasks |
| **P-Thread** | Parallel agents working simultaneously | Scale compute |
| **C-Thread** | Chained phases with checkpoints | Production-sensitive work |
| **F-Thread** | Fusion of multiple agent results | High-confidence decisions |
| **B-Thread** | Meta-threads containing sub-threads | Complex orchestration |
| **L-Thread** | Long-running autonomous workflows | Extended autonomy |

### Improvement Metrics

Know you're improving when you can:
1. Run **more threads** (parallel agents)
2. Run **longer threads** (extended autonomy)
3. Run **thicker threads** (nested orchestration)
4. Run **fewer checkpoints** (increased trust)

## Folder Structure

```
.kiro/
├── README.md                 # This file
├── agents/                   # Agent configurations
│   ├── orchestrator.json    # Master workflow coordinator
│   ├── ralph-master.json    # Parallel loop orchestrator
│   ├── templates/           # Base agent templates
│   └── [specialists]/       # Domain-specific agents
├── docs/                     # Framework documentation
│   ├── thread-engineering-guide.md
│   ├── setup-guide.md
│   └── improvement-plan.md
├── workflows/                # Executable scripts
│   ├── ralph-kiro.sh        # P-thread parallel spawner
│   ├── fusion.sh            # F-thread result fusion
│   ├── chain-workflow.sh    # C-thread phase management
│   └── metrics-tracker.sh   # Performance tracking
├── steering/                 # Protocols and evolution
│   ├── agent-evolution.md   # Self-improvement framework
│   └── ralph-loop.md        # Validation methodology
├── prompts/                  # Reusable prompt templates
├── specs/                    # Feature specifications
├── hooks/                    # Automation hooks
├── settings/                 # Configuration files
└── examples/                 # Sample workflows
```

## Core Components

### 1. Orchestrator Agent
The master coordinator using SPEC workflow:
- **Requirements** -> Design -> Tasks -> Implementation
- Delegates to specialists automatically
- Manages context efficiently

### 2. Ralph Loop (P-Thread)
Parallel agent spawning for tandem work:
```bash
./workflows/ralph-kiro.sh --parallel=5
```

### 3. Kiro Protocol (Self-Evolution)
Agents improve themselves using RBT (Roses, Buds, Thorns):
- Automatic error diagnosis
- Evolution logging
- 1% better every session

## Available Agents

| Agent | Specialty | Best For |
|-------|-----------|----------|
| `orchestrator` | Workflow coordination | Feature planning |
| `ralph-master` | Parallel orchestration | Multi-agent tasks |
| `code-surgeon` | Code review, security | Quality assurance |
| `test-architect` | Testing, coverage | Test generation |
| `frontend-designer` | UI/UX, accessibility | Visual work |
| `db-wizard` | Database, Prisma | Schema design |
| `devops-automator` | CI/CD, deployment | Infrastructure |
| `doc-smith` | Documentation | READMEs, API docs |

## Customization

### Adding New Agents
1. Copy `agents/templates/specialist-base.json`
2. Customize name, prompt, tools, and permissions
3. Add to `ralph-master.json` if needed for parallel work

### Creating New Workflows
1. Copy `workflows/ralph-kiro.sh` as a starting point
2. Modify agent list and coordination logic
3. Add fusion or chaining as needed

## Documentation

- [Thread Engineering Guide](docs/thread-engineering-guide.md) - Full framework explanation
- [Setup Guide](docs/setup-guide.md) - Detailed installation steps
- [Improvement Plan](docs/improvement-plan.md) - Roadmap for enhancements

## Credits

Based on Thread-Based Engineering framework concepts and the Ralph Loop methodology.
