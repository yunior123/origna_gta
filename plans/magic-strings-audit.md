# Plan: Magic Strings → Constants Audit & Fix

> **Status:** Ready to execute
> **Scope:** OrignaBase Rust codebase (`orignabase/`)
> **Total magic strings:** ~3,013 across 68 files

## Problem

The `fields` module (`crates/ob-handlers/src/shared/schema.rs:315-563`) defines **205 constants** but most code uses bare string literals like `"productId"` instead of `fields::PRODUCT_ID`. This creates maintenance risk — if a field name ever changes, magic strings silently break.

## Phase 1: Add 17 Missing Constants

**File:** `crates/ob-handlers/src/shared/schema.rs`

```rust
// User fields (add after IS_PREMIUM)
pub const DISPLAY_NAME: &str = "displayName";
pub const PHONE_NUMBER: &str = "phoneNumber";
pub const FIRST_NAME: &str = "firstName";
pub const LAST_NAME: &str = "lastName";

// Order fields (add after RETURN_STATUS)
pub const RETURN_ID: &str = "returnId";
pub const RETURN_REASON: &str = "returnReason";

// Coupon fields (add after COUPON_TYPE)
pub const DISCOUNT_TYPE: &str = "discountType";
pub const COUPON_CODE: &str = "couponCode";

// Item/product detail (add after REQUESTED_AT)
pub const UNIT_PRICE_CENTS: &str = "unitPriceCents";
pub const SHIP_FROM_PROVINCE: &str = "shipFromProvince";
pub const SHIP_FROM_COUNTRY: &str = "shipFromCountry";
pub const IS_LOCAL_DELIVERY_ONLY: &str = "isLocalDeliveryOnly";
pub const DOWNLOAD_URL: &str = "downloadUrl";

// Product Q&A (new section after Shipping)
pub const QUESTION_ID: &str = "questionId";
pub const QUESTION_TEXT: &str = "questionText";
pub const ANSWER_TEXT: &str = "answerText";
pub const ANSWERED_AT: &str = "answeredAt";
```

## Phase 2: Production Code Sweep (43 files, ~1,781 hits)

### Strategy
- Use smart pattern matching — only replace in JSON field contexts:
  - `"field":` in `json!()` macros
  - `.get("field")` access
  - `["field"]` bracket access
  - `.insert("field",` calls
  - `validate_uid("field",` calls
- Skip very generic strings (`"name"`, `"code"`, `"text"`, `"read"`, `"status"`, `"email"`, `"token"`, `"address"`, `"deleted"`, `"resolved"`, `"roles"`, `"platform"`, `"uid"`, `"state"`, `"label"`, `"apartment"`, `"latitude"`, `"longitude"`)
- Auto-add `use crate::shared::schema::fields;` import where needed
- Run `cargo check` after each batch of ~20 fields

### Top Offender Files (prioritize order)

| # | File | Magic Strings |
|---|------|:---:|
| 1 | `crates/ob-handlers/src/cron/mod.rs` | 326 |
| 2 | `crates/ob-handlers/src/orders/refunds.rs` | 229 |
| 3 | `crates/ob-handlers/src/orders/returns.rs` | 205 |
| 4 | `crates/ob-handlers/src/native_triggers.rs` | 106 |
| 5 | `crates/ob-handlers/src/orders/shipping.rs` | 105 |
| 6 | `crates/ob-handlers/src/payments/checkout.rs` | 86 |
| 7 | `crates/ob-handlers/src/users/mod.rs` | 81 |
| 8 | `crates/ob-handlers/src/products/triggers.rs` | 72 |
| 9 | `crates/ob-handlers/src/digital/mod.rs` | 62 |
| 10 | `crates/ob-handlers/src/orders/status.rs` | 58 |
| 11 | `crates/ob-handlers/src/coupons/mod.rs` | 57 |
| 12 | `crates/ob-handlers/src/payments/webhooks.rs` | 51 |
| 13 | `crates/ob-handlers/src/products/crud.rs` | 44 |
| 14 | `crates/ob-handlers/src/payments/subscriptions.rs` | 33 |
| 15 | `crates/ob-handlers/src/products/ratings.rs` | 25 |
| 16 | `crates/ob-mcp/src/tools/orders.rs` | 24 |
| 17 | `crates/ob-handlers/src/rest_api.rs` | 22 |
| 18 | `crates/ob-handlers/src/email/helpers.rs` | 19 |
| 19 | `crates/ob-realtime/src/dispatcher.rs` | 18 |
| 20 | `crates/ob-mcp/src/tools/shopping.rs` | 14 |

