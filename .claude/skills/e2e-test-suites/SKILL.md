---
name: e2e-test-suites
description: Catalog of all 279 E2E Playwright tests and 288 backend pytest tests with file locations. Use when running tests, adding tests, or debugging test failures.
---

# E2E Test Suite Reference

## Test Count: 279 E2E (9 files) + 288 Backend

### Test Results Summary (Last Run: Feb 10 2026 — Run 7, 266 passed)

| File | Tests | Passing | Status |
|------|-------|---------|--------|
| regression-e2e.spec.ts | 42 | 42/42 | ✅ All pass |
| comprehensive-flows-e2e.spec.ts | 34 | 34/34 | ✅ All pass |
| payment-workflow-e2e.spec.ts | 62 | 62/62 | ✅ All pass |
| logic-failures-e2e.spec.ts | 29 | 29/29 | ✅ (E.2 flaky, passes on retry) |
| flutter-web-e2e.spec.ts | 16 | 16/16 | ✅ All pass |
| fullstack-e2e.spec.ts | 37 | 37/37 | ✅ All pass |
| shipping-lifecycle-e2e.spec.ts | 48 | 48/48 | ✅ All pass |
| admin-email-test.spec.ts | 3 | 3/3 | ✅ Requires real Stripe + Mailjet |
| full-marketplace-e2e.spec.ts | 17 | 5/5+12skip | ✅ 12 intentionally skipped (CanvasKit) |

**Total: 266/267 passing (12 intentionally skipped), 1 flaky (passes on retry)**

### E2E Run Progression (Feb 2026)
| Run | Passed | Failed | Key Fixes Applied |
|-----|--------|--------|-------------------|
| 1 | 200 | 25 | Initial baseline |
| 2 | 194 | 29 | Webhook URL, fillStripeCheckout |
| 3 | 222 | 17 | SERVER_TIMESTAMP, paymentStatus, seller restrictions |
| 4 | 251 | 10 | Multi-seller Suite B rewrite, auto-promote SHIPPED |
| 5 | 262 | 2 | _capture_payment_impl, Yahoo isActive, stock assertion |
| 6 | 264 | 2 | A.6 idToken fix, more SERVER_TIMESTAMP ArrayUnion |
| 7 | 266 | 0 | Payout records in idempotent path, rating cleanup |

### Root Causes FIXED (Feb 2026 — 12 root causes)
1. **SERVER_TIMESTAMP in arrays** — Firestore sentinel cannot serialize inside array items or ArrayUnion. 8 instances fixed. Use `datetime.now(timezone.utc)`.
2. **Auto-capture mode** — `paymentStatus` is always `'captured'`, never `'authorized'`.
3. **Seller delivery restriction** — Sellers cannot mark delivered. Use admin.
4. **Multi-seller order-level blocked** — Use `update_item_status` per item.
5. **Missing auto-promote to SHIPPED** — `update_item_status` now auto-promotes.
6. **CallableRequest vs Flask Request** — `_capture_payment_impl` extraction.
7. **Yahoo product missing isActive** — Need both `status: 'active'` AND `isActive: true`.
8. **signIn returns {idToken}** — NOT `.token`.
9. **Missing payout records** — Auto-capture idempotent path now creates payouts.
10. **Rating test pollution** — Clean existing ratings before rating tests.
11. **Webhook URL project ID** — `orignagta` (NO hyphen).
12. **Stock field = stockQuantity** — Not `stock`. Assertion threshold 500.

### Critical: api-helpers.ts — Canonical E2E Module
**ALL spec files import from `e2e/api-helpers.ts`** (~830 lines, 40+ exports). Never duplicate these utilities.

