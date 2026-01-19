# Browser Automation

Quick reference for browser automation in the Orchestrator Template.

## Tool: agent-browser

The template uses [Vercel Labs agent-browser](https://github.com/vercel-labs/agent-browser) for browser automation.

### Why agent-browser?
- **Built for AI agents**: Snapshot-first workflow with deterministic refs
- **Fast**: Rust CLI with Node.js fallback
- **Simple**: No config files needed
- **AI-friendly**: JSON output mode for parsing
- **Parallel**: Session isolation built-in

## Quick Start

### Installation
```bash
npm install -g agent-browser
```

### Basic Usage
```bash
# Navigate
agent-browser open https://example.com

# Get page structure (AI-friendly)
agent-browser snapshot --json

# Interact using refs
agent-browser click "ref:123"

# Screenshot
agent-browser screenshot --full
```

## Agents with Browser Automation

### test-architect
E2E testing with agent-browser:
```bash
kiro-cli --agent test-architect
# Ask: "Open example.com and verify the page loads"
```

### frontend-designer
Accessibility testing with agent-browser:
```bash
kiro-cli --agent frontend-designer
# Ask: "Check accessibility of example.com"
```

## Documentation

- **[agent-browser-guide.md](./agent-browser-guide.md)** - Comprehensive guide
- **[agent-browser-setup.md](./agent-browser-setup.md)** - Quick setup
- **[Examples](../examples/agent-browser-examples.md)** - Usage examples

## Key Patterns

### Snapshot-First Workflow
```bash
# 1. Navigate
agent-browser open https://app.example.com

# 2. Snapshot to get refs
agent-browser snapshot --json > page.json

# 3. AI parses JSON to find elements
# Example: login button is ref:123

# 4. Interact using refs
agent-browser click "ref:123"
```

### Why Refs?
- **Stable**: Same element = same ref
- **Deterministic**: No guessing selectors
- **AI-friendly**: Easy to parse and use

## Resources

- **GitHub**: https://github.com/vercel-labs/agent-browser
- **Setup**: [agent-browser-setup.md](./agent-browser-setup.md)
- **Guide**: [agent-browser-guide.md](./agent-browser-guide.md)
- **Examples**: [agent-browser-examples.md](../examples/agent-browser-examples.md)
