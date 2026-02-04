# E2E Test Implementation Plan

## 🎯 Critical Flows to Test

Based on APPLICATION_LOGIC_AUDIT_REPORT.md, these flows have the highest impact and risk:

---

## 1. CHECKOUT FLOW (Priority: HIGHEST)

### Test: Complete Checkout with Payment
```dart
// integration_test/checkout_e2e_test.dart

testWidgets('Complete checkout flow - buyer to payment success', (tester) async {
  // 1. Login as buyer
  await tester.pumpWidget(ProviderScope(child: OrignaApp()));
  await loginAs('buyer@test.com', 'password123');
  
  // 2. Add product to cart
  await tester.tap(find.byType(ProductCard).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add to Cart'));
  await tester.pumpAndSettle();
  
  // 3. Navigate to cart
  await tester.tap(find.byIcon(Icons.shopping_cart));
  await tester.pumpAndSettle();
  
  // 4. Start checkout
  await tester.tap(find.text('Checkout'));
  await tester.pumpAndSettle();
  
  // 5. Fill shipping address
  await enterShippingAddress(tester, {
    'street': '123 Test St',
    'city': 'Toronto',
    'province': 'ON',
    'postalCode': 'M5H 2N2',
  });
  
  // 6. Select shipping option
  await tester.tap(find.text('Standard Shipping'));
  await tester.pumpAndSettle();
  
  // 7. Proceed to payment (mocked Stripe)
  await tester.tap(find.text('Proceed to Payment'));
  await tester.pumpAndSettle();
  
  // 8. Verify order created in Firestore
  final orderId = await getLastOrderId();
  expect(orderId, isNotEmpty);
  
  // 9. Verify order status
  final order = await getOrder(orderId);
  expect(order.status, OrderStatus.pending);
  expect(order.paymentStatus, PaymentStatus.authorized);
  
  // 10. Verify stock was decremented
  final product = await getProduct(order.items.first.productId);
  expect(product.stock, lessThan(originalStock));
});
```

### Test: Checkout with Insufficient Stock
```dart
testWidgets('Checkout fails gracefully with out-of-stock', (tester) async {
  // Setup: Product with 0 stock
  await setProductStock('product123', 0);
  
  // Attempt checkout
  await attemptCheckout('product123');
  
  // Verify error shown
  expect(find.text('Product out of stock'), findsOneWidget);
  
  // Verify NO order created
  final orders = await getOrdersForUser(currentUserId);
  expect(orders.length, 0);
});
```

### Test: Idempotency - Retry Checkout
```dart
testWidgets('Retry checkout with same idempotency key does not duplicate', (tester) async {
  final idempotencyKey = 'test-${DateTime.now().millisecondsSinceEpoch}';
  
  // First checkout
  final order1 = await createCheckout(items, idempotencyKey);
  
  // Retry with same key (simulates network retry)
  final order2 = await createCheckout(items, idempotencyKey);
  
  // Verify same order returned
  expect(order1.id, order2.id);
  
  // Verify stock only decremented ONCE
  final product = await getProduct(items.first.productId);
  expect(product.stock, originalStock - items.first.quantity);
});
```

---

## 2. SELLER ONBOARDING FLOW (Priority: HIGH)

### Test: Complete Seller Registration
```dart
testWidgets('Seller onboarding - registration to first payout', (tester) async {
  // 1. Login as buyer
  await loginAs('newuser@test.com', 'password123');
  
  // 2. Navigate to seller registration
  await tester.tap(find.text('Become a Seller'));
  await tester.pumpAndSettle();
  
  // 3. Create Stripe Connect account (mocked)
  await tester.tap(find.text('Start Registration'));
  await tester.pumpAndSettle();
  
  // Verify user has stripeAccountId
  final user = await getCurrentUser();
  expect(user.stripeAccountId, isNotNull);
  
  // 4. Complete Stripe onboarding (mocked redirect)
  await completeStripeOnboarding(user.stripeAccountId);
  
  // Verify seller role added
  final updatedUser = await getCurrentUser();
  expect(updatedUser.roles, contains(UserRoles.seller));
  expect(updatedUser.onboardingCompleted, true);
  
  // 5. Create first product
  await createProduct({
    'name': 'Test Product',
    'price': 29.99,
    'stock': 100,
  });
  
  // 6. Verify product appears in seller dashboard
  await tester.tap(find.text('My Products'));
  await tester.pumpAndSettle();
  expect(find.text('Test Product'), findsOneWidget);
});
```