Key exports:
- **Auth**: `signIn(email, password?)` — fail-fast, throws if no idToken
- **Callables**: `callCallable(fn, data, token)`, `callOk(fn, data, token)` (throws on error), `callExpectError(fn, data, token, code)`
- **Firestore REST**: `readDoc(collection, id)`, `writeDoc(collection, id, fields)`, `patchDoc(collection, id, fields)` (uses updateMask!), `deleteDoc(collection, id)`, `listDocs(collection)`, `listSubcollection(collection, id, sub)`
- **Firestore encoding**: `toFirestoreFields(obj)`, `toFsVal(v)`, `sv()/iv()/bv()`, `parseVal(v)`, `parseDoc(doc)`
- **Checkout**: `buildCheckoutPayload()`, `buildMultiSellerPayload()`, `createOrder()`, `forceOrderStatus()`
- **Polling**: `pollDocField(collection, id, field, expected, timeout)`, `waitForOrderStatus()`
- **Stripe UI**: `fillStripeCheckout(page)` (handles Link popup + 3DS + overlay), `fullCheckoutAndPay(page, token)`, `fullMultiSellerCheckoutAndPay(page, token)`
- **Setup**: `checkInfrastructure()`, `ensureSeedData()`, `createTestUser(email, pass, displayName)`
- **Constants**: `AUTH_EMULATOR`, `FIRESTORE_EMULATOR`, `FUNCTIONS_EMULATOR`, `WEB_APP_URL`, `PROJECT_ID`, `FIRESTORE_BASE`, `DEFAULT_PASS`, `STRIPE_CARD`, `TEST_ACCOUNTS`, `TEST_PRODUCTS`

### Stripe E2E Knowledge
- Card `4242424242424242` is NOT enrolled in 3D Secure
- "VerificationModal" is Stripe's "Link" login popup — dismiss with `page.locator('[data-testid="VerificationModal"]')` close button
- `fillStripeCheckout()` handles: Link popup dismissal → iframe card fill → Pay button → wait for navigation
- Tests needing Stripe webhooks require `stripe listen --forward-to localhost:5001/orignagta/us-central1/stripeWebhook` running

---

### comprehensive-flows-e2e.spec.ts — 32 tests (NEW)
10 suites (A-J) covering previously untested Cloud Function endpoints:
- A. Seller Onboarding (3): request, check status, get dashboard link
- B. User Profile (4): get, update, update address (Canada), reject non-Canada
- C. Cart & Favorites (3): add/get cart items, toggle favorites
- D. Admin MFA (3): setup, verify, status check
- E. Payment Providers (3): list providers, get connect status, check Stripe account
- F. Webhook Edge Cases (3): missing signature, invalid event, duplicate event
- G. Product Lifecycle (3): create, update, soft-delete
- H. GDPR & Roles (3): export data, delete account request, role management
- I. Multi-Province Tax (4): ON(HST 13%), QC(GST+QST 14.975%), AB(GST 5%), BC(GST+PST 12%)
- J. Shipping Cost (3): standard calculation, free shipping threshold, bulk/heavy surcharge

**Key constants**: `BUYER1_EMAIL = 'yuniorrodriguezo460@gmail.com'`, `SELLER1_EMAIL = 'seller1@test.origna.ca'`, `PRODUCT_HIGH_STOCK = 'product_001'`
**Rate limit note**: J.1 has 65s delay because `create_checkout_session` has 5 req/min limit and I.* tests exhaust it.

### fullstack-e2e.spec.ts — 37 tests
Core marketplace flow: auth, products, cart, checkout, orders

### payment-workflow-e2e.spec.ts — 62 tests  
Mega payment workflow: 10 suites (A-J) covering edge cases, multi-seller, stock, auth, refunds

### regression-e2e.spec.ts — 42 tests
10 regression suites (A-J): order statuses, timeline, confirm receipt, checkout data, cart ops, item status, payment status, schema consistency, rating formula, multi-seller
**Fixes applied (Feb 2026):**
1. `patchDoc()` now uses `updateMask.fieldPaths` to avoid replacing entire Firestore documents
2. H3: Fixed contradictory assertion (`createdAt` both defined AND undefined) → now checks `createdAt` vs `dateCreated`
3. G1: Restores `order_test_004.paymentStatus` to `captured` before asserting (C3 had modified it to `authorized`)

### logic-failures-e2e.spec.ts — 29 tests
7 logic attack suites (A-G):
- A. Financial Integrity (5): price tampering, subtotal mismatch, platform fee, zero/negative qty
- B. State Machine Violations (5): skip transitions, terminal revival, double ship, uncaptured refund
- C. Cron Job Logic (4): auto-confirm 7d, expired auth 7d, archive 30d, rate limit cleanup
- D. Suspension Cascade (4): deactivated products, blocked add, self-suspend, ghost seller
- E. Stock Integrity (4): cancel restores, double-cancel idempotent, delete blocked, concurrent race
- F. Permission Boundary (3): buyer self-refund, non-onboarded seller, fake rating
- G. Cross-Boundary (4): self-purchase, wrong seller, MFA-gated, GDPR active orders

