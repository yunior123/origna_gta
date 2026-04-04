# STATE.md — Current Verified State

## Snapshot
- Date: `2026-04-04` (full runbook execution — third pass + Phase 4B audits)
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
| E2E API (17 files) | 300+ pass | 0 failures |
| Load: auth storm | 137/137 | 100%, avg 2.24s, p95 2.59s |
| Load: checkout stress | 2650/2650 | 0% error rate, p95 153ms |
| Backend health | 200 OK | api.orignagta.ca/health |

**Total: 5500+ tests passing across Flutter, Rust, E2E, and load tests**

## Stripe Audit Results (2026-04-04)

| Check | Status | Notes |
|-------|--------|-------|
| Server creates session | PASS | `checkout.rs:271` |
| Prices from server | PASS | Server re-fetches products, validates with $2 tolerance |
| metadata.order_id | PASS | `checkout.rs:653-655` |
| success_url = pending | PASS | Points to `/payment-success` showing "Order Placed" |
| Idempotency key | PASS | Client + server + Stripe all use it |
| No double-convert `* 100` | PASS | All Stripe amounts already integer cents |
| Integer cents throughout | PASS | Rust `i64`, Dart `int` |
| Webhook signature (rawBody) | PASS | `webhooks.rs:70-91` |
| event.id dedup | PASS | Query-then-create with dual guards |
| webhook_events storage | PASS | Stored with 7-day cleanup |
| Stock: checkout-time only | PASS | Atomic PostgreSQL transaction, not webhook/redirect |
| Cart: webhook only | PASS | Cart cleared in webhook, not redirect |
| Manual capture mode | PASS | Pre-auth prevents premature charges |
| Capture idempotency | PASS | Order-based key prevents double-capture |
| Order state guards | PASS | WHERE clause prevents state regression |
| Webhook replay protection | PASS | 300-second timestamp window |

**Verdict: SAFE — No critical or high-severity issues found**

## Auth Audit Results (2026-04-04)

| Check | Status | Notes |
|-------|--------|-------|
| RS256 algorithm | PASS | RS256 primary, HS256 dev-only fallback |
| Private key never exposed | PASS | File permissions 0o600 |
| Token claims | PASS | sub, iat, exp, roles, typ, email_verified, mfa_required |
| Short-lived access tokens | PASS | 15-minute default TTL |
| Refresh token rotation | PASS | Advisory lock prevents race |
| Token revocation on logout | PASS | SHA-256 hash stored in DB |
| Argon2id (64MB, 3 iter) | PASS | Stronger than bcrypt |
| Password strength validation | MEDIUM | Only 8-char minimum; no complexity/breach checks |
| Password reset security | PASS | Short-lived JWT, hashed storage, constant-time comparison |
| Protected endpoints through middleware | PASS | `auth_extractor` on entire auth router |
| JWT from Bearer header | PASS | 401 on invalid |
| Role-based access | PASS | `require_admin()` checks authenticated + role |
| User ID from JWT only | PASS | `AuthContext.user_id` from JWT `sub` only |
| Login rate limits | PASS | 5 req/min per IP + account lockout after 5 failures |
| Register rate limits | PASS | 3 req/min per IP |
| Prod test mode disabled | PASS | Startup panic if `OB_TEST_MODE=1` in prod |
| TOTP secret generation | PASS | 20 bytes from `OsRng` (160 bits) |
| TOTP verification window | PASS | Skew=1 (±30s); replay prevention |
| Recovery codes | PASS | 8 codes, 128-bit entropy, Argon2id hashed |
| TOTP rate limiting | PASS | 5 attempts/15min, auto-lock |

**Result: 19 PASS, 1 MEDIUM (password strength only checks length)**

## Magic String Audit Results (2026-04-04)

Full audit completed: 56 unique magic string sites identified across Rust and Dart.

### Fixed (Critical)
- `ob-auth/routes.rs`: 22x `"users"` → `c::USERS`
- `orignabase_profile_viewmodel.dart`: `'DELETE_MY_ACCOUNT'` → `ConfirmationValues.deleteMyAccount`
- `orignabase_checkout_provider.dart`: 2x `'expectedPriceCents'` → `Fields.expectedPriceCents`
- `schema_constants.dart`: Added `Fields.expectedPriceCents`

### Remaining (Medium/Low — documented, not blocking)
- `ob-handlers/cron/mod.rs`: Status values already use `OrderStatus::X.as_str()` pattern
- `ob-handlers/native_triggers.rs`: 10x collection names, field names in SQL
- `ob-handlers/returns.rs`, `refunds.rs`, `shipping.rs`: Field names in SQL queries
- `ob-handlers/subscriptions.rs`, `connect.rs`: `"userId"` validation messages (API contract)
- Dart: Geoapify keys, GA4 analytics keys, CSV column names (external formats)

## Dead Code Audit Results (2026-04-04)

### Deleted (0 references)
- `notification_viewmodel.dart` — dead ViewModel
- `product_address_helpers.dart` — dead helper file

### Kept (have active references)
- `conf_services.dart` — imported by media_url_resolver + 3 test files
- `turnstile_service.dart` — imported by 2 test files
- `orignabase_digital_service.dart` — imported by 1 test file

### Incomplete Integrations (Documented)
- **Digital downloads**: Backend exists, no Flutter UI
- **PDF invoices**: Backend exists (680 lines, bilingual EN/FR), no Flutter trigger
- **Seller analytics**: Screen exists, no dedicated backend aggregation endpoint

## Load Tests — 2026-04-04

| Test | VUs | Duration | Result | Notes |
|------|-----|----------|--------|-------|
| Auth storm | 10 | 30s | 137/137 (100%) | avg 2.24s, p95 2.59s |
| Checkout stress | 50 | 60s | 2650/2650 (100%) | 0% error rate, p95 153ms |

## Coverage Notes — 2026-04-04

### Rust Payment Modules (well-covered)
- `capture.rs`: 20 tests | `checkout.rs`: 58 tests | `connect.rs`: 17 tests
- `providers.rs`: 35 tests | `subscriptions.rs`: 74 tests | `webhooks.rs`: 139 tests
- **Total: 343 payment tests**

### Flutter Coverage Gaps
- `orignabase_checkout_provider.dart`: 0 dedicated test files (critical checkout integration)
- All other critical modules have 2+ test files

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

## Commits This Session
1. `8c3cc37dd` — magic string remediation, price calc bug, webhook idempotency, test fixes
2. `630eef518` — dead code cleanup, stale comment fixes
3. `f16d2b63f` — STATE.md update with load test results and coverage analysis
4. `487dc9e17` — remove stale 'Phase 2' reference from FieldValue TODO comment
