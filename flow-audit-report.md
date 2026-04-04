# FLOW AUDIT REPORT — OrignaGTA E-Commerce Flows

Date: 2026-04-04T01:18:00Z
Auditor: Kilo (automated flow audit per .claude/skills/flow-audit/SKILL.md)
Scope: 12 e-commerce flows, Flutter + Rust full-stack trace

---

## FLOW 1: Buyer Purchases a Product (End-to-End)

### Finding 1.1: Stock Decrement at Checkout Time (Not Payment Confirmation)

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Buyer Purchases a Product
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:817-856 → webhooks.rs:734

DESCRIPTION:
  Stock is decremented atomically during checkout session creation
  (checkout.rs:817-856), BEFORE payment is confirmed. If the user
  abandons the Stripe session, stock is only restored when the
  checkout.session.expired webhook arrives (which may be delayed
  by up to 24 hours or never fire if Stripe doesn't send it for
  unpaid sessions).

  The comment at webhooks.rs:541 confirms: "Currently unused in
  production — stock is decremented at checkout time only."

  This means:
  - Abandoned checkouts lock stock for hours
  - Malicious users can DOS inventory by creating sessions and
    abandoning them repeatedly
  - No TTL-based stock restoration job exists

PROOF:
  1. Create checkout session → stock decremented (checkout.rs:817)
  2. Close browser without paying
  3. Stock remains decremented until checkout.session.expired webhook
  4. Stripe may not send expired event for unpaid sessions

IMPACT:
  Inventory gradually drains through abandoned checkouts. On a busy
  site, this causes false "out of stock" for legitimate buyers.

REAL-WORLD REFERENCE:
  WooCommerce #44273 (stock goes negative), Vendure #3508

FIX:
  Move stock decrement to webhook confirmation path
  (handle_checkout_session_completed). Add a background cron job
  that restores stock for pending_payment orders older than 30 min.

VERIFICATION:
  Create checkout → abandon → verify stock unchanged after 30 min
  (cron job restores). Complete payment → verify stock decremented
  in webhook handler.
═══════════════════════════════════════════════════════════════

### Finding 1.2: No UI-Level Double-Tap Debounce on Checkout Button

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Buyer Purchases a Product
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout_screen.dart → checkout_provider.dart

DESCRIPTION:
  The checkout screen passes items/subtotal to _CheckoutButton but
  does not disable the button during the in-flight checkout request.
  While OrignaBaseCheckoutNotifier has state.isProcessing guard
  (line 491), the screen does not watch this state to disable the
  button. A rapid double-tap can fire two concurrent requests
  before isProcessing flips to true.

  The server has a 5-minute dedup check (checkout.rs:599-626), but
  it uses a time-window query, not an atomic constraint. Two
  requests within the same millisecond can both pass the dedup
  check before either order is created.

PROOF:
  1. Tap "Place Order" twice rapidly
  2. Both requests pass dedup check (no order exists yet)
  3. Both create Stripe sessions and orders

IMPACT:
  Duplicate orders, double stock decrement, customer confusion

REAL-WORLD REFERENCE:
  WooCommerce ACDC #4099 (concurrent double-POST)

FIX:
  In checkout_screen.dart, watch checkoutStateProvider.isProcessing
  and disable the checkout button when true. Add a client-side
  debounce (e.g., 2-second cooldown).

VERIFICATION:
  Rapid-tap checkout button → only one session created.
═══════════════════════════════════════════════════════════════

### Finding 1.3: Platform Fee Uses Integer Division (Truncation)

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: Buyer Purchases a Product
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:633

DESCRIPTION:
  Platform fee is calculated as: `actual_subtotal_cents * 5 / 100`
  This is integer division, which truncates. For a $1.50 item
  (150 cents), fee = 150 * 5 / 100 = 7 cents (should be 7.5).
  For $0.50 item (50 cents), fee = 50 * 5 / 100 = 2 cents
  (should be 2.5). The platform consistently undercharges by
  0.5 cents per item.

  While the impact per transaction is negligible, it means the
  platform fee is not exactly 5% — it's floor(5%).

PROOF:
  Subtotal = 150 cents → fee = 7 (expected 7.5)
  Subtotal = 99 cents → fee = 4 (expected 4.95)

IMPACT:
  Minor revenue loss on low-value orders. No customer impact.

FIX:
  Use rounding: `(actual_subtotal_cents * 5 + 50) / 100`
  for banker's rounding.

VERIFICATION:
  Unit test: 150 cents → 8 fee, 99 cents → 5 fee.
═══════════════════════════════════════════════════════════════

### Finding 1.4: Order Success Screen Does Not Wait for Webhook Confirmation

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Buyer Purchases a Product
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: ordersuccess_screen.dart:207-237

