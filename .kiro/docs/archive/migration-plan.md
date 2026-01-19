# Migration Plan: Playwright → Vercel Agent Browser

## Overview
Migrate the Orchestrator Template from Playwright to Vercel Labs agent-browser for browser automation. Agent-browser is a headless browser automation CLI built specifically for AI agents, with fast Rust CLI and semantic locators optimized for LLM usage.

## Priority 1: Core Migration

### 1.1 Install Agent Browser
**Installation**:
```bash
npm install -g agent-browser
# or
npm install agent-browser --save-dev
```

**Verify installation**:
```bash
agent-browser --version
```

### 1.2 Remove MCP Configuration (Optional)
**File**: `.kiro/settings/mcp.json`

Agent-browser is a CLI tool, not an MCP server, so it doesn't need MCP configuration. You can:
- **Option A**: Remove the Playwright MCP server entry entirely
- **Option B**: Keep it disabled for potential future use

**Updated config**:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@anthropic/mcp-playwright"],
      "env": {},
      "disabled": true,
      "autoApprove": []
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-context7"],
      "env": {},
      "autoApprove": [
        "search_docs",
        "get_docs"
      ]
    }
  }
}
```

### 1.3 Update Agent Configurations
**Files to modify**:
- `.kiro/agents/test-architect.json`
- `.kiro/agents/frontend-designer.json`

**Changes**:
1. Replace `shell:playwright` with `shell:agent-browser` in `allowedTools`
2. Update tool references in prompts from Playwright to agent-browser
3. Remove config file patterns (`playwright.config.*`)
4. Add agent-browser to allowed shell commands

### 1.4 Update Documentation Files

**Files to update**:
- `.kiro/prompts/rca.md` - Line 21: Change "Playwright or unit" to "E2E or unit"
- `.kiro/prompts/a11y-audit.md` - Line 8: Change "Use Playwright accessibility snapshot" to "Use agent-browser snapshot"
- `.kiro/agent_docs/testing.md` - Line 18: Change "Run in browser with Playwright" to "Run in browser with agent-browser"
- `.kiro/agents/README.md` - Lines 87, 155: Update references from Playwright to agent-browser

### 1.5 Update Steering Files
**File**: `.kiro/steering/testing-standards.md`

Update E2E testing section to reference agent-browser instead of Playwright.

## Priority 2: Additional Improvements

### 2.1 Add Agent Browser Documentation
**New file**: `.kiro/docs/agent-browser-guide.md`

Create comprehensive guide covering:
- Core commands (open, click, fill, snapshot, screenshot)
- Semantic locators (refs) for deterministic element selection
- JSON output mode for AI agents
- Session management for parallel instances
- Network inspection and cookies
- Best practices for AI agents

### 2.2 Update CLAUDE.md
Add agent-browser to the tools reference section with common commands.

### 2.3 Create Migration Examples
**New file**: `.kiro/examples/agent-browser-examples.md`

Provide side-by-side comparisons:
- Playwright → agent-browser equivalents
- Common workflows (navigation, interaction, assertions)
- Snapshot-based element selection
- Authenticated sessions with headers

### 2.4 Update Test Architect Prompt
Enhance the test-architect agent prompt with agent-browser specific patterns:
- Snapshot-first workflow (snapshot → find refs → interact)
- Semantic locators for reliable element selection
- JSON output parsing for assertions
- Session isolation for parallel tests

## Benefits of Agent Browser

1. **Built for AI Agents**: Designed specifically for LLM-driven automation
2. **Fast Performance**: Rust CLI with Node.js fallback for speed
3. **Semantic Locators**: Refs provide deterministic element selection from snapshots
4. **JSON Output Mode**: Machine-readable output perfect for AI parsing
5. **No Config Files**: No need for playwright.config.* files
6. **Session Isolation**: Run multiple isolated browser instances in parallel
7. **Simple CLI**: Clean command structure that AI agents understand easily
8. **Snapshot-First Workflow**: Get page structure before interacting (optimal for AI)

## Migration Checklist

- [ ] Install agent-browser globally or as dev dependency
- [ ] Update `.kiro/settings/mcp.json` (disable Playwright)
- [ ] Update `test-architect.json` agent config
- [ ] Update `frontend-designer.json` agent config
- [ ] Update `.kiro/prompts/rca.md`
- [ ] Update `.kiro/prompts/a11y-audit.md`
- [ ] Update `.kiro/agent_docs/testing.md`
- [ ] Update `.kiro/agents/README.md`
- [ ] Update `.kiro/steering/testing-standards.md`
- [ ] Create `.kiro/docs/agent-browser-guide.md`
- [ ] Update `CLAUDE.md` with agent-browser reference
- [ ] Create `.kiro/examples/agent-browser-examples.md`
- [ ] Test with sample browser automation task
- [ ] Update README.md if it mentions Playwright

## Testing Strategy

After migration:
1. Test basic navigation: `agent-browser open https://example.com`
2. Test snapshot: `agent-browser snapshot --json`
3. Test interaction: `agent-browser click "button[name='login']"`
4. Test with AI agent: `@test-architect "Open https://example.com, take a snapshot, and click the first button"`
5. Test session isolation: `agent-browser --session test1 open https://example.com`

## Rollback Plan

If issues arise:
1. Re-enable Playwright MCP in `.kiro/settings/mcp.json`
2. Restore agent config files from git history
3. Uninstall agent-browser: `npm uninstall -g agent-browser`
4. Document issues in LEARNINGS.md for future attempts

---

## Agent Browser Quick Reference

### Core Commands
```bash
# Navigation
agent-browser open https://example.com
agent-browser back
agent-browser forward
agent-browser reload

# Inspection
agent-browser snapshot --json          # Get page structure
agent-browser snapshot --interactive   # Only interactive elements
agent-browser screenshot --full        # Full page screenshot

# Interaction
agent-browser click "ref:123"          # Click by ref from snapshot
agent-browser fill "input[name='email']" "test@example.com"
agent-browser text "Hello world"       # Type text
agent-browser press "Enter"            # Press key

# Wait
agent-browser wait "button.submit"     # Wait for element
agent-browser wait --load              # Wait for page load

# Sessions (parallel instances)
agent-browser --session test1 open https://example.com
agent-browser --session test2 open https://google.com

# JSON mode (for AI agents)
agent-browser --json snapshot
agent-browser --json state
```

### Optimal AI Workflow
1. **Navigate**: `agent-browser open <url>`
2. **Snapshot**: `agent-browser snapshot --json` (get refs)
3. **Interact**: `agent-browser click "ref:123"` (use refs from snapshot)
4. **Verify**: `agent-browser snapshot --json` (check result)

---

**Estimated Time**: 2-3 hours
**Risk Level**: Low (agent-browser is a separate CLI tool, doesn't interfere with existing setup)
