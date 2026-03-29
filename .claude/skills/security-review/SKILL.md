---
name: security-review
description: "Security review for Flutter + Rust e-commerce apps. Checks Stripe webhooks, JWT validation, parameterized queries, input validation, rate limiting, and OWASP mobile patterns. Use before releases or after auth/payment changes."
---

# Security Review — origna_gta

Comprehensive security review adapted for origna_gta's Flutter/Dart + Rust (OrignaBase) e-commerce stack.

## When to Use

- Before releases to production
- After changes to auth, payment, or user data flows
- When asked to "audit security", "review security", or "check for vulnerabilities"
- After adding new API endpoints

## Review Checklist

### 1. Stripe Webhook Security

- [ ] HMAC signature verified on every incoming webhook request
- [ ] Constant-time comparison via `mac.verify_slice()` (not string `==`)
- [ ] Replay protection: reject events with timestamp > 300 seconds old
- [ ] Idempotency: check `webhook_events` collection for duplicate event IDs before processing
- [ ] Idempotency keys on all outbound Stripe API calls: `{order_id}-{action}`
- [ ] Webhook secret loaded from env/Secret Manager, not hardcoded
- [ ] Never confirm orders from redirect URL alone — always wait for webhook

### 2. JWT / Authentication

- [ ] RS256 algorithm enforced (prevent `alg: "none"` or `alg: "HS256"` bypass)
- [ ] JWT expiry validated on every request
- [ ] User identity derived from JWT `sub` claim, never from request body
- [ ] Refresh tokens handled by OrignaBase SDK (no manual refresh logic)
- [ ] No Firebase Auth imports anywhere (Firebase is completely removed)
- [ ] Google Sign-In uses server-side OAuth redirect, not client-side `authenticate()`

### 3. Database Security (PostgreSQL)

- [ ] All queries parameterized: `$1`, `$2` — never string concatenation/format!
- [ ] Row-level security via `RLS` policies on all tables
- [ ] Seller can only access own products/orders/profile
- [ ] Buyer can only access own orders/profile
- [ ] Admin actions logged with `adminUid` in audit trail
- [ ] PostgreSQL credentials never in source code

### 4. Input Validation

- [ ] Canadian postal codes: `[A-Z]\d[A-Z] \d[A-Z]\d` regex
- [ ] Phone numbers: E.164 format (`+1XXXXXXXXXX`)
- [ ] Prices: positive integers in cents, max 10,000,000 ($100,000 CAD)
- [ ] Email: validated format on both client and server
- [ ] All user input validated server-side (client validation is UX only)

### 5. Rate Limiting

- [ ] Auth endpoints (login, register): 5 requests/minute via `tower_governor`
- [ ] Checkout endpoints: 10 requests/minute
- [ ] Search endpoints: 30 requests/minute
- [ ] Flutter SDK implements exponential backoff on 429 responses (1s start, 60s max)
- [ ] Search input debounced 300ms minimum before firing queries

### 6. Bot Protection (Turnstile)

- [ ] Cloudflare Turnstile on auth endpoints (login, register)
- [ ] Turnstile on checkout endpoints
- [ ] Token validated server-side
- [ ] Site key injected at deploy time, not hardcoded
- [ ] Never bypassed in production builds

### 7. No Secrets in Code

Scan for these forbidden patterns:

```
sk_live_*          — Stripe live key
sk_test_*          — Stripe test key (OK in .env, NOT in source)
whsec_*            — Webhook secret
API key patterns   — Long alphanumeric strings that look like keys
.env contents      — Never committed
```

### 8. PII Protection

- [ ] No PII logged in plaintext (emails, phones, addresses, payment info)
- [ ] Buyer addresses not exposed to sellers beyond shipping needs
- [ ] Bank details never stored in PostgreSQL (Stripe Connect handles it)
- [ ] GDPR delete support: purge all user records on request
- [ ] Error responses never expose stack traces or SQL details

### 9. Dependency Security

```bash
# Flutter
flutter pub audit

# Rust
cargo audit
```

- Zero high/critical CVEs required for release
- Pin major versions in pubspec.yaml (no `any` constraints)

### 10. Flutter-Specific

- [ ] No Stripe secret keys in Flutter code or `dart-define` variables
- [ ] `debugShowCheckedModeBanner: false` in production
- [ ] No Firebase SDK imports (completely removed)
- [ ] OrignaBase URLs from `EnvConfig`, never hardcoded

## Output Format

```
SECURITY REVIEW
===============
Stripe Webhooks:     [PASS/FAIL] (X issues)
JWT/Auth:            [PASS/FAIL] (X issues)
Database Security:   [PASS/FAIL] (X issues)
Input Validation:    [PASS/FAIL] (X issues)
Rate Limiting:       [PASS/FAIL] (X issues)
Bot Protection:      [PASS/FAIL] (X issues)
Secrets in Code:     [PASS/FAIL] (X issues)
PII Protection:      [PASS/FAIL] (X issues)
Dependencies:        [PASS/FAIL] (X CVEs)
Flutter-Specific:    [PASS/FAIL] (X issues)

Overall: [SECURE/ISSUES FOUND]

Critical Issues:
1. ...

Recommendations:
1. ...
```

## References

See `references/owasp-flutter-checklist.md` for OWASP Mobile Top 10 adapted for Flutter.