DESCRIPTION:
  The OrderSuccessScreen receives orderId and immediately shows
  "Order Placed" with confetti animation. It does NOT poll or
  wait for webhook confirmation. The _logPurchaseIfPaymentConfirmed
  method checks payment status but only for analytics — it does
  not gate the success display.

  If the user visits the success URL directly (without paying),
  they still see the success screen. The screen should show
  "Processing" state and poll until payment_status == captured.

  Note: The redirect URL from Stripe includes session_id and
  order_id, but the screen doesn't verify payment actually
  completed.

PROOF:
  1. Navigate to /order-success with any orderId
  2. Screen shows "Order Placed" regardless of payment status
  3. No verification that payment was actually captured

IMPACT:
  Users see false confirmation for failed/abandoned payments.
  Could be exploited to share success URLs socially.

FIX:
  Add a polling mechanism that checks order payment_status via
  watchPaidOrderBySession or fetchOrderById. Show "Processing"
  until payment is confirmed, "Failed" if payment failed.

VERIFICATION:
  Navigate to success screen with unpaid order → shows
  "Processing" not "Order Placed".
═══════════════════════════════════════════════════════════════

### Finding 1.5: Cart Not Cleared on Server-Side After Checkout Session Creation

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Buyer Purchases a Product
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:756-779 → webhooks.rs:1143-1157

DESCRIPTION:
  The cart is cleared in the webhook handler
  (webhooks.rs:1143: `DELETE FROM cart WHERE userId = $buyer_id`),
  which is correct. However, if the webhook is delayed, the user
  can still see their cart items and potentially start a second
  checkout with the same items.

  The client-side cart is NOT cleared after successful checkout
  session creation. The user can navigate back to cart and
  attempt another checkout.

  The 5-minute dedup check (checkout.rs:599) would catch this,
  but only in non-test mode and only within a 5-minute window.

PROOF:
  1. Complete checkout → redirect to Stripe
  2. Navigate back to app (cancel URL or back button)
  3. Cart still has items
  4. Can attempt second checkout within 5-min window

IMPACT:
  User confusion, potential duplicate order attempts

FIX:
  Clear cart client-side immediately after successful checkout
  session creation (in startCheckout, after receiving success).
  Server-side cart clearing in webhook remains as safety net.

VERIFICATION:
  Complete checkout → cancel → cart is empty.
═══════════════════════════════════════════════════════════════

### Finding 1.6: Stock Race Condition Uses format!() for SQL (Not Parameterized)

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Buyer Purchases a Product
OWASP: A03 Injection
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:817-828

DESCRIPTION:
  The stock decrement query uses format!() to interpolate values
  directly into the SQL string:

  ```rust
  tx.add_raw(&format!(
      "UPDATE {table} SET data = jsonb_set(...) WHERE id = '{pid}' AND (data->>'stockQuantity')::bigint >= {qty}"
  ));
  ```

  While `pid` is validated by `validate_document_id()` and `qty`
  is a u64 from validated items, this is still SQL string
  interpolation. If validate_document_id ever has a gap, this
  becomes SQL injection.

  The `now_escaped` variable uses naive escaping
  (`now.replace('\'', "''")`) which is fragile — if the timestamp
  format changes, this could break.

  The rest of the codebase uses parameterized queries
  (query_bind_value with $params). This one query breaks the
  pattern.

PROOF:
  Code inspection: checkout.rs:817-828 uses format!() for SQL.
  All other queries in the same file use query_bind_value.

IMPACT:
  If validate_document_id has any bypass, SQL injection is
  possible. The naive timestamp escaping is fragile.

REAL-WORLD REFERENCE:
  OWASP A03: Injection — parameterized queries are the standard

FIX:
  Convert to parameterized query using query_bind_value or
  add_raw with parameter binding. Use proper timestamp handling.

VERIFICATION:
  Code review: no format!() in SQL strings for this query.
═══════════════════════════════════════════════════════════════

---

## FLOW 2: Stripe Webhook Processing

### Finding 2.1: Webhook Dedup Has TOCTOU Race in try_store_webhook_event_atomic

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Stripe Webhook Processing
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: webhooks.rs:334-385

DESCRIPTION:
  The function try_store_webhook_event_atomic() does a
  get_document() check followed by create_document():

  ```rust
  if state.db.get_document(collections::WEBHOOK_EVENTS, &event.id).await.is_ok() {
      return Ok(false); // Duplicate
  }
  let result = state.db.create_document(collections::WEBHOOK_EVENTS, event_data).await;
  ```

  This is a check-then-create pattern with a TOCTOU race. Two
  concurrent webhook deliveries of the same event can both pass
  the get_document check before either creates the document.

  The function catches "already exists" errors as a fallback
  (line 374-379), but the gap between check and create means
  both handlers could start processing before one fails.

  The comment says "Strict INSERT (no ON CONFLICT)" but then
  does a SELECT first — defeating the purpose.

PROOF:
  1. Stripe delivers same webhook twice (at-least-once guarantee)
  2. Both handlers pass get_document check simultaneously
  3. Both start processing before one hits create_document error
  4. Both may execute side effects (order confirmation, email)

IMPACT:
  Duplicate order confirmations, double emails, potential
  double stock operations

