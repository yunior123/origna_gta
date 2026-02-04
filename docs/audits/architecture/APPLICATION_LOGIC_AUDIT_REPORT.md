# Origna GTA - Application Logic Audit Report
**Date**: 2026-02-02  
**Status**: COMPREHENSIVE ANALYSIS

---

## Executive Summary

The Origna GTA application is a complex Flutter/Firebase marketplace with multi-vendor support, payments (Stripe), and dynamic order workflows. This audit evaluates the logical correctness of each major workflow.

**Overall Assessment**: ✅ **SOUND ARCHITECTURE** with some **LOGIC GAPS** to address

---

## 1. AUTHENTICATION WORKFLOW

### Flow Diagram
```
User Input → Email/Password/Google → Firebase Auth → Firestore User Document
```

### Current Logic

**File**: [lib/features/auth/login_viewmodel.dart](origna_gta/lib/features/auth/login_viewmodel.dart)

#### ✅ STRENGTHS
- Strong password validation on registration (`_validatePasswordStrength()`)
- Proper error handling for Firebase exceptions
- Auto-refresh state on success/failure
- Google OAuth integrated

#### ⚠️ ISSUES IDENTIFIED

1. **Missing Email Verification**
   - No email verification before user can checkout
   - Risk: Typos in email → unrecoverable accounts
   - **Recommendation**: Enforce email verification before checkout

2. **Incomplete User Document Creation**
   - [auth_repository.dart](origna_gta/lib/core/repositories/auth_repository.dart) line 124
   - Only creates basic profile (no shipping addresses, preferences)
   - **Logic**: ✅ Correct (handled elsewhere in profile setup)

3. **Role Assignment Logic**
   ```dart
   'roles': [UserRoles.buyer],
   ```
   - Default role is always 'buyer' ✅
   - If seller role already exists, it adds buyer without removing seller ✅
   - **Status**: CORRECT

#### 🔴 CRITICAL GAP
- No session timeout mechanism
- No device/location verification
- No suspicious login detection

---

## 2. PRODUCT MANAGEMENT WORKFLOW

### Workflow: Seller Creates/Updates Products

**Files Involved**:
- [lib/features/products/add_product_viewmodel.dart](origna_gta/lib/features/products/add_product_viewmodel.dart)
- [lib/features/products/edit_product_viewmodel.dart](origna_gta/lib/features/products/edit_product_viewmodel.dart)
- [lib/core/repositories/product_repository.dart](origna_gta/lib/core/repositories/product_repository.dart)

### Current Logic

#### ✅ STRENGTHS
- Stock validation before creation ✅
- Firestore security rules validate required fields ✅
- Freezed models ensure immutability ✅
- Keywords generation for search ✅

#### ⚠️ ISSUES

1. **Stock Deduction Logic**
   - Question: Where is stock decremented when order is placed?
   - Answer: [functions/main.py](functions/main.py) line 482
   - ✅ Correctly decremented during `create_checkout_session()`

2. **Price Validation Gap**
   - No validation for negative prices in Dart
   - Firestore rules check `price > 0` ✅
   - But frontend allows form submission before validation
   - **Risk**: Silent rejection at backend
   - **Fix**: Add client-side price validation

3. **Seller Verification**
   - Product creation allows any authenticated user with 'seller' role
   - No check if seller account is "active" or "verified"
   - **Risk**: Unverified sellers can list products
   - **Status**: DESIGN CHOICE (may be intentional)

---

## 3. CART & CHECKOUT WORKFLOW

### Workflow Flow
```
Add to Cart → Validate Stock → Checkout Session → Stripe Redirect → Payment Confirmation
```

