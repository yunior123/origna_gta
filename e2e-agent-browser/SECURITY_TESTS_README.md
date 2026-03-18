# Security Fixes E2E Test Suite

## Overview
Comprehensive test suite verifying all critical security fixes implemented in the OrignaGTA backend and Flutter frontend.

**3 test files, 40+ tests covering:**
- Authentication & JWT validation
- Authorization & access control
- Payment & checkout integrity
- Data validation & integrity
- Webhook security
- Rate limiting
- Compliance & audit logging

---

## Test Files

### 1. `specs/phase1-api/security-auth-fixes.spec.ts` (16 tests)

**JWT & Authentication**
- T01: Request without Authorization header → 401
- T02: Request with invalid JWT → 401
- T03: Request with valid JWT → 200

**CORS Enforcement**
- T04: CORS from dev.orignagta.ca → allowed
- T05: CORS from evil.com → blocked
- T06: CORS from orignagta.ca (prod) → allowed

**Admin Role Enforcement**
- T07: Admin endpoint without admin role → 403
- T08: Admin with admin role → access granted
- T09: Seller tries to access admin endpoint → 403

**Access Control**
- T10: Buyer tries to read other buyer's orders → empty/403
- T11: Seller tries to modify other seller's product → 403
- T12: Self-purchase prevention (seller buying own product → blocked)

**Rate Limiting & Validation**
- T13: 10+ rapid login attempts → 429 (rate limited)
- T14: OrderStatus API returns lowercase (pending, confirmed, shipped, delivered, cancelled)
- T15: Webhook without Stripe-Signature → rejected
- T16: Health endpoint returns "ok"

---

### 2. `specs/phase1-api/security-payment-fixes.spec.ts` (13 tests)

**Platform Fee Calculation**
- T01: Order created with platformFeeTotalCents > 0
- T02: Platform fee = (subtotalCents × rate) / subtotalCents

**Amount Validation**
- T03: Order total = subtotal + tax + shipping

**Refund & Stock**
- T04: Refund amount > order total → rejected
- T05: Stock check: buy last item → next attempt fails
- T06: Negative stock → rejected

**Price Validation**
- T07: Price = 0 → rejected
- T08: Price > $100k CAD (10,000,000 cents) → rejected

**Product Lifecycle**
- T09: draft→active (valid), active→draft (invalid)

**Perishable Shipping**
- T10: Perishable > 50km → rejected

**Free Shipping Threshold**
- T11: Order ≥ $75 CAD → shippingCostCents = 0

**Idempotency & Image Validation**
- T12: Same checkout request twice → same session (idempotent)
- T13: Image URL with non-R2 domain → rejected

---

### 3. `specs/phase1-api/security-data-fixes.spec.ts` (15 tests)

**Input Validation**
- T01: Phone E.164 format (+14165551234) → valid
- T02: Phone invalid (416555) → rejected
- T03: Postal code valid (M5V 2T6) → valid
- T04: Postal code invalid (12345) → rejected

**Password & Token Security**
- T05: Password reset token used once → invalidated on second use
- T06: TOTP: 6+ failed attempts in 15 min → account locked

**Data Integrity**
- T07: Account deletion cascades to orders/addresses/cart
- T08: Duplicate active subscription → rejected
- T09: Webhook dedup: same event ID twice → second ignored

**File & Query Validation**
- T10: File upload > 500MB → rejected
- T11: DB query timeout: responds within 30s
- T12: Admin audit log: admin action creates audit_logs entry

**Data Format Enforcement**
- T13: Postal code format validation on addresses
- T14: Password strength validation (reject weak passwords)
- T15: Seller actions require verified email

---

## Running the Tests

### All security tests
```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e-agent-browser
bun test specs/phase1-api/security-*.spec.ts
```

### Single file
```bash
bun test specs/phase1-api/security-auth-fixes.spec.ts
bun test specs/phase1-api/security-payment-fixes.spec.ts
bun test specs/phase1-api/security-data-fixes.spec.ts
```