### Top Offending Fields (most frequent)

| Field | Should Use | Hits |
|-------|-----------|:---:|
| `"userId"` | `fields::USER_ID` | 358 |
| `"quantity"` | `fields::QUANTITY` | 126 |
| `"productId"` | `fields::PRODUCT_ID` | 111 |
| `"orderId"` | `fields::ORDER_ID` | 94 |
| `"items"` | `fields::ITEMS` | 63 |
| `"stockQuantity"` | `fields::STOCK_QUANTITY` | 60 |
| `"orderStatus"` | `fields::ORDER_STATUS` | 55 |
| `"lifecycleStatus"` | `fields::LIFECYCLE_STATUS` | 54 |
| `"priceCents"` | `fields::PRICE_CENTS` | 48 |
| `"sellerId"` | `fields::SELLER_ID` | 48 |
| `"returnStatus"` | `fields::RETURN_STATUS` | 47 |
| `"isDigital"` | `fields::IS_DIGITAL` | 46 |
| `"deliveredAt"` | `fields::DELIVERED_AT` | 32 |
| `"paymentIntentId"` | `fields::PAYMENT_INTENT_ID` | 29 |
| `"subtotalCents"` | `fields::SUBTOTAL_CENTS` | 28 |
| `"buyerId"` | `fields::BUYER_ID` | 27 |
| `"taxAmountCents"` | `fields::TAX_AMOUNT_CENTS` | 26 |
| `"createdAt"` | `fields::CREATED_AT` | 23 |
| `"expiresAt"` | `fields::EXPIRES_AT` | 21 |
| `"lockedAt"` | `fields::LOCKED_AT` | 20 |

## Phase 3: Test Code Sweep (~812 hits)

Lower priority — replace magic strings in test `json!()` macros.

| # | File | Hits |
|---|------|:---:|
| 1 | `crates/orignabase/tests/handlers_integration_test.rs` | 261 |
| 2 | `crates/orignabase/tests/order_lifecycle_test.rs` | 64 |
| 3 | `crates/orignabase/tests/integration_test.rs` | 64 |
| 4 | `crates/orignabase/tests/returns_refunds_test.rs` | 53 |
| 5 | `crates/orignabase/tests/security_fixes_test.rs` | 45 |

## Phase 4: Collection Name Sweep (~420 hits)

Replace bare collection name strings with `collections::` constants.

| Collection String | Bare Uses | Should Use |
|---|:---:|---|
| `"products"` | ~262 | `collections::PRODUCTS` |
| `"users"` | ~78 | `collections::USERS` |
| `"orders"` | ~55 | `collections::ORDERS` |
| `"return_requests"` | ~18 | `collections::RETURN_REQUESTS` |
| `"cart"` | ~13 | `collections::CART` |
| `"coupons"` | ~6 | `collections::COUPONS` |
| `"notifications"` | ~5 | `collections::NOTIFICATIONS` |

## Verification

After each phase:
```bash
cargo clippy -- -D warnings
cargo test
```

## Estimated Total

| Category | Magic Strings |
|----------|:---:|
| Production field names | 1,781 |
| Test field names | 812 |
| Collection names | ~420 |
| **Grand total** | **~3,013** |

---

## Execution Log & Discoveries

### Attempt 1 — Naive sed batch (FAILED, reverted)

**What happened:** Ran a bash script that used `sed` to replace ALL occurrences of `"field"` → `fields::CONSTANT` across all `.rs` files in `crates/ob-handlers/src/`. The script made **2,228 replacements across 36 files**.

**Result:** `cargo check` reported **400 errors**. Full revert via `git checkout -- crates/ob-handlers/src/`.

**Root causes of failure:**

1. **Missing imports:** Many files that got replacements never imported `fields`. They used raw strings before. After replacement, `fields::USER_ID` etc. were unresolved (E0425 errors). The sed approach didn't handle adding `use crate::shared::schema::fields;` imports.

2. **Over-broad generic strings:** Replaced strings like `"text"` → `fields::MESSAGE_TEXT`, `"read"` → `fields::READ`, `"status"` → `fields::STATUS` etc. These are too generic and appear in non-field contexts (chat message text, read operations, HTTP status codes, etc.).

3. **No context awareness:** `sed` replaced ALL occurrences of `"field":` regardless of whether it was in a JSON macro, a struct definition, a comment, or a log string.

