# Agent Browser Examples

Side-by-side comparisons and practical examples for migrating from Playwright to agent-browser.

## Migration Comparison

### Navigation

**Playwright:**
```typescript
await page.goto('https://example.com');
await page.goBack();
await page.goForward();
await page.reload();
```

**agent-browser:**
```bash
agent-browser open https://example.com
agent-browser back
agent-browser forward
agent-browser reload
```

### Element Interaction

**Playwright:**
```typescript
await page.click('button.submit');
await page.fill('input[name="email"]', 'test@example.com');
await page.press('Enter');
await page.hover('.menu-item');
```

**agent-browser:**
```bash
agent-browser click "button.submit"
agent-browser fill "input[name='email']" "test@example.com"
agent-browser press "Enter"
agent-browser hover ".menu-item"
```

### Waiting

**Playwright:**
```typescript
await page.waitForSelector('button.submit');
await page.waitForLoadState('load');
await page.waitForLoadState('networkidle');
```

**agent-browser:**
```bash
agent-browser wait "button.submit"
agent-browser wait --load
agent-browser wait --networkidle
```

### Screenshots

**Playwright:**
```typescript
await page.screenshot({ path: 'screenshot.png' });
await page.screenshot({ path: 'full.png', fullPage: true });
```

**agent-browser:**
```bash
agent-browser screenshot
agent-browser screenshot --full
agent-browser screenshot --name "full"
```

### Getting Page Content

**Playwright:**
```typescript
const content = await page.content();
const title = await page.title();
const url = page.url();
```

**agent-browser:**
```bash
agent-browser snapshot --json
agent-browser state
agent-browser url
```

## Common Workflows

### 1. Login Flow

**Playwright:**
```typescript
test('user can login', async ({ page }) => {
  await page.goto('https://app.example.com/login');
  await page.fill('[data-testid="email"]', 'user@example.com');
  await page.fill('[data-testid="password"]', 'password123');
  await page.click('[data-testid="submit"]');
  await page.waitForURL('**/dashboard');
  
  const heading = await page.locator('h1').textContent();
  expect(heading).toBe('Dashboard');
});
```

**agent-browser (AI Agent Workflow):**
```bash
# 1. Navigate
agent-browser open https://app.example.com/login

# 2. Get page structure
agent-browser snapshot --json > login.json

# 3. AI parses JSON to find refs:
# email_field: ref:101
# password_field: ref:102
# submit_button: ref:103

# 4. Fill and submit
agent-browser fill "ref:101" "user@example.com"
agent-browser fill "ref:102" "password123"
agent-browser click "ref:103"

# 5. Wait and verify
agent-browser wait --load
agent-browser snapshot --json > dashboard.json

# 6. AI verifies by checking for dashboard elements in JSON
```

### 2. Form Validation Testing

**Playwright:**
```typescript
test('shows validation errors', async ({ page }) => {
  await page.goto('https://app.example.com/signup');
  await page.click('[data-testid="submit"]');
  
  const emailError = await page.locator('[data-testid="email-error"]').textContent();
  expect(emailError).toContain('Email is required');
  
  const passwordError = await page.locator('[data-testid="password-error"]').textContent();
  expect(passwordError).toContain('Password is required');
});
```

**agent-browser:**
```bash
# Navigate to form
agent-browser open https://app.example.com/signup

# Get initial state
agent-browser snapshot --json > form-initial.json

# Submit without filling
agent-browser click "ref:submit-button"

# Wait for validation
agent-browser wait "div[role='alert']"

# Get error state
agent-browser snapshot --json > form-errors.json

# AI verifies error messages in JSON:
# - Checks for elements with role="alert"
# - Verifies error text content
```

### 3. Multi-Step Wizard

**Playwright:**
```typescript
test('completes multi-step wizard', async ({ page }) => {
  await page.goto('https://app.example.com/wizard');
  
  // Step 1
  await page.fill('[name="firstName"]', 'John');
  await page.fill('[name="lastName"]', 'Doe');
  await page.click('button:has-text("Next")');
  
  // Step 2
  await page.fill('[name="email"]', 'john@example.com');
  await page.fill('[name="phone"]', '555-1234');
  await page.click('button:has-text("Next")');
  
  // Step 3
  await page.check('[name="terms"]');
  await page.click('button:has-text("Submit")');
  
  await page.waitForURL('**/success');
});
```

