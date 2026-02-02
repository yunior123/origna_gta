# DEEP AUDIT: SECURITY & FRAUD DETECTION
**Date**: January 31, 2025
**Status**: Analysis Complete

---

## OVERVIEW

Comprehensive security audit covering:
- Payment fraud detection
- Rate limiting & brute force prevention
- Seller identity verification
- Customer account security
- API endpoint protection
- Data leakage vectors

---

## 1. PAYMENT AMOUNT VERIFICATION (EXCELLENT)

### Current Implementation
**Location**: `functions/main.py` lines 281-290

```python
# SECURITY: Reject if client price differs from DB price by > 1 cent
if abs(float(client_price) - float(price)) > 0.01:
    print(f"[SECURITY] Price mismatch detected: {client_price} vs {price}")
    raise ValueError(
        f"Price mismatch detected. Please refresh and try again."
    )
```

### Analysis ✅ **EXCELLENT**

**Protection Against**:
- ✅ Client-side price manipulation (browser dev tools)
- ✅ MITM attacks (proxy modifying prices)
- ✅ Fraudulent sellers jacking up shipping costs

**Safeguard**: Server truth, client data NOT trusted

**Why Important**:
```
Attack scenario (BLOCKED):
1. Attacker modifies browser console: 
   cartItems[0].price = 0.01 (instead of $99.99)
2. Sends checkout request with price=$0.01
3. Server checks: DB=$99.99 vs Client=$0.01
4. REJECTS ❌ "Price mismatch"
5. Order fails, attacker blocked
```

**Minor Improvement**: Log to security incident database
```python
if price_mismatch:
    # Log suspicious activity
    log_security_incident({
        'type': 'PRICE_TAMPERING',
        'userId': user_id,
        'productId': product_id,
        'clientPrice': client_price,
        'dbPrice': price,
        'timestamp': datetime.now()
    })
```

---

## 2. IDEMPOTENCY KEY PROTECTION (EXCELLENT)

### Current Implementation
**Location**: `functions/main.py` lines 175-240

```python
stripe_idem_key = f"{user_id}_{order_id}_{int(datetime.now().timestamp())}"

# ... checkout session created with idempotency_key ...
session = stripe.checkout.Session.create(
    idempotency_key=stripe_idem_key,  # ← Prevents duplicate charges
    # ...
)
```

### Analysis ✅ **EXCELLENT**

**Protection Against**:
- ✅ Duplicate order creation (network retry)
- ✅ Double charging (same request resent)
- ✅ API race conditions

**How It Works**:
```
Request 1: idempotencyKey="user123_order456_1709..."
 → Server creates order, returns sessionId
 
Request 2: Same idempotencyKey="user123_order456_1709..."
 → Server recognizes duplicate
 → Returns SAME sessionId (no new order created)
 → Prevents double charge ✅
```

**Why Important**: Stripe guarantees request idempotency

---

## 3. RATE LIMITING (IMPLEMENTED BUT NEEDS REVIEW)

### Current Implementation
**Location**: `functions/rate_limiter.py`

```python
class RateLimiter:
    def is_rate_limited(self, user_id, action, limit, window_seconds):
        # Check if user exceeded action limit in time window
```

### Usage
**Location**: `functions/main.py` (search for rate_limiter)

```python
# Check if user already has pending checkout
if rate_limiter.is_rate_limited(
    user_id=user_id,
    action='create_checkout_session',
    limit=5,  # Max 5 checkouts
    window_seconds=3600  # Per hour
):
    raise https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED,
        message="Too many checkout attempts"
    )
```

### Analysis ⚠️ **NEEDS VERIFICATION**

**Questions**:
1. Is rate limiter used for ALL sensitive endpoints?
2. What actions are rate-limited?
   - Login attempts?
   - Password reset requests?
   - Registration?
   - API calls?

**Recommended Actions**:
- [ ] Audit all endpoints for rate limiting
- [ ] Add login brute force protection (3 fails = 15 min lockout)
- [ ] Add email verification request throttling
- [ ] Add password reset throttling

---

## 4. EMAIL ENUMERATION PREVENTION (GOOD)

### Current Implementation
**Location**: `lib/core/repositories/auth_repository.dart` lines 59-72

```dart
Future<void> sendPasswordResetEmail(String email) async {
    try {
        await _auth.sendPasswordResetEmail(email: trimmedEmail);
    } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
            // SECURITY FIX M-1: Don't expose if email exists
            debugPrint('[SECURITY] Password reset attempted for non-existent email');
            // Don't throw - client sees success either way
            return;
        }
        rethrow;
    }
}
```

### Analysis ✅ **GOOD**

**Protection Against**:
- ✅ Email enumeration attacks
- ✅ Attacker discovering valid user emails
- ✅ Phishing list generation

**How It Works**:
```
Attacker tries 1000 emails:
- email1@example.com → "Success"
- email2@example.com → "Success"
- email3@example.com → "User not found" ← VULNERABILITY!
- ...

With fix:
- email1@example.com → "Success" (unknown)
- email2@example.com → "Success" (unknown)
- email3@example.com → "Success" (still unknown!)
- → Attacker can't distinguish registered vs unregistered
```

