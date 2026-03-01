> **Source of Truth:** [CLAUDE.md](./CLAUDE.md) — single source of truth.
> **Goal:** Launch by March 2026.

---

# FULL REPO AUDIT — 2026-02-28

## STATUS: Audit complete (19/33 + Gemini fallback + 6 new auditors 2026-03-01). All critical + most high fixes applied.

## PENDING TASKS
1. ✅ Full audit (complete — findings below)
2. Add Playwright tests to cover all APIs (Cloudflare R2, Stripe, Firestore, etc.)
3. Improve existing Playwright UI tests (go deeper into E2E scenarios)
4. Update repo map
5. Update docs/README for test running instructions

---

## FIXES APPLIED — SESSION 2026-03-01 (parallel agent wave)

| Fix | File | Status |
|-----|------|--------|
| SCH-C1: ORDER_REFUND_CENTS added to Python schema_constants.py | schema_constants.py | ✅ |
| SCH-C3: OrderStatusEnum.PARTIALLY_REFUNDED — already existed | models/base.py | ✅ verified |
| LEG-H3: hardcoded "users" → Collections.USERS | subscriptions.py | ✅ |
| PAY-C1: platform fee on pre-discount (actual_subtotal_cents) | payment_stripe.py | ✅ |
| PAY-C2: tax fallback float → integer cents math | payment_stripe.py | ✅ |
| EMAIL-C2: authorization expired email now called in cron | cron_jobs.py | ✅ |
| STOCK-C1: stock notifications deleted after email sent | products.py | ✅ |
| ADDR-C1: delete_buyer_address ownership check added | users.py | ✅ |
| EMAIL-H1: low stock alert checks emailConsent | cron_jobs.py | ✅ |
| EMAIL-H2: abandoned cart checks emailConsent | cron_jobs.py | ✅ |
| EMAIL-H3: renewal reminder skips CANCELLED subscriptions | cron_jobs.py | ✅ |
| CRON-M1: sync_expired_subscriptions → 6hr schedule | cron_jobs.py | ✅ |
| PROD-C1: form state reset on navigation away | addproduct_screen.dart | ✅ |
| PROD-C2: warehouse bypass prevention | add_product_viewmodel.dart | ✅ |
| PROD-C3: lifecycleStatus draft removed from Dart payload | add_product_viewmodel.dart | ✅ |
| PROD-C4: video upload loading state added | add_product_viewmodel.dart | ✅ |
| BOOT-C1: emulator no longer falls back silently to dev | main.dart | ✅ |
| FE-H1: unsafe .value! in chat_screen → null-safe access | chat_screen.dart | ✅ |
| FE-M1: qaControllerProvider.autoDispose added | qa_provider.dart | ✅ |
| NOTIF-M1: refund_issued deep link routing added | notification_service.dart | ✅ |
| NOTIF-M2: NotificationTypes.messageReport — already existed | schema_constants.dart | ✅ verified |
| CHAT-C2: max 500 messages per thread + BusinessRules constant | chat.py + schema_constants.py | ✅ |
| CHAT-H1: message_reports Firestore rules — already existed | firestore.rules | ✅ verified |
| EMAIL-C4: seller email+push on CONFIRMED via Firestore trigger | orders.py | ✅ |
| BOOT-H2: session timeout bound to specific user UID | session_timeout_service.dart | ✅ |
| BOOT-M3: analytics disabled in staging env | analytics_service.dart | ✅ |
| WH-H1: warehouse deletion race — products updated before delete | products.py | ✅ |
| WH-H2: international warehouse required fields validated | products.py | ✅ |
| STOCK-M1: orphaned variant subscriptions cleaned up on delete | products.py | ✅ |
| ADDR-M1: default address swap wrapped in Firestore transaction | users.py | ✅ |
| CHAT-M2: premium check reads isPremium from user doc (1 read vs 2) | chat.py | ✅ |
| CRON-C3: Sentry captures added to 16 batch error handlers | cron_jobs.py | ✅ |
| FE-M3: Q&A unanswered badge added to seller_products_screen | seller_products_screen.dart | ✅ |
| LEG-H1: CircularProgressIndicator → ModernLoadingIndicator | productaddvideo_screen.dart | ✅ |
| LEG-H2: FirebaseAuth.instance → ref.read(firebaseAuthProvider) | profile_screen.dart | ✅ |
| SRCH-H3: admin API key guard in update_remote_config.py | scripts/update_remote_config.py | ✅ |

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

### Ran in session 2026-03-01 (parallel batch):
logic-auditor, security-auditor, cross-stack-auditor, order-lifecycle-auditor, performance-auditor, premium-auditor, legal-compliance-auditor

### Still Needed:
product-lifecycle-auditor, return-requests-auditor, coupons-discounts-auditor, firebase-architect-agent, admin-panel-auditor, auth-onboarding-auditor

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


.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:143:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T07: Admin Tab — Payments and payouts
   ✅ Flutter initialized in 150200ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K[35/279] [chromium] › playwright_ui/admin-panel.spec.ts:165:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T09: Admin Action — View Seller Detail (retry #1)
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:165:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T09: Admin Action — View Seller Detail
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:154:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T08: Admin Tab — Security alerts and logs
   ✅ Flutter initialized in 150196ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K  7) [chromium] › playwright_ui/admin-panel.spec.ts:143:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T07: Admin Tab — Payments and payouts 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--522b7--Tab-—-Payments-and-payouts-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[36/279] [chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh
   ✅ Flutter initialized in 150189ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K  8) [chromium] › playwright_ui/admin-panel.spec.ts:154:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T08: Admin Tab — Security alerts and logs 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--00c04--—-Security-alerts-and-logs-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[37/279] [chromium] › playwright_ui/admin-security.spec.ts:19:7 › Admin Security › MFA enrollment endpoint responds for admin