REAL-WORLD REFERENCE:
  WooCommerce Stripe #3300 (duplicate webhook processing)

FIX:
  Use atomic CREATE without the preceding get_document check.
  Let the CREATE fail on duplicate and catch the error.
  Or use INSERT ... ON CONFLICT DO NOTHING in PostgreSQL.

VERIFICATION:
  Send duplicate webhook → only one handler processes.
═══════════════════════════════════════════════════════════════

### Finding 2.2: Webhook Handler Does Synchronous DB Work (Timeout Risk)

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Stripe Webhook Processing
OWASP: A10 Mishandling Exceptional Conditions
───────────────────────────────────────────────────────────────
LOCATION: webhooks.rs:59-210

DESCRIPTION:
  The webhook handler does all DB work synchronously before
  returning 200. handle_payment_intent_succeeded does:
  - find_order_by_metadata_id (DB query)
  - update_order_status (DB update)
  - Store payment intent ID (DB update)
  - mark_coupon_redeemed (DB update)
  - send_payment_authorized_emails (HTTP call to Mailjet)

  If Mailjet is slow or the DB is under load, the handler can
  exceed Stripe's 10-second timeout, causing Stripe to retry.
  The retry then hits the idempotency check, but the first
  attempt may have partially completed.

  The 200 response is only sent after ALL work completes.

PROOF:
  webhooks.rs:680-779: handle_payment_intent_succeeded does
  multiple DB operations + email sending before returning.

IMPACT:
  Stripe retries on timeout → duplicate webhook processing
  despite idempotency (see Finding 2.1)

FIX:
  Return 200 immediately after storing the event ID. Process
  business logic asynchronously (background task/queue).

VERIFICATION:
  Simulate slow Mailjet → webhook returns 200 within 2s.
═══════════════════════════════════════════════════════════════

### Finding 2.3: handle_charge_refunded Finds Order by payment_intent_id, Not Charge ID

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Stripe Webhook Processing
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: webhooks.rs:941-1041

DESCRIPTION:
  handle_charge_refunded extracts payment_intent_id from the
  charge object and uses find_order_by_payment_intent to locate
  the order. However, the order is created with checkout_session_id
  and order_id in metadata, not payment_intent_id (which is only
  set AFTER payment_intent.succeeded webhook fires).

  If charge.refunded arrives before payment_intent.succeeded
  (possible with async payment methods), the order won't have
  payment_intent_id set yet, and the lookup will fail.

  Additionally, the refund amount check compares refunded_amount
  against total_amount_cents, but Stripe's charge.refunded event
  uses amount_refunded which may be cumulative across multiple
  partial refunds.

PROOF:
  1. Issue refund before payment_intent.succeeded webhook
  2. Order has no payment_intent_id → lookup fails
  3. Returns NotFound error → Stripe retries indefinitely

IMPACT:
  Refund processing fails for orders where payment_intent_id
  hasn't been set yet. Stock may not be restored.

FIX:
  Add fallback lookup: try payment_intent_id first, then
  checkout_session_id, then order_id from metadata.

VERIFICATION:
  Refund order before payment_intent.succeeded → refund
  processed successfully via fallback lookup.
═══════════════════════════════════════════════════════════════

---

## FLOW 3: Order Lifecycle & State Machine

### Finding 3.1: update_item_status Lacks CAS Guard (Concurrency Risk)

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Order Lifecycle & State Machine
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: status.rs:828-1023

DESCRIPTION:
  update_item_status (status.rs:982-987) uses
  `state.db.update_document()` without a CAS (compare-and-swap)
  guard. In contrast, confirm_item_receipt (status.rs:417-427)
  uses `update_document_cas()` with an orderStatus precondition.

  This means two concurrent item status updates can overwrite
  each other. For example:
  - Seller A updates item 1 to "shipped"
  - Seller B updates item 2 to "shipped" (same order)
  - Second update overwrites the first update's items array

  The read-modify-write pattern is:
  1. Read order (line 865)
  2. Modify items array in memory (line 933-950)
  3. Write entire order back (line 982)

  If another write happens between steps 1 and 3, it's lost.

PROOF:
  status.rs:982: `state.db.update_document(collections::ORDERS, &req.order_id, update_data)`
  vs status.rs:417: `state.db.update_document_cas(...)` for confirm_item_receipt

IMPACT:
  Concurrent item updates can lose data. Tracking numbers,
  shipped_at timestamps, or status changes can be silently
  overwritten.

REAL-WORLD REFERENCE:
  Classic read-modify-write race condition

FIX:
  Use update_document_cas() with a version field or
  updatedAt precondition. Or use a PostgreSQL JSONB patch
  operation that only modifies the specific item.

VERIFICATION:
  Two concurrent item status updates → both persist.
═══════════════════════════════════════════════════════════════

### Finding 3.2: Order State Machine Allows Processing → Cancelled

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Order Lifecycle & State Machine
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: status.rs:69-93

