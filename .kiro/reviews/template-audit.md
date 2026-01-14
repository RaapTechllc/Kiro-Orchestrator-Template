# Orchestrator Template Audit Report

**Date**: 2026-01-14
**Auditor**: Kiro CLI
**Status**: Complete

---

## Executive Summary

1. **Agent Redundancy**: `doc-smith` and `doc-smith-ralph` are duplicates; `ralph-master` overlaps significantly with `orchestrator`
2. **Inconsistent Completion Signals**: `ralph-master` uses `<promise>COMPLETE</promise>` while all others use `<promise>DONE</promise>`
3. **Out-of-Scope Content**: `.kiro/persuasion/` folder (37KB+ of copywriting content) doesn't belong in an orchestration template
4. **Project-Specific Agents**: `demo-specialist`, `monitoring-specialist`, `performance-engineer` contain hardcoded task IDs (4.1, 4.2, 3.2, etc.) from a specific project
5. **Prompt/Command Duplication**: `code-review`, `security-audit`, `test-coverage` exist in BOTH `.kiro/prompts/` AND `.kiro/commands/`

---

## 1. Agent Roster Review

### Agents Found (14 total)

| Agent | Purpose | Issues |
|-------|---------|--------|
| `orchestrator` | Workflow coordinator, SPEC pattern | ✅ Well-designed |
| `ralph-master` | B-Thread meta-orchestrator | ⚠️ Overlaps with orchestrator; uses different completion signal |
| `code-surgeon` | Code review, security, refactoring | ✅ Good |
| `test-architect` | Testing, coverage | ✅ Good |
| `security-specialist` | OWASP audits | ✅ Good |
| `frontend-designer` | UI/UX, accessibility | ✅ Good |
| `db-wizard` | Database, Prisma | ✅ Good |
| `devops-automator` | CI/CD, deployment | ✅ Good |
| `doc-smith` | Documentation | ⚠️ Duplicate exists |
| `doc-smith-ralph` | Documentation (Ralph mode) | ❌ Redundant - same as doc-smith with hardcoded tasks |
| `demo-specialist` | Demo testing | ❌ Project-specific (hardcoded task IDs 4.1, 4.2, 4.4, 4.5, 4.7) |
| `monitoring-specialist` | Infrastructure monitoring | ❌ Project-specific (hardcoded task IDs 3.2, 3.7, 3.8) |
| `performance-engineer` | Performance testing | ❌ Project-specific (hardcoded task IDs 4.6, 4.8) |
| `agent-creator` | Creates custom agents | ✅ Useful meta-agent |

### Redundancies Identified

1. **doc-smith vs doc-smith-ralph**: Same agent, one has Ralph Loop protocol baked in with hardcoded task "4.10"
2. **ralph-master vs orchestrator**: Both coordinate workflows; unclear when to use which

### Missing Capabilities

- **API specialist**: No agent focused on REST/GraphQL API design
- **Migration specialist**: No agent for data/schema migrations specifically
- **Refactoring specialist**: code-surgeon does reviews but no dedicated refactoring agent

---

## 2. Workflow Scripts Review

### Scripts Found (8 total)

| Script | Purpose | Thread Type |
|--------|---------|-------------|
| `ralph-kiro.sh` | Parallel agent spawner | P-Thread |
| `chain-workflow.sh` | Sequential phases with checkpoints | C-Thread |
| `fusion.sh` | Multiple agents, fuse results | F-Thread |
| `b-thread-orchestrator.sh` | Meta-orchestration | B-Thread |
| `l-thread-runner.sh` | Long-running autonomous | L-Thread |
| `worktree-manager.sh` | Git worktree isolation | Utility |
| `metrics-tracker.sh` | Performance tracking | Utility |
| `dashboard.sh` | Real-time monitoring | Utility |
| `self-improve.sh` | Learning capture | Utility |

### Issues

