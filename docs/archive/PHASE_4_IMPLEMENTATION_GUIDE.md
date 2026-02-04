# Phase 4 Complete Implementation Guide

## PART 1: DIGITAL PRODUCTS (NO SHIPPING)

### What Needs to Change

#### Frontend Changes
1. **Product creation form** - Add "Digital Product" toggle
   - Location: `lib/features/seller/add_product_screen.dart`
   - When ON: Hide shipping fields, set shippingRequired = false
   
2. **Checkout screen** - Skip shipping section for digital products
   - Location: `lib/screens/checkout_screen.dart`
   - Check: `product.shippingRequired` before showing address/shipping fields

3. **Order confirmation** - No tracking number for digital products
   - Location: `lib/screens/order_success_screen.dart`
   - Show: "Instant download" or instant availability message

#### Backend Changes
1. **Product model** - Add field
   ```json
   "shippingRequired": false  // boolean
   ```

2. **Order model** - Make shipping optional
   ```json
   "shipping": {
     "required": false,
     "address": null,  // optional for digital
     "method": null,
     "cost": 0,
     "trackingNumber": null
   }
   ```

3. **Checkout function** - Skip shipping calculation for digital
4. **Shipping approval** - Auto-complete for digital products (no manual approval needed)

#### Database Schema Updates
- `products` collection: Add `shippingRequired` boolean field
- `orders` collection: Make shipping address optional
- Firestore rules: Allow orders without shipping address if digital product

#### Tests Needed
- Create digital product, verify shipping fields hidden
- Checkout digital product, skip shipping section
- Order confirmation shows "instant download"
- Shipping approval auto-completes for digital products

---

## PART 2: AUTH FLOWS AUDIT

### Flows to Verify

#### 1. **Sign Up Flow**
- Path: `lib/screens/signup_screen.dart` → Firebase Auth
- Check:
  - Email validation (Canada domain enforcement? No, allow all)
  - Password strength (min 8 chars, 1 number, 1 special char?)
  - Email verification email sent
  - User document created in Firestore with role='buyer'
  - Session timeout logic working

#### 2. **Email Verification**
- Path: `lib/screens/email_verification_screen.dart`
- Check:
  - Deep link from email opens verification
  - Resend verification email (rate limited?)
  - User can use app after verification (or enforce before?)

#### 3. **Sign In Flow**
- Path: `lib/screens/login_screen.dart`
- Check:
  - Rate limiting on failed attempts (5 attempts → 15min lockout)
  - "Remember me" functionality (safe?)
  - 2FA for sellers? (Currently no, add to Phase 4.5)

#### 4. **Forgot Password**
- Path: `lib/screens/forgot_password_screen.dart`
- Check:
  - Reset email sent securely
  - Reset link works and expires after 1 hour
  - New password validation same as signup

#### 5. **Sign Out Flow**
- Path: Anywhere with logout button
- Check:
  - Session cleared from Firebase
  - Local cache cleared
  - Return to login screen
  - Refresh tokens invalidated

#### 6. **Session Timeout**
- Location: `lib/services/session_timeout_service.dart`
- Check:
  - Timeout after 30 minutes of inactivity
  - User redirected to login
  - Unsaved data warning?

### Implementation Notes
- All sensitive endpoints must use HTTPS
- Passwords never logged or stored plaintext
- Session tokens should rotate on sensitive actions
- Rate limiting on auth endpoints (10 req/min per IP)

---

## PART 3: SELLER APPROVAL & SUSPENSION GATES

### Seller States
```
STATES:
1. "pending_approval" - After registration, before admin approval
2. "approved" - Can add products and operate
3. "suspended" - Cannot do anything (bad payment history, fraud, etc)
4. "rejected" - Registration rejected, cannot reapply for 30 days
```

### Gates to Implement

#### 1. **Product Addition Gate**
- **File**: `lib/features/seller/add_product_screen.dart`
- **Check**: 
  ```dart
  if (seller.status != 'approved') {
    showDialog("Your account must be approved to add products");
    return;
  }
  ```
