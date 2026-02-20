# Competitive Gap Analysis — OrignaGTA vs Amazon / AliExpress / Shopify / Etsy
**Date:** 2026-02-19
**Method:** Web research + codebase audit (schema_constants.py, database_schema.json, product.py, payment_stripe.py, orders.py, cron_jobs.py, products.py)

---

## TL;DR

3 code bugs exist today that cause silent data corruption. 5 high-priority missing features will hurt revenue and buyer trust at launch. 8 medium gaps are competitive disadvantages that should be addressed pre or shortly post-launch.

---

## 🔴 CRITICAL — Code Bugs (Silent Data Corruption / Dead Fields)

### BUG-1: `allowBackorder` is a Dead Field
**File:** `functions/models/product.py:182`, `functions/handlers/payment_stripe.py:883-921`
**What:** `InventoryConfig.allowBackorder` exists in the model and schema. Sellers can enable it. But `reserve_stock_transaction` at checkout NEVER reads it — it always throws `resource-exhausted` when `stockQuantity < quantity`.
**Impact:** Sellers who enable backorders get no backorder behavior. Buyers get confusing "stock changed" errors. False advertising of a feature.
**Fix:** In `reserve_stock_transaction`, after reading product data, check `product_data.get('inventory', {}).get('allowBackorder', False)`. If true, skip the stock check and allow the order.

---

### BUG-2: `warehouseStock` Desyncs from `stockQuantity` on Every Purchase
**File:** `functions/handlers/payment_stripe.py:883-921`, `docs/database_schema.json:472-474`
**What:** Schema says "stockQuantity equals the sum of all warehouseStock values." But `reserve_stock_transaction` ONLY decrements `stockQuantity`, never `warehouseStock[warehouseId]`. So after any purchase, `warehouseStock` overestimates per-warehouse stock.
**Impact:** The multi-warehouse UI (which should show stock per warehouse) will show stale data. Sellers relying on `warehouseStock` for warehouse management see wrong numbers. Gets worse with every order.
**Fix:** When a product has `warehouseIds`, the stock decrement must also update `warehouseStock`. Since the order doesn't track which specific warehouse fulfilled the item, use a "drain from default warehouse first" strategy.

---

### BUG-3: `lowStockThreshold` is a Dead Field
**File:** `functions/models/product.py:183`, `functions/handlers/cron_jobs.py`
**What:** `InventoryConfig.lowStockThreshold` exists (default: 5) and sellers can configure it. But no cron job, trigger, or any handler ever reads it to fire a "low stock" alert email to the seller.
**Impact:** Sellers will silently go out of stock with no warning. Lost sales.
**Fix:** Add a `check_low_stock_alerts` cron (daily) that queries products where `stockQuantity <= inventory.lowStockThreshold AND isActive=true` and emails the seller.

---

### BUG-4: `status` vs `isActive` Can Desync on Products
**File:** `functions/schema_constants.py:692-701`, `functions/handlers/products.py`
**What:** Products have both `status` ('draft', 'active', 'paused', 'archived', 'out_of_stock') AND `isActive` (bool). These are not always written atomically. A product can have `status='paused'` but `isActive=true` (still searchable in Algolia) or vice versa.
**Impact:** Products that should be hidden appear in search; products that should appear are hidden.
**Fix:** Enforce a sync rule — wherever `isActive` is written, `status` must be set consistently, and vice versa. Add a schema-level rule: `isActive = (status == 'active')`. Or eliminate one field.

---

## 🟠 HIGH — Missing Features That Hurt Revenue / Trust

### GAP-1: No Product Variants (Color / Size / Flavor)
**Comparison:** Amazon, AliExpress, Etsy, Shopify all have parent-child variant systems.
**What's Missing:** A T-shirt in 3 sizes × 4 colors requires 12 separate product listings. No per-variant stock, per-variant pricing, variant image mapping, or variant selector UI.
**Impact:**
- Sellers must create N listings for 1 product → bad UX, inflated product count
- Reviews fragment across variants → lower rating counts per listing
- Search results show duplicates from the same seller
- No variant-level inventory tracking

**Design (minimal viable):**
```
products/{id}/
  variants: [
    {variantId, label: "Red / M", options: {color: "Red", size: "M"},
     priceDelta: 0, stockQuantity: 15, imageIndex: 0}
  ]
  variantOptions: {color: ["Red", "Blue"], size: ["S", "M", "L"]}
```
Each variant is a map in the `variants` array. Stock tracked per variant. `stockQuantity` on the parent = sum of all variant stocks. This avoids breaking existing checkout flow — checkout still references `productId`, but also stores `variantId`.

---