**agent-browser:**
```bash
# Start wizard
agent-browser open https://app.example.com/wizard

# Step 1
agent-browser snapshot --json > step1.json
agent-browser fill "ref:firstName" "John"
agent-browser fill "ref:lastName" "Doe"
agent-browser click "text:Next"
agent-browser wait --load

# Step 2
agent-browser snapshot --json > step2.json
agent-browser fill "ref:email" "john@example.com"
agent-browser fill "ref:phone" "555-1234"
agent-browser click "text:Next"
agent-browser wait --load

# Step 3
agent-browser snapshot --json > step3.json
agent-browser check "ref:terms"
agent-browser click "text:Submit"
agent-browser wait --load

# Verify success
agent-browser snapshot --json > success.json
agent-browser url  # Should be /success
```

### 4. Accessibility Testing

**Playwright:**
```typescript
test('page is accessible', async ({ page }) => {
  await page.goto('https://app.example.com');
  
  const snapshot = await page.accessibility.snapshot();
  
  // Check for missing alt text
  const images = snapshot.children.filter(node => node.role === 'img');
  images.forEach(img => {
    expect(img.name).toBeTruthy();
  });
  
  // Check heading hierarchy
  const headings = snapshot.children.filter(node => 
    node.role === 'heading'
  );
  // Verify no skipped levels
});
```

**agent-browser:**
```bash
# Get accessibility tree
agent-browser open https://app.example.com
agent-browser snapshot --json > a11y.json

# AI analyzes JSON for:
# 1. Images without alt text (elements with role="img" and no name)
# 2. Heading hierarchy (check level progression)
# 3. Form labels (inputs with associated labels)
# 4. Interactive elements (buttons, links have accessible names)
# 5. ARIA attributes (proper usage)

# Example jq queries:
# Find images without alt text
jq '.elements[] | select(.role=="img" and .name==null)' a11y.json

# Check heading levels
jq '.elements[] | select(.role=="heading") | .level' a11y.json
```

### 5. Network Monitoring

**Playwright:**
```typescript
test('makes correct API calls', async ({ page }) => {
  const requests = [];
  
  page.on('request', request => {
    if (request.url().includes('/api/')) {
      requests.push({
        url: request.url(),
        method: request.method()
      });
    }
  });
  
  await page.goto('https://app.example.com');
  await page.click('[data-testid="load-data"]');
  
  expect(requests).toContainEqual({
    url: expect.stringContaining('/api/users'),
    method: 'GET'
  });
});
```

**agent-browser:**
```bash
# Start monitoring
agent-browser open https://app.example.com
agent-browser network > network.log &

# Trigger action
agent-browser click "ref:load-data"
agent-browser wait --networkidle

# Check network log
cat network.log | grep "/api/users"
```

### 6. Parallel Testing with Sessions

**Playwright:**
```typescript
test.describe.parallel('parallel tests', () => {
  test('test 1', async ({ page }) => {
    await page.goto('https://app.example.com');
    // Test 1 logic
  });
  
  test('test 2', async ({ page }) => {
    await page.goto('https://app.example.com');
    // Test 2 logic
  });
});
```

**agent-browser:**
```bash
# Session 1 (background)
(
  agent-browser --session test1 open https://app.example.com
  agent-browser --session test1 snapshot --json > test1.json
  agent-browser --session test1 click "ref:123"
) &

# Session 2 (background)
(
  agent-browser --session test2 open https://app.example.com
  agent-browser --session test2 snapshot --json > test2.json
  agent-browser --session test2 click "ref:456"
) &

# Wait for both to complete
wait
```

### 7. Authenticated Sessions

**Playwright:**
```typescript
test.use({
  storageState: 'auth.json'
});

test('authenticated test', async ({ page }) => {
  await page.goto('https://app.example.com/dashboard');
  // Already logged in via storageState
});
```

**agent-browser:**
```bash
# Set auth headers
agent-browser open https://app.example.com/dashboard \
  --headers '{"Authorization":"Bearer token123"}'

# Or use cookies
agent-browser cookies set "session_id" "abc123" --domain "example.com"
agent-browser open https://app.example.com/dashboard
```