DESCRIPTION:
  The state machine allows Processing → Cancelled transition
  (status.rs:83). However, at this point stock has already been
  decremented (at checkout time). The cancel path in
  handle_payment_intent_failed restores stock, but a manual
  cancellation via update_order_status does NOT restore stock.

  The update_order_status handler (status.rs:486-820) only
  updates the status field — it doesn't trigger stock restoration
  for cancelled orders.

PROOF:
  1. Order reaches Processing status
  2. Admin cancels order via update_order_status
  3. Status changes to Cancelled
  4. Stock is NOT restored (no restore_stock_for_order call)

IMPACT:
  Cancelled orders after Processing permanently lose stock.

FIX:
  Add stock restoration in update_order_status when transitioning
  to Cancelled from any post-checkout state.

VERIFICATION:
  Cancel Processing order → stock restored.
═══════════════════════════════════════════════════════════════

---

## FLOW 4: Refunds & Returns

### Finding 4.1: Return Request Has No Ownership Check on orderId

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Refunds & Returns
OWASP: A01 Broken Access Control (IDOR)
───────────────────────────────────────────────────────────────
LOCATION: orignabase_order_repository.dart:292-310

DESCRIPTION:
  createReturnRequest sends orderId, itemIds, and reason to the
  server endpoint. The client does NOT verify that the order
  belongs to the current user before submitting.

  The server-side handler must verify ownership, but the client
  repository just passes through whatever orderId is provided.
  If the server handler also lacks ownership verification, any
  authenticated user can create return requests for any order.

  The return request is created with orderId but no userId
  validation in the client call.

PROOF:
  orignabase_order_repository.dart:298-308:
  Creates return request with only orderId, itemIds, reason.
  No userId or ownership check.

IMPACT:
  If server lacks ownership check, users can create return
  requests for other users' orders, potentially triggering
  refunds to wrong accounts.

FIX:
  Server handler must verify: order.buyerId == auth.user_id.
  Add explicit ownership assertion in the return request handler.

VERIFICATION:
  User A attempts to create return for User B's order → 403.
═══════════════════════════════════════════════════════════════

### Finding 4.2: No Return Window Enforcement

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Refunds & Returns
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: orignabase_order_repository.dart:292-310

DESCRIPTION:
  The return request creation has no return window check.
  Users can request returns for orders delivered years ago.
  The skill specifies a 30-day return window from deliveredAt,
  but neither the client nor the visible server code enforces
  this.

  The return request just captures orderId, itemIds, reason,
  and description — no date validation.

PROOF:
  No deliveredAt check in createReturnRequest.
  No server-side return window validation visible.

IMPACT:
  Users can request returns outside the policy window,
  creating support overhead and potential refund abuse.

FIX:
  Server handler must check: deliveredAt + 30 days > now.
  Reject returns outside the window with a clear error.

VERIFICATION:
  Request return for order delivered 60 days ago → rejected.
═══════════════════════════════════════════════════════════════

---

## FLOW 5: Auth & Session

### Finding 5.1: Profile Creation Failure Silently Swallowed

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Auth & Session
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: orignabase_auth_repository.dart:663-741

DESCRIPTION:
  _createUserDocumentIfNeeded catches all errors and only logs
  them (line 737-738: `catch (e) { AppLogger.d(...) }`). The
  comment says "Don't rethrow — profile creation failure
  shouldn't block auth."

  This means a user can be authenticated (have a valid JWT) but
  have no profile document. Subsequent operations that depend on
  the profile (addresses, order history, preferences) will fail
  silently or show errors.

  The ensureUserDocumentExists method (line 543-561) attempts
  recovery but also swallows errors.

PROOF:
  1. Register user → auth succeeds
  2. Profile creation fails (DB error, network issue)
  3. User is "logged in" but has no profile
  4. All profile-dependent features break

IMPACT:
  Users can sign in but can't use the app. No error is shown
  — features just silently fail.

FIX:
  Show a recovery screen when profile is missing after auth.
  Retry profile creation with exponential backoff. Don't
  silently swallow the error.

VERIFICATION:
  Simulate profile creation failure → user sees recovery UI.
═══════════════════════════════════════════════════════════════

### Finding 5.2: deleteAccount Uses Weak Confirmation String

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: Auth & Session
OWASP: A07 Authentication Failures
───────────────────────────────────────────────────────────────
LOCATION: orignabase_auth_repository.dart:510-536

DESCRIPTION:
  Account deletion requires re-authentication within 60 seconds
  (good) and sends confirmation: 'DELETE_MY_ACCOUNT'. The
  60-second window is very short — a user who re-authenticates
  and then hesitates for 61 seconds must start over.

  More concerning: the confirmation string is a hardcoded magic
  string. If the server only checks for this string match, it's
  a weak confirmation mechanism.

PROOF:
  orignabase_auth_repository.dart:519-523:
  60-second re-auth window. Line 531: 'DELETE_MY_ACCOUNT'

IMPACT:
  Minor UX friction. Low security impact since re-auth is
  the real gate.

