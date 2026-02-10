---
name: e2e-test-suites
description: Catalog of all 267+ E2E Playwright tests and 288 backend pytest tests with file locations. Use when running tests, adding tests, or debugging test failures.
---

# E2E Test Suite Reference

## Test Count: 267+ E2E (8 files) + 288 Backend

### Test Results Summary (Last Run: Feb 2026)

| File | Tests | Passing | Status |
|------|-------|---------|--------|
| comprehensive-flows-e2e.spec.ts | 32 | 32/32 | ✅ All pass |
| regression-e2e.spec.ts | 42 | 42/42 | ✅ All pass (E1 flaky, passes on retry) |
| flutter-web-e2e.spec.ts | 14 | 14/14 | ✅ All pass |
| fullstack-e2e.spec.ts | 37 | 34/37 | 🔶 3 fail (Stripe Checkout UI headless) |
| logic-failures-e2e.spec.ts | 29 | 13/29 | 🔴 16 fail (Unauthenticated — pre-existing) |
| payment-workflow-e2e.spec.ts | 62 | 9/62 | 🔴 53 fail (Unauthenticated — pre-existing) |
| shipping-lifecycle-e2e.spec.ts | 48 | 2/48 | 🔴 46 fail (Unauthenticated — pre-existing) |
| admin-email-test.spec.ts | 3 | 0/3 | 🔴 Stripe UI + real email — pre-existing |

### Known Pre-existing Issues
2. **Stripe Checkout UI in headless** — `VerificationModal` overlay blocks the Pay button in Playwright headless Chromium. Affects fullstack-e2e test 6.3 and admin-email-test.

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
| `mega-seed.ts` | 75 users, 30 products, ~20 carts | For large-scale testing |
| `seed-emulator.ts` | 25 users, 16 products, 3 carts | Default for dev/E2E |
| `seed-orders.py` | 8 orders at various statuses | Requires `seed-uid-map.json` |
| `write_cycle.py` | Cycles order through all statuses (10s each) | — |

### seed-uid-map.json — CRITICAL
- Maps email → Firebase Auth UID for `seed-orders.py`
- **MUST be regenerated** when switching between `mega-seed.ts` and `seed-emulator.ts`
- Current map: 25 entries matching `seed-emulator.ts` users
- Key entries: `yr62813@gmail.com → ZBARTlsk3arOYgDHxc9HfKweoJv7`, `yuniorrodriguezo460@gmail.com → D1KBLkJRn6zLx1xWVONIhvag31HO`

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
- Rate limits accumulate across tests — add delays between suites that call rate-limited endpoints
- `create_checkout_session` has 5 req/min rate limit
