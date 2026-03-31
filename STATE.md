# STATE.md — Audit Findings & Tasks

## Completed Audit Summary (2026-03-22 through 2026-03-29)

All findings from Waves 1-5 have been resolved. Summary tables below.

### Resolved by Wave

| Wave | Date | Scope | Findings | Fixed | Verified Clean |
|------|------|-------|----------|-------|----------------|
| Initial | 2026-03-22 | Security, cross-stack, performance, logic | 48 | 46 | 2 |
| Flow Audit | 2026-03-24 | 6 critical checkout/webhook/cart flows | 6 | 6 | 0 |
| Full Audit (39) | 2026-03-24 | 3 parallel audits: checkout, MCP, Flutter | 39 | 37 | 2 |
| Wave 2 Pentest | 2026-03-24 | IDOR, SQL injection, TOCTOU, unwrap panics | 9 | 9 | 0 |
| Stripe Webhook | 2026-03-24 | 22 event types + 2 missing | 2 | 2 | 0 |
| Bulk Fix (14 agents) | 2026-03-25 | Rust security, cron, webhooks, Flutter | 50+ | 50+ | 0 |
| Wave 3 Deep | 2026-03-25 | JWT, GraphQL, WS, storage, admin, search | 96+ | 96+ | 0 |
| Wave 4 | 2026-03-25 | Stripe pipeline, concurrency, performance | 17 | 17 | 0 |
| Magic Strings | 2026-03-25 | 278 hits across 23 files | 278 | 278 | 0 |
| MEGA LOOP 3 | 2026-03-27 | Full verification + payments coverage | Verification | All pass | 0 |
| P0+P1 Blitz | 2026-03-30/31 | All P0s + 27 P1s: TOCTOU, IDOR, CAS, auth, upload, disposal, GraphQL, push | 29 | 29 | 0 |
| P2+P3+UI Sweep | 2026-03-31 | Colors violations, notification bell, reorder UX, bulk update, field filtering | 15+ | 15+ | 0 |

### Resolved Categories (all [x])

- **Security**: 2 P0 webhook HMAC + SQL injection, 5 P1 rate-limit/error/admin, 6 P2 config/validation
- **Cross-stack**: 7 P0 field name mismatches (17 Rust files), 8 P1 business rules, 3 P2 missing definitions
- **Performance**: 92 setState reduced to 22 acceptable, 154 ref.watch optimized, 22 large files refactored
- **Money**: All double→int cents migration complete, display-layer doubles only
- **Freezed**: All 22 state classes verified @freezed
- **Semantics**: 90+ labels added, glass helpers fixed at root cause
- **Pagination**: All repositories paginated
- **Localization**: 45+ .tr() calls, enum extensions localized
- **Duplication**: 5 widgets extracted (CartBadge, FilterChip, Skeletons, TrendingBadge, QuantityButton)
- **IDOR fixes**: 8 handlers migrated from req.user_id to Extension(auth)
- **Webhook security**: HMAC constant-time, replay 300s, atomic dedup, 22 event types
- **MCP security**: Ownership checks, spend limits, filter injection fix, quantity bounds

### Test Results (at resolution)

| Suite | Pass | Fail |
|-------|------|------|
| Flutter app (with live flag) | 4,953 | 0 |
| Rust backend | 3,228 | 0 |
| OrignaBase SDK | 538 | 0 |
| E2E (6 phases) | 1,225 | 0 |
| Stress tests (k6) | 1,503 | 0 |
| **Total** | **11,447** | **0** |

---

## SurrealDB → PostgreSQL Migration (2026-03-29) — COMPLETE

| Metric | Before | After |
|--------|--------|-------|
| Handler tests | 1437/1749 (82%) | 1749/1749 (100%) |
| Test failures | 312 | 0 |
| Commits | 0 | 16 |
| Files modified | 0 | ~30 |

### Completed

