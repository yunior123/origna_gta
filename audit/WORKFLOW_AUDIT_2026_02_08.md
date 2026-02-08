# Workflow Audit Report — OrignaGta
**Date:** 2026-02-08  
**Auditor:** Claude Code (Deep Analysis)  
**Scope:** All major workflows (Payment, Orders, Products, Auth, Cron, Shipping)  
**Status:** 30+ adversarial scenarios created, fixes proposed

---

## Executive Summary

The codebase shows **strong security foundations** (server-side price validation, atomic transactions, rate limiting) but has **several edge cases and race conditions** that could cause:
- Double-spending or double-capture scenarios
- Stock inconsistencies under high concurrency
- UI state drift in Add Product flow
- Incomplete order transitions during cron job execution

---

## 🎯 Critical Findings (Fix Immediately)

### 1. Add Product: Disconnected Inventory State Fields
**Location:** `add_product_screen.dart` local variables `_inventoryManaged`, `_trackQuantity`, `_allowBackorder`  
**Issue:** These local state variables are NOT connected to the ViewModel or persisted to Firestore. The UI allows toggling them but they have no effect.

**Adversarial Scenario:**
- Seller enables "Track Quantity" → enters stock quantity → submits
- Product created with `inventory` object missing `trackQuantity: true`
- Seller's inventory settings are silently discarded
- Potential for overselling when stock goes negative

**Fix:**
```dart
// In add_product_viewmodel.dart, add to ProductCreate:
inventory: models.InventoryConfig(
  managed: state.inventoryManaged,
  trackQuantity: state.trackQuantity,
  allowBackorders: state.allowBackorders,
  lowStockThreshold: state.lowStockThreshold,
),
```

---

### 2. Add Product: Missing Apartment Field UI
**Location:** `add_product_screen.dart`  
**Issue:** `_apartmentController` is declared but NO UI field renders for apartment input. The value is collected but never shown to the user.

**Adversarial Scenario:**
- Seller tries to specify unit/suite number for pickup address
- No input field visible → seller thinks it's not needed
- Product saved with `apartment: ""` even if seller intended to provide one
- Delivery failures due to incomplete address

**Fix:** Add TextField with `_apartmentController` in the Address section.

---

### 3. Add Product: Discount Tier Validation Missing
**Location:** `add_product_screen.dart` delivery options  
**Issue:** UI allows setting 3+ items = 50% off, 5+ items = 20% off (lower discount for higher quantity).

**Adversarial Scenario:**
- Seller accidentally sets decreasing discount tiers
- Buyer orders 5 items → gets 20% off instead of expected 50%
- Customer complaints, refunds required

**Fix:**
```dart
bool _validateDiscountTiers(List<DiscountTier> tiers) {
  for (int i = 1; i < tiers.length; i++) {
    if (tiers[i].discountValue < tiers[i-1].discountValue) {
      return false; // Later tier must have >= discount
    }
  }
  return true;
}
```

---

### 4. Shipping Cost Approval Race Condition
**Location:** `orders.py:approve_shipping_cost()`  
**Issue:** Authorization expiry check uses naive comparison without timezone handling consistently.

**Adversarial Scenario:**
1. Order created at 2026-01-01 00:00 UTC
2. Expires at 2026-01-08 00:00 UTC
3. Cron job `check_expired_authorizations` runs at 23:59:59
4. Buyer calls `approve_shipping_cost` at 00:00:01 (1 second after expiry)
5. Buyer approval succeeds, updates payment intent
6. Cron cancels order 1 second later
7. **State inconsistency:** Order approved but then cancelled, buyer charged for cancelled order

**Fix:** Use transaction-based locking in `approve_shipping_cost`:
```python
@firestore.transactional
def approve_with_lock(transaction):
    fresh = order_ref.get(transaction=transaction)
    if fresh.get('paymentStatus') != 'authorized':
        raise Error("Order no longer authorized")
    # ... proceed with approval
```

---

### 5. Stock Double-Restore on Cancel + Expire Race
**Location:** `orders.py:cancel_order()` and `cron_jobs.py:check_expired_authorizations()`  
**Issue:** Both functions check `stockRestored` flag, but the check-read-update is not atomic across functions.

**Adversarial Scenario:**
1. Order expires, cron job starts processing
2. Seller manually cancels order at the same moment
3. Both see `stockRestored: false`
4. Both restore stock → **double inventory increase**
5. Product shows 10 available when only 5 actually exist

**Fix:** Use Firestore transaction with `Increment` for stock restoration:
```python
# Already partially fixed with Increment, but add deduplication:
if not order_data.get('stockRestored'):
    # Use transaction to set flag AND restore stock atomically
    transaction.update(order_ref, {'stockRestored': True})
    for item in items:
        transaction.update(product_ref, {
            'stockQuantity': firestore.Increment(item['quantity'])
        })
```

---

### 6. Cart Screen: Plus Button Rebuilds Unnecessary Widgets
**Location:** `cart_screen.dart`  
**Issue:** Animation on quantity change triggers rebuild of entire cart item card instead of just the quantity display.

