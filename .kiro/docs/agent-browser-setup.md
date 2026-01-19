# Agent Browser Setup

Quick setup guide for Vercel Labs agent-browser in the Orchestrator Template.

## Installation

### Option 1: Global Installation (Recommended)
```bash
npm install -g agent-browser
```

**Pros:**
- Available in all projects
- Agents can use it immediately
- No project-specific setup

### Option 2: Project-Specific
```bash
npm install agent-browser --save-dev
```

**Pros:**
- Version locked per project
- Included in package.json

### Verify Installation
```bash
agent-browser --version
```

You should see output like: `agent-browser v1.x.x`

## Quick Test

```bash
# Navigate to a page
agent-browser open https://example.com

# Get page structure
agent-browser snapshot --json

# Take a screenshot
agent-browser screenshot
```

If these commands work, you're all set!

## Configuration (Optional)

### Custom Browser Executable
If you want to use a specific Chrome/Chromium installation:

```bash
# Set environment variable
export AGENT_BROWSER_EXECUTABLE_PATH=/path/to/chrome

# Or use flag
agent-browser --executable-path /path/to/chrome open https://example.com
```

### Default Session
Set a default session name:

```bash
export AGENT_BROWSER_SESSION=my-default-session
```

## Usage with Kiro Agents

### test-architect Agent
The test-architect agent can now use agent-browser for E2E testing:

```bash
kiro-cli --agent test-architect
```

Then ask:
```
"Open https://example.com, take a snapshot, and verify the page title"
```

### frontend-designer Agent
The frontend-designer agent can use agent-browser for accessibility testing:

```bash
kiro-cli --agent frontend-designer
```

Then ask:
```
"Check the accessibility of https://example.com"
```

## Common Issues

### "agent-browser: command not found"
**Solution:** Install globally or add to PATH:
```bash
npm install -g agent-browser
```

### Browser won't start
**Solution:** Try headed mode to see errors:
```bash
agent-browser --headed open https://example.com
```

### Permission errors
**Solution:** Check browser executable permissions:
```bash
# macOS/Linux
chmod +x /path/to/chrome
```

### Port already in use
**Solution:** Use a different session:
```bash
agent-browser --session test1 open https://example.com
```

## Next Steps

1. ✅ Install agent-browser
2. 📖 Read [agent-browser-guide.md](.kiro/docs/agent-browser-guide.md)
3. 💡 Check [agent-browser-examples.md](.kiro/examples/agent-browser-examples.md)
4. 🧪 Test with agents: `kiro-cli --agent test-architect`

## Resources

- **GitHub**: https://github.com/vercel-labs/agent-browser
- **Guide**: `.kiro/docs/agent-browser-guide.md`
- **Examples**: `.kiro/examples/agent-browser-examples.md`

---

**Need help?** Check the troubleshooting section in the [agent-browser guide](.kiro/docs/agent-browser-guide.md).
