# Orchestrator Self-Improvement Implementation Guide

**Purpose:** This document provides instructions for the orchestrator to implement five high-impact features that will upgrade the multi-agent workflow system. Execute these in order.

**Source:** Patterns extracted from Cole's Kiro Hackathon videos, AWS Labs CLI Agent Orchestrator, and Kiro CLI official documentation.

**Target Repository:** Kiro-Orchestrator-Template

---

## Overview

You are implementing five features:

1. **Agent Spawn Context Injection** — Agents know where they are when they start
2. **Stop Hook Self-Validation** — Agents verify their work before finishing
3. **Interactive PRD Planning** — Better planning through structured questions
4. **Code Review Swarm** — Parallel specialized reviewers
5. **GitHub PR Coordination** — PRs as the orchestration layer

Execute in this order. Each feature builds foundation for the next.

---

## Feature 1: Agent Spawn Context Injection

### Problem
Agents start without knowing their context. They don't know what branch they're on, what task they're doing, or that they're in an isolated work tree. This causes them to make wrong assumptions and sometimes break out of their intended scope.

### Solution
Add `agentSpawn` hooks to all agent configurations. These hooks run shell commands when the agent initializes. The output is captured and shown to the agent as its first context.

### Implementation

**Step 1: Create a shared context script**

Create file: `.kiro/scripts/inject-context.sh`

```bash
#!/bin/bash
# Context injection script for agent spawn
# Outputs context information for the agent to consume

echo "═══════════════════════════════════════════════════════════"
echo "AGENT CONTEXT INJECTION"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "## Working Directory"
pwd
echo ""
echo "## Git Branch"
git branch --show-current 2>/dev/null || echo "Not in a git repository"
echo ""
echo "## Git Status (brief)"
git status --short 2>/dev/null | head -10
echo ""
echo "## Active Plan"
if [ -f PLAN.md ]; then
  head -40 PLAN.md
else
  echo "No PLAN.md found in current directory"
fi
echo ""
echo "## Current Progress"
if [ -f PROGRESS.md ]; then
  tail -25 PROGRESS.md
else
  echo "No PROGRESS.md found in current directory"
fi
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "IMPORTANT: You are in an isolated environment."
echo "DO NOT switch branches or navigate to parent directories."
echo "Complete your assigned task within this context."
echo "═══════════════════════════════════════════════════════════"
```

Make executable: `chmod +x .kiro/scripts/inject-context.sh`

**Step 2: Update agent configurations**

For each agent in `.kiro/agents/`, add the `hooks` section if not present, or add to existing hooks.

Add to these agents:
- `orchestrator.json`
- `ralph-master.json`
- `code-surgeon.json`
- `test-architect.json`
- `frontend-designer.json`
- `db-wizard.json`
- `devops-automator.json`
- `doc-smith.json`
- `security-specialist.json`

Hook configuration to add:

```json
{
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash .kiro/scripts/inject-context.sh 2>/dev/null || echo 'Context script not found - running from project root recommended'",
        "timeout_ms": 5000
      }
    ]
  }
}
```

**Step 3: Create worktree-specific context injection**

Create file: `.kiro/scripts/inject-worktree-context.sh`

```bash
#!/bin/bash
# Enhanced context for worktree environments
# Used by Ralph loop and parallel execution agents

echo "═══════════════════════════════════════════════════════════"
echo "WORKTREE AGENT CONTEXT"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "## Environment"
echo "Working Directory: $(pwd)"
echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
echo "Git Root: $(git rev-parse --show-toplevel 2>/dev/null || echo 'unknown')"
echo ""

# Check if we're in a worktree
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  WORKTREE_ROOT=$(git rev-parse --show-toplevel)
  MAIN_WORKTREE=$(git worktree list | head -1 | awk '{print $1}')
  
  if [ "$WORKTREE_ROOT" != "$MAIN_WORKTREE" ]; then
    echo "## Worktree Status: ISOLATED WORKTREE"
    echo "Main Repository: $MAIN_WORKTREE"
    echo "Current Worktree: $WORKTREE_ROOT"
    echo ""
    echo "⚠️  YOU ARE IN AN ISOLATED WORKTREE"
    echo "⚠️  Do NOT run: git checkout, git switch, cd .."
    echo "⚠️  Stay in this directory and complete your task"
  else
    echo "## Worktree Status: MAIN REPOSITORY"
  fi
fi

echo ""
echo "## Task Assignment"
if [ -f PLAN.md ]; then
  echo "Plan file found. Current tasks:"
  grep -E "^- \[ \]" PLAN.md | head -10
else
  echo "No PLAN.md - check for task in conversation context"
fi

echo ""
echo "## Recent Activity"
if [ -f PROGRESS.md ]; then
  echo "Last 10 progress entries:"
  tail -10 PROGRESS.md
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
```

**Step 4: Update Ralph-related agents to use worktree context**

For `ralph-master.json` and any Ralph loop agents, use the enhanced script:

```json
{
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash .kiro/scripts/inject-worktree-context.sh 2>/dev/null || bash .kiro/scripts/inject-context.sh 2>/dev/null || echo 'Running without context injection'",
        "timeout_ms": 8000
      }
    ]
  }
}
```

