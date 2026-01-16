# API Standards

Standards for designing, implementing, and documenting APIs in this project.

## REST API Design

### URL Structure
```
GET    /api/v1/resources          # List
GET    /api/v1/resources/:id      # Read
POST   /api/v1/resources          # Create
PUT    /api/v1/resources/:id      # Update (full)
PATCH  /api/v1/resources/:id      # Update (partial)
DELETE /api/v1/resources/:id      # Delete
```

### Naming Conventions
- Use plural nouns: `/users`, `/orders`, `/products`
- Use kebab-case: `/user-profiles`, `/order-items`
- Nest for relationships: `/users/:id/orders`
- Max 3 levels of nesting

### Query Parameters
- Filtering: `?status=active&type=premium`
- Sorting: `?sort=created_at:desc,name:asc`
- Pagination: `?page=1&limit=20` or `?cursor=abc123`
- Fields: `?fields=id,name,email`

## Request/Response Format

### Success Response
```json
{
  "data": { ... },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

### List Response
```json
{
  "data": [ ... ],
  "meta": {
    "total": 150,
    "page": 1,
    "limit": 20,
    "hasMore": true
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

## HTTP Status Codes

### Success
- `200 OK` - Successful GET, PUT, PATCH, DELETE
- `201 Created` - Successful POST (include Location header)
- `204 No Content` - Successful DELETE with no body

### Client Errors
- `400 Bad Request` - Malformed request syntax
- `401 Unauthorized` - Missing/invalid authentication
- `403 Forbidden` - Authenticated but not authorized
- `404 Not Found` - Resource doesn't exist
- `409 Conflict` - Resource state conflict
- `422 Unprocessable Entity` - Validation errors
- `429 Too Many Requests` - Rate limit exceeded

### Server Errors
- `500 Internal Server Error` - Unexpected server error
- `502 Bad Gateway` - Upstream service error
- `503 Service Unavailable` - Temporary overload
- `504 Gateway Timeout` - Upstream timeout

## Authentication

### Headers
```
Authorization: Bearer <jwt_token>
X-API-Key: <api_key>
```

### JWT Claims
```json
{
  "sub": "user_123",
  "email": "user@example.com",
  "roles": ["user", "admin"],
  "iat": 1705312200,
  "exp": 1705315800
}
```

## Rate Limiting

### Headers (Response)
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705312800
Retry-After: 60
```

### Limits by Tier
- Anonymous: 10 req/min
- Authenticated: 100 req/min
- Premium: 1000 req/min

## Versioning

### URL Versioning (Preferred)
```
/api/v1/users
/api/v2/users
```

### Deprecation
- Announce 6 months before removal
- Return `Deprecation` header with sunset date
- Include migration guide in docs

## Validation

### Input Validation Rules
```typescript
// Example with Zod
const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(2).max(100),
  password: z.string().min(8).max(128),
  role: z.enum(['user', 'admin']).default('user')
});
```

### Sanitization
- Strip HTML from text inputs
- Normalize unicode (NFC)
- Trim whitespace
- Limit string lengths

## Documentation

### Required for Each Endpoint
- HTTP method and URL
- Description of purpose
- Request body schema
- Response body schema
- Error codes and meanings
- Example request/response
- Authentication requirements
- Rate limit information

### OpenAPI Specification
All APIs must have OpenAPI 3.0+ specification in `/docs/api/`.
