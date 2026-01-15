# Architecture Guidelines

## Design Principles
1. Separation of concerns - UI, business logic, data layers distinct
2. Single responsibility - Each module does one thing well
3. Dependency injection - Loose coupling between components
4. Fail fast - Validate early, error clearly

## Component Structure
```
src/
├── app/           # Routes and pages
├── components/    # Reusable UI components
│   ├── ui/       # Base components (buttons, inputs)
│   └── features/ # Feature-specific components
├── lib/          # Utilities and helpers
├── hooks/        # Custom React hooks
├── types/        # TypeScript definitions
└── services/     # API and external service calls
```

## Data Flow
1. User action triggers event
2. Event handler calls service/action
3. Service updates state/database
4. UI re-renders with new state

## API Design
- RESTful endpoints for CRUD
- Server Actions for mutations
- Consistent error response format
- Input validation on all endpoints