---

## 5. SELLER KYC VERIFICATION (CRITICAL GAP)

### Current Implementation
**Location**: `functions/main.py` (search for Stripe Connect)

```python
# When seller onboards:
account = stripe.Account.create(
    type='express',
    country='CA',
    # ... stripe connect details ...
)
seller_doc.update({
    'stripeAccountId': account.id,
    'onboardingCompleted': False,  # ← Only after user completes Stripe
})
```

### Analysis ❌ **INCOMPLETE**

**Issues**:
1. No verification seller identity before payout enabled
2. No check for sanctions lists (OFAC, etc.)
3. No age verification (18+ requirement)
4. No business license validation

### Severity: **CRITICAL** (Money laundering / terrorism financing risk)

### Risk Scenario
```
Attacker creates account:
- Fake name: "John Smith"
- Random Stripe Connect ID
- Gets paid for fraudulent sales
- Immediately initiates payout
- Stripe account flagged, but money already gone
```

### Recommended Fixes

**Tier 1**: Implement basic checks
```python
@https_fn.on_call()
def complete_seller_onboarding(req):
    seller_id = req.auth.uid
    seller_data = req.data  # {id_number, id_type, birthdate, ...}
    
    # Verify against sanctions list (e.g., OFAC)
    if is_sanctioned(seller_data.get('name')):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Account creation not available"
        )
    
    # Verify age >= 18
    birthdate = datetime.fromisoformat(seller_data.get('birthdate'))
    age = (datetime.now() - birthdate).days // 365
    if age < 18:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Seller must be 18+"
        )
    
    # Check Stripe Connect verification status
    stripe_account = stripe.Account.retrieve(seller_data.get('stripeAccountId'))
    if stripe_account.verification.status != 'verified':
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Stripe verification incomplete"
        )
    
    # Enable payouts
    db.collection('users').document(seller_id).update({
        'payoutsEnabled': True,
        'onboardingCompleted': True,
        'kycVerifiedAt': firestore.SERVER_TIMESTAMP,
    })
```

**Tier 2**: Implement sanctions screening (requires API)
```python
import httpx

async def check_sanctions(name: str, country: str) -> bool:
    """Check against OFAC SDN list"""
    response = httpx.get(
        f"https://api.sanctionslist.com/check",
        params={"name": name, "country": country}
    )
    return response.json().get('sanctioned', False)
```

---

## 6. PAYMENT INTENT SECURITY (MEDIUM)

### Issue: Exposed Payment Intent IDs

**Location**: Order documents store `paymentIntentId`

```firestore
// orders/{orderId}
{
  "paymentIntentId": "pi_1234567890abcdef",  // ← Exposed in database
  "amount": 10000,
  ...
}
```

**Risk**: 
- Attacker reads order, gets payment intent ID
- Calls Stripe API: `stripe.PaymentIntent.retrieve("pi_1234567890abcdef")`
- Could potentially modify intent (depends on Stripe permissions)

### Severity: **MEDIUM** (Stripe has good API security, but exposed IDs are risky)

### Mitigation
- ✅ Good: Firestore rules restrict order reading (only buyer/sellers/admin)
- ✅ Good: Stripe API key is server-side only
- ⚠️ Improve: Don't store intent ID in user-readable document (use system collection)

### Recommended Fix
```python
# Instead of:
orders/{orderId}
  - paymentIntentId: "pi_123..."  # ← Exposed

# Do this:
orders/{orderId}
  - (no payment details)

orders_payment_secrets/{orderId}
  - paymentIntentId: "pi_123..."  # Only backend reads
  - accessControl: 'admin'
```

---

## 7. STRIPE WEBHOOK VALIDATION (EXCELLENT)

### Current Implementation
**Location**: `functions/main.py` lines 900-920

```python
@https_fn.on_request()
def stripe_webhook(request):
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')
    
    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=sig_header,
            secret=STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        return {'error': 'Invalid payload'}, 400
    except stripe.error.SignatureVerificationError:
        return {'error': 'Invalid signature'}, 403  # ← CRITICAL CHECK
```

### Analysis ✅ **EXCELLENT**

**Protection Against**:
- ✅ Forged webhook events
- ✅ Attacker fake "payment_intent.succeeded" events
- ✅ Man-in-the-middle attacks

**Why Important**:
```
Without signature verification:
1. Attacker POSTs to webhook: 
   {
     "type": "payment_intent.succeeded",
     "data": {"object": {"id": "pi_xyz", "amount": 10000}}
   }
2. Server processes without validation
3. Order marked as PAID even though payment didn't happen
4. Attacker gets free products ❌

With signature verification:
1. Attacker sends same payload
2. Server verifies: Stripe-Signature header
3. Signature doesn't match STRIPE_WEBHOOK_SECRET
4. REJECTED ✅ "Invalid signature"
```