- **Backend**: Also validate in Cloud Function `create_product`

#### 2. **Seller Dashboard Gate**
- **File**: `lib/screens/seller_dashboard_screen.dart`
- **Check**:
  ```dart
  if (seller.status == 'suspended') {
    showDialog("Your account is suspended. Contact support.");
    return HomePage();
  }
  ```

#### 3. **Seller Orders Gate**
- **File**: `lib/screens/seller_orders_screen.dart`
- **Check**: Same as dashboard

#### 4. **Seller Registration Gate**
- **File**: `lib/screens/seller_registration_screen.dart`
- **Check**: Don't allow re-entry if already registered

### Backend Implementation

#### Firestore Rules
```javascript
// Only approved sellers can create products
allow create: if request.auth.uid != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.sellerStatus == 'approved';

// Only non-suspended sellers can update orders
allow update: if request.auth.uid != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.sellerStatus != 'suspended';
```

#### Cloud Functions
- `create_product`: Validate seller.status == 'approved'
- `update_order_status`: Validate seller not suspended
- `create_payout_account`: Validate seller.status != 'suspended'

---

## PART 4: KYC API INTEGRATION

### Decision: Which KYC API?

#### **ComplyAdvantage**
**Pros:**
- Best for Canada compliance
- Sanctions screening + identity verification combined
- Real-time API responses (< 1 sec)
- Pricing: $0.50-2.00 per check

**Cons:**
- Can be slower during bulk checks
- Requires manual review for some cases

**Recommendation:** ✅ **CHOOSE THIS** - Best balance for Canadian marketplace

#### **Trulioo**
**Pros:**
- Global coverage (100+ countries)
- Good for international sellers
- Fast API (< 2 sec)

**Cons:**
- More expensive ($1-5 per check)
- Overkill for Canada-only marketplace
- Setup more complex

**Recommendation:** ❌ Skip for now, add for future international expansion

#### **Onfido**
**Pros:**
- Best document verification (passport, ID)
- Video-based liveness checks available
- Good UX

**Cons:**
- Most expensive ($3-8 per check)
- Overkill for simple seller vetting
- Slower (2-5 sec response time)

**Recommendation:** ❌ Use only if you need video verification (not needed yet)

### Implementation Plan: ComplyAdvantage

#### Backend Setup
1. **Create account at https://www.complyadvantage.com**
   - Get API key from dashboard
   - Setup webhook for verification completion
   - Enable: Sanctions screening + PEP list

2. **Add to backend environment**
   ```python
   COMPLY_ADVANTAGE_API_KEY = "your_api_key"
   COMPLY_ADVANTAGE_BASE_URL = "https://api.complyadvantage.com/v1"
   ```

3. **Create KYC Cloud Function** (`kyc_verify_seller`)
   ```python
   def kyc_verify_seller(seller_id, seller_data):
       # Call ComplyAdvantage API
       # Save result to Firestore
       # Update seller.kycStatus
       # Send email if approved/rejected
   ```

#### Frontend Integration
- **Seller registration flow**: After basic info → KYC check
- **Show status**: "Verifying identity..." → "Approved/Rejected"
- **Handle rejection**: Show reason, allow resubmit after 7 days

#### Database Schema
```javascript
// users collection
"kycStatus": "pending" | "approved" | "rejected",
"kycCheckId": "string",  // ComplyAdvantage check ID
"kycRiskLevel": "low" | "medium" | "high",
"kycRejectionReason": "string",
"kycLastCheckDate": timestamp,
"kycNextAllowedResubmit": timestamp  // 7 days after rejection
```

#### Testing
- Mock ComplyAdvantage API responses
- Test with sandbox account
- Test rejection scenarios and retry logic

---

## PART 5: AIRWALLEX INTEGRATION (CHINA SELLERS)

### Airwallex Account Setup (MANDATORY CHECKLIST)

