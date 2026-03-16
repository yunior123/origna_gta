# Order Lifecycle Rules — origna_gta

## State Machine
```
pending → confirmed → shipped → delivered
        ↘ cancelled (from pending or confirmed only)
```

### Valid Transitions
| From | To | Who triggers |
|------|----|-------------|
| `pending` | `confirmed` | Stripe webhook (payment success) |
| `pending` | `cancelled` | Buyer cancel, payment timeout, payment failure |
| `confirmed` | `shipped` | Seller marks shipped |
| `confirmed` | `cancelled` | Seller or admin (with reason) |
| `shipped` | `delivered` | Buyer confirms or auto-delivery timeout |
| `delivered` | — | End state — no further transitions |
| `cancelled` | — | End state — no further transitions |

Never skip states. Never reverse. `delivered` and `cancelled` are terminal.

## Stock Management
- Decrement stock on `confirmed` (at Stripe payment webhook)
- Restore stock on `cancelled` (if was `confirmed` or later) via SurrealDB `Increment()` in transaction
- Restore stock on return approved
- Always atomic — never read-then-write (race condition risk)

## Notifications
| Event | Buyer | Seller |
|-------|-------|--------|
| New order (`pending`) | ✓ confirmation | ✓ new order alert |
| `confirmed` | ✓ | — |
| `shipped` | ✓ with tracking | — |
| `delivered` | ✓ | ✓ payout scheduled |
| `cancelled` | ✓ with refund info | ✓ |
| Perishable confirmed | ✓ | ✓ URGENT (24h deadline) |

## Returns / Refunds
- Return window: **30 days** from `deliveredAt` timestamp
- States: `pending` → `approved` / `rejected`
- On `approved`: Stripe refund + stock restore + order status update (atomic)
- Partial refunds allowed (damaged goods, partial return)
- Refund amount in **integer cents** — must match original `totalAmountCents`

## Multi-Seller Orders
- One checkout creates one order per seller
- Each order tracked independently with its own state machine
- Shipping calculated per seller warehouse address
- Stripe Connect payout per seller after delivery

## Schema (SurrealDB `orders` collection)
- Timestamp field: `createdAt` (Unix timestamp, integer)
- Key fields: `buyerId`, `sellerId`, `status`, `items[]`, `totalAmountCents`, `subtotalCents`, `taxAmountCents`, `shippingCostCents`
- Items: `[{ productId, name, quantity, unitPriceCents, imageUrl }]` — snapshot at creation
- Shipping address embedded at creation — never reference to user's address

## Display Rules
- Show orders newest-first (`createdAt` DESC)
- Format prices: `\$${(cents / 100).toStringAsFixed(2)}`
- Dates: `MMM d, yyyy` (e.g., "Mar 15, 2026")
- Status badge colors: pending=grey, confirmed=blue, shipped=orange, delivered=green, cancelled=red

## Cancellation Rules
- Buyer can cancel ONLY in `pending` (before seller confirms)
- Seller can cancel in `pending` or `confirmed`
- Both parties notified
- Stripe refund issued automatically if payment was captured
- Seller cancellations require a reason

## Forbidden
- ❌ State jumps (e.g., `pending` → `delivered`)
- ❌ Restoring stock without a SurrealDB transaction
- ❌ Issuing refunds without updating order status
- ❌ Modifying `items[]` after creation
- ❌ Changing `totalAmountCents` after payment captured
- ❌ Skipping notifications on state transitions