**Adversarial Scenario:**
- Buyer has 20 items in cart
- Taps + on item #1
- All 20 items' images and details rebuild
- Performance degradation, janky UI on low-end devices

**Fix:** Extract quantity selector to `const` widget with `const` constructor, use `ValueKey` properly.

---

## 🔥 30+ Adversarial Scenarios

### Payment & Checkout Scenarios

| # | Scenario | Attack Vector | Current Protection | Gap |
|---|----------|---------------|-------------------|-----|
| 1 | **Price Tampering** | Modify client-side price before checkout | Server validates against DB | ✅ Good |
| 2 | **Seller ID Swap** | Send `sellerId` that doesn't match product owner | Cross-validated with DB | ✅ Good |
| 3 | **Self-Purchase** | Buy own product to game ratings | Blocked in `create_checkout_session` | ✅ Good |
| 4 | **Double Checkout** | Retry checkout with same idempotency window | 60-second duplicate detection | ⚠️ Window too short? |
| 5 | **Stock Race** | Two buyers buy last item simultaneously | Atomic transaction used | ✅ Good |
| 6 | **Quantity Overflow** | Send `quantity: 999999` | Max 100 validation | ✅ Good |
| 7 | **Negative Quantity** | Send `quantity: -1` | Positive integer check | ✅ Good |
| 8 | **Address Injection** | 500-char street address | 100-char limit enforced | ✅ Good |
| 9 | **Shipping Bypass** | Remove shipping line item | Server recalculates | ✅ Good |
| 10 | **Tax Manipulation** | Modify tax amount | Server recalculates | ✅ Good |
| 11 | **Webhook Replay** | Replay old webhook event | 5-minute staleness check | ✅ Good |
| 12 | **Webhook Flood** | DDoS webhook endpoint | IP rate limiting 100/min | ✅ Good |
| 13 | **Capture During Cancel** | Cancel order while capture in progress | `capturing` lock state | ✅ Good |
| 14 | **Cancel During Capture** | Capture order while cancel in progress | `cancelling` lock state | ✅ Good |
| 15 | **Multi-Seller Capture** | Capture payment for seller A, funds go to seller B | `sellerStripeAccounts` snapshot | ✅ Good |

### Order Lifecycle Scenarios

| # | Scenario | Attack Vector | Current Protection | Gap |
|---|----------|---------------|-------------------|-----|
| 16 | **Fake Delivery** | Seller marks delivered without shipping | Only buyer confirm sets DELIVERED | ✅ Good |
| 17 | **Auto-Capture on Dispute** | Cron captures disputed order | Dispute check in auto-capture | ✅ Good |
| 18 | **Archived Order Update** | Try to update archived order | Blocked with check | ✅ Good |
| 19 | **Suspension Bypass** | Complete orders after seller suspended | Orders cancelled on suspend | ✅ Good |
| 20 | **State Machine Bypass** | Jump from pending → delivered | Validated in `is_valid_order_status_transition` | ✅ Good |
| 21 | **Partial Refund Loop** | Refund same item multiple times | Item status set to REFUNDED | ✅ Good |
| 22 | **Shipping Approval Bypass** | Ship without buyer approval | Blocked if approval pending | ✅ Good |
| 23 | **Expired Auth Capture** | Capture 8-day-old authorization | 7-day expiry enforced | ✅ Good |
| 24 | **Rate Limit Bypass** | Distributed requests from many IPs | Per-user rate limiting | ⚠️ Could add IP-level? |

### Product & Inventory Scenarios

| # | Scenario | Attack Vector | Current Protection | Gap |
|---|----------|---------------|-------------------|-----|
| 25 | **Digital Product Shipping** | Digital product shows shipping options | UI forces `freeShipping: true` | ⚠️ Toggle still visible |
| 26 | **Inventory Mismatch** | Stock quantity negative | Not validated on product update | 🔴 **GAP** |
| 27 | **Concurrent Edit** | Two admins edit same product | No optimistic locking | 🔴 **GAP** |
| 28 | **Image URL Injection** | Set `imageUrl` to malicious domain | URLs validated on upload | ✅ Good |
| 29 | **Category Spoofing** | Set invalid categoryId | Validated against enum | ✅ Good |
| 30 | **Local Delivery Bypass** | Order local-only from different province | Blocked in shipping calculation | ✅ Good |

### Auth & Admin Scenarios

| # | Scenario | Attack Vector | Current Protection | Gap |
|---|----------|---------------|-------------------|-----|
| 31 | **MFA Brute Force** | Try 1000 MFA codes | 5-attempt lockout | ✅ Good |
| 32 | **Role Escalation** | Make self admin | Requires existing admin + MFA | ✅ Good |
| 33 | **Account Deletion with Pending** | Delete account while order pending | Blocked, checks pending orders | ✅ Good |
| 34 | **MFA Timing Attack** | Measure response time to guess code | Constant-time response (100ms min) | ✅ Good |
| 35 | **Backup Code Reuse** | Use same backup code twice | Hashed and removed after use | ⚠️ Check implementation |

---

## 📋 Proposed Fixes (Non-Destructive)

