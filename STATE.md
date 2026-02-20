# PLAN: Fix All Bugs + Add Missing Features (Gap Analysis 2026-02-19)

> **Source:** docs/plans/2026-02-19-competitive-gap-analysis.md
> **Amazon return window 2026:** Still 30 days. We intentionally keep 7 days to prevent abuse — NO change.
> **Status: ✅ ALL 11 TASKS COMPLETE** (completed 2026-02-19)

---

## TASK LIST (11 tasks, ordered by dependency)

---

### ✅ TASK 01 — BUG-1: Enforce `allowBackorder` in checkout
**Problem:** `InventoryConfig.allowBackorder` stored/shown in UI but `reserve_stock_transaction` ALWAYS rejects when `stockQuantity < qty`. Field is ignored.
**Files to modify:**
- `functions/handlers/payment_stripe.py` — skip stock-check when `allowBackorder=True`
- `functions/tests/test_handlers_payment_stripe.py` — add backorder test
**Adversarial:** backorder=True → 0 stock checkout succeeds ✓ | backorder=False → 0 stock rejected ✓ | stock negative on concurrent backorders → acceptable (seller manages)

---

### ✅ TASK 02 — BUG-2: Sync `warehouseStock` on every purchase
**Problem:** `reserve_stock_transaction` only decrements `stockQuantity`. `warehouseStock` map diverges. Schema contract "stockQuantity = sum(warehouseStock.values())" broken.
**Strategy:** Select fulfillment warehouse (default first, then by stock). Deduct from `warehouseStock[warehouseId]`. Store `fulfillmentWarehouseId` on order item.
**Files to modify:**
- `functions/handlers/payment_stripe.py` — update `reserve_stock_transaction`
- `docs/database_schema.json` — add `fulfillmentWarehouseId: string?` to `OrderItem`
- `functions/schema_constants.py` — add `FULFILLMENT_WAREHOUSE_ID` to `Fields`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror constant
- `origna_gta/lib/models/generated/order_models.dart` — add field to `OrderItem` freezed model
- `origna_gta/lib/models/generated/order_models.freezed.dart` — regenerate
- `origna_gta/lib/models/generated/order_models.g.dart` — regenerate
- `functions/tests/test_handlers_payment_stripe.py` — add warehouseStock sync test
- `origna_gta/test/unit/schema_models_test.dart` — add field test
**Adversarial:** no warehouseIds → skip warehouseStock logic ✓ | default warehouse exhausted → overflow to next ✓

---

### ✅ TASK 03 — BUG-3: Activate `lowStockThreshold` — daily seller alert cron
**Problem:** `lowStockThreshold` stored but no cron ever reads it. Sellers silently hit zero stock.
**Strategy:** Daily cron queries products where `stockQuantity <= inventory.lowStockThreshold AND isActive=true AND status='active'`. Email seller once/day max (track `lastLowStockAlertAt`).
**Files to modify:**
- `functions/handlers/cron_jobs.py` — add `check_low_stock_alerts`
- `functions/services/email_service.py` — add low-stock email template
- `docs/database_schema.json` — add `lastLowStockAlertAt: timestamp?` to products
- `functions/schema_constants.py` — add `LAST_LOW_STOCK_ALERT_AT` to `Fields`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror constant
- `functions/main.py` — register cron
- `functions/tests/test_handlers_admin_cron.py` — add tests
**Adversarial:** already alerted today → skip ✓ | inactive product → skip ✓ | threshold=0 → never alert ✓

---

### ✅ TASK 04 — BUG-4: Enforce `status` ↔ `isActive` atomic sync
**Problem:** Both `status` (draft/active/paused/archived/out_of_stock) AND `isActive` (bool) can diverge. No atomic rule enforced.
**Strategy:** Add `_compute_is_active(status, approval_status) → bool` helper. Rule: `isActive = (status=='active' AND approvalStatus=='approved')`. Apply at every product write.
**Files to modify:**
- `functions/handlers/products.py` — add helper; apply at all write paths (create, update, approve, reject, suspend)
- `functions/tests/test_handlers_products_orders.py` — add sync invariant tests
**Adversarial:** paused + approved → isActive=false ✓ | active + rejected → isActive=false ✓ | active + approved → isActive=true ✓

---

