# OrignaGTA Security Audit Report
**Date**: 2026-03-18  
**Scope**: origna_gta (Flutter) + orignabase (Rust Backend)  
**Audit Depth**: Comprehensive (Auth, Payments, Permissions, Input, CORS, Rate Limiting, Secrets)

---

## CRITICAL FINDINGS

### 1. CORS Configuration Allows Wildcard Origins (CRITICAL)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-core/src/server.rs` (lines 18-22)  
**Severity**: CRITICAL  
**Description**: The Axum server uses `.allow_origin(tower_http::cors::Any)`, which permits requests from ANY origin without origin validation. This allows CSRF attacks and cross-origin data exfiltration.

```rust
CorsLayer::new()
    .allow_origin(tower_http::cors::Any)  // ❌ WILDCARD — CRITICAL
    .allow_methods(tower_http::cors::Any)
    .allow_headers(tower_http::cors::Any),
```

**Impact**: 
- Any attacker domain can make authenticated requests to the API
- If cookies/credentials are sent automatically, CSRF attacks succeed
- Unauthorized cross-origin data access

**Fix**: Replace wildcard with explicit origin list:
```rust
let allowed_origins = [
    "https://orignagta.ca",
    "https://dev.orignagta.ca",
    "https://staging.orignagta.ca",
]
.iter()
.filter_map(|origin| origin.parse().ok())
.collect::<Vec<_>>();

CorsLayer::new()
    .allow_origin(tower_http::cors::allow_list(allowed_origins))
    .allow_methods([Method::GET, Method::POST, Method::OPTIONS])
    .allow_headers([AUTHORIZATION, CONTENT_TYPE])
    .allow_credentials()
```

**Note**: Pentest file `pentest.rs` has a test `test_24_a08_cors_does_not_allow_wildcard_with_credentials()` that expects CORS to be restricted, but the implementation currently violates this.

---

### 2. Missing Cloudflare Turnstile Verification (CRITICAL)
**File**: OrignaBase auth routes (no validation found)  
**Scope**: `/auth/register`, `/auth/login`, `/payments/checkout`  
**Severity**: CRITICAL  
**Description**: Turnstile bot-protection tokens are generated on Flutter web but NOT verified server-side in OrignaBase. This allows bot attacks, account enumeration, and mass credential testing.

**Evidence**:
- Flutter implements `TurnstileService` (`lib/services/turnstile_service.dart`) to generate tokens
- Schema field `turnstileToken` defined in `schema_constants.dart`
- No `verify_turnstile()` or Cloudflare verification calls found in Rust backend
- Auth routes and checkout accept requests without Turnstile validation

**Impact**:
- Automated account creation (bot attack)
- Brute-force password attacks at scale
- Mass checkout spam
- Account enumeration

**Fix**: Add Turnstile verification to `/auth/register`, `/auth/login`, `/payments/checkout`:
```rust
// In ob-auth/src/routes.rs
async fn verify_turnstile(
    client: &reqwest::Client,
    token: &str,
    secret: &str,
) -> Result<bool> {
    #[derive(serde::Deserialize)]
    struct TurnstileResponse {
        success: bool,
    }
    
    let resp: TurnstileResponse = client
        .post("https://challenges.cloudflare.com/turnstile/v0/siteverify")
        .form(&[("secret", secret), ("response", token)])
        .send()
        .await?
        .json()
        .await?;
    
    Ok(resp.success)
}

// Modify register() handler:
pub async fn register(...) -> Result<...> {
    let token = body.turnstile_token.as_deref()
        .ok_or(Error::Validation("Turnstile token required".into()))?;
    
    if !verify_turnstile(&client, token, &secret).await? {
        return Err(Error::Validation("Bot verification failed".into()));
    }
    // ... rest of registration
}
```

---

## HIGH SEVERITY FINDINGS

### 3. PostgreSQL Query Injection Risk (HIGH)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/webhooks.rs` (lines 120-130, 150-160)  
**Severity**: HIGH  
**Description**: Event ID is escaped using `ob_core::escape_sql_string()` but the query is built as a raw string format. While escaping is used, there's a risk of logic injection if the escape function is incomplete.

```rust
// Line 120-130
let existing = state
    .db
    .query_raw(&format!(
        "SELECT * FROM {} WHERE eventId = '{}'",
        collections::WEBHOOK_EVENTS,
        ob_core::escape_sql_string(event_id)  // ✓ Escaped, but raw format is risky
    ))
    .await;
```

**Impact**: While current escaping appears sound, raw string formatting is error-prone and future changes could introduce injection.

**Fix**: Use parameterized queries (query_bind) instead of raw format:
```rust
let existing = state.db.query_bind(
    &format!("SELECT * FROM {}", collections::WEBHOOK_EVENTS),
    json!({ "eventId": event_id })
).await?;
```

---

### 4. Missing Input Validation for Postal Codes (HIGH)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/checkout.rs` (lines 85-91)  
**Severity**: HIGH (Secondary - proper validation exists but regex is strict)  
**Description**: Postal code validation is correct (regex enforces 6-character format) but validation error messages could reveal information.