### Acceptance Criteria
- [ ] `inject-context.sh` exists and is executable
- [ ] `inject-worktree-context.sh` exists and is executable
- [ ] All 9 main agents have `agentSpawn` hooks configured
- [ ] When starting any agent, context information appears before first prompt
- [ ] Agents in worktrees see the isolation warning

---

## Feature 2: Stop Hook Self-Validation

### Problem
Agents complete tasks and say "done" without verifying their work actually functions. This requires manual testing and reduces trust in agent output.

### Solution
Add `stop` hooks that run validation commands after each agent response. The output feeds back to the agent, allowing it to see failures and self-correct.

### Implementation

**Step 1: Create validation script**

Create file: `.kiro/scripts/validate-changes.sh`

```bash
#!/bin/bash
# Post-response validation script
# Runs appropriate tests based on project type

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "VALIDATION RESULTS"
echo "═══════════════════════════════════════════════════════════"

VALIDATION_FAILED=0

# Node.js / TypeScript projects
if [ -f package.json ]; then
  echo ""
  echo "## Package.json detected - running Node validations"
  
  # TypeScript check
  if grep -q '"typescript"' package.json 2>/dev/null || [ -f tsconfig.json ]; then
    echo ""
    echo "### TypeScript Compilation"
    npx tsc --noEmit 2>&1 | tail -15
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      VALIDATION_FAILED=1
      echo "❌ TypeScript errors detected"
    else
      echo "✅ TypeScript compilation passed"
    fi
  fi
  
  # Lint check
  if grep -q '"lint"' package.json 2>/dev/null; then
    echo ""
    echo "### Linting"
    npm run lint 2>&1 | tail -10
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      echo "⚠️  Lint warnings/errors detected"
    else
      echo "✅ Linting passed"
    fi
  fi
  
  # Test check (only if tests exist)
  if grep -q '"test"' package.json 2>/dev/null; then
    echo ""
    echo "### Tests"
    timeout 60 npm test 2>&1 | tail -20
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      VALIDATION_FAILED=1
      echo "❌ Tests failed"
    else
      echo "✅ Tests passed"
    fi
  fi
fi

# Python projects
if [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f setup.py ]; then
  echo ""
  echo "## Python project detected - running Python validations"
  
  # Pytest
  if [ -f pytest.ini ] || [ -d tests ] || [ -d test ]; then
    echo ""
    echo "### Pytest"
    timeout 60 pytest --tb=short -q 2>&1 | tail -20
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      VALIDATION_FAILED=1
      echo "❌ Pytest failed"
    else
      echo "✅ Pytest passed"
    fi
  fi
  
  # Type checking with mypy
  if [ -f mypy.ini ] || grep -q "mypy" requirements.txt 2>/dev/null; then
    echo ""
    echo "### Mypy Type Checking"
    mypy . --ignore-missing-imports 2>&1 | tail -10
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      echo "⚠️  Type errors detected"
    else
      echo "✅ Type checking passed"
    fi
  fi
fi

# Go projects
if [ -f go.mod ]; then
  echo ""
  echo "## Go project detected - running Go validations"
  
  echo ""
  echo "### Go Build"
  go build ./... 2>&1 | tail -10
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    VALIDATION_FAILED=1
    echo "❌ Go build failed"
  else
    echo "✅ Go build passed"
  fi
  
  echo ""
  echo "### Go Test"
  timeout 60 go test ./... 2>&1 | tail -15
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    VALIDATION_FAILED=1
    echo "❌ Go tests failed"
  else
    echo "✅ Go tests passed"
  fi
fi

# Shell script validation
SHELL_SCRIPTS=$(find . -maxdepth 3 -name "*.sh" -type f 2>/dev/null | head -5)
if [ -n "$SHELL_SCRIPTS" ]; then
  echo ""
  echo "## Shell Scripts - Syntax Check"
  for script in $SHELL_SCRIPTS; do
    bash -n "$script" 2>&1
    if [ $? -ne 0 ]; then
      echo "❌ Syntax error in $script"
    fi
  done
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
if [ $VALIDATION_FAILED -eq 1 ]; then
  echo "❌ VALIDATION FAILED - Please fix the errors above"
  echo "Do not mark this task complete until validations pass."
else
  echo "✅ VALIDATION PASSED"
fi
echo "═══════════════════════════════════════════════════════════"

exit $VALIDATION_FAILED
```

Make executable: `chmod +x .kiro/scripts/validate-changes.sh`

**Step 2: Create lightweight validation for quick checks**

Create file: `.kiro/scripts/quick-validate.sh`

```bash
#!/bin/bash
# Lightweight validation - runs quickly after every response
# For full validation, use validate-changes.sh

echo ""
echo "── Quick Validation ──"

# Check for syntax errors in recently modified files
RECENT_FILES=$(git diff --name-only HEAD 2>/dev/null | head -5)

if [ -n "$RECENT_FILES" ]; then
  for file in $RECENT_FILES; do
    if [ -f "$file" ]; then
      case "$file" in
        *.js|*.ts|*.jsx|*.tsx)
          # Quick syntax check for JS/TS
          node --check "$file" 2>&1 | tail -3
          ;;
        *.py)
          # Quick syntax check for Python
          python -m py_compile "$file" 2>&1 | tail -3
          ;;
        *.sh)
          # Bash syntax check
          bash -n "$file" 2>&1 | tail -3
          ;;
        *.json)
          # JSON validation
          python -m json.tool "$file" > /dev/null 2>&1 || echo "❌ Invalid JSON: $file"
          ;;
      esac
    fi
  done
  echo "✓ Syntax check complete"
else
  echo "No uncommitted changes to validate"
fi
```