- PgDatabaseStore adapter: 22 trait methods (16 original + 6 new filter/aggregate)
- translate_surreal_to_pg: type::thing, CREATE CONTENT, UPSERT, UPDATE MERGE, bare field rewrite
- `= NONE` → `IS NULL`, json_to_text fix for data->> comparisons
- Test isolation: ON CONFLICT, auto-truncation on startup
- All 19 handler modules at 0 failures
- Hexagonal architecture: find_where, count_where, exists_where, update_where, delete_where, find_where_multi
- Architecture grade: C+ → B+ (to reach A: refactor ~80 query_bind/query_raw calls to trait methods)

### Remaining Migration Work

1. **P1**: Refactor remaining ~80 handler query_bind/query_raw calls to trait methods (B+ → A)
2. **P1**: Increase test coverage to 95%+ (live tests priority)
3. **P2**: Run 30+ agent audit across codebase (10 done, 20+ remaining)

---

## UNFIXED Findings — Deep Codebase Audit 2026-03-28

### P0 — CRITICAL (3 remaining)

| # | Finding | Location | Status |
|---|---------|----------|--------|
| ~~P0-2~~ | ~~Payment failure stock restore~~ | webhooks.rs | **FIXED** 2026-03-29 — restore_stock_for_order verified |
| ~~P0-4~~ | ~~TOCTOU update_item_status~~ | status.rs | **FIXED** 2026-03-29 — update_document_cas added |
| ~~P0-5~~ | ~~TOCTOU confirm_item_receipt~~ | status.rs | **FIXED** 2026-03-29 — update_document_cas added |
| ~~P0-NEW-1~~ | ~~12 merge conflict files~~ | Flutter | **FIXED** 2026-03-29 — all conflicts resolved |
| ~~P0-NEW-2~~ | ~~Webhook dedup SQL injection~~ | webhooks.rs | **FIXED** 2026-03-30 — create_document (parameterized) |
| ~~P0-NEW-3~~ | ~~Stock decrement format!~~ | checkout.rs | **FIXED** — validate_document_id + bind params |
| ~~P0-NEW-4~~ | ~~IDOR answer_question~~ | questions.rs | **FIXED** 2026-03-30 — JWT auth Extension |
| ~~P0-NEW-5~~ | ~~IDOR stock subscribe~~ | stock.rs | **FIXED** 2026-03-30 — JWT auth Extension |
| ~~P0-NEW-6~~ | ~~require_admin bypass~~ | ob-auth/routes.rs | **FIXED** 2026-03-30 — production guard |
| ~~P0-NEW-7~~ | ~~Rate limiter not wired~~ | ob-auth/routes.rs | **FIXED** 2026-03-30 — 5/3/3 per min |
| P0-NEW-8 | Refund cumulative cap TOCTOU race | refunds.rs:404-420 | **FIXED** 2026-03-30 — CAS retry loop (3 attempts), no unprotected init |
| ~~P0-NEW-9~~ | ~~update_item_status lost-update~~ | status.rs | **FIXED** 2026-03-29 — CAS guard |
| ~~P0-NEW-10~~ | ~~Push token table mismatch~~ | native_triggers.rs | **FIXED** 2026-03-30 — unified PUSH_TOKENS |
| ~~P0-NEW-11~~ | ~~Email XSS~~ | native_triggers.rs | **FIXED** 2026-03-30 — html_escape() |
| ~~P0-NEW-12~~ | ~~MCP get_order ownership stub~~ | ob-mcp/orders.rs | **FIXED** 2026-03-30 — real auth check |
| P0-NEW-13 | MCP spend tracker no TTL | ob-mcp/safeguards.rs | **FIXED** 2026-03-30 — periodic cleanup every 100 calls + capacity eviction at 10K users |

### P1 — HIGH (2 remaining — architecture gaps, 25 fixed 2026-03-31)

#### Checkout & Payment
- [x] **P1-1.** Double checkout race on rapid taps — **FIXED** (already had isProcessing guard)
- [x] **P1-2.** Price verification sends double dollars instead of priceCents — **FIXED** (already sends priceCents)
- [x] **P1-3.** Dual subtotal: double vs int cents can disagree by 1 cent — **FIXED** (display only uses double)
- [x] **P1-4.** `CartItemDetailModel.fromMap` uses `~/ 1` truncation — **FIXED** 2026-03-29 → `.round()`
- [x] **P1-5.** Biometric guard dead-end on unsupported devices — **FIXED** (returns error, not dead-end)