### Test: KYC Sanctions Check Blocks Registration
```dart
testWidgets('Seller with sanctioned keyword is blocked', (tester) async {
  // Login with sanctioned display name
  await loginAs('Terrorist Test Account', 'terroristtest@test.com');
  
  // Attempt seller registration
  await tester.tap(find.text('Become a Seller'));
  await tester.pumpAndSettle();
  
  // Verify blocked with error
  expect(find.text('Unable to complete seller registration'), findsOneWidget);
  
  // Verify security alert logged
  final alerts = await getSecurityAlerts();
  expect(alerts.any((a) => a.type == 'sanctions_match'), true);
});
```

---

## 3. SELLER ORDERS VIEW (Priority: HIGH)

### Test: View Orders by Status
```dart
testWidgets('Seller sees filtered orders by status', (tester) async {
  // Setup: Create orders in different statuses
  await createOrderForSeller(sellerId, status: OrderStatus.pending);
  await createOrderForSeller(sellerId, status: OrderStatus.confirmed);
  await createOrderForSeller(sellerId, status: OrderStatus.processing);
  await createOrderForSeller(sellerId, status: OrderStatus.shipped);
  
  // Login as seller
  await loginAs('seller@test.com', 'password123');
  
  // Navigate to seller orders
  await tester.tap(find.text('Seller Dashboard'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Orders'));
  await tester.pumpAndSettle();
  
  // Filter by 'pending'
  await tester.tap(find.text('Pending'));
  await tester.pumpAndSettle();
  
  // Verify only pending orders shown
  final pendingOrders = find.byType(OrderCard);
  expect(pendingOrders, findsNWidgets(1));
  
  // Filter by 'shipped'
  await tester.tap(find.text('Shipped'));
  await tester.pumpAndSettle();
  
  // Verify only shipped orders shown
  final shippedOrders = find.byType(OrderCard);
  expect(shippedOrders, findsNWidgets(1));
});
```

---

## 4. SHIPPING CONFIRMATION (Priority: CRITICAL)

### Test: Shipping Approval Flow
```dart
testWidgets('Seller approves shipping and payment is captured', (tester) async {
  // Setup: Order with paymentStatus = authorized
  final orderId = await createAuthorizedOrder();
  
  // Login as seller
  await loginAs('seller@test.com', 'password123');
  
  // Navigate to order
  await openOrder(tester, orderId);
  
  // Approve shipping
  await tester.tap(find.text('Approve Shipping'));
  await tester.pumpAndSettle();
  
  // Enter tracking (optional)
  await tester.enterText(find.byKey(Key('tracking')), 'TRACK123');
  
  // Confirm
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
  
  // Verify order updated
  final order = await getOrder(orderId);
  expect(order.shippingApprovalStatus, ShippingApprovalStatus.approved);
  expect(order.status, OrderStatus.processing);
  
  // Verify payment captured (check Firestore or mock Stripe)
  expect(order.paymentStatus, PaymentStatus.captured);
});
```

### Test: Shipping Auto-Approval After 24h
```dart
testWidgets('Shipping auto-approves after 24 hours', (tester) async {
  // Setup: Order created 24h+ ago
  final orderId = await createOrderWithTimestamp(
    DateTime.now().subtract(Duration(hours: 25)),
  );
  
  // Run scheduled job (or advance clock)
  await runScheduledJob('auto_approve_shipping');
  
  // Verify order auto-approved
  final order = await getOrder(orderId);
  expect(order.shippingApprovalStatus, ShippingApprovalStatus.approved);
  expect(order.autoApprovedAt, isNotNull);
  
  // Verify payment captured
  expect(order.paymentStatus, PaymentStatus.captured);
});
```

---

## 5. ORDER LIFECYCLE (Priority: CRITICAL)

### Test: Complete Order Lifecycle
```dart
testWidgets('Order transitions through all states correctly', (tester) async {
  // 1. Create order (pending)
  final orderId = await createOrder();
  var order = await getOrder(orderId);
  expect(order.status, OrderStatus.pending);
  
  // 2. Confirm order
  await confirmOrder(orderId);
  order = await getOrder(orderId);
  expect(order.status, OrderStatus.confirmed);
  
  // 3. Process order (seller approves shipping)
  await approveShipping(orderId);
  order = await getOrder(orderId);
  expect(order.status, OrderStatus.processing);
  expect(order.paymentStatus, PaymentStatus.captured);
  
  // 4. Ship order
  await markAsShipped(orderId, 'TRACK123');
  order = await getOrder(orderId);
  expect(order.status, OrderStatus.shipped);
  
  // 5. Deliver order
  await markAsDelivered(orderId);
  order = await getOrder(orderId);
  expect(order.status, OrderStatus.delivered);
  expect(order.deliveryStatus, DeliveryStatus.delivered);
});
```