#### Step 1: Create Account
1. Go to https://www.airwallex.com/business
2. Sign up with business email (you@orignaventures.ca)
3. Company: OrignaGta Inc
4. Country: Canada
5. Business type: Marketplace/Payment Platform

#### Step 2: Complete Business Verification (KYC)
1. Upload company registration documents (Articles of Incorporation)
2. Upload proof of address (utility bill, lease)
3. Upload director/owner ID
4. Bank account verification (they'll send 2 micro-deposits)
5. Wait 3-5 business days for approval

#### Step 3: Setup Connectivity
1. **Get API credentials** from dashboard:
   - Client ID
   - Client Secret
   - API key
2. **Create webhook endpoint** in your Firebase functions:
   - URL: `https://us-central1-orignagta.cloudfunctions.net/airwallex_webhook`
   - Events: `payment.succeeded`, `payment.failed`, `payout.completed`, `payout.failed`

#### Step 4: Configure for Sellers
1. **Marketplace settings**:
   - Enable "Connected Accounts" or similar
   - Set platform fee: 2.5% (same as Stripe)
   - Currency: CAD

#### Step 5: Testing
1. **Airwallex Sandbox**:
   - Dashboard → Settings → Switch to Sandbox
   - Use test card: `4111 1111 1111 1111`
   - Expiry: 12/25, CVV: 123

#### Step 6: Webhook Verification
1. Test webhook signature verification
2. Test payment flow end-to-end
3. Test payout flow end-to-end

#### Step 7: Production Switch
1. Switch from Sandbox to Production
2. Verify all settings migrated
3. Run full E2E tests with real transactions

### Backend Implementation

#### 1. Database Schema
```javascript
// users collection - sellers
"paymentProvider": "stripe" | "airwallex",
"airwallexAccount": {
  "accountId": "string",
  "customerId": "string",  // Airwallex customer ID
  "status": "pending" | "active" | "suspended",
  "connectedAt": timestamp,
  "verifiedAt": timestamp
},
"stripeAccount": {  // existing
  "accountId": "string",
  ...
}
```

#### 2. New Cloud Functions

**`airwallex_create_seller_account`**
```python
def airwallex_create_seller_account(seller_id, seller_data):
    """Create Airwallex account for seller"""
    # 1. Call Airwallex API to create customer
    # 2. Save account ID to Firestore
    # 3. Send email with next steps
    # 4. Return account link (for seller to complete verification)
```

**`airwallex_process_payment`**
```python
def airwallex_process_payment(order_id, seller_id, amount):
    """Process payment via Airwallex"""
    # 1. Validate seller is Airwallex connected
    # 2. Create payment intent via Airwallex API
    # 3. Authorize (not capture yet)
    # 4. Save to Firestore
```

**`airwallex_capture_payment`**
```python
def airwallex_capture_payment(order_id, seller_id):
    """Capture payment after shipping confirmed"""
    # 1. Find authorization
    # 2. Capture via Airwallex API
    # 3. Calculate platform fee (2.5%)
    # 4. Schedule payout
```

**`airwallex_webhook`**
```python
def airwallex_webhook(request):
    """Handle Airwallex webhook events"""
    # Verify signature
    # Route by event type
    # Update Firestore
    # Handle errors with retry logic
```

#### 3. Python Implementation Example
```python
import requests
import hmac
import hashlib
import json
from datetime import datetime

class AirwallexClient:
    def __init__(self, client_id, client_secret, api_key):
        self.client_id = client_id
        self.client_secret = client_secret
        self.api_key = api_key
        self.base_url = "https://api.airwallex.com/api/v1" if ENV == "prod" else "https://api-sandbox.airwallex.com/api/v1"
        self.token = self._get_auth_token()
    
    def _get_auth_token(self):
        """Get OAuth token from Airwallex"""
        response = requests.post(
            f"{self.base_url}/authentication/login",
            json={
                "api_key": self.api_key
            }
        )
        return response.json()["token"]
    
    def create_customer(self, seller_data):
        """Create Airwallex customer"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "customer_name": seller_data["business_name"],
            "email": seller_data["email"],
            "customer_type": "individual" if seller_data["is_individual"] else "corporate",
            "country": "CA"
        }
        response = requests.post(
            f"{self.base_url}/customers",
            json=payload,
            headers=headers
        )
        return response.json()
    
    def create_payment_intent(self, seller_id, order_id, amount_cents):
        """Create payment intent (authorize only, don't capture)"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "amount": amount_cents,
            "currency": "CAD",
            "merchant_id": seller_id,
            "order_id": order_id,
            "capture": False  # CRITICAL: Don't capture yet
        }
        response = requests.post(
            f"{self.base_url}/payments/create",
            json=payload,
            headers=headers
        )
        return response.json()
    
    def capture_payment(self, payment_id):
        """Capture previously authorized payment"""
        headers = {"Authorization": f"Bearer {self.token}"}
        response = requests.post(
            f"{self.base_url}/payments/{payment_id}/confirm",
            headers=headers
        )
        return response.json()
    
    def create_payout(self, seller_id, amount_cents, bank_account_id):
        """Schedule payout to seller"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "customer_id": seller_id,
            "amount": amount_cents,
            "currency": "CAD",
            "bank_account_id": bank_account_id
        }
        response = requests.post(
            f"{self.base_url}/payouts",
            json=payload,
            headers=headers
        )
        return response.json()
    
    def verify_webhook_signature(self, body, signature_header):
        """Verify webhook came from Airwallex"""
        computed = hmac.new(
            self.client_secret.encode(),
            body.encode(),
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(computed, signature_header)
```

#### 4. Seller Registration Flow (Frontend)
```dart
// lib/screens/seller_registration_screen.dart
class _PaymentProviderSelection extends StatefulWidget {
  @override
  State<_PaymentProviderSelection> createState() => _PaymentProviderSelectionState();
}

class _PaymentProviderSelectionState extends State<_PaymentProviderSelection> {
  String selectedProvider = 'stripe'; // Default

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Choose Payment Method"),
        // Stripe option
        ModernCard(
          child: Row(
            children: [
              Icon(Icons.payment, color: Colors.blue),
              Expanded(
                child: Text("Stripe (Recommended for Canada)")
              ),
              Radio(
                value: 'stripe',
                groupValue: selectedProvider,
                onChanged: (val) => setState(() => selectedProvider = val)
              )
            ]
          )
        ),
        SizedBox(height: 12),
        // Airwallex option
        ModernCard(
          child: Row(
            children: [
              Icon(Icons.public, color: Colors.orange),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Airwallex (For international sellers)"),
                    Text("Supports China & Asia",
                      style: TextStyle(fontSize: 12, color: Colors.grey)
                    )
                  ]
                )
              ),
              Radio(
                value: 'airwallex',
                groupValue: selectedProvider,
                onChanged: (val) => setState(() => selectedProvider = val)
              )
            ]
          )
        ),
        // Continue button
        ModernButton(
          label: "Continue",
          onPressed: () => continueWithProvider(selectedProvider)
        )
      ]
    );
  }

  void continueWithProvider(String provider) {
    // Call backend to create account with selected provider
    // For Stripe: Existing flow
    // For Airwallex: New flow
  }
}
```

#### 5. Checkout Flow (Updated for Both Providers)
```python
# functions/main.py - Updated create_checkout_session

def create_checkout_session(req):
    """Create checkout for ANY seller (Stripe or Airwallex)"""
    seller_id = req.json['seller_id']
    order_data = req.json['order_data']
    
    # 1. Get seller payment provider
    seller = db.collection('users').document(seller_id).get()
    payment_provider = seller.get('paymentProvider')  # 'stripe' or 'airwallex'
    
    if payment_provider == 'stripe':
        return _create_stripe_checkout(seller, order_data)
    elif payment_provider == 'airwallex':
        return _create_airwallex_checkout(seller, order_data)
    else:
        return error("Seller has no payment provider configured")

def _create_airwallex_checkout(seller, order_data):
    """Create Airwallex payment intent"""
    airwallex = AirwallexClient(...)
    
    amount_cents = int(order_data['total'] * 100)
    
    # Create payment intent (authorize only)
    payment = airwallex.create_payment_intent(
        seller_id=seller.id,
        order_id=order_data['order_id'],
        amount_cents=amount_cents
    )
    
    # Save to Firestore
    db.collection('payments').document(order_data['order_id']).set({
        'payment_id': payment['id'],
        'seller_id': seller.id,
        'provider': 'airwallex',
        'status': 'authorized',
        'amount': amount_cents,
        'created_at': firestore.SERVER_TIMESTAMP
    })
    
    return {
        'clientSecret': payment['client_secret'],
        'paymentId': payment['id'],
        'provider': 'airwallex'
    }
```

#### 6. Payout Flow (New)
```python
def schedule_airwallex_payout(order_id):
    """Schedule payout to seller via Airwallex"""
    
    # 1. Get payment & order details
    payment = db.collection('payments').document(order_id).get()
    order = db.collection('orders').document(order_id).get()
    seller = db.collection('users').document(order.get('seller_id')).get()
    
    # 2. Calculate seller amount (after 2.5% platform fee)
    gross_amount = payment.get('amount')
    platform_fee = int(gross_amount * 0.025)
    seller_payout = gross_amount - platform_fee
    
    # 3. Get seller's bank account
    bank_account_id = seller.get('airwallexAccount', {}).get('bankAccountId')
    if not bank_account_id:
        return error("Seller bank account not configured")
    
    # 4. Create payout
    airwallex = AirwallexClient(...)
    payout = airwallex.create_payout(
        seller_id=seller.id,
        amount_cents=seller_payout,
        bank_account_id=bank_account_id
    )
    
    # 5. Save payout record
    db.collection('payouts').document().set({
        'order_id': order_id,
        'seller_id': seller.id,
        'provider': 'airwallex',
        'amount': seller_payout,
        'payout_id': payout['id'],
        'status': 'pending',
        'created_at': firestore.SERVER_TIMESTAMP
    })
```

### Critical: Keep Stripe & Airwallex Logic Separated
```
WRONG:
├── payment_service.py
│   ├── if provider == 'stripe': ...
│   ├── elif provider == 'airwallex': ...
│   └── (mixed logic, hard to maintain)

RIGHT:
├── stripe_service.py (100% Stripe logic)
├── airwallex_service.py (100% Airwallex logic)
└── payment_router.py (Just routes to correct service)
```

### Testing Checklist
- [ ] Create Airwallex seller account
- [ ] Checkout with Airwallex payment
- [ ] Payment authorization succeeds
- [ ] Payment capture after shipping
- [ ] Payout scheduled to seller bank
- [ ] Webhook handles completion
- [ ] Dispute flow works
- [ ] Refund flow works
- [ ] Error handling (network failures, validation errors)

---

## PART 6: ADMIN MFA (TOTP)

### Implementation Overview
- Google Authenticator compatible
- 6-digit TOTP codes
- 30-second time window
- 10 backup codes for account recovery

### Sequence
1. Admin clicks "Enable 2FA" in settings
2. System generates secret (base32)
3. QR code displayed (uses secret)
4. Admin scans with Google Authenticator/Authy
5. Admin enters 6-digit code to verify
6. System generates 10 backup codes
7. Admin stores backup codes safely
8. From now on, every admin login requires TOTP code

### Database Schema
```javascript
// users collection - admin users
"mfaEnabled": true,
"mfaSecret": "REDACTED_SECRET",  // encrypted
"mfaBackupCodes": [
  {
    "code": "abc123xyz789",
    "used": false,
    "usedAt": null
  }
  // 9 more...
],
"mfaEnabledAt": timestamp,
"mfaLastUsedAt": timestamp
```

### Backend Implementation
```python
# requirements.txt
pyotp==2.9.0
qrcode==7.4.2

# functions/mfa_service.py
import pyotp
import qrcode
import io
import base64
import secrets
import string

class MFAService:
    @staticmethod
    def generate_secret(email):
        """Generate TOTP secret for user"""
        secret = pyotp.random_base32()
        # Store encrypted in Firestore (encrypt before storing)
        return secret
    
    @staticmethod
    def get_qr_code(email, secret):
        """Generate QR code for authenticator app"""
        totp = pyotp.TOTP(secret)
        uri = totp.provisioning_uri(
            name=email,
            issuer_name='OrignaGta Admin'
        )
        qr = qrcode.QRCode(version=1, box_size=10)
        qr.add_data(uri)
        qr.make()
        
        img = qr.make_image(fill_color="black", back_color="white")
        buf = io.BytesIO()
        img.save(buf)
        return base64.b64encode(buf.getvalue()).decode()
    
    @staticmethod
    def verify_token(secret, token):
        """Verify TOTP token (6-digit code)"""
        totp = pyotp.TOTP(secret)
        # Allow current + previous time window for clock skew
        return totp.verify(token, valid_window=1)
    
    @staticmethod
    def generate_backup_codes():
        """Generate 10 backup codes (8 chars each)"""
        codes = []
        for _ in range(10):
            code = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(8))
            codes.append({
                'code': code,
                'used': False,
                'usedAt': None
            })
        return codes
    
    @staticmethod
    def use_backup_code(user_id, code_entered):
        """Use backup code as fallback (one-time)"""
        user = db.collection('users').document(user_id).get()
        codes = user.get('mfaBackupCodes', [])
        
        for code_obj in codes:
            if code_obj['code'] == code_entered and not code_obj['used']:
                # Mark as used
                code_obj['used'] = True
                code_obj['usedAt'] = firestore.SERVER_TIMESTAMP
                db.collection('users').document(user_id).update({
                    'mfaBackupCodes': codes
                })
                return True
        return False

# functions/main.py - New endpoints
def enable_mfa_start(req):
    """Step 1: Start MFA setup"""
    user_id = req.headers.get('Authorization')  # From Firebase token
    email = db.collection('users').document(user_id).get()['email']
    
    secret = MFAService.generate_secret(email)
    qr_code_data_url = MFAService.get_qr_code(email, secret)
    
    # Store secret temporarily (unverified)
    db.collection('users').document(user_id).update({
        'mfaPendingSecret': secret,
        'mfaPendingCreatedAt': firestore.SERVER_TIMESTAMP
    })
    
    return {
        'qr_code': qr_code_data_url,
        'manual_entry': secret
    }

def enable_mfa_verify(req):
    """Step 2: Verify TOTP code to enable MFA"""
    user_id = req.headers.get('Authorization')
    token = req.json['token']  # 6-digit code from authenticator
    
    user = db.collection('users').document(user_id).get()
    secret = user.get('mfaPendingSecret')
    
    if not MFAService.verify_token(secret, token):
        return error("Invalid code", 400)
    
    # MFA verified! Generate backup codes
    backup_codes = MFAService.generate_backup_codes()
    
    # Save to database
    db.collection('users').document(user_id).update({
        'mfaEnabled': True,
        'mfaSecret': secret,  # Should be encrypted!
        'mfaBackupCodes': backup_codes,
        'mfaEnabledAt': firestore.SERVER_TIMESTAMP,
        'mfaPendingSecret': firestore.DELETE_FIELD
    })
    
    return {
        'success': True,
        'backup_codes': [c['code'] for c in backup_codes],
        'message': 'Save these codes in a safe place'
    }

def verify_mfa_login(req):
    """Verify MFA code during login"""
    email = req.json['email']
    password = req.json['password']
    mfa_code = req.json['mfa_code']  # 6-digit or 8-digit backup code
    
    # 1. Verify password
    user = db.collection('users').where('email', '==', email).get()[0]
    
    # 2. Verify MFA
    if len(mfa_code) == 6:
        # TOTP code
        if not MFAService.verify_token(user.get('mfaSecret'), mfa_code):
            return error("Invalid MFA code", 401)
    elif len(mfa_code) == 8:
        # Backup code
        if not MFAService.use_backup_code(user.id, mfa_code):
            return error("Invalid backup code", 401)
    else:
        return error("Invalid MFA code format", 400)
    
    # 3. Return auth token
    token = create_jwt_token(user.id)
    return {'token': token}
```

### Frontend Implementation
```dart
// lib/screens/admin_settings_screen.dart
class _AdminMFASettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(currentAdminProvider);
    
    if (adminUser.mfaEnabled) {
      return ModernCard(
        child: Column(
          children: [
            Icon(Icons.verified, color: Colors.green),
            Text("2FA Enabled"),
            ModernButton(
              label: "Disable 2FA",
              isOutlined: true,
              onPressed: () => _disableMFA(context)
            )
          ]
        )
      );
    }
    
    return ModernCard(
      child: Column(
        children: [
          Icon(Icons.lock_open, color: Colors.orange),
          Text("Enable 2-Factor Authentication"),
          Text("Secure your admin account with Google Authenticator",
            style: TextStyle(fontSize: 12, color: Colors.grey)
          ),
          SizedBox(height: 16),
          ModernButton(
            label: "Enable 2FA",
            onPressed: () => _startMFASetup(context, ref)
          )
        ]
      )
    );
  }
  
  void _startMFASetup(BuildContext context, WidgetRef ref) async {
    // Call backend to generate QR code
    final response = await FirebaseAuth.instance
      .currentUser!.getIdToken()
      .then((token) => CloudFunctions.instance
        .httpsCallable('enable_mfa_start')
        .call()
      );
    
    // Show QR code dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Scan QR Code"),
        content: Column(
          children: [
            Image.memory(
              base64Decode(response['qr_code']),
              width: 200,
              height: 200
            ),
            SizedBox(height: 16),
            Text("Or enter manually: ${response['manual_entry']}",
              style: TextStyle(fontSize: 10, color: Colors.grey)
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Enter 6-digit code from app"
              ),
              onSubmitted: (code) => _verifyMFACode(context, ref, code)
            )
          ]
        )
      )
    );
  }
  
  void _verifyMFACode(BuildContext context, WidgetRef ref, String code) async {
    try {
      final response = await CloudFunctions.instance
        .httpsCallable('enable_mfa_verify')
        .call({'token': code});
      
      // Show backup codes
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Save Backup Codes"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text("Save these codes in a secure location"),
                SizedBox(height: 12),
                ...response['backup_codes'].map((code) =>
                  Text(code, style: TextStyle(fontFamily: 'monospace'))
                ).toList(),
                SizedBox(height: 16),
                ModernButton(
                  label: "I've saved the codes",
                  onPressed: () => Navigator.pop(ctx)
                )
              ]
            )
          )
        )
      );
      
      ref.refresh(currentAdminProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid code: $e"))
      );
    }
  }
}
```

### Testing
- [ ] Enable MFA: QR code displays
- [ ] Scan QR in authenticator app
- [ ] Enter correct 6-digit code → succeeds
- [ ] Enter wrong code → fails
- [ ] Login with MFA code required
- [ ] Backup codes work (one-time)
- [ ] Can't reuse backup code
- [ ] Disable MFA works

---

## SUMMARY: IMPLEMENTATION ORDER

1. **Digital Products** (1-2 days) - Frontend + backend easy wins
2. **Auth Audits** (2-3 days) - Systematic testing of all flows
3. **Seller Gates** (1 day) - Quick database rule + UI updates
4. **KYC Setup** (3-5 days) - ComplyAdvantage integration
5. **Airwallex** (5-7 days) - Complex but isolated from Stripe
6. **Admin MFA** (1-2 days) - Straightforward TOTP
7. **Audits & Testing** (3-5 days) - Full E2E testing

**Total: 2-3 weeks for full Phase 4**

All pieces ready. Pick a starting point?
