# Testing Guidelines

## Test Types

### Unit Tests
- Test individual functions in isolation
- Mock external dependencies
- Fast execution (< 1s per test)
- Location: `tests/unit/` or `*.test.ts`

### Integration Tests
- Test API endpoints end-to-end
- Use test database
- Location: `tests/integration/`

### E2E Tests
- Test critical user journeys
- Run in browser with agent-browser
- Snapshot-based element selection
- Location: `tests/e2e/`

## Running Tests
```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

## Writing Good Tests
1. Arrange - Set up test data
2. Act - Execute the code
3. Assert - Verify the result

## Coverage Targets
- Critical paths: 90%+
- Business logic: 80%+
- UI components: 60%+

## Mocking
- Prefer real implementations over mocks
- Mock only external services
- Use factories for test data