Make executable: `chmod +x .kiro/scripts/quick-validate.sh`

**Step 3: Add stop hooks to implementation agents**

Update these agents with stop hooks:
- `code-surgeon.json`
- `test-architect.json`
- `frontend-designer.json`
- `db-wizard.json`
- `devops-automator.json`

Add to each agent's hooks section:

```json
{
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash .kiro/scripts/inject-context.sh 2>/dev/null",
        "timeout_ms": 5000
      }
    ],
    "stop": [
      {
        "command": "bash .kiro/scripts/quick-validate.sh 2>/dev/null",
        "timeout_ms": 10000
      }
    ]
  }
}
```

**Step 4: Add full validation to orchestrator**

For `orchestrator.json`, use the comprehensive validation:

```json
{
  "hooks": {
    "agentSpawn": [
      {
        "command": "bash .kiro/scripts/inject-context.sh 2>/dev/null",
        "timeout_ms": 5000
      }
    ],
    "stop": [
      {
        "command": "bash .kiro/scripts/validate-changes.sh 2>/dev/null || true",
        "timeout_ms": 120000
      }
    ]
  }
}
```

**Step 5: Update steering to reference validation**

Add to `.kiro/steering/validation.md`:

```markdown
# Validation Protocol

## Automatic Validation
After every response, validation scripts run automatically via stop hooks.
You will see the output at the start of your next turn.

## Responding to Validation Failures

When you see validation failures:

1. **Read the error messages carefully** — They indicate exactly what's broken
2. **Fix the specific issues** — Don't rewrite entire files, target the problem
3. **Verify your fix** — After making changes, check if the validation passes
4. **Do not mark task complete** — Until validation shows ✅ PASSED

## Validation Types

- **TypeScript Compilation** — Type errors must be fixed
- **Linting** — Warnings are acceptable, errors should be fixed
- **Tests** — All tests must pass before completion
- **Syntax Checks** — Any syntax error is a blocker

## If Stuck

If you cannot resolve a validation error after 3 attempts:
1. Document what you tried
2. Explain what the error means
3. Escalate to human with full context
```

### Acceptance Criteria
- [ ] `validate-changes.sh` exists and is executable
- [ ] `quick-validate.sh` exists and is executable
- [ ] Implementation agents have `stop` hooks configured
- [ ] Orchestrator has comprehensive validation on stop
- [ ] `validation.md` steering file exists
- [ ] After agent response, validation output appears
- [ ] Agents acknowledge and act on validation failures

---

## Feature 3: Interactive PRD Planning

### Problem
Current planning assumes the user provides all context upfront. This leads to incomplete plans when requirements aren't fully specified.

### Solution
Create an interactive PRD prompt that asks structured questions before generating a plan. Two modes: Quick (all context upfront) and Interactive (guided questions).

### Implementation

**Step 1: Create the interactive PRD prompt**

Create file: `.kiro/prompts/ralph-prd.md`

```markdown
# Ralph PRD - Interactive Planning

You are creating a Product Requirements Document through structured dialogue.
This process ensures comprehensive planning before any implementation begins.

## Mode Selection

First, determine which mode to use:

**Quick Mode** — User says "quick", "fast", or provides extensive context upfront
**Interactive Mode** — Default. Use when context seems incomplete.

---

## Interactive Mode Process

Ask these questions ONE AT A TIME. Wait for each answer before proceeding.

### Question 1: Goal
"What is the main goal of this feature/task? What does success look like when it's complete?"

### Question 2: Requirements
"What are the specific requirements? Are there any hard constraints (tech stack, performance, compatibility)?"

### Question 3: Scope Boundaries
"What is explicitly OUT of scope? What should this NOT do or change?"

### Question 4: Dependencies
"What dependencies or blockers exist? Does this require other work to be completed first?"

### Question 5: Validation
"How will we know it's working? What tests or checks validate success?"

### Question 6: Risks
"What could go wrong? What's the rollback plan if this breaks something?"

---

## After All Questions Answered

Generate the PRD in this format:

```markdown
# PRD: [Feature Name]

**Created:** [Date]
**Status:** Draft
**Author:** Orchestrator + [Human Name if provided]

## Problem Statement
[1-2 sentences describing the problem this solves]

## Success Criteria
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

## Requirements

### Must Have
- [Requirement 1]
- [Requirement 2]

### Should Have
- [Requirement 3]

### Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Technical Approach
[High-level description of how this will be built]

### Components Affected
- [File/Module 1]
- [File/Module 2]

### Dependencies
- [Dependency 1]
- [Dependency 2]

## Task Breakdown

### Phase 1: [Name]
- [ ] Task 1.1 — [Description] (~[estimate])
- [ ] Task 1.2 — [Description] (~[estimate])

### Phase 2: [Name]
- [ ] Task 2.1 — [Description] (~[estimate])
- [ ] Task 2.2 — [Description] (~[estimate])

## Testing Strategy
- [ ] [Test type 1]: [What it validates]
- [ ] [Test type 2]: [What it validates]

## Risks & Mitigation
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to handle] |

