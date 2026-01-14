# Code Review

Review recent code changes for quality, security, and maintainability.

## Review Focus

1. **Code Quality**
   - Readable and well-named variables/functions
   - No duplicated logic
   - Appropriate abstraction level

2. **Error Handling**
   - Proper try/catch blocks
   - Meaningful error messages
   - Graceful degradation

3. **Type Safety**
   - No `any` types without justification
   - Proper null/undefined handling
   - Correct type assertions

4. **Performance**
   - No unnecessary re-renders
   - Efficient data fetching
   - Proper memoization

5. **Security**
   - Input validation
   - No exposed secrets
   - Safe data handling

## Workflow

1. Run `git diff` to see recent changes
2. Focus on modified files only
3. Prioritize findings: Critical → Warnings → Suggestions

Provide actionable feedback with specific code suggestions.
