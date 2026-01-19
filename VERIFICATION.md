# Template Verification

Quick verification steps to ensure the template is functional.

## ✅ Pre-Flight Checks

### 1. File Structure
```bash
# Check core files exist
ls CLAUDE.md AGENTS.md README.md LEARNINGS.md PLAN.md PROGRESS.md CHANGELOG.md

# Check .kiro structure
ls .kiro/agents/ .kiro/docs/ .kiro/prompts/ .kiro/workflows/ .kiro/steering/
```

### 2. Configuration Files
```bash
# Check MCP config
cat .kiro/settings/mcp.json

# Should show:
# - playwright: disabled
# - context7: enabled
```

### 3. Agent Configurations
```bash
# Check test-architect has agent-browser
grep -i "agent-browser" .kiro/agents/test-architect.json

# Check frontend-designer has agent-browser
grep -i "agent-browser" .kiro/agents/frontend-designer.json
```

### 4. Documentation
```bash
# Check browser automation docs exist
ls .kiro/docs/agent-browser-guide.md
ls .kiro/docs/agent-browser-setup.md
ls .kiro/docs/browser-automation.md
ls .kiro/examples/agent-browser-examples.md
```

### 5. Archive
```bash
# Check migration docs are archived
ls .kiro/docs/archive/migration-*.md
ls .kiro/docs/archive/README.md
```

## 🧪 Functional Tests

### Test 1: agent-browser Installation
```bash
# Install agent-browser
npm install -g agent-browser

# Verify installation
agent-browser --version
```

### Test 2: Basic agent-browser Usage
```bash
# Navigate to a page
agent-browser open https://example.com

# Get snapshot
agent-browser snapshot --json

# Take screenshot
agent-browser screenshot
```

### Test 3: Agent Invocation
```bash
# Test orchestrator
kiro-cli --agent orchestrator
# Should start without errors

# Test test-architect
kiro-cli --agent test-architect
# Should start without errors

# Test frontend-designer
kiro-cli --agent frontend-designer
# Should start without errors
```

### Test 4: Browser Automation with Agents
```bash
# Start test-architect
kiro-cli --agent test-architect

# Ask: "Open https://example.com and take a snapshot"
# Should execute agent-browser commands successfully
```

## 📋 Verification Checklist

- [ ] All core files present
- [ ] .kiro directory structure intact
- [ ] MCP configuration correct
- [ ] Agent configs have agent-browser
- [ ] Browser automation docs exist
- [ ] Migration docs archived
- [ ] agent-browser installs successfully
- [ ] agent-browser basic commands work
- [ ] Agents start without errors
- [ ] Agents can use agent-browser

## ✅ Expected Results

### Configuration
- Playwright MCP: `"disabled": true`
- context7 MCP: Active with autoApprove
- test-architect: Has `shell:agent-browser` in allowedTools
- frontend-designer: Has `shell:agent-browser` in allowedTools

### Documentation
- 4 browser automation docs in `.kiro/docs/` and `.kiro/examples/`
- 3 migration docs in `.kiro/docs/archive/`
- CHANGELOG.md with v2.0.0 entry
- LEARNINGS.md with browser automation patterns

### Functionality
- agent-browser commands execute successfully
- Agents start without configuration errors
- Agents can invoke agent-browser via shell commands

## 🐛 Troubleshooting

### agent-browser not found
```bash
# Install globally
npm install -g agent-browser

# Or check PATH
which agent-browser
```

### Agent configuration errors
```bash
# Check agent JSON syntax
cat .kiro/agents/test-architect.json | jq .

# Verify allowedTools includes agent-browser
jq '.allowedTools' .kiro/agents/test-architect.json
```

### MCP configuration issues
```bash
# Verify MCP config syntax
cat .kiro/settings/mcp.json | jq .

# Check Playwright is disabled
jq '.mcpServers.playwright.disabled' .kiro/settings/mcp.json
```

## ✅ Success Criteria

Template is verified when:
1. All files and directories are present
2. Configurations are syntactically valid
3. agent-browser installs and runs
4. Agents start without errors
5. Agents can execute agent-browser commands

---

**Run these checks after cloning the template to ensure everything works!**