### Fix 1: Inventory State Connection
**File:** `origna_gta/lib/features/products/add_product_viewmodel.dart`
```dart
// Add these parameters to addProduct() call:
inventory: models.InventoryConfig(
  managed: true,  // Or from state if UI connected
  trackQuantity: state.trackQuantity,  // Connect to ViewModel state
  allowBackorders: state.allowBackorders,
  lowStockThreshold: 5,
),
```

### Fix 2: Add Apartment Field UI
**File:** `origna_gta/lib/screens/addproduct_screen.dart`
```dart
TextField(
  controller: _apartmentController,
  decoration: InputDecoration(
    labelText: 'Apartment/Unit (Optional)',
    hintText: 'e.g., Suite 100',
  ),
),
```

### Fix 3: Discount Tier Validation
**File:** `origna_gta/lib/screens/addproduct_screen.dart` (or ViewModel)
```dart
void _validateDeliveryOptions() {
  final tiers = deliveryOptions.expand((o) => o.quantityDiscounts).toList()
    ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
  
  for (int i = 1; i < tiers.length; i++) {
    if (tiers[i].discountValue < tiers[i-1].discountValue) {
      throw ValidationError(
        'Discount for ${tiers[i].minQuantity}+ items must be ≥ ${tiers[i-1].discountValue}%'
      );
    }
  }
}
```

### Fix 4: Hide Free Shipping Toggle for Digital Products
**File:** `origna_gta/lib/screens/addproduct_screen.dart`
```dart
// Wrap in conditional:
if (!state.isDigital) ...[
  SwitchListTile(
    title: Text('Free Shipping'),
    value: state.freeShipping,
    onChanged: (v) => viewModel.toggleFreeShipping(v),
  ),
],
```

### Fix 5: Cart Screen Performance
**File:** `origna_gta/lib/screens/cart_screen.dart`
```dart
// Extract quantity selector to StatefulWidget:
class QuantitySelector extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  
  const QuantitySelector({
    required this.quantity,
    required this.onChanged,
    Key? key,
  }) : super(key: key);
  
  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}
```

### Fix 6: Stock Validation on Product Update
**File:** `functions/handlers/products.py`
```python
def validate_product_data(data: dict) -> tuple[bool, str]:
    """Validate product before create/update."""
    stock = data.get('stockQuantity', 0)
    if stock < 0:
        return False, "Stock quantity cannot be negative"
    
    # Check inventory config consistency
    inventory = data.get('inventory', {})
    if inventory.get('managed', False):
        if inventory.get('trackQuantity', False) and stock < 0:
            return False, "Tracked inventory cannot be negative"
        if not inventory.get('allowBackorders', False) and stock < 1:
            return False, "Non-backorder products must have positive stock"
    
    return True, ""
```

### Fix 7: Optimistic Locking for Product Edit
**File:** `functions/handlers/products.py`
```python
@firestore.transactional
def update_product_atomic(transaction, product_ref, updates, expected_version):
    """Update product only if version matches (optimistic locking)."""
    snapshot = product_ref.get(transaction=transaction)
    if not snapshot.exists:
        raise NotFound("Product not found")
    
    current_version = snapshot.to_dict().get('version', 0)
    if current_version != expected_version:
        raise Conflict("Product was modified by another user. Please refresh.")
    
    updates['version'] = current_version + 1
    transaction.update(product_ref, updates)
```

---

## 🧪 Recommended Additional Tests

### Backend Tests (pytest)
```python
# tests/test_inventory_edge_cases.py
def test_negative_stock_rejected():
    """Product update with negative stock should fail."""
    
def test_concurrent_cancel_and_expire():
    """Simulate race between cancel_order and check_expired_authorizations."""
    
def test_discount_tier_validation():
    """Discount tiers must be monotonically increasing."""
    
def test_shipping_approval_after_expiry():
    """Approval should fail if authorization expired during request."""
```

### Frontend Tests (Flutter)
```dart
// test/add_product_inventory_test.dart
test('inventory state is persisted to Firestore', () async {
  // Toggle track quantity, submit product, verify inventory object
});

test('discount tiers are validated', () {
  // Set 3+ = 50%, 5+ = 20%, expect validation error
});
```

---

## 🎯 Priority Matrix

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | Inventory state not connected | 2h | High (overselling risk) |
| P0 | Apartment field missing | 1h | Medium (delivery failures) |
| P1 | Discount tier validation | 2h | Medium (customer complaints) |
| P1 | Hide free shipping for digital | 30m | Low (UI confusion) |
| P2 | Cart performance | 3h | Medium (UX) |
| P2 | Stock validation | 2h | Low (defense in depth) |
| P3 | Optimistic locking | 4h | Low (rare race condition) |

---

## ✅ Verification Checklist

- [ ] Add product with inventory settings → verify in Firestore
- [ ] Add product with apartment → verify UI field exists
- [ ] Set invalid discount tiers → verify validation error
- [ ] Digital product → verify free shipping toggle hidden
- [ ] Concurrent cancel + expire → verify single stock restore
- [ ] Capture during cancel → verify proper locking
- [ ] Cart quantity change → verify minimal rebuilds

---

**Report Generated:** 2026-02-08 07:54 UTC  
**Next Review:** After fixes implemented