### GAP-2: Buyer Has Only ONE Saved Address
**Comparison:** Amazon has address book with labeled saved addresses.
**What's Missing:** `users.address` is a single map. No `addresses` subcollection for buyers.
**Impact:** Buyers who ship to work vs. home must re-enter every time → high friction, cart abandonment.
**Fix:** Add `users/{uid}/addresses` subcollection (mirrors how sellers have `warehouses`). Schema is already designed for it (`isDefault`, `label` fields exist in Address schema). Just need a new subcollection + CRUD endpoints.

---

### GAP-3: Return Window is 7 Days (Industry Standard is 30 Days)
**Comparison:** Amazon = 30 days, AliExpress = 15–90 days (buyer protection), Etsy = seller-set but typically 14–30 days.
**What's Missing:** `BusinessRules.RETURN_WINDOW_DAYS = 7` at `schema_constants.py:1040`.
**Impact:** Buyers will feel rushed. Significantly higher dispute/chargeback rate when buyers can't return items within 7 days and escalate to Stripe directly. Stripe disputes cost $15 each.
**Fix:** Change to 30 days. Also consider making it seller-configurable (premium sellers can offer longer windows) with a platform minimum.

---

### GAP-4: No Seller Performance Metrics / Health Dashboard
**Comparison:** Amazon (ODR < 1%, LSR < 4%, Valid Tracking Rate > 95%), Walmart, Newegg all track seller health.
**What's Missing:** No tracking of:
- Dispute rate per seller
- Late shipment rate (items marked `shipped` after expected date)
- Cancellation rate
- Return/refund rate
- Response time on shipping approvals

**Impact:** Bad sellers (high dispute rate, slow shippers) have no automated consequence. Platform quality degrades. Stripe may flag the platform if dispute rates are high.
**Fix:** A `sellerMetrics` document per seller (computed by cron weekly) with rolling 30/60-day rates. Automated account review alert when thresholds breached.

---

### GAP-5: No Coupon / Promo Code System
**Comparison:** Amazon (Lightning Deals, coupons), Etsy (promo codes, sales), Shopify (discount engine).
**What's Missing:** No `coupons` collection, no discount code at checkout, no flash sale pricing, no `compareAtPrice` field.
**Impact:** Sellers can't run promotions. Platform can't run acquisition campaigns. Major revenue tool missing.
**Design (minimal):**
```
coupons/{code}:
  code: "LAUNCH20"
  discountType: "percent" | "fixed"
  discountValue: 20
  minOrderCents: 2000  // $20 minimum
  expiresAt: timestamp
  maxUses: 500
  usedCount: 0
  sellerId: null  // null = platform-wide, set = seller-specific
  isActive: true
```
Checkout handler reads coupon before creating Stripe session, applies discount.

---

### GAP-6: Photo Reviews Not Supported
**Comparison:** Amazon, AliExpress, Etsy all allow photo/video in reviews.
**What's Missing:** `product_ratings` schema only has `rating` + `comment`. No `imageUrls` field.
**Impact:** Photo reviews are a top conversion driver. Buyers want to see real product photos from buyers.
**Fix:** Add `imageUrls: array<string>` to `product_ratings`. Reuse R2 upload infrastructure. Add 3-image limit per review.

---

### GAP-7: No "Back in Stock" Buyer Notifications
**Comparison:** Amazon, AliExpress, Shopify all have stock notification subscriptions.
**What's Missing:** No `stock_notifications` collection, no buyer subscription to products, no trigger on `stockQuantity > 0`.
**Impact:** Buyers who want a sold-out product leave and never come back. Amazon captures these with "Notify me" buttons.
**Fix:**
```
stock_notifications/{auto}:
  productId, userId, email, createdAt, notifiedAt
```
Add `on_product_updated` trigger branch: when `stockQuantity` transitions from 0 to >0, query `stock_notifications` for that product and send emails.

---

## 🟡 MEDIUM — Competitive Gaps (Pre/Post Launch)

### GAP-8: No Abandoned Cart Recovery Emails
**What's Missing:** Cart items persist in Firestore but no email reminder is sent to buyers who have items in cart but didn't checkout in 24h.
**Industry:** 40% open rate on abandonment emails, 50% of those click, 50% of those purchase (Moosend 2025).
**Fix:** Add a daily cron that queries users with cart items and `lastCheckoutTimestamp` > 24h ago → send a "You left items behind" email.

---

### GAP-9: No Seller Comparative Pricing ("Was / Now")
**What's Missing:** No `compareAtPrice` field on products. Sellers can't show "~~$49.99~~ $29.99".
**Fix:** Add `compareAtPrice: float | null` to `Product` model. Validate `compareAtPrice > price`. Display strikethrough in UI.

---

### GAP-10: No Product Q&A Section
**What's Missing:** No collection for buyer questions and seller answers on product pages (Amazon's most-used feature).
**Fix:**
```
product_questions/{auto}:
  productId, userId (asker), question, answer, answeredAt, sellerId, upvotes
```
Notify seller by email when a new question arrives.