1. **Simulated execution**: All workflow scripts contain `# REPLACE WITH ACTUAL KIRO-CLI` comments with simulated `sleep` commands instead of real execution
2. **No Base Thread script**: Documentation mentions 6 thread types but Base Thread has no dedicated script

---

## 3. Steering Files Review

### Files Found

| File | Purpose | Status |
|------|---------|--------|
| `product.md` | Product overview template | ✅ Good template |
| `tech.md` | Tech stack template | ✅ Good template |
| `structure.md` | Project structure template | ✅ Good template |
| `ralph-loop.md` | Ralph Loop methodology | ✅ Comprehensive |
| `agent-evolution.md` | Self-improvement protocol | ✅ Comprehensive |
| `kiro-cli-reference.md` | CLI reference guide | ⚠️ 13KB - very long for steering |

### Issues

1. **kiro-cli-reference.md** (13KB): Too long for a steering file; should be in `docs/` for on-demand loading
2. **Redundancy**: `agent-evolution.md` duplicates content from `LEARNINGS.md` explanation in CLAUDE.md

---

## 4. Prompts & Commands Review

### Prompts (16 files)

| Prompt | Purpose | Issue |
|--------|---------|-------|
| `plan-feature.md` | Start SPEC workflow | ✅ Good |
| `execute.md` | Execute tasks | ✅ Good |
| `next-task.md` | Continue workflow | ✅ Good |
| `code-review.md` | Review code | ❌ Duplicate in commands/ |
| `security-audit.md` | Security scan | ❌ Duplicate in commands/ |
| `test-coverage.md` | Coverage analysis | ❌ Duplicate in commands/ |
| `reflect.md` | Session learnings | ⚠️ Similar to self-reflect.md |
| `self-reflect.md` | RBT analysis | ⚠️ Similar to reflect.md |
| `rca.md` | Root cause analysis | ✅ Good, uses "When invoked, ask:" |
| `quickstart.md` | Project bootstrap | ✅ Good |
| `prime.md` | Load context | ✅ Good |
| `deploy-checklist.md` | Pre-deploy checks | ✅ Good |
| `a11y-audit.md` | Accessibility audit | ✅ Good |
| `workflow-status.md` | Check spec status | ✅ Good |

### Commands (4 files)

All 4 commands duplicate prompts:
- `code-review.md` - duplicates prompt
- `security-audit.md` - duplicates prompt  
- `spec-workflow.md` - similar to plan-feature prompt
- `test-coverage.md` - duplicates prompt

### "When invoked, ask:" Pattern Compliance

✅ Compliant: `rca.md`, `code-review.md` (command), `security-audit.md` (command), `test-coverage.md` (command), `spec-workflow.md`
❌ Non-compliant: Most prompts assume context is provided

---

## 5. Hooks Review

### Hooks Found (5 files)

