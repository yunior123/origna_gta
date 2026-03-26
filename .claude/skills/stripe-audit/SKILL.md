---
name: stripe-audit
description: "Deep Stripe integration audit for OrignaGTA. Covers Checkout Sessions, webhooks, Connect payouts, refunds, idempotency, amount integrity, and platform fees. Grounded in Stripe docs, 15+ GitHub issues, and production incidents. Use when asked to 'audit Stripe', 'check payments', 'review checkout', 'payment audit', or similar."
---

# Stripe Integration Audit — OrignaGTA

Complete audit of every Stripe touchpoint in the app. Grounded in Stripe's own documentation, 15+ closed GitHub issues across WooCommerce/MedusaJS/Saleor, and production incident patterns.

## When To Use

- Before any production deploy touching payment code
- After modifying checkout, webhook, or refund logic
- When investigating duplicate charges or payment failures
- Pre-release security review

## Files to Read

### Flutter (Frontend)
```
lib/features/checkout/checkout_provider.dart              # Computed providers (tax, totals, platform fee)
lib/features/checkout/orignabase_checkout_provider.dart   # Checkout state machine (circuit breakers, biometric guard)
lib/features/checkout/checkout_state.dart                 # State shape
lib/screens/checkout_screen.dart                          # Checkout UI
lib/screens/parts/checkout_address_section.dart           # Address validation
lib/screens/parts/checkout_payment_section.dart           # Payment UI
lib/screens/parts/checkout_summary_section.dart           # Order summary
lib/screens/ordersuccess_screen.dart                      # Post-payment
lib/screens/payment_screens.dart                          # Payment screens
lib/core/repositories/orignabase_order_repository.dart    # createCheckoutSession, capturePayment
lib/services/checkout_service.dart                        # Checkout service abstraction
```

### Backend (Rust — OrignaBase)
```
OrignaBase handlers:
  /stripe/webhook          — Webhook receiver
  /payments/checkout       — Checkout session creation
  /payments/capture        — Payment capture
  /payments/refund         — Refund processing
  /orders/create           — Order creation from checkout
```

---

## Audit Checkpoints

### 1. Checkout Session Creation

**The entire checkout flow: Flutter → OrignaBase → Stripe → back.**

```
DATA FLOW:
  Flutter: ref.read(checkoutProvider.notifier).startCheckout()
    → OrignaBaseCheckoutNotifier.startCheckout()
      → verifyCartPrices()           # Server-side price check
      → calculateShipping()          # Per-seller shipping
      → biometric guard (≥$100)      # Biometric auth
      → OrderRepository.createCheckoutSession()
        → POST ApiEndpoints.checkoutSession
          → OrignaBase: creates Stripe Checkout Session
            → returns session_url
      → opens session_url
```

**Check:**
- [ ] Session created SERVER-SIDE only (Flutter never touches Stripe API directly)
- [ ] `line_items` prices come from server, not client cart
- [ ] `metadata.order_id` included in session
- [ ] `success_url` points to a PENDING page, not CONFIRMED page
- [ ] `cancel_url` returns to cart without losing items
- [ ] Session has `expires_at` set (Stripe default: 24h)
- [ ] No `payment_intent_data.amount` passed — Stripe calculates from line_items
- [ ] For Connect: `payment_intent_data.application_fee_amount` set correctly
- [ ] For Connect: `payment_intent_data.transfer_data.destination` set

**Grep for:** `CheckoutSession`, `checkout.sessions.create`, `success_url`, `cancel_url`, `application_fee_amount`, `metadata`

### 2. Idempotency — 3-Layer Defense

**Stripe's own defense model (from their blog):**

```
LAYER 1: API Idempotency Key
  - Every Stripe API call includes Idempotency-Key header
  - Format: <order_id>-<action> (e.g., "ord_abc123-checkout")
  - Stripe caches response for 24h, returns cached on retry
  - If same key + different params → Stripe returns error

LAYER 2: Database Constraint
  - Unique constraint on (orderId, status) or (orderId, eventType)
  - Even if idempotency cache fails, DB rejects duplicate
  - SurrealDB: UNIQUE constraint or upsert pattern

LAYER 3: Application Logic
  - Check if order already confirmed before processing
  - Check if webhook event already processed
  - Atomic check + process in single transaction
```

