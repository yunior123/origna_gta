---
name: concurrency-audit
description: "Concurrency & race condition audit for OrignaGTA. Detects TOCTOU, read-modify-write, non-atomic operations, isolation level issues, and distributed system failures. Covers SurrealDB atomic patterns, Riverpod disposal race conditions, stock overselling, and double-charge prevention. Use when asked to 'audit concurrency', 'find race conditions', 'check atomicity', 'isolation level review', or similar."
---

# Concurrency Audit — OrignaGTA

Systematic detection of race conditions, non-atomic operations, and concurrency bugs. Every pattern is grounded in production incidents and academic research.

## Why This Exists

Race conditions are invisible in dev (single user) and catastrophic in production (concurrent users). This skill catches them BEFORE they ship.

| Bug | Type | Source | Impact |
|-----|------|--------|--------|
| Stock goes negative (two users buy last item) | TOCTOU | WooCommerce #44273, Vendure #3508, Magento #3072 | Overselling |
| Double checkout (one click → two payments) | Race condition | WooCommerce ACDC #4099 | Double charges |
| Voucher used twice (concurrent threads) | Atomic violation | Saleor #15849 | Revenue loss |
| ref.read() returns stale data | Riverpod disposal | Riverpod #3879 | Wrong UI |
| state= on disposed provider crashes | Lifecycle race | Riverpod #2506 | App crash |
| Webhook processes event twice | At-least-once delivery | Stripe docs, WC #3300 | Double actions |

---

## Classification of Concurrency Bugs

### Type 1: TOCTOU (Time-of-Check to Time-of-Use)

**The most common race condition in e-commerce.** Check passes, then state changes before use.

```
TOCTOU PATTERN:
  T1: Read state S
  T2: [Another thread modifies state S → S']
  T3: Use state S (stale!) ← BUG
  
EXAMPLE:
  T1: Read stock = 1
  T2: Other user buys last item → stock = 0
  T3: Process order using stale stock = 1 → oversold!
```

**Where to look in OrignaGTA:**
- `orignabase_cart_repository.dart` — stock check before add
- `orignabase_checkout_provider.dart` — price verification
- `orignabase_order_repository.dart` — order creation
- Backend handlers — any read-then-write pattern

**Grep for:** `getStock`, `read.*then.*write`, `check.*then.*update`, `if.*stock.*>`, `findOne`, `query.*SELECT.*WHERE` followed by `UPDATE`

### Type 2: Lost Update

**Two transactions read the same value, both write back. One write is lost.**

```
LOST UPDATE PATTERN:
  T1: Read balance = 100
  T2: Read balance = 100
  T1: Write balance = 100 - 50 = 50
  T2: Write balance = 100 - 30 = 70  ← T1's update lost!
  
  Expected: 20
  Actual: 70
```

**Where to look:**
- Cart quantity updates (two devices, same user)
- Order status transitions (buyer + seller acting simultaneously)
- Profile updates (concurrent edits)

**Grep for:** `UPDATE.*SET.*=.*-` without `WHERE` guard, `save()`, `update()` after `findOne()`

### Type 3: Phantom Read

**Transaction reads a set of rows, another transaction inserts/deletes rows, first transaction reads again and gets different set.**

```
PHANTOM READ PATTERN:
  T1: SELECT COUNT(*) FROM orders WHERE status = 'pending' → 5
  T2: INSERT INTO orders (status='pending') ...
  T1: SELECT COUNT(*) FROM orders WHERE status = 'pending' → 6  ← Different!
```

**Where to look:**
- Pagination with offset (items shift between pages)
- Dashboard statistics (counts change mid-fetch)
- Order list (new orders appear during scroll)

**Grep for:** `COUNT`, `OFFSET`, `LIMIT` without `ORDER BY` + `keyset pagination`

### Type 4: Lifecycle Race (Riverpod-Specific)

**Provider disposed while async operation in flight. State set on disposed provider crashes app.**

```
RIVERPOD DISPOSAL RACE:
  T1: User taps "Checkout" → state = AsyncLoading()
  T2: User taps "Back" → provider disposed
  T3: Stripe response arrives → state = AsyncData(session) → CRASH!
  (Riverpod #2506: "Bad state: Future already completed")
```

**Where to look:**
- All `AsyncNotifier` implementations
- Any `state = AsyncValue.guard(() async { ... })` pattern
- Checkout, cart, order providers

**Grep for:** `AsyncValue.guard`, `state =`, `autoDispose`, `ref.read(` inside callbacks

---

## Audit Procedure

### Step 1: Classify Operations

For every operation in the flow, classify as:

| Operation Type | Safe? | Action |
|---------------|-------|--------|
| **Read** (no write) | ✅ Safe | No concern |
| **Write** (single field, atomic) | ✅ Safe | No concern |
| **Read → Check → Write** | ⚠️ TOCTOU risk | Verify atomic |
| **Read → Compute → Write** | ⚠️ Lost update risk | Verify atomic |
| **Read → Read → Write** | ⚠️ Phantom read risk | Verify isolation |
| **Multiple reads across entities** | ⚠️ Consistency risk | Verify transaction |

### Step 2: Check Atomicity

For every TOCTOU-risky operation, verify:

```
UNSAFE (read-modify-write in app code):
  let stock = db.getStock(id);       // Read
  if stock > 0 {                      // Check
    db.setStock(id, stock - 1);       // Write ← Race window here
  }

SAFE (atomic conditional update):
  db.query("
    UPDATE products 
    SET stock = stock - $qty 
    WHERE id = $id AND stock >= $qty
  ");                                // Single atomic operation
  // affected_rows == 0 means out of stock
```