[1A[2K[38/279] [chromium] › playwright_ui/admin-security.spec.ts:34:7 › Admin Security › Non-admin cannot call admin MFA endpoints
[1A[2K[39/279] [chromium] › playwright_ui/admin-security.spec.ts:40:7 › Admin Security › Unauthenticated requests to admin endpoints are rejected
[1A[2K[40/279] [chromium] › playwright_ui/admin-security.spec.ts:50:7 › Admin Security › Non-seller cannot access seller-only endpoints via API
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:165:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T09: Admin Action — View Seller Detail
   ✅ Flutter initialized in 150106ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K[41/279] [chromium] › playwright_ui/admin-security.spec.ts:62:7 › Admin Security › Permission enforcement: wrong user cannot modify others orders
[1A[2K[42/279] [chromium] › playwright_ui/buyer-flow.spec.ts:23:9 › PW IT Replica — Buyer Flow › Complete Buyer Journey
[1A[2K[chromium] › playwright_ui/buyer-flow.spec.ts:23:9 › PW IT Replica — Buyer Flow › Complete Buyer Journey
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[43/279] [chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh (retry #1)
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility
   ✅ Flutter initialized in 150196ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K  9) [chromium] › playwright_ui/admin-panel.spec.ts:165:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T09: Admin Action — View Seller Detail 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--91149-Action-—-View-Seller-Detail-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[44/279] [chromium] › playwright_ui/checkout-validation.spec.ts:42:7 › Checkout Validation › Rejects unauthenticated checkout request
[1A[2K[45/279] [chromium] › playwright_ui/checkout-validation.spec.ts:52:7 › Checkout Validation › Rejects empty items array
[1A[2K[46/279] [chromium] › playwright_ui/checkout-validation.spec.ts:68:7 › Checkout Validation › Rejects missing shipping address fields
[1A[2K[47/279] [chromium] › playwright_ui/checkout-validation.spec.ts:75:7 › Checkout Validation › Rejects invalid postal code format
[1A[2K[48/279] [chromium] › playwright_ui/checkout-validation.spec.ts:82:7 › Checkout Validation › Rejects invalid province code
[1A[2K[49/279] [chromium] › playwright_ui/checkout-validation.spec.ts:90:7 › Checkout Validation › Rejects price tampering (client sends lower price)
[1A[2K[50/279] [chromium] › playwright_ui/checkout-validation.spec.ts:98:7 › Checkout Validation › Rejects subtotal mismatch
[1A[2K[51/279] [chromium] › playwright_ui/checkout-validation.spec.ts:105:7 › Checkout Validation › Rejects negative price
[1A[2K[52/279] [chromium] › playwright_ui/checkout-validation.spec.ts:113:7 › Checkout Validation › Rejects quantity zero
[1A[2K[53/279] [chromium] › playwright_ui/checkout-validation.spec.ts:121:7 › Checkout Validation › Rejects quantity exceeding max cap (>100)
[1A[2K[54/279] [chromium] › playwright_ui/checkout-validation.spec.ts:129:7 › Checkout Validation › Rejects negative quantity
[1A[2K[55/279] [chromium] › playwright_ui/checkout-validation.spec.ts:136:7 › Checkout Validation › Rejects self-purchase (buyer is the seller of the product)
[1A[2K[56/279] [chromium] › playwright_ui/checkout-validation.spec.ts:145:7 › Checkout Validation › Rejects non-Canadian shipping address (USA)
[1A[2K[57/279] [chromium] › playwright_ui/checkout-validation.spec.ts:152:7 › Checkout Validation › Valid checkout creates session with Stripe URL
[1A[2K[58/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:51:7 › A. Digital Product Catalogue › A.1 Software product has correct Firestore fields (FXCleaner)
[1A[2K[59/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:67:7 › A. Digital Product Catalogue › A.2 Book product has correct Firestore fields (eBook bundle)
[1A[2K[60/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:80:7 › A. Digital Product Catalogue › A.3 Digital product shows "Instant delivery" badge (product model)
[1A[2K[61/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:106:7 › B. Digital-Only Checkout › B.1 Digital-only cart does not require Canadian shipping address
[1A[2K[62/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:123:7 › B. Digital-Only Checkout › B.2 Buy digital software product → license key created on order item
[1A[2K[chromium] › playwright_ui/buyer-flow.spec.ts:23:9 › PW IT Replica — Buyer Flow › Complete Buyer Journey
   ✅ Flutter initialized in 150163ms

[1A[2K[63/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:158:7 › B. Digital-Only Checkout › B.3 Buy digital book product → book license created with bookSourceUrl
[1A[2K[64/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:191:7 › C. Mixed Cart — Digital + Physical › C.1 Mixed cart requires shipping address (digital does not waive physical requirement)
[1A[2K[65/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:210:7 › C. Mixed Cart — Digital + Physical › C.2 Mixed cart checkout creates order with both digital and physical items
[1A[2K[66/279] [chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility (retry #1)
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[67/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:247:7 › C. Mixed Cart — Digital + Physical › C.3 Shipping cost is nonzero in mixed cart (physical item triggers shipping calc)
[1A[2K[68/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:322:7 › D. License Activation & Book Download › D.1 Activate software license on a new device → approved with downloadUrls
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:322:7 › D. License Activation & Book Download › D.1 Activate software license on a new device → approved with downloadUrls
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh
   ✅ Flutter initialized in 150130ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:322:7 › D. License Activation & Book Download › D.1 Activate software license on a new device → approved with downloadUrls
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[69/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:338:7 › D. License Activation & Book Download › D.2 Re-activating same device is idempotent (no duplicate activation entry)
[1A[2K[70/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:356:7 › D. License Activation & Book Download › D.3 Generate book download session → single-use downloadUrl returned
[1A[2K[71/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:370:7 › D. License Activation & Book Download › D.4 Software license on wrong platform is rejected
[1A[2K[72/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:511:7 › F. Seller UX — Digital Product Creation › F.1 Digital product schema is valid for Firestore after seeding
[1A[2K[73/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:530:7 › F. Seller UX — Digital Product Creation › F.2 Digital-only checkout generates zero shipping cost
[1A[2K[74/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:541:7 › F. Seller UX — Digital Product Creation › F.3 FXCleaner software product is buyable worldwide (no Canada-only restriction)
[1A[2K[75/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:779:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.1 deactivate_license removes device — remaining activations decremented
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:779:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.1 deactivate_license removes device — remaining activations decremented
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[76/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:798:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.2 After deactivation, same device can be re-activated (slot freed)
[1A[2K[77/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:809:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.3 Non-owner cannot deactivate a license
[1A[2K[78/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:818:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.4 Activating a revoked license is rejected with "revoked" error
[1A[2K[79/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:828:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.5 device_limit_exceeded: adding a 3rd device to limit=2 license is rejected
[1A[2K[80/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:838:7 › H. License Management — Deactivate, Verify, Device Limit, Revoke › H.6 verify_license re-activates idempotently — no duplicate in activations array
[1A[2K[81/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:879:7 › I. Digital Business Rules › I.1 Digital product cannot be returned (create_return_request rejected)
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:879:7 › I. Digital Business Rules › I.1 Digital product cannot be returned (create_return_request rejected)
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc failed [403]: https://firestore.googleapis.com/v1/projects/orignagta-dev/databases/(default)/documents/orders/e2e-test-i1-digital-return
[1A[2KRequest Body: {"fields":{"orderId":{"stringValue":"e2e-test-i1-digital-return"},"userId":{"stringValue":"smy7bq6BXfeTuXKSTZJoOQ9a6K42"},"items":{"arrayValue":{"values":[{"mapValue":{"fields":{"productId":{"stringValue":"product_031"},"name":{"stringValue":"FXCleaner"},"description":{"stringValue":"Mac disk cleaner"},"price":{"doubleValue":29.99},"quantity":{"integerValue":"1"},"imageUrls":{"arrayValue":{"values":[{"stringValue":"https://example.com/fx.jpg"}]}},"sellerId":{"stringValue":"eVxwL5SfEATPnw1zhWYaUdGx8MD2"},"isDigital":{"booleanValue":true},"status":{"stringValue":"delivered"},"deliveredAt":{"timestampValue":"2026-02-27T01:11:20.450Z"}}}}]}},"orderStatus":{"stringValue":"delivered"},"paymentStatus":{"stringValue":"captured"},"subtotalCents":{"integerValue":"2999"},"shippingCostCents":{"integerValue":"0"},"taxAmountCents":{"integerValue":"150"},"totalAmountCents":{"integerValue":"3149"},"createdAt":{"timestampValue":"2026-03-01T01:11:20.450Z"},"updatedAt":{"timestampValue":"2026-03-01T01:11:20.450Z"}}}
[1A[2KResponse Body: {
  "error": {
    "code": 403,
    "message": "Missing or insufficient permissions.",
    "status": "PERMISSION_DENIED"
  }
}




[1A[2K[82/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:924:7 › I. Digital Business Rules › I.2 License is revoked when order is refunded (revoke_digital_licenses_for_order)
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:924:7 › I. Digital Business Rules › I.2 License is revoked when order is refunded (revoke_digital_licenses_for_order)
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[83/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:977:7 › I. Digital Business Rules › I.3 Digital-only order has no shipping requirement and zero shippingCostCents
[1A[2K[84/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:437:7 › E. Security & Access Control › E.1 Another buyer cannot activate a license they do not own
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:437:7 › E. Security & Access Control › E.1 Another buyer cannot activate a license they do not own
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[85/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:452:7 › E. Security & Access Control › E.2 Malformed license key format is rejected before DB lookup
[1A[2K[86/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:464:7 › E. Security & Access Control › E.3 Non-owner cannot generate book download session
[1A[2K[87/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:475:7 › E. Security & Access Control › E.4 Book download session token is single-use (second use of same token fails)
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:475:7 › E. Security & Access Control › E.4 Book download session token is single-use (second use of same token fails)
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[88/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:611:7 › G. Software Download Session › G.1 generate_software_download_session → downloadUrl with /sdl?t= token
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:611:7 › G. Software Download Session › G.1 generate_software_download_session → downloadUrl with /sdl?t= token
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[89/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:624:7 › G. Software Download Session › G.2 software download token is single-use (second use returns 410)
[1A[2K[90/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:643:7 › G. Software Download Session › G.3 generate_software_download_session on wrong platform is rejected
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:643:7 › G. Software Download Session › G.3 generate_software_download_session on wrong platform is rejected
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[91/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:653:7 › G. Software Download Session › G.4 Non-owner cannot generate software download session
[1A[2K[92/279] [chromium] › playwright_ui/digital-product-e2e.spec.ts:662:7 › G. Software Download Session › G.5 generate_software_download_session on a book license is rejected
[1A[2K[chromium] › playwright_ui/digital-product-e2e.spec.ts:662:7 › G. Software Download Session › G.5 generate_software_download_session on a book license is rejected
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[93/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:74:7 › 1. Self-Purchase Prevention › Seller cannot purchase their own product via API
[1A[2K[94/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:96:7 › 2. Quantity Validation › Checkout rejected when quantity exceeds live stock
[1A[2K[chromium] › playwright_ui/edge-cases-security.spec.ts:96:7 › 2. Quantity Validation › Checkout rejected when quantity exceeds live stock
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[95/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:130:7 › 2. Quantity Validation › Checkout rejected for quantity = 0
[1A[2K[96/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:144:7 › 2. Quantity Validation › Checkout rejected for quantity > 100 (max item cap)
[1A[2K[97/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:174:7 › 3. Order Guards › cancel_order on non-existent order returns not-found
[1A[2K[98/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:182:7 › 3. Order Guards › update_order_status on non-existent order returns not-found
[1A[2K[99/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:191:7 › 3. Order Guards › Buyer cannot call update_order_status (seller/admin only endpoint)
[1A[2K[100/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:205:7 › 3. Order Guards › Seller cannot update status of order they are not part of
[1A[2K[chromium] › playwright_ui/edge-cases-security.spec.ts:205:7 › 3. Order Guards › Seller cannot update status of order they are not part of
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[101/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:244:7 › 4. Product Rating Security › Rating > 5 is rejected (range check fires before order lookup)
[1A[2K[102/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:259:7 › 4. Product Rating Security › Rating < 1 is rejected (range check fires before order lookup)
[1A[2K[103/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:274:7 › 4. Product Rating Security › Rating rejected when orderId does not exist (order ownership enforced)
[1A[2K[104/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:290:7 › 4. Product Rating Security › Rating rejected when a different user owns the order
[1A[2K[chromium] › playwright_ui/edge-cases-security.spec.ts:290:7 › 4. Product Rating Security › Rating rejected when a different user owns the order
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[105/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:331:7 › 5. Checkout Idempotency › Duplicate checkout within 60s returns existing order (duplicate=true)
[1A[2K[106/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:363:7 › 6. Non-Canadian Address Rejected › Checkout with non-Canada country is rejected
[1A[2K[107/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:384:7 › 6. Non-Canadian Address Rejected › Checkout with invalid Canadian postal code format is rejected
[1A[2K[108/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:398:7 › 6. Non-Canadian Address Rejected › Checkout with missing country is rejected
[1A[2K[109/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:417:7 › 7. Non-Existent Product at Checkout › Checkout with non-existent product ID is rejected
[1A[2K[110/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:429:7 › 7. Non-Existent Product at Checkout › Checkout with subtotal of 0 is rejected
[1A[2K[111/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:449:7 › 8. Permission Isolation › Unauthenticated request to create_checkout_session is rejected
[1A[2K[112/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:458:7 › 8. Permission Isolation › Unauthenticated request to cancel_order is rejected
[1A[2K[113/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:465:7 › 8. Permission Isolation › Unauthenticated request to submit_product_rating is rejected
[1A[2K[114/279] [chromium] › playwright_ui/edge-cases-security.spec.ts:474:7 › 8. Permission Isolation › Buyer cannot call update_order_status (requires seller or admin role)
[1A[2K[chromium] › playwright_ui/edge-cases-security.spec.ts:474:7 › 8. Permission Isolation › Buyer cannot call update_order_status (requires seller or admin role)
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[115/279] [chromium] › playwright_ui/favorites.spec.ts:25:7 › Favorites › User can navigate to favorites page
[1A[2K[chromium] › playwright_ui/favorites.spec.ts:25:7 › Favorites › User can navigate to favorites page
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[116/279] [chromium] › playwright_ui/favorites.spec.ts:53:7 › Favorites › Product card favorite toggle is accessible
[1A[2K[chromium] › playwright_ui/favorites.spec.ts:53:7 › Favorites › Product card favorite toggle is accessible
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  10) [chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--52890-b-persistence-after-refresh-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[117/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:43:7 › Multi-Seller Orders › Cart with multiple items creates single order
[1A[2K[chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility
   ✅ Flutter initialized in 150169ms

[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K[118/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:53:7 › Multi-Seller Orders › Multi-seller cart creates order with correct items
[1A[2K[chromium] › playwright_ui/favorites.spec.ts:25:7 › Favorites › User can navigate to favorites page
   ✅ Flutter initialized in 150059ms

[1A[2K[119/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:65:7 › Multi-Seller Orders › Multi-country + Multi-seller cart creates order
[1A[2K[chromium] › playwright_ui/favorites.spec.ts:53:7 › Favorites › Product card favorite toggle is accessible
   ✅ Flutter initialized in 150060ms

[1A[2K[120/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:114:7 › Multi-Seller Orders › Wrong seller cannot update another seller items
[1A[2K[121/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:112:7 › 2. Digital Product Purchase → License Generation › 2.1 Purchasing a digital product creates a license after capture
[1A[2K[122/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:131:7 › 2. Digital Product Purchase → License Generation › 2.2 License is NOT created before payment is captured
[1A[2K[123/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:52:7 › 1. Stock Notification Subscribe/Unsubscribe › 1.1 Subscribe to out-of-stock notification (product-level)
[1A[2K[124/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:61:7 › 1. Stock Notification Subscribe/Unsubscribe › 1.2 Duplicate subscribe is idempotent
[1A[2K[125/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:71:7 › 1. Stock Notification Subscribe/Unsubscribe › 1.3 Unsubscribe removes stock notification
[1A[2K[126/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:80:7 › 1. Stock Notification Subscribe/Unsubscribe › 1.4 Subscribe and unsubscribe (product-level cleanup)
[1A[2K  11) [chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:71:13

    TimeoutError: locator.click: Timeout 60000ms exceeded.
    Call log:
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:309

      307 | export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
      308 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 309 |     await settingsBtn.click();
          |                       ^
      310 |     await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
      311 |     await waitForFlutter(page, 30000);
      312 |
        at performSignOut (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:309:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/admin-panel.spec.ts:77:33

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/admin-panel-PW-IT-Replica--811b4-—-Return-to-Home-visibility-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[127/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:92:7 › 1. Stock Notification Subscribe/Unsubscribe › 1.5 Unauthenticated subscribe is rejected
[1A[2K[128/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:170:7 › 3. Async Payment (Interac) Confirmation Flow › 3.1 Checkout session can be created with interac_present payment method
[1A[2K[129/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:178:7 › 3. Async Payment (Interac) Confirmation Flow › 3.2 Order created for async payment starts in pending_capture
[1A[2K[130/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:244:7 › 4. Multi-Seller Cart → Per-Seller Payout Verification › 4.2 Each seller item has independent status tracking
[1A[2K[131/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:194:7 › 3. Async Payment (Interac) Confirmation Flow › 3.3 Webhook handler processes payment_intent.succeeded for async payment
[1A[2K[132/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:222:7 › 4. Multi-Seller Cart → Per-Seller Payout Verification › 4.1 Multi-seller cart creates order with items from both sellers
[1A[2K[chromium] › playwright_ui/multi-seller-orders.spec.ts:65:7 › Multi-Seller Orders › Multi-country + Multi-seller cart creates order
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[chromium] › playwright_ui/multi-seller-orders.spec.ts:114:7 › Multi-Seller Orders › Wrong seller cannot update another seller items
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[133/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:87:7 › Multi-Seller Orders › Per-item status tracking works for multi-item order
[1A[2K[134/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:136:7 › Multi-Seller Orders › Seller cannot update order-level status for multi-seller order
[1A[2K[135/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:264:7 › 4. Multi-Seller Cart → Per-Seller Payout Verification › 4.3 Payout amounts are computed per-seller after capture
[1A[2K[chromium] › playwright_ui/new-coverage-e2e.spec.ts:222:7 › 4. Multi-Seller Cart → Per-Seller Payout Verification › 4.1 Multi-seller cart creates order with items from both sellers
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[chromium] › playwright_ui/multi-seller-orders.spec.ts:87:7 › Multi-Seller Orders › Per-item status tracking works for multi-item order
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[136/279] [chromium] › playwright_ui/new-notification-features.spec.ts:53:7 › New Notification Features E2E › Price drop notification is triggered for favorited products
[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:53:7 › New Notification Features E2E › Price drop notification is triggered for favorited products
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 973, prefix: eyJhbGciOi...

[1A[2K[chromium] › playwright_ui/multi-seller-orders.spec.ts:136:7 › Multi-Seller Orders › Seller cannot update order-level status for multi-seller order
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[137/279] [chromium] › playwright_ui/multi-seller-orders.spec.ts:87:7 › Multi-Seller Orders › Per-item status tracking works for multi-item order (retry #1)
[1A[2K[138/279] [chromium] › playwright_ui/new-coverage-e2e.spec.ts:288:7 › 4. Multi-Seller Cart → Per-Seller Payout Verification › 4.4 Buyer cannot buy from their own seller account (self-purchase blocked)
[1A[2K[139/279] [chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered
[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[140/279] [chromium] › playwright_ui/new-notification-features.spec.ts:120:7 › New Notification Features E2E › Message reporting (flagging) creates a report record
[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:120:7 › New Notification Features E2E › Message reporting (flagging) creates a report record
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:53:7 › New Notification Features E2E › Price drop notification is triggered for favorited products
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[141/279] [chromium] › playwright_ui/notifications.spec.ts:26:7 › Notifications E2E Tests › Notify Me button — stock subscription API works for OOS product
[1A[2K[142/279] [chromium] › playwright_ui/notifications.spec.ts:34:7 › Notifications E2E Tests › Subscription to stock notifications & idempotency
[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:120:7 › New Notification Features E2E › Message reporting (flagging) creates a report record
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[143/279] [chromium] › playwright_ui/notifications.spec.ts:47:7 › Notifications E2E Tests › Push notification opt-out is respected (pushEnabled: false)
[1A[2K[chromium] › playwright_ui/notifications.spec.ts:47:7 › Notifications E2E Tests › Push notification opt-out is respected (pushEnabled: false)
writeDoc using token length: 973, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 973, prefix: eyJhbGciOi...

[1A[2K[144/279] [chromium] › playwright_ui/notifications.spec.ts:67:7 › Notifications E2E Tests › SnackBar foreground message — logic verified via push_service.py audit
[1A[2K[145/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:73:7 › Order Cancellation & Refund › Buyer can cancel order before shipping
[1A[2K[chromium] › playwright_ui/order-cancellation-refund.spec.ts:73:7 › Order Cancellation & Refund › Buyer can cancel order before shipping
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[146/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:31:7 › Order Lifecycle › Order created after payment has confirmed status
[1A[2K[chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[147/279] [chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered (retry #1)
[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K  12) [chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered 

    Error: Buyer should receive a notification for the new message

    [2mexpect([22m[31mreceived[39m[2m).[22mtoBeTruthy[2m()[22m

    Received: [31mundefined[39m

      115 |     const chatNotif = userNotifs.find((n: any) => n.type === 'new_message' && n.chatId === chatId);
      116 |     
    > 117 |     expect(chatNotif, 'Buyer should receive a notification for the new message').toBeTruthy();
          |                                                                                  ^
      118 |   });
      119 |
      120 |   test('Message reporting (flagging) creates a report record', async () => {
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/new-notification-features.spec.ts:117:82

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/new-notification-features--3cc3b-e-notification-is-triggered-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: Buyer should receive a notification for the new message

    [2mexpect([22m[31mreceived[39m[2m).[22mtoBeTruthy[2m()[22m

    Received: [31mundefined[39m

      115 |     const chatNotif = userNotifs.find((n: any) => n.type === 'new_message' && n.chatId === chatId);
      116 |     
    > 117 |     expect(chatNotif, 'Buyer should receive a notification for the new message').toBeTruthy();
          |                                                                                  ^
      118 |   });
      119 |
      120 |   test('Message reporting (flagging) creates a report record', async () => {
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/new-notification-features.spec.ts:117:82

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/new-notification-features--3cc3b-e-notification-is-triggered-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #2: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/new-notification-features--3cc3b-e-notification-is-triggered-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/new-notification-features--3cc3b-e-notification-is-triggered-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[148/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:56:7 › Order Lifecycle › Seller can transition processing → shipped with tracking
[1A[2K  13) [chromium] › playwright_ui/multi-seller-orders.spec.ts:87:7 › Multi-Seller Orders › Per-item status tracking works for multi-item order 

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/multi-seller-orders.spec.ts:99:26

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/multi-seller-orders.spec.ts:99:26

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/multi-seller-orders-Multi--7028c--works-for-multi-item-order-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[149/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:41:7 › Order Lifecycle › Seller can transition confirmed → processing
[1A[2K[150/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:93:7 › Order Lifecycle › Buyer cannot update order status (only seller/admin can)
[1A[2K[151/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:87:7 › Order Cancellation & Refund › Cannot cancel a shipped order
[1A[2K[152/279] [chromium] › playwright_ui/order-notifications.spec.ts:39:7 › Order Notifications › Buyer receives notification when individual items are shipped
[1A[2K[153/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:109:7 › Order Cancellation & Refund › Cannot cancel a delivered order
[1A[2K[chromium] › playwright_ui/order-lifecycle.spec.ts:56:7 › Order Lifecycle › Seller can transition processing → shipped with tracking
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[154/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:79:7 › Order Lifecycle › Invalid transition confirmed → delivered is rejected
[1A[2K[chromium] › playwright_ui/order-lifecycle.spec.ts:93:7 › Order Lifecycle › Buyer cannot update order status (only seller/admin can)
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[155/279] [chromium] › playwright_ui/order-notifications.spec.ts:39:7 › Order Notifications › Buyer receives notification when individual items are shipped (retry #1)
[1A[2K[156/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:132:7 › Order Cancellation & Refund › Stock restores after cancellation
[1A[2K[157/279] [chromium] › playwright_ui/order-notifications.spec.ts:116:7 › Order Notifications › Local pickup order receives "Ready for Pickup" notification
[1A[2K  14) [chromium] › playwright_ui/order-notifications.spec.ts:39:7 › Order Notifications › Buyer receives notification when individual items are shipped 

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:53:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:53:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--c44a4-ndividual-items-are-shipped-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[158/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:156:7 › Order Cancellation & Refund › Cannot cancel an already cancelled order
[1A[2K[159/279] [chromium] › playwright_ui/order-notifications.spec.ts:75:7 › Order Notifications › Buyer receives notification when individual items are delivered
[1A[2K[160/279] [chromium] › playwright_ui/order-notifications.spec.ts:116:7 › Order Notifications › Local pickup order receives "Ready for Pickup" notification (retry #1)
[1A[2K[161/279] [chromium] › playwright_ui/order-lifecycle.spec.ts:93:7 › Order Lifecycle › Buyer cannot update order status (only seller/admin can) (retry #1)
[1A[2K[162/279] [chromium] › playwright_ui/order-notifications.spec.ts:75:7 › Order Notifications › Buyer receives notification when individual items are delivered (retry #1)
[1A[2K[163/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:171:7 › Order Cancellation & Refund › Another buyer cannot cancel an order they do not own
[1A[2K  15) [chromium] › playwright_ui/order-lifecycle.spec.ts:93:7 › Order Lifecycle › Buyer cannot update order status (only seller/admin can) 

    Error: waitForOrderStatus timeout: order ue6ILesNHEBHa3FAEQIz expected [confirmed] but got "processing" after 90000ms

       at api-helpers.ts:574

      572 |   }
      573 |   const currentStatus = lastOrder?.orderStatus || 'unknown';
    > 574 |   throw new Error(
          |         ^
      575 |     `waitForOrderStatus timeout: order ${orderId} expected [${targetStatuses}] but got "${currentStatus}" after ${maxWaitMs}ms`
      576 |   );
      577 | }
        at waitForOrderStatus (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:574:9)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-lifecycle.spec.ts:96:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-lifecycle-Order-Life-3c494-atus-only-seller-admin-can--chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-lifecycle-Order-Life-3c494-atus-only-seller-admin-can--chromium/error-context.md


[1A[2K[164/279] [chromium] › playwright_ui/order-notifications.spec.ts:205:7 › Order Notifications › Seller receives notification when a return is requested
[1A[2K[chromium] › playwright_ui/order-notifications.spec.ts:116:7 › Order Notifications › Local pickup order receives "Ready for Pickup" notification
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K  16) [chromium] › playwright_ui/order-notifications.spec.ts:116:7 › Order Notifications › Local pickup order receives "Ready for Pickup" notification 

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:157:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: update_item_status failed: Tracking number required

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:157:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--50813-ady-for-Pickup-notification-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[165/279] [chromium] › playwright_ui/order-notifications.spec.ts:180:7 › Order Notifications › Seller receives notification when a new order is placed
[1A[2K[chromium] › playwright_ui/order-cancellation-refund.spec.ts:171:7 › Order Cancellation & Refund › Another buyer cannot cancel an order they do not own
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[chromium] › playwright_ui/order-notifications.spec.ts:75:7 › Order Notifications › Buyer receives notification when individual items are delivered
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[166/279] [chromium] › playwright_ui/order-notifications.spec.ts:205:7 › Order Notifications › Seller receives notification when a return is requested (retry #1)
[1A[2K[167/279] [chromium] › playwright_ui/order-cancellation-refund.spec.ts:186:7 › Order Cancellation & Refund › Concurrent cancel requests are idempotent — only one succeeds
[1A[2K  17) [chromium] › playwright_ui/order-notifications.spec.ts:75:7 › Order Notifications › Buyer receives notification when individual items are delivered 

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:87:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:87:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--0ad3b-ividual-items-are-delivered-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[168/279] [chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[169/279] [chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  18) [chromium] › playwright_ui/order-notifications.spec.ts:205:7 › Order Notifications › Seller receives notification when a return is requested 

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:217:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: update_item_status failed: INTERNAL

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/order-notifications.spec.ts:217:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/order-notifications-Order--17ed3--when-a-return-is-requested-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[170/279] [chromium] › playwright_ui/password-reset.spec.ts:30:7 › Password Reset Routing › should reject URL with invalid oobCode format
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:30:7 › Password Reset Routing › should reject URL with invalid oobCode format
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[171/279] [chromium] › playwright_ui/payment-edge-cases.spec.ts:30:7 › Payment Edge Cases › Declined card shows error on Stripe page
[1A[2K[172/279] [chromium] › playwright_ui/payment-edge-cases.spec.ts:90:7 › Payment Edge Cases › 3D Secure card triggers authentication challenge
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL
   ✅ Flutter initialized in 105102ms

[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired
   ✅ Flutter initialized in 105039ms

[1A[2K[173/279] [chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL (retry #1)
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[174/279] [chromium] › playwright_ui/payment-edge-cases.spec.ts:157:7 › Payment Edge Cases › Currency is always CAD for Canadian buyers
[1A[2K[175/279] [chromium] › playwright_ui/payment-edge-cases.spec.ts:168:7 › Payment Edge Cases › Declined card does not decrement stock
[1A[2K[176/279] [chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired (retry #1)
[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:30:7 › Password Reset Routing › should reject URL with invalid oobCode format
   ✅ Flutter initialized in 105135ms

[1A[2K[177/279] [chromium] › playwright_ui/premium-subscription.spec.ts:306:7 › A. Subscription Status API › A1: get_subscription_status returns expected shape
[1A[2K[178/279] [chromium] › playwright_ui/premium-subscription.spec.ts:317:7 › A. Subscription Status API › A2: get_subscription_status requires authentication
[1A[2K[179/279] [chromium] › playwright_ui/premium-subscription.spec.ts:322:7 › A. Subscription Status API › A3: isPremium on user doc matches subscription doc status
[1A[2K[180/279] [chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[181/279] [chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL
   ✅ Flutter initialized in 105941ms

[1A[2K[chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired
   ✅ Flutter initialized in 106056ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer
   ✅ Flutter initialized in 105725ms

[1A[2K  19) [chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeVisible[2m([22m[2m)[22m failed

    Locator: getByLabel('Go to Login')
    Expected: visible
    Timeout: 25000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeVisible" with timeout 25000ms[22m
    [2m  - waiting for getByLabel('Go to Login')[22m


      13 |     // This confirms ResetPasswordScreen was rendered (routing worked)
      14 |     await expect(page.getByLabel('Go to Login'))
    > 15 |       .toBeVisible({ timeout: 25000 });
         |        ^
      16 |   });
      17 |
      18 |   test('should show error and Go to Login when oobCode is invalid/expired', async ({ page, baseURL }) => {
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/password-reset.spec.ts:15:8

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeVisible[2m([22m[2m)[22m failed

    Locator: getByLabel('Go to Login')
    Expected: visible
    Timeout: 25000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeVisible" with timeout 25000ms[22m
    [2m  - waiting for getByLabel('Go to Login')[22m


      13 |     // This confirms ResetPasswordScreen was rendered (routing worked)
      14 |     await expect(page.getByLabel('Go to Login'))
    > 15 |       .toBeVisible({ timeout: 25000 });
         |        ^
      16 |   });
      17 |
      18 |   test('should show error and Go to Login when oobCode is invalid/expired', async ({ page, baseURL }) => {
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/password-reset.spec.ts:15:8

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-00cb3-ode-resetPassword-is-in-URL-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[182/279] [chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium
   ✅ Flutter initialized in 113402ms

[1A[2K  20) [chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeVisible[2m([22m[2m)[22m failed

    Locator: getByLabel('Go to Login')
    Expected: visible
    Timeout: 25000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeVisible" with timeout 25000ms[22m
    [2m  - waiting for getByLabel('Go to Login')[22m


      22 |     // After Firebase rejects the invalid code, error state shows "Go to Login" button
      23 |     const goToLoginBtn = page.getByLabel('Go to Login');
    > 24 |     await expect(goToLoginBtn).toBeVisible({ timeout: 25000 });
         |                                ^
      25 |
      26 |     // Password form must NOT be visible for invalid oobCode
      27 |     await expect(page.getByLabel('New Password')).not.toBeVisible();
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/password-reset.spec.ts:24:32

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeVisible[2m([22m[2m)[22m failed

    Locator: getByLabel('Go to Login')
    Expected: visible
    Timeout: 25000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeVisible" with timeout 25000ms[22m
    [2m  - waiting for getByLabel('Go to Login')[22m


      22 |     // After Firebase rejects the invalid code, error state shows "Go to Login" button
      23 |     const goToLoginBtn = page.getByLabel('Go to Login');
    > 24 |     await expect(goToLoginBtn).toBeVisible({ timeout: 25000 });
         |                                ^
      25 |
      26 |     // Password form must NOT be visible for invalid oobCode
      27 |     await expect(page.getByLabel('New Password')).not.toBeVisible();
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/password-reset.spec.ts:24:32

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/password-reset-Password-Re-26c57--oobCode-is-invalid-expired-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[183/279] [chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[184/279] [chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[185/279] [chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits
   ✅ Flutter initialized in 107409ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month
   ✅ Flutter initialized in 105374ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer
   ✅ Flutter initialized in 105235ms

[1A[2K[186/279] [chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium
   ✅ Flutter initialized in 105316ms

[1A[2K[187/279] [chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K  21) [chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:350:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:350:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3e6af-nders-for-non-premium-buyer-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[188/279] [chromium] › playwright_ui/premium-subscription.spec.ts:413:7 › C. Create Subscription API + Session Integrity › C1: create_subscription returns Stripe checkout URL in subscription mode
[1A[2K[189/279] [chromium] › playwright_ui/premium-subscription.spec.ts:429:7 › C. Create Subscription API + Session Integrity › C2: Checkout URL is a Stripe hosted page in subscription mode
[1A[2K  22) [chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:371:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:371:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-f703d-el-is-btn-subscribe-premium-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[190/279] [chromium] › playwright_ui/premium-subscription.spec.ts:459:7 › C. Create Subscription API + Session Integrity › C3: Checkout page displays subscription product name (Origna Premium)
[1A[2K[191/279] [chromium] › playwright_ui/premium-subscription.spec.ts:481:7 › C. Create Subscription API + Session Integrity › C4: create_subscription requires authentication
[1A[2K[192/279] [chromium] › playwright_ui/premium-subscription.spec.ts:486:7 › C. Create Subscription API + Session Integrity › C5: create_subscription idempotency — same user gets same session (or ALREADY_EXISTS)
[1A[2K[193/279] [chromium] › playwright_ui/premium-subscription.spec.ts:524:7 › D. Full Stripe Checkout — Success Flow › D1: 4242 card → successful subscription → Firestore isPremium=true within 60s
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits
   ✅ Flutter initialized in 105299ms

[1A[2K[194/279] [chromium] › playwright_ui/premium-subscription.spec.ts:568:7 › D. Full Stripe Checkout — Success Flow › D2: After successful subscription, user doc has isPremium=true + premiumExpiresAt set
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:568:7 › D. Full Stripe Checkout — Success Flow › D2: After successful subscription, user doc has isPremium=true + premiumExpiresAt set
D2: Buyer not premium — run D1 first or set up test data

[1A[2K[195/279] [chromium] › playwright_ui/premium-subscription.spec.ts:583:7 › D. Full Stripe Checkout — Success Flow › D3: After subscription, get_subscription_status returns correct period dates
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:583:7 › D. Full Stripe Checkout — Success Flow › D3: After subscription, get_subscription_status returns correct period dates
D3: skipped — not premium

[1A[2K[196/279] [chromium] › playwright_ui/premium-subscription.spec.ts:600:7 › D. Full Stripe Checkout — Success Flow › D4: Success redirect URL goes to /subscription/success route
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month
   ✅ Flutter initialized in 105183ms

[1A[2K[197/279] [chromium] › playwright_ui/premium-subscription.spec.ts:636:7 › E. Stripe Checkout — Declined Card Scenarios › E1: Declined card (4000...0002) shows error — user stays non-premium
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:636:7 › E. Stripe Checkout — Declined Card Scenarios › E1: Declined card (4000...0002) shows error — user stays non-premium
E1: skipped — buyer already premium

[1A[2K[198/279] [chromium] › playwright_ui/premium-subscription.spec.ts:687:7 › E. Stripe Checkout — Declined Card Scenarios › E2: Insufficient funds card (4000...9995) shows decline error
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:687:7 › E. Stripe Checkout — Declined Card Scenarios › E2: Insufficient funds card (4000...9995) shows decline error
E2: skipped — buyer premium

[1A[2K[199/279] [chromium] › playwright_ui/premium-subscription.spec.ts:722:7 › E. Stripe Checkout — Declined Card Scenarios › E3: Wrong CVC card (4000...0127) shows error
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:722:7 › E. Stripe Checkout — Declined Card Scenarios › E3: Wrong CVC card (4000...0127) shows error
E3: skipped — buyer premium

[1A[2K[200/279] [chromium] › playwright_ui/premium-subscription.spec.ts:756:7 › E. Stripe Checkout — Declined Card Scenarios › E4: After all declined attempts, isPremium remains false
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:756:7 › E. Stripe Checkout — Declined Card Scenarios › E4: After all declined attempts, isPremium remains false
E4: Buyer became premium — this is only unexpected if D1 was not run

[1A[2K[201/279] [chromium] › playwright_ui/premium-subscription.spec.ts:775:7 › F. 3DS Authentication for Subscription › F1: 3DS card (4000...3155) → approve → subscription becomes active
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:775:7 › F. 3DS Authentication for Subscription › F1: 3DS card (4000...3155) → approve → subscription becomes active
F1: skipped — buyer already premium

[1A[2K[202/279] [chromium] › playwright_ui/premium-subscription.spec.ts:827:7 › F. 3DS Authentication for Subscription › F2: 3DS card → cancel/fail authentication → isPremium stays false
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:827:7 › F. 3DS Authentication for Subscription › F2: 3DS card → cancel/fail authentication → isPremium stays false
F2: skipped — buyer already premium

[1A[2K[203/279] [chromium] › playwright_ui/premium-subscription.spec.ts:874:7 › G. Webhook Sync — Firestore State › G1: customer.subscription.created webhook sets isPremium=true on user doc
[1A[2K[204/279] [chromium] › playwright_ui/premium-subscription.spec.ts:890:7 › G. Webhook Sync — Firestore State › G2: Subscription doc has all required webhook-synced fields
[1A[2K[205/279] [chromium] › playwright_ui/premium-subscription.spec.ts:911:7 › G. Webhook Sync — Firestore State › G3: Webhook is idempotent — re-delivery does not create duplicate subscription docs
[1A[2K[206/279] [chromium] › playwright_ui/premium-subscription.spec.ts:931:7 › G. Webhook Sync — Firestore State › G4: invoice.payment_failed → subscription status becomes past_due
[1A[2K[207/279] [chromium] › playwright_ui/premium-subscription.spec.ts:955:7 › H. Double-Subscribe Guard › H1: create_subscription returns ALREADY_EXISTS when subscription active
[1A[2K[208/279] [chromium] › playwright_ui/premium-subscription.spec.ts:970:7 › H. Double-Subscribe Guard › H2: ALREADY_EXISTS error message is user-friendly
[1A[2K[209/279] [chromium] › playwright_ui/premium-subscription.spec.ts:991:7 › I. Cancel Subscription Flow › I1: cancel_subscription sets cancelAtPeriodEnd=true on subscription doc
[1A[2K[210/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1015:7 › I. Cancel Subscription Flow › I2: cancel_subscription returns not-found for non-subscriber
[1A[2K[211/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1022:7 › I. Cancel Subscription Flow › I3: cancel_subscription requires authentication
[1A[2K[212/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K  23) [chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:380:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:380:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-b3596-s-all-four-premium-benefits-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[213/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1047:7 › I. Cancel Subscription Flow › I5: Cancel confirmation dialog has btn-keep-premium and btn-confirm-cancel-subscription
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1047:7 › I. Cancel Subscription Flow › I5: Cancel confirmation dialog has btn-keep-premium and btn-confirm-cancel-subscription
I5: skipped — not premium or already cancelling

[1A[2K[214/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1087:7 › J. Platform Fee Waiver › J1: Non-premium buyer pays 2.5% platform fee at checkout
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1087:7 › J. Platform Fee Waiver › J1: Non-premium buyer pays 2.5% platform fee at checkout
J1: skipped — buyer is premium (fee is waived)

[1A[2K[215/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1115:7 › J. Platform Fee Waiver › J2: Premium buyer gets platform fee = 0
[1A[2K[216/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1139:7 › J. Platform Fee Waiver › J3: isPremium injected in checkout payload does NOT bypass fee
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1139:7 › J. Platform Fee Waiver › J3: isPremium injected in checkout payload does NOT bypass fee
J3: skipped — buyer is premium (injection test only meaningful for non-premium)

[1A[2K[217/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1171:7 › K. Chat Paywall Gate › K1: Non-premium buyer gets permission-denied from open_chat
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1171:7 › K. Chat Paywall Gate › K1: Non-premium buyer gets permission-denied from open_chat
K1: skipped — buyer is premium

[1A[2K[218/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1184:7 › K. Chat Paywall Gate › K2: Premium-check fires BEFORE product existence check
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1184:7 › K. Chat Paywall Gate › K2: Premium-check fires BEFORE product existence check
K2: skipped — buyer is premium

[1A[2K[219/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1197:7 › K. Chat Paywall Gate › K3: Chat paywall widget is shown in Flutter UI for non-premium buyer
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1197:7 › K. Chat Paywall Gate › K3: Chat paywall widget is shown in Flutter UI for non-premium buyer
K3: skipped — buyer is premium

[1A[2K[220/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1228:7 › L. Security Adversarial › L1: All three subscription endpoints reject unauthenticated requests
[1A[2K[221/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1235:7 › L. Security Adversarial › L2: open_chat rejects unauthenticated request
[1A[2K[222/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1240:7 › L. Security Adversarial › L3: Stripe webhook rejects requests without valid signature
[1A[2K[223/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1252:7 › L. Security Adversarial › L4: Stripe webhook rejects tampered signature
[1A[2K[224/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1265:7 › L. Security Adversarial › L5: cancel_subscription rejects when subscription is already cancelled
[1A[2K[225/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K  24) [chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:391:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:391:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-B-Sub-3b10e--Price-shows-CAD-7-86-month-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[226/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[227/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1341:7 › N. Reactivate Subscription › N1: reactivate_subscription sets cancelAtPeriodEnd=false
[1A[2K[228/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1371:7 › N. Reactivate Subscription › N2: reactivate_subscription requires authentication
[1A[2K[229/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1376:7 › N. Reactivate Subscription › N3: reactivate_subscription returns not-found for non-subscriber
[1A[2K[230/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1398:8 › O. Webhook Edge Cases › O1: invoice.payment_failed → subscription status becomes past_due
[1A[2K[231/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1419:8 › O. Webhook Edge Cases › O2: invoice.payment_succeeded keeps isPremium=true and advances expiresAt
[1A[2K[232/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1443:8 › O. Webhook Edge Cases › O3: past_due user loses premium access to gated features
[1A[2K[233/279] [chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state
[1A[2K[chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state
   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription
   ✅ Flutter initialized in 105045ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation
   ✅ Flutter initialized in 105148ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route
   ✅ Flutter initialized in 105096ms

[1A[2K[234/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[235/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state
   ✅ Flutter initialized in 105270ms

[1A[2K[236/279] [chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route (retry #1)
[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[237/279] [chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state (retry #1)
[1A[2K[chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state
   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription
   ✅ Flutter initialized in 105247ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation
   ✅ Flutter initialized in 105203ms

[1A[2K[chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route
   ✅ Flutter initialized in 105264ms

[1A[2K  25) [chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1036:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1036:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-I-Can-f9e0d-led-btn-cancel-subscription-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[238/279] [chromium] › playwright_ui/product-video-e2e.spec.ts:59:10 › Product Video Flow › T02: Validation - Oversized video
[1A[2K[239/279] [chromium] › playwright_ui/product-video-e2e.spec.ts:75:10 › Product Video Flow › T03: Validation - Overly long video
[1A[2K[240/279] [chromium] › playwright_ui/profile-management.spec.ts:25:7 › Profile Management › User can view profile page
[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:25:7 › Profile Management › User can view profile page
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  26) [chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1291:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1291:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-dbc94-ter-cancellation-navigation-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[241/279] [chromium] › playwright_ui/profile-management.spec.ts:58:7 › Profile Management › User can navigate to address management
[1A[2K[chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state
   ✅ Flutter initialized in 105220ms

[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:58:7 › Profile Management › User can navigate to address management
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  27) [chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1316:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/premium-subscription.spec.ts:1316:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/premium-subscription-M-Scr-53fa5--subscription-success-route-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[242/279] [chromium] › playwright_ui/profile-management.spec.ts:88:7 › Profile Management › User can navigate to orders from profile
[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:88:7 › Profile Management › User can navigate to orders from profile
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  28) [chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state 

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/product-video-e2e.spec.ts:18:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mlocator[39m[2m).[22mtoBeAttached[2m([22m[2m)[22m failed

    Locator: getByRole('button', { name: 'btn-home-settings' }).first()
    Expected: attached
    Timeout: 60000ms
    Error: element(s) not found

    Call log:
    [2m  - Expect "toBeAttached" with timeout 60000ms[22m
    [2m  - waiting for getByRole('button', { name: 'btn-home-settings' }).first()[22m


       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/product-video-e2e.spec.ts:18:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/product-video-e2e-Product--07640-nd-verify-playback-UI-state-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[243/279] [chromium] › playwright_ui/profile-management.spec.ts:115:7 › Profile Management › Privacy policy is accessible from profile
[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:115:7 › Profile Management › Privacy policy is accessible from profile
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:25:7 › Profile Management › User can view profile page
   ✅ Flutter initialized in 150204ms

[1A[2K[244/279] [chromium] › playwright_ui/rate-limiting.spec.ts:28:7 › Rate Limiting › Rapid checkout requests trigger rate limiting
[1A[2K[245/279] [chromium] › playwright_ui/rate-limiting.spec.ts:28:7 › Rate Limiting › Rapid checkout requests trigger rate limiting (retry #1)
[1A[2K  29) [chromium] › playwright_ui/rate-limiting.spec.ts:28:7 › Rate Limiting › Rapid checkout requests trigger rate limiting 

    Error: [2mexpect([22m[31mreceived[39m[2m).[22mtoBeGreaterThan[2m([22m[32mexpected[39m[2m)[22m

    Expected: > [32m0[39m
    Received:   [31m0[39m

      49 |
      50 |     // At least one request should be rate-limited OR all fail (already at limit)
    > 51 |     expect(errors.length).toBeGreaterThan(0);
         |                           ^
      52 |     console.log(`Rate limit test: ${successes.length} success, ${errors.length} errors (${rateLimitErrors.length} rate-limit specific)`);
      53 |   });
      54 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/rate-limiting.spec.ts:51:27

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mreceived[39m[2m).[22mtoBeGreaterThan[2m([22m[32mexpected[39m[2m)[22m

    Expected: > [32m0[39m
    Received:   [31m0[39m

      49 |
      50 |     // At least one request should be rate-limited OR all fail (already at limit)
    > 51 |     expect(errors.length).toBeGreaterThan(0);
         |                           ^
      52 |     console.log(`Rate limit test: ${successes.length} success, ${errors.length} errors (${rateLimitErrors.length} rate-limit specific)`);
      53 |   });
      54 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/rate-limiting.spec.ts:51:27

    attachment #1: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/rate-limiting-Rate-Limitin-a122f-uests-trigger-rate-limiting-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/rate-limiting-Rate-Limitin-a122f-uests-trigger-rate-limiting-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[246/279] [chromium] › playwright_ui/rate-limiting.spec.ts:55:7 › Rate Limiting › Multiple rapid API calls do not crash the service
[1A[2K[247/279] [chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve
[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:58:7 › Profile Management › User can navigate to address management
   ✅ Flutter initialized in 150168ms

[1A[2K[248/279] [chromium] › playwright_ui/return-request.spec.ts:99:7 › Return Request Flow (Flow 6) › Cannot request return for digital products
[1A[2K[249/279] [chromium] › playwright_ui/search-products.spec.ts:20:7 › Search & Discovery › Home page shows product cards
[1A[2K[chromium] › playwright_ui/search-products.spec.ts:20:7 › Search & Discovery › Home page shows product cards
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:88:7 › Profile Management › User can navigate to orders from profile
   ✅ Flutter initialized in 150103ms

[1A[2K[250/279] [chromium] › playwright_ui/search-products.spec.ts:39:7 › Search & Discovery › Search bar is accessible on home page
[1A[2K[chromium] › playwright_ui/search-products.spec.ts:39:7 › Search & Discovery › Search bar is accessible on home page
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve
Order Items: [
  {
    "sellerAddress": {
      "country": "Canada",
      "city": "Montreal",
      "postalCode": "H2Y 1A1",
      "state": "QC",
      "street": "100 Rue Saint-Paul"
    },
    "widthCm": null,
    "shippedAt": "2026-03-01T01:41:36.839287Z",
    "price": 34.99,
    "deliveredAt": null,
    "categoryId": 3,
    "weightKg": 0.3,
    "imageUrls": [
      "https://orignagta-dev.web.app/assets/icons/icon-192.png"
    ],
    "trackingNumber": "TEST-TRACK-123",
    "supplier": null,
    "isDigital": false,
    "buyerNote": null,
    "deliveryOptions": [
      "standard"
    ],
    "confirmedByBuyer": false,
    "description": "Artisanal wool scarf from Quebec.",
    "quantity": 1,
    "lengthCm": null,
    "isInternational": false,
    "name": "Handmade Quebec Scarf",
    "carrier": "Canada Post",
    "freeShipping": false,
    "sellerId": "eVxwL5SfEATPnw1zhWYaUdGx8MD2",
    "status": "shipped",
    "shipFromCountry": "Canada",
    "isLocalDeliveryOnly": false,
    "isPerishable": false,
    "cartItemId": "f982f9da-033a-4bdc-a1ed-05539f988e8d",
    "heightCm": null,
    "productId": "product_001",
    "isSmallSupplier": false,
    "supplierType": null,
    "taxCode": "txcd_10201000"
  }
]

[1A[2K[251/279] [chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve (retry #1)
[1A[2K[chromium] › playwright_ui/profile-management.spec.ts:115:7 › Profile Management › Privacy policy is accessible from profile
   ✅ Flutter initialized in 150100ms

[1A[2K[252/279] [chromium] › playwright_ui/search-products.spec.ts:70:7 › Search & Discovery › Product card click navigates to product detail
[1A[2K[chromium] › playwright_ui/search-products.spec.ts:70:7 › Search & Discovery › Product card click navigates to product detail
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve
Order Items: [
  {
    "isDigital": false,
    "freeShipping": false,
    "isSmallSupplier": false,
    "isLocalDeliveryOnly": false,
    "imageUrls": [
      "https://orignagta-dev.web.app/assets/icons/icon-192.png"
    ],
    "buyerNote": null,
    "supplier": null,
    "carrier": "Canada Post",
    "supplierType": null,
    "description": "Artisanal wool scarf from Quebec.",
    "productId": "product_001",
    "deliveredAt": null,
    "sellerId": "eVxwL5SfEATPnw1zhWYaUdGx8MD2",
    "weightKg": 0.3,
    "quantity": 1,
    "widthCm": null,
    "shipFromCountry": "Canada",
    "cartItemId": "1c466ba2-0bb7-4996-8249-089813fa5762",
    "heightCm": null,
    "deliveryOptions": [
      "standard"
    ],
    "sellerAddress": {
      "state": "QC",
      "country": "Canada",
      "street": "100 Rue Saint-Paul",
      "city": "Montreal",
      "postalCode": "H2Y 1A1"
    },
    "lengthCm": null,
    "isPerishable": false,
    "taxCode": "txcd_10201000",
    "categoryId": 3,
    "trackingNumber": "TEST-TRACK-123",
    "status": "shipped",
    "confirmedByBuyer": false,
    "shippedAt": "2026-03-01T01:42:33.466048Z",
    "name": "Handmade Quebec Scarf",
    "isInternational": false,
    "price": 34.99
  }
]

[1A[2K  30) [chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve 

    Error: create_return_request failed: Item must be marked as delivered before requesting a return

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/return-request.spec.ts:72:26

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: create_return_request failed: Item must be marked as delivered before requesting a return

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/return-request.spec.ts:72:26

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/return-request-Return-Requ-8ae82-turn-and-seller-can-approve-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[253/279] [chromium] › playwright_ui/search-products.spec.ts:100:7 › Search & Discovery › Home page scroll loads more products
[1A[2K[chromium] › playwright_ui/search-products.spec.ts:100:7 › Search & Discovery › Home page scroll loads more products
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/search-products.spec.ts:20:7 › Search & Discovery › Home page shows product cards
   ✅ Flutter initialized in 150147ms

[1A[2K[254/279] [chromium] › playwright_ui/seller-flow.spec.ts:24:9 › PW IT Replica — Seller Flow › Complete Seller Journey
[1A[2K[chromium] › playwright_ui/seller-flow.spec.ts:24:9 › PW IT Replica — Seller Flow › Complete Seller Journey
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/search-products.spec.ts:39:7 › Search & Discovery › Search bar is accessible on home page
   ✅ Flutter initialized in 150123ms

[1A[2K[255/279] [chromium] › playwright_ui/seller-product-management.spec.ts:26:7 › Seller Product Management › Seller can navigate to add product page
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:26:7 › Seller Product Management › Seller can navigate to add product page
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/search-products.spec.ts:70:7 › Search & Discovery › Product card click navigates to product detail
   ✅ Flutter initialized in 150086ms

[1A[2K[256/279] [chromium] › playwright_ui/seller-product-management.spec.ts:46:7 › Seller Product Management › Product form validates required fields
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:46:7 › Seller Product Management › Product form validates required fields
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/search-products.spec.ts:100:7 › Search & Discovery › Home page scroll loads more products
   ✅ Flutter initialized in 150197ms

[1A[2K[257/279] [chromium] › playwright_ui/seller-product-management.spec.ts:76:7 › Seller Product Management › Product form accepts valid input
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:76:7 › Seller Product Management › Product form accepts valid input
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/seller-flow.spec.ts:24:9 › PW IT Replica — Seller Flow › Complete Seller Journey
   ✅ Flutter initialized in 150183ms

[1A[2K[258/279] [chromium] › playwright_ui/seller-product-management.spec.ts:141:7 › Seller Product Management › Digital product toggle works
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:141:7 › Seller Product Management › Digital product toggle works
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:26:7 › Seller Product Management › Seller can navigate to add product page
   ✅ Flutter initialized in 150088ms

[1A[2K[259/279] [chromium] › playwright_ui/seller-registration.spec.ts:17:7 › Seller Registration › Seller can check Stripe Connect account status
[1A[2K[260/279] [chromium] › playwright_ui/seller-registration.spec.ts:33:7 › Seller Registration › Seller can request account link for onboarding
[1A[2K[261/279] [chromium] › playwright_ui/seller-registration.spec.ts:56:7 › Seller Registration › Buyer cannot access seller-only endpoints
[1A[2K[262/279] [chromium] › playwright_ui/seller-registration.spec.ts:68:7 › Seller Registration › Unauthenticated request to seller endpoints is rejected
[1A[2K[263/279] [chromium] › playwright_ui/shipping-approval.spec.ts:30:7 › Shipping Approval › Seller can submit shipping cost for an order
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:46:7 › Seller Product Management › Product form validates required fields
   ✅ Flutter initialized in 150079ms

[1A[2K[264/279] [chromium] › playwright_ui/shipping-approval.spec.ts:53:7 › Shipping Approval › Only the order seller can submit shipping cost
[1A[2K[265/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:27:7 › Shipping Calculation › Checkout includes tax calculation for Ontario address
[1A[2K[266/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:50:7 › Shipping Calculation › Order total = subtotal + tax + shipping
[1A[2K[267/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:64:7 › Shipping Calculation › Currency is always CAD
[1A[2K[268/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:75:7 › Shipping Calculation › Multiple quantity correctly multiplies subtotal
[1A[2K[chromium] › playwright_ui/shipping-calculation.spec.ts:75:7 › Shipping Calculation › Multiple quantity correctly multiplies subtotal
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[269/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:75:7 › Shipping Calculation › Multiple quantity correctly multiplies subtotal (retry #1)
[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K  31) [chromium] › playwright_ui/shipping-calculation.spec.ts:75:7 › Shipping Calculation › Multiple quantity correctly multiplies subtotal 

    Error: Product test_ship_stock_1772329647510 not found in Firestore.

       at api-helpers.ts:396

      394 |   const prodDoc = await readDoc(`products/${productId}`, token);
      395 |   const product = parseDoc(prodDoc);
    > 396 |   if (!product) throw new Error(`Product ${productId} not found in Firestore.`);
          |                       ^
      397 |
      398 |   const buyerDoc = await readDoc(`users/${buyerUid}`, token);
      399 |   const buyer = parseDoc(buyerDoc);
        at buildCheckoutPayload (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:396:23)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/shipping-calculation.spec.ts:98:31

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: create_checkout_session failed: Product test_ship_stock_1772329651236 is not active and cannot be purchased

       at api-helpers.ts:320

      318 |         continue;
      319 |       }
    > 320 |       throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
          |             ^
      321 |     }
      322 |     return body.result || body;
      323 |   }
        at callOk (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/api-helpers.ts:320:13)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/shipping-calculation.spec.ts:95:23

    attachment #1: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/shipping-calculation-Shipp-6b698-rrectly-multiplies-subtotal-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/shipping-calculation-Shipp-6b698-rrectly-multiplies-subtotal-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[270/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:111:7 › Shipping Calculation › Quebec address applies QST+GST tax rate (~14.975%)
[1A[2K[271/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:129:7 › Shipping Calculation › Alberta address applies GST-only tax rate (5%)
[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:76:7 › Seller Product Management › Product form accepts valid input
   ✅ Flutter initialized in 150048ms

[1A[2K[272/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:147:7 › Shipping Calculation › International seller uses national ceiling shipping cost ($26.99)
[1A[2K[273/279] [chromium] › playwright_ui/smoke-home-profile.spec.ts:25:9 › PW IT Replica — Smoke Home + Profile (admin) › replica
[1A[2K[274/279] [chromium] › playwright_ui/shipping-calculation.spec.ts:147:7 › Shipping Calculation › International seller uses national ceiling shipping cost ($26.99) (retry #1)
[1A[2K[chromium] › playwright_ui/smoke-home-profile.spec.ts:25:9 › PW IT Replica — Smoke Home + Profile (admin) › replica
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K  32) [chromium] › playwright_ui/shipping-calculation.spec.ts:147:7 › Shipping Calculation › International seller uses national ceiling shipping cost ($26.99) 

    Error: [2mexpect([22m[31mreceived[39m[2m).[22mtoBe[2m([22m[32mexpected[39m[2m) // Object.is equality[22m

    Expected: [32m2699[39m
    Received: [31m0[39m

      155 |
      156 |     // National ceiling is $26.99 = 2699 cents
    > 157 |     expect(order.shippingCostCents).toBe(2699);
          |                                     ^
      158 |   });
      159 | });
      160 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/shipping-calculation.spec.ts:157:37

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    Error: [2mexpect([22m[31mreceived[39m[2m).[22mtoBe[2m([22m[32mexpected[39m[2m) // Object.is equality[22m

    Expected: [32m2699[39m
    Received: [31m0[39m

      155 |
      156 |     // National ceiling is $26.99 = 2699 cents
    > 157 |     expect(order.shippingCostCents).toBe(2699);
          |                                     ^
      158 |   });
      159 | });
      160 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/shipping-calculation.spec.ts:157:37

    attachment #1: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/shipping-calculation-Shipp-f1aee-eiling-shipping-cost-26-99--chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/shipping-calculation-Shipp-f1aee-eiling-shipping-cost-26-99--chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[275/279] [chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[276/279] [chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/seller-product-management.spec.ts:141:7 › Seller Product Management › Digital product toggle works
   ✅ Flutter initialized in 150059ms

[1A[2K[277/279] [chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)
   ✅ Flutter initialized in 89875ms

[1A[2K[278/279] [chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart) (retry #1)
[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed
   ✅ Flutter initialized in 89588ms

[1A[2K[279/279] [chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed (retry #1)
[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state
   ✅ Flutter initialized in 89372ms

[1A[2K[280/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state (retry #1)
[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/smoke-home-profile.spec.ts:25:9 › PW IT Replica — Smoke Home + Profile (admin) › replica
   ✅ Flutter initialized in 150099ms

[1A[2K[281/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)
   ✅ Flutter initialized in 90357ms

[1A[2K  33) [chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart) 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:101:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:101:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0447f-fy-section-not-add-to-cart--chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[282/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt
⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed
   ✅ Flutter initialized in 90062ms

[1A[2K  34) [chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:122:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:122:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--7b917-rrectly-when-not-subscribed-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[283/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)
   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state
   ✅ Flutter initialized in 90177ms

[1A[2K  35) [chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:140:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:140:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--c61e6-and-toggles-to-cancel-state-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[284/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me
   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)
   ✅ Flutter initialized in 84800ms

[1A[2K[285/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle) (retry #1)
[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt
   ✅ Flutter initialized in 89795ms

[1A[2K[286/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt (retry #1)
[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)
   ✅ Flutter initialized in 89858ms

[1A[2K[287/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me) (retry #1)
[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me
   ✅ Flutter initialized in 89797ms

[1A[2K[288/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me (retry #1)
[1A[2K   ⌨️  Logging in as yr62813@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)
   ✅ Flutter initialized in 89892ms

[1A[2K  36) [chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle) 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:171:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:171:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--994c9-d-time-unsubscribes-toggle--chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[289/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt
   ✅ Flutter initialized in 90339ms

[1A[2K  37) [chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeVisible: Target page, context or browser has been closed

      198 |
      199 |     const notifyBtn = page.locator('[aria-label="product_notify_me_button"]');
    > 200 |     await expect(notifyBtn).toBeVisible({ timeout: 15_000 });
          |                             ^
      201 |     await notifyBtn.click();
      202 |     await page.waitForTimeout(2_000);
      203 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:200:29

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeVisible: Target page, context or browser has been closed

      198 |
      199 |     const notifyBtn = page.locator('[aria-label="product_notify_me_button"]');
    > 200 |     await expect(notifyBtn).toBeVisible({ timeout: 15_000 });
          |                             ^
      201 |     await notifyBtn.click();
      202 |     await page.waitForTimeout(2_000);
      203 |
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:200:29

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--0c88a-Notify-Me-sees-login-prompt-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[290/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:378:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.4 Subscribe with variantKey works (variant-level subscription)
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)
   ✅ Flutter initialized in 90405ms

[1A[2K[291/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:408:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.5 Subscribe without variantKey (product-level) works
[1A[2K  38) [chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me) 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:215:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:215:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--dbd37--Add-to-Cart-not-Notify-Me--chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[292/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:420:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.6 Unauthenticated subscribe is rejected with unauthenticated error
[1A[2K[293/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:429:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.7 Subscribe to non-existent product is rejected
[1A[2K[294/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:438:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.8 Subscribe to in-stock product is rejected (must be OOS)
[1A[2K[295/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:516:7 › 4. Security — Adversarial Scenarios › 4.2 Expired auth token is rejected
[1A[2K[296/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:526:7 › 4. Security — Adversarial Scenarios › 4.3 productId injection attempt is safely rejected
[1A[2K[297/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:537:7 › 4. Security — Adversarial Scenarios › 4.4 Subscribe with excessively long variantKey is rejected
[1A[2K[298/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:547:7 › 4. Security — Adversarial Scenarios › 4.5 Firestore direct write to stock_notifications is blocked by rules
[1A[2K[299/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:25:7 › Stripe Payment Flow › Full checkout → Stripe payment → order confirmed
[1A[2K[300/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:455:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.9 Missing productId is rejected with invalid-argument
[1A[2K[301/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:464:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.10 Unsubscribe when not subscribed is idempotent (no error)
[1A[2K[302/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:498:7 › 4. Security — Adversarial Scenarios › 4.1 Buyer cannot unsubscribe another user's notification
[1A[2K[303/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:40:7 › Stripe Payment Flow › Order document has correct structure after payment
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me
   ✅ Flutter initialized in 90260ms

[1A[2K  39) [chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:231:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:231:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-1-UI-—-Notify--3fb77-oduct-message-not-Notify-Me-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[304/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:66:7 › Stripe Payment Flow › Stock decremented by exact ordered quantity after payment
[1A[2K[305/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:90:7 › Stripe Payment Flow › Checkout URL redirects to Stripe hosted page
[1A[2K[306/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:104:7 › Stripe Payment Flow › Duplicate checkout with same idempotency key returns same order
[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart
   ✅ Flutter initialized in 89879ms

[1A[2K[307/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart (retry #1)
[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K   ⌨️  Logging in as yuniorrodriguezo460@gmail.com...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 120000ms)...

[1A[2K[308/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:120:7 › Stripe Payment Flow › [BONUS] Order expiresAt is within 6-day authorization window
[1A[2K[309/279] (retries) [chromium] › playwright_ui/stripe-payment.spec.ts:142:7 › Stripe Payment Flow › [BONUS] Cart is cleared after successful order creation
[1A[2K[310/279] (retries) [chromium] › playwright_ui/trending-products.spec.ts:59:9 › Trending Products flows › Premium user can toggle Trending Products notifications
[1A[2K[chromium] › playwright_ui/trending-products.spec.ts:59:9 › Trending Products flows › Premium user can toggle Trending Products notifications
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K⏳ Waiting for Flutter Web to initialize (timeout: 180000ms)...

[1A[2K[311/279] (retries) [chromium] › playwright_ui/trending-products.spec.ts:108:9 › Trending Products flows › Admin can mark a product as trending programmatically
[1A[2K[chromium] › playwright_ui/trending-products.spec.ts:108:9 › Trending Products flows › Admin can mark a product as trending programmatically
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[312/279] (retries) [chromium] › playwright_ui/warehouse-multi-location.spec.ts:63:7 › Warehouse: multi-location seller flow › T1: seller creates a warehouse and it is persisted in Firestore
[1A[2K[313/279] (retries) [chromium] › playwright_ui/warehouse-multi-location.spec.ts:90:7 › Warehouse: multi-location seller flow › T2: seller can have multiple warehouses and list them all
[1A[2K[314/279] (retries) [chromium] › playwright_ui/warehouse-multi-location.spec.ts:120:7 › Warehouse: multi-location seller flow › T3: duplicate sellerSku products cannot coexist — one is blocked on write
[1A[2K[chromium] › playwright_ui/warehouse-multi-location.spec.ts:120:7 › Warehouse: multi-location seller flow › T3: duplicate sellerSku products cannot coexist — one is blocked on write
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[315/279] (retries) [chromium] › playwright_ui/warehouse-multi-location.spec.ts:169:7 › Warehouse: multi-location seller flow › T4: product document has shipFromCity and shipFromProvince after warehouse-based creation
[1A[2K[chromium] › playwright_ui/warehouse-multi-location.spec.ts:169:7 › Warehouse: multi-location seller flow › T4: product document has shipFromCity and shipFromProvince after warehouse-based creation
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[316/279] (retries) [chromium] › playwright_ui/warehouse-multi-location.spec.ts:220:7 › Warehouse: multi-location seller flow › T5: inventoryLevels subcollection stores per-warehouse stock; stockQuantity equals sum
[1A[2K[chromium] › playwright_ui/warehouse-multi-location.spec.ts:220:7 › Warehouse: multi-location seller flow › T5: inventoryLevels subcollection stores per-warehouse stock; stockQuantity equals sum
writeDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K[chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart
   ✅ Flutter initialized in 90248ms

[1A[2K  40) [chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart 

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:294:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium/error-context.md

    Retry #1 ───────────────────────────────────────────────────────────────────────────────────────

    [31mTest timeout of 90000ms exceeded.[39m

    Error: expect.toBeAttached: Target page, context or browser has been closed

       at flutter-helpers.ts:132

      130 |     //   logged out → shows "Connexion requise" / "Login required" dialog
      131 |     const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    > 132 |     await expect(settingsBtn).toBeAttached({ timeout: 60000 });
          |                               ^
      133 |     await settingsBtn.click();
      134 |
      135 |     // Check for sign-in dialog button (unauthenticated state)
        at ensureLoggedInAsAdmin (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/flutter-helpers.ts:132:31)
        at loginAndNavigate (/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:87:3)
        at /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e/playwright_ui/stock-notif.spec.ts:294:5

    attachment #1: screenshot (image/png) ──────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium-retry1/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium-retry1/error-context.md

    attachment #3: trace (application/zip) ─────────────────────────────────────────────────────────
    ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium-retry1/trace.zip
    Usage:

        npx playwright show-trace ../../../../Desktop/origna-screenshots/dev/stock-notif-2-UI-—-Stock-R-5bda2--restored-shows-Add-to-Cart-chromium-retry1/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────


[1A[2K[317/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:350:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.1 Subscribe to OOS product returns subscribed:true
[1A[2K[318/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:359:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.2 Duplicate subscribe is idempotent (no error, no duplicate doc)
[1A[2K[319/279] (retries) [chromium] › playwright_ui/stock-notif.spec.ts:369:7 › 3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.3 Unsubscribe returns unsubscribed:true
[1A[2K[chromium] › playwright_ui/stripe-payment.spec.ts:142:7 › Stripe Payment Flow › [BONUS] Cart is cleared after successful order creation
Still on Stripe Checkout after 45s — payment may still be processing

[1A[2K[chromium] › playwright_ui/trending-products.spec.ts:59:9 › Trending Products flows › Premium user can toggle Trending Products notifications
   ✅ Flutter initialized in 150075ms

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2KwriteDoc using token length: 940, prefix: eyJhbGciOi...

[1A[2K  Slow test file: [chromium] › playwright_ui/order-cancellation-refund.spec.ts (6.2m)
  Consider running tests from slow files in parallel. See: https://playwright.dev/docs/test-parallel
  39 failed
    [chromium] › playwright_ui/admin-panel.spec.ts:32:9 › PW IT Replica — Admin Panel Flow › T01: Access Control — Non-admin cannot access admin panel 
    [chromium] › playwright_ui/admin-panel.spec.ts:80:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T02: Navigate to Admin Panel via Profile 
    [chromium] › playwright_ui/admin-panel.spec.ts:93:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T03: Admin Tab — Sellers list visibility 
    [chromium] › playwright_ui/admin-panel.spec.ts:105:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T04: Admin Tab — Users search functionality 
    [chromium] › playwright_ui/admin-panel.spec.ts:120:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T05: Admin Tab — Orders management view 
    [chromium] › playwright_ui/admin-panel.spec.ts:132:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T06: Admin Tab — Products review queue 
    [chromium] › playwright_ui/admin-panel.spec.ts:143:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T07: Admin Tab — Payments and payouts 
    [chromium] › playwright_ui/admin-panel.spec.ts:154:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T08: Admin Tab — Security alerts and logs 
    [chromium] › playwright_ui/admin-panel.spec.ts:165:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T09: Admin Action — View Seller Detail 
    [chromium] › playwright_ui/admin-panel.spec.ts:176:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T10: Admin UI — Tab persistence after refresh 
    [chromium] › playwright_ui/admin-panel.spec.ts:196:13 › PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibility 
    [chromium] › playwright_ui/multi-seller-orders.spec.ts:87:7 › Multi-Seller Orders › Per-item status tracking works for multi-item order 
    [chromium] › playwright_ui/new-notification-features.spec.ts:93:7 › New Notification Features E2E › Chat message notification is triggered 
    [chromium] › playwright_ui/order-notifications.spec.ts:39:7 › Order Notifications › Buyer receives notification when individual items are shipped 
    [chromium] › playwright_ui/order-notifications.spec.ts:75:7 › Order Notifications › Buyer receives notification when individual items are delivered 
    [chromium] › playwright_ui/order-notifications.spec.ts:116:7 › Order Notifications › Local pickup order receives "Ready for Pickup" notification 
    [chromium] › playwright_ui/order-notifications.spec.ts:205:7 › Order Notifications › Seller receives notification when a return is requested 
    [chromium] › playwright_ui/password-reset.spec.ts:8:7 › Password Reset Routing › should render ResetPasswordScreen when mode=resetPassword is in URL 
    [chromium] › playwright_ui/password-reset.spec.ts:18:7 › Password Reset Routing › should show error and Go to Login when oobCode is invalid/expired 
    [chromium] › playwright_ui/premium-subscription.spec.ts:342:7 › B. Subscription Screen UI › B1: Subscription screen renders for non-premium buyer 
    [chromium] › playwright_ui/premium-subscription.spec.ts:362:7 › B. Subscription Screen UI › B2: Upgrade button semantic label is btn-subscribe-premium 
    [chromium] › playwright_ui/premium-subscription.spec.ts:378:7 › B. Subscription Screen UI › B3: Subscription screen lists all four premium benefits 
    [chromium] › playwright_ui/premium-subscription.spec.ts:389:7 › B. Subscription Screen UI › B4: Price shows CAD $7.86/month 
    [chromium] › playwright_ui/premium-subscription.spec.ts:1027:7 › I. Cancel Subscription Flow › I4: Cancel button in subscription screen is labelled btn-cancel-subscription 
    [chromium] › playwright_ui/premium-subscription.spec.ts:1289:7 › M. Screen Rendering › M1: SubscriptionCancelScreen renders after cancellation navigation 
    [chromium] › playwright_ui/premium-subscription.spec.ts:1314:7 › M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success route 
    [chromium] › playwright_ui/product-video-e2e.spec.ts:24:9 › Product Video Flow › T01: Upload valid video and verify playback UI state 
    [chromium] › playwright_ui/rate-limiting.spec.ts:28:7 › Rate Limiting › Rapid checkout requests trigger rate limiting 
    [chromium] › playwright_ui/return-request.spec.ts:33:7 › Return Request Flow (Flow 6) › Buyer can request return and seller can approve 
    [chromium] › playwright_ui/shipping-calculation.spec.ts:75:7 › Shipping Calculation › Multiple quantity correctly multiplies subtotal 
    [chromium] › playwright_ui/shipping-calculation.spec.ts:147:7 › Shipping Calculation › International seller uses national ceiling shipping cost ($26.99) 
    [chromium] › playwright_ui/stock-notif.spec.ts:100:7 › 1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart) 
    [chromium] › playwright_ui/stock-notif.spec.ts:116:7 › 1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribed 
    [chromium] › playwright_ui/stock-notif.spec.ts:134:7 › 1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel state 
    [chromium] › playwright_ui/stock-notif.spec.ts:166:7 › 1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle) 
    [chromium] › playwright_ui/stock-notif.spec.ts:194:7 › 1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login prompt 
    [chromium] › playwright_ui/stock-notif.spec.ts:214:7 › 1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me) 
    [chromium] › playwright_ui/stock-notif.spec.ts:228:7 › 1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Me 
    [chromium] › playwright_ui/stock-notif.spec.ts:292:7 › 2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cart 
  1 flaky
    [chromium] › playwright_ui/order-lifecycle.spec.ts:93:7 › Order Lifecycle › Buyer cannot update order status (only seller/admin can) 
  38 skipped
  201 passed (1.4h)
❌ ERROR: Playwright E2E tests failed on dev.
error: failed to push some refs to 'https://github.com/yunior123/origna_gta.git'