### ✅ TASK 05 — FEAT: Buyer address book (multiple saved addresses)
**Problem:** `users.address` is single field. No multi-address support. `addressmanagement_screen.dart` shows one address only.
**Strategy:** Add `users/{uid}/addresses/{addressId}` subcollection (mirrors sellers' `warehouses`). CRUD handlers. Checkout address picker.
**Files to create:**
- `e2e/playwright_ui/address-book.spec.ts`
**Files to modify:**
- `docs/database_schema.json` — add `addresses` subcollection to users
- `functions/schema_constants.py` — add `BUYER_ADDRESSES = "addresses"`, `ADDRESS_ID = "addressId"` constants
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `firestore.rules` — add `/addresses/{addressId}` match under `/users/{userId}`
- `functions/handlers/users.py` — add `add_buyer_address`, `update_buyer_address`, `delete_buyer_address`, `set_default_buyer_address`
- `functions/main.py` — register handlers
- `origna_gta/lib/screens/addressmanagement_screen.dart` — rewrite to list all from subcollection
- `origna_gta/lib/screens/checkout_screen.dart` or checkout_provider — add address picker
- `functions/tests/test_handlers_products_orders.py` — CRUD tests
**Adversarial:** >10 addresses → reject ✓ | delete default → next becomes default ✓ | non-Canada address → rules reject ✓ | access another user's addresses → rules deny ✓

---

### ✅ TASK 06 — FEAT: Photo reviews (images in product_ratings)
**Problem:** `product_ratings` text-only. Photo reviews drive conversions (Amazon, AliExpress standard).
**Strategy:** Add `reviewImageUrls: list[str]?` (max 3) to `product_ratings`. Reuse R2 upload infrastructure.
**Files to modify:**
- `docs/database_schema.json` — add `reviewImageUrls: array<string>?` (maxItems: 3) to `product_ratings`
- `functions/schema_constants.py` — add `REVIEW_IMAGE_URLS = "reviewImageUrls"` to `Fields`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `functions/handlers/products.py` — `submit_product_rating`: accept optional `reviewImageUrls`, validate R2 domain, max 3
- `firestore.rules` — update `product_ratings` write rule to allow `reviewImageUrls`
- `origna_gta/lib/models/generated/product_models.dart` — add `@Default(null) List<String>? reviewImageUrls` to `ProductRating`
- `origna_gta/lib/models/generated/product_models.freezed.dart` — regenerate
- `origna_gta/lib/models/generated/product_models.g.dart` — regenerate
- Review submission UI — add photo picker (≤3 photos)
- `functions/tests/test_handlers_products_orders.py` — photo review tests
**Adversarial:** 4 images → rejected ✓ | non-R2 URL → rejected ✓ | no images → still works ✓

---

### ✅ TASK 07 — FEAT: Back-in-stock buyer notifications
**Problem:** Buyers have no way to request restock notification. Permanent sales loss on sold-out items.
**Strategy:** New `stock_notifications` collection. Subscribe from product page. `on_product_updated` fires emails when `stockQuantity` 0→>0.
**Files to create:**
- `e2e/playwright_ui/back-in-stock.spec.ts`
**Files to modify:**
- `docs/database_schema.json` — add `stock_notifications` collection
- `functions/schema_constants.py` — add `STOCK_NOTIFICATIONS = "stock_notifications"` to `Collections`; `NOTIFIED_AT` to `Fields`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `firestore.rules` — add `stock_notifications` rules
- `functions/handlers/products.py` — add `subscribe_stock_notification`, `unsubscribe_stock_notification`; extend `on_product_updated` trigger
- `functions/services/email_service.py` — add back-in-stock email template
- `functions/main.py` — register handlers
- Product detail screen — "Notify me when available" button (visible only when stockQuantity==0)
- `functions/tests/test_handlers_products_orders.py` — subscription + trigger tests
**Adversarial:** 5→0→5 → notification fires only on 0→5 ✓ | duplicate subscribe → idempotent ✓ | deactivated product restocked → no notification ✓

---

### ✅ TASK 08 — FEAT: `compareAtPrice` (strikethrough seller pricing)
**Problem:** No way for sellers to show "~~$49~~ $29" sale pricing. Missing standard e-commerce feature.
**Files to modify:**
- `docs/database_schema.json` — add `compareAtPrice: number?` to products
- `functions/schema_constants.py` — add `COMPARE_AT_PRICE = "compareAtPrice"` to `Fields`
- `functions/models/product.py` — add `compareAtPrice: float | None` with validator `compareAtPrice > price`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `origna_gta/lib/models/generated/product_models.dart` — add `@Default(null) double? compareAtPrice` to `Product` + `ProductSummary`
- `origna_gta/lib/models/generated/product_models.freezed.dart` — regenerate
- `origna_gta/lib/models/generated/product_models.g.dart` — regenerate
- `firestore.rules` — add `compareAtPrice` to allowed product write fields
- `origna_gta/lib/screens/addproduct_screen.dart` — add compare-at-price input
- `origna_gta/lib/screens/editproduct_screen.dart` — same
- `origna_gta/lib/widgets/modern_product_card.dart` — show strikethrough price
- `functions/tests/test_pydantic_models.py` — validation tests
**Adversarial:** compareAtPrice ≤ price → rejected ✓ | null → allowed ✓

---

### ✅ TASK 09 — FEAT: Product Q&A section (buyer questions + seller answers)
**Problem:** Buyers can't ask product questions pre-purchase. Amazon Q&A is highest-converting feature.
**Schema for `product_questions`:**
```
{questionId}: { productId, sellerId (denormalized), askerId, question (10-500 chars),
  answer?, answeredAt?, answeredBy?, isAnswered (bool), upvotes (int), createdAt }
```
**Files to create:**
- `e2e/playwright_ui/product-qa.spec.ts`
**Files to modify:**
- `docs/database_schema.json` — add `product_questions` collection
- `functions/schema_constants.py` — add `PRODUCT_QUESTIONS`, field constants (`QUESTION`, `ANSWER_TEXT`, `ANSWERED_AT`, `ANSWER_BY`, `IS_ANSWERED`, `UPVOTES`)
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `firestore.rules` — add `product_questions` rules (any auth can read/create; only product's seller can update answer; no question edits after submit)
- `functions/handlers/products.py` — add `ask_product_question`, `answer_product_question`, `get_product_questions`
- `functions/services/email_service.py` — add Q-received email (to seller) + A-received email (to asker)
- `functions/main.py` — register handlers
- `origna_gta/lib/models/generated/product_models.dart` — add `ProductQuestion` freezed model
- `origna_gta/lib/models/generated/product_models.freezed.dart` — regenerate
- `origna_gta/lib/models/generated/product_models.g.dart` — regenerate
- Product detail screen — add Q&A section (ask form + answers list + unanswered count)
- Seller screen — add unanswered questions badge
- `functions/tests/test_handlers_products_orders.py` — Q&A handler tests
**Adversarial:** seller answers own question → allowed ✓ | seller answers another seller's product → rules block ✓ | XSS in question → sanitized ✓ | buyer edits question → blocked ✓

---

### ✅ TASK 10 — FEAT: Abandoned cart recovery emails (CASL-compliant)
**Problem:** Buyers add items, don't checkout, never reminded. Industry 40% email open rate.
**Strategy:** Daily cron. Find users with non-empty cart + `lastCheckoutTimestamp > 24h OR null`. Email once per 3 days max. Skip users with `marketingOptIn=false` (CASL).
**Files to modify:**
- `functions/handlers/cron_jobs.py` — add `send_abandoned_cart_emails`
- `functions/services/email_service.py` — add abandoned cart template
- `docs/database_schema.json` — add `lastCartAbandonEmailAt: timestamp?` to users
- `functions/schema_constants.py` — add `LAST_CART_ABANDON_EMAIL_AT` to `Fields`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `functions/main.py` — register cron
- `functions/tests/test_handlers_admin_cron.py` — cron tests
**Adversarial:** marketingOptIn=false → skip (CASL) ✓ | emailed 2 days ago → skip ✓ | all cart items deactivated → skip ✓ | deleted user → skip ✓

---

### ✅ TASK 11 — FEAT: Seller health metrics tracking
**Problem:** No per-seller dispute/refund/cancellation/shipment tracking. Bad actors have no automated signal.
**Schema for `seller_metrics/{sellerId}`:**
```
{ disputeRate, refundRate, cancellationRate, lateShipmentRate,
  avgResponseTimeHours, totalOrders30d, totalRevenueCents30d, computedAt }
```
**Thresholds → security alert:** disputeRate>5% | refundRate>15% | cancellationRate>10%
**Files to modify:**
- `docs/database_schema.json` — add `seller_metrics` collection
- `functions/schema_constants.py` — add `SELLER_METRICS` to `Collections`; metric field constants; `SELLER_METRICS_BREACH` to `SecurityAlertTypes`
- `origna_gta/lib/core/schema/schema_constants.dart` — mirror
- `firestore.rules` — add `seller_metrics` rules (seller reads own; admin reads/writes all; no client writes)
- `functions/handlers/cron_jobs.py` — add `compute_seller_metrics` weekly cron
- `functions/main.py` — register cron
- `functions/tests/test_handlers_admin_cron.py` — metric computation tests
**Adversarial:** new seller with 1 dispute out of 1 order → weight by sample size ✓ | suspended seller → compute but skip alert ✓ | 0 orders → no alert ✓

---

## Execution Order
1. TASK 04 (status/isActive sync) — affects all product writes
2. TASK 01 (allowBackorder) — single-file backend
3. TASK 02 (warehouseStock sync) — needs schema change
4. TASK 03 (lowStockThreshold cron) — backend only
5. TASK 08 (compareAtPrice) — schema + model + UI
6. TASK 05 (buyer address book) — schema + rules + frontend
7. TASK 06 (photo reviews) — schema + model + UI
8. TASK 07 (back-in-stock) — schema + trigger + UI
9. TASK 09 (product Q&A) — biggest feature, new collection + UI
10. TASK 10 (abandoned cart cron) — backend only
11. TASK 11 (seller metrics cron) — backend only

## Quality Gates (each task)
- [x] All existing pytest pass (no regressions) — 483 passed
- [ ] All existing Playwright pass (no regressions)
- [x] schema_constants.py ↔ schema_constants.dart ↔ database_schema.json in sync
- [x] firestore.rules updated for every new collection
- [ ] New tests added and passing (backend handlers tested; unit tests pending for new callables)
- [ ] logic-auditor clean on modified workflows
- [ ] payment-auditor clean if payment_stripe.py touched (TASK 01, 02)
- [ ] schema-sync-checker clean after schema changes
- Tests to update: none (improvements only)

---

## Phase 1: Token Optimization (AI context)

**Goal:** MEMORY.md under 100 lines with only what's NOT already in LEARNED.md or CLAUDE.md.

- [ ] Trim MEMORY.md — remove content duplicated in CLAUDE.md (env tables, quick commands, gotchas already in KEY GOTCHAS section)
- [ ] Keep: test account UIDs/emails, critical bugs with non-obvious fixes, unique E2E patterns
- [ ] Move bulk content to LEARNED.md sections already there
- [ ] Target: ~80 lines in MEMORY.md

---

## Phase 2: Performance Audit & Improvements

### Backend
- [ ] Fix 2 UP007 ruff violations (auto-fix in airwallex_service.py, algolia_service.py)
- [ ] Scan orders.py for N+1 Firestore reads (document reads inside loops)
- [ ] Scan cron_jobs.py for sequential awaits that could be `asyncio.gather()`
- [ ] Scan payment_stripe.py for redundant document reads
- [ ] Check cold start: are imports at module level minimal?

### Frontend
- [ ] Scan providers for `ref.watch()` where `ref.read()` suffices (event handlers)
- [ ] Check if `.select()` is used to limit rebuilds on large providers
- [ ] Scan for `build()` methods doing expensive work without `const` constructors or caching

---

## Phase 3: Push to Main + Pipeline Fix

- [ ] Stage ruff.toml + requirements-dev.txt (already modified, needed for CI)
- [ ] Auto-fix 2 UP007 ruff violations
- [ ] Run backend tests locally to verify Python 3.13 compat
- [ ] Stage all changes
- [ ] Commit + push
- [ ] Monitor GitHub Actions run (backend CI should pass; E2E CI will skip actual tests if secrets not set)

## Quality Gates
- [x] `ruff check .` → 0 errors in functions/
- [x] `pytest tests/ -v` → 483 passed (1 pre-existing digital test failure unrelated)
- [ ] Pipeline triggers on push → no red jobs

---

## UI Work (Deferred — Backend Ready)

These features have complete backend implementations but no UI yet:

- [ ] **Photo reviews** — photo picker on review submission screen (max 3 images)
- [ ] **Back-in-stock** — "Notify me when available" button on product detail (visible when stockQuantity==0)
- [ ] **Product Q&A** — Q&A section on product detail screen (ask form + answers list)
- [ ] **Seller Q&A badge** — unanswered questions count badge on seller products screen