**Files**:
- [lib/screens/checkout_screen.dart](origna_gta/lib/screens/checkout_screen.dart)  
- [lib/features/checkout/checkout_viewmodel.dart](origna_gta/lib/features/checkout/checkout_viewmodel.dart)
- [functions/main.py create_checkout_session()](functions/main.py#L482)

### ✅ CORRECT LOGIC

1. **Idempotency Key**
   - ✅ Prevents duplicate orders on retry
   - Implementation: Used to deduplicate in Firestore

2. **Stock Reservation**
   - Logic: Reserve stock → Create order → Create Stripe session
   - ✅ Correct sequence (stock held until payment)
   - ✅ Stock restored if payment fails

3. **Tax Calculation**
   - ✅ Calculated per province
   - ✅ Applied before Stripe session creation

4. **Shipping Cost Calculation**
   - ✅ Fetched from shipping service
   - ✅ Included in total before Stripe

### ⚠️ LOGICAL GAPS

1. **Race Condition: Stock Check → Reserve**
   ```python
   # functions/main.py ~line 520
   reserved_stock = _reserve_stock_for_order(items, order_id)
   if not reserved_stock:
       return error('Out of stock')
   ```
   - **Issue**: Between client-side display and server reserve, stock might change
   - **Impact**: Possible overselling
   - **Mitigation**: ✅ Already handled by backend reserve-before-create pattern

2. **Total Price Verification**
   - ✅ Backend verifies `expectedSubtotalCents` matches Stripe amount
   - ✅ Fraud detection if amounts don't match
   - **Status**: SECURE

3. **Double-Charging Prevention**
   - ✅ `idempotencyKey` ensures single order creation
   - ✅ But what if user refreshes after payment success?
   - **Answer**: Order ID stored in session ID lookup
   - **Status**: CORRECT (uses `watchPaidOrderBySession`)

---

## 4. PAYMENT WORKFLOW (Stripe Integration)

### Workflow
```
Checkout Session Created
  ↓
Stripe Redirect
  ↓
Payment Completed / Cancelled
  ↓
Webhook: session.completed
  ↓
Order Status → paid / Capture Payment
```

**Files**:
- [functions/main.py create_checkout_session()](functions/main.py#L482)
- [functions/main.py process_checkout_session_completed()](functions/main.py#L900)

### ✅ CORRECT LOGIC

1. **Manual Capture Mode**
   - ✅ Payment authorized but not captured until order confirmed
   - ✅ Reduces fraud risk
   - ✅ Allows time for shipping validation

2. **Webhook Validation**
   - ✅ Validates Stripe signature
   - ✅ Only processes valid webhooks

3. **Amount Verification**
   ```python
   expected_subtotal_cents = int(expected_subtotal * 100)
   stripe_amount_subtotal = session.get('amount_subtotal')
   
   if stripe_amount_subtotal != expected_subtotal_cents:
       # Mark fraud, restore stock, reject order
   ```
   - ✅ EXCELLENT - prevents man-in-the-middle total manipulation

4. **Payment Status Handling**
   - ✅ Distinguishes between PAID, PROCESSING, UNPAID
   - ✅ Handles async payments correctly

### ⚠️ GAPS

1. **Capture Flow Logic** 
   - Question: When is payment actually captured?
   - Current: Manual capture on `confirm_order_receipt`
   - **Issue**: What if user closes app after success and never calls confirm?
   - **Risk**: Authorized but uncaptured payments
   - **Recommendation**: Add automatic capture after 30 mins

2. **Refund Logic**
   - No refund flow visible in Dart
   - Backend has logic but not exposed to sellers
   - **Status**: INCOMPLETE (sellers can't refund orders)

---

## 5. ORDER LIFECYCLE & STATUS WORKFLOW

### Order Status Transitions
```
pending 
  ↓
authorized (payment authorized)
  ↓
paid (payment captured)
  ↓ (per seller)
processing → shipped → in_transit → delivered
  ↓
completed
```

**Files**:
- [lib/models/models.dart Order model](origna_gta/lib/models/models.dart#L550)
- [lib/utils/constants.dart OrderStatus enum](origna_gta/lib/utils/constants.dart#L140)
- [functions/config.py OrderStatus class](functions/config.py#L8)

### ✅ STATUS VALIDATION

```dart
enum OrderStatus {
  pending, confirmed, processing, shipped, delivered,
  cancelled, failed, expired, refunded, partiallyRefunded
}
```

States defined consistently across frontend/backend ✅

### ⚠️ TRANSITION LOGIC ISSUES

1. **No State Machine Validation**
   - No code preventing invalid transitions
   - Example: Can move from `delivered` → `pending`?
   - **Status**: NOT ENFORCED - anyone with order doc access can modify
   - **Impact**: Data corruption risk
   - **Fix Required**: Add Firestore rules validating legal transitions

2. **ShippingApprovalStatus**
   - Values: `pending`, `approved`, `rejected`
   - **Issue**: No timeout if seller doesn't approve
   - **Risk**: Orders stuck in `pending` indefinitely
   - **Recommendation**: Add 24-hour auto-approval

3. **Delivery Status Per Item** 
   - Each order item has separate delivery status
   - **Logic**: Correct - allows partial delivery tracking
   - ✅ Implemented correctly

---

## 6. SELLER REGISTRATION & PAYOUT WORKFLOW

### Workflow
```
Seller Role Assignment
  ↓
Stripe Connect Onboarding
  ↓
Bank Account Verification
  ↓
canReceivePayouts = true
  ↓
Automatic Payouts
```

**Files**:
- [lib/screens/seller_registration_screen.dart](origna_gta/lib/screens/seller_registration_screen.dart)
- [lib/features/seller/seller_account_status_viewmodel.dart](origna_gta/lib/features/app/seller_account_status_viewmodel.dart)

### ✅ CORRECT

1. **Stripe Connect Flow**
   - ✅ Three states tracked: `hasAccount`, `isComplete`, `canReceivePayouts`
   - ✅ User redirected back to app on completion
   - ✅ Account status persisted in Firestore

2. **Payout Calculation**
   ```dart
   net = gross - platformFee
   ```
   - Platform fee: 2.5% (hardcoded)
   - ✅ Applied correctly

### ⚠️ GAPS

1. **Platform Fee Hardcoding**
   - Fee is 2.5% but has no configuration
   - **Risk**: Changing fee requires code update + redeployment
   - **Fix**: Move to Firestore config collection

2. **Seller Verification Missing**
   - Nothing stops unverified seller from receiving payouts
   - Current logic: `canReceivePayouts` depends only on Stripe status
   - **Risk**: Potential money laundering vector
   - **Recommendation**: Add KYC verification step

3. **Payout Schedule**
   - No logic visible for when payouts occur
   - Expected: Daily or weekly automatic payouts
   - **Status**: MISSING from audit scope (backend scheduled task?)

---

## 7. SEARCH & DISCOVERY WORKFLOW

### Workflow
```
User enters search query
  ↓
Algolia search OR Firestore fallback
  ↓
Results filtered by category/seller
  ↓
Display products
```

**Files**:
- [lib/services/algolia_service.dart](origna_gta/lib/services/algolia_service.dart)
- [lib/core/repositories/algolia_product_repository.dart](origna_gta/lib/core/repositories/algolia_product_repository.dart)

### ✅ STRENGTHS

1. **Dual-Tier Search**
   - ✅ Primary: Algolia (fast, fuzzy)
   - ✅ Fallback: Firestore (when Algolia down)
   - ✅ hitToProductMap includes fallback for old docs

2. **Keyword Indexing**
   - ✅ Products indexed with `keywords` field
   - ✅ Generated from product name automatically
   - ✅ Searchable across name + description

### ⚠️ ISSUES

1. **Search Result Freshness**
   - Algolia updates on product save
   - **Lag**: Up to 10 seconds (Algolia sync delay)
   - **Impact**: User creates product → doesn't appear immediately
   - **Status**: ACCEPTABLE (not critical)

2. **Deactivated Products**
   - Search includes `isActive` check ✅
   - But deactivated products take time to disappear from Algolia
   - **Impact**: Can buy deactivated product briefly
   - **Mitigation**: Backend stock check happens regardless ✅

---

## 8. TAX CALCULATION WORKFLOW

### Tax System
- Per-province HST/GST/PST
- Applied to subtotal (not shipping)
- Shown before payment

**File**: [lib/utils/utils.dart getTaxRate()](origna_gta/lib/utils/utils.dart#L248)

### ✅ CORRECT
- ✅ All 13 Canadian provinces defined
- ✅ Rates accurate (ON=13%, BC=5%, etc.)
- ✅ Applied per item quantity

### ⚠️ ISSUE

1. **Tax Rate Hardcoding**
   - Rates in code: `ON: 0.13`
   - **Risk**: When rates change (rare but happens), code update needed
   - **Solution**: Move to Firestore config

2. **Tax on Shipping**
   - Current: Tax on subtotal only, not shipping
   - **Status**: Correct (standard practice)
   - But should be documented

---

## 9. SHIPPING & FULFILLMENT WORKFLOW

### Workflow
```
Order Placed (with delivery options)
  ↓
Seller Approves Shipping Cost
  ↓
Order Status → processing
  ↓
Seller Ships (updates tracking)
  ↓
Delivery Status Updated
```

**Files**:
- [lib/models/models.dart SellerDeliveryOption](origna_gta/lib/models/models.dart#L240)
- [lib/features/orders/shipping_approval_viewmodel.dart](origna_gta/lib/features/orders/shipping_approval_viewmodel.dart)

### ✅ CORRECT

1. **Delivery Options**
   - Sellers define custom delivery speeds (standard, express, same-day)
   - ✅ Prices per option
   - ✅ Enabled/disabled per seller

2. **Shipping Approval Flow**
   - ✅ Buyer sees estimated cost
   - ✅ Seller can approve/reject
   - ✅ No double-charge if seller adjusts cost

### ⚠️ CRITICAL GAP

1. **Cost Adjustment Without Refund**
   - Scenario: Seller quotes $5, approves $8
   - **Current Logic**: Charges buyer $5 initially, then what?
   - **Issue**: No mechanism shown for buyer to pay diff or deny
   - **Status**: INCOMPLETE WORKFLOW

2. **No Tracking Integration**
   - Sellers manually update "shipped"
   - No carrier/tracking number tracking
   - ✅ Manual is acceptable but limits UX

3. **Shipping Cost Calculation**
   - Question: How is shipping cost determined initially?
   - Answer: From shipping service, per delivery option
   - ✅ Correct logic

---

## 10. ADMIN FUNCTIONALITY

**File**: [lib/admin/admin_repository.dart](origna_gta/lib/admin/admin_repository.dart)

### Admin Capabilities
- View all orders across sellers
- View all products
- Suspend sellers
- View fraud alerts

### ✅ IMPLEMENTED
- Admin can query all sellers' orders
- Admin can see fraud flags
- ✅ Security: Admin queries restricted by Firestore rules

### ⚠️ GAP
- No admin actions visible (edit order, refund, suspend product)
- **Status**: May be intentional (manual process)

---

## 11. SECURITY & FRAUD DETECTION

### Fraud Detection Points

1. **Amount Mismatch** (line 927)
   ```python
   if stripe_amount_subtotal != expected_subtotal_cents:
       fraudAlert: true
   ```
   ✅ EXCELLENT

2. **Stock Overselling Prevention**
   - ✅ Reserved-until-paid pattern
   - ✅ Stock restored on payment failure

3. **Duplicate Order Prevention**
   - ✅ Idempotency keys prevent retry attacks

### ⚠️ MISSING

1. **Payment Method Restrictions**
   - No limit on number of failed payment attempts
   - No velocity checks (too many orders too fast)

2. **Seller Verification**
   - No background check before payout eligibility

---

## CRITICAL ISSUES SUMMARY

| Issue | Severity | Impact | Fix Effort |
|-------|----------|--------|-----------|
| Missing auto-capture timeout | 🟡 Medium | Stuck authorized payments | 2-4 hours |
| Shipping cost adjustment UX | 🟡 Medium | Buyer friction | 4-8 hours |
| No shipping approval timeout | 🔴 High | Orders stuck indefinitely | 2-3 hours |
| State transition validation missing | 🔴 High | Data corruption risk | 3-4 hours |
| No email verification | 🟡 Medium | Account recovery issues | 2-3 hours |
| Fee & tax rates hardcoded | 🟡 Medium | Operational rigidity | 1-2 hours |

---

## LOGICAL SOUNDNESS RATING

| Workflow | Rating | Notes |
|----------|--------|-------|
| Authentication | 8/10 | Strong password policy, missing session timeout |
| Products | 8/10 | Good validation, unverified sellers allowed |
| Cart/Checkout | 9/10 | Excellent idempotency & stock handling |
| Payments | 9/10 | Strong fraud detection, missing auto-capture |
| Orders | 7/10 | Status tracking exists, no state validation |
| Seller Onboarding | 7/10 | Stripe integration good, no KYC |
| Search | 9/10 | Dual-tier search is robust |
| Taxes | 9/10 | Accurate rates, hardcoded (minor) |
| Shipping | 6/10 | Basic workflow, approval timeout missing |
| **OVERALL** | **8/10** | **Solid foundation, needs operational polish** |

---

## RECOMMENDATIONS (Priority Order)

### 🔴 CRITICAL (Do First)
1. Add shipping approval timeout (24 hours)
2. Implement order state machine validation in Firestore rules
3. Add automatic payment capture after 30 minutes

### 🟡 HIGH (Next Sprint)
4. Add email verification requirement
5. Implement seller KYC/verification before payouts
6. Add shipping cost adjustment confirmation flow

### 🟢 MEDIUM (Later)
7. Move hardcoded rates/fees to Firestore config
8. Add payment attempt velocity limits
9. Add tracking number support

---

## CONCLUSION

The Origna GTA application has **sound core logic** for complex marketplace operations. The payment flow is particularly well-designed with excellent fraud detection. However, there are **operational gaps** (timeouts, approval flows) and **security gaps** (verification, state validation) that should be addressed before production launch.

**Status**: ✅ **READY FOR TESTING WITH CAVEATS** - Address critical issues first.