```rust
fn is_valid_canadian_postal(code: &str) -> bool {
    let c: Vec<char> = code.to_uppercase().chars().collect();
    c.len() == 6
        && c[0].is_ascii_alphabetic()
        && c[1].is_ascii_digit()
        && c[2].is_ascii_alphabetic()
        && c[3].is_ascii_digit()
        && c[4].is_ascii_alphabetic()
        && c[5].is_ascii_digit()
}
```

**Status**: ✓ GOOD — Proper validation exists.

---

### 5. Rate Limiting Not Applied to Checkout Endpoint (HIGH)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/checkout.rs` (lines 114-122)  
**Severity**: HIGH  
**Description**: Rate limiting IS implemented for `create_checkout_session` (5 requests per 1 second per user):

```rust
crate::shared::rate_limiter::check_user_rate_limit(
    &state.db,
    &user_id,
    "create_checkout_session",
    5,  // max_requests
    1,  // window_secs
)
.await?;
```

**Status**: ✓ GOOD — Rate limiting is properly implemented.

---

## MEDIUM SEVERITY FINDINGS

### 6. JWT Token Type Validation Could Be Stricter (MEDIUM)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-auth/src/middleware.rs` (lines 55-60)  
**Severity**: MEDIUM  
**Description**: JWT verification checks `typ == "access"` but allows anonymous context to fall through without hard rejection on failed verification.

```rust
match verify_token(token, keys) {
    Ok(claims) if claims.typ == "access" => AuthContext::from_claims(claims),
    Ok(_) => return Err(Error::Auth("Invalid token type".into())),
    Err(_) => AuthContext::anonymous(),  // ⚠️ Invalid tokens become anonymous
}
```

**Impact**: If token verification fails (corrupt/expired), request becomes unauthenticated instead of rejecting. Handlers must check `ctx.authenticated` explicitly.

**Status**: Partially Mitigated — Handlers that require auth should use security rules. Currently relies on handler-level checks.

**Fix**: Add a debug assertion or warning for production:
```rust
Err(e) => {
    if cfg!(debug_assertions) {
        tracing::warn!("Token verification failed: {e}");
    }
    AuthContext::anonymous()
}
```

---

### 7. Price Tampering Defense Present But Tolerance Could Be Tighter (MEDIUM)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/checkout.rs` (lines 271-280)  
**Severity**: MEDIUM  
**Description**: Checkout verifies client subtotal against server-calculated subtotal with 1% tolerance:

```rust
fn checkout_subtotal_tolerance(actual_subtotal_cents: i64) -> i64 {
    (actual_subtotal_cents as f64 * 0.01).max(1.0) as i64  // 1% tolerance
}
```

**Impact**: Allows 1% price variance. For a $10,000 order, buyer can undercut by $100. Acceptable for most transactions but consider lower tolerance.

**Status**: ✓ GOOD — Server-side recalculation prevents most tampering.

---

### 8. Self-Purchase Prevention Implemented (GOOD)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/checkout.rs` (lines 239-246)  
**Severity**: N/A (Good Practice)  
**Description**: Checkout explicitly prevents sellers from buying their own products:

```rust
if seller_id == user_id {
    return Err(ob_core::Error::Validation(
        "Cannot purchase your own products".into(),
    ));
}
```

**Status**: ✓ GOOD

---

### 9. Webhook Idempotency Implemented (GOOD)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/webhooks.rs` (lines 115-135)  
**Severity**: N/A (Good Practice)  
**Description**: Webhook handler checks for duplicate `eventId` before processing:

```rust
let existing = state.db.query_raw(...)
    .await;

if let Ok(rows) = &existing && !rows.is_empty() {
    info!(event_id = %event_id, "Webhook event already processed, skipping");
    return Ok(Json(WebhookResponse { received: true }));
}
```

**Status**: ✓ GOOD — Prevents double-processing.

---

### 10. Stripe Webhook Signature Verification Implemented (GOOD)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-handlers/src/payments/webhooks.rs` (lines 33-82)  
**Severity**: N/A (Good Practice)  
**Description**: HMAC signature verification on every Stripe webhook:

```rust
fn verify_stripe_signature(
    payload: &[u8],
    sig_header: &str,
    secret: &str,
    tolerance_secs: i64,
) -> Result<(), ob_core::Error> {
    // ... timestamp tolerance check ...
    // ... HMAC verification ...
}
```

**Status**: ✓ GOOD — Constant-time comparison prevents timing attacks.

---

## LOW SEVERITY FINDINGS

### 11. Rate Limiter IP Extraction Could Be More Robust (LOW)
**File**: `/Users/yuniorrodriguezosorio/Documents/GitHub/orignabase/crates/ob-auth/src/rate_limit.rs` (lines 45-65)  
**Severity**: LOW  
**Description**: IP extraction checks `X-Forwarded-For` and `X-Real-IP` headers, but trusted proxy list is not validated.