**Lesson:** The replacement tool MUST:
- Only target specific JSON field access patterns (`json!()`, `.get()`, `[]`, `.insert()`, `validate_*()`)
- Skip generic string literals (`"name"`, `"code"`, `"text"`, `"read"`, `"status"`, `"email"`, `"token"`, `"address"`, `"deleted"`, `"resolved"`, `"roles"`, `"platform"`, `"uid"`, `"state"`, `"label"`, `"apartment"`, `"latitude"`, `"longitude"`)
- Auto-add `use crate::shared::schema::fields;` where missing (either extend existing `{...}` import or add new line)

### Phase 1 — Constants added (DONE)

**Commit:** Added 17 missing constants to `schema.rs` fields module. All placed in logical groupings:
- User: `DISPLAY_NAME`, `PHONE_NUMBER`, `FIRST_NAME`, `LAST_NAME`
- Order: `RETURN_ID`, `RETURN_REASON`
- Coupon: `DISCOUNT_TYPE`, `COUPON_CODE`
- Item: `UNIT_PRICE_CENTS`, `SHIP_FROM_PROVINCE`, `SHIP_FROM_COUNTRY`, `IS_LOCAL_DELIVERY_ONLY`, `DOWNLOAD_URL`
- Q&A: `QUESTION_ID`, `QUESTION_TEXT`, `ANSWER_TEXT`, `ANSWERED_AT`

**Note:** These were added to `schema.rs` but then got reverted along with everything else during the full revert. Need to re-apply.

### Files Already Importing `fields` (no import change needed)

These files already have `use crate::shared::schema::{..., fields}`:
- `payments/checkout.rs` — `{OrderStatus, collections, fields, lifecycle_status}`
- `payments/webhooks.rs` — `{OrderStatus, collections, fields}`
- `payments/subscriptions.rs` — `{SubscriptionStatus, business_rules, collections, fields}`
- `payments/connect.rs` — `{app_config, collections, fields}`
- `payments/providers.rs` — `{collections, documents, fields}`
- `payments/capture.rs` — `{OrderStatus, PaymentStatus, collections, fields}`
- `native_triggers.rs` — `{OrderStatus, collections, fields, notification_types}`
- `products/crud.rs` — `{collections, fields}`
- `products/triggers.rs` — `{collections, fields}`
- `products/questions.rs` — `{collections, fields}`
- `products/stock.rs` — `{collections, fields}`
- `products/ratings.rs` — `{collections, fields}`
- `chat/mod.rs` — `{collections, fields}`
- `coupons/mod.rs` — `{collections, fields}`
- `shared/indexes.rs` — `{collections, fields}`
- `rest_api.rs` — `{collections, fields, lifecycle_status}`
- `warehouses/mod.rs` — `{COUNTRY_CANADA, collections, fields}`
- `email/helpers.rs` — has `use crate::shared::schema::fields` (only inside a test block)

### Files That NEED Import Added

These files likely use magic strings but don't import `fields`:
- `crates/ob-handlers/src/cron/mod.rs` — biggest offender (326 hits), needs import
- `crates/ob-handlers/src/orders/refunds.rs` — 229 hits
- `crates/ob-handlers/src/orders/returns.rs` — 205 hits
- `crates/ob-handlers/src/orders/shipping.rs` — 105 hits
- `crates/ob-handlers/src/orders/status.rs` — 58 hits
- `crates/ob-handlers/src/users/mod.rs` — 81 hits
- `crates/ob-handlers/src/digital/mod.rs` — 62 hits
- `crates/ob-handlers/src/shared/auth.rs`
- `crates/ob-handlers/src/shared/validation.rs`
- `crates/ob-handlers/src/shipping_calc/mod.rs`
- `crates/ob-handlers/src/push/mod.rs`
- `crates/ob-handlers/src/addresses/mod.rs`
- `crates/ob-handlers/src/email/mod.rs`
- `crates/ob-handlers/src/geocoding/mod.rs`
- `crates/ob-handlers/src/shared/rate_limiter.rs`
- `crates/ob-handlers/src/shared/specs.rs`
- `crates/ob-mcp/src/tools/orders.rs`
- `crates/ob-mcp/src/tools/shopping.rs`
- `crates/ob-realtime/src/dispatcher.rs`

---

## What Remains (unexecuted)

### Step 0: Current state
- Codebase is **clean** (reverted to pre-attempt state)
- Phase 1 constants were also reverted — need to re-apply
- No changes are staged; everything must be redone