## Rollback Plan
[Steps to undo this change if needed]
```

---

## Quick Mode Process

When in quick mode, skip the questions and generate the PRD directly from provided context.
Still include all sections, marking unknowns as "TBD - clarify before implementation".

---

## Output Location

Save the generated PRD to: `artifacts/plans/[feature-slug].md`

After saving, ask: "PRD saved. Ready to proceed with implementation, or would you like to revise any section?"
```

**Step 2: Create the quick planning prompt**

Create file: `.kiro/prompts/create-plan.md`

```markdown
# Create Plan - Quick Planning

Generate a structured implementation plan from the provided context.
This is the fast path when you already have comprehensive requirements.

## Input Expected
User provides: goal, constraints, scope, and any relevant context.

## Output Format

Generate a PLAN.md compatible task list:

```markdown
# Implementation Plan: [Feature Name]

**Created:** [Date]
**Estimated Effort:** [X hours/days]

## Overview
[1-2 sentence summary]

## Tasks

### Setup
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]

### Implementation
- [ ] Task 3: [Description]
- [ ] Task 4: [Description]
- [ ] Task 5: [Description]

### Testing
- [ ] Task 6: [Description]
- [ ] Task 7: [Description]

### Documentation
- [ ] Task 8: [Description]

## Notes
- [Important consideration 1]
- [Important consideration 2]

## Done Criteria
- [ ] All tasks checked
- [ ] Tests passing
- [ ] Documentation updated
```

## After Generation

1. Save to `PLAN.md` in current directory (or specified location)
2. Ask if user wants to start execution or modify the plan
```

**Step 3: Update the main plan-feature prompt**

Modify `.kiro/prompts/plan-feature.md` to route between modes:

```markdown
# Plan Feature

Intelligent planning that adapts to your input.

## Routing Logic

Analyze the user's request:

**Route to Interactive PRD (@ralph-prd) when:**
- Request is vague or high-level ("build a login system")
- Missing key details (no success criteria, no scope boundaries)
- User explicitly asks for "thorough" or "detailed" planning
- Complex feature spanning multiple components

**Route to Quick Plan (@create-plan) when:**
- User says "quick" or "fast"
- Comprehensive context already provided
- Simple, well-defined task
- User provides explicit requirements list

## Default Behavior

If uncertain, ask: "Would you like a quick plan from what you've provided, or should we go through the interactive PRD process to ensure nothing is missed?"

## Integration with Execution

After planning completes:
1. Plan is saved to appropriate location
2. Offer to begin execution with `@execute`
3. Or create worktree for parallel execution with `@create-shard`
```

**Step 4: Create artifacts directory structure**

Ensure directory exists: `artifacts/plans/`

Add `.gitkeep` file: `artifacts/plans/.gitkeep`

**Step 5: Add planning steering**

Create file: `.kiro/steering/planning.md`

```markdown
# Planning Standards

## When to Plan

Always create a plan before:
- Implementing new features
- Making architectural changes
- Refactoring existing code
- Any task estimated at >30 minutes

## Plan Quality Checklist

Good plans have:
- [ ] Clear success criteria (how do we know it's done?)
- [ ] Explicit scope boundaries (what's NOT included?)
- [ ] Task breakdown with estimates
- [ ] Testing strategy
- [ ] Risk consideration

## Plan Storage

- PRDs go in: `artifacts/plans/[feature-slug].md`
- Active task list goes in: `PLAN.md` (root)
- Progress tracking goes in: `PROGRESS.md` (root)

## Plan Versioning

When revising a plan:
1. Don't delete the original
2. Add revision notes at the top
3. Strike through changed items, add new ones below
```

### Acceptance Criteria
- [ ] `ralph-prd.md` prompt exists with interactive questions
- [ ] `create-plan.md` prompt exists for quick planning
- [ ] `plan-feature.md` routes between modes intelligently
- [ ] `artifacts/plans/` directory exists
- [ ] `planning.md` steering file exists
- [ ] Interactive mode asks questions one at a time
- [ ] Generated PRDs include all required sections
- [ ] Plans save to correct locations

---

## Feature 4: Code Review Swarm

### Problem
Single reviewer misses issues. Code-surgeon tries to check everything and gets overwhelmed or loses focus.

### Solution
Four specialized reviewer agents that run in parallel, each focused on one domain. Results merge into unified report.

### Implementation

**Step 1: Create the Logic Reviewer agent**

Create file: `.kiro/agents/logic-reviewer.json`

```json
{
  "name": "logic-reviewer",
  "description": "Reviews business logic for correctness, edge cases, and error handling",
  "model": "claude-sonnet-4",
  "prompt": "You are a code reviewer focused EXCLUSIVELY on business logic correctness.\n\nYou check for:\n- Edge cases not handled\n- Error conditions not caught\n- Race conditions in async code\n- Logic errors in conditionals\n- Missing input validation\n- Off-by-one errors\n- Null/undefined handling\n\nYou DO NOT comment on:\n- Code style or formatting (style-reviewer handles this)\n- Security issues (security-reviewer handles this)\n- Type coverage (type-reviewer handles this)\n\nOutput format: JSON array of issues\n{\n  \"reviewer\": \"logic-reviewer\",\n  \"issues\": [\n    {\n      \"severity\": \"critical|important|suggestion\",\n      \"file\": \"path/to/file\",\n      \"line\": 42,\n      \"title\": \"Brief title\",\n      \"description\": \"Detailed explanation\",\n      \"suggestion\": \"How to fix\"\n    }\n  ]\n}",
  "tools": ["read", "shell"],
  "allowedTools": ["read"],
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git diff", "git show", "grep", "find", "cat", "head", "tail"]
    }
  }
}
```

