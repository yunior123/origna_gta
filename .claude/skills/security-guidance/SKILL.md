---
name: security-guidance
description: "Pre-edit security scanner. Detects vulnerabilities in code changes before they're committed: command injection, XSS, secrets, unsafe input handling. Adapted from Anthropic's official security-guidance plugin."
---

# Security Guidance

Proactive security scanner that checks code changes for vulnerabilities.

## When to Activate

- After any file edit (especially auth, payment, API endpoints)
- Before commits
- When handling user input
- When adding new API endpoints or routes

## Scan Categories

### 1. Hardcoded Secrets
Grep changed files for:
- `sk_live_`, `sk_test_` (Stripe keys)
- `AKIA` (AWS access keys)
- `ghp_`, `gho_` (GitHub tokens)
- `password\s*=\s*["'][^"']+["']` (hardcoded passwords)
- `-----BEGIN.*PRIVATE KEY-----`
- API keys in Dart `--dart-define` that should be server-side

### 2. Injection Risks
- **SQL**: string concatenation in queries instead of parameterized
- **Command injection**: unsanitized input in `Process.run()` or shell commands
- **XSS**: rendering user HTML without sanitization
- **Path traversal**: user input in file paths without validation

### 3. Authentication Gaps
- Missing `Authorization` header checks on protected endpoints
- JWT validation skipped or using wrong algorithm
- `alg: "none"` not rejected
- Missing rate limiting on auth endpoints
- Token stored in localStorage instead of httpOnly cookie

### 4. Input Validation
- User input used directly without validation
- Missing postal code format validation (`[A-Z]\d[A-Z] \d[A-Z]\d`)
- Missing E.164 phone format validation
- Price/amount fields accepting negative values
- Missing max length on text inputs

### 5. Data Exposure
- PII (email, phone, address) in log statements
- Stack traces exposed in API responses
- Internal error details sent to client
- Stripe card data stored in database

### 6. origna_gta-Specific
- Firebase imports (Firebase is GONE)
- Direct PostgreSQL/Meilisearch calls from Flutter (must use OrignaBase SDK)
- Stripe API called from Flutter (must go through OrignaBase)
- Missing Turnstile validation on auth/checkout endpoints
- Webhook HMAC verification skipped or using non-constant-time comparison

## Output

```
SECURITY SCAN
=============
Files scanned: X
Issues found: Y

CRITICAL:
- [file:line] Hardcoded Stripe key found

HIGH:
- [file:line] SQL string concatenation (injection risk)

MEDIUM:
- [file:line] Missing input validation on postal code field

Status: PASS / FAIL
```

## Rules

- CRITICAL findings block the commit — must fix
- HIGH findings should fix before commit
- MEDIUM findings can be deferred with justification
- Never false-positive on test fixtures or mock data
- Check only changed files (not entire codebase)
