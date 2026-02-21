# Schema P0 Fixes — Design Doc
**Date:** 2026-02-21
**Status:** Approved
**References:** Medusa.js, Saleor, Shopify, Commercetools production patterns

---

## Problem Summary

Six P0-level schema issues found during architecture audit:

1. Index references non-existent field `authorizationExpiresAt` (stored field is `expiresAt`) — broken cron
2. No variant tracking in cart or OrderItem — variant system built but disconnected from purchases
3. No order event log — dispute resolution is blind with no status history
4. `OrderItem.deliveryStatus` duplicates `OrderItem.status` — race condition on partial writes
5. `idempotencyKey` in order index but not in order schema fields
6. `orderStatus` mixes lifecycle + financial dimensions (`refunded`/`partially_refunded` belong in `paymentStatus`)

---

## Design Decisions (validated against production OSS platforms)

### Decision 1: Order Event Log → Subcollection (not embedded array)

**Pattern used by:** Saleor (`OrderEvent` table), Medusa (`OrderChange`/`OrderChangeAction`), Shopify (`events` connection)

**Why subcollection, not embedded array:**
- Firestore 1MB document limit — an order with many status transitions (tracking updates, partial fulfillments, disputes) will breach this
- Google Firestore docs: "embedded arrays aren't scalable for growing lists — use subcollections"
- Subcollection grows independently, has full query capability, never bloats the order document

**Schema:** `orders/{orderId}/events/{eventId}`

```json
{
  "eventId": "auto-generated",
  "eventType": "status_changed | payment_captured | payment_authorized | refund_issued | item_shipped | item_delivered | note_added | cancellation_requested | cancellation_confirmed",
  "fromStatus": "confirmed",
  "toStatus": "shipped",
  "actor": "uid | 'system' | 'stripe_webhook'",
  "actorType": "seller | buyer | admin | system",
  "metadata": {},
  "createdAt": "timestamp"
}
```

**What writes events:** Every Cloud Function that mutates order status writes an event document atomically in the same batch. Frontend reads subcollection for order timeline display.

---

### Decision 2: Cart Item Doc ID → Auto-generated (not productId)

**Pattern used by:** Medusa (`cali_{auto}`), Saleor (PK auto), Shopify (auto integer ID)

**Current:** `users/{uid}/cart/{productId}` — cannot store two variants of same product

**New:** `users/{uid}/cart/{cartItemId}` — auto-generated, allows same productId with different variantIds

**Cart item schema (new fields added):**

```json
{
  "cartItemId": "auto",
  "productId": "...",
  "variantId": "variant_abc | null",
  "variantTitle": "Size: M / Color: Blue | null",
  "variantOptions": {"Size": "M", "Color": "Blue"},
  "variantSku": "SKU-M-BLUE | null",
  "priceSnapshot": 2999,
  "quantity": 2,
  "createdAt": "timestamp"
}
```

`priceSnapshot` (cents) captures price at add-to-cart time. Checkout validates against live price server-side.

---

### Decision 3: OrderItem Variant Snapshot

**Pattern used by:** Medusa (full variant snapshot on LineItem), Saleor (`variant_name`, `product_sku`, `product_variant_id` on OrderLine), Shopify (`variant_id`, `variant_title`, `sku` on line_item)

**New fields added to OrderItem:**

```json
{
  "variantId": "variant_abc | null",
  "variantTitle": "Size: M / Color: Blue | null",
  "variantOptions": {"Size": "M", "Color": "Blue"},
  "variantSku": "SKU-M-BLUE | null"
}
```

These are **immutable snapshots** written at order creation. They never update even if the product variant changes.

---

### Decision 4: Remove `deliveryStatus` from OrderItem

**Problem:** Two fields (`status` + `deliveryStatus`) create a write race condition. If one write succeeds and the other fails, they permanently diverge with no reconciliation.

**Decision:** Remove `deliveryStatus`. Use `status` (string, `DeliveryStatusValues.*`) everywhere.

**Migration:** All reads/writes updated cross-stack. Python model removes `deliveryStatus` field. Dart model removes fallback merge logic. Schema constants retain `DELIVERY_STATUS` for historical reads only, remove `deliveryStatus` constant.

---

### Decision 5: `version: int` on Order (Optimistic Concurrency)

**Pattern used by:** Medusa (`version: int` on Order, incremented on `OrderChange.confirm()`), Commercetools (required on every update)

**Purpose:** NOT schema migration. Prevents two simultaneous Cloud Functions (e.g., Stripe webhook + cron) from processing the same order state change. Checked inside Firestore transactions.

**Usage:**
```python
# In transaction:
order = transaction.get(order_ref)
if order.version != expected_version:
    raise ConcurrentModificationError
transaction.update(order_ref, {"version": order.version + 1, ...})
```

---

### Decision 6: Index Fixes

| Fix | Action |
|-----|--------|
| `authorizationExpiresAt` → `expiresAt` | Rename in `database_schema.json` index definition |
| `idempotencyKey` in index but not in schema | Add `idempotencyKey: str` field to Order schema |

---

### Decision 7: `orderStatus` Dimension Cleanup

**Problem:** `orderStatus` values include `refunded` and `partially_refunded` which are payment outcomes, not lifecycle states.

**Decision:** Remove `refunded` and `partially_refunded` from `OrderStatusValues`. These states must be expressed via `paymentStatus` only. `orderStatus` becomes lifecycle-only.

**New orderStatus values:** `pending | confirmed | processing | shipped | delivered | completed | cancelled | disputed`

**paymentStatus** already handles: `pending | authorized | captured | refund_requested | refunded | partially_refunded | failed | voided`

---

## Files Affected

| File | Change |
|------|--------|
| `docs/database_schema.json` | Add events subcollection, cart fields, OrderItem variant fields, version field, fix index, add idempotencyKey, remove deliveryStatus |
| `docs/json_schemas/individual/Order.json` | Regenerate |
| `functions/schema_constants.py` | Add events constants, cart item fields, variant fields, remove deliveryStatus |
| `lib/core/schema/schema_constants.dart` | Mirror Python changes |
| `functions/models/order.py` | Add variant fields to OrderItem, add version, remove deliveryStatus, add event model |
| `lib/models/generated/order_models.dart` | Mirror Python model changes |
| `functions/handlers/orders.py` | Write events on every status change, use version in transactions |
| `functions/handlers/payment_stripe.py` | Write events on payment transitions |
| `lib/features/cart/*.dart` | Update cart provider for new doc ID structure + variant fields |
| `lib/features/checkout/checkout_provider.dart` | Pass variantId through checkout |
| `firestore.indexes.json` | Fix authorizationExpiresAt → expiresAt |

---

## Out of Scope (P1/P2 — separate tasks)

- `usedByUids` coupon array
- `priceCents` on products
- `sellerName` snapshot in OrderItem
- `commissionRateBps`
- Users God Object split
- Returns collection
- Quebec bilingual fields
