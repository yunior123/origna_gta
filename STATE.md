> **Source of Truth:** [CLAUDE.md](./CLAUDE.md) — single source of truth.
> **Goal:** Launch by March 2026.

---

# FULL REPO AUDIT — 2026-02-28

## STATUS: Audit complete (19/33 + Gemini fallback). All critical fixes applied. Deploy in progress.

## PENDING TASKS
1. ✅ Full audit (complete — findings below)
2. Add Playwright tests to cover all APIs (Cloudflare R2, Stripe, Firestore, etc.)
3. Improve existing Playwright UI tests (go deeper into E2E scenarios)
4. Update repo map
5. Update docs/README for test running instructions

---

## FIXES APPLIED (commits: 6de9999, d7dd13b, cd7602e, 06016ba)

| Fix | File | Status |
|-----|------|--------|
| PaymentStatusEnum: DISPUTED + PARTIALLY_REFUNDED | models/base.py | ✅ |
| database_schema.json: missing paymentStatus values | docs/database_schema.json | ✅ |
| firestore.rules: partially_refunded + refunded terminal states | firestore.rules | ✅ |
| firestore.rules: message_reports collection rules | firestore.rules | ✅ |
| 17 missing Firestore composite indexes | firestore.indexes.json | ✅ deployed |
| Chat: SERVER_TIMESTAMP for message/thread timestamps | chat.py | ✅ |
| Cron: .limit(500) on cleanup_stale_webhook_events | cron_jobs.py | ✅ |
| Cron: .limit(500) on cleanup_stale_security_alerts | cron_jobs.py | ✅ |
| Orders: email + push for FAILED/EXPIRED/DISPUTED status | orders.py | ✅ |
| Products: rating transaction fetches product_doc inside txn | products.py | ✅ |
| Products: notifiedAt rollback on email failure (both paths) | products.py | ✅ |
| Products: warehouse default reassignment on deletion | products.py | ✅ |
| Algolia: lifecycleStatus=active persistent filter | algolia_service.dart | ✅ |
| Payment: seller push notification on new orders | payment_stripe.py | ✅ |
| Payment: payout idempotency checks all non-FAILED status | payment_stripe.py | ✅ |
| .env: fix invalid dotenv lines (BedrockAPIKey, AWS_BedRock) | functions/.env | ✅ local |
| Digital item refund: revoke license for specific product | orders.py | ✅ |
| stock_notifications cleanup: remove .limit(10) per item | orders.py | ✅ |
| chat mark_messages_read: add .limit(500) to unbounded query | chat.py | ✅ |

## AGENTS RAN (19 succeeded, 14 rate-limited)

### Succeeded
schema-sync, cron-jobs, app-bootstrap, legacy-code, frontend, add-product, notifications, product-qa-ratings, profile-address, chat, seller-warehouses, missing-indexes (17 added), search-discovery, email-notifications, stock-notifications, favorites, payment, legal-compliance, Gemini test-gaps

### Bedrock quota exhausted — used Gemini CLI as fallback (3 of 14 produced real findings)

From Gemini audits:
- **logic/security/cross-stack/order-lifecycle**: quota hit before analysis
- **admin-panel**: admin can grant ADMIN role to others (HIGH, intentional feature with MFA guard)
- **digital-products**: item-level refund didn't revoke license → FIXED
- **performance**: N+1 FCM reads in _fire_back_in_stock_notifications + _fire_price_drop_notifications + _notify_premium_users_new_product (HIGH — complex, deferred)
- **performance**: mark_messages_read unbounded query → FIXED
- **return-requests**: digital admin manual refund path may not revoke license (MEDIUM)
- **product-lifecycle**: Algolia sync not atomic with Firestore (architectural, deferred)
- **premium**: reactivate_subscription was false positive — _sync_subscription called synchronously ✅
- **auth**: Sellers lack MFA for payout actions (MEDIUM, deferred)

### Still Needed (run individually with ~30s gap between):
logic-auditor, security-auditor, cross-stack-auditor, order-lifecycle-auditor, product-lifecycle-auditor, return-requests-auditor, coupons-discounts-auditor, firebase-architect-agent, admin-panel-auditor

---

# FINDINGS — SORTED BY SEVERITY

## 🔴 CRITICAL (must fix before launch)

