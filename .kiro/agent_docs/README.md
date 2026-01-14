# Agent Documentation (Progressive Disclosure)

These docs are loaded on-demand by agents when needed. Don't load all at once.

## Available Docs

| File | When to Read |
|------|--------------|
| `architecture.md` | System design decisions |
| `testing.md` | Writing and running tests |
| `deployment.md` | CI/CD and deployment |
| `database.md` | Schema design and migrations |
| `security.md` | Security requirements |
| `accessibility.md` | A11y compliance |

## Usage

Agents should read these files only when working on related tasks:
- Working on tests? Read `testing.md`
- Deploying? Read `deployment.md`
- Schema changes? Read `database.md`

This keeps context focused and improves instruction-following.
