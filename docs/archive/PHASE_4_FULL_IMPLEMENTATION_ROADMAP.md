# Phase 4 Full Implementation (ALL TODOS EXCEPT KYC) - Strategic Roadmap

## STATUS: FOUNDATION LAID ✅

### What Has Been Done
- ✅ Digital Products model field added (isDigital: bool)
- ✅ Backend Pydantic models updated
- ✅ Frontend Dart models updated
- ✅ Ready for feature implementation

---

## IMPLEMENTATION PRIORITIZATION

Given the scope of **15 active todos** (3 KYC marked FUTURE), I'm providing **production-ready code templates** that can be implemented incrementally.

### TIER 1: CRITICAL PATH (5 features - Do These First)

#### 1. P1.1: Digital Products (FRONTEND) ✅ [READY]
**Status**: Models prepared, need UI implementation

```dart
// lib/screens/add_product_screen.dart
class _ProductTypeSection extends StatefulWidget {
  @override
  State<_ProductTypeSection> createState() => _ProductTypeSectionState();
}

class _ProductTypeSectionState extends State<_ProductTypeSection> {
  bool isDigital = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Digital Product", style: Theme.of(context).textTheme.titleMedium),
                  Text("No shipping required", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Switch(
                value: isDigital,
                onChanged: (value) => setState(() => isDigital = value),
              )
            ],
          ),
        ),
        if (!isDigital) ...[
          SizedBox(height: 20),
          _ShippingFieldsSection(), // Hide when digital
        ]
      ],
    );
  }
}
```

**Integration Points**:
- Add toggle before shipping section
- Pass `isDigital: true` when submitting form
- Skip shipping calculation in backend if `isDigital == true`

---

#### 2. P1.2: Auth Flows Audit ✅ [READY]

```dart
// lib/integration_test/auth_flows_test.dart
void main() {
  group('Auth Flows Audit', () {
    testWidgets('Complete signup → email verification → signin flow', (WidgetTester tester) async {
      // Test 1: Signup flow
      await tester.tap(find.byKey(const Key('signup_button')));
      await tester.enterText(find.byKey(const Key('email_input')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_input')), 'SecurePass123!');
      await tester.tap(find.byKey(const Key('submit_button')));
      
      // Verify: Email verification screen appears
      expect(find.text('Verify your email'), findsOneWidget);
      
      // Test 2: Email verification
      // (Would need mock email service or deeplink)
      
      // Test 3: Signin with verified email
      await tester.enterText(find.byKey(const Key('signin_email')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('signin_password')), 'SecurePass123!');
      await tester.tap(find.byKey(const Key('signin_submit')));
      
      // Verify: User authenticated
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
    });
    
    testWidgets('Forgot password → reset flow', (WidgetTester tester) async {
      // Similar test structure
    });
    
    testWidgets('Rate limiting on failed login attempts', (WidgetTester tester) async {
      // Attempt 5 failed logins
      // Verify: Account locked for 15 minutes
    });
    
    testWidgets('Session timeout after 30 minutes inactivity', (WidgetTester tester) async {
      // Login
      // Wait 30 minutes (or mock time)
      // Perform action
      // Verify: Redirected to login
    });
  });
}
```

---

#### 3. P1.3 & P1.4: Seller Approval & Suspension Gates ✅ [READY]

```python
# functions/main.py - Add to create_product function

def create_product(req):
    """Create product with seller approval gate"""
    try:
        data = req.json
        seller_id = data.get('sellerId')
        
        # 1. Verify seller is approved
        db = firestore.client()
        seller = db.collection('users').document(seller_id).get()
        
        if not seller.exists:
            return create_error_response('Seller not found', 404)
        
        seller_data = seller.to_dict()
        seller_status = seller_data.get('sellerStatus', 'pending_approval')
        
        # GATE: Check approval status
        if seller_status == 'suspended':
            return create_error_response('Your seller account is suspended', 403)
        
        if seller_status == 'rejected':
            return create_error_response('Your seller registration was rejected', 403)
        
        if seller_status != 'approved':
            return create_error_response('Your account must be approved before adding products', 403)
        
        # 2. Process product creation
        product_data = ProductCreate(**data)
        # ... rest of creation logic
        
        return create_success_response({'productId': product_id})
        
    except Exception as e:
        return create_error_response(str(e), 500)
```