**Check:**
- [ ] Idempotency key included in ALL Stripe API calls (not just charges)
- [ ] Key format: `<order_id>-<action>` (traceable, deterministic)
- [ ] `createCheckoutSession()` uses idempotency key
- [ ] `capturePayment()` uses idempotency key
- [ ] Refund uses idempotency key: `<order_id>-refund`
- [ ] DB has unique constraint preventing duplicate order confirmations
- [ ] Webhook handler checks `event.id` before processing
- [ ] `webhook_events` collection stores processed event IDs

**Grep for:** `idempotency`, `Idempotency-Key`, `UNIQUE`, `already.*processed`, `event.id`, `webhook_event`

### 3. Webhook Processing

**The most dangerous part of any Stripe integration.**

```
BUG PATTERN (Stripe docs):
  - Parsed JSON body breaks HMAC signature verification
  - Must use rawBody (bytes) for construct_event()
  
BUG PATTERN (WC Stripe #3300):
  - Duplicate webhook events → double notes, double emails
  - No dedup on event.id
  
BUG PATTERN (WC PayPal #4110):
  - Browser return URL + webhook BOTH process payment
  - Two orders, two charges, same timestamp
```

**Check:**
- [ ] Signature verification uses `rawBody` (bytes), NOT parsed JSON
- [ ] `STRIPE_WEBHOOK_SECRET` loaded from env vars, not hardcoded
- [ ] Signature verified BEFORE any business logic
- [ ] Invalid signatures → 400 response (not 500)
- [ ] Webhook secret differs per environment (dev ≠ prod)
- [ ] Idempotency check on `event.id` before processing
- [ ] 200 returned immediately, processing async
- [ ] Event ordering not assumed (payment_intent.succeeded may arrive first)
- [ ] `webhook_events.timestamp` field uses `createdAt` or `timestamp`
- [ ] Failed webhook processing logged for manual review

**Grep for:** `webhook`, `construct_event`, `rawBody`, `signature`, `STRIPE_WEBHOOK_SECRET`, `event.id`, `payment_intent.succeeded`, `checkout.session.completed`

### 4. Amount Integrity

**Real bug: MedusaJS #13160. $9.99 → 99,900 cents (100× overcharge).**

```
BUG PATTERN:
  // Code stores prices in cents: 1999
  // Stripe API also expects cents
  // But code does: amount = priceCents * 100  ← DOUBLE CONVERSION
  // Stripe receives 199,900 = $1,999.00 instead of $19.99

SAFE:
  amount: totalAmountCents  // Direct pass-through, no conversion
```

**Check:**
- [ ] EVERY monetary field is integer cents
- [ ] NO `* 100` or `/ 100` near Stripe API calls
- [ ] `amount` in Stripe calls = `totalAmountCents` (direct)
- [ ] Tax calculated in cents: `subtotalCents * taxRate ~/ 100`
- [ ] Platform fee in cents: `platformFeeTotalCents`
- [ ] Display formatting: `'$${(cents / 100).toStringAsFixed(2)}'` (UI only)
- [ ] No `double`/`float` used for money anywhere in checkout path
- [ ] Currency code matches: `CAD` for Canadian marketplace

**Grep for:** `* 100`, `/ 100`, `toDouble`, `double.*price`, `double.*amount`, `double.*total`, `double.*fee`, `double.*cost`

### 5. Platform Fee (Stripe Connect)

**Real bug: Stripe Connect #2212. Estonia platform + Mexico account = no application fee, platform negative balance.**

```
CHARGE TYPES (from Stripe docs):
  Direct charges:
    - Refund debited from connected account
    - Platform keeps application fee on refund
  
  Destination charges:
    - Refund debited from PLATFORM balance
    - Need transfer_reversal to recover from connected account
  
  Separate charges:
    - Refund debited from PLATFORM balance
    - Need transfer_reversal to recover
```

**Check:**
- [ ] Platform fee calculated on `subtotalCents` NOT `totalAmountCents`
- [ ] Platform fee = percentage of subtotal, not including shipping/tax
- [ ] `application_fee_amount` ≤ payment amount
- [ ] Platform country supports application fees for connected account countries
- [ ] On refund: transfer reversed to recover funds from seller
- [ ] Platform fee NOT refunded to buyer (non-refundable)
- [ ] Seller balance checked before refund (sufficient funds)
- [ ] If insufficient balance: refund queued as "pending" (Stripe handles)

**Grep for:** `application_fee_amount`, `transfer_data`, `platformFee`, `platform_fee`, `transfer_reversal`, `connected_account`

### 6. Refund Processing

**From Stripe docs: "You can issue multiple partial refunds until the original amount is exhausted, within 180 days."**