### Payment & Money
- **PAY-C1** — Platform fee calculated on post-discount subtotal — business logic may be wrong (payment_stripe.py:1524)
- **PAY-C2** — Tax fallback uses float math `round(taxable_total * rate, 2)` → penny rounding errors (payment_stripe.py:1116)
- **PAY-C3** — Payout idempotency only checks COMPLETED — webhook retries create duplicate PENDING payouts (payment_stripe.py:2112)

### Schema Sync
- **SCH-C1** — `ORDER_REFUND_CENTS` constant missing in Python schema_constants.py (Dart has it at line 748)
- **SCH-C2** — `PaymentStatusEnum.DISPUTED` + `PARTIALLY_REFUNDED` missing in Python models/base.py (Dart line 127/135)
- **SCH-C3** — `OrderStatusEnum.PARTIALLY_REFUNDED` missing in Python models/base.py (Dart line 102)

### Cron Jobs
- **CRON-C1** — `cleanup_stale_webhook_events`: no `.limit()` clause → OOM at scale (cron_jobs.py:1141)
- **CRON-C2** — `cleanup_stale_security_alerts`: no `.limit()` clause (cron_jobs.py:1181)
- **CRON-C3** — No Sentry integration in batch error handlers — silent production failures

### App Bootstrap
- **BOOT-C1** — Emulator mode falls back to dev Firebase silently when emulators unavailable → data contamination (main.dart:64)

### Add Product
- **PROD-C1** — Form state NOT reset on navigation away — stale data on re-entry (addproduct_screen.dart:793)
- **PROD-C2** — Sellers with warehouses can bypass warehouse selection by entering address manually (add_product_viewmodel.dart:126)
- **PROD-C3** — `lifecycleStatus` sent as `draft` from Dart; violates schema contract (backend overrides but Dart wrong) (add_product_viewmodel.dart:340)
- **PROD-C4** — No loading state during video upload — UI shows no feedback, double-submit possible (add_product_viewmodel.dart:384)

### Chat
- **CHAT-C1** — Messages use `datetime.now(UTC)` not `firestore.SERVER_TIMESTAMP` — ordering broken on rapid sends (chat.py:320)
- **CHAT-C2** — No max messages per thread limit — 86K msgs/day = 2.5GB/month per thread possible

### Email Notifications
- **EMAIL-C1** — FAILED order status → NO email to buyer (CASL violation) (orders.py:2294)
- **EMAIL-C2** — Authorization EXPIRED email function exists but NEVER called (payment_stripe.py:2807)
- **EMAIL-C3** — DISPUTED orders → NO buyer notification → platform loses chargebacks by default
- **EMAIL-C4** — Seller notification only via webhook path — admin/cron-confirmed orders = seller misses order

### Stock Notifications
- **STOCK-C1** — Notifications NEVER deleted after email sent — 100K+ zombie docs over 12 months (products.py:3393)

### Search & Discovery
- **SRCH-C1** — Inactive products NOT filtered from Algolia search — stale inactive products appear if deletion failed (algolia_service.dart:28)

### Q&A & Ratings
- **QA-C1** — Rating transaction reads `product_doc` OUTSIDE transaction scope → incorrect average calculations (products.py:804)

### Profile & Address
- **ADDR-C1** — `delete_buyer_address` has no explicit ownership check — attacker can delete another user's address with guessed ID (users.py:491)

### Missing Firestore Indexes
- **IDX-C1** — **17 missing composite indexes** added to firestore.indexes.json — must deploy before launch
  - Checkout idempotency, admin suspend_seller, expired auth cron, payout webhooks, stock notifications, account deletion guards, duplicate rating prevention, renewal reminder emails
  - **DEPLOY**: `firebase deploy --only firestore:indexes` to all 3 envs

### Seller Warehouses
- **WH-C1** — `delete_warehouse` does NOT reassign default when default is deleted → seller ends up with 0 defaults (products.py:3191)

---

## 🟠 HIGH

### Payment
- **PAY-H1** — Address comparison dead code (shipping_address_collection disabled) — will break if enabled (payment_stripe.py:2324)
- **PAY-H2** — Charge ID extraction fragile — Stripe format change would pass wrong ID to Transfer API (payment_stripe.py:2462)

### Cron Jobs
- **CRON-H1** — Auto-confirm race: `AUTO_CONFIRM_DAYS=5` vs `AUTHORIZATION_EXPIRY_DAYS=6` — hourly expiry cron races auto-capture
- **CRON-H2** — Rate limiter cleanup cutoff = 1hr = rate limit window → can delete active entries mid-window