```rust
fn extract_ip(request: &Request) -> IpAddr {
    if let Some(forwarded) = request.headers().get("x-forwarded-for")
        && let Ok(val) = forwarded.to_str()
        && let Some(first_ip) = val.split(',').next()
        && let Ok(ip) = first_ip.trim().parse::<IpAddr>()
    {
        return ip;  // ⚠️ Trusts X-Forwarded-For without proxy validation
    }
    // ... fallback ...
}
```

**Impact**: Attacker behind a proxy could spoof X-Forwarded-For to bypass rate limits.

**Status**: Mitigated if Caddy (reverse proxy) is the only trusted source. Ensure Caddy validates and overwrites these headers.

**Fix**: Add trusted proxy list or validate that request comes from Caddy only:
```rust
// In production, only trust X-Forwarded-For from known proxy IPs (e.g., Caddy)
const TRUSTED_PROXIES: &[&str] = &["127.0.0.1", "10.0.0.0/8"];

if let Some(forwarded) = request.headers().get("x-forwarded-for") {
    // Only trust if request came through a known proxy
    if let Ok(peer_addr) = request.extensions().get::<SocketAddr>() {
        if TRUSTED_PROXIES.contains(&peer_addr.ip().to_string()) {
            // Extract IP from X-Forwarded-For
        }
    }
}
```

---

### 12. Secrets Not Hardcoded (GOOD)
**Scope**: Both Flutter and Rust  
**Status**: ✓ GOOD  
**Evidence**:
- Flutter uses `dart-define` for environment config only (no secrets)
- Rust uses `Config::require_secret()` which loads from environment or Secret Manager
- `.gitignore` excludes `.env`, `.env.prod`, `secrets-*.json`
- No `sk_test`, `sk_live`, API keys found in source

---

### 13. Input Validation for Products (GOOD)
**File**: Flutter validation constants (`lib/core/constants/validation_constants.dart`)  
**Status**: ✓ GOOD  
**Evidence**:
- Email regex validation: `/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/`
- Strong password: 8+ chars, uppercase, lowercase, digit, special character
- Max field lengths enforced

---

### 14. Stripe Secret Key Not in Flutter (GOOD)
**Scope**: Both codebases  
**Status**: ✓ GOOD  
**Evidence**:
- Flutter never constructs Stripe API calls
- All Stripe interactions go through OrignaBase endpoints
- Stripe secret key only in OrignaBase environment

---

## ARCHITECTURAL OBSERVATIONS

### JWT Implementation
- RS256 (RSA) used in production, HS256 fallback for development
- Token types properly segregated: `access`, `refresh`, `email_verify`, `password_reset`, `mfa_challenge`
- Expiry enforced on verification
- Token revocation not explicitly implemented (no token blacklist)

### PostgreSQL Security Rules
- Security evaluator implemented (`ob-security` crate) with rule engine
- Supports: `isAuthenticated()`, `hasRole()`, `isOwner()` functions
- Rules apply OR semantics (any matching rule allows)
- Field-level access control supported

### Database Access Patterns
- Parameterized queries used in most places
- `query_bind()` method with JSON parameters (good)
- Some raw `query_raw()` with string interpolation (acceptable with escaping, but suboptimal)

### Money Handling
- All values in integer cents (no floats)
- Server-side calculation prevents price tampering
- Platform fee calculation correct: `platformFeeTotalCents / subtotalCents`

---

## SUMMARY

| Category | Status | Critical | High | Medium | Low |
|----------|--------|----------|------|--------|-----|
| Auth & JWT | ✓ Mostly Good | — | — | 1 | — |
| PostgreSQL Permissions | ✓ Good | — | 1 | — | — |
| Input Validation | ✓ Good | — | — | — | — |
| Stripe/Payments | ✓ Good | — | — | 1 | — |
| CORS | ✗ Critical | 1 | — | — | — |
| Rate Limiting | ✓ Good | — | — | — | 1 |
| Bot Protection | ✗ Critical | 1 | — | — | — |
| Secrets Management | ✓ Good | — | — | — | — |

**Total Findings**: 14  
- **Critical**: 2 (CORS wildcard, Missing Turnstile)
- **High**: 1 (PostgreSQL injection risk)
- **Medium**: 3 (JWT handling, Price tolerance, IP extraction)
- **Low**: 1 (Proxy trust)
- **Good/No Issues**: 7

---

## IMMEDIATE ACTIONS REQUIRED

1. **CRITICAL - Fix CORS** (1 day): Replace wildcard CORS with explicit origin list
2. **CRITICAL - Add Turnstile Verification** (2-3 days): Implement Cloudflare Turnstile token validation in auth and checkout endpoints
3. **HIGH - Replace Raw Queries** (1-2 days): Convert `query_raw()` calls in webhooks to parameterized `query_bind()`
4. **MEDIUM - Proxy Validation** (1 day): Add trusted proxy list to rate limiter