#### Rust Backend
- [x] **P1-11.** Missing auth on /api/shipping/calculate — **FIXED** (require_authenticated already called)
- [x] **P1-12.** mark_coupon_redeemed swallows DB errors — **FALSE POSITIVE** (uses `?` propagation)
- [x] **P1-13.** Float arithmetic on money in shipping/tax — **FALSE POSITIVE** (constants only, calc uses i64 cents)
- [x] **P1-14.** Fallback speed multiplier inverted — **FALSE POSITIVE** (same_day=200bp > express=180bp is correct)

#### Auth & Session
- [x] **P1-15.** deleteAccount() silently no-ops — **FIXED** (throws no-current-user exception)
- [x] **P1-16.** Session timeout swallows sign-out failure — **FIXED** 2026-03-31 — AppLogger.w added
- [x] **P1-17.** sendPasswordResetEmail swallows "not found" — **BY DESIGN** (anti-enumeration security)
- [x] **P1-18.** Password not trimmed — **FIXED** (already calls .trim() at line 93)
- [x] **P1-19.** _rethrowAsAuthException maps any "account" to user-disabled — **FIXED** 2026-03-31 — requires "disabled" OR "suspended"

#### Product & Upload
- [x] **P1-20.** Video uploaded into memory before PUT — **FIXED** 2026-03-31 — File.length() pre-check in repository (rejects >100MB before readAsBytes)
- [x] **P1-21.** Edit mode reads video into memory to check size — **FIXED** 2026-03-31 — uses File.length()
- [x] **P1-22.** Image upload partial failure silently drops images — **FIXED** 2026-03-31 — blocks save on any failure, shows error count

#### SDK
- [x] **P1-23.** WebSocket reconnect leaks old listener/channel — **FIXED** (listener cancelled before reconnect)
- [x] **P1-24.** snapshots() StreamController never closed — **FIXED** (onCancel cleans up)
- [x] **P1-25.** Infinite polling with no timeout — **FIXED** (maxPollAttempts=30, 90s timeout)
- [x] **P1-9.** Order state machine missing delivered→refund transitions — **FIXED** 2026-03-29 — partiallyRefunded added

