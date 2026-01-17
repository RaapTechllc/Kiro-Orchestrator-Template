# Orchestrator Template - Product Overview

## Product Purpose
A drop-in multi-agent orchestration framework that transforms any project into a structured, AI-assisted development environment. Solves the problem of managing complex AI-assisted workflows by providing validation gates, parallel execution, and self-improvement systems.

## Target Users
- **Primary**: Senior engineers using AI coding assistants who want structured workflows
- **Secondary**: Teams adopting AI-first development practices
- **Tertiary**: Solo developers managing complex features with AI assistance

## Key Features
- **Spec-Driven Development**: PRD → Plan → Implement workflow with approval gates
- **Validation Enforcement**: Stop hooks prevent false completion claims
- **Parallel Execution**: Git worktrees isolate agents working simultaneously
- **Self-Improvement**: LEARNINGS.md + `@self-reflect` for continuous improvement
- **Specialist Delegation**: Domain-expert agents (security, testing, DB, etc.)

## Business Objectives
- Reduce AI-generated code quality issues through validation gates
- Enable parallel AI development without merge conflicts
- Capture and compound learnings across sessions

## User Journey
1. **Onboarding**: Copy `.kiro/` folder into project, run `kiro-cli --agent orchestrator`
2. **Core Action**: `@plan-feature "description"` to start structured development
3. **Progress**: Follow approval gates, delegate to specialists, validate and merge

## Success Criteria
- Agent work passes validation on first completion attempt
- Parallel agents merge without manual conflict resolution
- LEARNINGS.md captures actionable improvements
- Feature delivery follows spec phases without skipping