FIX:
  Extend re-auth window to 5 minutes. Server should also
  verify the confirmation string matches.

VERIFICATION:
  Re-authenticate → wait 61 seconds → delete fails → re-auth
  required again.
═══════════════════════════════════════════════════════════════

---

## FLOW 6: Seller Product Management

### Finding 6.1: Product Creation Uses Client-Side Price Conversion (Float)

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Seller Product Management
OWASP: A03 Injection
───────────────────────────────────────────────────────────────
LOCATION: add_product_viewmodel.dart:252

DESCRIPTION:
  The ViewModel converts price from dollars to cents using
  floating-point math: `final priceCents = (price * 100).round()`

  For certain dollar amounts, floating-point representation
  causes rounding errors:
  - $19.99 → 19.99 * 100 = 1998.9999999999998 → rounds to 1999 (correct)
  - $9.90 → 9.90 * 100 = 989.9999999999999 → rounds to 990 (correct)
  - $0.29 → 0.29 * 100 = 28.999999999999996 → rounds to 29 (correct)

  While .round() catches most cases, the pattern is fragile.
  The AGENTS.md standard says "Money: always integer cents —
  never use double/float for money."

  The price parameter is `double price` — it should be
  `int priceCents` from the UI layer.

PROOF:
  add_product_viewmodel.dart:252: `(price * 100).round()`
  Function signature: `required double price`

IMPACT:
  Potential 1-cent discrepancy on certain price points.
  Violates the project's integer-cents standard.

REAL-WORLD REFERENCE:
  MedusaJS #13160 (double ×100 conversion)

FIX:
  Change the function signature to accept `int priceCents`
  directly. UI layer should convert at the text input boundary.

VERIFICATION:
  Create product with price $0.29 → priceCents = 29 exactly.
═══════════════════════════════════════════════════════════════

### Finding 6.2: Image URLs from picsum.photos in Dev/Test Mode

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: Seller Product Management
OWASP: A10 SSRF
───────────────────────────────────────────────────────────────
LOCATION: add_product_viewmodel.dart:318-319

DESCRIPTION:
  In dev/test mode with no images, the ViewModel uses
  picsum.photos URLs: `'https://picsum.photos/seed/origna-$stamp/800/800'`

  While this is only for dev/test, if OB_TEST_MODE is
  accidentally set in production, external image URLs would
  be used for products.

  Additionally, the URL is constructed with a timestamp seed,
  which means each test product gets a different random image.
  This is fine for testing but could be confusing.

PROOF:
  add_product_viewmodel.dart:318-319:
  `testImageUrls = ['https://picsum.photos/seed/origna-$stamp/800/800']`

IMPACT:
  Low — only active in dev/test mode. No production impact.

FIX:
  Use a deterministic test image URL or a local asset.
  Add an explicit environment check that prevents this path
  in production builds.

VERIFICATION:
  Create product in dev mode → uses test image.
  Create product in production → requires real images.
═══════════════════════════════════════════════════════════════

---

## FLOW 7: Multi-Seller Cart & Order Splitting

### Finding 7.1: Multi-Seller Checkout Rejected Entirely

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Multi-Seller Cart & Order Splitting
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:538-543

DESCRIPTION:
  The checkout handler rejects multi-seller carts entirely:
  "Multi-seller carts require separate checkout sessions per seller."

  This means if a user adds items from 3 sellers to their cart,
  they cannot checkout all at once. The frontend must split the
  cart and create separate checkout sessions.

  However, the cart repository (orignabase_cart_repository.dart)
  stores all items in a single cart subcollection with no
  seller-aware grouping. The frontend has no logic to split
  the cart by seller.

  This creates a gap: the cart can contain multi-seller items,
  but checkout will fail. The user sees an error with no
  guidance on how to proceed.

PROOF:
  1. Add items from seller A and seller B to cart
  2. Proceed to checkout
  3. Server returns: "Multi-seller carts require separate
     checkout sessions per seller."
  4. No UI guidance on how to split the cart

IMPACT:
  Users with multi-seller carts cannot complete purchase.
  Lost revenue, poor UX.

FIX:
  Either: (a) Implement automatic cart splitting in the
  checkout handler, creating multiple Stripe sessions, or
  (b) Add UI logic to detect multi-seller carts and guide
  users through separate checkouts.

VERIFICATION:
  Multi-seller cart → either auto-splits or shows clear UI
  guidance.
═══════════════════════════════════════════════════════════════

### Finding 7.2: Platform Fee Not Collected Without Stripe Connect Account

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Multi-Seller Cart & Order Splitting
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:666-691

