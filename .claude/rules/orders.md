---
paths:
  - "**/order*"
  - "**/orders*"
  - "functions/handlers/orders.py"
  - "functions/handlers/cron_jobs.py"
  - "origna_gta/lib/features/orders/**"
  - "origna_gta/lib/screens/orders_screen.dart"
  - "origna_gta/lib/screens/seller_orders_screen.dart"
---

# Order Lifecycle Rules

## State Machine (STRICT — no skipping states)
```
pending → confirmed → processing → shipped → in_transit → delivered
                                                          ↘ cancelled
                                                          ↘ failed / expired
                                                          ↘ refunded / partially_refunded
```

## Critical Invariants
- **State transitions are one-way** — never go backwards (e.g., `shipped` → `confirmed` ILLEGAL)
- **Terminal states are final** — `delivered`, `cancelled`, `failed`, `expired`, `refunded` cannot change
- **Order-level vs Item-level**: order has `OrderStatus` enum, each item has `status` string
- **`deliveryStatus` is DEPRECATED** — use `status` string on items
- **Cancel must**: restore stock + refund payment (if captured) or void auth (if uncaptured)
- **Double-cancel must be idempotent** — no double stock restore
- **Cron: auto-confirm** delivery 7 days after shipped
- **Cron: expired auth** checked within 7-day Stripe window

## Files to Cross-Check
```
functions/handlers/orders.py                    ← State transitions backend
functions/handlers/payment_stripe.py            ← Capture on ship, refund on cancel
functions/handlers/cron_jobs.py                 ← Auto-confirm, auth expiry
origna_gta/lib/features/orders/*.dart           ← Frontend order management
origna_gta/lib/models/generated/order_models.dart ← Order model
origna_gta/lib/models/generated/base_models.dart  ← OrderStatus enum
docs/diagrams/state-order-lifecycle.puml        ← Visual reference
```
