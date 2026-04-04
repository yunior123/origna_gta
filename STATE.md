# STATE.md — Current Verified State

## Snapshot
- Date: `2026-04-04` (full runbook execution — third pass)
- Critical path: backend live -> Flutter live -> E2E/design

## Fixes Applied This Run (2026-04-04 Pass 3)

1. **`pg_store.rs` (ob-database)** — Fixed clippy `collapsible_if` warning at line 1410.
2. **`native_triggers.rs` (ob-handlers)** — Added missing `PaymentStatus` import (4 compile errors).
3. **`webhooks.rs` (ob-handlers)** — Fixed webhook idempotency: `try_store_webhook_event_atomic` now queries for existing events before insert. 2 tests now pass.
4. **`models.dart` (Flutter)** — Fixed `CartItemDetailModel.fromMap` price calculation: dollars were being divided by 100 again (25.5 → 0.255).
5. **`routes.rs` (ob-auth)** — Replaced 22 occurrences of `"users"` magic string with `c::USERS` from ob-core constants.
6. **`orignabase_profile_viewmodel.dart`** — Replaced `'DELETE_MY_ACCOUNT'` with `ConfirmationValues.deleteMyAccount`.
7. **`orignabase_checkout_provider.dart`** — Replaced 2x `'expectedPriceCents'` with `Fields.expectedPriceCents`.
8. **`schema_constants.dart`** — Added `Fields.expectedPriceCents` constant.

## Test Results — 2026-04-04 (Current)

| Suite | Result | Notes |
|-------|--------|-------|
| Flutter analyze | 0 issues | |
| Flutter unit tests | 3163/3163 | All pass |
| Flutter widget tests | 1125/1125 | All pass |
| Rust clippy | clean | All crates |
| ob-auth unit | 285/285 | |
| ob-handlers unit | 1782/1783 | 1 pre-existing cron test (infrastructure) |
| E2E API contract | 56/56 | |
| E2E cart API | 10/10 | |
| E2E checkout validation | 24/24 | |
| E2E address/data-integrity/admin-security | 28/28 | |
| E2E product/search/user | 38/38 | |
| E2E order/shipping/rate | 17/17 | |
| E2E security (4 files) | 72/72 | |
| E2E infra/notification/MFA | 33/33 | |
| E2E returns/cancellation/shipping | 15/15 | |
| E2E edit-product/multi-seller/security | 13/13 | |
| E2E email/warehouse | 21/21 | |
| E2E geoapify/infra/coverage | 41/41 | |
| Backend health | 200 OK | api.orignagta.ca/health |

**Total: 5500+ tests passing across Flutter, Rust, and E2E**

## Magic String Audit Results (2026-04-04)

Full audit completed: 56 unique magic string sites identified across Rust and Dart.

### Fixed (Critical)
- `ob-auth/routes.rs`: 22x `"users"` → `c::USERS`
- `orignabase_profile_viewmodel.dart`: `'DELETE_MY_ACCOUNT'` → `ConfirmationValues.deleteMyAccount`
- `orignabase_checkout_provider.dart`: 2x `'expectedPriceCents'` → `Fields.expectedPriceCents`
- `schema_constants.dart`: Added `Fields.expectedPriceCents`

### Remaining (Medium/Low — documented, not blocking)
- `ob-handlers/cron/mod.rs`: Status values in SQL queries already use `OrderStatus::X.as_str()` pattern
- `ob-handlers/native_triggers.rs`: 10x collection names, field names in SQL
- `ob-handlers/returns.rs`, `refunds.rs`, `shipping.rs`: Field names in SQL queries
- `ob-handlers/subscriptions.rs`, `connect.rs`: `"userId"` validation messages (API contract)
- Dart: Geoapify keys, GA4 analytics keys, CSV column names (external formats)

## Load Tests — 2026-04-04

| Test | VUs | Duration | Result | Notes |
|------|-----|----------|--------|-------|
| Auth storm | 10 | 30s | 137/137 (100%) | avg 2.24s, p95 2.59s |
| Checkout stress | 50 | 60s | 2650/2650 (100%) | 0% error rate, p95 153ms |

## Coverage Notes — 2026-04-04

### Rust Payment Modules (well-covered)
- `capture.rs`: 20 tests
- `checkout.rs`: 58 tests
- `connect.rs`: 17 tests
- `providers.rs`: 35 tests
- `subscriptions.rs`: 74 tests
- `webhooks.rs`: 139 tests
- **Total: 343 payment tests**

### Flutter Coverage Gaps
- `orignabase_checkout_provider.dart`: 0 dedicated test files (critical checkout integration)
- `.freezed.dart` files: generated, no direct tests needed
- All other critical modules have 2+ test files

### Dead Code Cleanup
- Deleted: `notification_viewmodel.dart` (0 references)
- Deleted: `product_address_helpers.dart` (0 references)
- Kept: `conf_services.dart`, `turnstile_service.dart`, `orignabase_digital_service.dart` (have active test references)

## Load Tests — 2026-04-04

| Test | VUs | Duration | Result | Notes |
|------|-----|----------|--------|-------|
| Auth storm | 10 | 30s | 137/137 (100%) | avg 2.24s, p95 2.59s |
| Checkout stress | 50 | 60s | 2650/2650 (100%) | 0% error rate, p95 153ms |

## Coverage Notes — 2026-04-04

### Rust Payment Modules (well-covered)
- `capture.rs`: 20 tests
- `checkout.rs`: 58 tests
- `connect.rs`: 17 tests
- `providers.rs`: 35 tests
- `subscriptions.rs`: 74 tests
- `webhooks.rs`: 139 tests
- **Total: 343 payment tests**

### Flutter Coverage Gaps
- `orignabase_checkout_provider.dart`: 0 dedicated test files (critical checkout integration)
- `.freezed.dart` files: generated, no direct tests needed
- All other critical modules have 2+ test files

### Dead Code Cleanup
- Deleted: `notification_viewmodel.dart` (0 references)
- Deleted: `product_address_helpers.dart` (0 references)
- Kept: `conf_services.dart`, `turnstile_service.dart`, `orignabase_digital_service.dart` (have active test references)

## Active Blockers
- **Cron test `test_auto_capture_confirmed_receipts_flow`**: Pre-existing infrastructure issue — shared PostgreSQL test DB doesn't isolate between tests.
- **CORS security**: Deploy needed (source code correct with explicit whitelisting)
- **Admin test**: Stale deploy — `/admin/users` omits `email` (source fixed)
- **E2E browser tests**: Phase 2-6 (visual/accessibility) require Chrome, timeout on 8GB RAM

## Known Infrastructure Issues
- 7 ob-handlers tests flaky under parallel execution (shared local PostgreSQL)
- E2E order lifecycle tests skip when Stripe webhook not available in test env
- Email trigger tests skip when order ID not available from previous test
- MFA user API tests skip when dev env returns 500 for login-history/known-devices

## Deep Audit Findings

### Magic Strings (2026-04-04)
- 56 unique sites across Rust/Dart
- Highest impact: `ob-auth/routes.rs` had 22 occurrences of `"users"` — now fixed
- ob-core already has `collections` and `fields` modules — all crates can use them
- Remaining work: replace field names in SQL format strings (lower priority, already using constants where practical)

### Flutter Price Calculation Bug (Fixed)
- `CartItemDetailModel.fromMap` was treating dollar values as cents when `priceCents` was absent
- Root cause: `(price as num).toDouble() / 100` — should be `(price as num).toDouble()` when no priceCents
- Affects all cart/order displays when backend sends `price` as dollars instead of `priceCents`
