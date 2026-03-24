---
name: flow-audit
description: "Deep audit of OrignaGTA e-commerce flows. Traces the real data path (Screen → ref.read(notifier) → ViewModel → Repository → OrignaBase SDK → GraphQL → SurrealDB → back) for 12 critical flows. Grounded in Stripe docs, OWASP e-commerce top 10, and real production bugs (double checkout, stock race conditions, webhook idempotency failures). Finds logic bugs, race conditions, missing error handling, and security gaps. Use when asked to 'audit a flow', 'deep logic audit', 'trace checkout', 'find bugs', 'review orders', or similar."
---

# Flow Audit — OrignaGTA

Deep audit of 12 e-commerce flows. Each audit follows a buyer buying a product end-to-end: browsing → cart → checkout → payment → order → delivery → return. Grounded in Stripe best practices, real production bugs, and OWASP patterns.

## Why This Skill Exists

Real e-commerce bugs that destroyed production systems:

| Bug | Source | Impact |
|-----|--------|--------|
| Double checkout: one click → two payments | WooCommerce ACDC race condition (Feb 2026) | Orders marked Failed before 3DS completes |
| Stock race condition: two users buy last item simultaneously | Production inventory systems | Overselling, manual refunds, broken trust |
| Webhook double-processing: Stripe retries cause duplicate charges | Stripe webhook docs + idempotency guard repos | Double credit, corrupted state |
| Price manipulation: client sends price, server trusts it | Common in AI-generated checkout code | Free products |
| Payment abandonment: stock locked forever when user bounces | Real production systems | Permanent inventory loss |
| Transfer reversal missing on refunds: platform eats the cost | Stripe Connect docs | Platform liability |

---

## How To Audit

### Data Flow Template

Every audit traces this exact path. At each step, check the specific criteria below.

```
1. Screen (UI)
   └─ User taps button, ref.read(provider.notifier).method()
   
2. ViewModel (StateNotifier / AsyncNotifier)
   └─ state = AsyncLoading()
   └─ await repository.method()
   └─ state = await AsyncValue.guard(() async { ... })
   
3. Repository (lib/core/repositories/)
   └─ OrignaBase SDK call or HTTP POST
   └─ Handles typed exceptions (AppError, OrignaBaseException)
   
4. OrignaBase SDK (client.graphql())
   └─ jsonEncode(jsonEncode(data)) — double encoding
   └─ Attaches JWT Authorization header
   
5. Server (Rust axum handlers)
   └─ normalize_data() — parses double-encoded JSON
   └─ Resolver logic: validation, auth check, business rules
   └─ SurrealDB: query_bind() with $params — NEVER format!()
   
6. SurrealDB
   └─ Atomic operations, transactions
   └─ Returns Result<Value>
   
7. Response path (reverse)
   └─ Server → JSON → SDK → Repository → ViewModel → Screen
   └─ Screen: ref.watch(provider).when(data: ..., loading: ..., error: ...)
```

### Per-Step Checklist (apply at EVERY step)

| Check | What to look for |
|-------|-----------------|
| **Input validation** | Is data validated BEFORE it enters the system? At boundaries, not deep in call chains. |
| **Auth/ownership** | Does the code verify the user OWNS this resource? Can user A access user B's data? |
| **Error handling** | Is every error caught and handled? Empty catch blocks? Swallowed errors? |
| **Race conditions** | Can two concurrent requests corrupt state? Read-then-write vs atomic? |
| **Idempotency** | If this operation runs twice, does it produce the same result? Critical for payments + webhooks. |
| **Amount integrity** | Is money in integer cents? Does the client ever send price data the server trusts? |
| **State machine** | Are state transitions enforced? Can you skip steps? Reverse order? |

---

## Flow 1: Buyer Purchases a Product (End-to-End)

**This is the most critical flow. It covers the entire purchase path: browse → cart → checkout → pay → order created.**