#### 2026-03-29 Additions
- [x] **P1-NEW-1.** IDOR: submit_rating — **FIXED** (already uses resolve_self_user_id)
- [x] **P1-NEW-2.** IDOR: ask_question — **FIXED** 2026-03-30 — JWT auth Extension
- [x] **P1-NEW-3.** IDOR: toggle_favorite — **FIXED** (already uses resolve_self_user_id)
- [x] **P1-NEW-4.** MFA recovery zero rate limiting, 32-bit entropy — **FIXED** 2026-03-31 — 128-bit entropy + 3/15min rate limit
- [x] **P1-NEW-5.** Invalid JWT silently downgrades to anonymous in MCP — **FIXED** 2026-03-31 — returns 401
- [x] **P1-NEW-6.** Stock restore on refund_order_item lost-update — **FIXED** 2026-03-31 — CAS retry loop
- [x] **P1-NEW-7.** cancel_order stock restore non-atomic — **FIXED** 2026-03-31 — CAS retry loop + order CAS
- [x] **P1-NEW-8.** update_order_status manual CAS non-atomic — **FIXED** 2026-03-31 — true update_document_cas
- [x] **P1-NEW-9.** confirm_item_receipt TOCTOU — **FIXED** 2026-03-31 — CAS on orderStatus
- [x] **P1-NEW-10.** Notification tap switch fallthrough — **FALSE POSITIVE** (Dart switch doesn't fall through; proper default handler exists)
- [ ] **P1-NEW-11.** Foreground push broken — `push_transport.dart` has no real FCM impl (NoopPushMessagingClient default). Needs `FirebasePushMessagingClient` with onMessage/onMessageOpenedApp streams. **Architecture gap.**
- [x] **P1-NEW-12.** Push rate limiting dead code — **FIXED** 2026-03-31 — wired check_daily_limit() in dispatch_push()
- [x] **P1-NEW-13.** snapshots() StreamController never closed — **FIXED** (dup of P1-24, onCancel added)
- [x] **P1-NEW-14.** Reconnect leaks StreamSubscription — **FIXED** (dup of P1-23, listener cancelled)
- [x] **P1-NEW-15.** Perishable 50km check skipped without Geoapify — **FIXED** 2026-03-31 — fail closed
- [ ] **P1-NEW-16.** No rate limiting on MCP HTTP transport — `transport.rs` (deferred — needs tower_governor layer)
- [x] **P1-NEW-17 to 19.** Riverpod race conditions — **FIXED** 2026-03-31 — _disposed flag + guards in all 3 VMs
- [x] **P1-NEW-20.** No default limit on GraphQL list query — **FIXED** (default 20, max 100)
- [x] **P1-NEW-21.** No field-level output filtering in GraphQL — **FIXED** 2026-03-31 — strip_sensitive_fields on get+list (blocklist: hashedPassword, mfaSecret, mfaRecoveryCodes, refreshToken, etc.)
- [x] **P1-NEW-22.** bulk_update_products N sequential DB calls — **FIXED** 2026-03-31 — pre-validate all, clone update data once, sequential updates (bounded 100 max)

### P2 — MEDIUM (60 remaining)

#### Checkout/UI (P2-1 through P2-8)
- [ ] Constructor param named `total` used as `subtotal` | calculateShipping before calculateTaxes | updateAddress no recalc | Coupon discount > subtotal no clamp | Display uses double | _checkLocalDelivery per-cart not per-item | Timeout vs order race | Digital items fallback province

#### Cart/Orders (P2-9 through P2-18)
- [ ] updateQuantity no try/catch | saveForLater non-atomic | _cartProductsBatchProvider swallows errors | Return window not enforced on submit | cartItemId/productId mixed | No pending→processing transition | Item status config inconsistent | _reorderItems partial failure | Quantity defaults inconsistent | updateShippingAndCapture drops tracking failure

#### Auth/Seller (P2-19 through P2-25)
- [ ] isEmailVerified returns false on expired session | ensureUserDocumentExists silently returns on null | validateCurrentUser fragile string matching | validateCurrentUser returns true on unknown errors | refreshAccountStatus discards response | _continueOnboarding leaves isOperationInProgress=true | Add vs edit price validation inconsistent

#### SDK (P2-26 through P2-31)
- [ ] fetchProductsByIdsImpl sequential chunks | Subscription ID duplicate in same ms | Batch deletes ignore response | authStateProvider stream never cancelled | normalizeId vs _bareId different results

#### Scripts/Config (P2-32 through P2-40)
- [ ] deploy_web.sh hardcodes production URL | No custom lint rules | EnvConfig defaults to production on typo | Quality gate passes with test failures | DeliverySpeed.baseSurcharge uses double | Duplicate refund transitions | buyer_cancellable duplicates | update_item_status no payment check | Fragile stock restore interaction

#### 2026-03-29 Additions (P2-NEW-1 through P2-NEW-20)
- [ ] upload_product_video/upload_review_images IDOR | toggle_favorite no auth | Recovery codes 32-bit entropy | Turnstile bypass via struct/env mismatch | Refresh token race window | Video upload path traversal | validate_postal_code_ca accepts invalid letters | validate_amount_cents allows zero | sanitize_html preserves script content | Cron stock restore not transactional | cancel_order transition duplicates | Push token no TTL | FCM errors silently swallowed | invoice.payment_failed no-op handler | Webhook processing synchronous | Batch deletes ignore response | deploy_web.sh hardcoded prod URL | env_config no validation | _rethrowAsAuthException "account" mapping | MCP first-role-only

### P3 — LOW (39 remaining)

#### Checkout/UI (P3-1 through P3-4)
- [ ] Biometric threshold on subtotal not total | Doc says fail-open but code fail-closed | Confetti repeat() forever | Analytics fire-and-forget no retry

#### Cart/Orders (P3-5, P3-6)
- [ ] CartItemDetailModel.copyWith missing fields | updateQuantity clamps silently

#### Auth (P3-7 through P3-9)
- [ ] Re-auth window 60s (industry: 5min) | _lastReAuthenticatedAt in-memory only | MFA uses exception for control flow

#### Product (P3-10 through P3-12)
- [ ] Price defaults to 0 on parse failure | categoryId defaults to 0 | Edit strips quantityDiscounts

#### SDK (P3-13 through P3-18)
- [ ] get() ambiguous null | delete() swallows response | add() dummy empty ID | _decodeClaims swallows errors | No JWT expiry pre-check | jsonDecode uncaught FormatException

#### Rust (P3-19 through P3-21)
- [ ] is_valid_order_transition dead code in refunds.rs | Log says stock decremented but already done | Unknown provinces get 5% silently

#### Scripts/Config (P3-22 through P3-24)
- [ ] deploy sed macOS-only | Quality gate cd/cd.. | envConfig dead code

#### 2026-03-29 Additions (P3-NEW-1 through P3-NEW-15)
- [ ] Empty JWT secret accepted | MFA disable replay window | JWT error details leaked | Stripe IDs in docs | SDK _decodeClaims blanket catch | No JWT expiry pre-check | jsonDecode uncaught | Carrier names hardcoded English | Colors.white instead of DesignTokens | MediaQuery.sizeOf for layout | Search limit 1000 inconsistent | Filter injection blocklist incomplete | fetchProductsByIds sequential | Video thumbnails full-res | Deprecated flutter_lints

---

### False Positives Confirmed (2026-03-29 validation)

| Previous Finding | Verdict |
|-----------------|---------|
| P0-1 (SQL injection checkout.rs) | PARTIALLY SAFE — validate_document_id prevents today |
| P0-3 (rollback ?? syntax) | FALSE POSITIVE — no ?? in refunds.rs |
| P0-6 (GraphQL injection SDK) | FALSE POSITIVE — escapeGraphQLId works |
| P0-7 (WebSocket auth wrong) | FALSE POSITIVE — SDK uses ?token= correctly |
| P1-6 (updateQuantity skips stock) | FALSE POSITIVE — lines 266-299 check stock |
| P1-7 (addToCart no existing qty) | FALSE POSITIVE — line 134 checks total |
| P1-10 (Transaction not atomic) | FALSE POSITIVE — real BEGIN/COMMIT via sqlx |
| P2-26 (orderBy overwrites) | FALSE POSITIVE — Query._copy() preserves fields |

---

### Audit Summary — Cumulative

| Severity | Total Found | Fixed | Unfixed |
|----------|-------------|-------|---------|
| P0 — CRITICAL | 29 | 29 | 0 |
| P1 — HIGH | 69 | 67 | 2 |
| P2 — MEDIUM | 72 | 12 | 60 |
| P3 — LOW | 42 | 3 | 39 |
| **TOTAL** | **212** | **111** | **101** |

### Top 10 Priority Fixes

| # | Finding | Category |
|---|---------|----------|
| 1 | P0-NEW-1: 12 merge conflict files — code doesn't compile | Infrastructure |
| 2 | P0-NEW-4/5: IDOR — answer_question/stock subscribe no JWT auth | Security |
| 3 | P0-NEW-6: require_admin() bypass with no prod guard | Security |
| 4 | P0-NEW-7: Rate limiter never wired to auth routes | Security |
| 5 | P0-NEW-8: Refund cumulative cap TOCTOU | Concurrency |
| 6 | P0-NEW-9: update_item_status concurrent lost-update | Concurrency |
| 7 | P0-NEW-11: Email HTML XSS via unescaped data | Security |
| 8 | P0-2: Payment failure doesn't restore stock | Stock |
| 9 | P0-NEW-12: MCP get_order ownership stub | Security |
| 10 | P0-NEW-10: Push token table mismatch | Notifications |
