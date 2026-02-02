# EDGE CASES & UNHANDLED WORKFLOWS AUDIT

Date: 2 février 2026  
Status: Chasse proactive des edge cases après Phase 3

---

## 1. ❌ PRODUCT DELETION WITH ACTIVE ORDERS

### Current Behavior
- Product soft-deleted: `isActive = false`
- Product stays in orders collection (by ID reference)

### Edge Case
**Scenario**: Seller deletes product while order is in `pending`, `confirmed`, or `shipped` state.

```python
# functions/main.py line 1795
def delete_product(req):
    product_ref.update({'isActive': False, 'deletedAt': now})
    # ❌ No check for active orders referencing this product
```

### Risks
1. **Buyer sees broken product data**: Product name/image might disappear
2. **Seller can't fulfill**: Deleted product → no stock tracking
3. **Refunds unclear**: If seller deletes, should buyer auto-refund?

### Recommendation
```python
# Before soft-delete, check for active orders
active_orders = db.collection('orders').where(
    'items', 'array_contains', {'productId': product_id}
).where('status', 'in', ['pending', 'confirmed', 'shipped']).get()

if active_orders:
    raise ValueError("Cannot delete product with active orders. Cancel orders first.")
```

**Severity**: MEDIUM  
**Impact**: UX degradation, potential order fulfillment issues  
**Fix Priority**: Phase 4

---

## 2. ❌ SELLER ACCOUNT SUSPENSION WITH PENDING ORDERS

### Current Behavior
- Admin can suspend seller: `suspended = true`
- Suspended seller UI locked

### Edge Case
**Scenario**: Admin suspends seller who has 10 active orders in `confirmed` or `shipped` state.

**What happens?**
- ❌ Seller can't ship orders (UI locked)
- ❌ Buyers stuck waiting
- ❌ No auto-cancellation or refund

### Recommendation
```python
# admin_actions.py
def suspend_seller(seller_id):
    # 1. Find active orders
    active_orders = db.collection('orders').where(
        'items', 'array_contains', {'sellerId': seller_id}
    ).where('status', 'in', ['pending', 'confirmed', 'shipped']).get()
    
    # 2. Cancel & refund all
    for order in active_orders:
        cancel_order(order.id, reason="Seller suspended")
        refund_order(order.id)
    
    # 3. Then suspend
    db.collection('users').document(seller_id).update({'suspended': True})
```

**Severity**: HIGH  
**Impact**: Buyer funds locked, no delivery  
**Fix Priority**: Phase 4 (URGENT)

---

## 3. ❌ AUTO-CAPTURE FAILURE → STUCK AUTHORIZATION

### Current Behavior
- Auto-capture job runs every 30min
- If capture fails: logged, but no compensation

```python
# functions/main.py line 4095
except stripe.error.CardError as e:
    print(f"❌ Card error capturing order {order_id}: {e.user_message}")
    failed_count += 1
    # TODO: Send notification to buyer that payment capture failed
```

### Edge Case
**Scenario**: Authorization expires (7 days), auto-capture never succeeded.

**What happens?**
- ❌ Order stuck in `authorized` state forever
- ❌ Stock never restored
- ❌ Buyer never notified
- ❌ No manual intervention trigger

### Recommendation
```python
# Add to auto_capture job
if failed_attempts >= 3:  # After 3 failures (1.5 hours)
    # Cancel order
    order_ref.update({'status': 'cancelled', 'paymentStatus': 'capture_failed'})
    
    # Restore stock
    _restore_stock_for_order(order_data)
    
    # Notify buyer
    send_email(buyer_email, 
        subject="Order Cancelled - Payment Issue",
        body="Your payment could not be processed. Stock has been restored."
    )
```

**Severity**: MEDIUM  
**Impact**: Stock leakage, buyer confusion  
**Fix Priority**: Phase 4

---

## 4. ⚠️ DISPUTE AFTER DELIVERED (CHARGEBACK FRAUD)

### Current Behavior
- `charge.dispute.created` logged
- `charge.dispute.closed` updates dispute status

```python
# functions/main.py line 1312
def process_dispute_closed(dispute):
    order_ref.update({
        "disputeStatus": dispute_status,
        "disputeClosedAt": now,
    })
```

### Edge Case
**Scenario**: Buyer receives product → files chargeback → wins dispute.

**What happens?**
- ✅ Dispute status logged
- ❌ No stock restoration (product delivered)
- ❌ No seller notification
- ❌ No fraud flag for buyer

### Recommendation
```python
def process_dispute_closed(dispute):
    if dispute_status == 'lost':
        # Seller lost → buyer got refund + kept product
        order_ref.update({
            'disputeStatus': 'lost',
            'fraudSuspected': True,  # Flag buyer
        })
        
        # Alert admin for review
        db.collection('security_alerts').add({
            'type': 'chargeback_fraud',
            'userId': order_data['userId'],
            'orderId': order_id,
            'timestamp': now,
        })
```

**Severity**: MEDIUM  
**Impact**: Seller revenue loss, platform trust  
**Fix Priority**: Phase 4

---

## 5. ❌ SHIPPING APPROVAL TIMEOUT NOT ENFORCED