---

## 8. CUSTOMER ACCOUNT TAKEOVER (LOW RISK)

### Current Implementation
- Firebase Auth handles password hashing
- OAuth available (Google Sign-In)
- No session timeout implemented

### Severity: **MEDIUM** (Session timeout missing)

### Issue: Infinite Session Duration
```
User logs in → Session token valid forever
User leaves computer unattended → Anyone can buy, refund, etc.
```

### Recommended Fix
**Location**: `lib/core/providers.dart` (authentication provider)

```dart
// Add session timeout
final sessionTimeoutProvider = StreamProvider<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);
  
  // Auto-logout after 1 hour of inactivity
  return _inactivityStream().map((_) {
    FirebaseAuth.instance.signOut();
    return false;
  });
});

Stream<void> _inactivityStream() {
  return Rx.merge([
    // Reset timer on any user activity
    HardwareKeyboard.instance.onKeyEvent.map((_) => null),
    Gesture.onTap.map((_) => null),
  ]).debounceTime(Duration(hours: 1));
}
```

---

## 9. ADMIN ACCOUNT SECURITY (CRITICAL)

### Issue: No Multi-Factor Authentication

**Location**: Admin panel is just another user account

```dart
// Anyone with 'admin' role can:
- View all orders
- Process refunds
- Modify user accounts
- Access Stripe Connect accounts
- Delete products
```

**Risk**: If admin password compromised → full platform compromise

### Severity: **CRITICAL**

### Recommended Fix
```python
@https_fn.on_call()
def require_mfa_for_admin(req):
    user_id = req.auth.uid
    user_doc = db.collection('users').document(user_id).get()
    user_data = user_doc.to_dict()
    
    if 'admin' in user_data.get('roles', []):
        # Check if MFA is enabled
        mfa_status = user_data.get('mfaEnabled', False)
        if not mfa_status:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="Admin requires 2FA"
            )
        
        # Verify TOTP token
        mfa_token = req.data.get('mfaToken')
        if not verify_totp(user_id, mfa_token):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="Invalid 2FA code"
            )
```

---

## 10. REFUND AUTHORIZATION (GOOD)

### Current Implementation
**Location**: `functions/main.py` (refund function)

```python
@https_fn.on_call()
def refund_order(req):
    user_id = req.auth.uid
    order_id = req.data.get('orderId')
    
    # Fetch order
    order_doc = db.collection('orders').document(order_id).get()
    order_data = order_doc.to_dict()
    
    # AUTHORIZATION CHECK
    if order_data['userId'] != user_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Unauthorized"
        )
    
    # Additional checks
    if order_data['status'] not in ['delivered', 'confirmed']:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Order cannot be refunded in current state"
        )
```

### Analysis ✅ **GOOD**

**Safeguards**:
- ✅ Only order owner can refund
- ✅ Only certain statuses allow refund
- ✅ Audit trail maintained

---

## SUMMARY TABLE

| Issue | Severity | Status | Fix Required |
|-------|----------|--------|--------------|
| Payment amount validation | CRITICAL | ✅ Good | Add logging |
| Idempotency keys | CRITICAL | ✅ Good | None |
| Rate limiting | HIGH | ⚠️ Partial | Expand coverage |
| Email enumeration | HIGH | ✅ Good | None |
| Seller KYC verification | CRITICAL | ❌ Missing | Implement sanctions check |
| Payment intent exposure | MEDIUM | ⚠️ Risky | Move to secret collection |
| Webhook signature validation | CRITICAL | ✅ Good | None |
| Session timeout | MEDIUM | ❌ Missing | Implement 1-hour timeout |
| Admin MFA | CRITICAL | ❌ Missing | Require 2FA for admin |
| Refund authorization | HIGH | ✅ Good | Add stock restoration |

---

## PRIORITY FIX LIST

### Immediate (Critical Security)
1. **Admin MFA** - Require 2FA for all admin accounts
2. **Seller KYC** - Implement sanctions list check

### This Week (High Security)
3. **Session Timeout** - Auto-logout after 1 hour inactivity
4. **Rate Limiting** - Expand to all sensitive endpoints
5. **Payment Intent Secrets** - Move to admin-only collection

### Nice to Have
6. **Stripe webhook logging** - Log all webhook events for audit

---

## COMPLIANCE NOTES

**PCI DSS (Credit Card Security)**:
- ✅ Stripe handles card processing (we never touch card data)
- ✅ Payment amounts validated server-side
- ✅ Idempotency prevents duplicate charges
- ✅ Webhook signatures verified

**GDPR (Data Privacy)**:
- ⚠️ Need to verify: Customer data deletion on request
- ⚠️ Need to implement: Data export functionality
- ✅ Passwords hashed (Firebase Auth)
- ✅ Email enumeration prevented

**AML/CFT (Anti-Money Laundering)**:
- ❌ No sanctions list check (CRITICAL FIX NEEDED)
- ❌ No suspicious activity monitoring
- ✅ Seller identity verification (via Stripe)

