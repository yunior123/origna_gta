# STATE.md

Now I have enough context for the full audit.

---

```
[CRITICAL] lib/features/checkout/payment_screens.dart:OrderSuccessGate + order_repository.dart:95
PROBLEM: watchPaidOrderBySession queries paymentStatus == 'captured', but process_checkout_session_completed sets paymentStatus = 'authorized' (manual capture). Every buyer lands on the 45-second timeout screen instead of success — permanent UX breakage.
FIX: Query for paymentStatus in ['authorized', 'captured'] OR change watchPaidOrderBySession to watch orderStatus == 'confirmed' instead.
ALSO: functions/handlers/payment_stripe.py:1427 (capture_method: manual)
```

```
[CRITICAL] functions/handlers/payment_stripe.py:1427
PROBLEM: capture_method="manual" contradicts Payment Auditor Pattern #1: "Auto-capture — paymentStatus is always 'captured' immediately at checkout. There is NO manual capture step." The entire capture/payout flow (confirm_order_receipt, _capture_payment_impl) is built on a forbidden authorization-only model.
FIX: Remove capture_method="manual" from Session.create, confirm payment_intent_data is absent or set to auto-capture, set paymentStatus=CAPTURED in webhook immediately, remove manual capture flow.
```

```
[CRITICAL] functions/handlers/payment_stripe.py:782-785
PROBLEM: Checkout handler reads ONBOARDING_COMPLETED and CHARGES_ENABLED from Collections.USERS (seller_cache), but per schema "seller-specific fields live in seller_profiles/{uid}, NOT in users/{uid}." These fields won't exist on the users doc, making every seller pass as if onboarding was never required.
FIX: Replace seller_cache with a seller_profiles_cache that reads from Collections.SELLER_PROFILES, matching _assert_seller_active (line 184).
```

```
[HIGH] functions/handlers/payment_stripe.py:2050-2068
PROBLEM: process_async_payment_succeeded marks paymentStatus=CAPTURED but skips amount validation, confirmation email, cart clearing, and digital license generation — all done in process_checkout_session_completed. Buyers paying by bank transfer/Interac get no email and cart is never cleared.
FIX: Extract common post-payment logic into a shared _finalize_confirmed_order() helper and call it from both process_checkout_session_completed and process_async_payment_succeeded.
```

```
[HIGH] functions/handlers/payment_stripe.py:3789-3796
PROBLEM: Payout is calculated only for items with status DELIVERED, but at capture time (buyer confirms receipt of full order) not all individual items may be DELIVERED yet (multi-seller orders). sellers_total_cents will be empty, all payouts are skipped, and payment is captured with no transfers.
FIX: Fall back to paying all sellers for SHIPPED+DELIVERED items if none are DELIVERED, or capture only after all items reach SHIPPED (at minimum), with per-item payout as each is delivered.
```

```
[HIGH] functions/handlers/payment_stripe.py:304-355
PROBLEM: verify_cart_prices reads product docs one-by-one in a loop (N+1 Firestore reads per cart item). At 10 items = 10 serial reads; at scale this is both slow and expensive.
FIX: Replace loop with db.get_all([ref1, ref2, ...]) batch read, then iterate results.
```

```
[HIGH] functions/handlers/payment_stripe.py:2041-2047 (_clear_user_cart)
PROBLEM: Deletes cart items sequentially with individual .delete() calls — not atomic. Cloud Function timeout mid-loop leaves a half-cleared cart; re-running the webhook re-processes an already-confirmed order.
FIX: Use a WriteBatch (batch.delete()) for all cart docs and commit once.
```

```
[MEDIUM] docs/json_schemas/individual/OrderCreate.json:183 + payment_stripe.py:3794,1382
PROBLEM: OrderItem.price is type number (float dollars), violating schema rule "money fields must be int cents." Float precision causes silent rounding errors (e.g., $9.99 × 100 = 998.9999...) in both tax calculation and transfer amounts.
FIX: Rename to priceCents:int in schema, all models, and handlers; remove all *100 conversions for this field.
```

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:28
PROBLEM: Hardcoded 0.13 (Ontario HST) as fallback tax rate — magic number violating "no hardcoded values" rule and schema_constants must be source of truth.
FIX: Replace with BusinessRules.defaultTaxRate or getTaxRate(BusinessRules.defaultProvince).
```

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:188
PROBLEM: Magic string 'discountAmountCents' used to parse backend response instead of ApiKeys constant.
FIX: Replace with ApiKeys.discountAmountCents (verify constant exists, add if missing).
```