---

### GAP-11: No Subcategories / Hierarchical Taxonomy
**What's Missing:** Flat 21 categories. No subcategories. "Fashion" has no "Men's", "Women's", "Kids" breakdown.
**Impact:** Browsing becomes impossible at scale. Search noise (unrelated items in same category).
**Fix:** Add `subcategoryId` field + a subcategory constants class. Keep backward compatibility by making it optional.

---

### GAP-12: No Bulk Seller Operations
**What's Missing:** Sellers can't bulk-pause, bulk-archive, bulk-price-update products.
**Fix:** Add `bulk_update_products` handler that accepts `productIds[]` + patch fields. Rate-limited.

---

### GAP-13: No Price History Tracking
**What's Missing:** No audit log of price changes. Buyers can't see price history (CamelCamelCamel-style). Also useful for fraud detection (sellers inflating then discounting prices).
**Fix:** On product update, if `price` changes, append `{oldPrice, newPrice, changedAt}` to a `priceHistory` array (capped at last 10 entries).

---

### GAP-14: No Cross-Sell / "Frequently Bought Together"
**What's Missing:** Algolia is already integrated but not used for recommendations. No `related_products` or purchased-together data.
**Fix:** Leverage Algolia Recommend API. Mine order `items` arrays for co-purchase patterns. Store `recommendedProductIds` on product at write time.

---

### GAP-15: Guest Checkout Not Supported
**What's Missing:** All purchases require a Firebase Auth account. Amazon found 26% of shoppers abandon when forced to register.
**Complexity:** High (Stripe requires customer email, stock must still be reserved, order needs a userId). Can be implemented with anonymous Firebase Auth + email collection at checkout.
**Recommendation:** Defer post-launch but plan for it.

---

### GAP-16: No Order Gift Messages / Delivery Notes at Order Level
**What's Missing:** `deliveryInstructions` exists as a field constant but there's no `giftMessage` field and it's unclear if `deliveryInstructions` is collected at checkout.
**Fix:** Add `giftMessage: string | null` and confirm `deliveryInstructions` is wired in checkout flow.

---

## Priority Matrix

| # | Gap | Severity | Effort | Ship? |
|---|-----|----------|--------|-------|
| BUG-1 | `allowBackorder` dead | CRITICAL | Low | Before launch |
| BUG-2 | `warehouseStock` desync | CRITICAL | Medium | Before launch |
| BUG-3 | `lowStockThreshold` dead | CRITICAL | Low | Before launch |
| BUG-4 | `status` vs `isActive` desync | CRITICAL | Low | Before launch |
| GAP-3 | Return window 7→30 days | HIGH | Trivial | Before launch |
| GAP-6 | Photo reviews | HIGH | Medium | Before launch |
| GAP-7 | Back-in-stock notifications | HIGH | Medium | Before launch |
| GAP-1 | Product variants | HIGH | Very High | Post-launch v2 |
| GAP-2 | Buyer address book | HIGH | Medium | Before launch |
| GAP-4 | Seller health metrics | HIGH | High | Post-launch v1 |
| GAP-5 | Coupon/promo codes | HIGH | High | Post-launch v1 |
| GAP-8 | Abandoned cart emails | MEDIUM | Medium | Post-launch v1 |
| GAP-9 | compareAtPrice | MEDIUM | Low | Before launch |
| GAP-10 | Product Q&A | MEDIUM | Medium | Post-launch v1 |
| GAP-11 | Subcategories | MEDIUM | High | Post-launch v2 |
| GAP-12 | Bulk seller ops | MEDIUM | Medium | Post-launch v1 |
| GAP-13 | Price history | MEDIUM | Low | Post-launch v1 |
| GAP-14 | Cross-sell | MEDIUM | Medium | Post-launch v2 |
| GAP-15 | Guest checkout | MEDIUM | Very High | Post-launch v2 |
| GAP-16 | Gift messages | LOW | Low | Before launch |

---

## Summary of What We Do Well (vs Competitors)

- ✅ Multi-warehouse support per product (just solved)
- ✅ Full Canadian tax compliance (GST/HST/PST/QST/QST) with Stripe Tax
- ✅ Atomic stock reservation during checkout (prevents oversell)
- ✅ Per-item delivery tracking in multi-seller orders
- ✅ Dispute tracking + payout reversal flow
- ✅ CASL + PIPEDA + Quebec Law 25 compliance
- ✅ Admin approval gate for products (prevents spam listings)
- ✅ MFA for admin accounts
- ✅ Seller suspension + product deactivation cascade
- ✅ Digital products (ebooks + software with license keys)
- ✅ International supplier tracking (AliExpress, Alibaba, etc.)
- ✅ Idempotent webhook processing
- ✅ Verified purchase requirement for reviews
