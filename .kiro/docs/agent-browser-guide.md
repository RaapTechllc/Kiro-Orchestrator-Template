# Agent Browser Guide

Comprehensive guide for using Vercel Labs agent-browser for browser automation in AI agent workflows.

## Overview

agent-browser is a headless browser automation CLI built specifically for AI agents. It features:
- **Fast Rust CLI** with Node.js fallback
- **Semantic locators** (refs) for deterministic element selection
- **JSON output mode** for machine-readable results
- **Session isolation** for parallel browser instances
- **Snapshot-first workflow** optimized for AI agents

## Installation

```bash
# Global installation (recommended)
npm install -g agent-browser

# Project-specific
npm install agent-browser --save-dev

# Verify installation
agent-browser --version
```

## Core Workflow

### 1. Navigate
```bash
agent-browser open https://example.com
agent-browser back
agent-browser forward
agent-browser reload
```

### 2. Inspect (Snapshot-First)
```bash
# Get page structure with refs
agent-browser snapshot --json

# Only interactive elements
agent-browser snapshot --interactive

# Compact output (remove empty structural elements)
agent-browser snapshot --compact

# Limit tree depth
agent-browser snapshot --depth 3

# Scope to specific selector
agent-browser snapshot --selector "main"
```

### 3. Interact
```bash
# Click using ref from snapshot
agent-browser click "ref:123"

# Fill form fields
agent-browser fill "input[name='email']" "test@example.com"
agent-browser fill "ref:456" "password123"

# Type text
agent-browser text "Hello world"

# Press keys
agent-browser press "Enter"
agent-browser press "Control+A"

# Hover
agent-browser hover "button.submit"

# Check/uncheck
agent-browser check "input[type='checkbox']"
agent-browser uncheck "input[type='checkbox']"
```

### 4. Wait
```bash
# Wait for element
agent-browser wait "button.submit"

# Wait for page load
agent-browser wait --load

# Wait for network idle
agent-browser wait --networkidle
```

### 5. Capture
```bash
# Screenshot
agent-browser screenshot
agent-browser screenshot --full
agent-browser screenshot --name "login-page"

# Get current state
agent-browser state
agent-browser url
```

## Selectors

### Refs (Recommended for AI)
Refs provide deterministic element selection from snapshots:

```bash
# 1. Get snapshot
agent-browser snapshot --json > page.json

# 2. Parse to find element ref
# Example: ref:123 for login button

# 3. Use ref for interaction
agent-browser click "ref:123"
```

**Why use refs?**
- Stable across page changes
- Deterministic (same element = same ref)
- AI-friendly (no need to construct complex selectors)

### CSS Selectors
```bash
agent-browser click "button.primary"
agent-browser fill "input[name='email']" "test@example.com"
agent-browser hover "#menu-trigger"
```

### Text Selectors
```bash
agent-browser click "text:Login"
agent-browser click "text:Sign up"
```

### Semantic Locators
```bash
agent-browser click "button:Login"
agent-browser click "link:Documentation"
```

## JSON Mode (For AI Agents)

Use `--json` for machine-readable output:

```bash
# Get structured page data
agent-browser --json snapshot

# Get current state
agent-browser --json state

# Get URL
agent-browser --json url
```

**Example JSON output:**
```json
{
  "elements": [
    {
      "ref": "ref:123",
      "role": "button",
      "name": "Login",
      "tag": "button",
      "attributes": {
        "type": "submit",
        "class": "btn-primary"
      }
    }
  ]
}
```

## Session Management

Run multiple isolated browser instances:

```bash
# Session 1
agent-browser --session test1 open https://example.com
agent-browser --session test1 snapshot

# Session 2 (parallel)
agent-browser --session test2 open https://google.com
agent-browser --session test2 snapshot

# Each session has its own:
# - Cookies
# - Local storage
# - Browser state
# - Navigation history
```

## Authentication

### Using Headers
```bash
# Set headers for specific origin
agent-browser open https://api.example.com \
  --headers '{"Authorization":"Bearer token123"}'

# Headers are scoped to the URL's origin
```

### Using Cookies
```bash
# Set cookies
agent-browser cookies set "session_id" "abc123" --domain "example.com"

# Get cookies
agent-browser cookies get

# Clear cookies
agent-browser cookies clear
```

## Advanced Features

### Network Inspection
```bash
# Monitor network requests
agent-browser network

# Clear network log
agent-browser network clear
```

### Custom Browser
```bash
# Use custom Chrome/Chromium
agent-browser --executable-path /path/to/chrome open https://example.com

# Or set environment variable
export AGENT_BROWSER_EXECUTABLE_PATH=/path/to/chrome
```

### Headed Mode (Debug)
```bash
# Show browser window
agent-browser --headed open https://example.com
```

### CDP Mode
```bash
# Connect to existing browser via Chrome DevTools Protocol
agent-browser --cdp 9222 open https://example.com
```

## AI Agent Patterns

### Pattern 1: Snapshot → Interact → Verify
```bash
# 1. Navigate
agent-browser open https://app.example.com/login

# 2. Snapshot to find elements
agent-browser snapshot --json > login-page.json

# 3. Parse JSON to find refs (AI does this)
# email_input: ref:101
# password_input: ref:102
# submit_button: ref:103

# 4. Interact using refs
agent-browser fill "ref:101" "user@example.com"
agent-browser fill "ref:102" "password123"
agent-browser click "ref:103"

# 5. Wait and verify
agent-browser wait --load
agent-browser snapshot --json > dashboard.json
# AI verifies login success by checking for dashboard elements
```

