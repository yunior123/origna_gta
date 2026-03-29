---
name: flow-audit
description: "Deep audit of OrignaGTA e-commerce flows. Traces the real data path (Screen → ref.read(notifier) → ViewModel → Repository → OrignaBase SDK → GraphQL → PostgreSQL → back) for 12 critical flows. Grounded in Stripe docs, OWASP e-commerce top 10, and real production bugs (double checkout, stock race conditions, webhook idempotency failures, amount miscalculation, Riverpod race conditions). Finds logic bugs, race conditions, missing error handling, and security gaps. Use when asked to 'audit a flow', 'deep logic audit', 'trace checkout', 'find bugs', 'review orders', or similar."
---

# Flow Audit — OrignaGTA

Deep audit of 12 e-commerce flows. Each audit follows a buyer buying a product end-to-end: browse → cart → checkout → pay → order → delivery → return. Every checkpoint is grounded in a real production bug, GitHub issue, or industry standard.

## Why This Skill Exists

Real production bugs from GitHub issues, Stripe docs, and security research:

### Stock & Inventory Race Conditions

| Bug | Source | Impact | Date |
|-----|--------|--------|------|
| Concurrent checkout oversells last item: stock goes negative | Vendure [#3508](https://github.com/vendurehq/vendure/issues/3508) | Overselling on concurrent checkout | Apr 2025 |
| Stock goes negative on non-backorder items, busy site | WooCommerce [#44273](https://github.com/woocommerce/woocommerce/issues/44273) | Negative inventory, 2yr old open bug | Feb 2024 |
| Product oversold when multiple users purchase simultaneously | Magento [#3072](https://github.com/magento/inventory/issues/3072) | Overselling, closed after 5 years | Jun 2020 |
| Two users buy last item, stock goes -1 | Production e-commerce (Ram Mobiles, Medium) | Overselling, manual refunds | Feb 2026 |
| Race condition exploitation via Burp Suite parallel requests | TryHackMe Advent of Cyber 2025, Day 20 | Targeted attack, overselling | Dec 2025 |

### Duplicate Charges & Orders

| Bug | Source | Impact | Date |
|-----|--------|--------|------|
| Duplicate payment intents: customer charged twice for same order | WooCommerce Stripe [#3638](https://github.com/woocommerce/woocommerce-gateway-stripe/issues/3638) | Double charge, priority:high | Dec 2024 |
| Idempotency keys not preventing duplicate charges on payment_intents | WooCommerce Stripe [#2339](https://github.com/woocommerce/woocommerce-gateway-stripe/issues/2339) | Triple charge on subscription renewal | Apr 2022 |
| Duplicate Stripe charges for same order (~1 in 50 orders) | WooCommerce Stripe [#831](https://github.com/woocommerce/woocommerce-gateway-stripe/issues/831) | Double charges, customer complaints | Apr 2019 |
| Duplicate orders since 3.4.0: two PayPal charges from single checkout | WooCommerce PayPal [#4110](https://github.com/woocommerce/woocommerce-paypal-payments/issues/4110) | Double charge, regression | Feb 2026 |
| Duplicate orders for single PayPal transaction, double stock reduction | WooCommerce PayPal [#3946](https://github.com/woocommerce/woocommerce-paypal-payments/issues/3946) | Double stock, double shipping | Dec 2025 |
| Double order confirmations with PayPal, sporadic | WooCommerce PayPal [#3788](https://github.com/woocommerce/woocommerce-paypal-payments/issues/3788) | Double invoices, customer confusion | Oct 2025 |
| Duplicate webhook events processing causing double notes + emails | WooCommerce Stripe [#3300](https://github.com/woocommerce/woocommerce-gateway-stripe/pull/3300) | Double notifications, corrupted state | Jul 2024 |

### Checkout Race Conditions

| Bug | Source | Impact | Date |
|-----|--------|--------|------|
| Concurrent double-POST marks order Failed before 3DS completes | WooCommerce ACDC [#4099](https://github.com/woocommerce/woocommerce-paypal-payments/issues/4099) | Payment abandoned, no recovery | Feb 2026 |
| Voucher race condition: concurrent threads, payment auto-refunded | Saleor [#15849](https://github.com/saleor/saleor/pull/15849) | Voucher overspent, revenue loss | Apr 2024 |

### Amount & Pricing Bugs

| Bug | Source | Impact | Date |
|-----|--------|--------|------|
| $9.99 → 99,900 cents sent to Stripe (double ×100 conversion) | MedusaJS [#13160](https://github.com/medusajs/medusa/issues/13160) | 100× overcharge | Aug 2025 |
| Platform fee ignored: Estonia platform + Mexico connected account | Stripe Connect [#2212](https://github.com/stripe/stripe-node/issues/2212) | Platform eats all Stripe fees | Oct 2024 |

### Riverpod State Bugs

| Bug | Source | Impact | Date |
|-----|--------|--------|------|
| `ref.read()` returns stale value while `ref.listen()` has fresh state | Riverpod [#3879](https://github.com/rrousselGit/riverpod/issues/3879) | UI shows wrong data | Dec 2024 |
| Disposed notifier: `state =` throws `Future already completed` | Riverpod [#2506](https://github.com/rrousselGit/riverpod/issues/2506) | App crash | Apr 2023 |
| `ref.watch()` returns different value than `ref.read()` after side effect | Riverpod [#3889](https://github.com/rrousselGit/riverpod/issues/3889) | Stale UI, provider conflict | Dec 2024 |

---

## How To Audit

### Data Flow Template (OrignaGTA-Specific)

Every audit traces this exact path. At each step, check the specific criteria below.

```
1. Screen (lib/screens/)
   └─ User taps button
   └─ ref.read(provider.notifier).method()  ← Is this .read() or .watch()? .read() gets stale data!
   └─ Semantics(label: 'btn-*') present?

2. ViewModel (lib/features/*/ )
   └─ extends AsyncNotifier<T> or StateNotifier<T>
   └─ state = const AsyncLoading()           ← Does it reset loading state?
   └─ state = await AsyncValue.guard(() async { ... })  ← Errors caught?
   └─ If provider disposed mid-await: state = throws! (Riverpod #2506)

3. Repository (lib/core/repositories/)
   └─ OrignaBase SDK call or HTTP POST to ApiEndpoints.*
   └─ Handles typed exceptions (OrignaBaseException, AppError)
   └─ Does it use _rethrowAsAuthException() pattern?

4. OrignaBase SDK (client.graphql())
   └─ jsonEncode(jsonEncode(data)) — double encoding for GraphQL
   └─ Attaches JWT Authorization header automatically
   └─ FieldValue auto-detection → updateWithFieldValues mutation

5. Server (Rust axum handlers)
   └─ normalize_data() — parses double-encoded JSON string
   └─ Resolver: validation, auth check (Extension<User>), ownership check
    └─ PostgreSQL: query_bind() with $params — NEVER format!() (injection risk)

6. PostgreSQL
   └─ Atomic operations (UPDATE SET field = field - $qty WHERE field >= $qty)
   └─ Transactions (BEGIN/COMMIT) for multi-step operations
   └─ query_raw_value for aggregates (no id field in GROUP ALL)

7. Response path (reverse)
   └─ Server → JSON → SDK → Repository → ViewModel → Screen
   └─ Screen: ref.watch(provider).when(data: ..., loading: ..., error: ...)
   └─ Error state: SnackBar (transient) or inline (form)?
```

### Per-Step Checklist (apply at EVERY step)

| Check | What to look for | Why it matters |
|-------|-----------------|----------------|
| **Input validation** | Is data validated at boundaries? Before it enters the system? | OWASP A03: Injection |
| **Auth/ownership** | Does the code verify `user.id == resource.ownerId`? Can user A access user B's data? | OWASP A01: Broken Access Control |
| **IDOR** | Can user change an ID in the request to access another user's data? (`/orders?id=other_user_order`) | OWASP A01: IDOR — #1 web vuln |
| **Error handling** | Empty catch blocks? Swallowed errors? `AsyncValue.guard()` used? | Silent failures corrupt state |
| **Exceptional conditions** | What happens when Stripe times out? Network fails? DB unavailable? Rate limited? | OWASP A10:2025 — Mishandling Exceptional Conditions |
| **Race conditions** | Read-then-write vs atomic? Concurrent requests corrupt state? | WooCommerce #44273, Saleor #15849 |
| **Idempotency** | If this runs twice, same result? 3-layer defense? | Stripe at-least-once delivery |
| **Amount integrity** | Integer cents everywhere? Client sends price server trusts? Double ×100 conversion? | MedusaJS #13160 ($9.99 → $999) |
| **State machine** | Transitions enforced? Can you skip steps? Reverse? Terminal states? | Order lifecycle integrity |
| **DB isolation** | Correct isolation level for this operation? SERIALIZABLE for payments, READ COMMITTED + atomic for stock? | Academic research (WJAETS, 2025) |
| **Riverpod safety** | Is `ref.read()` used where `ref.watch()` is needed? Provider disposed mid-operation? | Riverpod #3879, #2506 |
| **SSRF** | Does image/product URL fetching validate against internal IPs? | OWASP A10: SSRF |
| **XSS** | User input rendered without sanitization? Profile names, product descriptions? | OWASP A03: Injection |

### Idempotency 3-Layer Defense (Stripe's Own Model)

Every critical operation (payment, webhook, stock change) must have ALL 3 layers:

```
LAYER 1: API Idempotency Key
  - Every Stripe API call includes Idempotency-Key header
  - Format: <order_id>-<action> (e.g., "ord_abc123-checkout")
  - Stripe caches response for 24h, returns cached on retry
  - If same key + different params → Stripe returns error
  - Generate key BEFORE request, store for retries

LAYER 2: Database Constraint
  - UNIQUE constraint on (orderId, eventType) or (orderId, status)
  - Even if idempotency cache fails, DB rejects duplicate
   - PostgreSQL: upsert (INSERT ... ON CONFLICT DO UPDATE) or UNIQUE constraint
  - Safety net if application logic has a bug

LAYER 3: Application Logic
  - Check if order already confirmed before processing
  - Check if webhook event already processed (event.id in webhook_events)
  - Atomic check + process in single DB transaction
  - "Is this order already confirmed?" before any mutation
```

**Grep for:** `idempotency`, `Idempotency-Key`, `UNIQUE`, `already.*processed`, `event.id`, `webhook_event`, `CHECK.*EXISTS`

### IDOR Detection Pattern (OWASP A01 — #1 Web Vulnerability)

**100% of tested applications have broken access control (OWASP 2025). IDOR is the most common form.**

```
IDOR PATTERN:
  // DANGEROUS — uses user-supplied ID without ownership check
  GET /orders/{orderId}
  // Can user A access user B's order by changing orderId?
  
  // SAFE — server verifies ownership
  GET /orders/{orderId}
  if order.userId != currentUser.id: return 403

VERTICAL ESCALATION:
  // Can a regular user call admin endpoints?
  POST /admin/products/delete → No role check → Admin bypass

HORIZONTAL ESCALATION:
  // Can user A edit user B's product?
  PUT /products/{productId} → No sellerId check → Cross-user edit
```

**For every flow, check:**
- [ ] Does the API endpoint verify the user OWNS the resource?
- [ ] Can a user access another user's orders by changing the ID?
- [ ] Can a user edit another user's products?
- [ ] Can a user view another user's profile, addresses, payment methods?
- [ ] Are admin endpoints protected with role checks?
- [ ] Are IDs predictable (sequential) or random (UUID)?

**Grep for:** `userId`, `sellerId`, `ownerId`, `currentUser`, `Extension<User>`, `owner.*check`, `permission.*check`

---

## Flow 1: Buyer Purchases a Product (End-to-End)

**This is THE critical flow. It covers: browse → add to cart → checkout → pay → order created → cart cleared.**

### Files to read (in order):
```
1. lib/screens/home_screen.dart                          # Browse products
2. lib/screens/productdetails_screen.dart                # View product details
3. lib/features/products/product_actions_viewmodel.dart  # Add to cart action
4. lib/core/repositories/orignabase_cart_repository.dart # Cart persistence (deterministic doc IDs)
5. lib/screens/cart_screen.dart                          # Cart UI
6. lib/screens/checkout_screen.dart                      # Checkout UI
7. lib/features/checkout/orignabase_checkout_provider.dart # Checkout state machine (circuit breakers)
8. lib/features/checkout/checkout_provider.dart          # Computed providers (tax, totals, platform fee)
9. lib/core/repositories/orignabase_order_repository.dart # Order creation (createCheckoutSession)
10. lib/screens/ordersuccess_screen.dart                 # Post-payment state
```

---

### Checkpoint 1: Add to Cart — Stock Race Condition

**THE #1 e-commerce production bug. Verified in WooCommerce #44273, Vendure #3508, Magento #3072, and production systems.**

```
BUG PATTERN (WooCommerce #44273, Feb 2024):
  // Two orders happen at EXACT same timestamp
  // Order 1: stock 1 → 0
  // Order 2: stock 0 → -1  (oversold!)
  // Product is set to "no backorders" but goes negative anyway

BUG PATTERN (Production e-commerce, Feb 2026):
  // Naive: read → check → update
  const stock = await db.getStock(productId);  // T1: both read stock=1
  if (stock > 0) {
    await db.updateStock(productId, stock - 1); // T2: both pass check
  }
  // Result: stock = -1

SAFE PATTERN (atomic conditional decrement):
  // PostgreSQL: single query, check + update atomically
  await db.query("
    UPDATE products
    SET stockQuantity = stockQuantity - $1
    WHERE id = $2 AND stockQuantity >= $1
  ", [quantity, productId]).await?;
  // If 0 rows affected → out of stock
```

**DB Isolation Level Guidance (from WJAETS academic research, 2025):**

| Scenario | Recommended Isolation | Why |
|----------|----------------------|-----|
| Normal stock (low traffic) | READ COMMITTED + atomic UPDATE | Good perf, safe with WHERE guard |
| Flash sale / limited stock (1-10 items) | SERIALIZABLE or Redis queue | Must prevent ALL races |
| Stock reservation (hold during checkout) | SERIALIZABLE + TTL expiry | Temp holds must be atomic |
| Stock restoration (cancel/return) | READ COMMITTED + atomic increment | Increment is safer than decrement |

**Key insight from research:** The atomic `UPDATE ... WHERE` pattern is sufficient for 99% of cases. SERIALIZABLE is only needed when multiple related tables must be consistent (e.g., stock + order + payment in one transaction).

**For PostgreSQL specifically:**
- [ ] Does PostgreSQL support transactions? Use `BEGIN` / `COMMIT` for multi-step
- [ ] Are all queries parameterized? (No `format!()` — injection risk)
- [ ] Is `affected_rows` checked after atomic update? (0 = out of stock)
- [ ] For flash-sale items: is there a reservation queue or token system?```

**Audit questions:**
- [ ] Does `addToCart()` in `orignabase_cart_repository.dart` check stock AT ALL?
- [ ] Is stock check atomic or read-then-write?
- [ ] If read-then-write: is there a PostgreSQL transaction wrapping the check + decrement?
- [ ] What happens if stock goes to 0 between the check and the cart write?
- [ ] Does quantity accumulation (`addToCart` with existing item) validate stock for the NEW total?
- [ ] Is stock decrement on `addToCart` or on payment confirmation? (Should be on confirmation)
- [ ] For limited-stock items: is there a reservation/held-stock mechanism?

**Grep for:** `stockQuantity`, `stock`, `quantity`, `WHERE.*stock` in cart repository + backend handlers.

---

### Checkpoint 2: Cart → Checkout — Price Verification

**The client must NEVER send price data the server trusts. Real bug: attacker manipulates cart price → free products.**

```
BUG PATTERN:
  // Client sends: { productId: "abc", priceCents: 1 }
  // Server uses client price → $0.01 for any product
  
SAFE PATTERN:
  // Server fetches price independently
  const product = await db.getProduct(productId);
  const serverPriceCents = product.priceCents;
  // Compare with cart price, fail if different
```

**Audit questions:**
- [ ] Does `orignabase_checkout_provider.dart` call `verifyCartPrices()`?
- [ ] What does `verifyCartPrices()` do? Compare cart prices against server prices?
- [ ] If prices drift (cart cached stale price), what happens? Fail-open or fail-closed?
- [ ] Are prices stored as integer cents throughout? Any `double`/`float` for money?
- [ ] Does `checkoutTotalProvider` use verified prices or cart-displayed prices?
- [ ] Is the cart total recalculated server-side before creating the Stripe session?

**Grep for:** `verifyCartPrices`, `priceCents`, `price.*toDouble`, `subtotalCents` in checkout files.

---

### Checkpoint 3: Checkout Session — Double Checkout (Race Condition)

**THE MOST DANGEROUS BUG. Real bug: WooCommerce ACDC #4099, Feb 2026.**

```
BUG PATTERN (WooCommerce ACDC #4099):
  User clicks "Place Order" → two concurrent POST requests fire
  First POST: creates PayPal order (201 Created)
  Second POST: immediately marks WooCommerce order as Failed
  3DS authentication never completes
  Payment abandoned. No recovery.
  In v3.4.0: webhook recovery doesn't work, order stays Failed.

BUG PATTERN (Medium, Oct 2025):
  Network delay → user clicks "Submit" twice
  Same payload, same order_id, two transactions
  Bank returns "approved" for BOTH
  Two settlements, one customer
  System shows one confirmation but charged twice
```

**Audit questions:**
- [ ] Does `startCheckout()` have UI debouncing? (disable button after first tap, `setState(isLoading: true)`)
- [ ] Is there an idempotency key for the checkout session creation?
- [ ] If `createCheckoutSession()` is called twice with the same order_id, does it return the SAME session or create a NEW one?
- [ ] Is there a circuit breaker on Stripe calls? (visible in `orignabase_checkout_provider.dart`)
- [ ] Does the backend check for existing pending session before creating new one?
- [ ] What happens if the user closes the browser mid-checkout? Session expires? Stock restored?
- [ ] Is the biometric guard (≥$100) in place? Does it prevent accidental double-taps?
- [ ] Does the order have a unique constraint that prevents duplicate creation?

**Grep for:** `idempotency`, `duplicate`, `existing.*session`, `circuit`, `_stripeCallCount`, `isLoading`, `isSubmitting` in checkout files.

### Checkpoint 3b: Duplicate Charges (THE most reported e-commerce bug on GitHub)

**7 closed GitHub issues across WooCommerce Stripe + PayPal about duplicate charges. Pattern: browser return URL AND webhook BOTH process the payment.**

```
BUG PATTERN (WooCommerce Stripe #3638, Dec 2024):
  Customer makes purchase → TWO payment intents created
  Each payment intent has a successful charge
  Customer charged TWICE for same order
  Stripe keeps fees on BOTH charges
  Only one charge ID in order notes, but two in Stripe dashboard

BUG PATTERN (WooCommerce PayPal #4110, Feb 2026):
  Since v3.4.0: both browser return URL AND webhook fire
  Both successfully process payment
  Two separate orders created at exact same timestamp
  Two different PayPal transaction IDs
  Customer charged twice

BUG PATTERN (WooCommerce PayPal #3946, Dec 2025):
  Single PayPal payment → multiple WooCommerce orders
  All marked as "Paid" with same PayPal transaction ID
  Double stock reduction
  Risk of shipping twice

ROOT CAUSE ANALYSIS (from 7 GitHub issues):
  1. Browser redirect confirms order (success_url hit)
  2. Webhook also confirms order (payment_intent.succeeded)
  3. No mutex/lock prevents both paths from running
  4. No idempotency check: "is this order already confirmed?"
  5. Race window: redirect arrives before webhook can lock
```

**Audit questions:**
- [ ] Is there a mutex/lock on order confirmation? (Only ONE path can confirm)
- [ ] Does the success_url handler check if the order is already confirmed before acting?
- [ ] Does the webhook handler check if the order is already confirmed before acting?
- [ ] Is there a unique constraint on `orderId + status` to prevent duplicate confirmations?
- [ ] Is stock decremented in BOTH the redirect path AND the webhook path? (Should be webhook ONLY)
- [ ] Are order confirmation emails sent in BOTH paths? (Should be webhook ONLY)
- [ ] Does the system use `payment_intent` ID as the unique key for dedup?
- [ ] If the redirect arrives first, does it wait/poll for webhook confirmation?
- [ ] If the webhook arrives first, does the redirect just show the already-confirmed order?

**Grep for:** `already.*confirmed`, `duplicate.*order`, `order.*exists`, `payment_intent` dedup logic in order repository + backend.

---

### Checkpoint 4: Stripe Amount — Double ×100 Miscalculation

**Real bug: MedusaJS #13160, Aug 2025. $9.99 → 99,900 cents sent to Stripe (100× overcharge).**

```
BUG PATTERN (MedusaJS #13160):
  // Medusa stores prices in dollars: 19.99
  // Dev stores prices in cents: 1999 (thinking Medusa uses cents)
  // Medusa multiplies by 100 internally: 1999 × 100 = 199,900
  // Stripe receives $1,999.00 instead of $19.99
  
  // In OrignaGTA equivalent:
  // If code does: amount: totalAmountCents * 100
  // And totalAmountCents is already in cents
  // → 100× overcharge

SAFE PATTERN:
  // totalAmountCents is ALWAYS in cents
  // Pass directly to Stripe API — NO conversion
  amount: totalAmountCents  // 999 for $9.99
```

**Audit questions:**
- [ ] Is EVERY monetary field an integer (cents)?
- [ ] Search for ANY `* 100` or `/ 100` near Stripe API calls
- [ ] Does `createCheckoutSession()` pass cents directly to Stripe?
- [ ] Is there any double conversion? (cents → dollars → cents)
- [ ] Search for `toDouble`, `double.parse` near money concepts
- [ ] Are tax calculations done in cents? (13% HST on $10.00 = 130 cents, not 1.3 dollars)
- [ ] Is `platformFeeTotalCents` calculated on `subtotalCents` NOT `totalAmountCents`?
- [ ] Is display formatting done ONLY at the UI layer? (`'$${(cents / 100).toStringAsFixed(2)}'`)

**Grep for:** `* 100`, `/ 100`, `toDouble`, `double.*price`, `double.*amount`, `double.*cost`, `double.*fee` across all Dart files + backend Rust files.

---

### Checkpoint 5: Payment Success — Webhook vs Redirect

**NEVER confirm an order based on a URL redirect. Real bug: user visits success URL without paying → free order.**

```
BUG PATTERN:
  // DANGEROUS — confirm on redirect
  success_url: "https://app.com/order/confirmed?session_id=..."
  // User can visit this URL directly without paying
  // Or: attacker shares the URL → everyone gets "order confirmed"
  
  // SAFE — redirect to pending, wait for webhook
  success_url: "https://app.com/order/pending?session_id=..."
  // Webhook: payment_intent.succeeded → confirm order → clear cart
```

**Audit questions:**
- [ ] Does `ordersuccess_screen.dart` wait for webhook confirmation or confirm immediately on load?
- [ ] Is the success page a "processing" state that polls/waits, or does it immediately show "Order Confirmed"?
- [ ] Where is the webhook handler? (Should be in OrignaBase backend, not Flutter)
- [ ] Does the webhook verify the signature (HMAC with `rawBody`, not parsed JSON)?
- [ ] Is `STRIPE_WEBHOOK_SECRET` loaded from env vars, never hardcoded?
- [ ] Is there idempotency checking on webhook events? (store processed event IDs in `webhook_events`)
- [ ] Does the webhook handle out-of-order delivery? (Stripe does NOT guarantee ordering)
- [ ] Is the 200 response sent BEFORE or AFTER business logic? (Should be before, process async)

**Grep for:** `webhook`, `payment_intent.succeeded`, `checkout.session.completed`, `signature`, `constructEvent`, `rawBody` in order repo + backend.

---

### Checkpoint 6: Post-Payment — Cart Clearing Timing

**Cart must be cleared AFTER order confirmed by webhook, NOT after redirect.**

```
BUG PATTERN:
  // DANGEROUS — clear cart on redirect
  success_url → clearCart()
  // If webhook fails → order never confirmed, cart is gone
  // User can't retry checkout (empty cart)
  // Stock was possibly decremented → ghost inventory
  
  // SAFE — clear cart in webhook handler
  webhook: payment_intent.succeeded → confirmOrder() → clearCart()
  // Only clears after order truly confirmed
```

**Audit questions:**
- [ ] When is `clearCart()` called? On redirect or in the webhook confirmation path?
- [ ] If webhook is delayed, does the user still see their cart items?
- [ ] If user navigates away during "processing", can they still see their cart?
- [ ] What happens if `clearCart()` fails after order confirmation? Is there a retry?

**Grep for:** `clearCart`, `clear_cart`, `removeAll` in checkout + order success flows.

---

### Checkpoint 7: Riverpod Race Conditions in Checkout

**Real bugs: Riverpod #3879, #2506. `ref.read()` gets stale data while `ref.listen()` has fresh. Provider disposed mid-operation crashes.**

```
BUG PATTERN (Riverpod #3879):
  // ref.listen() fires with new state
  // Inside listener, ref.read() returns PREVIOUS state
  // ref.listen(provider, (prev, next) {
  //   final current = ref.read(provider).value;  // ← returns prev, not next!
  // });

BUG PATTERN (Riverpod #2506):
  // Provider disposed while AsyncValue.guard() running
  // state = AsyncData(result) throws "Future already completed"
  // Happens when: no listeners, provider auto-disposes
  // Fix: check if provider is still mounted before setting state

BUG PATTERN (checkout specific):
  // User starts checkout → state = AsyncLoading()
  // User navigates away (back button) → provider disposed
  // Stripe response arrives → state = AsyncData(session) → CRASH
  // Stock was decremented but checkout never completed
```

**Audit questions:**
- [ ] In `orignabase_checkout_provider.dart`: does `startCheckout()` handle disposal mid-operation?
- [ ] Does the checkout ViewModel check `mounted` before setting `state = AsyncData(...)`?
- [ ] In the success screen: is `ref.read()` or `ref.watch()` used to check order status?
- [ ] Are there any `ref.read()` calls inside `ref.listen()` callbacks that should use the `next` value?
- [ ] Does the cart provider properly handle disposal during checkout?
- [ ] What happens if the user taps "Back" during checkout loading state?

**Grep for:** `ref.read(` inside `listen(` callbacks, `mounted`, `dispose`, `autoDispose` in checkout + cart providers.

---

## Flow 2: Stripe Webhook Processing

### Files to read:
```
1. OrignaBase backend: /stripe/webhook endpoint (Rust)
2. lib/core/repositories/orignabase_order_repository.dart
3. lib/features/orders/buyer_orders_viewmodel.dart
4. lib/features/checkout/orignabase_checkout_provider.dart
```

### Checkpoint 1: Signature Verification (CRITICAL)

**Without HMAC verification, anyone can send fake webhook events.**

```
BUG PATTERN:
  // DANGEROUS — no signature check
  async fn handle_webhook(body: Json<StripeEvent>) -> Result<()> {
    match event.type { ... }  // Trusts any request
  }
  
  // Also dangerous — using parsed JSON body
  let event: Event = serde_json::from_slice(&body)?;  // Breaks HMAC
  stripe::Webhook::construct_event(&serde_json::to_vec(&event)?, sig, secret) // Fails
  
  // SAFE — use raw bytes
  async fn handle_webhook(body: Bytes, headers: HeaderMap) -> Result<()> {
    let sig = headers.get("stripe-signature").ok_or(...)?;
    let secret = std::env::var("STRIPE_WEBHOOK_SECRET")?;
    let event = stripe::Webhook::construct_event(&body, sig.to_str()?, secret.as_bytes())?;
    // event is verified
  }
```

**Audit questions:**
- [ ] Does the webhook handler use `rawBody` (bytes) or parsed JSON? (Parsed breaks HMAC)
- [ ] Is `STRIPE_WEBHOOK_SECRET` loaded from env vars, never hardcoded?
- [ ] Is signature verification done BEFORE any business logic?
- [ ] Are invalid signatures rejected with 400 (not 500)?
- [ ] Is the webhook secret different per environment? (dev ≠ staging ≠ prod)

### Checkpoint 2: Idempotency (CRITICAL)

**Stripe delivers webhooks with at-least-once guarantee. Duplicate events WILL happen. Verified by Stripe docs + production incidents.**

```
BUG PATTERN:
  // No dedup
  async fn handle_payment_succeeded(event) {
    db.confirm_order(order_id);     // First call: stock 1 → 0
    db.decrement_stock(order_id);   // First call: ok
    // Stripe retries (timeout) → confirm_order again → stock -1!
  }
  
  // SAFE — atomic idempotency check + business logic
  async fn handle_payment_succeeded(event) {
    // Transaction: check + record + business logic
    db.transaction(|| {
      if db.webhook_event_exists(&event.id)? { return Ok(()); }
      db.record_webhook_event(&event.id, &event.type)?;
      db.confirm_order(order_id)?;
      db.decrement_stock(order_id)?;
      Ok(())
    })
  }
```

**Audit questions:**
- [ ] Is there a `webhook_events` collection tracking processed event IDs?
- [ ] Is the idempotency check ATOMIC with business logic? (PostgreSQL transaction)
- [ ] If the app crashes between idempotency check and business logic, what happens on retry?
- [ ] Does the idempotency check use `event.id` (Stripe's unique ID)?
- [ ] What timestamp field does `webhook_events` use? (Should be `timestamp` or `createdAt`)

### Checkpoint 3: Event Ordering

**Stripe does NOT guarantee webhook ordering. `payment_intent.succeeded` may arrive before `checkout.session.completed`.**

**Audit questions:**
- [ ] Does the code assume events arrive in order?
- [ ] Can `payment_intent.succeeded` process before the order record exists?
- [ ] Is there defensive coding: "if order not found, create it from webhook data"?
- [ ] Can `checkout.session.completed` create the order, and `payment_intent.succeeded` confirm it? (Correct order)
- [ ] Can `payment_intent.succeeded` arrive first and try to confirm a non-existent order?

### Checkpoint 4: Webhook Response Time

**Stripe retries after 10-second timeout. Return 200 immediately. Process asynchronously.**

**Audit questions:**
- [ ] Does the webhook handler do heavy work synchronously? (DB writes, email, notifications)
- [ ] Is the 200 response sent BEFORE or AFTER business logic completes?
- [ ] Is there a queue/background worker for processing?
- [ ] If business logic takes >10s, Stripe will retry → potential duplicate processing

---

## Flow 3: Order Lifecycle & State Machine

### Files to read:
```
1. lib/features/orders/buyer_orders_viewmodel.dart
2. lib/features/orders/seller_orders_viewmodel.dart
3. lib/core/repositories/orignabase_order_repository.dart
4. lib/screens/order_detail_screen.dart
5. lib/screens/seller_orders_screen.dart
6. lib/screens/shipping_approval_screen.dart
7. lib/features/orders/shipping_approval_viewmodel.dart
```

### State Machine (from order-lifecycle skill)
```
pending → confirmed → shipped → delivered
        ↘ cancelled (from pending or confirmed only)

delivered = terminal
cancelled = terminal
```

### Checkpoint 1: State Transition Enforcement

**Real bug pattern: client sends `pending → delivered`, skipping `confirmed` + `shipped`.**

```
SAFE PATTERN (server-side validation):
  const VALID_TRANSITIONS = {
    pending: ['confirmed', 'cancelled'],
    confirmed: ['shipped', 'cancelled'],
    shipped: ['delivered'],
  };
  if (!VALID_TRANSITIONS[order.status]?.includes(newStatus)) {
    return Err("Invalid transition");
  }
```

**Audit questions:**
- [ ] Is there a valid-transition map enforced SERVER-SIDE? (Not just client-side)
- [ ] Can a client skip states? (`pending → delivered` directly?)
- [ ] Can a client reverse states? (`delivered → pending`?)
- [ ] Who can trigger each transition? (buyer vs seller vs admin)
- [ ] Can buyer confirm delivery for someone else's order?
- [ ] Can seller mark as delivered? (Only buyer should confirm delivery per order-lifecycle skill)
- [ ] Are transitions logged as order events? (audit trail)

### Checkpoint 2: Stock Management

**Real bug: stock decremented on checkout (not confirmation). User abandons payment → stock permanently lost.**

```
BUG PATTERN:
  checkout() → decrementStock()
  // User closes browser, payment never completes
  // Stock locked forever, inventory slowly drains
  
SAFE PATTERN:
  // Reserve (soft decrement) on checkout with timeout
  checkout() → reserveStock(expiry: 30min)
  // Confirm (hard decrement) on webhook
  webhook: payment_succeeded → confirmStockDecrement()
  // Restore on timeout
  cleanup_job: expireReservations() → restoreStock()
```

**Audit questions:**
- [ ] When is stock decremented? On checkout or on payment confirmation?
- [ ] When is stock restored? On cancellation? On timeout?
- [ ] Is stock decrement atomic? (`UPDATE SET stock -= $qty WHERE stock >= $qty`)
- [ ] Is stock restoration atomic?
- [ ] What happens if stock restoration fails after cancellation?
- [ ] Is there a timeout mechanism for abandoned checkouts? (30 min typical)
- [ ] Is there a background job that cleans up stale pending orders?

### Checkpoint 3: Voucher Race Condition

**Real bug: Saleor #15849. Concurrent checkout threads with voucher usage limit. Thread 1 increases usage, Thread 2 errors → payment auto-refunded, but Thread 1's order proceeds with refunded payment.**

**Audit questions:**
- [ ] If coupons/vouchers have usage limits, is the increment atomic?
- [ ] Can two concurrent checkouts use the same single-use voucher?
- [ ] Is there a flag like `is_voucher_usage_increased` (Saleor's fix) to prevent double-increment?

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

**Stripe refunds: platform fee is NOT refunded. Stripe processing fees are NOT returned.**

```
Stripe Connect refund behavior (from docs):
  - Direct charges: refund debited from connected account balance
  - Destination charges: refund debited from platform balance, need transfer reversal
  - Separate charges: refund debited from platform balance, need transfer reversal
  - If insufficient balance: refund status = "pending", processed when funds available
```

**Audit questions:**
- [ ] Is the refund amount `subtotalCents` (not `totalAmountCents` which includes platform fee)?
- [ ] Is platform fee explicitly excluded from refund?
- [ ] For multi-seller orders: is each seller's portion refunded independently?
- [ ] Does the refund use an idempotency key? (`<order_id>-refund`)
- [ ] Is the Stripe refund created with the correct `payment_intent` ID?
- [ ] For destination charges: is the transfer reversed to recover funds from connected account?
- [ ] Can a user request a refund amount higher than the original payment?

### Checkpoint 2: Return Window

**Audit questions:**
- [ ] Is the return window enforced? (30 days from `deliveredAt`)
- [ ] Is `deliveredAt` a required field for returns?
- [ ] Can a user request return for a `pending` order?
- [ ] Can a user request return twice for the same order?
- [ ] Is the return reason captured and validated?

### Checkpoint 3: Partial Refunds

**From Stripe docs: "You can issue multiple partial refunds until the original amount is exhausted, within 180 days of the charge."**

**Audit questions:**
- [ ] Does the system track total refunded amount per order?
- [ ] Can the sum of partial refunds exceed the original payment?
- [ ] Are partial refunds supported for multi-item orders? (refund 1 of 3 items)

---

## Flow 5: Auth & Session

### Files to read:
```
1. lib/features/auth/auth_provider.dart
2. lib/core/repositories/orignabase_auth_repository.dart
3. lib/screens/login_screen.dart
4. lib/screens/mfa_challenge_screen.dart
5. lib/services/session_timeout_service.dart
6. lib/services/web_auth_redirect_web.dart
```

### Checkpoint 1: Session Fixation

**Audit questions:**
- [ ] Is a new session token issued after login? (Not reusing pre-login token)
- [ ] Is the JWT validated on every request? (Not just at login)
- [ ] Can a user access protected routes without a valid token?
- [ ] On logout: is the token invalidated server-side? (Not just client-side clear)

### Checkpoint 2: MFA Bypass

**Audit questions:**
- [ ] After password validation, is MFA enforced before granting access?
- [ ] Can the MFA challenge screen be skipped via direct navigation?
- [ ] Is the TOTP code validated server-side? (Not client-side comparison)
- [ ] Is there a brute-force protection on TOTP codes? (Rate limiting, lockout)
- [ ] Can MFA be disabled without re-authentication?

### Checkpoint 3: Rate Limiting & Error Handling

**From `orignabase_auth_repository.dart`: `signInWithEmail()` has retry loop for rate-limit/network errors.**

**Audit questions:**
- [ ] Is there rate limiting on login attempts? (5 per session/IP)
- [ ] Does the retry loop have a max retry count? (Prevents infinite loops)
- [ ] Is exponential backoff implemented?
- [ ] Are error messages generic? (Don't reveal if email exists)
- [ ] Does `_rethrowAsAuthException()` map all SDK exceptions correctly?

---

## Flow 6: Seller Product Management

### Files to read:
```
1. lib/screens/addproduct_screen.dart + all addproduct_*.dart parts
2. lib/features/products/add_product_viewmodel.dart
3. lib/screens/editproduct_screen.dart + all editproduct_*.dart parts
4. lib/features/products/edit_product_viewmodel.dart
5. lib/screens/seller_products_screen.dart
6. lib/screens/seller/bulk_upload_screen.dart
7. lib/features/products/bulk_upload_viewmodel.dart
```

### Checkpoint 1: Ownership & Authorization

**OWASP A01: Broken Access Control. Can user A edit user B's product?**

**Audit questions:**
- [ ] Can user A edit user B's product? (Server must check `sellerId == currentUser.uid`)
- [ ] Can a non-seller create products?
- [ ] Can a seller with incomplete Stripe onboarding publish products?
- [ ] Is ownership checked server-side, not just UI-hidden?
- [ ] For bulk upload: are all items validated for ownership?

### Checkpoint 2: Image Upload Security

**OWASP A10: SSRF. Can attacker upload a URL that points to internal services?**

**Audit questions:**
- [ ] Is image upload using presigned URL flow? (2-step: presign → PUT)
- [ ] Are file type, size, and count limits enforced?
- [ ] Are uploaded URLs validated to prevent SSRF? (No `file://`, `http://localhost`, `http://169.254.*`)
- [ ] Is there image processing/optimization on the server?
- [ ] Can a user upload a malicious file disguised as an image?

### Checkpoint 3: Price & Inventory Manipulation

**Audit questions:**
- [ ] Is price stored as integer cents? (No float conversion)
- [ ] Can a product be created with negative price?
- [ ] Can a product be created with price = 0? (Is that intentional?)
- [ ] Can stock quantity be set to negative?
- [ ] On product edit: is the price change audited/logged?

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
- [ ] If one sub-order fails, what happens to the others?

### Checkpoint 2: Platform Fee (Stripe Connect)

**Real bug: Stripe Connect #2212. Platform in Estonia, connected accounts in Mexico. Application fee not collected, platform negative balance.**

```
Stripe Connect charge types:
  - Direct charges: refund from connected account balance
  - Destination charges: refund from platform balance, need transfer reversal
  - Separate charges: refund from platform balance, need transfer reversal
  
  Platform fee = application_fee_amount on Checkout Session
  Must be ≤ payment amount
```

**Audit questions:**
- [ ] Is platform fee calculated on `subtotalCents` NOT `totalAmountCents`?
- [ ] Platform fee = percentage of subtotal, not including shipping/tax?
- [ ] Is platform fee collected via `application_fee_amount` in Stripe Connect?
- [ ] Platform fee is non-refundable on buyer refunds — is this enforced?
- [ ] For destination charges: is `transfer_data.destination` set correctly?
- [ ] Does the platform's country support application fees for connected account countries?

---

## Flow 8: Search & Discovery

### Files to read:
```
1. lib/screens/home_screen.dart (search)
2. lib/features/home/home_viewmodel.dart
3. lib/screens/product_card_screen.dart
4. lib/screens/parts/product_card_*.dart
```

### Checkpoint 1: Meilisearch Injection

**OWASP A03: Injection. Can attacker inject Meilisearch filter syntax?**

**Audit questions:**
- [ ] Are search queries sanitized before hitting Meilisearch?
- [ ] Can Meilisearch filter syntax be injected? (e.g., `status = published AND sellerId != me`)
- [ ] Are unpublished products excluded from search results SERVER-SIDE?
- [ ] Is the search index ACL configured to prevent cross-user data leakage?

### Checkpoint 2: Pagination & Performance

**Audit questions:**
- [ ] Is pagination cursor-based or offset-based? (Cursor preferred for real-time data)
- [ ] Does infinite scroll have duplicate detection?
- [ ] Is there a max limit on page size? (Prevent fetching 10,000 products)
- [ ] Are product images lazy-loaded?
- [ ] Is there a search debounce? (Prevent DoS from rapid keystrokes)

---

## Flow 9: Notifications & Push

### Files to read:
```
1. lib/services/orignabase_notification_service.dart
2. lib/services/push_transport.dart
3. lib/screens/notifications_screen.dart
4. lib/features/notifications/ (all files)
```

### Checkpoint 1: Deep Linking Security

**Audit questions:**
- [ ] Can a notification deep-link to an unauthorized screen?
- [ ] Is the deep link target validated against the user's permissions?
- [ ] Can a malicious notification redirect to an external URL?
- [ ] Are notification data payloads validated? (Not blindly passed to router)

### Checkpoint 2: Token Management

**Audit questions:**
- [ ] Is the FCM token refreshed on app update?
- [ ] Is the old token invalidated on logout?
- [ ] Can stale tokens cause notifications to go to wrong users? (Device transfer)
- [ ] Is the notification token stored per-device or per-user? (Should be per-device)

---

## Flow 10: Seller Onboarding & Stripe Connect

### Files to read:
```
1. lib/screens/seller_registration_screen.dart
2. lib/features/seller/seller_registration_view_model.dart
3. lib/features/seller/seller_account_status_viewmodel.dart
4. lib/screens/seller_setup_screen.dart
5. lib/screens/seller_integration_screen.dart
```

### Checkpoint 1: Onboarding Bypass

**Audit questions:**
- [ ] Can a seller list products before Stripe onboarding is complete?
- [ ] Is the onboarding status verified via Stripe API (not just a local boolean)?
- [ ] Can a seller register with another user's Stripe account?
- [ ] If Stripe onboarding link expires, is there a re-onboarding flow?

### Checkpoint 2: Payout Timing

**Audit questions:**
- [ ] Is payout triggered ONLY after delivery confirmation?
- [ ] Can a seller mark their own order as delivered to trigger payout? (Only buyer)
- [ ] Is there a delay/pending period for new sellers? (Stripe recommendation: 2 weeks)
- [ ] Does the earnings calculation account for refunds? (Subtract refunded amounts)

---

## Flow 11: User Profile & Addresses

### Files to read:
```
1. lib/screens/profile_screen.dart
2. lib/screens/parts/profile_header.dart
3. lib/screens/addressmanagement_screen.dart
4. lib/screens/editaddress_screen.dart
5. lib/features/profile/address_management_viewmodel.dart
6. lib/screens/security_settings_screen.dart
7. lib/screens/parts/security_mfa_section.dart
```

### Checkpoint 1: Input Sanitization (OWASP A03)

**Audit questions:**
- [ ] Is the user's display name sanitized? (XSS: `<script>alert(1)</script>` in profile name)
- [ ] Are address fields validated? (Max lengths, required fields, no injection)
- [ ] Is there a max address limit per user? (Resource exhaustion: add 1000 addresses)
- [ ] Are profile fields escaped when rendered? (Not just on input)
- [ ] Is the profile image URL validated? (No `javascript:` or `data:` URLs)

### Checkpoint 2: Security Settings

**Audit questions:**
- [ ] Can MFA be disabled without re-authentication?
- [ ] Is MFA setup verified before marking as enabled?
- [ ] Can a user lock themselves out by enabling MFA without backup codes?
- [ ] Is login history paginated? (Don't load 10,000 entries at once)
- [ ] Can user A view user B's login history? (Broken access control)

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
- [ ] Is the subscription renewal date enforced? (Don't let expired sellers operate)

---

## Reporting Findings

For each bug found:

```
═══════════════════════════════════════════════════════════════
SEVERITY: CRITICAL | HIGH | MEDIUM | LOW
FLOW: [flow name]
OWASP: [A01-A10 if applicable]
───────────────────────────────────────────────────────────────
LOCATION: file.dart:line → file.dart:line (cross-stack trace)

DESCRIPTION:
  [What's wrong — be specific about the code path]

PROOF:
  [How to reproduce / what input triggers the bug]

IMPACT:
  [What happens to users / data / money]

REAL-WORLD REFERENCE:
  [GitHub issue URL or production incident reference]

FIX:
  [Exact code-level change needed]

VERIFICATION:
  [How to confirm the fix works — specific test or command]
═══════════════════════════════════════════════════════════════
```

### Severity (grounded in business impact)

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | Financial loss, data breach, auth bypass. Users lose money or data. | Double charge, stock manipulation, webhook forgery, price manipulation |
| **HIGH** | Wrong behavior affecting real users. Race conditions. Missing validation. | Stock oversold, wrong order status, voucher double-use, amount miscalculation |
| **MEDIUM** | UX bugs, missing error states, degraded performance. | Empty cart error, missing loading state, Riverpod disposal crash, slow pagination |
| **LOW** | Cosmetic, missing edge case, minor style violation. | Wrong badge color, missing tooltip, off-by-one in display |

---

## Summary Report Format

After auditing all flows:

```
FLOW AUDIT SUMMARY
═══════════════════════════════════════════════════════════════
Date: [ISO 8601]
Flows audited: 12
Total findings: X (CRITICAL: X, HIGH: X, MEDIUM: X, LOW: X)

OWASP COVERAGE:
  A01 Broken Access Control: X findings
  A03 Injection: X findings
  A04 Insecure Design: X findings
  A07 Auth Failures: X findings
  A10 SSRF: X findings

TOP 5 PRIORITIES (fix these first):
1. [CRITICAL] flow → description → GitHub ref
2. [CRITICAL] flow → description → GitHub ref
3. [HIGH] flow → description → GitHub ref
4. [HIGH] flow → description → GitHub ref
5. [HIGH] flow → description → GitHub ref

CLEAN FLOWS (no findings):
- Flow X: [name]

MOST DANGEROUS FLOW: [name] — [why]
═══════════════════════════════════════════════════════════════
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
| Cart repository | `lib/core/repositories/orignabase_cart_repository.dart` |
| Order repository | `lib/core/repositories/orignabase_order_repository.dart` |
| Auth repository | `lib/core/repositories/orignabase_auth_repository.dart` |
| Quality gate | `scripts/run_quality_gate.sh` |

---

## Running The Audit

```
/audit-workflow checkout    # Audit checkout + payment flow
/audit-workflow orders      # Audit order lifecycle
/audit-workflow all         # Audit all 12 flows
```

For `all`: run flows sequentially. Between flows, clear context to stay fresh. Produce summary at end.
