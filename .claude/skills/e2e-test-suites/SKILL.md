---
name: e2e-test-suites
description: Catalog of all 161+ E2E Playwright tests and 288 backend pytest tests with file locations. Use when running tests, adding tests, or debugging test failures.
---

# E2E Test Suite Reference

## Test Count: 161+ E2E + 288 Backend

### fullstack-e2e.spec.ts — 37 tests
Core marketplace flow: auth, products, cart, checkout, orders

### payment-workflow-e2e.spec.ts — 54 tests  
Mega payment workflow: 10 suites (A-J) covering edge cases, multi-seller, stock, auth, refunds

### regression-e2e.spec.ts — 38 tests
10 regression suites (A-J): order statuses, timeline, confirm receipt, checkout data, cart ops, item status, payment status, schema consistency, rating formula, multi-seller

### logic-failures-e2e.spec.ts — 29 tests
7 logic attack suites (A-G):
- A. Financial Integrity (5): price tampering, subtotal mismatch, platform fee, zero/negative qty
- B. State Machine Violations (5): skip transitions, terminal revival, double ship, uncaptured refund
- C. Cron Job Logic (4): auto-confirm 7d, expired auth 7d, archive 30d, rate limit cleanup
- D. Suspension Cascade (4): deactivated products, blocked add, self-suspend, ghost seller
- E. Stock Integrity (4): cancel restores, double-cancel idempotent, delete blocked, concurrent race
- F. Permission Boundary (3): buyer self-refund, non-onboarded seller, fake rating
- G. Cross-Boundary (4): self-purchase, wrong seller, MFA-gated, GDPR active orders

### admin-email-test.spec.ts — 3 tests
Real email delivery verification

### Seed Scripts
| Script | Data |
|--------|------|
| `mega-seed.ts` | 75 users, 30 products, ~20 carts |
| `seed-emulator.ts` | 25 users, 16 products, 3 carts |
| `seed-orders.py` | 8 orders at various statuses |
| `write_cycle.py` | Cycles order through all statuses (10s each) |

### Stock Warning
- `product_002` (Leather Bag) can run out from repeated tests
- Prefer `product_001` (Scarf, 25 stock) or `product_007` (Jerky, 60 stock)
