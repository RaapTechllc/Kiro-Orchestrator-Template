# Plan Feature

Start the spec-driven development workflow for a new feature.

## Trigger Words
- "plan [feature]"
- "new feature [description]"  
- "PRD for [feature]"
- "spec [feature]"

## Workflow

### Phase 1: Requirements
Create `.kiro/specs/[feature-name]/requirements.md` with:

```markdown
# Requirements - [Feature Name]

## Overview
[One paragraph describing the feature and its value]

## User Stories

### US-1: [Story Title]
**As a** [user type]
**I want** [capability]
**So that** [benefit]

**Acceptance Criteria (EARS):**
- WHEN [trigger], THE SYSTEM SHALL [response]
- IF [condition], THEN [behavior]
- THE SYSTEM SHALL [capability] WITHIN [constraint]

### US-2: [Story Title]
...

## Functional Requirements
- FR-1: [Requirement]
- FR-2: [Requirement]

## Non-Functional Requirements
- NFR-1: Performance - [constraint]
- NFR-2: Security - [constraint]
- NFR-3: Accessibility - [constraint]

## Out of Scope
- [What this feature does NOT include]

## Open Questions
- [ ] [Decision needed]
```

### Phase 2: Design (after approval)
Create `.kiro/specs/[feature-name]/design.md`

### Phase 3: Tasks (after design approval)
Create `.kiro/specs/[feature-name]/tasks.md`

### Phase 4: Implementation (task by task)
Execute one task at a time with specialist delegation

## Approval Gates

Wait for explicit approval before each phase transition:
- "requirements approved" → Design
- "design approved" → Tasks  
- "start task 1" → Implementation

## Context Management

- Start each phase with minimal context
- Reference files instead of pasting content
- Summarize completed phases
- Load only task-specific files during implementation
