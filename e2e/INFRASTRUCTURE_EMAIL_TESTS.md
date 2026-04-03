# Infrastructure & Email Notification E2E Tests

**Created**: 2026-03-18  
**Location**: `/specs/phase1-api/`  
**Test Framework**: Bun + bun:test  
**Total Tests**: 30 (across 3 files)

## Overview

Three new comprehensive test suites verify infrastructure stability and email notification system integrity without requiring browser interaction.

### Test Files

#### 1. infrastructure-health.spec.ts (12 tests)
**Purpose**: Verify OrignaBase infrastructure, health endpoints, and security headers.

**Tests**:
- `GET /health` returns 200 with "ok" status
- Docker healthcheck: all services responding
- CSP headers present (Content-Security-Policy)
- X-XSS-Protection header present
- CORS not using wildcard (`*`)
- Rate limiting headers present (X-RateLimit-*)
- API responds within 5 seconds (no hangs)
- POST /auth/login endpoint responds (no 500)
- POST /auth/register endpoint responds (no 500)
- SurrealDB connection healthy (implicit via /health)
- Meilisearch connection healthy (search endpoint works)
- Webhook endpoint exists (POST /api/webhooks/stripe ≠ 404)
- Support chat endpoint exists (POST /api/support/chat ≠ 404)

**Key Assertions**:
- All infrastructure endpoints respond with status < 500
- Security headers are present (no wildcard CORS)
- Response times under 5 seconds
- Webhook endpoint exists (not 404) even if signature invalid

#### 2. email-triggers.spec.ts (8 tests)
**Purpose**: Verify email notification triggers don't error on API calls. Can't verify actual delivery, but confirms triggers fire without 500 errors.

**Tests**:
- Create order via API → no 500 error (email trigger fires)
- Update order to shipped with tracking → no 500 error
- Password reset request → no 500 error
- Email verification request → no 500 error
- Registration → welcome email trigger (no error)
- Seller payout scheduled → no error on delivered transition
- Return request → notification trigger (no error)
- Bulk operations don't crash email system (create 5 orders rapidly)

**Key Assertions**:
- Email-triggering endpoints don't return 500 or 503
- Service stays alive under rapid bulk operations
- All email workflow steps complete without server errors

**Dependencies**:
- Test accounts (admin, seller, buyer)
- Stable product: `e2e_product_test_seller`

#### 3. data-integrity.spec.ts (10 tests)
**Purpose**: Verify data consistency and correctness in API responses (timestamps, money values, status enums, schema).

**Tests**:
- Timestamps are valid (not DateTime.now() fallback)
- Money values are integer cents (no decimals)
- OrderStatus values are lowercase (pending, confirmed, shipped, delivered, cancelled)
- Product prices have priceCents field (integer)
- Shipping costs are integer cents
- Platform fee is calculated (platformFeeTotalCents > 0)
- Free shipping threshold works (subtotal ≥ 7500 → shipping = 0)
- SurrealDB record IDs are valid format (collection:id)
- Search returns paginated results (has limit/offset)
- Consent timestamps present on user profile

**Key Assertions**:
- All monetary fields are integers (cents), not floats
- Timestamps are in valid ranges (recent, not fallback values)
- Status enums are lowercase
- SurrealDB IDs follow `collection:id` format
- Platform fee > 0 on orders with subtotal ≥ $75

## Running the Tests

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e-agent-browser

# Run all infrastructure + email tests
bun test specs/phase1-api/{infrastructure-health,email-triggers,data-integrity}.spec.ts

# Run individually
bun test specs/phase1-api/infrastructure-health.spec.ts
bun test specs/phase1-api/email-triggers.spec.ts
bun test specs/phase1-api/data-integrity.spec.ts

# Via npm scripts
npm run test:api  # Runs all phase1-api tests
```

## Test Environment

- **API**: https://api.dev.orignagta.ca
- **Test Accounts**:
  - Admin: `e2e-admin@test.origna.ca` / `REDACTED_TEST_PASSWORD`
  - Seller: `e2e-seller@test.origna.ca` / `REDACTED_TEST_PASSWORD`
  - Buyer: `e2e-buyer@test.origna.ca` / `REDACTED_TEST_PASSWORD`
- **Stable Products**:
  - `e2e_product_test_seller` — general purpose test product
  - `e2e_product_admin_seller` — adversarial tests
  - `e2e_product_intl_seller` — China address for international shipping

## Expected Behavior

### Infrastructure Tests
✓ All endpoints respond without hanging (< 5s)  
✓ Security headers present (CSP, X-XSS-Protection)  
✓ CORS doesn't use wildcard  
✓ All services (SurrealDB, Meilisearch) reachable  

### Email Trigger Tests
✓ Email notifications don't crash API (no 500 errors)  
✓ Bulk operations don't exhaust email system  
✓ All email-triggering workflows complete  

### Data Integrity Tests
✓ All timestamps are valid Unix timestamps (not fallbacks)  
✓ All money values are integers (cents), not floats  
✓ Status enums follow spec (lowercase)  
✓ Platform fee calculated correctly  
✓ Free shipping threshold enforced  
✓ SurrealDB IDs in correct format  

## Debugging Failed Tests

**Timeout (> 5s response)**:
- Check OrignaBase logs: `ssh root@204.168.137.16 docker logs orignabase_dev`
- Verify SurrealDB connection: `curl https://api.dev.orignagta.ca/health`

**Money value is float**:
- OrignaBase returning wrong type (check Rust schemas)
- Frontend may need to convert but API should return integers

**Timestamp invalid**:
- Check `DateTime.now()` fallbacks in Rust code (should be explicit timestamps)
- Verify database has populated timestamps

**Email trigger returns 500**:
- Check Mailjet credentials in .env.dev
- Verify email provider is responsive
- Check logs for email formatting errors

**CORS is wildcard**:
- Update Caddy config on VPS: remove wildcard, use explicit origin list

## CI Integration

These tests run as part of `npm run test:api` in the E2E test suite.

```bash
# In CI pipeline
bun test specs/phase1-api/infrastructure-health.spec.ts
bun test specs/phase1-api/email-triggers.spec.ts
bun test specs/phase1-api/data-integrity.spec.ts
```

No additional setup required — all use dev environment and test accounts.
