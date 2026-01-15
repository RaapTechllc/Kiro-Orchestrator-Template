# Specs Directory

Feature specifications created through the spec-driven workflow.

## Structure
```
specs/
└── [feature-name]/
    ├── requirements.md  # User stories, acceptance criteria
    ├── design.md        # Architecture, data models
    └── tasks.md         # Implementation breakdown
```

## Creating Specs

Use `@plan-feature` prompt:
```
@plan-feature User authentication
```

This guides you through:
1. Requirements → wait for approval
2. Design → wait for approval  
3. Tasks → wait for approval
4. Implementation → one task at a time

## Spec Lifecycle

Each phase requires explicit approval before proceeding.
