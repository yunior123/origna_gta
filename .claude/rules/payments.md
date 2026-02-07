---
paths:
  - "**/payment*"
  - "**/checkout*"
  - "**/stripe*"
  - "functions/handlers/payment_stripe.py"
  - "functions/handlers/payment_airwallex.py"
  - "origna_gta/lib/features/checkout/**"
  - "origna_gta/lib/screens/checkout_screen.dart"
---

# Payment Rules

## Stripe Connect Model
- **Direct Charges** with Stripe Connect Express
- Platform fee: **2.5%**
- Payment Intents with **manual capture**
- Flow: Authorization → Ship → Capture (7-day window)
- Stripe handles KYC, payouts, fraud, disputes
- No platform fund holding

## Critical Invariants
- **Price tampering prevention**: Backend re-fetches product price from Firestore, validates within ±$0.01
- **Idempotency**: All payment operations use event_id or idempotency keys
- **Self-purchase blocked**: `sellerId != buyerId` enforced in backend
- **Webhook dedup**: `webhook_events` collection with event_id
- **Dispute auto-reversal**: `handle_dispute_created()` reverses all transfers
- **3DS handling**: `send_3ds_authentication_email()` when `requires_action`

## Files to Cross-Check (always read together)
```
functions/handlers/payment_stripe.py     ← Payment backend
origna_gta/lib/features/checkout/checkout_provider.dart  ← Checkout frontend
functions/handlers/orders.py             ← Order creation on payment success
functions/handlers/cron_jobs.py          ← Auth expiry, auto-confirm
```

## Test Cards
- `pm_card_visa` — success
- `pm_card_authenticationRequired` — 3DS required