### Step 1: Re-add 17 missing constants to schema.rs

Exact edits on `crates/ob-handlers/src/shared/schema.rs`:

```rust
// After IS_PREMIUM (line 350), add:
pub const DISPLAY_NAME: &str = "displayName";
pub const PHONE_NUMBER: &str = "phoneNumber";
pub const FIRST_NAME: &str = "firstName";
pub const LAST_NAME: &str = "lastName";

// After RETURN_STATUS (line 372), add:
pub const RETURN_ID: &str = "returnId";
pub const RETURN_REASON: &str = "returnReason";

// After COUPON_TYPE (line 421), add:
pub const DISCOUNT_TYPE: &str = "discountType";
pub const COUPON_CODE: &str = "couponCode";

// After REQUESTED_AT (line 440), add:
pub const UNIT_PRICE_CENTS: &str = "unitPriceCents";
pub const SHIP_FROM_PROVINCE: &str = "shipFromProvince";
pub const SHIP_FROM_COUNTRY: &str = "shipFromCountry";
pub const IS_LOCAL_DELIVERY_ONLY: &str = "isLocalDeliveryOnly";
pub const DOWNLOAD_URL: &str = "downloadUrl";

// After SHIPPING_CARRIER (line 394), add new section:
pub const QUESTION_ID: &str = "questionId";
pub const QUESTION_TEXT: &str = "questionText";
pub const ANSWER_TEXT: &str = "answerText";
pub const ANSWERED_AT: &str = "answeredAt";
```

### Step 2: Build the replacement tool

Need a Python script (not sed) that:

1. **Walks** `crates/ob-handlers/src/` and `crates/ob-mcp/src/` and `crates/ob-realtime/src/`
2. **Skips** `schema.rs` and `tests/` directories
3. **For each file**, applies replacements only in these 6 patterns:
   - `"field":` → `fields::CONSTANT:` (json!() key)
   - `.get("field")` → `.get(fields::CONSTANT)`
   - `.get("field",` → `.get(fields::CONSTANT,`
   - `["field"]` → `[fields::CONSTANT]`
   - `.insert("field",` → `.insert(fields::CONSTANT,`
   - `"field".to_string(),` → `fields::CONSTANT.to_string(),`
4. **Skips** these 18 generic strings (too risky):
   - `"name"`, `"code"`, `"text"`, `"read"`, `"status"`, `"email"`, `"token"`, `"address"`, `"deleted"`, `"resolved"`, `"roles"`, `"platform"`, `"uid"`, `"state"`, `"label"`, `"apartment"`, `"latitude"`, `"longitude"`
5. **After replacement**, checks if file uses `fields::` but doesn't import it:
   - If existing `use crate::shared::schema::{...};` → append `, fields` to the group
   - If no schema import → add `use crate::shared::schema::fields;` after first `use` block

### Step 3: Run replacement in batches, verify each