DESCRIPTION:
  Platform fee is only added to the Stripe Checkout Session if
  the seller has a Stripe Connect account (starts with "acct_"):

  ```rust
  if has_connect_account {
      form_data.push(("application_fee_amount", ...));
  }
  ```

  If a seller has completed onboarding but their Stripe account
  ID is not yet set (or doesn't start with "acct_"), the platform
  fee is silently skipped. The order is still created with
  platform_fee_cents recorded, but Stripe doesn't actually
  collect it.

  This means the platform loses revenue on orders from sellers
  who haven't fully connected their Stripe accounts.

PROOF:
  checkout.rs:666-691: application_fee_amount only added when
  has_connect_account is true.

IMPACT:
  Revenue loss on orders from sellers without connected
  Stripe accounts.

REAL-WORLD REFERENCE:
  Stripe Connect #2212 (platform fee not collected)

FIX:
  Block checkout if seller doesn't have a connected Stripe
  account. The existing onboarding_completed check (line 568)
  should be sufficient, but also verify stripe_account_id
  is present and starts with "acct_".

VERIFICATION:
  Seller without Stripe Connect → checkout blocked with
  clear error message.
═══════════════════════════════════════════════════════════════

---

## FLOW 8: Search & Discovery

### Finding 8.1: Meilisearch Filter Injection Possible

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Search & Discovery
OWASP: A03 Injection
───────────────────────────────────────────────────────────────
LOCATION: home_viewmodel.dart:148-149

DESCRIPTION:
  The search suggestions filter is constructed by string
  concatenation:

  ```dart
  filter: '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}'
  ```

  While the current values are constants, if any user input
  were ever incorporated into this filter string, it would
  allow Meilisearch filter injection.

  The main product fetch goes through the repository layer
  which may have proper sanitization, but the autocomplete
  suggestions call ob.search() directly with a raw filter string.

  The searchQuery itself is passed to ob.search() which should
  sanitize it, but the filter string is not parameterized.

PROOF:
  home_viewmodel.dart:148-149: filter string is hardcoded
  constants, but the pattern is vulnerable if extended.

IMPACT:
  Currently low risk (constants only), but the pattern is
  fragile and would be vulnerable if user input is ever
  incorporated into the filter.

FIX:
  Use parameterized filter construction. Validate any
  user-provided filter values against an allowlist.

VERIFICATION:
  Search with special characters → no injection.
═══════════════════════════════════════════════════════════════

### Finding 8.2: No Max Page Size Limit on Product Fetch

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: Search & Discovery
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: home_viewmodel.dart:226-310

DESCRIPTION:
  The product loading uses pagination via lastDocumentId but
  doesn't enforce a max page size. The repository's fetchProducts
  method likely has a default limit, but there's no client-side
  or visible server-side cap.

  If the limit can be manipulated, an attacker could request
  thousands of products in a single query, causing memory
  exhaustion or slow responses.

PROOF:
  home_viewmodel.dart: fetchProducts called without explicit
  limit parameter.

IMPACT:
  Potential DoS via large page size requests.

FIX:
  Enforce max page size server-side (e.g., 50 products per
  page). Client should not be able to override this.

VERIFICATION:
  Request 1000 products → server caps at 50.
═══════════════════════════════════════════════════════════════

---

## FLOW 9: Notifications & Push

### Finding 9.1: Notification Deep Link Navigation Not Validated

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Notifications & Push
OWASP: A01 Broken Access Control
───────────────────────────────────────────────────────────────
LOCATION: orignabase_notification_service.dart:386-458

DESCRIPTION:
  handleNotificationTap navigates to screens based on
  notification data without validating user permissions:

  - Order notifications navigate to order detail with the
    orderId from the notification payload
  - No check that the user owns the order
  - If a malicious notification contains another user's
    orderId, the user is navigated to that order's detail

  The order detail screen itself should enforce ownership,
  but the notification service blindly trusts the payload.

  Additionally, the data.type field is a raw string from the
  notification payload — if an attacker can craft a notification
  with a custom type, they could potentially trigger unexpected
  navigation.

PROOF:
  orignabase_notification_service.dart:398-404:
  Navigates to order detail with orderId from notification
  data without validation.

IMPACT:
  Users could be navigated to other users' orders via
  crafted notification payloads.

FIX:
  Validate orderId ownership before navigation. Use an
  allowlist of valid notification types. Sanitize all
  navigation arguments.

VERIFICATION:
  Tap notification with another user's orderId → navigates
  to orders list, not the other user's order.
═══════════════════════════════════════════════════════════════

### Finding 9.2: FCM Token Not Invalidated on Logout for All Devices

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: Notifications & Push
OWASP: A07 Authentication Failures
───────────────────────────────────────────────────────────────
LOCATION: orignabase_auth_repository.dart:353-380

DESCRIPTION:
  signOut() calls clearTokenFromOrignaBase() which unregisters
  the current device's FCM token. However, if the user is logged
  in on multiple devices, only the current device's token is
  removed. Other devices still receive push notifications for
  the user.

  This is partially mitigated by the auth state listener that
  re-registers tokens on login, but a logged-out device's token
  may persist in the database.

PROOF:
  orignabase_auth_repository.dart:354:
  `await OrignaBaseNotificationService.instance.clearTokenFromOrignaBase()`
  Only clears current device token.

IMPACT:
  Logged-out devices may still receive push notifications.
  Privacy concern if device is shared or sold.

FIX:
  Unregister ALL FCM tokens for the user on logout, not just
  the current device's token.

VERIFICATION:
  Login on device A and B → logout on A → B still receives
  notifications, A does not.
═══════════════════════════════════════════════════════════════

---

## FLOW 10: Seller Onboarding & Stripe Connect

### Finding 10.1: No Server-Side Verification of Stripe Onboarding Completion

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Seller Onboarding & Stripe Connect
OWASP: A01 Broken Access Control
───────────────────────────────────────────────────────────────
LOCATION: checkout.rs:565-572

DESCRIPTION:
  The checkout handler checks onboarding_completed as a boolean
  field on the user document:

  ```rust
  let onboarding_completed = seller
      .get(fields::ONBOARDING_COMPLETED)
      .and_then(|v| v.as_bool())
      .unwrap_or(false);
  ```

  This field is set by the client during the onboarding flow.
  There's no server-side verification via Stripe API that the
  onboarding is actually complete. A malicious user could
  manually set this field to true in the database and bypass
  Stripe onboarding entirely.

  The charges_enabled and payouts_enabled checks (line 577-588)
  provide some protection, but these are also client-set fields
  that should be verified via Stripe API.

PROOF:
  checkout.rs:565-572: Checks onboarding_completed boolean
  from user document, not via Stripe API.

IMPACT:
  Users could bypass Stripe onboarding by manually setting
  onboarding_completed = true, then receive payments without
  proper identity verification (KYC).

REAL-WORLD REFERENCE:
  OWASP A01: Broken Access Control — client-controlled
  security fields

FIX:
  Verify onboarding status via Stripe API
  (GET /v1/accounts/{account_id}) before allowing checkout.
  Cache the result with a TTL.

VERIFICATION:
  Set onboarding_completed = true manually → checkout still
  fails because Stripe API verification fails.
═══════════════════════════════════════════════════════════════

### Finding 10.2: Seller Registration Has No Rate Limiting

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Seller Onboarding & Stripe Connect
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: orignabase_seller_registration_view_model.dart:73-116

DESCRIPTION:
  The seller registration ViewModel has a client-side debounce
  (_minOperationInterval = 3 seconds), but there's no visible
  server-side rate limiting on the /api/connect/create-account
  or /api/connect/account-link endpoints.

  An attacker could create many Stripe Connect accounts rapidly,
  potentially triggering Stripe's own rate limits or creating
  fraudulent seller accounts.

PROOF:
  orignabase_seller_registration_view_model.dart:47-48:
  Client-side 3-second debounce only.

IMPACT:
  Potential abuse of Stripe Connect account creation.
  Stripe may rate-limit or suspend the platform.

FIX:
  Add server-side rate limiting on Connect account creation
  endpoints (e.g., 5 per hour per user).

VERIFICATION:
  Rapid registration attempts → server returns 429.
═══════════════════════════════════════════════════════════════

---

## FLOW 11: User Profile & Addresses

### Finding 11.1: Address Management ViewModel Lacks Ownership Verification

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: User Profile & Addresses
OWASP: A01 Broken Access Control (IDOR)
───────────────────────────────────────────────────────────────
LOCATION: address_management_viewmodel.dart:27-48

DESCRIPTION:
  deleteAddress and setDefaultAddress pass addressId directly
  to the repository without verifying ownership. The repository
  calls userRepositoryProvider.deleteBuyerAddress and
  setDefaultBuyerAddress, which should verify the address
  belongs to the current user.

  However, the ViewModel has no client-side validation and
  relies entirely on server-side checks. If the server handler
  lacks ownership verification, any user could delete or modify
  any other user's addresses.

PROOF:
  address_management_viewmodel.dart:30:
  `await ref.read(userRepositoryProvider).deleteBuyerAddress(addressId)`
  No ownership check before the call.

IMPACT:
  If server lacks ownership check, users can delete or modify
  other users' addresses.

FIX:
  Server handler must verify: address.userId == auth.user_id.
  Add explicit ownership assertion.

VERIFICATION:
  User A attempts to delete User B's address → 403.
═══════════════════════════════════════════════════════════════

### Finding 11.2: No Max Address Limit Per User

═══════════════════════════════════════════════════════════════
SEVERITY: LOW
FLOW: User Profile & Addresses
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: address_management_viewmodel.dart

DESCRIPTION:
  There's no limit on how many addresses a user can create.
  An attacker could create thousands of addresses, consuming
  database storage and potentially causing performance issues
  when loading the address list.

PROOF:
  No address count limit visible in address management code.

IMPACT:
  Resource exhaustion via excessive address creation.

FIX:
  Enforce max 20 addresses per user server-side.

VERIFICATION:
  Create 21st address → rejected with clear error.
═══════════════════════════════════════════════════════════════

---

## FLOW 12: Subscriptions

### Finding 12.1: Subscription Creation Has Race Condition (Non-Atomic Check-Then-Create)

═══════════════════════════════════════════════════════════════
SEVERITY: HIGH
FLOW: Subscriptions
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: subscriptions.rs:266-593

DESCRIPTION:
  The create_subscription handler checks for existing active
  subscription (line 313-335), then creates a Stripe subscription
  (line 478-507), then stores in DB (line 552-559).

  Between the check and the Stripe subscription creation, another
  concurrent request could also pass the check and create a
  second Stripe subscription.

  The DB upsert (line 552) uses the user ID as the record key,
  so only one DB record is created. But the loser of the race
  has already created a Stripe subscription that is never
  recorded in the DB — a "ghost" subscription that continues
  billing the user.

  The code comment at line 523-525 acknowledges this:
  "the loser gets an empty result and must cancel the Stripe
  subscription it just created."

  But there's no code that actually cancels the ghost subscription.

PROOF:
  subscriptions.rs:523-559:
  Check → Stripe create → DB upsert.
  No cleanup of ghost Stripe subscription on DB conflict.

IMPACT:
  Users could be charged for multiple subscriptions.
  Ghost subscriptions continue billing indefinitely.

FIX:
  Wrap the entire operation in a database transaction with
  a unique constraint. If the DB upsert fails (duplicate),
  cancel the Stripe subscription that was just created.

VERIFICATION:
  Two concurrent subscription requests → only one Stripe
  subscription created, one DB record.
═══════════════════════════════════════════════════════════════

### Finding 12.2: Subscription Price Hardcoded Without Server Verification

═══════════════════════════════════════════════════════════════
SEVERITY: MEDIUM
FLOW: Subscriptions
OWASP: A04 Insecure Design
───────────────────────────────────────────────────────────────
LOCATION: subscriptions.rs:97-98

DESCRIPTION:
  The subscription price is hardcoded as a constant:
  `const PREMIUM_PRICE_CENTS: i64 = (business_rules::PREMIUM_SUBSCRIPTION_PRICE_CAD * 100.0) as i64;`

  The multiplication by 100.0 and cast to i64 uses floating-point
  math. For $7.86: 7.86 * 100.0 = 786.0 → 786 (correct).
  But if the business rule changes to a value with more decimal
  places, the truncation could cause pricing errors.

  More importantly, the price is not verified against Stripe's
  price catalog. If the Stripe price changes but the constant
  doesn't, users could be charged the wrong amount.

PROOF:
  subscriptions.rs:98: `(business_rules::PREMIUM_SUBSCRIPTION_PRICE_CAD * 100.0) as i64`

IMPACT:
  Potential pricing discrepancy if business rules change.
  No verification against Stripe's actual price.

FIX:
  Use integer constant directly: `const PREMIUM_PRICE_CENTS: i64 = 786;`
  Verify against Stripe price catalog at startup.

VERIFICATION:
  Subscription price matches Stripe catalog exactly.
═══════════════════════════════════════════════════════════════

---

## FLOW AUDIT SUMMARY

═══════════════════════════════════════════════════════════════
Date: 2026-04-04T01:18:00Z
Flows audited: 12
Total findings: 24 (CRITICAL: 0, HIGH: 7, MEDIUM: 11, LOW: 6)

OWASP COVERAGE:
  A01 Broken Access Control: 4 findings (1.4, 4.1, 9.1, 11.1)
  A03 Injection: 3 findings (1.6, 6.1, 8.1)
  A04 Insecure Design: 13 findings (1.1, 1.2, 1.3, 1.4, 1.5, 2.2, 3.2, 4.2, 5.1, 7.1, 7.2, 10.2, 11.2, 12.2)
  A07 Authentication Failures: 2 findings (5.2, 9.2)
  A10 Mishandling Exceptional Conditions: 2 findings (2.2, 2.3)

TOP 5 PRIORITIES (fix these first):
1. [HIGH] Flow 1 → Stock decremented at checkout, not payment confirmation → stock locked on abandoned checkouts → WooCommerce #44273
2. [HIGH] Flow 2 → Webhook dedup has TOCTOU race → duplicate order confirmations → WooCommerce Stripe #3300
3. [HIGH] Flow 3 → update_item_status lacks CAS guard → concurrent updates lose data → classic read-modify-write race
4. [HIGH] Flow 6 → Product price uses float→cents conversion → potential 1-cent errors → MedusaJS #13160
5. [HIGH] Flow 10 → Stripe onboarding verified via client-set boolean → KYC bypass → OWASP A01

CLEAN FLOWS (no significant findings):
- None — all 12 flows have at least one finding

MOST DANGEROUS FLOW: Flow 1 (Buyer Purchases a Product) — 6 findings
  including stock race conditions, double-checkout risk, SQL
  interpolation, and cart clearing gaps. This is the revenue-critical
  flow and has the most attack surface.

RUNNER-UP: Flow 2 (Stripe Webhook Processing) — 3 findings
  including TOCTOU race in dedup, synchronous processing timeout
  risk, and refund lookup fragility.
═══════════════════════════════════════════════════════════════