**Step 2: Create the Security Reviewer agent**

Create file: `.kiro/agents/security-reviewer.json`

```json
{
  "name": "security-reviewer",
  "description": "Reviews code for security vulnerabilities and OWASP compliance",
  "model": "claude-sonnet-4",
  "prompt": "You are a security-focused code reviewer.\n\nYou check for:\n- Injection vulnerabilities (SQL, XSS, command injection)\n- Authentication/authorization flaws\n- Sensitive data exposure\n- Insecure dependencies\n- Hardcoded secrets or credentials\n- CSRF vulnerabilities\n- Insecure direct object references\n- Security misconfiguration\n\nYou DO NOT comment on:\n- Business logic (logic-reviewer handles this)\n- Code style (style-reviewer handles this)\n- Type coverage (type-reviewer handles this)\n\nOutput format: JSON array of issues\n{\n  \"reviewer\": \"security-reviewer\",\n  \"issues\": [\n    {\n      \"severity\": \"critical|important|suggestion\",\n      \"file\": \"path/to/file\",\n      \"line\": 42,\n      \"title\": \"Brief title\",\n      \"description\": \"Detailed explanation with OWASP reference if applicable\",\n      \"suggestion\": \"How to fix\"\n    }\n  ]\n}",
  "tools": ["read", "shell"],
  "allowedTools": ["read"],
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git diff", "git show", "grep", "find", "cat"]
    }
  }
}
```

**Step 3: Create the Style Reviewer agent**

Create file: `.kiro/agents/style-reviewer.json`

```json
{
  "name": "style-reviewer",
  "description": "Reviews code style, naming conventions, and structural quality",
  "model": "claude-sonnet-4",
  "prompt": "You are a code quality reviewer focused on style and structure.\n\nYou check for:\n- Naming conventions (variables, functions, classes)\n- Code organization and structure\n- DRY violations (repeated code)\n- Function/method length (too long = split it)\n- Cyclomatic complexity\n- Comment quality and necessity\n- Consistent formatting\n- Import organization\n\nYou DO NOT comment on:\n- Business logic correctness (logic-reviewer handles this)\n- Security issues (security-reviewer handles this)\n- Type coverage (type-reviewer handles this)\n\nOutput format: JSON array of issues\n{\n  \"reviewer\": \"style-reviewer\",\n  \"issues\": [\n    {\n      \"severity\": \"critical|important|suggestion\",\n      \"file\": \"path/to/file\",\n      \"line\": 42,\n      \"title\": \"Brief title\",\n      \"description\": \"Detailed explanation\",\n      \"suggestion\": \"How to fix\"\n    }\n  ]\n}",
  "tools": ["read", "shell"],
  "allowedTools": ["read"],
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git diff", "git show", "grep", "find", "cat", "wc"]
    }
  }
}
```

**Step 4: Create the Type Reviewer agent**

Create file: `.kiro/agents/type-reviewer.json`

```json
{
  "name": "type-reviewer",
  "description": "Reviews type safety, type coverage, and type correctness",
  "model": "claude-sonnet-4",
  "prompt": "You are a type system reviewer.\n\nYou check for:\n- Missing type annotations\n- Overly broad types (any, unknown overuse)\n- Type assertion abuse (as Type)\n- Null/undefined safety\n- Generic type usage\n- Interface vs type consistency\n- Return type accuracy\n- Parameter type correctness\n\nYou DO NOT comment on:\n- Business logic (logic-reviewer handles this)\n- Security issues (security-reviewer handles this)\n- Code style (style-reviewer handles this)\n\nOutput format: JSON array of issues\n{\n  \"reviewer\": \"type-reviewer\",\n  \"issues\": [\n    {\n      \"severity\": \"critical|important|suggestion\",\n      \"file\": \"path/to/file\",\n      \"line\": 42,\n      \"title\": \"Brief title\",\n      \"description\": \"Detailed explanation\",\n      \"suggestion\": \"How to fix\"\n    }\n  ]\n}",
  "tools": ["read", "shell"],
  "allowedTools": ["read"],
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git diff", "git show", "grep", "find", "cat", "npx tsc"]
    }
  }
}
```

**Step 5: Create the Code Review Swarm orchestration prompt**

Create file: `.kiro/prompts/code-review-swarm.md`

```markdown
# Code Review Swarm

Orchestrate parallel code reviews from four specialized agents.

## Process

### Step 1: Get the Diff

Determine what to review:
- If PR number provided: `gh pr diff [number]`
- If branch provided: `git diff main...[branch]`
- If no input: `git diff HEAD~1`

Save diff content for distribution to reviewers.

### Step 2: Spawn Reviewers (Parallel)

Spawn four subagents simultaneously:

1. **logic-reviewer** — "Review this diff for logic issues: [diff]"
2. **security-reviewer** — "Review this diff for security issues: [diff]"
3. **style-reviewer** — "Review this diff for style issues: [diff]"
4. **type-reviewer** — "Review this diff for type issues: [diff]"

Each returns JSON with their findings.

### Step 3: Collect and Merge Results

Wait for all reviewers to complete. Merge their JSON outputs.

### Step 4: Synthesize Report

Create unified markdown report:

```markdown
# Code Review Report