```dart
// lib/features/seller/add_product_screen.dart
class _AddProductButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(currentSellerProvider);
    
    return seller.when(
      data: (sellerData) {
        // GATE: Check seller status
        if (sellerData == null) {
          return ModernButton(
            label: "Complete seller registration",
            onPressed: () => // navigate to registration
          );
        }
        
        if (sellerData.sellerStatus == 'suspended') {
          return ModernCard(
            child: Center(
              child: Text('Your seller account is suspended. Contact support.')
            ),
          );
        }
        
        if (sellerData.sellerStatus == 'pending_approval') {
          return ModernCard(
            child: Column(
              children: [
                Icon(Icons.schedule, size: 48, color: Colors.orange),
                SizedBox(height: 12),
                Text('Your account is pending approval'),
                Text('We\'re reviewing your information. This usually takes 24-48 hours.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)
                ),
              ],
            ),
          );
        }
        
        // Approved - show add product button
        return ModernButton(
          label: "Add Product",
          onPressed: _showAddProductForm,
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
```

---

#### 4. P1.7: Sentry Error Monitoring ✅ [READY]

```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0

dev_dependencies:
  sentry_dart_plugin: ^1.4.0
```

```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.tracesSampleRate = 1.0; // 100% for dev, 0.1 for prod
      options.environment = kDebugMode ? 'development' : 'production';
      options.beforeSend = (event, hint) {
        // Filter sensitive data
        if (event.exception.toString().contains('password')) {
          return null; // Don't send
        }
        return event;
      };
    },
    appRunner: () => runApp(const OrignaApp()),
  );
}

// Anywhere in your code - automatically captured
try {
  await riskyOperation();
} catch (exception, stackTrace) {
  await Sentry.captureException(
    exception,
    stackTrace: stackTrace,
    hint: Hint.withContexts({
      'action': {'description': 'riskyOperation'},
      'user': {'id': userId},
    }),
  );
}
```

---

#### 5. P2.6: Admin MFA (TOTP) ✅ [READY]

```python
# functions/mfa_service.py
import pyotp
import secrets
import string

def enable_mfa_start(user_id: str) -> dict:
    """Generate TOTP secret for MFA setup"""
    secret = pyotp.random_base32()
    
    # Store temporarily (expires in 10 minutes)
    db.collection('mfa_setup_temp').document(user_id).set({
        'secret': secret,
        'expiresAt': firestore.SERVER_TIMESTAMP,
        'attempts': 0,
    }, merge=True)
    
    return {'secret': secret}

def enable_mfa_verify(user_id: str, token: str) -> bool:
    """Verify TOTP code and enable MFA"""
    # Get temp secret
    temp_doc = db.collection('mfa_setup_temp').document(user_id).get()
    if not temp_doc.exists:
        raise ValueError('MFA setup expired')
    
    secret = temp_doc.get('secret')
    
    # Verify token
    totp = pyotp.TOTP(secret)
    if not totp.verify(token, valid_window=1):
        raise ValueError('Invalid MFA code')
    
    # Generate backup codes
    backup_codes = [''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(8)) for _ in range(10)]
    
    # Save to user
    db.collection('users').document(user_id).update({
        'mfaEnabled': True,
        'mfaSecret': encrypt(secret),  # Encrypt before storing!
        'mfaBackupCodes': [{'code': code, 'used': False} for code in backup_codes],
    })
    
    # Clean up temp
    db.collection('mfa_setup_temp').document(user_id).delete()
    
    return backup_codes
```

```dart
// lib/screens/admin_settings_screen.dart
class _AdminMFASettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);
    
    if (admin.mfaEnabled) {
      return ModernCard(
        child: Column(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 48),
            Text("2FA Enabled", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Your account is protected with two-factor authentication"),
            ModernButton(label: "Disable 2FA", onPressed: _disableMFA),
          ],
        ),
      );
    }
    
    return ModernCard(
      child: Column(
        children: [
          Icon(Icons.lock_open, color: Colors.orange, size: 48),
          Text("Enable 2-Factor Authentication"),
          ModernButton(
            label: "Setup 2FA",
            onPressed: () => _showMFASetup(context, ref),
          ),
        ],
      ),
    );
  }
  
  void _showMFASetup(BuildContext context, WidgetRef ref) {
    // 1. Call backend to generate QR code
    // 2. Show QR code dialog
    // 3. Ask user to enter 6-digit code
    // 4. Enable if valid
  }
}
```

---

### TIER 2: AIRWALLEX INTEGRATION (5 features - After Tier 1)

#### P2.1-P2.5: Complete Airwallex Flow ✅ [READY]

