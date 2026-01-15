# Database Guidelines

## Schema Design
1. Use appropriate data types
2. Add indexes for query patterns
3. Use foreign keys for integrity
4. Consider soft deletes for audit

## Prisma Commands
```bash
# Generate client after schema changes
npx prisma generate

# Create migration
npx prisma migrate dev --name description

# Apply migrations (production)
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Open database GUI
npx prisma studio
```

## Migration Safety
- Always test migrations on copy of prod data
- Ensure migrations are reversible
- No data loss on rollback
- Consider zero-downtime patterns

## Query Optimization
- Use `include` for related data (avoid N+1)
- Add indexes for WHERE clauses
- Use `select` to limit returned fields
- Check query plans with EXPLAIN

## Common Patterns
```typescript
// Avoid N+1
const users = await prisma.user.findMany({
  include: { posts: true }
});

// Pagination
const posts = await prisma.post.findMany({
  skip: page * pageSize,
  take: pageSize,
});
```
