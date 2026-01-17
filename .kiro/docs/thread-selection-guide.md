# Thread Selection Guide

> Quick decision tree for choosing the right execution pattern.

## TL;DR Flowchart

```
START
  │
  ▼
┌─────────────────────────────────────────────┐
│ Are tasks INDEPENDENT (can run in parallel)? │
└─────────────────────────────────────────────┘
        │                    │
       YES                   NO
        │                    │
        ▼                    ▼
┌───────────────┐  ┌────────────────────────────┐
│  P-THREAD     │  │ Are tasks RISKY or need    │
│  (parallel)   │  │ human checkpoints?         │
│               │  └────────────────────────────┘
│ ralph-kiro.sh │          │            │
│ --worktrees   │         YES           NO
└───────────────┘          │            │
                           ▼            ▼
                 ┌───────────────┐ ┌────────────────────────┐
                 │  C-THREAD     │ │ Do you have MULTIPLE   │
                 │  (phased)     │ │ outputs to combine?    │
                 │               │ └────────────────────────┘
                 │ chain-workflow│        │            │
                 │ .sh           │       YES           NO
                 └───────────────┘        │            │
                                          ▼            ▼
                                ┌───────────────┐ ┌────────────────────────┐
                                │  F-THREAD     │ │ Is it a NESTED         │
                                │  (fusion)     │ │ sub-orchestration?     │
                                │               │ └────────────────────────┘
                                │ fusion.sh     │        │            │
                                └───────────────┘       YES           NO
                                                         │            │
                                                         ▼            ▼
                                               ┌───────────────┐ ┌────────────────────────┐
                                               │  B-THREAD     │ │ Is it LONG-RUNNING     │
                                               │  (nested)     │ │ (1+ hours)?            │
                                               │               │ └────────────────────────┘
                                               │ b-thread-     │        │            │
                                               │ orchestrator  │       YES           NO
                                               └───────────────┘        │            │
                                                                        ▼            ▼
                                                              ┌───────────────┐ ┌───────────────┐
                                                              │  L-THREAD     │ │ SINGLE RALPH  │
                                                              │  (long)       │ │ LOOP          │
                                                              │               │ │ (default)     │
                                                              │ l-thread-     │ │               │
                                                              │ runner.sh     │ │ ralph-loop-v2 │
                                                              └───────────────┘ └───────────────┘
```

## Quick Reference Table

| Pattern | When to Use | Script | Key Flag |
|---------|------------|--------|----------|
| **P-Thread** | Independent tasks, max parallelism | `ralph-kiro.sh` | `--worktrees` |
| **C-Thread** | Sequential phases, need approvals | `chain-workflow.sh` | `--template=` |
| **F-Thread** | Merge multiple agent outputs | `fusion.sh` | - |
| **B-Thread** | Complex task needs sub-orchestration | `b-thread-orchestrator.sh` | - |
| **L-Thread** | Long autonomous work (1+ hrs) | `l-thread-runner.sh` | `--duration=` |
| **Default** | Simple sequential task | `ralph-loop-v2.sh` | `--task=` |

## Decision Heuristics

### Use P-Thread (Parallel) When:
- Tasks don't share files (or rarely conflict)
- Speed matters more than coordination
- You have 3+ independent work items
- Examples: "Add tests for 5 different modules", "Fix 10 unrelated lint errors"

### Use C-Thread (Chain/Phased) When:
- Work has natural phases (plan → implement → test → deploy)
- Some phases need human approval before continuing
- Errors in early phases would waste work in later phases
- Examples: "Build feature with design review", "Migrate database with checkpoints"

### Use F-Thread (Fusion) When:
- Multiple agents produce outputs that need combining
- Final deliverable requires synthesis
- Different perspectives needed on same problem
- Examples: "Get code + tests + docs for feature", "Compare 3 implementation approaches"

### Use B-Thread (Nested) When:
- Main task has sub-tasks that themselves need orchestration
- Complexity requires divide-and-conquer
- Some sub-tasks are parallel, others sequential
- Examples: "Build microservices system", "Refactor large module with multiple components"

### Use L-Thread (Long-running) When:
- Work will take 1+ hours
- Need checkpoint saves to avoid losing progress
- Want to run overnight or during meetings
- Examples: "Major refactor", "Full test suite implementation"

### Use Single Ralph Loop When:
- Simple, focused task
- Unclear if parallel/phased makes sense
- Starting exploration or prototyping
- Examples: "Fix this bug", "Add a single feature", "Investigate an issue"

## Thread Composition

Threads can be nested. Common patterns:

```
B-Thread
├── P-Thread (parallel frontend + backend)
│   ├── ralph-loop (frontend)
│   └── ralph-loop (backend)
└── C-Thread (sequential deploy phases)
    ├── Phase 1: Staging deploy
    ├── [Approval]
    └── Phase 2: Production deploy
```

## Anti-Patterns

| Don't Do This | Why | Do This Instead |
|---------------|-----|-----------------|
| P-Thread for files that conflict | Merge hell | C-Thread or single loop |
| C-Thread for independent tasks | Wasted time waiting | P-Thread |
| L-Thread for quick fixes | Overhead not worth it | Single ralph loop |
| Nested B-Threads 3+ deep | Complexity explosion | Simplify task breakdown |

## Starting Point Recommendation

**If unsure, start with Single Ralph Loop.** It's the simplest and you can always escalate to a more complex pattern if needed.

```bash
# Start simple
./ralph-loop-v2.sh --task "your task" --max-iterations 20

# Escalate if you see:
# - "I need to do X and Y in parallel" → Switch to P-Thread
# - "This is risky, I need approval" → Switch to C-Thread
# - "I need to combine outputs" → Switch to F-Thread
```

---

*For deep dives, see: `.kiro/docs/thread-engineering-guide.md`*