**Check:**
- [ ] Refund amount ≤ original payment amount
- [ ] Total partial refunds tracked per order
- [ ] Refund uses idempotency key: `<order_id>-refund`
- [ ] Correct `payment_intent` ID used for refund
- [ ] For Connect: transfer reversed after refund
- [ ] Stock restored after refund confirmed
- [ ] Order status updated to `refunded`/`returned`
- [ ] Refund reason captured
- [ ] Original Stripe processing fee NOT refunded (sunk cost)
- [ ] Platform fee NOT refunded to buyer

**Grep for:** `Refund`, `refund`, `createRefund`, `payment_intent`, `refund_amount`, `refund.*reason`

### 7. Redirect vs Webhook (THE Duplicate Charge Root Cause)

**7 closed GitHub issues: WooCommerce Stripe #3638, #2339, #831; WooCommerce PayPal #4110, #3946, #3788; WC Stripe #3300.**

```
ROOT CAUSE (from all 7 issues):
  1. Browser redirect hits success_url → processes payment
  2. Webhook hits /stripe/webhook → ALSO processes payment
  3. No mutex/lock prevents both from running
  4. Result: duplicate orders, duplicate charges, double stock

SAFE PATTERN:
  success_url → shows "Processing..." page
  → Polls order status until webhook confirms
  → Only then shows "Order Confirmed"
  
  webhook → ONLY path that confirms order
  → Decrements stock
  → Clears cart
  → Sends confirmation email
```

**Check:**
- [ ] `ordersuccess_screen.dart` shows "Processing" state, not immediate "Confirmed"
- [ ] Stock decremented ONLY in webhook path
- [ ] Cart cleared ONLY in webhook path
- [ ] Confirmation email sent ONLY in webhook path
- [ ] Success page polls/waits for webhook confirmation
- [ ] Unique constraint prevents duplicate order confirmation
- [ ] If redirect arrives first: order stays in "pending" until webhook
- [ ] If webhook arrives first: redirect just shows confirmed order

**Grep for:** `Order Confirmed`, `clearCart`, `decrement.*stock`, `sendEmail`, `confirmation` in success screen + webhook handler

### 8. Error Handling (OWASP A10:2025 — Mishandling Exceptional Conditions)

**New OWASP 2025 category. Payment systems must handle EVERY edge case.**

**Check:**
- [ ] Stripe API errors caught and displayed to user (not swallowed)
- [ ] Network timeout during checkout → user notified, not left hanging
- [ ] Stripe rate limit (429) → retry with backoff
- [ ] Session expired → user redirected to cart with explanation
- [ ] Payment declined → clear error message, retry option
- [ ] 3DS authentication failed → user can retry or use different card
- [ ] Webhook processing failure → logged, not silently dropped
- [ ] Circuit breaker trips → graceful degradation (queue, not crash)
- [ ] All Stripe exceptions mapped to user-friendly messages

**Grep for:** `catch`, `onError`, `try.*catch`, `StripeError`, `StripeException`, `circuit`, `timeout`

---

## Test Card Matrix

| Card | Behavior | Use For |
|------|----------|---------|
| `4242 4242 4242 4242` | Success | Happy path |
| `4000 0025 0000 3155` | Requires 3DS | 3DS flow |
| `4000 0000 0000 9995` | Decline | Decline handling |
| `4000 0000 0000 0341` | Failed (attach) | Card attach failure |
| `4000 0027 6000 3184` | Requires 3DS2 | 3DS2 flow |
| `4000 0082 6000 3178` | Debit card | Debit handling |

**NEVER use real cards in dev/staging.**

---

## Report Format

```
═══════════════════════════════════════════════
STRIPE AUDIT REPORT
═══════════════════════════════════════════════
Date: [ISO 8601]
Integration: OrignaBase + OrignaGTA Flutter

CHECKOUT SESSION:      [PASS/FAIL]
IDEMPOTENCY (3-layer): [PASS/FAIL]
WEBHOOK PROCESSING:    [PASS/FAIL]
AMOUNT INTEGRITY:      [PASS/FAIL]
PLATFORM FEE:          [PASS/FAIL]
REFUND PROCESSING:     [PASS/FAIL]
REDIRECT vs WEBHOOK:   [PASS/FAIL]
ERROR HANDLING:        [PASS/FAIL]

CRITICAL FINDINGS:
1. [file:line] Description → Fix

HIGH FINDINGS:
1. [file:line] Description → Fix

VERDICT: SAFE / CHANGES REQUIRED / BLOCKED
═══════════════════════════════════════════════
```
