# Learnings & Corrections

Captured patterns, corrections, and preferences for continuous improvement.

## Browser Automation (2026-01-19)

**PATTERN:** Snapshot-first workflow with agent-browser
- Always snapshot before interacting: `agent-browser snapshot --json`
- Use refs from snapshots for stable element selection: `agent-browser click "ref:123"`
- JSON mode for all AI agent workflows: `agent-browser --json snapshot`
- Sessions for parallel test isolation: `agent-browser --session test1`

**PREFER:** Use refs over CSS selectors for stability
- Refs are deterministic and stable across page changes
- Better for AI agents than fragile CSS selectors

**AVOID:** Guessing CSS selectors
- Always snapshot first to get current page state
- Use refs from snapshots instead of constructing selectors

---

## Template for Future Learnings

### CORRECTION: [What was wrong]
**Why:** [Explanation]
**Fix:** [What to do instead]

### PREFER: [Preferred approach]
**Over:** [Alternative approach]
**Because:** [Reasoning]

### PATTERN: [Workflow pattern]
**When:** [Trigger condition]
**Do:** [Steps to follow]

### AVOID: [Anti-pattern]
**Why:** [Explanation]
**Instead:** [Better approach]

---

*Last updated: 2026-01-19*