## AI Agent Patterns

### Pattern: Snapshot-Driven Interaction

```bash
#!/bin/bash
# AI agent workflow for form filling

# 1. Navigate to page
agent-browser open https://app.example.com/form

# 2. Get page structure
SNAPSHOT=$(agent-browser --json snapshot)

# 3. AI parses snapshot to identify form fields
# Example: Extract all input refs
INPUTS=$(echo "$SNAPSHOT" | jq -r '.elements[] | select(.tag=="input") | .ref')

# 4. AI determines what to fill based on field names/labels
# email_ref=$(echo "$SNAPSHOT" | jq -r '.elements[] | select(.name=="email") | .ref')
# name_ref=$(echo "$SNAPSHOT" | jq -r '.elements[] | select(.name=="name") | .ref')

# 5. Fill fields
agent-browser fill "$email_ref" "user@example.com"
agent-browser fill "$name_ref" "John Doe"

# 6. Find and click submit button
# submit_ref=$(echo "$SNAPSHOT" | jq -r '.elements[] | select(.role=="button" and .name=="Submit") | .ref')
agent-browser click "$submit_ref"

# 7. Verify result
agent-browser wait --load
agent-browser --json snapshot | jq '.url'  # Check URL changed
```

### Pattern: Error Detection

```bash
#!/bin/bash
# AI agent workflow for detecting errors

# Navigate and interact
agent-browser open https://app.example.com
agent-browser click "ref:123"

# Wait for response
sleep 2

# Get current state
STATE=$(agent-browser --json snapshot)

# Check for error indicators
HAS_ERROR=$(echo "$STATE" | jq '.elements[] | select(.role=="alert" or .class | contains("error"))')

if [ -n "$HAS_ERROR" ]; then
  echo "Error detected:"
  echo "$HAS_ERROR" | jq '.name'
  exit 1
fi
```

### Pattern: Visual Regression

```bash
#!/bin/bash
# AI agent workflow for visual regression testing

# Baseline
agent-browser open https://app.example.com
agent-browser screenshot --full --name "baseline"

# Make changes...

# Compare
agent-browser open https://app.example.com
agent-browser screenshot --full --name "current"

# AI compares baseline.png and current.png
# (Use image comparison tool or AI vision model)
```

## Tips for AI Agents

### 1. Always Use JSON Mode
```bash
# GOOD: Machine-readable
agent-browser --json snapshot | jq '.elements[] | select(.role=="button")'

# BAD: Human-readable (hard to parse)
agent-browser snapshot | grep "button"
```

### 2. Prefer Refs Over Selectors
```bash
# GOOD: Stable refs
agent-browser click "ref:123"

# LESS GOOD: Fragile selectors
agent-browser click "div.container > div:nth-child(2) > button"
```

### 3. Snapshot Before Every Interaction
```bash
# GOOD: Fresh snapshot
agent-browser snapshot --json > current.json
# Parse to find element
agent-browser click "ref:123"

# BAD: Stale information
# Using old snapshot data
```

### 4. Use Sessions for Isolation
```bash
# GOOD: Isolated tests
agent-browser --session test1 open https://example.com
agent-browser --session test2 open https://example.com

# BAD: Shared state
agent-browser open https://example.com  # Default session
```

### 5. Wait After State Changes
```bash
# GOOD: Wait for stability
agent-browser click "ref:123"
agent-browser wait --load
agent-browser snapshot --json

# BAD: Race condition
agent-browser click "ref:123"
agent-browser snapshot --json  # Might be stale
```

## Troubleshooting

### Element Not Found
```bash
# Debug: Take snapshot to see what's available
agent-browser snapshot --interactive

# Debug: Use headed mode to see browser
agent-browser --headed open https://example.com
```

### Timing Issues
```bash
# Add explicit waits
agent-browser wait "button.submit"
agent-browser wait --load
agent-browser wait --networkidle
```

### Session Conflicts
```bash
# Use unique session names
agent-browser --session "test-$(date +%s)" open https://example.com
```

---

**For more examples:** See `.kiro/docs/agent-browser-guide.md`