### Test: Invalid State Transitions Blocked
```dart
testWidgets('Cannot skip order states', (tester) async {
  final orderId = await createOrder(); // pending
  
  // Attempt to jump from pending → shipped (skipping processing)
  final result = await attemptUpdateOrderStatus(orderId, OrderStatus.shipped);
  
  // Verify blocked by Firestore rules or backend validation
  expect(result.success, false);
  expect(result.error, contains('Invalid state transition'));
  
  // Verify order still pending
  final order = await getOrder(orderId);
  expect(order.status, OrderStatus.pending);
});
```

---

## 6. REFUND FLOW (Priority: HIGH)

### Test: Refund Restores Stock
```dart
testWidgets('Refund properly restores product stock', (tester) async {
  // Setup: Order with captured payment
  final orderId = await createCapturedOrder(productId: 'prod123', quantity: 5);
  final originalStock = await getProductStock('prod123');
  
  // Process refund (simulate Stripe webhook)
  await processRefund(orderId);
  
  // Verify stock restored
  final newStock = await getProductStock('prod123');
  expect(newStock, originalStock + 5);
  
  // Verify order status
  final order = await getOrder(orderId);
  expect(order.status, OrderStatus.refunded);
  expect(order.paymentStatus, PaymentStatus.refunded);
});
```

---

## 7. AUTHORIZATION EXPIRY (Priority: MEDIUM)

### Test: Expired Authorization Cancels Order
```dart
testWidgets('Order cancelled after 7 days without capture', (tester) async {
  // Setup: Order with expired authorization (8 days old)
  final orderId = await createOrderWithAuthExpiry(
    expiresAt: DateTime.now().subtract(Duration(days: 8)),
  );
  
  // Run expiry check job
  await runScheduledJob('check_expired_authorizations');
  
  // Verify order cancelled
  final order = await getOrder(orderId);
  expect(order.status, OrderStatus.cancelled);
  
  // Verify stock restored
  final product = await getProduct(order.items.first.productId);
  expect(product.stock, originalStock + order.items.first.quantity);
  
  // Verify Stripe intent cancelled (check logs or mock)
  // ...
});
```

---

## 📋 Implementation Checklist

### Phase 1 (Critical - Week 1)
- [ ] Checkout E2E test (complete flow)
- [ ] Checkout E2E test (out of stock)
- [ ] Checkout E2E test (idempotency)
- [ ] Shipping approval E2E test
- [ ] Shipping auto-approval E2E test
- [ ] Order lifecycle E2E test
- [ ] Invalid state transitions E2E test

### Phase 2 (High - Week 2)
- [ ] Seller onboarding E2E test
- [ ] Seller orders view E2E test
- [ ] KYC sanctions check E2E test
- [ ] Refund flow E2E test

### Phase 3 (Medium - Week 3)
- [ ] Authorization expiry E2E test
- [ ] Rate limiting E2E tests
- [ ] Session timeout E2E test
- [ ] Algolia search E2E test

---

## 🛠️ Test Infrastructure Setup

### 1. Mock Stripe API
```dart
// test/mocks/stripe_mock.dart
class MockStripeService extends Mock implements StripeService {
  @override
  Future<CheckoutSession> createCheckoutSession({...}) async {
    return CheckoutSession(
      id: 'cs_test_${DateTime.now().millisecondsSinceEpoch}',
      url: 'https://checkout.stripe.com/test',
      paymentIntentId: 'pi_test_123',
    );
  }
}
```

### 2. Firestore Emulator
```yaml
# firebase.json
{
  "emulators": {
    "firestore": {
      "port": 8080
    },
    "functions": {
      "port": 5001
    }
  }
}
```

### 3. GitHub Actions Integration
```yaml
# .github/workflows/integration_tests.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Start Firebase Emulators
        run: firebase emulators:start --only firestore,functions &
        
      - name: Run Integration Tests
        run: flutter test integration_test
        
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

---

## 📊 Success Metrics

- **Test Coverage**: > 80% for critical flows
- **E2E Test Duration**: < 10 minutes total
- **Flakiness Rate**: < 5% (tests fail randomly)
- **CI Integration**: All tests run on every PR
- **Documentation**: Each test has comments explaining WHY

---

## 🚀 Next Steps

1. Create `integration_test/` directory
2. Set up Firestore emulator config
3. Implement Phase 1 tests (checkout + shipping)
4. Add to CI/CD pipeline
5. Monitor test results in GitHub Actions