### Pattern 2: Form Filling
```bash
# Snapshot first
agent-browser snapshot --interactive --json > form.json

# AI identifies all form fields and fills them
agent-browser fill "ref:201" "John Doe"
agent-browser fill "ref:202" "john@example.com"
agent-browser check "ref:203"  # Terms checkbox
agent-browser click "ref:204"  # Submit
```

### Pattern 3: Navigation Testing
```bash
# Test navigation flow
agent-browser open https://example.com
agent-browser click "text:Products"
agent-browser wait --load
agent-browser snapshot --json | jq '.url'  # Verify URL changed

agent-browser click "text:Pricing"
agent-browser wait --load
agent-browser snapshot --json | jq '.url'  # Verify URL changed
```

### Pattern 4: Accessibility Testing
```bash
# Get full accessibility tree
agent-browser snapshot --json > a11y.json

# AI checks for:
# - Missing alt text
# - Improper heading hierarchy
# - Missing ARIA labels
# - Keyboard navigation issues
```

## Best Practices

### 1. Always Snapshot First
```bash
# GOOD: Snapshot before interacting
agent-browser snapshot --json
agent-browser click "ref:123"

# BAD: Guessing selectors
agent-browser click "button.submit"  # Might break if class changes
```

### 2. Use Refs for Stability
```bash
# GOOD: Refs are stable
agent-browser click "ref:123"

# LESS GOOD: CSS selectors can break
agent-browser click "div.container > button:nth-child(3)"
```

### 3. Wait for State Changes
```bash
# GOOD: Wait after navigation
agent-browser click "ref:123"
agent-browser wait --load
agent-browser snapshot --json

# BAD: Snapshot too early
agent-browser click "ref:123"
agent-browser snapshot --json  # Might capture old state
```

### 4. Use Sessions for Isolation
```bash
# GOOD: Isolated test environments
agent-browser --session test1 open https://example.com
agent-browser --session test2 open https://example.com

# BAD: Shared state between tests
agent-browser open https://example.com  # Default session
```

### 5. JSON Mode for Parsing
```bash
# GOOD: Machine-readable output
agent-browser --json snapshot | jq '.elements[] | select(.role=="button")'

# BAD: Parsing human-readable output
agent-browser snapshot | grep "button"
```

## Troubleshooting

### Browser Won't Start
```bash
# Check if browser is already running
ps aux | grep chrome

# Try headed mode to see errors
agent-browser --headed open https://example.com

# Use custom executable
agent-browser --executable-path /usr/bin/chromium open https://example.com
```

### Element Not Found
```bash
# Take snapshot to see what's available
agent-browser snapshot --interactive

# Wait for element to appear
agent-browser wait "button.submit"
agent-browser click "button.submit"
```

### Session Issues
```bash
# List active sessions
agent-browser sessions

# Clear specific session
agent-browser --session test1 close

# Clear all sessions
agent-browser sessions clear
```

## Integration with Kiro Agents

### test-architect Agent
```bash
# E2E test workflow
agent-browser open https://app.example.com
agent-browser snapshot --json > initial.json
agent-browser click "ref:login-button"
agent-browser fill "ref:email" "test@example.com"
agent-browser fill "ref:password" "test123"
agent-browser click "ref:submit"
agent-browser wait --load
agent-browser snapshot --json > logged-in.json
# Verify success by checking for dashboard elements
```

### frontend-designer Agent
```bash
# Visual and accessibility testing
agent-browser open https://app.example.com
agent-browser screenshot --full --name "homepage"
agent-browser snapshot --json > a11y-tree.json
# AI analyzes for accessibility issues
```

## Environment Variables

```bash
# Custom browser executable
export AGENT_BROWSER_EXECUTABLE_PATH=/path/to/chrome

# Default session name
export AGENT_BROWSER_SESSION=my-session

# Streaming port (for live preview)
export AGENT_BROWSER_STREAM_PORT=9223
```

## Command Reference

| Command | Description |
|---------|-------------|
| `open <url>` | Navigate to URL |
| `back` | Go back in history |
| `forward` | Go forward in history |
| `reload` | Reload current page |
| `snapshot` | Get page structure |
| `screenshot` | Capture screenshot |
| `click <selector>` | Click element |
| `fill <selector> <value>` | Fill input field |
| `text <value>` | Type text |
| `press <key>` | Press keyboard key |
| `hover <selector>` | Hover over element |
| `check <selector>` | Check checkbox |
| `uncheck <selector>` | Uncheck checkbox |
| `wait <selector>` | Wait for element |
| `state` | Get current state |
| `url` | Get current URL |
| `cookies` | Manage cookies |
| `network` | Network inspection |
| `sessions` | Manage sessions |

## Options

| Option | Description |
|--------|-------------|
| `--json` | JSON output mode |
| `--session <name>` | Use isolated session |
| `--headers <json>` | Set HTTP headers |
| `--executable-path <path>` | Custom browser executable |
| `--full, -f` | Full page screenshot |
| `--interactive, -i` | Only interactive elements |
| `--compact, -c` | Remove empty elements |
| `--depth <n>, -d` | Limit tree depth |
| `--selector <sel>, -s` | Scope to selector |
| `--headed` | Show browser window |
| `--cdp <port>` | Connect via CDP |

---

**For more information:** https://github.com/vercel-labs/agent-browser
