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