**Reviewed:** [branch/PR]
**Date:** [timestamp]
**Reviewers:** logic, security, style, type

## Summary
- Critical Issues: [count]
- Important Issues: [count]
- Suggestions: [count]

## Critical Issues (Must Fix)

### [Issue Title]
**File:** `path/to/file` **Line:** 42
**Reviewer:** [which reviewer found this]

[Description]

**Suggestion:** [How to fix]

---

## Important Issues (Should Fix)

[Same format]

---

## Suggestions (Consider)

[Same format]

---

## Verdict

[ ] **BLOCKED** — Critical issues must be resolved
[ ] **APPROVED WITH CHANGES** — Important issues should be addressed
[ ] **APPROVED** — Only suggestions, good to merge
```

### Step 5: Post Results

If GitHub PR:
- Post report as PR comment via `gh pr comment [number] --body "[report]"`
- Add appropriate label: `needs-fixes` or `approved`

If local review:
- Save to `artifacts/reviews/[branch]-[date].md`
- Display summary in response

## Usage

```
@code-review-swarm PR 8
@code-review-swarm branch feature/new-thing
@code-review-swarm  # reviews last commit
```
```

**Step 6: Update the existing code-review prompt to use swarm**

Modify `.kiro/prompts/code-review.md`:

```markdown
# Code Review

Routes to appropriate review method based on scope.

## Routing

**Use Swarm Review (@code-review-swarm) when:**
- Reviewing a PR
- Reviewing a feature branch
- Changes span multiple files
- User requests "thorough" or "comprehensive" review

**Use Quick Review (inline) when:**
- Single file change
- User requests "quick" review
- Hotfix or small patch

## Quick Review Process

For small changes, review inline without spawning subagents:
1. Get the diff
2. Check for obvious issues across all categories
3. Provide brief feedback

## Default

Default to swarm review for anything more than 50 lines changed.
```

### Acceptance Criteria
- [ ] All four reviewer agents created (`logic-reviewer.json`, `security-reviewer.json`, `style-reviewer.json`, `type-reviewer.json`)
- [ ] `code-review-swarm.md` prompt exists
- [ ] `code-review.md` routes appropriately
- [ ] Reviewers output valid JSON format
- [ ] Swarm merges results into unified report
- [ ] Reports save to `artifacts/reviews/` for local reviews
- [ ] PR comments work via GitHub CLI

---

## Feature 5: GitHub PR Coordination

### Problem
Managing agent state manually is complex. Work completion is hard to track. Handoffs between agents are fragile.

### Solution
Use GitHub PRs as the coordination layer. Agents create PRs when done. Reviews happen via PR comments. Merge signals completion. Labels track state.

### Implementation

**Step 1: Create PR creation script**

Create file: `.kiro/scripts/create-pr.sh`

```bash
#!/bin/bash
# Create a PR from current branch
# Usage: create-pr.sh "PR Title" "PR Body"

TITLE="${1:-"Agent implementation"}"
BODY="${2:-"Automated PR created by orchestrator agent."}"
BRANCH=$(git branch --show-current)
BASE_BRANCH="${3:-main}"

# Check if we're on a feature branch
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "❌ Cannot create PR from main/master branch"
  echo "Create a feature branch first"
  exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  Uncommitted changes detected"
  echo "Committing all changes..."
  git add -A
  git commit -m "chore: auto-commit before PR creation"
fi

# Push branch
echo "Pushing branch to origin..."
git push -u origin "$BRANCH" 2>&1

# Create PR
echo "Creating PR..."
PR_URL=$(gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  --base "$BASE_BRANCH" \
  --label "agent-created,needs-review" \
  2>&1)

if [ $? -eq 0 ]; then
  echo "✅ PR created successfully"
  echo "URL: $PR_URL"
  
  # Extract PR number
  PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
  echo "PR Number: $PR_NUMBER"
else
  echo "❌ Failed to create PR"
  echo "$PR_URL"
  exit 1
fi
```

Make executable: `chmod +x .kiro/scripts/create-pr.sh`

**Step 2: Create PR status check script**

Create file: `.kiro/scripts/check-pr-status.sh`

```bash
#!/bin/bash
# Check status of a PR
# Usage: check-pr-status.sh [PR_NUMBER]

PR_NUMBER="${1}"

if [ -z "$PR_NUMBER" ]; then
  # Get PR for current branch
  PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null)
fi

if [ -z "$PR_NUMBER" ]; then
  echo "No PR found for current branch"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "PR #$PR_NUMBER Status"
echo "═══════════════════════════════════════════════════════════"

# Get PR details
gh pr view "$PR_NUMBER" --json title,state,labels,reviews,mergeable,statusCheckRollup \
  --template '
Title: {{.title}}
State: {{.state}}
Mergeable: {{.mergeable}}

Labels: {{range .labels}}{{.name}} {{end}}

Reviews:
{{range .reviews}}  - {{.author.login}}: {{.state}}
{{end}}

Status Checks:
{{range .statusCheckRollup}}  - {{.name}}: {{.status}} ({{.conclusion}})
{{end}}
'

echo "═══════════════════════════════════════════════════════════"
```

