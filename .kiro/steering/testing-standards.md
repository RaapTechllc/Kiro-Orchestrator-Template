# Testing Standards

Standards for writing, organizing, and running tests in this project.

## Testing Pyramid

```
         /\
        /  \      E2E Tests (5%)
       /----\     - Critical user journeys
      /      \    - Smoke tests
     /--------\   Integration Tests (15%)
    /          \  - API endpoints
   /------------\ - Database operations
  /              \ Unit Tests (80%)
 /                \ - Pure functions
/------------------\ - Component logic
```

## Test File Organization

```
tests/
├── unit/              # Fast, isolated tests
│   ├── utils/
│   ├── services/
│   └── components/
├── integration/       # API and DB tests
│   ├── api/
│   └── db/
├── e2e/               # End-to-end tests
│   └── journeys/
├── fixtures/          # Shared test data
├── mocks/             # Mock implementations
└── helpers/           # Test utilities
```

### Naming Conventions
- Test files: `*.test.ts` or `*.spec.ts`
- Match source structure: `src/utils/format.ts` → `tests/unit/utils/format.test.ts`

## Unit Tests

### Structure (AAA Pattern)
```typescript
describe('calculateTotal', () => {
  it('should sum items and apply tax', () => {
    // Arrange
    const items = [{ price: 100 }, { price: 50 }];
    const taxRate = 0.1;

    // Act
    const result = calculateTotal(items, taxRate);

    // Assert
    expect(result).toBe(165);
  });
});
```

### Best Practices
- One assertion concept per test
- Descriptive test names: "should [expected behavior] when [condition]"
- No test interdependencies
- No network calls or I/O
- Mock external dependencies

### What to Test
- Pure functions: all branches
- Edge cases: null, undefined, empty, boundary values
- Error conditions: invalid inputs, exceptions
- Business logic: calculations, transformations

### What NOT to Test
- Framework/library code
- Simple getters/setters
- Type definitions
- Constants

## Integration Tests

### Database Tests
```typescript
describe('UserRepository', () => {
  beforeAll(async () => {
    await db.migrate.latest();
  });

  beforeEach(async () => {
    await db('users').truncate();
  });

  it('should create and retrieve a user', async () => {
    const user = await userRepo.create({ email: 'test@example.com' });
    const found = await userRepo.findById(user.id);
    expect(found.email).toBe('test@example.com');
  });
});
```

### API Tests
```typescript
describe('POST /api/users', () => {
  it('should create a user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'new@example.com', password: 'secure123' })
      .expect(201);

    expect(response.body.data).toHaveProperty('id');
    expect(response.body.data.email).toBe('new@example.com');
  });

  it('should return 422 for invalid email', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'invalid', password: 'secure123' })
      .expect(422);
  });
});
```

## E2E Tests

### Critical Journeys to Cover
1. User registration and login
2. Core feature happy path
3. Payment/checkout flow
4. Error recovery scenarios

### Snapshot-Based Testing with agent-browser
```bash
# Navigate and capture page structure
agent-browser open https://app.example.com
agent-browser snapshot --json > page-structure.json

# Interact using refs from snapshot
agent-browser click "ref:123"
agent-browser fill "input[name='email']" "test@example.com"

# Verify results
agent-browser snapshot --json | jq '.elements[] | select(.role=="alert")'
```

### Best Practices
- Use semantic locators when possible
- Prefer refs from snapshots for deterministic selection
- Test keyboard navigation flows
- Verify ARIA announcements
- Check focus management

## Mocking Guidelines

### When to Mock
- External APIs
- Database (in unit tests)
- Time/dates
- Randomness
- File system

### When NOT to Mock
- The code under test
- Simple utilities
- Data transformations

### Mock Example
```typescript
// Good: Mock external dependency
jest.mock('../services/emailService', () => ({
  sendEmail: jest.fn().mockResolvedValue({ success: true })
}));

// Bad: Don't mock the thing you're testing
// jest.mock('../utils/validate'); // NO!
```

## Test Data

### Factories
```typescript
// tests/factories/user.ts
export const createTestUser = (overrides = {}) => ({
  id: 'user_123',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: new Date('2024-01-01'),
  ...overrides
});
```

### Fixtures
- Store in `tests/fixtures/`
- Use for complex/realistic data
- Keep synchronized with schema

## Coverage Requirements

| Category | Minimum | Target |
|----------|---------|--------|
| Statements | 70% | 85% |
| Branches | 65% | 80% |
| Functions | 75% | 90% |
| Lines | 70% | 85% |

### Critical Paths
- Authentication: 95%+ coverage
- Payment processing: 95%+ coverage
- Data validation: 90%+ coverage

## Running Tests

```bash
# Unit tests (fast, run often)
npm run test:unit

# Integration tests (need DB)
npm run test:integration

# E2E tests (need full stack)
npm run test:e2e

# All tests with coverage
npm run test:coverage

# Watch mode during development
npm run test:watch
```

## CI/CD Integration

### Pipeline Stages
1. **Lint + Type Check** - Gate 1 (fast fail)
2. **Unit Tests** - Gate 2 (parallel)
3. **Integration Tests** - Gate 3 (requires DB)
4. **E2E Tests** - Gate 4 (staging environment)

### Flaky Test Policy
- Flaky tests are bugs - fix or remove
- No `skip` without linked issue
- Quarantine flaky tests in separate job