### Files to read (in order):
```
1. lib/screens/home_screen.dart                          # Browse
2. lib/screens/productdetails_screen.dart                # View product
3. lib/features/products/product_actions_viewmodel.dart  # Add to cart action
4. lib/core/repositories/orignabase_cart_repository.dart # Cart persistence
5. lib/screens/cart_screen.dart                          # Cart UI
6. lib/screens/checkout_screen.dart                      # Checkout UI
7. lib/features/checkout/orignabase_checkout_provider.dart # Checkout state machine
8. lib/features/checkout/checkout_provider.dart          # Computed providers (tax, totals)
9. lib/core/repositories/orignabase_order_repository.dart # Order creation
10. lib/screens/ordersuccess_screen.dart                 # Post-payment
```

### Checkpoint 1: Add to Cart — Stock Race Condition
**The #1 e-commerce bug. Two users click "Add to Cart" for the last item simultaneously.**

```
REAL BUG PATTERN (from production systems):
  // DANGEROUS — read then write
  const stock = await db.getStock(productId);
  if (stock > 0) {
    await db.addToCart(productId);  // Another request may have taken the last one
  }
  
  // SAFE — atomic conditional decrement
  await db.query("UPDATE products SET stock = stock - 1 
    WHERE id = $id AND stock >= 1");
  // If affected_rows == 0 → out of stock
```

**Audit questions:**
- [ ] Does `addToCart()` in `orignabase_cart_repository.dart` check stock AT ALL?
- [ ] Is stock check atomic or read-then-write?
- [ ] If read-then-write: is there a SurrealDB transaction wrapping the check + decrement?
- [ ] What happens if stock goes to 0 between the check and the cart write?
- [ ] Does quantity accumulation (`addToCart` with existing item) validate stock for the NEW total?

**Grep for:** `stockQuantity`, `stock`, `quantity` in cart repository. Check if conditional queries exist.

### Checkpoint 2: Cart → Checkout — Price Verification
**The client must NEVER send price data the server trusts. Prices must be verified server-side.**

```
REAL BUG PATTERN:
  // Client sends: { productId: "abc", price: 0.01 }
  // Server uses client price → free products
  
  // SAFE — server fetches price
  const product = await db.getProduct(productId);
  const serverPrice = product.priceCents;
```

**Audit questions:**
- [ ] Does `orignabase_checkout_provider.dart` call `verifyCartPrices()`?
- [ ] What does `verifyCartPrices()` actually do? Does it compare cart prices against server prices?
- [ ] If prices drift (cart cached a stale price), what happens? Fail-open or fail-closed?
- [ ] Are prices stored as integer cents throughout? Any `double` / `float` for money?
- [ ] Does `checkoutTotalProvider` use the verified prices or cart-displayed prices?

**Grep for:** `verifyCartPrices`, `priceCents`, `price`, `toDouble`, `toDoubleAsFixed` in checkout files.

### Checkpoint 3: Checkout Session — Double Checkout (Race Condition)
**THE MOST DANGEROUS BUG: one "Pay" click creates two payment intents.**

```
REAL BUG (WooCommerce ACDC, Feb 2026):
  Two concurrent POST requests fire when "Place Order" is clicked.
  First creates PayPal order (201).
  Second immediately marks WooCommerce order as Failed.
  3DS authentication never completes. Payment abandoned.
  
REAL BUG (Medium, Oct 2025):
  Network delay → user clicks "Submit" twice.
  Same payload, same order_id, two transactions.
  Bank returns "approved" for BOTH.
  Two settlements, one customer.
```

**Audit questions:**
- [ ] Does `startCheckout()` have UI debouncing? (disable button after first tap)
- [ ] Is there an idempotency key for the checkout session creation?
- [ ] If `createCheckoutSession()` is called twice with the same order_id, does it return the SAME session or create a NEW one?
- [ ] Is there a circuit breaker on Stripe calls (visible in `orignabase_checkout_provider.dart`)?
- [ ] Does the backend check for existing pending session before creating new one?
- [ ] What happens if the user closes the browser mid-checkout? Does the session expire? Is stock restored?

**Grep for:** `idempotency`, `duplicate`, `existing.*session`, `circuit`, `_stripeCallCount` in checkout files.

### Checkpoint 4: Payment Success — Webhook vs Redirect
**NEVER confirm an order based on a URL redirect. Always wait for the Stripe webhook.**

