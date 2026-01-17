# Orchestrator Template - Technical Context

## Tech Stack
- **AI Models**: Claude Opus 4.5 (primary), Claude Haiku 4.5 (fast tasks)
- **Orchestration**: Kiro CLI for agent execution
- **Scripts**: Bash shell scripts for workflow automation
- **Version Control**: Git with worktree support for isolation
- **Config**: JSON for agents, YAML for validation, Markdown for docs

## Architecture

### Agent System
```
┌─────────────────────────────────────────────────────────────┐
│                     Kiro CLI                                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Orchestrator │  │ Specialists  │  │ Reviewers    │       │
│  │              │──▶│ (parallel)   │──▶│ (validation) │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
├─────────────────────────────────────────────────────────────┤
│                  Git Worktrees (isolation)                   │
└─────────────────────────────────────────────────────────────┘
```

### Validation Flow
```
Agent outputs <promise>DONE</promise>
         │
         ▼
    Stop Hook Runs
         │
    ┌────┴────┐
    │ Level 1 │ → npm run lint && npm run typecheck
    └────┬────┘
         │ Pass
    ┌────┴────┐
    │ Level 2 │ → npm run test:unit
    └────┬────┘
         │ Pass
         ▼
    Loop Terminates
```

### Thread Types
| Type | Pattern | Use Case |
|------|---------|----------|
| P-Thread | Parallel worktrees | Independent tasks |
| C-Thread | Chained phases | Sequential with gates |
| F-Thread | Fusion | Multiple perspectives merged |
| B-Thread | Nested orchestration | Complex hierarchies |
| L-Thread | Long-running | Extended autonomous work |

## Key Dependencies
- **jq**: JSON parsing in shell scripts
- **Git**: Worktree support (2.5+)
- **Node.js**: For projects using npm validation
- **Kiro CLI**: Agent execution environment

## API Contracts

### Agent JSON Schema
```json
{
  "name": "string",
  "description": "string",
  "model": "claude-opus-4-5-20251101 | claude-haiku-4-5-20251014",
  "prompt": "string (system prompt)",
  "tools": ["read", "write", "glob", "grep", "shell"],
  "allowedTools": ["pre-approved tools"],
  "resources": ["file://path/pattern"],
  "toolsSettings": {},
  "hooks": {
    "agentSpawn": [{"command": "string", "timeout_ms": 5000}],
    "stop": [{"command": "string", "timeout_ms": 120000}]
  }
}
```

### State File Schema
```json
{
  "active": true,
  "iteration": 0,
  "max_iterations": 50,
  "task": "description",
  "validation_passed": {
    "syntax": false,
    "unit_tests": false,
    "integration": false
  }
}
```

## Performance Characteristics
- **Agent spawn**: ~2-5 seconds
- **Validation gate**: ~10-60 seconds depending on test suite
- **Context efficiency**: CLAUDE.md should be <100 lines for optimal adherence

## Security Model
- Agents have scoped tool permissions via `allowedTools`
- Path restrictions via `toolsSettings`
- Validation hooks prevent completion without passing checks
- Worktrees provide isolation between parallel agents

## Monitoring & Observability
- `PROGRESS.md`: Human-readable status
- `.kiro/state/ralph-state.json`: Machine-readable state
- `dashboard.sh`: Real-time monitoring
- `health-monitor.sh`: Continuous health checks

## Known Limitations
- Stop hooks require the project to have lint/test scripts
- Worktree isolation requires sufficient disk space
- Long-running agents may hit context limits