```
Batch 1: Top 5 unambiguous fields (productId, userId, orderId, sellerId, buyerId)
  → cargo check
Batch 2: Money fields (priceCents, subtotalCents, taxAmountCents, totalAmountCents, shippingCostCents, amountCents, netAmountCents, discountAmountCents, refundAmountCents, cumulativeRefundedCents, partialRefundAmountCents, unitPriceCents, platformFeeCents)
  → cargo check
Batch 3: Status/lifecycle (orderStatus, returnStatus, lifecycleStatus, paymentStatus, subscriptionStatus)
  → cargo check
Batch 4: Boolean flags (isDigital, isPerishable, isAgeRestricted, isActive, isPremium, isTrending, isLocalDeliveryOnly, hasDispute, autoCaptured, trackQuantity, marketingOptIn, cancelAtPeriodEnd, maxRetriesExceeded, stockRestored, resolved [skipped], deleted [skipped], suspended)
  → cargo check
Batch 5: Timestamps (createdAt, updatedAt, deliveredAt, expiresAt, lockedAt, completedAt, requestedAt, refundedAt, archivedAt, savedAt, deletedAt, escalatedAt, trendingAt, answeredAt, computedAt→completedAt, lockedBy, lastCheckoutTimestamp, lastCheckoutSession)
  → cargo check
Batch 6: IDs (couponId, chatId, subscriptionId, stripeSubscriptionId, stripeAccountId, customerId, paymentIntentId, checkoutSessionId→stripeSessionId, cartItemId, refundId, returnId, questionId, fulfillmentWarehouseId, deviceId, lastActorId, fcmToken, licenseKey)
  → cargo check
Batch 7: Shipping (trackingNumber, shippingCarrier, shippingAddress, shipFromProvince, shipFromCountry)
  → cargo check
Batch 8: Product fields (stockQuantity, imageUrls, categoryId, avgRating, totalReviews, description, productType, deliverySpeed)
  → cargo check
Batch 9: Coupon fields (couponType, discountType, discountValue, minOrderCents, maxUsesTotal→maxUses, usedCount, couponCode)
  → cargo check
Batch 10: User fields (email, preferredLanguage, sellerProfile, businessAddress, payoutsEnabled, chargesEnabled, onboardingCompleted, mfaEnabled, emailConsent, commissionRateBps, suspendedAt, suspendedBy, suspensionReason, isPremium, displayName, phoneNumber, firstName, lastName)
  → cargo check
  ⚠️ "email", "displayName", "firstName", "lastName" are semi-generic — verify manually
Batch 11: Order item fields (items, quantity, discountAmountCents, deliveredAt, refundedAt, refundReason, refundAmountCents, refundId)
  → cargo check
Batch 12: Chat fields (participants, lastMessage, lastMessageAt, buyerUnreadCount, sellerUnreadCount, senderId)
  → cargo check
  ⚠️ "participants" is semi-generic — verify
Batch 13: Rating fields (rating, reviewText, helpfulCount)
  → cargo check
  ⚠️ "rating" is semi-generic
Batch 14: Cron-specific (payoutStatus, payoutDate, trendingScore, trendingAt, favoriteCount, viewCount, purchaseCount, premiumSince, premiumExpiresAt, disputeRate, refundRate, cancellationRate, escalatedAt, escalationReason, lowStockThreshold, stripeTransferId, eventType, failureReason, benefitsActiveAt, earlyCancelCount, cancelsAt, jobName, errorMessage, retryCount, lastLowStockAlertAt, lastCartAbandonEmailAt)
  → cargo check
Batch 15: Notification (notificationType, token, platform, fcmToken)
  → cargo check
  ⚠️ "token" and "platform" are very generic — may need to skip
Batch 16: Digital (downloadUrl, licenseKey, deviceId, maxDevices, activatedDevices)
  → cargo check
Batch 17: Q&A (questionId, questionText, answerText, answeredAt)
  → cargo check
```

### Step 4: Full verification

```bash
cargo clippy -- -D warnings
cargo test
```

### Step 5: Phase 3 — Test code sweep

Same replacement tool, but pointed at `crates/orignabase/tests/` and `crates/ob-handlers/tests/`.
Add `use ob_handlers::shared::schema::fields;` imports where needed (different path for external test crates).

### Step 6: Phase 4 — Collection names

Separate pass for `collections::` constants. Same pattern-matching approach but targeting:
- `"products"` → `collections::PRODUCTS`
- `"users"` → `collections::USERS`
- `"orders"` → `collections::ORDERS`
- `"return_requests"` → `collections::RETURN_REQUESTS`
- `"cart"` → `collections::CART`
- `"coupons"` → `collections::COUPONS`
- `"notifications"` → `collections::NOTIFICATIONS`

⚠️ `"cart"` is semi-generic (could be variable name). `"users"` and `"products"` could appear in URL paths or doc comments. Must target same JSON patterns only.

### Step 7: Final commit

```bash
git add -A
git commit -m "refactor: replace magic strings with fields:: and collections:: constants"
```

### Fields to SKIP entirely (too generic, high false-positive risk)

| String | Why risky |
|--------|-----------|
| `"name"` | Variable names, struct fields, HashMap keys, comments |
| `"code"` | HTTP status codes, error codes, coupon codes |
| `"text"` | Chat messages, log text, error text |
| `"read"` | Read operations, IO |
| `"status"` | HTTP status, generic status vars |
| `"email"` | Display strings, SMTP config |
| `"token"` | JWT tokens, FCM tokens, CSRF tokens |
| `"address"` | Memory addresses, email addresses |
| `"deleted"` | Boolean ops, soft-delete checks |
| `"resolved"` | Promise/future, DNS, dispute resolution |
| `"roles"` | Auth roles, RBAC |
| `"platform"` | Device platform, OS platform |
| `"uid"` | Generic ID variable |
| `"state"` | State machine, US state, app state |
| `"label"` | UI labels, form labels |
| `"apartment"` | Address parsing |
| `"latitude"` | Geo calculations |
| `"longitude"` | Geo calculations |