Make executable: `chmod +x .kiro/scripts/check-pr-status.sh`

**Step 3: Create PR merge script**

Create file: `.kiro/scripts/merge-pr.sh`

```bash
#!/bin/bash
# Merge a PR after validation
# Usage: merge-pr.sh [PR_NUMBER] [--squash|--rebase|--merge]

PR_NUMBER="${1}"
MERGE_METHOD="${2:---squash}"

if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null)
fi

if [ -z "$PR_NUMBER" ]; then
  echo "❌ No PR number provided and no PR found for current branch"
  exit 1
fi

# Check PR status
echo "Checking PR #$PR_NUMBER status..."
PR_STATE=$(gh pr view "$PR_NUMBER" --json state -q '.state')
MERGEABLE=$(gh pr view "$PR_NUMBER" --json mergeable -q '.mergeable')

if [ "$PR_STATE" != "OPEN" ]; then
  echo "❌ PR is not open (state: $PR_STATE)"
  exit 1
fi

if [ "$MERGEABLE" != "MERGEABLE" ]; then
  echo "❌ PR is not mergeable (status: $MERGEABLE)"
  echo "Check for conflicts or failing checks"
  exit 1
fi

# Merge
echo "Merging PR #$PR_NUMBER with $MERGE_METHOD..."
gh pr merge "$PR_NUMBER" "$MERGE_METHOD" --delete-branch

if [ $? -eq 0 ]; then
  echo "✅ PR #$PR_NUMBER merged successfully"
  echo "Branch deleted"
else
  echo "❌ Merge failed"
  exit 1
fi
```

Make executable: `chmod +x .kiro/scripts/merge-pr.sh`

**Step 4: Create GitHub workflow prompt**

Create file: `.kiro/prompts/github-workflow.md`

```markdown
# GitHub PR Workflow

Manage the full PR lifecycle: create, review, merge.

## Creating a PR

After implementation is complete and validation passes:

1. Ensure all changes are committed
2. Run: `bash .kiro/scripts/create-pr.sh "feat: [description]" "[detailed body]"`
3. Note the PR number for tracking

PR body should include:
- What was implemented
- How it was tested
- Any known limitations
- Related issues (closes #X)

## Reviewing a PR

When a PR needs review:

1. Check current PRs: `gh pr list --label needs-review`
2. Trigger swarm review: `@code-review-swarm PR [number]`
3. Review results are posted as PR comment
4. Labels updated based on findings

## Handling Review Feedback

When review finds issues:

1. Read the review comment
2. Address each issue by category:
   - **Critical** — Must fix before merge
   - **Important** — Should fix, explain if skipping
   - **Suggestion** — Consider, document decision
3. Push fixes to the same branch
4. Request re-review if needed: `gh pr ready [number]`

## Merging

When PR is approved:

1. Check status: `bash .kiro/scripts/check-pr-status.sh [number]`
2. Verify all checks pass
3. Merge: `bash .kiro/scripts/merge-pr.sh [number] --squash`

## Labels

Standard labels used:
- `agent-created` — PR was created by an agent
- `needs-review` — Awaiting code review
- `needs-fixes` — Review found issues to address
- `approved` — Review passed, ready to merge
- `blocked` — Cannot proceed (conflicts, dependencies)

## After Merge

1. Clean up worktree if applicable
2. Update PROGRESS.md
3. Close related issues
4. Update devlog with completion
```

**Step 5: Create PR watcher prompt**

Create file: `.kiro/prompts/github-pr-watch.md`

```markdown
# GitHub PR Watcher

Monitor PRs and trigger appropriate actions.

## Check for PRs Needing Action

Run this periodically or on-demand to process pending PRs.

### Step 1: List PRs by State

```bash
# PRs needing review
gh pr list --label needs-review --json number,title,createdAt

# PRs with requested changes
gh pr list --label needs-fixes --json number,title

# PRs ready to merge
gh pr list --label approved --json number,title
```

### Step 2: Process Each Category

**For needs-review PRs:**
1. Trigger code review swarm
2. Post review results
3. Update label based on findings

**For approved PRs:**
1. Verify all checks pass
2. Merge if ready
3. Clean up worktree

**For needs-fixes PRs:**
1. Report status to user
2. Wait for human intervention or explicit fix request

### Step 3: Report Summary

Output a summary of PR states:
- X PRs awaiting review
- X PRs approved and merged
- X PRs needing fixes
- X PRs blocked

## Automation

This can be run:
- Manually: `@github-pr-watch`
- On schedule via cron flow
- As part of daily standup
```

**Step 6: Create GitHub steering file**

Create file: `.kiro/steering/github-workflow.md`

