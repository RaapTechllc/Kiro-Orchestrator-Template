# Orchestrator Template - Project Structure

## Directory Layout
```
project-root/
├── CLAUDE.md              # Primary AI instructions (concise)
├── AGENTS.md              # Agent directory + universal directives
├── GEMINI.md              # Gemini-compatible instructions
├── PLAN.md                # Current task checklist
├── PROGRESS.md            # Real-time status (agents update)
├── LEARNINGS.md           # Corrections and patterns
└── .kiro/
    ├── agents/            # Agent definitions (JSON)
    │   ├── orchestrator.json
    │   ├── code-surgeon.json
    │   ├── test-architect.json
    │   └── ...
    ├── docs/              # Deep documentation
    │   ├── thread-engineering-guide.md
    │   └── setup-guide.md
    ├── hooks/             # Stop hooks for validation
    │   └── ralph-stop.sh
    ├── prompts/           # Reusable prompt templates
    │   ├── reflect.md
    │   └── ...
    ├── specs/             # PRDs and plans
    │   ├── prds/          # Product requirements
    │   └── plans/         # Implementation plans
    │       └── completed/ # Archive of finished plans
    ├── state/             # Runtime state
    │   └── ralph-state.json
    ├── steering/          # Project context
    │   ├── product.md
    │   ├── structure.md
    │   ├── tech.md
    │   └── ralph-loop.md
    ├── validation/        # Quality gate configs
    │   └── levels.yaml
    └── workflows/         # Shell scripts
        ├── ralph-loop-v2.sh
        ├── ralph-kiro.sh
        ├── worktree-manager.sh
        └── dashboard.sh
```

## File Naming Conventions
- **Agents**: `kebab-case.json` (e.g., `code-surgeon.json`)
- **Specs**: `feature-name.prd.md`, `feature-name.plan.md`
- **Scripts**: `kebab-case.sh`
- **Markdown**: `kebab-case.md`

## Module Organization
- Agent definitions are self-contained JSON with embedded prompts
- Workflows are independent shell scripts
- Specs follow a consistent phase structure (requirements → design → tasks)
- Steering files provide context without being loaded automatically

## Configuration Files
- **Agent config**: `.kiro/agents/*.json`
- **Validation**: `.kiro/validation/levels.yaml`
- **State**: `.kiro/state/ralph-state.json`

## Documentation Structure
- **Quick reference**: Root-level .md files (CLAUDE.md, AGENTS.md)
- **Deep docs**: `.kiro/docs/` (load on-demand)
- **Context**: `.kiro/steering/` (for understanding project)

## Build Artifacts
- None - this is a framework/template, not an application
- Projects using this template will have their own build artifacts

## Environment-Specific Files
- **Local**: `ralph-state.json` (gitignored in real projects)
- **Shared**: All `.kiro/` contents except state files