```
REAL BUG PATTERN:
  // DANGEROUS — confirm on redirect
  success_url: "https://app.com/order/confirmed?session_id=..."
  // User can visit this URL without paying → free order
  
  // SAFE — redirect to pending page, wait for webhook
  success_url: "https://app.com/order/pending?session_id=..."
  // Webhook: payment_intent.succeeded → confirm order
```

**Audit questions:**
- [ ] Does `ordersuccess_screen.dart` wait for webhook confirmation or confirm immediately on load?
- [ ] Is the success page a "processing" state that polls/waits, or does it immediately show "Order Confirmed"?
- [ ] Where is the webhook handler? (Should be in OrignaBase backend, not Flutter)
- [ ] Does the webhook verify the signature (HMAC with `rawBody`, not parsed JSON)?
- [ ] Is there idempotency checking on webhook events? (store processed event IDs)
- [ ] Does the webhook handle out-of-order delivery? (Stripe does NOT guarantee ordering)

**Grep for:** `webhook`, `payment_intent.succeeded`, `checkout.session.completed`, `signature`, `constructEvent` in order repo + backend.

### Checkpoint 5: Post-Payment — Cart Clearing Timing
**Cart must be cleared AFTER order is confirmed by webhook, NOT after redirect.**

```
REAL BUG PATTERN:
  // DANGEROUS — clear cart on redirect
  success_url → clearCart()
  // If webhook fails, order never confirmed, cart is gone
  
  // SAFE — clear cart in webhook handler after confirmation
  webhook: payment_intent.succeeded → confirmOrder() → clearCart()
```

**Audit questions:**
- [ ] When is `clearCart()` called? On redirect or in the webhook confirmation path?
- [ ] If webhook is delayed, does the user still see their cart items?
- [ ] If the user navigates away during "processing", can they still see their cart?

**Grep for:** `clearCart`, `clear_cart`, `removeAll` in checkout and order success flows.

### Checkpoint 6: Amount Integrity
**Every monetary value must be integer cents. Stripe API also uses integer cents.**

```
REAL BUG PATTERN:
  // DANGEROUS — float for money
  double total = items.fold(0.0, (sum, item) => sum + item.price * item.qty);
  // Floating point: 0.1 + 0.2 = 0.30000000000000004
  
  // SAFE — integer cents
  int totalCents = items.fold(0, (sum, item) => sum + item.priceCents * item.qty);
```

**Audit questions:**
- [ ] Is EVERY monetary field in the codebase an `int` (cents)? Search for `double` near money concepts.
- [ ] Does `checkoutTotalProvider` calculate with integer cents?
- [ ] Are tax calculations done in cents? (13% HST on $10.00 = 130 cents, not 1.3 dollars)
- [ ] Is `platformFeeTotalCents` calculated on `subtotalCents` (NOT `totalAmountCents`)?
- [ ] Is display formatting done ONLY at the UI layer? (`'$${(cents / 100).toStringAsFixed(2)}'`)
- [ ] Does the Stripe API call pass integer amounts directly (no conversion)?

**Grep for:** `toDouble`, `double.*price`, `double.*amount`, `double.*cost`, `double.*fee` across all Dart files.

---

## Flow 2: Stripe Webhook Processing

### Files to read:
```
1. OrignaBase backend: /stripe/webhook endpoint (Rust)
2. lib/core/repositories/orignabase_order_repository.dart # Order updates
3. lib/features/orders/buyer_orders_viewmodel.dart       # UI state
4. lib/features/checkout/orignabase_checkout_provider.dart # Post-checkout state
```

### Checkpoint 1: Signature Verification (CRITICAL)
**Without HMAC verification, anyone can send fake webhook events.**

```
REAL BUG PATTERN:
  // DANGEROUS — no signature check
  async fn handle_webhook(body: Json<StripeEvent>) -> Result<()> {
    match event.type { ... }  // Trusts any request
  }
  
  // SAFE — verify signature
  async fn handle_webhook(body: Bytes, headers: HeaderMap) -> Result<()> {
    let sig = headers.get("stripe-signature").ok_or(...)?;
    let secret = env::var("STRIPE_WEBHOOK_SECRET")?;
    let event = stripe::Webhook::construct_event(&body, sig.to_str()?, secret.as_bytes())?;
    // Now event is verified
  }
```

