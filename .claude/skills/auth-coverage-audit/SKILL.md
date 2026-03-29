---
name: auth-coverage-audit
description: "Deep audit of OrignaGTA authentication and authorization: JWT RS256 lifecycle, MFA/TOTP, password security, rate limiting, Cloudflare Turnstile, Google OAuth, login tracking, email verification, and auth middleware. Covers all 11 source files in ob-auth with only 1 test file — identifies test coverage gaps. Use when asked to 'audit auth', 'check authentication', 'review JWT', 'auth security audit', or similar."
---

# Auth Coverage Audit — OrignaGTA

Complete audit of the authentication and authorization stack. OrignaBase handles ALL auth (Firebase Auth is gone). 11 source files in `ob-auth`, currently covered by only 1 test file — this audit identifies both security issues and test coverage gaps.

## When To Use

- Before production deploy touching auth code
- After modifying JWT, MFA, password, or OAuth logic
- When investigating authentication failures or token issues
- Pre-release security review
- When expanding test coverage for ob-auth

## Files to Read

### Backend (Rust — OrignaBase ob-auth crate)
```
orignabase/crates/ob-auth/src/jwt.rs              # RS256 JWT signing, verification, claims, expiry
orignabase/crates/ob-auth/src/key_rotation.rs      # RSA key pair generation, rotation schedule
orignabase/crates/ob-auth/src/totp.rs              # TOTP/MFA setup, verification, recovery codes
orignabase/crates/ob-auth/src/password.rs          # Bcrypt hashing, minimum strength validation
orignabase/crates/ob-auth/src/rate_limit.rs        # tower_governor rate limiting config
orignabase/crates/ob-auth/src/turnstile.rs         # Cloudflare Turnstile bot protection
orignabase/crates/ob-auth/src/oauth.rs             # Google OAuth server-side redirect, state CSRF
orignabase/crates/ob-auth/src/login_tracking.rs    # Audit log, suspicious login detection
orignabase/crates/ob-auth/src/email.rs             # Email verification token generation, expiry
orignabase/crates/ob-auth/src/middleware.rs         # Auth context extraction, role enforcement
orignabase/crates/ob-auth/src/lib.rs               # Module exports, public API
```

### Handler Integration
```
orignabase/crates/ob-handlers/src/users/mod.rs     # User registration, login, profile endpoints
orignabase/crates/ob-handlers/src/rest_api.rs      # Route definitions with auth middleware
```

### Flutter (Frontend)
```
origna_gta/lib/core/repositories/orignabase_auth_repository.dart  # Auth SDK calls
origna_gta/lib/core/providers.dart                                 # Auth providers
```

### Tests (CRITICAL GAP)
```
orignabase/crates/ob-auth/tests/                   # Only 1 test file for 11 source files
```

---

## Audit Checkpoints

### 1. JWT Lifecycle (RS256)

**Token flow: Login -> server signs JWT -> client stores -> auto-attaches to requests -> refresh on expiry**

**Check:**
- [ ] RS256 algorithm used (asymmetric — private key signs, public key verifies)
- [ ] Private key NEVER exposed outside OrignaBase process
- [ ] Public key available for token verification (other services, middleware)
- [ ] Token claims include: `sub` (user ID), `exp` (expiry), `iat` (issued at), `role`
- [ ] `sub` format: user UUID — verify consumers handle this
- [ ] Short-lived access tokens (recommended: 15-60 minutes)
- [ ] Refresh token stored securely (HttpOnly cookie or secure storage)
- [ ] Refresh token rotation: old refresh token invalidated on use
- [ ] Token expiry checked on EVERY request in middleware
- [ ] Clock skew tolerance: small window (≤30 seconds) for `exp` check
- [ ] `alg: none` attack prevented (reject tokens without RS256 algorithm)
- [ ] JWT library rejects tokens signed with HMAC using RSA public key (CVE-2015-9235)
- [ ] Token revocation: logout invalidates refresh token server-side
- [ ] Auth expiry: 6 days (BusinessRules)

**Grep for:** `RS256`, `jsonwebtoken`, `encode`, `decode`, `exp`, `sub`, `refresh`, `private_key`, `public_key`

### 2. Key Rotation

**RSA key pairs must be rotated periodically without breaking active sessions.**

**Check:**
- [ ] Key pair stored at `./data/keys` (auto-generated on first run)
- [ ] Key files have restrictive permissions (600 or 400)
- [ ] Rotation schedule defined (e.g., every 90 days)
- [ ] During rotation: old key still verifies existing tokens (grace period)
- [ ] `kid` (Key ID) header in JWT identifies which key signed it
- [ ] JWKS endpoint or equivalent for public key distribution
- [ ] Key generation uses secure random (not deterministic seed)
- [ ] Key size: RSA 2048-bit minimum (4096 preferred)

