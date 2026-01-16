# Security Policies

Security requirements and best practices for all development work.

## OWASP Top 10 Compliance

### 1. Injection Prevention
```typescript
// BAD - SQL Injection vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`;

// GOOD - Parameterized query
const query = 'SELECT * FROM users WHERE id = ?';
await db.execute(query, [userId]);

// GOOD - ORM usage
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 2. Authentication
- Use established libraries (next-auth, passport)
- Passwords: bcrypt with cost factor ≥12
- Sessions: httpOnly, secure, sameSite cookies
- Tokens: Short-lived JWTs (15 min access, 7 day refresh)
- MFA: Required for admin accounts

### 3. Sensitive Data Protection
- Encrypt at rest: AES-256 for stored data
- Encrypt in transit: TLS 1.3 minimum
- Never log: passwords, tokens, PII, credit cards
- Mask in UI: SSN, credit cards, passwords

### 4. XML External Entities (XXE)
- Disable external entity processing
- Use JSON over XML when possible
- If XML required, use defused parsers

### 5. Access Control
```typescript
// Middleware pattern
const requireRole = (role: string) => (req, res, next) => {
  if (!req.user?.roles.includes(role)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
};

// Usage
app.delete('/api/users/:id', requireRole('admin'), deleteUser);
```

### 6. Security Misconfiguration
- Remove default credentials
- Disable directory listing
- Remove server version headers
- Configure CORS restrictively
- Enable security headers (see below)

### 7. XSS Prevention
```typescript
// BAD - XSS vulnerable
element.innerHTML = userInput;

// GOOD - Text content
element.textContent = userInput;

// GOOD - Sanitized HTML (if HTML required)
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### 8. Insecure Deserialization
- Never deserialize untrusted data
- Use JSON.parse with schema validation
- Avoid eval(), Function(), and dynamic imports

### 9. Vulnerable Dependencies
```bash
# Check for vulnerabilities
npm audit

# Fix automatically where possible
npm audit fix

# Update outdated packages
npm outdated
npm update
```

### 10. Logging & Monitoring
- Log authentication events
- Log authorization failures
- Log input validation failures
- Never log sensitive data
- Alert on anomalies

## Security Headers

```typescript
// Required headers
const securityHeaders = {
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Content-Security-Policy': "default-src 'self'; script-src 'self'",
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
};
```

## Input Validation

### Validation Rules
```typescript
// All input must be validated
const validateUserInput = z.object({
  email: z.string().email().max(255).toLowerCase(),
  username: z.string().regex(/^[a-zA-Z0-9_-]+$/).min(3).max(30),
  age: z.number().int().min(13).max(120).optional(),
  bio: z.string().max(500).transform(sanitizeHtml).optional()
});
```

### File Upload Security
- Validate MIME type (not just extension)
- Scan for malware if possible
- Limit file size (configurable per type)
- Store outside web root
- Generate random filenames
- Never execute uploaded files

## Secrets Management

### Environment Variables
```bash
# .env.local (never commit)
DATABASE_URL=postgresql://...
JWT_SECRET=randomly-generated-256-bit-key
API_KEY=external-service-key
```

### Git Exclusions
```gitignore
# .gitignore
.env
.env.*
!.env.example
*.pem
*.key
secrets/
```

### Secret Rotation
- API keys: Rotate every 90 days
- JWT secrets: Rotate every 30 days with overlap
- Database passwords: Rotate every 90 days
- Document rotation procedures

## Rate Limiting

```typescript
const rateLimits = {
  // Public endpoints
  public: { windowMs: 60000, max: 20 },

  // Authentication endpoints (prevent brute force)
  auth: { windowMs: 900000, max: 5 },

  // Authenticated users
  authenticated: { windowMs: 60000, max: 100 },

  // Admin endpoints
  admin: { windowMs: 60000, max: 200 }
};
```

## Security Checklist

### Before Every PR
- [ ] No secrets in code or commits
- [ ] Input validation on all endpoints
- [ ] SQL queries parameterized
- [ ] XSS vectors sanitized
- [ ] Authentication required where needed
- [ ] Authorization checks in place
- [ ] Error messages don't leak info
- [ ] `npm audit` shows no high/critical

### Before Every Release
- [ ] Dependency audit completed
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Logging configured (no PII)
- [ ] Backup/recovery tested
- [ ] Incident response plan updated

## Incident Response

### Severity Levels
1. **Critical**: Active exploitation, data breach
2. **High**: Vulnerability with known exploit
3. **Medium**: Vulnerability requiring specific conditions
4. **Low**: Minor security improvement

### Response Times
- Critical: Immediate response, fix within 24h
- High: Response within 4h, fix within 72h
- Medium: Response within 24h, fix within 1 week
- Low: Fix in next sprint

### Disclosure Policy
- Never disclose vulnerabilities publicly until fixed
- Coordinate with affected parties
- Provide remediation guidance
- Document lessons learned