### flutter-web-e2e.spec.ts — 14 tests
Flutter web app smoke tests: page loads, navigation, responsive layout

### shipping-lifecycle-e2e.spec.ts — 48 tests
Full shipping lifecycle: label generation, tracking, delivery confirmation, multi-province

### admin-email-test.spec.ts — 3 tests
Real email delivery verification (requires real Mailjet credentials)

---

### Seed Scripts
| Script | Data | Notes |
|--------|------|-------|
| `mega-seed.ts` | 76 users, 30 products, ~20 carts, 8 orders | **Use this for E2E** |
| `seed-emulator.ts` | 25 users, 16 products, 3 carts | Legacy — NOT recommended |
| `seed-orders.py` | 8 orders at various statuses | Legacy — now built into mega-seed.ts |
| `write_cycle.py` | Cycles order through all statuses (10s each) | — |

### mega-seed.ts — CRITICAL for E2E
**MUST run before any E2E test**: `cd e2e && npx ts-node mega-seed.ts`

Seeds:
- **76 users** in Auth Emulator + Firestore /users collection (buyers, sellers, admins)
- **30 products** in Firestore /products (various categories, prices, stock levels)
- **Cart items** for buyer accounts
- **8 orders** (`order_test_001` to `order_test_008`):
  - 001: pending/pending
  - 002: confirmed/captured
  - 003: processing/captured
  - 004: shipped/captured (with trackingNumber + carrier)
  - 005: in_transit/captured (with trackingNumber + carrier)
  - 006: delivered/captured
  - 007: cancelled/refunded
  - 008: multi-seller (2 items from different sellers, sellerAddress array)

Order fields: `orderStatus`, `paymentStatus`, `paymentProvider: 'stripe'`, `subtotalCents/shippingCostCents/taxAmountCents/totalAmountCents`, `stripePaymentIntentId` (pi_test_* prefix), `items` with `imageUrls` (picsum.photos), `shippingAddress`, `createdAt`

Key user: `yuniorrodriguezo460@gmail.com` — used as buyer by regression + payment tests

### Stock Warning
- `product_002` (Leather Bag) can run out from repeated tests
- Prefer `product_001` (Scarf, 25 stock) or `product_007` (Jerky, 60 stock)

---

### Firestore REST API Quick Reference (Emulator)

```bash
# Read a document
curl "http://localhost:8080/v1/projects/orignagta/databases/(default)/documents/COLLECTION/DOC_ID" \

# PATCH a document (MUST use updateMask to avoid replacing entire doc!)
curl -X PATCH \
  "http://localhost:8080/v1/projects/orignagta/databases/(default)/documents/COLLECTION/DOC_ID?updateMask.fieldPaths=field1&updateMask.fieldPaths=field2" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"field1":{"stringValue":"value"}}}'

# List all documents in a collection
curl "http://localhost:8080/v1/projects/orignagta/databases/(default)/documents/COLLECTION" \
```

**⚠️ CRITICAL**: Firestore REST PATCH without `updateMask` replaces the ENTIRE document. Always include `updateMask.fieldPaths` for partial updates.

### Test Ordering Gotchas
- Tests within a file run sequentially and can modify shared Firestore data
- If test C modifies a document, test G must restore it before asserting
- Rate limiter now has 100x multiplier in emulator mode (`functions/services/rate_limiter.py`) — but still not infinite
- `create_checkout_session` base limit: 5 req/min × 100 = 500 req/min in emulator
- **Firestore REST PATCH without `updateMask`** replaces the ENTIRE document — `patchDoc()` in api-helpers.ts handles this correctly

### E2E Startup Checklist
```bash
# 1. Start emulators
firebase emulators:start --import=./emulator-data

# 2. Seed data (REQUIRED — Auth Emulator starts with 0 users!)
cd e2e && npx ts-node mega-seed.ts

# 3. (Optional) Start Stripe webhook forwarding for payment tests
stripe listen --forward-to localhost:5001/orignagta/us-central1/stripeWebhook

# 4. Run tests
npx playwright test regression-e2e.spec.ts  # or any spec file
```

### Emulator Detection in Backend
`functions/services/rate_limiter.py` checks `os.environ.get('FIRESTORE_EMULATOR_HOST')` to detect emulator mode. When detected, applies `_EMULATOR_RATE_MULTIPLIER = 100` to `max_requests`. This prevents rate limit throttling during parallel E2E test execution.
