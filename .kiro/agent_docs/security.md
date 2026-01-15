# Security Guidelines

## OWASP Top 10 Checklist
1. [ ] Injection - Use parameterized queries (Prisma handles this)
2. [ ] Broken Auth - Secure session management
3. [ ] Sensitive Data - Encrypt at rest and in transit
4. [ ] XXE - Disable XML external entities
5. [ ] Access Control - Verify permissions on every request
6. [ ] Misconfiguration - Secure defaults, no debug in prod
7. [ ] XSS - Sanitize user input, escape output
8. [ ] Insecure Deserialization - Validate all input
9. [ ] Known Vulnerabilities - Keep dependencies updated
10. [ ] Logging - Log security events, don't log secrets

## Input Validation
```typescript
// Always validate on server
import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});
```

## Authentication
- Use secure session cookies
- Implement rate limiting on login
- Hash passwords with bcrypt
- Support MFA where appropriate

## Secrets Management
- Never commit secrets to git
- Use environment variables
- Rotate secrets regularly
- Audit secret access

## Headers
```typescript
// Security headers
{
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Strict-Transport-Security': 'max-age=31536000',
}
```