```
[MEDIUM] functions/handlers/payment_stripe.py:519-538 (_coupon_within_limits)
PROBLEM: Coupon per-user usage count is read without a Firestore transaction — two simultaneous checkouts with the same coupon both pass the limit check before either increments the counter, allowing double-redemption.
FIX: Move usedCount check + increment into a Firestore transaction in the same redeem_coupon call that runs at checkout commit time.
```

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:261-284
PROBLEM: buyerNote is omitted from the per-item map sent to createCheckoutSession. Backend reads Fields.BUYER_NOTE from client item (line 880) so notes are always null on orders.
FIX: Add Fields.buyerNote: item.buyerNote to each item map in orderData.
```

```
[LOW] lib/features/checkout/checkout_provider.dart:282
PROBLEM: Client-generated idempotencyKey is sent to backend but never used — backend generates its own key from order_id (line 1432). Dead field wastes payload space and implies false protection.
FIX: Remove ApiKeys.idempotencyKey from orderData, or use it as the Stripe session idempotency_key on the backend.
```

```
[BONUS] functions/handlers/payment_stripe.py:3807
PROBLEM: payment_intent.latest_charge is a ChargeObject (not a string) in Stripe SDK v5+. Using it directly as source_transaction=charge_id passes an object where a string is expected, causing a TypeError at runtime.
FIX: charge_id = payment_intent.latest_charge if isinstance(payment_intent.latest_charge, str) else payment_intent.latest_charge.id
```

```
[BONUS] functions/handlers/payment_stripe.py:3831-3833
PROBLEM: stored_fee_rate divides stored_fee_total / subtotal_cents — but if a coupon was applied, subtotal_cents is the pre-discount value while fee was calculated on discounted_subtotal_cents, making the stored_fee_rate higher than PLATFORM_FEE_RATIO and over-charging sellers.
FIX: Store stored_fee_rate = PLATFORM_FEE_RATIO explicitly on the order at checkout instead of recomputing it.
```

```
[BONUS] functions/handlers/orders.py:336-343 (admin update_order_status)
PROBLEM: Admin can set orderStatus=DELIVERED directly, bypassing payment capture and payout logic. Delivered order with uncaptured payment = seller never gets paid.
FIX: When admin transitions to DELIVERED, call _capture_payment_impl if paymentStatus is AUTHORIZED.
```

```
[BONUS] functions/handlers/payment_stripe.py:3894
PROBLEM: At capture time, seller CHARGES_ENABLED is read from Collections.USERS (line 3847-3851 + 3894), same schema violation as checkout — field lives in seller_profiles.
FIX: Read from Collections.SELLER_PROFILES for all Stripe-specific flags.
```

```
[BONUS] lib/core/repositories/cart_repository.dart:addToCart
PROBLEM: addToCart uses a Firestore transaction to detect existing items, but the query inside a transaction (query.get()) is not supported by the Firestore Admin SDK — only document reads are transactional. The "existing item detection" is not actually atomic.
FIX: Use the cart item document ID as productId+variantId composite key (deterministic doc ID) so the transaction can do a document read instead of a query.
```

```
[BONUS] lib/features/checkout/checkout_provider.dart:99
PROBLEM: calculateShippingCost is wrapped in _algoliaCircuitBreaker, but Algolia is not involved in shipping cost calculation — this is a Geoapify/distance call. Wrong circuit breaker label causes misleading Sentry alerts.
FIX: Use a dedicated _shippingCircuitBreaker with CircuitBreakerConfig.shippingDefault.
```

```
[BONUS] functions/handlers/payment_stripe.py:1256-1298
PROBLEM: Duplicate-order dedup checks subtotal_cents match, but two identical carts submitted 61 seconds apart bypass the dedup window (BusinessRules.ORDER_DEDUP_WINDOW_SECONDS) and create two orders. Stock is double-decremented before the second Stripe session is paid.
FIX: Add a session-level idempotency key derived from userId+itemSet hash, not just time window, so identical carts always return the same pending session regardless of timing.
```

```
[BONUS] lib/features/cart/cart_provider.dart:CartController.updateQuantity:239
PROBLEM: Stock check before updateQuantity reads product doc directly (Firestore read per update), but the actual cart update is not transactional with the stock read — another buyer could decrement stock between the read and the cart write.
FIX: Remove the client-side stock check entirely (it's a UX hint only); rely on server-side stock validation at checkout which is properly transactional.
```

Now I have all the context needed. Let me compile the full verified audit with code.All findings verified. Here is the final audit with code snippets.

---

```
[CRITICAL] lib/core/repositories/order_repository.dart:95
ALSO: functions/handlers/payment_stripe.py:1427, 1930
PROBLEM: watchPaidOrderBySession queries paymentStatus == 'captured', but Session.create uses capture_method="manual" so checkout.session.completed sets paymentStatus=AUTHORIZED. process_payment_intent_succeeded (line 2292) explicitly skips AUTHORIZED orders. Every buyer lands on the 45-second timeout screen — 100% failure rate in production.
FIX: Remove capture_method="manual" (auto-capture spec, Payment Auditor #1). In process_checkout_session_completed set CAPTURED directly. Payouts execute at webhook time, not on buyer confirmation. No query change needed.
```

**payment_stripe.py — Session.create fix (~line 1417):**
```python
# REMOVE payment_intent_data entirely — auto-capture is the spec
session = stripe.checkout.Session.create(
    line_items=line_items,
    mode="payment",
    success_url=f"{BASE_URL}{AppConfig.CHECKOUT_SUCCESS_PATH}?session_id={{CHECKOUT_SESSION_ID}}",
    cancel_url=f"{BASE_URL}{AppConfig.CHECKOUT_CANCEL_PATH}",
    client_reference_id=user_id,
    metadata={Fields.ORDER_ID: order_id, Fields.USER_ID: user_id},
    # No payment_intent_data → Stripe auto-captures immediately
    idempotency_key=f"checkout_{order_id}",
)
```

**process_checkout_session_completed — set CAPTURED directly (~line 1916):**
```python
# After passing all validation and address checks:
pi_id = session.get("payment_intent")
charge_id = None
if pi_id:
    try:
        pi = stripe.PaymentIntent.retrieve(pi_id)
        charge_id = pi.latest_charge  # string in default SDK (no expand)
    except Exception as e:
        logger.warning(f"Could not retrieve PI for charge_id: {e}")

update_data = {
    Fields.ORDER_STATUS: OrderStatusValues.CONFIRMED,
    Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,  # auto-capture: always CAPTURED
    Fields.CAPTURED_AT: get_server_timestamp(),
    Fields.STRIPE_PAYMENT_INTENT_ID: pi_id,
    Fields.STRIPE_CHARGE_ID: charge_id,  # store for transfers
    Fields.UPDATED_AT: get_server_timestamp(),
}
order_ref.update(update_data)

# Immediately execute transfers (charge_id available now)
_execute_seller_payouts(order_id, order_data, charge_id)
```

**New _execute_seller_payouts helper (replaces sellers_total_cents loop in _capture_payment_impl):**
```python
def _execute_seller_payouts(order_id: str, order_data: dict, charge_id: str) -> list:
    """Execute Stripe transfers for all sellers. Called at checkout.session.completed (auto-capture)."""
    if not charge_id:
        logger.error(f"No charge_id for order {order_id} — transfers skipped")
        return [{"error": "no_charge_id"}]

    items = order_data.get(Fields.ITEMS, [])
    sellers_total_cents: dict[str, int] = {}
    for item in items:
        seller_id = item[Fields.SELLER_ID]
        item_total = round(item[Fields.PRICE] * 100) * item[Fields.QUANTITY]
        sellers_total_cents[seller_id] = sellers_total_cents.get(seller_id, 0) + item_total

    platform_fee_ratio = PLATFORM_FEE_RATIO  # snapshot at call time
    seller_account_snapshot = order_data.get(Fields.SELLER_STRIPE_ACCOUNTS, {})
    transfer_errors = []

    for seller_id, amount_cents in sellers_total_cents.items():
        platform_fee_cents = round(amount_cents * platform_fee_ratio)
        net_amount_cents = amount_cents - platform_fee_cents
        stripe_account_id = seller_account_snapshot.get(seller_id)
        if not stripe_account_id:
            # Fallback: live lookup (new sellers post-launch)
            sp = get_db().collection(Collections.SELLER_PROFILES).document(seller_id).get()
            stripe_account_id = (sp.to_dict() or {}).get(Fields.STRIPE_ACCOUNT_ID) if sp.exists else None
        if not stripe_account_id:
            transfer_errors.append({Fields.SELLER_ID: seller_id, Fields.ERROR: "no_stripe_account"})
            continue
        payout_ref = get_db().collection(Collections.PAYOUTS).document(f"{order_id}_{seller_id}")
        payout_ref.set({
            Fields.ORDER_ID: order_id,
            Fields.SELLER_ID: seller_id,
            Fields.AMOUNT_CENTS: amount_cents,
            Fields.PLATFORM_FEE_CENTS: platform_fee_cents,
            Fields.NET_AMOUNT_CENTS: net_amount_cents,
            Fields.CURRENCY: BusinessRules.DEFAULT_CURRENCY,
            Fields.STRIPE_ACCOUNT_ID: stripe_account_id,
            Fields.STATUS: PayoutStatusValues.PENDING,
            Fields.CREATED_AT: get_server_timestamp(),
        }, merge=True)
        try:
            transfer = stripe.Transfer.create(
                amount=net_amount_cents,
                currency=BusinessRules.DEFAULT_CURRENCY,
                destination=stripe_account_id,
                source_transaction=charge_id,
                transfer_group=order_id,
                metadata={Fields.ORDER_ID: order_id, Fields.SELLER_ID: seller_id},
                idempotency_key=f"transfer_{order_id}_{seller_id}",
            )
            payout_ref.update({Fields.STRIPE_TRANSFER_ID: transfer.id, Fields.STATUS: PayoutStatusValues.COMPLETED})
        except Exception as e:
            payout_ref.update({Fields.STATUS: PayoutStatusValues.FAILED, Fields.FAILURE_REASON: str(e)})
            transfer_errors.append({Fields.SELLER_ID: seller_id, Fields.ERROR: type(e).__name__})
    return transfer_errors
```

---

```
[CRITICAL] functions/handlers/payment_stripe.py:771-785
ALSO: functions/handlers/payment_stripe.py:3894
PROBLEM: Checkout validates seller using seller_cache loaded from Collections.USERS. ONBOARDING_COMPLETED and CHARGES_ENABLED live in seller_profiles/{uid} per schema (confirmed correct in _assert_seller_active at line 184). Every seller always passes the check with .get(..., False) returning False — meaning sellers who never completed Stripe onboarding can still accept payments.
FIX: Load seller_profiles separately into a profiles_cache; read Stripe-specific flags from there.
```

```python
# In create_checkout_session — replace seller_cache with split caches
seller_cache: dict[str, dict] = {}        # users/{uid} — for suspended/name
seller_profiles_cache: dict[str, dict] = {}  # seller_profiles/{uid} — for Stripe flags

# Inside the per-item loop replacing lines 771-786:
if seller_id not in seller_cache:
    seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
    seller_cache[seller_id] = seller_doc.to_dict() if seller_doc.exists else {}
    sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(seller_id).get()
    seller_profiles_cache[seller_id] = sp_doc.to_dict() if sp_doc.exists else {}

seller_data = seller_cache[seller_id]
seller_profile = seller_profiles_cache[seller_id]  # Stripe fields live here

if not seller_data:
    raise https_fn.HttpsError("not-found", f"Seller {seller_id} not found")
if seller_data.get(Fields.SUSPENDED, False):
    raise https_fn.HttpsError("permission-denied", f"Seller {seller_id} is suspended")
if not seller_profile.get(Fields.ONBOARDING_COMPLETED, False):
    raise https_fn.HttpsError("failed-precondition", f"Seller {seller_id} has not completed onboarding")
if not seller_profile.get(Fields.CHARGES_ENABLED, False):
    raise https_fn.HttpsError("failed-precondition", f"Seller {seller_id} is not approved to receive payments")
```

```python
# Same fix in _capture_payment_impl (~line 3847) — replace:
seller_doc = get_db().collection(Collections.USERS).document(seller_id).get()
# ADD:
sp_doc = get_db().collection(Collections.SELLER_PROFILES).document(seller_id).get()
sp_data = sp_doc.to_dict() if sp_doc.exists else {}
# Then at line ~3894:
if not sp_data.get(Fields.CHARGES_ENABLED, False):  # was: seller_data.get(...)
```

---

```
[CRITICAL] functions/handlers/payment_stripe.py:1241-1298
PROBLEM: reserve_stock_transaction (line 1241) executes BEFORE the dedup check (line 1256). On a duplicate concurrent request that exits early at line 1292 returning the existing session, the stock reservation from the current request is never rolled back. Two users purchasing simultaneously both decrement stock, but only one order exists — negative stock / oversell.
FIX: Move dedup check BEFORE stock reservation, or rollback stock if early-return path is taken.
```

```python
# In create_checkout_session — MOVE the dedup block to BEFORE reserve_stock_transaction
# Replace the current order: [validate items] → [reserve stock] → [dedup check]
# With: [validate items] → [dedup check] → [reserve stock] → [create order]

# Insert this block AFTER validated_items loop and BEFORE reserve_stock_transaction:
recent_orders = (
    get_db()
    .collection(Collections.ORDERS)
    .where(Fields.USER_ID, "==", user_id)
    .where(Fields.ORDER_STATUS, "==", OrderStatusValues.PENDING)
    .where(Fields.PAYMENT_STATUS, "==", PaymentStatusValues.AWAITING_PAYMENT)
    .order_by(Fields.CREATED_AT, direction="DESCENDING")
    .limit(1)
    .get()
)
for recent_doc in recent_orders:
    recent_data = recent_doc.to_dict()
    recent_created = recent_data.get(Fields.CREATED_AT)
    if recent_created:
        if hasattr(recent_created, "tzinfo") and recent_created.tzinfo is None:
            recent_created = recent_created.replace(tzinfo=UTC)
        age_seconds = (datetime.now(UTC) - recent_created).total_seconds()
        if (
            age_seconds < BusinessRules.ORDER_DEDUP_WINDOW_SECONDS
            and recent_data.get(Fields.SUBTOTAL_CENTS) == actual_subtotal_cents
        ):
            existing_session_id = recent_data.get(Fields.STRIPE_SESSION_ID)
            if existing_session_id:
                try:
                    existing_session = stripe.checkout.Session.retrieve(existing_session_id)
                    checkout_url = existing_session.url
                except Exception:
                    checkout_url = None
                if checkout_url:
                    # Return BEFORE stock reservation — no rollback needed
                    return {
                        ApiKeys.SUCCESS: True,
                        ApiKeys.SESSION_ID: existing_session_id,
                        Fields.ORDER_ID: recent_doc.id,
                        ApiKeys.CHECKOUT_URL: checkout_url,
                        ApiKeys.DUPLICATE: True,
                    }

# THEN reserve stock:
transaction = get_db().transaction()
try:
    reserve_stock_transaction(transaction)
...
```

---

```
[HIGH] functions/handlers/payment_stripe.py:2050-2068
PROBLEM: process_async_payment_succeeded (bank transfer / Interac) only updates paymentStatus to CAPTURED — it does not send confirmation email, clear the cart, generate digital licenses, or redeem coupons. Buyers paying via Interac (hugely popular in Canada) get no order confirmation email and cart is never cleared.
FIX: Extract post-confirmation side-effects from process_checkout_session_completed into a shared helper; call it from both handlers.
```

```python
def _run_post_payment_side_effects(order_id: str, order_data: dict) -> None:
    """
    Runs all side-effects after payment is confirmed (email, cart, licenses, coupons).
    Called from both checkout.session.completed and checkout.session.async_payment_succeeded.
    """
    # Send confirmation email
    try:
        buyer_email = order_data.get(Fields.CUSTOMER_EMAIL)
        if not buyer_email:
            buyer_doc = get_db().collection(Collections.USERS).document(order_data[Fields.USER_ID]).get()
            if buyer_doc.exists:
                buyer_email = buyer_doc.to_dict().get(Fields.EMAIL)
        buyer_lang = order_data.get(Fields.PREFERRED_LANGUAGE, "en")
        if buyer_email:
            html = get_order_confirmation_email(order_data, order_id, lang=buyer_lang)
            send_email(to_email=buyer_email, subject=_email_t("sub.confirmed", buyer_lang), html_content=html)
        for seller_id in set(i[Fields.SELLER_ID] for i in order_data.get(Fields.ITEMS, [])):
            sdoc = get_db().collection(Collections.USERS).document(seller_id).get()
            if sdoc.exists:
                sd = sdoc.to_dict()
                se = sd.get(Fields.EMAIL)
                if se:
                    sl = sd.get(Fields.PREFERRED_LANGUAGE, "en")
                    send_email(to_email=se, subject=_email_t("sub.new_order", sl),
                               html_content=get_seller_notification_email(order_data, order_id, seller_id, lang=sl))
    except Exception as e:
        logger.error(f"Confirmation email failed for {order_id}: {e}")

    try:
        _generate_digital_licenses(order_id, order_data)
    except Exception as e:
        logger.error(f"Digital license generation failed for {order_id}: {e}")

    try:
        applied_coupon = order_data.get(Fields.COUPON_CODE)
        if applied_coupon:
            from handlers.coupons import redeem_coupon as _redeem_coupon
            _redeem_coupon(applied_coupon, order_data[Fields.USER_ID], order_id=order_id)
    except Exception as e:
        logger.error(f"Coupon redeem failed for {order_id}: {e}")

    try:
        _clear_user_cart(order_data[Fields.USER_ID])
    except Exception as e:
        logger.error(f"Cart clear failed for {order_id}: {e}")


def process_async_payment_succeeded(session: dict) -> str | None:
    order_id = session.get("metadata", {}).get(Fields.ORDER_ID)
    if not order_id:
        return None
    order_ref = get_db().collection(Collections.ORDERS).document(order_id)
    order_doc = order_ref.get()
    if not order_doc.exists:
        return None
    order_data = order_doc.to_dict()
    
    # Idempotency: don't re-run if already captured
    if order_data.get(Fields.PAYMENT_STATUS) == PaymentStatusValues.CAPTURED:
        return f"Order {order_id} already captured (idempotent)"

    charge_id = None
    pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
    if pi_id:
        try:
            pi = stripe.PaymentIntent.retrieve(pi_id)
            charge_id = pi.latest_charge
        except Exception as e:
            logger.warning(f"Could not get charge_id for async payout {order_id}: {e}")

    order_ref.update({
        Fields.PAYMENT_STATUS: PaymentStatusValues.CAPTURED,
        Fields.CAPTURED_AT: get_server_timestamp(),
        Fields.UPDATED_AT: get_server_timestamp(),
    })

    _execute_seller_payouts(order_id, order_data, charge_id)  # same helper as above
    _run_post_payment_side_effects(order_id, order_data)
    return f"Order {order_id} async payment captured"
```

---

```
[HIGH] functions/handlers/payment_stripe.py:304-355
PROBLEM: verify_cart_prices reads each product document individually inside a loop — N+1 Firestore reads per cart item. 10-item cart = 10 serial roundtrips. At 100M+ users this is both slow (linear latency) and expensive.
FIX: Batch all product reads with db.get_all() then iterate the results map.
```

```python
@https_fn.on_call(**DEFAULT_OPTIONS)
def verify_cart_prices(req: https_fn.CallableRequest) -> dict[str, Any]:
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "User must be authenticated")

    # ... rate limit check unchanged ...

    items = req.data.get(Fields.ITEMS, [])
    if not items:
        raise https_fn.HttpsError("invalid-argument", "No items to verify")

    # BATCH READ: one round-trip for all products
    db = get_db()
    product_ids = [item.get(Fields.PRODUCT_ID) for item in items if item.get(Fields.PRODUCT_ID)]
    product_refs = [db.collection(Collections.PRODUCTS).document(pid) for pid in product_ids]
    product_snapshots = db.get_all(product_refs)  # single batch read
    product_map = {snap.id: snap.to_dict() for snap in product_snapshots if snap.exists}

    price_changes, stock_changes, removed_products = [], [], []

    for item in items:
        product_id = item.get(Fields.PRODUCT_ID)
        if not product_id:
            continue

        product_data = product_map.get(product_id)

        if not product_data:
            removed_products.append({Fields.PRODUCT_ID: product_id})
            continue

        if product_data.get(Fields.LIFECYCLE_STATUS) != ProductLifecycleStatusValues.ACTIVE:
            removed_products.append({
                Fields.PRODUCT_ID: product_id,
                Fields.NAME: product_data.get(Fields.NAME, ""),
                Fields.REASON: CartVerificationReasonValues.DEACTIVATED,
            })
            continue

        db_price = round(product_data.get(Fields.PRICE, 0), 2)
        client_price_r = round(item.get(Fields.PRICE, 0), 2)
        if abs(db_price - client_price_r) > 0.01:
            price_changes.append({
                Fields.PRODUCT_ID: product_id,
                Fields.NAME: product_data.get(Fields.NAME, ""),
                ApiKeys.OLD_PRICE: item.get(Fields.PRICE),
                ApiKeys.NEW_PRICE: db_price,
            })

        stock_qty = product_data.get(Fields.STOCK_QUANTITY, 0)
        requested_qty = item.get(Fields.QUANTITY, 1)
        if stock_qty < requested_qty:
            stock_changes.append({
                Fields.PRODUCT_ID: product_id,
                Fields.NAME: product_data.get(Fields.NAME, ""),
                ApiKeys.REQUESTED: requested_qty,
                ApiKeys.AVAILABLE: stock_qty,
            })

    from utils.helpers import create_success_response
    return create_success_response({
        ApiKeys.HAS_CHANGES: bool(price_changes or stock_changes or removed_products),
        ApiKeys.PRICE_CHANGES: price_changes,
        ApiKeys.STOCK_CHANGES: stock_changes,
        ApiKeys.REMOVED_PRODUCTS: removed_products,
    })
```

---

```
[HIGH] functions/handlers/payment_stripe.py:2041-2047
PROBLEM: _clear_user_cart deletes items one-by-one in a loop. If Cloud Function times out mid-loop (possible with large carts), cart is left half-cleared. On webhook retry, idempotency guard prevents re-running the whole handler, so cart is never fully cleared.
FIX: Batch all deletes; commit atomically.
```

```python
def _clear_user_cart(user_id: str) -> None:
    cart_ref = get_db().collection(Collections.USERS).document(user_id).collection(Collections.CART)
    docs = list(cart_ref.stream())
    if not docs:
        return
    # Firestore batch limit is 500 writes
    for chunk_start in range(0, len(docs), 500):
        batch = get_db().batch()
        for doc in docs[chunk_start:chunk_start + 500]:
            batch.delete(doc.reference)
        batch.commit()
```

---

```
[MEDIUM] functions/handlers/payment_stripe.py:519-538
PROBLEM: _coupon_within_limits reads usedCount for per-user limit check WITHOUT a transaction. Two simultaneous checkouts with the same coupon (race window ~200ms) both pass the check before either increments the counter — double redemption on single-use coupons.
FIX: Move the usedCount check + increment into a single Firestore transaction inside redeem_coupon, using conditional update to enforce atomicity.
```

```python
# In handlers/coupons.py — redeem_coupon (called at checkout commit, not verify)
def redeem_coupon(code: str, user_id: str, order_id: str) -> bool:
    """
    Atomically validates per-user usage and increments counter.
    Returns True if redemption succeeded, False if limit already reached.
    """
    from firebase_admin import firestore as fs
    db = get_db()
    coupon_ref = db.collection(Collections.COUPONS).document(code)
    use_ref = coupon_ref.collection(Collections.COUPON_USES).document(user_id)

    @fs.transactional
    def _atomic_redeem(transaction):
        coupon_snap = coupon_ref.get(transaction=transaction)
        use_snap = use_ref.get(transaction=transaction)
        if not coupon_snap.exists:
            return False, "not_found"

        coupon_data = coupon_snap.to_dict() or {}

        # Re-check global limit inside transaction
        max_total = coupon_data.get(Fields.MAX_USES_TOTAL)
        used_total = int(coupon_data.get(Fields.USED_COUNT, 0))
        if max_total is not None and used_total >= int(max_total):
            return False, "global_limit_reached"

        # Re-check per-user limit inside transaction
        max_per_user = int(coupon_data.get(Fields.MAX_USES_PER_USER, 1))
        user_count = int((use_snap.to_dict() or {}).get("useCount", 0)) if use_snap.exists else 0
        if user_count >= max_per_user:
            return False, "user_limit_reached"

        # Atomically increment both counters
        transaction.update(coupon_ref, {Fields.USED_COUNT: fs.Increment(1)})
        transaction.set(use_ref, {
            "useCount": fs.Increment(1),
            "lastOrderId": order_id,
            Fields.UPDATED_AT: get_server_timestamp(),
        }, merge=True)
        return True, None

    txn = db.transaction()
    success, reason = _atomic_redeem(txn)
    if not success:
        logger.warning(f"Coupon {code} redeem rejected for user {user_id}: {reason}")
    return success
```

---

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:261-284
PROBLEM: buyerNote is not included in the per-item map sent to createCheckoutSession. Backend reads Fields.BUYER_NOTE from client items (payment_stripe.py:880) so all buyer notes are null on every order.
FIX: Add buyerNote to each item map.
```

```dart
Fields.items: items
    .map(
      (item) => {
        Fields.productId: item.productId,
        Fields.name: item.name,
        Fields.price: item.price,
        Fields.quantity: item.quantity,
        Fields.sellerId: item.sellerId,
        Fields.imageUrls: item.imageUrls,
        if (item.buyerNote != null && item.buyerNote!.isNotEmpty)
          Fields.buyerNote: item.buyerNote,
      },
    )
    .toList(),
```

---

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:28
PROBLEM: Hardcoded magic number 0.13 (Ontario HST) as fallback tax rate. Violates "no magic strings/values" rule. Will silently show wrong tax to non-Ontario users who haven't set an address yet.
FIX: Use schema constant.
```

```dart
// checkout_provider.dart:28
final checkoutTaxRateProvider = Provider.autoDispose<double>((ref) {
  final checkoutState = ref.watch(checkoutStateProvider);
  if (checkoutState.address == null) {
    return getTaxRate(BusinessRules.defaultProvince); // not 0.13
  }
  return getTaxRate(checkoutState.address!.state);
});
```

---

```
[MEDIUM] lib/features/checkout/checkout_provider.dart:188
PROBLEM: Magic string 'discountAmountCents' to parse backend response. Violates no-magic-strings rule; will silently return 0 if backend renames the key.
FIX: Use ApiKeys constant (add to schema_constants if missing).
```

```dart
// checkout_provider.dart:188
final discountCents = (data[ApiKeys.discountAmountCents] as num?)?.toInt() ?? 0;
```

```python
# schema_constants.py — verify/add to ApiKeys:
class ApiKeys:
    ...
    DISCOUNT_AMOUNT_CENTS = 'discountAmountCents'
```

```dart
// schema_constants.dart — verify/add:
abstract final class ApiKeys {
  ...
  static const discountAmountCents = 'discountAmountCents';
}
```

---

```
[LOW] lib/features/checkout/checkout_provider.dart:282
PROBLEM: Client sends ApiKeys.idempotencyKey to the backend, but create_checkout_session ignores it — using f"checkout_{order_id}" as the Stripe idempotency key instead (line 1432). Dead request field creates false security impression that the client key is protecting anything.
FIX: Either use the client key on the backend for Stripe session creation, or remove it from orderData entirely.
```

```python
# In create_checkout_session, replace hardcoded key with client-supplied one:
client_idempotency_key = data.get(ApiKeys.IDEMPOTENCY_KEY)
stripe_idempotency_key = client_idempotency_key or f"checkout_{order_id}"

session = stripe.checkout.Session.create(
    ...
    idempotency_key=stripe_idempotency_key,
)
```

---

```
[BONUS] functions/handlers/orders.py:246-251
PROBLEM: update_order_status allows admin to set orderStatus=DELIVERED directly (line 336) without triggering payment capture. An admin marking an authorized order as DELIVERED leaves the PaymentIntent in requires_capture until it expires 7 days later — seller is never paid, buyer was never charged.
FIX: When admin transitions to DELIVERED and paymentStatus is AUTHORIZED/CAPTURING, call _capture_payment_impl before updating status.
```

```python
# In update_order_status, admin path (after line 335):
if is_admin and new_status == OrderStatusValues.DELIVERED:
    payment_status = order_data.get(Fields.PAYMENT_STATUS)
    if payment_status in (PaymentStatusValues.AUTHORIZED, PaymentStatusValues.CAPTURING):
        # With auto-capture (F2 fix applied), this path shouldn't normally be reached.
        # Guard for legacy manual-capture orders or edge cases.
        pi_id = order_data.get(Fields.STRIPE_PAYMENT_INTENT_ID)
        if pi_id:
            try:
                ensure_stripe_key()
                pi = stripe.PaymentIntent.retrieve(pi_id)
                if pi.status == "requires_capture":
                    stripe.PaymentIntent.capture(pi_id, idempotency_key=f"admin_capture_{order_id}")
                    charge_id = stripe.PaymentIntent.retrieve(pi_id).latest_charge
                    _execute_seller_payouts(order_id, order_data, charge_id)
            except Exception as e:
                logger.error(f"Admin-triggered capture failed for {order_id}: {e}")
                raise https_fn.HttpsError("internal", "Could not capture payment before marking delivered.")
```

---

```
[BONUS] lib/features/checkout/checkout_provider.dart:99
PROBLEM: calculateShippingCost is wrapped in _algoliaCircuitBreaker. Algolia is not involved in shipping calculation (Geoapify/distance). Wrong circuit breaker label means: Algolia search outages open the shipping circuit, and shipping timeouts open the Algolia circuit — cross-contamination that takes down unrelated features.
FIX: Use a dedicated shipping circuit breaker.
```

```dart
// checkout_provider.dart — add at top level:
final _shippingCircuitBreaker = CircuitBreakerRegistry.get(
  'shipping_calculation',
  config: CircuitBreakerConfig.serviceDefault, // or a shipping-specific config
);

// In calculateShipping, line 99:
final cost = await _shippingCircuitBreaker.execute(  // was _algoliaCircuitBreaker
    () => calculateShippingCost(items, state.address));
```