**Grep for:** `key_rotation`, `generate_key`, `RSA`, `kid`, `jwks`, `data/keys`, `PEM`

### 3. MFA / TOTP

**Two-factor authentication: setup -> QR code -> verify -> enable -> recovery codes**

**Check:**
- [ ] TOTP secret generated with cryptographically secure random
- [ ] Secret stored encrypted at rest (not plaintext in DB)
- [ ] QR code URL uses `otpauth://totp/OrignaGTA:{email}?secret={secret}&issuer=OrignaGTA`
- [ ] TOTP verification allows ±1 time step window (30-second tolerance)
- [ ] Rate limit on TOTP verification attempts (max 5 per minute)
- [ ] Recovery codes: 8-10 codes, each single-use, stored hashed
- [ ] Recovery code used -> marked as consumed (cannot reuse)
- [ ] MFA setup requires current password confirmation
- [ ] MFA disable requires current TOTP code or recovery code
- [ ] Login flow: password verified FIRST, then TOTP prompt (don't reveal if MFA is enabled to unauthenticated users)
- [ ] Backup codes displayed ONCE at setup (not retrievable later)

**Grep for:** `totp`, `recovery_code`, `mfa`, `two_factor`, `otpauth`, `secret`, `time_step`

### 4. Password Security

**Bcrypt hashing with minimum strength enforcement.**

**Check:**
- [ ] Bcrypt with cost factor ≥ 12 (balances security vs. latency)
- [ ] Password minimum: 8 characters, at least 1 uppercase, 1 lowercase, 1 digit
- [ ] No maximum password length that's unreasonably short (allow up to 128 chars)
- [ ] Password never logged or stored in plaintext anywhere
- [ ] Password comparison uses constant-time comparison (bcrypt verify does this)
- [ ] Password reset: token generated with secure random, single-use, expires in 1 hour
- [ ] Password reset doesn't reveal whether email exists (timing-safe response)
- [ ] Old password required when changing password (not just session token)
- [ ] Password hash updated if bcrypt cost factor changes (rehash on successful login)

**Grep for:** `bcrypt`, `hash`, `verify`, `cost`, `password_reset`, `MIN_LENGTH`

### 5. Rate Limiting

**tower_governor configuration for auth endpoints.**

**Check:**
- [ ] Login endpoint: strict limit (e.g., 5 attempts per minute per IP)
- [ ] Register endpoint: strict limit (e.g., 3 per minute per IP)
- [ ] Password reset: strict limit (e.g., 3 per hour per email)
- [ ] TOTP verification: max 5 per minute
- [ ] Rate limit by IP AND by account (prevent distributed brute force)
- [ ] 429 response includes `Retry-After` header
- [ ] Rate limit state not stored only in memory (survives restart)
- [ ] Bypass attempts: X-Forwarded-For header not blindly trusted (use rightmost trusted proxy)
- [ ] Dev mode (`OB_TEST_MODE=1`) disables rate limits — verify prod doesn't have this

**Grep for:** `tower_governor`, `rate_limit`, `GovernorConfig`, `per_second`, `per_minute`, `429`, `Retry-After`, `OB_TEST_MODE`

### 6. Cloudflare Turnstile

**Bot protection on auth and checkout endpoints.**

**Check:**
- [ ] Turnstile token validated SERVER-SIDE on: login, register, checkout
- [ ] Validation calls Cloudflare API: `POST https://challenges.cloudflare.com/turnstile/v0/siteverify`
- [ ] Secret key stored in env/secrets (not in source code)
- [ ] Validation failure returns 403 with clear error message
- [ ] Turnstile not bypassed in production (check for `OB_TEST_MODE` or similar)
- [ ] Token is single-use (Cloudflare enforces this, but verify we don't cache/reuse)
- [ ] Timeout on Turnstile verification API call (don't hang on Cloudflare outage)
- [ ] Fallback behavior on Cloudflare outage: fail open or fail closed? (should fail closed for auth)

**Grep for:** `turnstile`, `siteverify`, `cf-turnstile`, `TURNSTILE_SECRET`, `challenges.cloudflare.com`

### 7. Google OAuth

**Server-side OAuth redirect flow (not client-side `google_sign_in` package).**

**Check:**
- [ ] OAuth flow: Flutter -> OrignaBase `/auth/google/start` -> Google consent -> callback -> JWT
- [ ] `state` parameter generated with secure random and verified on callback (CSRF protection)
- [ ] `state` parameter bound to user session (not just a random string)
- [ ] Authorization code exchanged server-side (never exposed to client)
- [ ] ID token claims verified: `iss`, `aud`, `exp`, `email_verified`
- [ ] `aud` must match OrignaBase Google client ID exactly
- [ ] Email from Google linked to existing account if email matches (account linking)
- [ ] New user created if no matching email (with `email_verified: true` from Google)
- [ ] Redirect URI matches exactly what's registered in Google Cloud Console
- [ ] No open redirect: callback URL validated against allowlist

**Grep for:** `google`, `oauth`, `state`, `authorization_code`, `id_token`, `callback`, `redirect_uri`, `GOOGLE_CLIENT`

### 8. Login Tracking & Suspicious Login Detection

**Audit log of login attempts with anomaly detection.**

**Check:**
- [ ] Every login attempt logged: user ID (or email hash), IP, timestamp, success/failure, user agent
- [ ] Failed login attempts tracked per account (for lockout policy)
- [ ] Account lockout after N consecutive failures (e.g., 10 in 15 minutes)
- [ ] Lockout notification sent to account email
- [ ] Suspicious login detection: new IP + new device -> confirmation email
- [ ] Login from new country triggers additional verification
- [ ] Audit log entries are append-only (not deletable via API)
- [ ] PII in audit log: email hashed, IP stored (needed for security), user agent truncated

**Grep for:** `login_tracking`, `login_attempt`, `suspicious`, `lockout`, `audit_log`, `ip_address`, `user_agent`

### 9. Email Verification

**Token-based email verification flow.**

**Check:**
- [ ] Verification token: cryptographically secure random, ≥ 32 bytes
- [ ] Token expires: 24 hours (or configurable)
- [ ] Token is single-use: consumed on first verification
- [ ] Verification link: `https://api.orignagta.ca/auth/verify-email?token={token}`
- [ ] After verification: `email_verified` flag set on user record
- [ ] Seller features gated behind `email_verified: true`
- [ ] Re-send verification rate limited (max 3 per hour)
- [ ] Email change: requires verification of NEW email before switching
- [ ] Token stored hashed in DB (not plaintext — prevents DB dump from mass-verifying)

**Grep for:** `verify_email`, `verification_token`, `email_verified`, `token_hash`, `expires_at`, `single_use`

### 10. Auth Middleware

**Request-level authentication and authorization.**

**Check:**
- [ ] Every protected endpoint passes through auth middleware
- [ ] Middleware rejects: missing token, expired token, invalid signature, wrong algorithm
- [ ] User ID extracted from `sub` claim and injected into request context
- [ ] Role extracted from JWT claims (admin, seller, buyer)
- [ ] Role-based access: admin endpoints reject non-admin tokens
- [ ] Seller endpoints verify `seller_profiles` record exists and is active
- [ ] User ID from JWT is the ONLY source of identity (never trust client-sent user_id)
- [ ] Middleware does NOT return different error messages for "no token" vs "invalid token" (info leak)
- [ ] OPTIONS/CORS preflight requests bypass auth middleware

**Grep for:** `middleware`, `Bearer`, `extract`, `claims`, `role`, `admin`, `seller`, `authorization`

---

## Test Coverage Gap Analysis

### Current State
- 11 source files in `orignabase/crates/ob-auth/src/`
- Only 1 test file in `orignabase/crates/ob-auth/tests/`
- **Estimated coverage: < 20%**

### Priority Test Gaps (ordered by risk)

| File | Risk | Missing Tests |
|------|------|---------------|
| `jwt.rs` | P0 | Token signing/verification, expiry, algorithm enforcement, `alg:none` rejection |
| `middleware.rs` | P0 | Missing token, expired token, wrong role, CORS preflight bypass |
| `password.rs` | P0 | Hash/verify roundtrip, strength validation, timing-safe comparison |
| `totp.rs` | P1 | Setup, verify, recovery codes, time window, rate limit |
| `turnstile.rs` | P1 | Valid token, invalid token, timeout, bypass in test mode |
| `oauth.rs` | P1 | State parameter CSRF, code exchange, ID token validation |
| `rate_limit.rs` | P1 | Rate exceeded, under limit, reset, different endpoints |
| `key_rotation.rs` | P2 | Key generation, rotation, grace period, old key still valid |
| `login_tracking.rs` | P2 | Login logging, lockout, suspicious detection |
| `email.rs` | P2 | Token generation, expiry, single-use, re-send limit |
| `lib.rs` | P3 | Module exports (compile-time check) |

---

## Severity Guide

| Severity | Criteria | Example |
|----------|----------|---------|
| **P0 Critical** | Authentication bypass or token forgery possible | `alg:none` accepted; rate limit bypassed in prod; password logged |
| **P1 High** | Weakened security or missing protection layer | TOTP allows unlimited retries; Turnstile skipped; no key rotation |
| **P2 Medium** | Suboptimal security or missing audit trail | Short bcrypt cost; no login tracking; email token not hashed |
| **P3 Low** | Best practice not followed | Key size 2048 instead of 4096; verbose error messages |

## Output Format

For each finding:
```
## [P0/P1/P2/P3] — Title
- **File**: path/to/file.rs:line
- **Issue**: What's wrong
- **Impact**: What could happen
- **Fix**: Specific code change needed
- **Test**: Test case that should exist to prevent regression
```