### Current Behavior
- Auto-approval scheduler runs every 15min
- Approves orders > 24h old with `shippingApprovalStatus = pending`

### Edge Case
**Scenario**: Buyer never approves/rejects shipping cost, but scheduler fails to run (Firebase outage).

**What happens?**
- ❌ Order stuck in `pending` forever
- ❌ Seller can't ship
- ❌ Authorization might expire

### Current Safeguard
✅ Scheduler exists: `auto_approve_shipping()` every 15min

### Additional Safety
```python
# Add TTL-based check in capture_payment()
if approval_status == 'pending':
    created_at = order_data.get('createdAt')
    age_hours = (now - created_at).total_seconds() / 3600
    
    if age_hours > 24:
        # Auto-approve (fallback)
        order_ref.update({'shippingApprovalStatus': 'approved'})
        print(f"⏰ Auto-approved after 24h timeout")
```

**Severity**: LOW (already mitigated)  
**Status**: GOOD (scheduler + fallback)

---

## 6. ❌ WEBHOOK REPLAY ATTACK (IDEMPOTENCY BYPASS)

### Current Behavior
- Webhook events logged by `eventId`
- Duplicate events skipped

```python
# functions/main.py line 680
event_log_ref = db.collection('stripe_events').document(event_id)
if event_log_ref.get().exists:
    return success("already_processed")
```

### Edge Case
**Scenario**: Attacker modifies `event_id` to bypass duplicate check.

**Risk**: Payment processing twice (double charge)

### Current Safeguard
✅ Stripe signature verification (`stripe.Webhook.construct_event`)

### Additional Hardening
```python
# Add timestamp check
event_created = event.get('created')
age_seconds = time.time() - event_created

if age_seconds > 300:  # 5 minutes
    return error("Event too old, likely replay attack")
```

**Severity**: LOW (Stripe signature sufficient)  
**Status**: GOOD

---

## 7. ❌ RATE LIMITER COLLISION (CONCURRENT REQUESTS)

### Current Behavior
- Rate limits checked via Firestore document

```python
# functions/main.py line 2150
rate_ref = db.collection('rate_limits').document(rate_key)
rate_doc = rate_ref.get()

if attempt_count >= max_attempts:
    raise https_fn.HttpsError("Too many requests")
```

### Edge Case
**Scenario**: 10 concurrent requests hit rate limiter simultaneously, all read `attempt_count = 0`, all pass.

**Risk**: Rate limit bypass

### Recommendation
```python
# Use Firestore transaction
@firestore.transactional
def check_and_increment_rate_limit(transaction, rate_ref, max_attempts):
    rate_doc = rate_ref.get(transaction=transaction)
    attempts = rate_doc.to_dict().get('attempts', 0) if rate_doc.exists else 0
    
    if attempts >= max_attempts:
        raise RateLimitError()
    
    transaction.set(rate_ref, {'attempts': attempts + 1, 'updatedAt': now}, merge=True)
```

**Severity**: MEDIUM  
**Impact**: Rate limit bypass, API abuse  
**Fix Priority**: Phase 4

---

## 8. ❌ MULTI-SELLER ORDER → PARTIAL CAPTURE

### Current Behavior
- Multi-seller order: single `PaymentIntent`
- Each seller calls `capture_payment()` separately

```python
# functions/main.py line 3176
if not is_already_paid:
    stripe.PaymentIntent.capture(payment_intent_id, amount_to_capture=capture_amount)
```

### Edge Case
**Scenario**: 3 sellers, Seller A captures, Seller B captures, **Seller C never ships**.

**What happens?**
- ❌ Payment fully captured (Sellers A+B)
- ❌ Buyer charged for Seller C's items (not shipped)
- ❌ No partial refund logic

### Recommendation
```python
# Track per-seller capture status
order_ref.update({
    f'sellers.{seller_id}.captured': True,
    f'sellers.{seller_id}.capturedAmount': seller_total,
})

# After 7 days, check if all sellers captured
if all_sellers_captured():
    mark_paid()
else:
    # Refund uncaptured portion
    refund_amount = total - captured_sum
    stripe.Refund.create(payment_intent=payment_intent_id, amount=refund_amount)
```

**Severity**: MEDIUM  
**Impact**: Buyer overcharged  
**Fix Priority**: Phase 4

---

## 9. ⚠️ SESSION TIMEOUT DURING CHECKOUT

### Current Behavior
- Session timeout: 1h inactivity
- Auto-logout + snackbar

### Edge Case
**Scenario**: User fills cart → goes to checkout → session expires → redirected to login.

**What happens?**
- ❌ Cart persisted in Firestore (good)
- ✅ User can log back in → cart still there (GOOD)
- ⚠️ Stock reserved? **NO** (stock reserved during checkout, not in cart)

### Status
✅ SAFE: Stock reserved atomically during checkout session creation, not cart updates.

**No fix needed** (cart is ephemeral, checkout is atomic)

---

## 10. ❌ ALGOLIA RECONCILIATION GAP (DAILY SYNC)

### Current Behavior
- Daily job: compare Firestore vs Algolia
- Re-indexes missing/outdated products

