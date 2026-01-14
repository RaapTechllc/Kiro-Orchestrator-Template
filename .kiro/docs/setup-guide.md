# Setup Guide

How to use the Kiro Orchestrator Template in new projects.

## Prerequisites

- Node.js 18+ (for Kiro CLI)
- Bash shell (Git Bash on Windows, native on Mac/Linux)
- Kiro CLI installed (`npm install -g kiro-cli` or via your package manager)

## Installation

### Option 1: Copy the Template

```bash
# From a project with this template
cp -r .kiro /path/to/new/project/

# Navigate to new project
cd /path/to/new/project

# Verify structure
ls -la .kiro/
```

### Option 2: Clone from Template Repository

```bash
# Clone the template (if stored in a repo)
git clone https://github.com/your-org/orchestrator-template.git
cp -r orchestrator-template/.kiro /path/to/new/project/
```

## Post-Installation Setup

### 1. Configure Project-Specific Paths

Edit `.kiro/agents/orchestrator.json`:
```json
{
  "toolsSettings": {
    "read": {
      "allowedPaths": [
        "./.kiro/**",
        "./src/**",        // Adjust to your project structure
        "./lib/**",        // Add your source directories
        "./package.json"
      ]
    }
  }
}
```

### 2. Initialize State Files

Create the required state files in your project root:

```bash
# Create PLAN.md (your task checklist)
cat > PLAN.md << 'EOF'
# Project Plan

## Phase 1: Setup
- [ ] Task 1.1: Initialize project structure
- [ ] Task 1.2: Configure dependencies

## Phase 2: Implementation
- [ ] Task 2.1: Core feature
- [ ] Task 2.2: Tests
EOF

# Create PROGRESS.md (agent progress tracking)
cat > PROGRESS.md << 'EOF'
# Progress Tracker

## Status: In Progress

### Completed Tasks
- (none yet)

### Current Tasks
- Initializing...

### Blocked Tasks
- (none)
EOF

# Create activity.log
touch activity.log
```

### 3. Set Execute Permissions (Linux/Mac)

```bash
chmod +x .kiro/workflows/*.sh
```

### 4. Test the Setup

```bash
# Test orchestrator
kiro-cli --agent orchestrator
> "What is the current status of this project?"

# Test parallel spawning
./.kiro/workflows/ralph-kiro.sh
```

## Customization

### Adding Project-Specific Agents

1. Copy a template:
```bash
cp .kiro/agents/templates/specialist-base.json .kiro/agents/my-agent.json
```

2. Edit the new agent:
```json
{
  "name": "my-agent",
  "description": "My custom agent for [purpose]",
  "prompt": "You are a specialist in [domain]...",
  "model": "claude-sonnet-4-20250514",
  "tools": ["read", "write", "glob", "grep", "shell"],
  "resources": ["file://relevant/paths/**/*"]
}
```

3. Add to ralph-master if needed for parallel work:
```json
// In ralph-master.json
{
  "agents": [
    "security-specialist",
    "my-agent"  // Add here
  ]
}
```

### Configuring Workflows

Edit `.kiro/workflows/ralph-kiro.sh` to customize:
- Agent list (line 7-10)
- Parallel count
- Completion signals
- Monitoring intervals

### Adding Custom Prompts

Create new prompts in `.kiro/prompts/`:
```markdown
# .kiro/prompts/my-workflow.md

## Purpose
[What this prompt does]

## Instructions
1. Step 1
2. Step 2
3. Step 3

## Output Format
[Expected output structure]
```

## Troubleshooting

### "Agent not found"
- Verify `.kiro/agents/[name].json` exists
- Check JSON syntax is valid
- Ensure `name` field matches filename

### "Permission denied" on workflows
```bash
chmod +x .kiro/workflows/*.sh
```

### Agents not completing
- Check `activity.log` for errors
- Verify `<promise>DONE</promise>` signal is being written
- Increase timeout in ralph-kiro.sh

### Context window exceeded
- Reduce files in `resources` array
- Use more specific glob patterns
- Split into C-threads (phases)

## Environment Variables

Optional environment variables:
```bash
export KIRO_MODEL="claude-opus-4-5-20251101"  # Default model
export KIRO_PARALLEL=5                          # Default parallel count
export KIRO_TIMEOUT=3600                        # Default timeout (seconds)
```

## File Locations

| File | Purpose |
|------|---------|
| `PLAN.md` | Task checklist (project root) |
| `PROGRESS.md` | Agent progress tracking (project root) |
| `activity.log` | Execution timeline (project root) |
| `.kiro/` | All orchestration config |
| `~/.kiro/evolution/` | Global agent evolution logs |

## Next Steps

1. Read [Thread Engineering Guide](thread-engineering-guide.md)
2. Run your first P-thread with `ralph-kiro.sh`
3. Customize agents for your domain
4. Track improvements with metrics

---

*For issues or enhancements, update the template and re-copy to projects.*