**Audit questions:**
- [ ] Does the webhook handler use `rawBody` (bytes) or parsed JSON? (Parsed breaks HMAC)
- [ ] Is `STRIPE_WEBHOOK_SECRET` loaded from env vars, never hardcoded?
- [ ] Is signature verification done BEFORE any business logic?
- [ ] Are invalid signatures rejected with 400 (not 500)?

### Checkpoint 2: Idempotency (CRITICAL)
**Stripe delivers webhooks with at-least-once guarantee. Duplicate events WILL happen.**

```
REAL BUG PATTERN:
  // DANGEROUS — no dedup
  async fn handle_payment_succeeded(event) {
    db.confirm_order(order_id);     // First call
    db.decrement_stock(order_id);   // First call
    // Stripe retries → confirm_order again → stock decremented TWICE
  }
  
  // SAFE — idempotency check
  async fn handle_payment_succeeded(event) {
    if db.webhook_event_exists(&event.id).await? { return Ok(()); }
    db.record_webhook_event(&event.id).await?;
    // Now safe to process
  }
```

**Audit questions:**
- [ ] Is there a `webhook_events` collection/table that tracks processed event IDs?
- [ ] Is the idempotency check ATOMIC with the business logic? (transaction)
- [ ] If the app crashes between idempotency check and business logic, what happens on retry?
- [ ] Does the idempotency check use `event.id` (Stripe's unique ID)?
- [ ] Is the webhook_events timestamp field `createdAt` or `timestamp`? (orders use `createdAt`)

### Checkpoint 3: Event Ordering
**Stripe does NOT guarantee webhook ordering. `payment_intent.succeeded` may arrive before `checkout.session.completed`.**

**Audit questions:**
- [ ] Does the code assume events arrive in order?
- [ ] Can `payment_intent.succeeded` process before the order record exists?
- [ ] Is there defensive coding: "if order not found, create it from webhook data"?

### Checkpoint 4: Webhook Response Time
**Return 200 immediately. Process asynchronously. Stripe retries after 10s timeout.**

**Audit questions:**
- [ ] Does the webhook handler do heavy work synchronously?
- [ ] Is the 200 response sent BEFORE or AFTER business logic completes?
- [ ] Is there a queue/background worker for processing?

---

## Flow 3: Order Lifecycle & State Machine

### Files to read:
```
1. lib/features/orders/buyer_orders_viewmodel.dart
2. lib/features/orders/seller_orders_viewmodel.dart
3. lib/core/repositories/orignabase_order_repository.dart
4. lib/screens/order_detail_screen.dart
5. lib/screens/seller_orders_screen.dart
```

### State Machine
```
pending → confirmed → shipped → delivered
        ↘ cancelled (from pending or confirmed only)

delivered = terminal (no further transitions)
cancelled = terminal (no further transitions)
```

### Checkpoint 1: State Transition Enforcement
```
REAL BUG PATTERN:
  // DANGEROUS — no validation
  await updateOrderStatus(orderId, newStatus);
  // User can send: pending → delivered (skipping confirmed + shipped)
  
  // SAFE — validate transition
  const validTransitions = {
    pending: ['confirmed', 'cancelled'],
    confirmed: ['shipped', 'cancelled'],
    shipped: ['delivered'],
  };
  if (!validTransitions[order.status]?.includes(newStatus)) {
    throw new Error(`Invalid transition: ${order.status} → ${newStatus}`);
  }
```

**Audit questions:**
- [ ] Is there a valid-transition map enforced server-side?
- [ ] Can a client skip states? (pending → delivered directly?)
- [ ] Can a client reverse states? (delivered → pending?)
- [ ] Who can trigger each transition? (buyer vs seller vs admin)
- [ ] Can buyer confirm delivery for someone else's order?
- [ ] Can seller mark as delivered? (Only buyer should confirm delivery)

### Checkpoint 2: Stock Management
```
REAL BUG PATTERN:
  // DANGEROUS — decrement on checkout (not confirmation)
  checkout() → decrementStock()
  // User abandons payment → stock permanently lost
  
  // SAFE — decrement on confirmation only
  webhook: payment_succeeded → decrementStock() atomically
  // Stock restored on cancellation or timeout
```

**Audit questions:**
- [ ] When is stock decremented? On checkout or on payment confirmation?
- [ ] When is stock restored? On cancellation? On timeout?
- [ ] Is stock decrement atomic? (`UPDATE products SET stock -= $qty WHERE stock >= $qty`)
- [ ] Is stock restoration atomic?
- [ ] What happens if stock restoration fails after cancellation?

### Checkpoint 3: Payment Abandonment Recovery
```
REAL PRODUCTION PATTERN:
  User begins checkout → stock reserved (atomic decrement)
  User bounces / network fails → payment never completes
  After timeout (e.g., 30 min) → stock restored automatically
  
  Without recovery: stock locked forever, inventory slowly drains
```

**Audit questions:**
- [ ] Is there a timeout mechanism for abandoned checkouts?
- [ ] If user closes browser mid-checkout, is stock eventually restored?
- [ ] Is there a background job that cleans up stale pending orders?

---

## Flow 4: Refunds & Returns

### Files to read:
```
1. lib/screens/return_request_screen.dart
2. lib/features/orders/return_request_viewmodel.dart
3. lib/core/repositories/orignabase_order_repository.dart (createReturnRequest)
4. OrignaBase backend: refund handler (Rust)
```

### Checkpoint 1: Refund Amount
**Stripe refunds: platform fee is NOT refunded to buyer. Refund = subtotal + tax + shipping, NOT + platform fee.**

**Audit questions:**
- [ ] Is the refund amount `subtotalCents` (not `totalAmountCents` which includes platform fee)?
- [ ] Is platform fee explicitly excluded from refund?
- [ ] For multi-seller orders: is each seller's portion refunded independently?
- [ ] Does the refund use an idempotency key? (`<order_id>-refund`)
- [ ] Is the Stripe refund created with the correct `payment_intent` ID?

### Checkpoint 2: Transfer Reversal (Stripe Connect)
**When refunding a Connect charge, the platform must reverse the transfer to recover funds from the seller.**

**Audit questions:**
- [ ] After refunding, is the transfer reversed? (Stripe Connect `transfer_reversal`)
- [ ] Does the seller's balance reflect the reversal?
- [ ] What if the seller has insufficient balance? (Stripe queues pending refunds)

### Checkpoint 3: Return Window
**Audit questions:**
- [ ] Is the return window enforced? (30 days from `deliveredAt`)
- [ ] Can a user request return for a `pending` order?
- [ ] Can a user request return twice for the same order?
- [ ] Is the return reason captured?

---

## Flow 5: Auth & Session

### Files to read:
```
1. lib/features/auth/auth_provider.dart
2. lib/core/repositories/orignabase_auth_repository.dart
3. lib/screens/login_screen.dart
4. lib/screens/mfa_challenge_screen.dart
5. lib/services/session_timeout_service.dart
```

### Checkpoint 1: Session Fixation
**Audit questions:**
- [ ] Is a new session token issued after login? (Not reusing pre-login token)
- [ ] Is the JWT validated on every request? (Not just at login)
- [ ] Can a user access protected routes without a valid token?

### Checkpoint 2: MFA Bypass
**Audit questions:**
- [ ] After password validation, is MFA enforced before granting access?
- [ ] Can the MFA challenge screen be skipped via direct navigation?
- [ ] Is the TOTP code validated server-side? (Not client-side comparison)

### Checkpoint 3: Rate Limiting
**Audit questions:**
- [ ] Is there rate limiting on login attempts? (5 per session/IP)
- [ ] Does `signInWithEmail()` handle rate-limit errors from the server?
- [ ] Is there exponential backoff on repeated failures?

---

## Flow 6: Seller Product Management

### Files to read:
```
1. lib/screens/addproduct_screen.dart
2. lib/features/products/add_product_viewmodel.dart
3. lib/screens/editproduct_screen.dart
4. lib/features/products/edit_product_viewmodel.dart
5. lib/screens/parts/addproduct_*.dart (all)
```

### Checkpoint 1: Ownership
**Audit questions:**
- [ ] Can user A edit user B's product? (Server must check `sellerId == currentUser.uid`)
- [ ] Can a non-seller create products?
- [ ] Can a seller with incomplete Stripe onboarding publish products?

### Checkpoint 2: Image Upload Security
**Audit questions:**
- [ ] Is image upload using presigned URL flow? (2-step: presign → PUT)
- [ ] Are file type, size, and count limits enforced?
- [ ] Are uploaded URLs validated to prevent SSRF?
- [ ] Is there image processing/optimization on the server?

### Checkpoint 3: Price Manipulation
**Audit questions:**
- [ ] Is price stored as integer cents? (No float conversion)
- [ ] Can a product be created with negative price?
- [ ] Can a product be created with price = 0? (Is that intentional?)

---

## Flow 7: Multi-Seller Cart & Order Splitting

### Files to read:
```
1. lib/features/checkout/orignabase_checkout_provider.dart (calculateShipping)
2. lib/core/repositories/orignabase_order_repository.dart
3. lib/features/checkout/checkout_provider.dart (checkoutPlatformFeeProvider)
```

### Checkpoint 1: Order Splitting
**Audit questions:**
- [ ] When cart has items from 3 sellers, are 3 separate orders created?
- [ ] Does each sub-order have its own state machine?
- [ ] Is shipping calculated per-seller (from each seller's warehouse)?
- [ ] Is the Stripe Checkout Session amount the SUM of all sub-orders?

### Checkpoint 2: Platform Fee
**Audit questions:**
- [ ] Is platform fee calculated on `subtotalCents` NOT `totalAmountCents`?
- [ ] Platform fee = percentage of subtotal, not including shipping/tax?
- [ ] Is platform fee collected via `application_fee_amount` in Stripe Connect?
- [ ] Platform fee is non-refundable on buyer refunds — is this enforced?

---

## Flow 8: Search & Discovery

### Files to read:
```
1. lib/screens/home_screen.dart (search)
2. lib/features/home/home_viewmodel.dart
3. lib/screens/product_card_screen.dart
```

### Checkpoint 1: Meilisearch Injection
**Audit questions:**
- [ ] Are search queries sanitized before hitting Meilisearch?
- [ ] Can Meilisearch filter syntax be injected? (e.g., `status = published`)
- [ ] Are unpublished products excluded from search results server-side?

### Checkpoint 2: Pagination
**Audit questions:**
- [ ] Is pagination cursor-based or offset-based?
- [ ] Does infinite scroll have duplicate detection?
- [ ] Is there a max limit on page size?

---

## Flow 9: Notifications & Push

### Files to read:
```
1. lib/services/orignabase_notification_service.dart
2. lib/services/push_transport.dart
3. lib/screens/notifications_screen.dart
```

### Checkpoint 1: Deep Linking Security
**Audit questions:**
- [ ] Can a notification deep-link to an unauthorized screen?
- [ ] Is the deep link target validated against the user's permissions?
- [ ] Can a malicious notification redirect to an external URL?

### Checkpoint 2: Token Management
**Audit questions:**
- [ ] Is the FCM token refreshed on app update?
- [ ] Is the old token invalidated on logout?
- [ ] Can stale tokens cause notifications to go to wrong users? (Device transfer)

---

## Flow 10: Seller Onboarding & Stripe Connect

### Files to read:
```
1. lib/screens/seller_registration_screen.dart
2. lib/features/seller/seller_registration_view_model.dart
3. lib/features/seller/seller_account_status_viewmodel.dart
```

### Checkpoint 1: Onboarding Bypass
**Audit questions:**
- [ ] Can a seller list products before Stripe onboarding is complete?
- [ ] Is the onboarding status verified via Stripe API (not just a local boolean)?
- [ ] Can a seller register with another user's Stripe account?

### Checkpoint 2: Payout Timing
**Audit questions:**
- [ ] Is payout triggered ONLY after delivery confirmation?
- [ ] Can a seller mark their own order as delivered to trigger payout? (Only buyer)
- [ ] Is there a delay/pending period for new sellers?

---

## Flow 11: User Profile & Addresses

### Files to read:
```
1. lib/screens/profile_screen.dart
2. lib/screens/addressmanagement_screen.dart
3. lib/features/profile/address_management_viewmodel.dart
4. lib/screens/security_settings_screen.dart
```

### Checkpoint 1: Input Sanitization
**Audit questions:**
- [ ] Is the user's display name sanitized? (XSS, script injection)
- [ ] Are address fields validated? (Max lengths, required fields)
- [ ] Is there a max address limit per user?

### Checkpoint 2: MFA Management
**Audit questions:**
- [ ] Can MFA be disabled without re-authentication?
- [ ] Is MFA setup verified before marking as enabled?
- [ ] Can a user lock themselves out by enabling MFA without backup codes?

---

## Flow 12: Subscriptions

### Files to read:
```
1. lib/screens/subscription_screen.dart
2. lib/screens/subscription_cancel_screen.dart
3. lib/features/subscription/ (all files)
```

### Checkpoint 1: Subscription State
**Audit questions:**
- [ ] Is subscription status checked server-side before allowing seller actions?
- [ ] Can expired subscriptions still list/fulfill orders?
- [ ] Is cancellation handled via Stripe webhook (not just client-side)?

---

## Reporting Findings

For each bug found:

```
═══════════════════════════════════════════════
SEVERITY: CRITICAL | HIGH | MEDIUM | LOW
FLOW: [flow name]
LOCATION: file.dart:line → file.dart:line (cross-stack trace)
───────────────────────────────────────────────
DESCRIPTION:
  [What's wrong — be specific about the code path]

PROOF:
  [How to reproduce / what input triggers the bug]

IMPACT:
  [What happens to users / data / money]

REAL-WORLD REFERENCE:
  [Similar bug in production systems — WooCommerce, Stripe docs, etc.]

FIX:
  [Exact change needed — code-level, not vague]
───────────────────────────────────────────────
VERIFICATION:
  [How to confirm the fix works]
═══════════════════════════════════════════════
```

### Severity (grounded in business impact)

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | Financial loss, data breach, auth bypass. Users lose money or data. | Double charge, stock manipulation, webhook forgery |
| **HIGH** | Wrong behavior that affects real users. Race conditions. Missing validation. | Stock oversold, wrong order status, price manipulation |
| **MEDIUM** | UX bugs, missing error states, degraded performance. | Empty cart error, missing loading state, slow pagination |
| **LOW** | Cosmetic, missing edge case, minor style violation. | Wrong badge color, missing tooltip, off-by-one in display |

---

## Summary Report Format

After auditing all flows:

```
FLOW AUDIT SUMMARY
═══════════════════════════════════════════════
Flows audited: 12
Total findings: X (CRITICAL: X, HIGH: X, MEDIUM: X, LOW: X)

TOP 5 PRIORITIES (fix these first):
1. [CRITICAL] flow → description
2. [CRITICAL] flow → description
3. [HIGH] flow → description
4. [HIGH] flow → description
5. [HIGH] flow → description

CLEAN FLOWS (no findings):
- Flow X: [name]

MOST DANGEROUS FLOW: [name] — [why]
═══════════════════════════════════════════════
```

---

## Key Files Reference

| Purpose | Path |
|---------|------|
| Environment config | `lib/utils/env_config.dart` |
| Auth providers | `lib/core/providers.dart` |
| Design tokens | `lib/utils/design_tokens.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
| Order models | `lib/models/generated/order_models.dart` |
| Seller models | `lib/models/generated/seller_profile_models.dart` |
| Checkout state | `lib/features/checkout/checkout_state.dart` |
| API endpoints | `lib/core/api/api_endpoints.dart` |
| Quality gate | `scripts/run_quality_gate.sh` |

---

## Running The Audit

```
/audit-workflow checkout    # Audit checkout + payment flow
/audit-workflow orders      # Audit order lifecycle
/audit-workflow all         # Audit all 12 flows
```

For `all`: run flows sequentially. Between flows, clear context to stay fresh. Produce summary at end.