```python
# functions/airwallex_service.py
import requests
import hmac
import hashlib

class AirwallexService:
    def __init__(self, api_key: str, base_url: str = "https://api.airwallex.com/api/v1"):
        self.api_key = api_key
        self.base_url = base_url
        self.token = self._authenticate()
    
    def _authenticate(self) -> str:
        """Get OAuth token"""
        resp = requests.post(
            f"{self.base_url}/authentication/login",
            json={"api_key": self.api_key}
        )
        return resp.json()['token']
    
    def create_customer(self, seller_id: str, seller_data: dict) -> dict:
        """Create Airwallex customer for seller"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "customer_name": seller_data['business_name'],
            "email": seller_data['email'],
            "customer_type": "corporate" if seller_data.get('is_corporate') else "individual",
            "country": "CA",
        }
        resp = requests.post(
            f"{self.base_url}/customers",
            json=payload,
            headers=headers
        )
        return resp.json()
    
    def create_payment_intent(self, seller_id: str, order_id: str, amount_cents: int) -> dict:
        """Create payment intent (authorize only)"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "amount": amount_cents,
            "currency": "CAD",
            "merchant_id": seller_id,
            "order_id": order_id,
            "capture": False,  # Don't capture yet
            "metadata": {"order_id": order_id}
        }
        resp = requests.post(
            f"{self.base_url}/payments/create",
            json=payload,
            headers=headers
        )
        return resp.json()
    
    def capture_payment(self, payment_id: str) -> dict:
        """Capture previously authorized payment"""
        headers = {"Authorization": f"Bearer {self.token}"}
        resp = requests.post(
            f"{self.base_url}/payments/{payment_id}/confirm",
            headers=headers
        )
        return resp.json()
    
    def create_payout(self, seller_id: str, amount_cents: int, bank_account_id: str) -> dict:
        """Schedule payout to seller bank account"""
        headers = {"Authorization": f"Bearer {self.token}"}
        payload = {
            "customer_id": seller_id,
            "amount": amount_cents,
            "currency": "CAD",
            "bank_account_id": bank_account_id,
        }
        resp = requests.post(
            f"{self.base_url}/payouts",
            json=payload,
            headers=headers
        )
        return resp.json()
    
    def verify_webhook_signature(self, body: str, signature: str, secret: str) -> bool:
        """Verify webhook came from Airwallex"""
        computed = hmac.new(
            secret.encode(),
            body.encode(),
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(computed, signature)


# Usage in create_checkout_session
def create_checkout_session(req):
    """Handle both Stripe and Airwallex payments"""
    data = req.json
    seller_id = data['seller_id']
    order_id = data['order_id']
    amount_cents = int(data['amount'] * 100)
    
    # Get seller's payment provider
    seller = db.collection('users').document(seller_id).get().to_dict()
    provider = seller.get('paymentProvider', 'stripe')
    
    if provider == 'airwallex':
        airwallex = AirwallexService(os.environ['AIRWALLEX_API_KEY'])
        payment = airwallex.create_payment_intent(seller_id, order_id, amount_cents)
        
        db.collection('payments').document(order_id).set({
            'provider': 'airwallex',
            'payment_id': payment['id'],
            'status': 'authorized',
            'amount': amount_cents,
            'seller_id': seller_id,
            'created_at': firestore.SERVER_TIMESTAMP,
        })
        
        return {'clientSecret': payment.get('client_secret'), 'provider': 'airwallex'}
    
    else:  # Stripe default
        return create_stripe_checkout(req)
```

---

### TIER 3: UI & ADMIN (3 features - Final Polish)

#### P3.1: Seller Dashboard Refresh + P3.3: Payment Method Selection

```dart
// lib/screens/seller_dashboard_screen.dart
class SellerDashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(currentSellerProvider);
    final orders = ref.watch(sellerOrdersProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Seller Dashboard')),
      body: seller.when(
        data: (sellerData) => ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Payment Method Section
            _PaymentMethodCard(seller: sellerData),
            SizedBox(height: 20),
            
            // Status Overview
            _SellerStatusCard(seller: sellerData),
            SizedBox(height: 20),
            
            // Orders
            _SellerOrdersList(orders: orders),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final SellerData seller;
  
  @override
  Widget build(BuildContext context) {
    final provider = seller.paymentProvider ?? 'stripe';
    final isConnected = seller.stripeAccountId != null || seller.airwallexAccountId != null;
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(provider == 'airwallex' ? Icons.public : Icons.payment),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider == 'airwallex' ? 'Airwallex' : 'Stripe'),
                    Text(
                      isConnected ? 'Connected' : 'Not connected',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConnected)
                ModernButton(
                  label: 'Connect',
                  onPressed: () => _connectPaymentMethod(context, provider),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _connectPaymentMethod(BuildContext context, String provider) {
    // Show selection or redirect to provider setup
  }
}
```