```python
# functions/main.py line 4120
@scheduler_fn.on_schedule(schedule="every day at 02:00")
def reconcile_firestore_algolia(req):
    # Sync all products
```

### Edge Case
**Scenario**: Product deactivated at 3 AM → reconciliation ran at 2 AM → **product visible in Algolia for 23 hours**.

**Risk**: User sees out-of-stock product in search

### Mitigation
1. ✅ Checkout validates stock against Firestore (not Algolia)
2. ✅ Out-of-stock → user gets error (no overselling)

### Additional Safety
```python
# Add on_product_updated trigger (immediate delete)
@firestore_fn.on_document_updated(document="products/{productId}")
def on_product_updated(event):
    if new_data.get('isActive') == False:
        algolia_index.delete_object(product_id)  # Immediate removal
```

**Severity**: LOW (already fixed in Phase 2)  
**Status**: ✅ GOOD (trigger exists)

---

## SUMMARY TABLE

| Edge Case | Severity | Handled? | Fix Required |
|-----------|----------|----------|--------------|
| Product deletion with active orders | MEDIUM | ❌ No | Add pre-delete order check |
| Seller suspension with pending orders | HIGH | ❌ No | Auto-cancel & refund orders |
| Auto-capture failure compensation | MEDIUM | ⚠️ Partial | Cancel after 3 failures, restore stock |
| Dispute after delivery (fraud) | MEDIUM | ⚠️ Partial | Flag buyer, alert admin |
| Shipping approval timeout | LOW | ✅ Yes | Scheduler + fallback |
| Webhook replay attack | LOW | ✅ Yes | Stripe signature verified |
| Rate limiter collision | MEDIUM | ❌ No | Use Firestore transactions |
| Multi-seller partial capture | MEDIUM | ❌ No | Track per-seller captures |
| Session timeout during checkout | LOW | ✅ Yes | Stock reserved atomically |
| Algolia reconciliation gap | LOW | ✅ Yes | Trigger deletes immediately |

---

## PRIORITY FIX LIST

### **URGENT (Phase 4 Week 1)**
1. **Seller suspension with pending orders** → Auto-cancel & refund
2. **Multi-seller partial capture** → Track per-seller captures, refund unshipped

### **HIGH (Phase 4 Week 2)**
3. **Auto-capture failure compensation** → Cancel after 3 failures, restore stock
4. **Rate limiter collision** → Use transactions for atomic increment

### **MEDIUM (Phase 4 Week 3)**
5. **Product deletion with active orders** → Pre-delete order check
6. **Dispute after delivery** → Fraud flagging + admin alerts

### **NICE TO HAVE (Backlog)**
7. Webhook timestamp validation (anti-replay)
8. Shipping approval TTL check in capture_payment (fallback)

---

## TESTING PLAN

### Scenario 1: Seller Suspension with Active Orders
1. Create order (status = confirmed)
2. Admin suspends seller
3. **Expected**: Order auto-cancelled, payment refunded, buyer notified
4. **Actual** (current): Order stuck, seller can't ship

### Scenario 2: Auto-Capture 3x Failure
1. Create order (payment authorized)
2. Simulate Stripe API failure (CardError) 3 times
3. **Expected**: Order cancelled, stock restored, buyer notified
4. **Actual** (current): Logged, but order stuck in `authorized`

### Scenario 3: Multi-Seller Partial Ship
1. Create order with 3 sellers (Seller A, B, C)
2. Seller A ships → captures payment
3. Seller B ships → captures payment
4. Seller C never ships
5. **Expected**: After 7 days, Seller C's portion refunded
6. **Actual** (current): Buyer charged full amount

---

## FIRESTORE RULES GAPS

### Orders Collection
```javascript
// Current: Allow seller to update any order item
// Gap: Seller could update OTHER sellers' items

match /orders/{orderId} {
  allow update: if request.auth != null &&
    // ❌ No check for which items seller can modify
    isOrderSeller(resource.data, request.auth.uid);
}
```

**Fix**:
```javascript
allow update: if request.auth != null &&
  isOrderSeller(resource.data, request.auth.uid) &&
  onlyUpdateOwnItems(resource.data, request.resource.data, request.auth.uid);
```

### Products Collection
```javascript
// Current: Seller can soft-delete anytime
// Gap: No check for active orders

match /products/{productId} {
  allow update: if request.auth != null &&
    request.resource.data.sellerId == request.auth.uid;
    // ❌ No check for active orders
}
```

**Fix**: Enforce via backend function (Firestore rules can't query other collections)

---

## NEXT STEPS

1. **Implement urgent fixes** (seller suspension, multi-seller captures)
2. **Add E2E tests** for all edge cases (see E2E_TEST_IMPLEMENTATION_PLAN.md)
3. **Deploy to staging** + manual testing
4. **Add Sentry alerts** for:
   - Auto-capture failures
   - Dispute losses
   - Rate limit bypasses
5. **Document** all edge case handling in `EDGE_CASES_HANDLED.md`

---

**Last Updated**: 2 février 2026  
**Auditor**: GitHub Copilot  
**Status**: Ready for Phase 4 implementation