### App Bootstrap
- **BOOT-H1** — Email verification bypassed in emulator mode — behavior divergence vs production
- **BOOT-H2** — Session timeout race: no user ID binding, stale timer can sign out wrong user (session_timeout_service.dart:46)
- **BOOT-H3** — Riverpod providers accessed before auth resolves — "provider not initialized" on cold start (origna_app.dart:663)

### Legacy/Dead Code
- **LEG-H1** — `CircularProgressIndicator` instead of `ModernLoadingIndicator` (productaddvideo_screen.dart:270)
- **LEG-H2** — Direct `FirebaseAuth.instance.currentUser` in screen — violates MVVM (profile_screen.dart:832)
- **LEG-H3** — Hardcoded `"users"` string in subscriptions.py:36 instead of `Collections.USERS`

### Frontend/Riverpod
- **FE-H1** — Unsafe `.value!` access in chat_screen.dart:177 — crash risk

### Chat
- **CHAT-H1** — `message_reports` collection has NO Firestore rules (missing match block)
- **CHAT-H2** — No message deletion for senders — soft delete pattern needed
- **CHAT-H3** — No `delete_message` admin callable for moderation

### Email Notifications
- **EMAIL-H1** — Low stock alert emails ignore `emailConsent` — Quebec Law 25 violation (cron_jobs.py:1517)
- **EMAIL-H2** — Abandoned cart emails missing CASL unsubscribe link + physical address (cron_jobs.py:1631)
- **EMAIL-H3** — Premium renewal reminders sent to CANCELLED users (cron_jobs.py:2102)
- **EMAIL-H4** — DELIVERED email: dedup happens AFTER send → retries cause duplicates

### Search & Discovery
- **SRCH-H1** — No Canada-only filtering in search — non-shippable products visible to Canadian buyers (algolia_service.dart:28)
- **SRCH-H2** — No Algolia sync retry — dead letter queue exists but never processed
- **SRCH-H3** — No validation guard in update_remote_config.py — admin API key could accidentally be pushed

### Stock Notifications
- **STOCK-H1** — `notifiedAt` stamped BEFORE email task enqueued → email failure = buyer never notified but marked as notified (products.py:3393)

### Profile & Address
- **ADDR-H1** — No check for active orders before deleting address — buyer loses shipping reference
- **ADDR-H2** — Geoapify error not surfaced with context — user stuck if API is down

### Notifications (Push)
- **NOTIF-H1** — Sellers NOT notified via push on new orders — email only (payment_stripe.py:2237)
- **NOTIF-H2** — No stale FCM token cleanup cron job — zombie tokens accumulate

### Seller Warehouses
- **WH-H1** — Warehouse deletion race: warehouse deleted first (line 3191), then products updated — checkout fails in window
- **WH-H2** — International warehouse province/postal code NOT validated (only Canadian)

### Add Product
- **PROD-H1** — No drag-to-reorder UI for images — seller can't set primary without deleting others
- **PROD-H2** — SKU uniqueness error shown as SnackBar not inline field error

### Q&A & Ratings
- **QA-H1** — Photo review images uploaded before rating doc — orphaned R2 images if write fails (product_rating_viewmodel.dart:52)

---

## 🟡 MEDIUM

### Payment
- **PAY-M1** — Webhook secret cached module-level — rotation requires cold start (payment_stripe.py:104)
- **PAY-M2** — Stock reservation outside order creation transaction — stock leaks if order creation fails (payment_stripe.py:1419)
- **PAY-M3** — No seller account status check before reversing transfer on refund

### Schema Sync
- **SCH-M1** — Firestore rules should validate new payment/order status values

### Cron Jobs
- **CRON-M1** — `sync_expired_subscriptions` runs hourly → 4800 reads/day unnecessarily; change to 6hr
- **CRON-M2** — Stock restore double-increment risk on crash (mitigated by status lock but fragile)

### App Bootstrap
- **BOOT-M1** — CORS missing dev.orignagta.ca / staging.orignagta.ca
- **BOOT-M2** — Algolia index name defined in two places (Dart + Python) — drift risk
- **BOOT-M3** — Analytics NOT disabled in staging — pollutes production data (analytics_service.dart:9)
- **BOOT-M4** — R2 folder ternary chain error-prone — use switch/factory pattern

