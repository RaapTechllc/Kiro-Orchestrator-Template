# Thread-Based Engineering Guide

A mental framework for measuring and improving your agentic engineering output. Think of all work as **threads** - units of engineering work over time driven by you and your agents.

## The Core Concept

Every thread has two mandatory nodes where YOU show up:
1. **Beginning**: Prompt or Plan
2. **End**: Review or Validate

The middle is your agent doing work through **tool calls**. More tool calls = more impact.

```
┌─────────┐     ┌─────────────────────┐     ┌─────────┐
│  YOU    │ --> │   AGENT WORK        │ --> │   YOU   │
│ Prompt  │     │ (Tool Calls)        │     │ Review  │
└─────────┘     └─────────────────────┘     └─────────┘
```

## The Six Thread Types

### 1. Base Thread (Foundation)
The simplest unit of agentic work.

**Pattern**: Prompt -> Agent executes -> Review

**When to use**: 
- Single, focused tasks
- Quick iterations
- Learning new codebases

**Example**:
```bash
# Start a base thread
kiro-cli --agent orchestrator
> "What does this codebase do?"
# Agent reads files, analyzes, responds
# You review the summary
```

---

### 2. P-Thread (Parallel)
Scale compute by running multiple agents simultaneously.

**Pattern**: Multiple prompts -> Parallel execution -> Review all

**When to use**:
- Code reviews (multiple perspectives)
- Research tasks
- Independent subtasks

**Implementation** (`workflows/ralph-kiro.sh`):
```bash
# Launch 5 parallel agents
./workflows/ralph-kiro.sh --parallel=5

# Or manually in separate terminals
kiro-cli --agent security-specialist &
kiro-cli --agent test-architect &
kiro-cli --agent devops-automator &
```

**Key insight**: The engineer running 5 parallel agents gets 5x more done than single-agent work.

---

### 3. C-Thread (Chained)
Break massive plans into phases with checkpoints.

**Pattern**: Phase 1 -> Review -> Phase 2 -> Review -> Phase 3...

**When to use**:
- Production-sensitive work (migrations, deployments)
- Work exceeding context window
- High-risk changes requiring validation

**Implementation** (`workflows/chain-workflow.sh`):
```bash
# Define phases
PHASES=("design" "implement" "test" "deploy")

for phase in "${PHASES[@]}"; do
  run_phase $phase
  echo "Phase $phase complete. Review and press Enter to continue..."
  read
done
```

**Trade-off**: More human time, but higher confidence in each step.

---

### 4. F-Thread (Fusion)
Run multiple agents on the same task, then combine/select the best results.

**Pattern**: Same prompt -> Multiple agents -> Fuse results

**When to use**:
- Rapid prototyping (generate many versions)
- High-confidence decisions (majority vote)
- Creative tasks (cherry-pick best ideas)

**Implementation** (`workflows/fusion.sh`):
```bash
# Run 3 agents with same prompt
for i in {1..3}; do
  kiro-cli --agent code-surgeon --output results/$i.md \
    "Review the authentication module" &
done
wait

# Fuse results (majority vote, best-of-N, or merge)
./fuse-results.sh results/
```

**Key insight**: If 4/5 agents give the same answer, you can be highly confident.

---

### 5. B-Thread (Big/Meta)
Your prompts fire off other prompts. Agents manage agents.

**Pattern**: You prompt orchestrator -> Orchestrator prompts specialists -> You review final result

**When to use**:
- Complex features requiring multiple specialists
- Team-like coordination
- Nested workflows

**Implementation** (`agents/ralph-master.json`):
```json
{
  "agents": ["security-specialist", "test-architect", "doc-smith"],
  "parallel": true,
  "coordination": "orchestrator manages all sub-agents"
}
```

**Example flow**:
```
You: "Implement user authentication"
  └── Orchestrator: Plans the work
      ├── db-wizard: Designs schema
      ├── code-surgeon: Reviews security
      ├── test-architect: Writes tests
      └── doc-smith: Documents API
You: Review the complete implementation
```

---

### 6. L-Thread (Long-Running)
Extended autonomous execution with minimal human intervention.

**Pattern**: Detailed prompt -> Hours of agent work -> Final review

**When to use**:
- Well-defined, large tasks
- Overnight/background work
- High-trust scenarios

**Implementation** (Ralph Loop with stop hooks):
```bash
# Run until completion or max iterations
./workflows/ralph-kiro.sh --max-iterations=100 --timeout=4h

# Stop hook validates work before continuing
```

**Key insight**: The engineer running longer threads outperforms those with frequent interruptions.

---

## The Four Ways to Improve

| Improvement | What It Means | How to Achieve |
|-------------|---------------|----------------|
| **More threads** | Run more parallel agents | Add terminals, background agents |
| **Longer threads** | Increase autonomy duration | Better prompts, trust building |
| **Thicker threads** | Nest threads within threads | Use orchestrators, sub-agents |
| **Fewer checkpoints** | Reduce human reviews | Self-validation, stop hooks |

## Measuring Progress

Track these metrics over time:
- **Total tool calls** per session
- **Parallel agents** running simultaneously
- **Thread duration** (how long before you review)
- **Success rate** without human intervention

Use `workflows/metrics-tracker.sh` to log and visualize.

## Thread Composition

Threads can be combined:

```
B-Thread (Big)
├── P-Thread (Parallel)
│   ├── Base Thread (Agent 1)
│   ├── Base Thread (Agent 2)
│   └── Base Thread (Agent 3)
├── F-Thread (Fusion)
│   └── Combine P-Thread results
└── C-Thread (Chained)
    ├── Phase: Design (F-Thread)
    ├── Phase: Implement (P-Thread)
    └── Phase: Deploy (Base Thread)
```

## The Z-Thread (Advanced)

The ultimate goal: **Zero-touch threads** where you don't need to review.

**Requirements**:
- Maximum trust in your agent system
- Comprehensive self-validation
- Battle-tested workflows

**This is NOT vibe coding** - it's maximum engineering discipline where the system validates itself.

## Quick Reference

| Thread | Symbol | Scaling Method |
|--------|--------|----------------|
| Base | B | Foundation |
| Parallel | P | More compute |
| Chained | C | Phases |
| Fusion | F | Consolidation |
| Big | B* | Nesting |
| Long | L | Autonomy |
| Zero | Z | Trust |

## Next Steps

1. Start with Base Threads to learn your agents
2. Graduate to P-Threads for parallel work
3. Use C-Threads for sensitive production work
4. Master F-Threads for high-confidence decisions
5. Build B-Threads for complex orchestration
6. Push toward L-Threads for maximum output
7. Aspire to Z-Threads as your ultimate goal

---

*"Tool calls roughly equal impact. Scale your threads, scale your impact."*