**Check for SurrealDB:**
- [ ] Uses `query_bind()` with `$params` (not `format!()`)
- [ ] Conditional update: `WHERE field >= $value`
- [ ] Check `affected_rows` to detect failure
- [ ] Multi-step operations wrapped in transactions
- [ ] No `SELECT` then `UPDATE` without transaction lock

### Step 3: Check Isolation Level

**From academic research (WJAETS, 2025): Different operations need different isolation levels.**

| Operation | Recommended Isolation | Why |
|-----------|----------------------|-----|
| Normal inventory (low traffic) | READ COMMITTED + atomic update | Good performance, safe with atomic guard |
| Flash sale / limited stock | SERIALIZABLE or queue-based | Prevents all race conditions |
| Wallet / balance | SERIALIZABLE + append-only ledger | Money must never be wrong |
| Order listing | READ COMMITTED | Good enough, slight staleness OK |
| Dashboard stats | READ COMMITTED | Approximate counts acceptable |
| Payment processing | SERIALIZABLE | Financial correctness required |

**Check for SurrealDB:**
- [ ] Is SurrealDB using transactions for multi-step operations?
- [ ] Is the transaction isolation level appropriate for the operation?
- [ ] For flash-sale items: is there a queue or reservation system?

### Step 4: Check Riverpod Safety

**From Riverpod GitHub issues #3879, #2506, #3889:**

```
BUG PATTERN 1: ref.read() inside ref.listen() callback
  ref.listen(provider, (prev, next) {
    final current = ref.read(provider).value;  // ← Returns PREV, not next!
  });

BUG PATTERN 2: Provider disposed mid-operation
  Future<void> checkout() async {
    state = AsyncLoading();
    await repository.createSession();  // Takes 5 seconds
    // User navigated away → provider disposed
    state = AsyncData(session);        // ← CRASH! (Riverpod #2506)
  }

BUG PATTERN 3: ref.watch() ≠ ref.read() after side effect
  ref.read(provider.notifier).doSomething();  // Changes state
  final val = ref.watch(provider);            // ← May return stale!
```

**Check for:**
- [ ] `ref.read()` inside `ref.listen()` callbacks (should use `next` parameter)
- [ ] `state =` after async gap without checking disposal
- [ ] `ref.read()` then `ref.watch()` of same provider
- [ ] `autoDispose` providers with long-running operations
- [ ] `AsyncValue.guard()` without disposal handling

**Grep for:** `ref.read(` inside `listen(`, `autoDispose`, `AsyncValue.guard`, `state =` after `await`

### Step 5: Check Webhook Idempotency

**Stripe delivers at-least-once. Events WILL be duplicated.**

```
BUG PATTERN:
  webhook_handler(event):
    if event.type == 'payment_intent.succeeded':
      confirm_order(event.order_id)      // First call
      decrement_stock(event.order_id)    // First call
      // Retry → confirm_order again → stock decremented TWICE!

SAFE PATTERN (3-layer):
  Layer 1: Check event.id in webhook_events table
  Layer 2: UNIQUE constraint on (orderId, eventType)
  Layer 3: Atomic check + process in single transaction
```

**Check for:**
- [ ] `webhook_events` table exists with processed event IDs
- [ ] Idempotency check is ATOMIC with business logic (transaction)
- [ ] `event.id` used as the dedup key (not event.type)
- [ ] Crash recovery: TTL on processing locks
- [ ] Concurrent delivery: only one handler processes each event

---

## Files to Read

### Stock & Inventory
```
lib/core/repositories/orignabase_cart_repository.dart
lib/core/repositories/orignabase_order_repository.dart
Backend: stock decrement handler (Rust)
```

### Payments
```
lib/features/checkout/orignabase_checkout_provider.dart
lib/features/checkout/checkout_provider.dart
lib/core/repositories/orignabase_order_repository.dart (createCheckoutSession)
Backend: /stripe/webhook handler (Rust)
```

### Riverpod Providers
```
lib/features/cart/cart_provider.dart
lib/features/checkout/checkout_provider.dart
lib/features/orders/buyer_orders_viewmodel.dart
lib/features/auth/auth_provider.dart
```

### Seller Operations
```
lib/features/seller/seller_products_viewmodel.dart
lib/features/orders/seller_orders_viewmodel.dart
lib/features/orders/shipping_approval_viewmodel.dart
```

---

## Report Format

```
═══════════════════════════════════════════════
CONCURRENCY AUDIT REPORT
═══════════════════════════════════════════════
Date: [ISO 8601]
Operations analyzed: [count]
Race conditions found: [count]

TOCTOU VULNERABILITIES:
  [count] operations with read-modify-write risk

LOST UPDATE VULNERABILITIES:
  [count] operations with non-atomic updates

PHANTOM READ VULNERABILITIES:
  [count] operations with set-based reads

RIVERPOD RACES:
  [count] disposal/safety issues

WEBHOOK IDEMPOTENCY:
  [count] missing dedup checks

TOP FINDINGS:
1. [CRITICAL] [file:line] TOCTOU in [operation]
2. [HIGH] [file:line] Riverpod disposal race in [provider]
3. [HIGH] [file:line] Missing webhook idempotency on [event]

RECOMMENDED ISOLATION LEVELS:
  Stock operations: [READ COMMITTED + atomic / SERIALIZABLE]
  Payments: [SERIALIZABLE]
  Listings: [READ COMMITTED]
═══════════════════════════════════════════════
```

---

## Key Files Reference

| Purpose | Path |
|---------|------|
| Cart repository | `lib/core/repositories/orignabase_cart_repository.dart` |
| Order repository | `lib/core/repositories/orignabase_order_repository.dart` |
| Checkout provider | `lib/features/checkout/orignabase_checkout_provider.dart` |
| Cart provider | `lib/features/cart/cart_provider.dart` |
| Schema constants | `lib/core/schema/schema_constants.dart` |