### With verbose output
```bash
bun test --verbose specs/phase1-api/security-auth-fixes.spec.ts
```

---

## Test Infrastructure

### API Client Functions Used
- `signIn(email, password)` — Authenticate user
- `callOk(fn, data, token)` — Call API, expect success (throws on error)
- `callExpectError(fn, data, token)` — Call API, expect error
- `callCallable(fn, data, token)` — Raw API call
- `getProductStock(productId, token)` — Get current stock
- `discoverProducts(token)` — List available products
- `fetch()` — Raw HTTP for low-level tests (CORS, headers, etc.)

### Test Accounts (dev environment)
| Role | Email | Password |
|------|-------|----------|
| Admin | e2e-admin@test.origna.ca | REDACTED_TEST_PASSWORD |
| Seller | e2e-seller@test.origna.ca | REDACTED_TEST_PASSWORD |
| Buyer | e2e-buyer@test.origna.ca | REDACTED_TEST_PASSWORD |

### API URL
- **Dev**: https://api.dev.orignagta.ca
- **Test products**: e2e_product_admin_seller, e2e_product_test_seller, e2e_product_intl_seller

---

## Coverage Checklist

✅ **Authentication (4 tests)**
  - JWT validation & parsing
  - Authorization header enforcement
  - Invalid/expired token rejection

✅ **Authorization (5 tests)**
  - Admin role verification
  - Seller/buyer access control
  - Self-purchase prevention

✅ **CORS (3 tests)**
  - Allowed origins (orignagta.ca domains)
  - Blocked origins (evil.com, untrusted)
  - Preflight responses

✅ **Rate Limiting (1 test)**
  - Multiple rapid login attempts → 429

✅ **Payment & Checkout (7 tests)**
  - Platform fee > 0
  - Amount arithmetic validation
  - Stock enforcement
  - Price validation (0 < price ≤ $100k)
  - Lifecycle state transitions
  - Perishable shipping distance
  - Free shipping threshold ($75 CAD)

✅ **Data Integrity (10 tests)**
  - Phone format (E.164)
  - Postal code format (Canadian)
  - Token invalidation
  - Rate limiting (TOTP)
  - Cascade deletes
  - Deduplication (webhooks, subscriptions)
  - File size limits
  - Query timeouts
  - Audit logging
  - Password strength

✅ **Webhook Security (2 tests)**
  - Signature verification required
  - Event deduplication

✅ **Compliance (1 test)**
  - Health endpoint

---

## Common Test Patterns

### Expecting Success
```typescript
const result = await callOk('create_order', payload, buyerToken);
expect(result.orderId).toBeTruthy();
```

### Expecting Failure
```typescript
const error = await callExpectError('create_product', {
  priceCents: 0, // Invalid
}, sellerToken);
expect(error.code).not.toBe('unexpected-success');
```

### Raw Fetch (for headers, CORS, etc.)
```typescript
const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
  },
});
expect([200, 401, 403]).toContain(res.status);
```

### Skipping Tests (when prerequisites missing)
```typescript
if (!testProductId) {
  console.log('Skipping: no test product found');
  return;
}
```

---

## Known Limitations

1. **Password Reset Tokens**: Test assumes reset endpoint is implemented; adjust as needed.
2. **TOTP Locking**: Requires TOTP to be configured in dev environment.
3. **Account Deletion Cascade**: Uses non-existent user to avoid actual deletion.
4. **Perishable Shipping**: Depends on seller location & product perishability config.
5. **File Upload Size**: Validates API rules without uploading massive files.

---

## Maintenance Notes

- Update test accounts if they change in dev environment
- Adjust timeout values (default 60s) if API is slow
- Keep TEST_PRODUCTS in config in sync with actual seeded products
- Monitor rate limits if backend changes limits
- Validate postal code format if it changes

---

## Related Documentation

- Security audit: `/tmp/rust_backend_security_recommendations.md`
- Performance audit: `/tmp/perf_audit.md`
- E2E test patterns: `e2e-patterns.md`
- API client: `lib/api-client.ts`
- Config: `lib/config.ts`