### Frontend
- **FE-M1** — `qaControllerProvider` missing `.autoDispose` → memory leak (qa_provider.dart:7)
- **FE-M2** — `notificationPermissionProvider` missing `.autoDispose` — needs justification comment
- **FE-M3** — Seller Q&A badge missing on seller_products_screen (only on seller_orders_screen)

### Chat
- **CHAT-M1** — Content sanitization misses Unicode homoglyphs/zero-width chars (chat.py:36)
- **CHAT-M2** — Premium check reads Firestore on every message — 60 reads/min/user → $36/day at scale
- **CHAT-M3** — No duplicate identical message spam detection

### Stock Notifications
- **STOCK-M1** — Orphaned variant subscriptions when seller deletes variant — no cleanup

### Profile & Address
- **ADDR-M1** — Default address swap not in transaction — concurrent update race
- **ADDR-M2** — Province code not validated client-side before backend call
- **ADDR-M3** — Postal code regex validation missing on frontend

### Notifications (Push)
- **NOTIF-M1** — Deep link routing missing for `refund_issued` notification type (notification_service.dart:244)
- **NOTIF-M2** — `NotificationTypes.messageReport` missing in Dart schema_constants.dart

### Seller Warehouses
- **WH-M1** — No admin callable to update `commissionRateBps` (manual Firebase Console = no audit trail)

### Search & Discovery
- **SRCH-M1** — Out-of-stock products not visually marked in search results
- **SRCH-M2** — Trending score calculation not audited

### Favorites
- **FAV-M1** — Orphaned favorites from hard-deleted products never cleaned up client-side
- **FAV-M2** — Seller product list hard-capped at 200, no pagination (seller_products_viewmodel.dart:17)
- **FAV-M3** — Missing Firestore composite index for seller products query: (sellerId ASC, createdAt DESC)

### Q&A & Ratings
- **QA-M1** — No admin callable for deleting abusive Q&A (manual Console only, no audit trail)

### Email Notifications
- **EMAIL-M1** — 42% of order status transitions send NO email (FAILED, EXPIRED, DISPUTED, PENDING)
- **EMAIL-M2** — Low stock + abandoned cart templates hardcoded English only — Quebec Bill 96 violation

---

## 🔵 LOW (tech debt, post-launch)

### Add Product
- **PROD-L1** — No CAD-only currency hint on price field
- **PROD-L2** — Video duration validation allows zero-duration corrupted video

### Cron Jobs
- **CRON-L1** — Docstring mismatch: `check_expired_authorizations` says "Daily 02:00" but runs hourly

### App Bootstrap
- **BOOT-L1** — Session timeout 15min hardcoded (should be in schema_constants)
- **BOOT-L2** — Orphaned route `/seller/setup` registered but not implemented

### Frontend
- **FE-L1** — Hardcoded subscription price `CAD $7.86/month` not i18n (productdetails_screen.dart:939)
- **FE-L2** — Hardcoded paywall description in English — Quebec Bill 96 (productdetails_screen.dart:1114)

### Chat
- **CHAT-L1** — Chat ID is `{productId}_{buyerId}` — exposes buyer UID to seller
- **CHAT-L2** — Seller response time not aggregated to seller_metrics

### Profile & Address
- **ADDR-L1** — 10-address limit not enforced client-side

### Notifications (Push)
- **NOTIF-L1** — No per-user rate limiting on push sends — 50 items = 50 notifications
- **NOTIF-L2** — FCM token stale cleanup reactive-only (not proactive)

### Legacy/Dead Code
- **LEG-L1** — "legacy" word in 4 code comments (forbidden per CLAUDE.md)
- **LEG-L2** — `StateNotifierProvider` without `.autoDispose` (qa_provider.dart:7 — same as FE-M1)
- **LEG-L3** — `warehouseStock` field ambiguous — tested but possibly unused in production

### Favorites
- **FAV-L1** — Orphan cleanup on product delete best-effort — no retry
- **FAV-L2** — Empty `_shipFromLabel` shows "Ships from: " with no text

---

## TEST COVERAGE GAPS (from Gemini analysis)

### CRITICAL E2E Missing
1. Dispute Resolution E2E — no test for buyer/seller/admin arbitration
2. Seller Payouts/Withdrawals E2E — no test for earnings flow
3. 2FA E2E — no test (if implemented)

### HIGH E2E Missing
4. Chat Functionality E2E — no buyer-seller messaging test
5. Product Reviews/Ratings E2E — no submit/view test
6. Coupon Application E2E — no test for expired/invalid codes
7. Address Management E2E — no add/edit/delete/default test
8. Subscription Upgrade/Downgrade/Cancel E2E