| Hook | Trigger | Action |
|------|---------|--------|
| `completion-validation.kiro.hook` | agentComplete | sendMessage reminder |
| `progress-update.kiro.hook` | fileSave (src/**) | sendMessage reminder |
| `quality-gate.kiro.hook` | agentComplete | runCommand (lint/typecheck) |
| `session-reflect.kiro.hook` | onAgentMessage (DONE pattern) | sendMessage reminder |
| `frontend-dev-agent.kiro.hook` | fileEdited (*.tsx) | askAgent for review |

### Issues

1. **Hook schema inconsistency**: `session-reflect.kiro.hook` uses `event.type` and `event.pattern` while others use `trigger.type`
2. **Duplicate triggers**: Both `completion-validation` and `quality-gate` trigger on `agentComplete`

---

## 6. Self-Improvement System Review

### Components

- `LEARNINGS.md` - ✅ Good structure with types (Correction, Preference, Pattern, Anti-pattern)
- `self-improve.sh` - ✅ Functional CLI for adding learnings
- `reflect.md` prompt - ✅ Good process
- `session-reflect.kiro.hook` - ✅ Auto-triggers on completion

### Issues

1. **LEARNINGS.md has only 2 entries**: Template should ship empty or with example entries clearly marked
2. **No automated promotion**: No mechanism to auto-promote high-frequency learnings to CLAUDE.md

---

## 7. Documentation Review

### README Files

| File | Lines | Status |
|------|-------|--------|
| Root `README.md` | 100+ | ✅ Good quick start |
| `.kiro/README.md` | 115 | ✅ Good overview |
| `.kiro/agents/README.md` | 213 | ✅ Comprehensive |
| `.kiro/prompts/README.md` | 28 | ✅ Good index |
| `.kiro/agent_docs/README.md` | 18 | ✅ Good progressive disclosure |
| `.kiro/specs/README.md` | 28 | ✅ Good |

### Missing Documentation

- No CONTRIBUTING.md for template contributions
- No CHANGELOG.md for template versions

---

## 8. Integration & Consistency

### Completion Signal Inconsistency

| Agent/File | Signal Used |
|------------|-------------|
| Most agents | `<promise>DONE</promise>` |
| `ralph-master` | `<promise>COMPLETE</promise>` ❌ |
| C-Thread checkpoints | `<promise>CHECKPOINT</promise>` ✅ (intentionally different) |

### Out-of-Scope Content

**`.kiro/persuasion/` folder** (17 files, 150KB+):
- Copywriting masterclass content
- Tone recipes, workbooks
- Completely unrelated to orchestration template
- References paths like `file:///e:/antigravity/persuasion/` (hardcoded local paths)

---

## Recommendations Table

| Item | Type | Priority | Suggested Action |
|------|------|----------|------------------|
| Remove `.kiro/persuasion/` folder | Redundancy | **High** | Delete entire folder - not related to orchestration |
| Remove project-specific agents | Redundancy | **High** | Delete `demo-specialist`, `monitoring-specialist`, `performance-engineer`, `doc-smith-ralph` |
| Fix `ralph-master` completion signal | Improvement | **High** | Change `<promise>COMPLETE</promise>` to `<promise>DONE</promise>` |
| Remove duplicate commands | Redundancy | **Medium** | Delete `.kiro/commands/code-review.md`, `security-audit.md`, `test-coverage.md` (keep prompts) |
| Merge `reflect.md` and `self-reflect.md` | Redundancy | **Medium** | Consolidate into single prompt |
| Move `kiro-cli-reference.md` to docs | Improvement | **Medium** | Move from steering/ to docs/ |
| Fix hook schema inconsistency | Improvement | **Medium** | Standardize `session-reflect.kiro.hook` to use `trigger` not `event` |
| Add real kiro-cli execution | Gap | **Medium** | Replace simulated `sleep` in workflow scripts with actual CLI calls |
| Clear LEARNINGS.md | Improvement | **Low** | Remove project-specific entries, add example format comments |
| Add API specialist agent | Gap | **Low** | Create agent for REST/GraphQL design |
| Add CONTRIBUTING.md | Gap | **Low** | Document how to contribute to template |

---

## Questions for Human Review

1. **Should `ralph-master` be removed entirely?** It overlaps heavily with `orchestrator` - clarify distinct use cases or consolidate.

2. **What is the persuasion folder?** It appears to be from a different project (`antigravity`). Confirm deletion.

3. **Are the project-specific agents intentional examples?** The hardcoded task IDs (4.1, 4.2, etc.) suggest they were created for a specific project, not as reusable templates.

4. **Commands vs Prompts distinction**: What's the intended difference? Currently they duplicate each other.

5. **Hook trigger schema**: Which is correct - `trigger.type` or `event.type`? Need to standardize.

---

*Report generated by Kiro CLI audit on 2026-01-14*


---

## Prioritized Action Plan

### Phase 1: Critical Cleanup (Do First)

**1.1 Remove persuasion folder**
```bash
rm -rf .kiro/persuasion/
```
- 17 files, 150KB+ of unrelated copywriting content
- Contains hardcoded paths to `e:/antigravity/`

**1.2 Remove project-specific agents**
```bash
rm .kiro/agents/demo-specialist.json
rm .kiro/agents/monitoring-specialist.json
rm .kiro/agents/performance-engineer.json
rm .kiro/agents/doc-smith-ralph.json
```
- These contain hardcoded task IDs (3.2, 3.7, 4.1, 4.2, etc.)
- Keep generic `doc-smith.json`

**1.3 Fix ralph-master completion signal**
- File: `.kiro/agents/ralph-master.json` line 4
- Change: `<promise>COMPLETE</promise>` → `<promise>DONE</promise>`

---

### Phase 2: Reduce Redundancy (Do Second)

**2.1 Remove duplicate commands**
```bash
rm .kiro/commands/code-review.md
rm .kiro/commands/security-audit.md
rm .kiro/commands/test-coverage.md
```
- Keep `spec-workflow.md` (unique)
- Prompts versions are sufficient

**2.2 Consolidate reflect prompts**
- Merge `.kiro/prompts/reflect.md` and `self-reflect.md` into single `reflect.md`
- Current overlap: both do session analysis with slightly different frameworks

**2.3 Move kiro-cli-reference.md**
```bash
mv .kiro/steering/kiro-cli-reference.md .kiro/docs/
```
- 13KB is too large for always-loaded steering
- Better as on-demand documentation

---

### Phase 3: Fix Inconsistencies (Do Third)

**3.1 Fix hook schema**
- File: `.kiro/hooks/session-reflect.kiro.hook`
- Change `event` to `trigger` to match other hooks:
```json
{
  "trigger": {
    "type": "onAgentMessage",
    "pattern": "<promise>DONE</promise>|task complete|finished|all done"
  }
}
```

**3.2 Clear LEARNINGS.md**
- Remove the 2 project-specific entries
- Keep structure with example format in comments

**3.3 Update agents README**
- File: `.kiro/agents/README.md`
- Remove references to deleted agents
- Update agent count and table

---

### Phase 4: Enhancements (Optional)

**4.1 Add "When invoked, ask:" to prompts**
Prompts needing update:
- `plan-feature.md` - ask for feature name
- `code-review.md` - ask for scope
- `test-coverage.md` - ask for target

**4.2 Replace simulated execution in workflows**
Files with `# REPLACE WITH ACTUAL KIRO-CLI`:
- `ralph-kiro.sh` (line ~240)
- `fusion.sh` (line ~180)
- `chain-workflow.sh` (line ~340)
- `l-thread-runner.sh` (line ~350)

**4.3 Add missing docs**
```bash
touch CONTRIBUTING.md
touch CHANGELOG.md
```

---

## Estimated Effort

| Phase | Time | Risk |
|-------|------|------|
| Phase 1 | 5 min | Low (deletions) |
| Phase 2 | 15 min | Low (consolidation) |
| Phase 3 | 10 min | Medium (schema changes) |
| Phase 4 | 30 min | Low (enhancements) |

**Total: ~1 hour for full cleanup**

---

## Files to Delete (Summary)

```
.kiro/persuasion/                    # 17 files - entire folder
.kiro/agents/demo-specialist.json
.kiro/agents/monitoring-specialist.json
.kiro/agents/performance-engineer.json
.kiro/agents/doc-smith-ralph.json
.kiro/commands/code-review.md
.kiro/commands/security-audit.md
.kiro/commands/test-coverage.md
.kiro/prompts/self-reflect.md        # after merging into reflect.md
```

## Files to Modify (Summary)

```
.kiro/agents/ralph-master.json       # completion signal
.kiro/hooks/session-reflect.kiro.hook # schema fix
.kiro/prompts/reflect.md             # merge self-reflect content
.kiro/agents/README.md               # update agent list
.kiro/steering/ → .kiro/docs/        # move kiro-cli-reference.md
LEARNINGS.md                         # clear project entries
```
