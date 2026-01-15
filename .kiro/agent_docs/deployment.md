# Deployment Guidelines

## Pre-Deployment Checklist
- [ ] All tests pass
- [ ] No linting errors
- [ ] Environment variables documented
- [ ] Database migrations tested
- [ ] Health check endpoint works

## Environment Variables
```bash
# Required
DATABASE_URL=         # Database connection string
NODE_ENV=             # development | production

# Optional
LOG_LEVEL=            # debug | info | warn | error
```

## Deployment Commands
```bash
# Build
npm run build

# Database migrations
npx prisma migrate deploy

# Start production
npm start
```

## Rollback Procedure
1. Identify the issue
2. Revert to previous deployment
3. Roll back database if needed
4. Investigate root cause

## Monitoring
- Health check: `/api/health`
- Logs: Check deployment platform
- Errors: Monitor error tracking service