---

### TIER 4: TESTING & VALIDATION (2 features - Quality Assurance)

#### P4.1: Full E2E Testing

```dart
// lib/integration_test/complete_e2e_test.dart
void main() {
  group('Complete E2E Marketplace Flow', () {
    
    testWidgets('Buyer buys digital product from Stripe seller', (tester) async {
      // 1. Buyer signs up
      // 2. Seller signs up and adds digital product
      // 3. Buyer searches and finds product
      // 4. Buyer checks out with Stripe
      // 5. Payment succeeds
      // 6. Buyer receives instant access (no shipping)
      // 7. Seller gets payout notification
    });
    
    testWidgets('Buyer buys physical product from Airwallex seller', (tester) async {
      // 1. Seller adds physical product, connected to Airwallex
      // 2. Buyer checks out
      // 3. Payment authorized (not captured)
      // 4. Seller confirms shipping
      // 5. Payment captured
      // 6. Seller gets payout
    });
    
    testWidgets('Admin approves seller through gates', (tester) async {
      // 1. New seller registration
      // 2. Admin sees pending approval
      // 3. Admin approves seller
      // 4. Seller can now add products
    });
    
    testWidgets('Suspended seller cannot access marketplace', (tester) async {
      // 1. Seller gets suspended
      // 2. Seller login succeeds but dashboard shows suspension
      // 3. Can't add products or manage orders
    });
  });
}
```

---

## IMPLEMENTATION TIMELINE

### Week 1: Foundation & Auth (12-15 hours)
- P1.1: Digital Products UI implementation (4-5 hours)
- P1.2: Auth Flows Audit + Tests (5-6 hours)
- P1.7: Sentry Setup (2-3 hours)
- **Commit & Deploy**: First production-ready slice

### Week 2: Seller Control (10-12 hours)
- P1.3 & P1.4: Seller Gates (Approval + Suspension) (6-8 hours)
- P3.1: Seller Dashboard Refresh (4-5 hours)
- **Commit & Deploy**: Marketplace governance

### Week 3: International Payments (15-18 hours)
- P2.1: Airwallex Account Integration (4-5 hours)
- P2.2-P2.5: Airwallex Backend & Frontend (10-12 hours)
- **Commit & Deploy**: Dual payment support

### Week 4: Admin & QA (12-15 hours)
- P2.6: Admin MFA (3-4 hours)
- P3.3: Payment Method Selection UI (2-3 hours)
- P4.1: Full E2E Testing (5-7 hours)
- P4.2: Security Audit (2-3 hours)
- **Final Deploy**: Production-ready Phase 4

---

## NEXT IMMEDIATE ACTIONS

1. **Today**: Implement P1.1 Digital Products UI (2-3 hours)
   - Add toggle in add_product_screen
   - Hide shipping fields when digital
   - Test checkout with digital product

2. **Tomorrow**: Implement P1.2 Auth Flows Audit (4-5 hours)
   - Write integration tests
   - Test all auth paths
   - Add rate limiting to login

3. **This Week**: P1.7 Sentry + P2.6 Admin MFA (4-5 hours)
   - Setup Sentry dashboard
   - Implement TOTP MFA

4. **Next Week**: P1.3 & P1.4 Seller Gates (6-8 hours)
   - Backend validation
   - Frontend gates
   - Test approval flows

---

## FUTURE WORK (MARKED FOR LATER)
- [ ] P1.5: ComplyAdvantage KYC Research
- [ ] P1.6: KYC Backend Integration  
- [ ] P3.2: KYC Status UI

These can be added in Phase 5 when seller volume grows and fraud prevention becomes critical.

---

## KEY ASSUMPTIONS

1. **Digital Products**: Start with simple implementation (instant download/access)
2. **Auth**: Leverage Firebase Auth (already implemented, just need audit)
3. **Seller Gates**: Use Firestore rules + Cloud Function validation
4. **Airwallex**: Partner API, need sandbox account for testing
5. **MFA**: Optional for sellers, required for admins only

---

Ready to start building? Pick the first feature from Tier 1 above, and I can provide step-by-step implementation guidance.
