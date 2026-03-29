# OWASP Mobile Top 10 — Flutter Checklist (origna_gta)

Adapted from OWASP Mobile Top 10 (2024) for Flutter e-commerce apps with Rust backend.

## M1: Improper Credential Usage

- [ ] No hardcoded API keys, tokens, or secrets in Dart source
- [ ] Stripe keys never in Flutter — all Stripe calls go through OrignaBase
- [ ] JWT tokens stored securely (flutter_secure_storage, not SharedPreferences)
- [ ] OrignaBase SDK manages token lifecycle (auto-refresh, secure storage)
- [ ] No credentials in `dart-define` for production builds
- [ ] `.env` files gitignored and never committed

**origna_gta specific:**
- OrignaBase URLs from `EnvConfig`, secrets from VPS `.env` files
- macOS Keychain vault for dev secrets (`get-secret`/`set-secret`)

## M2: Inadequate Supply Chain Security

- [ ] `flutter pub audit` run before every release
- [ ] `cargo audit` for Rust dependencies
- [ ] Major versions pinned in `pubspec.yaml`
- [ ] No `any` version constraints
- [ ] Third-party packages reviewed before adoption
- [ ] Lock files committed (`pubspec.lock`, `Cargo.lock`)

## M3: Insecure Authentication/Authorization

- [ ] RS256 JWT with algorithm enforcement (no `alg: "none"`)
- [ ] JWT expiry validated server-side on every request
- [ ] User ID derived from JWT `sub`, never from request body
- [ ] Row-level security in PostgreSQL `RLS` policies
- [ ] Seller isolation: own products/orders/profile only
- [ ] Admin actions require `admin` role + audit logging
- [ ] Google Sign-In via server-side OAuth (not client `authenticate()`)
- [ ] Email verification required before seller features

**origna_gta specific:**
- Firebase Auth completely removed — OrignaBase handles all auth
- JWT `sub` = `users:xxx` (full path), `uid` = `xxx` (short) — match correctly

## M4: Insufficient Input/Output Validation

- [ ] All user input validated server-side (client = UX only)
- [ ] Canadian postal codes: `[A-Z]\d[A-Z] \d[A-Z]\d`
- [ ] Phone: E.164 (`+1XXXXXXXXXX`)
- [ ] Prices: positive integer cents, max $100K CAD (10,000,000 cents)
- [ ] Error responses never expose SQL, stack traces, or internal paths
- [ ] PostgreSQL queries always parameterized (no string concatenation)

## M5: Insecure Communication

- [ ] All API calls over HTTPS (TLS 1.2+)
- [ ] Certificate pinning considered for production
- [ ] No HTTP fallback in production
- [ ] Caddy auto-TLS on VPS handles certificates
- [ ] WebSocket connections (if any) over WSS

**origna_gta specific:**
- Dev: `https://api.dev.orignagta.ca`
- Prod: `https://api.orignagta.ca`
- Never `http://` in production builds

## M6: Inadequate Privacy Controls

- [ ] No PII in logs (emails, phones, addresses, payment data)
- [ ] Buyer addresses limited to shipping needs for sellers
- [ ] Bank details in Stripe Connect only (never in PostgreSQL)
- [ ] GDPR delete: full user data purge capability
- [ ] Analytics/telemetry respects user consent
- [ ] Sentry error reports scrub PII before sending

## M7: Insufficient Binary Protections

- [ ] Flutter web: `--release` mode for production (no debug symbols)
- [ ] `debugShowCheckedModeBanner: false` in production
- [ ] No `print()` or `debugPrint()` in production code (use AppLogger)
- [ ] Obfuscation enabled for mobile builds: `--obfuscate --split-debug-info`
- [ ] Source maps not deployed to production web server

## M8: Security Misconfiguration

- [ ] Rate limiting enforced: auth 5/min, checkout 10/min, search 30/min
- [ ] Cloudflare Turnstile on auth + checkout (bot protection)
- [ ] CORS configured correctly on OrignaBase
- [ ] Webhook signature verification never skipped
- [ ] Webhook replay protection: reject > 300s old events
- [ ] Dev mode (`OB_TEST_MODE=1`) never enabled in production

**origna_gta specific:**
- VPS security: SSH key-only, fail2ban, ufw firewall
- Docker: non-root containers, limited capabilities

## M9: Insecure Data Storage

- [ ] Sensitive data in flutter_secure_storage (not SharedPreferences)
- [ ] No caching of payment data
- [ ] Cart data cleared after successful checkout
- [ ] Session tokens cleared on logout
- [ ] No sensitive data in URL parameters

## M10: Insufficient Cryptography

- [ ] JWT: RS256 (asymmetric) not HS256 (symmetric)
- [ ] Auto-generated keys at `./data/keys` (OrignaBase)
- [ ] Webhook HMAC: SHA-256 with constant-time verification
- [ ] Passwords: REDACTED_SECRET hashing (OrignaBase handles this)
- [ ] No custom crypto implementations — use battle-tested libraries

## Quick Scan Commands

```bash
# Check for hardcoded secrets in Dart
grep -rn 'sk_live_\|sk_test_\|whsec_\|api_key\|secret' lib/ --include='*.dart'

# Check for Firebase remnants
grep -rn 'FirebaseAuth\|Firestore\|FirebaseStorage\|firebase_' lib/ --include='*.dart'

# Check for print statements
grep -rn 'print(\|debugPrint(' lib/ --include='*.dart'

# Check for float money
grep -rn 'double.*price\|double.*total\|double.*fee\|double.*amount' lib/ --include='*.dart'

# Rust: check for string-formatted queries
grep -rn 'format!.*SELECT\|format!.*INSERT\|format!.*UPDATE\|format!.*DELETE' orignabase/ --include='*.rs'

# Rust: check for unwrap in production code
grep -rn '\.unwrap()' orignabase/crates/ --include='*.rs' | grep -v test | grep -v '#\[cfg(test)\]'

# Dependency audit
flutter pub audit
cd orignabase && cargo audit
```