```markdown
# GitHub Workflow Standards

## Branch Naming

Format: `[type]/[short-description]`

Types:
- `feat/` — New feature
- `fix/` — Bug fix
- `refactor/` — Code refactoring
- `docs/` — Documentation
- `test/` — Test additions
- `chore/` — Maintenance

Examples:
- `feat/user-authentication`
- `fix/login-redirect-bug`
- `refactor/database-queries`

## Commit Messages

Format: `[type]: [description]`

Keep under 72 characters. Use imperative mood.

Examples:
- `feat: add user login endpoint`
- `fix: resolve null pointer in auth flow`
- `docs: update API documentation`

## PR Standards

Every PR must have:
- Descriptive title following commit format
- Body explaining what and why
- Labels for tracking
- Linked issues if applicable

## Review Process

1. All PRs get automated swarm review
2. Critical issues block merge
3. Important issues should be addressed
4. Suggestions are optional but encouraged

## Merge Strategy

Default: Squash merge
- Keeps main branch history clean
- Combines feature commits into one
- Preserves PR reference in commit
```

**Step 7: Ensure GitHub CLI labels exist**

Create file: `.kiro/scripts/setup-github-labels.sh`

```bash
#!/bin/bash
# Create standard labels for PR workflow
# Run once per repository

LABELS=(
  "agent-created:0366d6:Created by an AI agent"
  "needs-review:fbca04:Awaiting code review"
  "needs-fixes:d93f0b:Review found issues to address"
  "approved:0e8a16:Review passed, ready to merge"
  "blocked:b60205:Cannot proceed due to blocker"
)

echo "Setting up GitHub labels..."

for label_def in "${LABELS[@]}"; do
  IFS=':' read -r name color description <<< "$label_def"
  
  # Check if label exists
  if gh label list | grep -q "^$name"; then
    echo "Label '$name' already exists"
  else
    gh label create "$name" --color "$color" --description "$description"
    echo "Created label '$name'"
  fi
done

echo "✅ Labels setup complete"
```

Make executable: `chmod +x .kiro/scripts/setup-github-labels.sh`

### Acceptance Criteria
- [ ] `create-pr.sh` exists and is executable
- [ ] `check-pr-status.sh` exists and is executable
- [ ] `merge-pr.sh` exists and is executable
- [ ] `setup-github-labels.sh` exists and is executable
- [ ] `github-workflow.md` prompt exists
- [ ] `github-pr-watch.md` prompt exists
- [ ] `github-workflow.md` steering file exists
- [ ] PRs can be created from feature branches
- [ ] Reviews post as PR comments
- [ ] Labels update automatically
- [ ] Merge cleans up branches

---

## Verification Checklist

After implementing all features, verify:

### Feature 1: Context Injection
- [ ] Start orchestrator agent and see context output
- [ ] Start any specialist agent and see context output
- [ ] Context shows correct branch and working directory

### Feature 2: Self-Validation
- [ ] Make a code change and see validation run after response
- [ ] Introduce a deliberate error and see it caught
- [ ] Agent acknowledges validation failure

### Feature 3: Interactive Planning
- [ ] Run `@ralph-prd` and receive questions one at a time
- [ ] Complete the process and get a full PRD
- [ ] PRD saves to `artifacts/plans/`

### Feature 4: Code Review Swarm
- [ ] Run `@code-review-swarm` on a branch
- [ ] See results from all four reviewers
- [ ] Unified report generates correctly

### Feature 5: GitHub Coordination
- [ ] Create a PR using the script
- [ ] PR gets correct labels
- [ ] Review posts as PR comment
- [ ] Merge works and cleans up branch

---

## Files Created/Modified Summary

### New Files
```
.kiro/scripts/
├── inject-context.sh
├── inject-worktree-context.sh
├── validate-changes.sh
├── quick-validate.sh
├── create-pr.sh
├── check-pr-status.sh
├── merge-pr.sh
└── setup-github-labels.sh

.kiro/agents/
├── logic-reviewer.json
├── security-reviewer.json
├── style-reviewer.json
└── type-reviewer.json

.kiro/prompts/
├── ralph-prd.md
├── create-plan.md
├── code-review-swarm.md
├── github-workflow.md
└── github-pr-watch.md

.kiro/steering/
├── validation.md
├── planning.md
└── github-workflow.md

artifacts/
└── plans/.gitkeep
```

### Modified Files
```
.kiro/agents/orchestrator.json         (add hooks)
.kiro/agents/ralph-master.json         (add hooks)
.kiro/agents/code-surgeon.json         (add hooks)
.kiro/agents/test-architect.json       (add hooks)
.kiro/agents/frontend-designer.json    (add hooks)
.kiro/agents/db-wizard.json            (add hooks)
.kiro/agents/devops-automator.json     (add hooks)
.kiro/agents/doc-smith.json            (add hooks)
.kiro/agents/security-specialist.json  (add hooks)

.kiro/prompts/plan-feature.md          (add routing)
.kiro/prompts/code-review.md           (add routing to swarm)
```

---

## Execution Order

1. **Create directories and scripts first** — These have no dependencies
2. **Add hooks to agent configs** — Enables context injection and validation
3. **Create new agents** — Reviewer agents for swarm
4. **Create prompts** — Planning and workflow prompts
5. **Create steering files** — Standards documentation
6. **Test each feature** — Verify before moving to next
7. **Run full integration test** — End-to-end workflow

---

## Success Metrics

After full implementation:

1. **Context Clarity** — Agents never ask "what branch am I on?" or get confused about their environment
2. **Self-Correction** — Agents fix their own failing tests without being told
3. **Plan Quality** — PRDs include all sections with no "TBD" items after interactive mode
4. **Review Coverage** — Code reviews catch issues across all four domains
5. **PR Velocity** — PRs flow from creation to merge with minimal manual intervention