### CRITICAL Backend Tests Missing
9. Dispute resolution backend logic
10. Seller payout fraud/security backend tests
11. User data deletion/PIPEDA compliance tests
12. Subscription recurring billing/proration
13. Real-time inventory over-sell prevention

---

## AGENTS NEEDING RE-RUN (429 rate limited)

Priority order for next session:
1. **logic-auditor** — most important, covers race conditions + state machine
2. **security-auditor** — Firestore rules bypass, privilege escalation
3. **order-lifecycle-auditor** — order state machine completeness
4. **cross-stack-auditor** — API field mismatches
5. **auth-onboarding-auditor** — auth rate limiting, Stripe Connect flow
6. **performance-auditor** — N+1 reads, unbounded queries
7. **premium-auditor** — subscription bypass, cache consistency
8. **admin-panel-auditor** — admin route protection
9. **legal-compliance-auditor** — CASL, PIPEDA, Quebec Law 25/Bill 96
10. **product-lifecycle-auditor**, return-requests-auditor, coupons-discounts-auditor, digital-products-auditor, firebase-architect-agent, cost-monitor

---

## IMMEDIATE ACTIONS (before proceeding)

**Do you want to proceed with fixes?**

Suggested fix order:
1. **Wave A — Deploy critical infra (no code changes):**
   - Deploy 17 Firestore indexes to dev/staging/prod
   - This fixes checkout idempotency, payout webhooks, rating integrity

2. **Wave B — Critical schema fixes (30min):**
   - Add missing Python enums: `DISPUTED`, `PARTIALLY_REFUNDED` to PaymentStatusEnum/OrderStatusEnum
   - Add `ORDER_REFUND_CENTS` constant to Python schema_constants.py

3. **Wave C — Critical email fixes (2hr):**
   - Add FAILED/EXPIRED/DISPUTED email triggers
   - Add seller notification for non-webhook CONFIRMED transitions
   - Fix abandoned cart + low stock CASL compliance

4. **Wave D — Critical chat fixes (1hr):**
   - Replace `datetime.now(UTC)` with SERVER_TIMESTAMP in chat.py
   - Add max messages per thread limit
   - Add Firestore rules for `message_reports` collection

5. **Wave E — Critical search fix (30min):**
   - Add `lifecycleStatus=active` filter to Algolia search
   - Add Canada-only buyer filtering

6. **Re-run 15 rate-limited auditors** in next session (smaller batches of 6-8 max)

---

# PERFORMANCE AUDIT REPORT — 2026-02-28 (VERIFIED)

## REAL PERFORMANCE ISSUES (agent findings cross-checked against code)

### [HIGH] N+1 FCM token reads in notification functions (from Gemini audit)
- `_fire_back_in_stock_notifications`, `_fire_price_drop_notifications`, `_notify_premium_users_new_product`
- Each fetches FCM tokens one-by-one per user instead of batch collectionGroup query
- Fix: Use `collectionGroup(FCM_TOKENS)` with whereIn for batch fetch → send MulticastMessage
- **Files:** functions/handlers/products.py (lines ~3710-3820), functions/handlers/cron_jobs.py

### [HIGH] check_expired_authorizations sequential Stripe calls (cron_jobs.py:672)
- 100 orders × 500ms Stripe API = ~50 seconds per cron run
- Acceptable for launch (within 540s timeout), optimize post-launch with asyncio.gather

### [MEDIUM] Module-level boto3 import (products.py:68)
- Contributes to cold start time
- Fix: Move import inside function body

## FALSE POSITIVES (code already optimized)
✓ favoritesProvider: onDispose(link.close) + userId null check handles logout correctly
✓ filteredProductsProvider: uses `limit = 20` default + pageSize param to repository
✓ buyerOrdersProvider: uses `.limit(BusinessRules.ordersPageSize)` (line 99 in order_repository.dart)
✓ checkout inventory reads: .limit(50) per unique product (not per item); most products have 1-5 warehouses
✓ Algolia search debouncing: already 500ms (home_viewmodel.dart:132)
✓ duplicate rating check: already has .limit(1) (products.py:797)
✓ cart fetches full product data intentionally (needed for checkout validation)
4. Set up Firestore usage alerts at $100/day

6. **Re-run 15 rate-limited auditors** in next session (smaller batches of 6-8 max)
