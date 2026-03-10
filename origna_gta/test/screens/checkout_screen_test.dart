import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/core/repositories/order_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/models.dart' as models;
import 'package:origna_gta/screens/checkout_screen.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:orignabase/orignabase.dart';

import '../test_utils.dart';
@GenerateNiceMocks([
  MockSpec<OrignaBase>(),
  MockSpec<OrderRepository>(),
  MockSpec<UserRepository>(),
  MockSpec<AuthRepository>(),
])
import 'checkout_screen_test.mocks.dart';

void main() {
  const signedInUser = AppAuthUser(
    uid: 'test_user_123',
    email: 'test@example.com',
    emailVerified: true,
  );
  late MockOrignaBase mockOrignaBase;
  late MockOrderRepository mockOrderRepo;
  late MockUserRepository mockUserRepo;
  late MockAuthRepository mockAuthRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockOrignaBase = MockOrignaBase();
    mockOrderRepo = MockOrderRepository();
    mockUserRepo = MockUserRepository();
    mockAuthRepo = MockAuthRepository();

    when(mockAuthRepo.isEmailVerified()).thenAnswer((_) async => true);
    when(mockOrignaBase.request(any, any, body: anyNamed('body')))
        .thenAnswer((_) async => <String, dynamic>{});
  });

  Widget buildTestWidget({List<models.CartItemDetailModel> items = const [], double total = 0.0, List<models.Address> addresses = const []}) {
    return TestWrapper(
      overrides: [
        currentUserProvider.overrideWithValue(signedInUser),
        obUserIdProvider.overrideWithValue(signedInUser.uid),
        userProfileProvider.overrideWith(
          (ref) =>
              Stream.value(models.UserModel(uid: 'test_user_123', name: 'Test User', email: 'test@example.com', roles: ['buyer'], createdAt: DateTime.now())),
        ),
        userAddressesProvider.overrideWith((ref) => Stream.value(addresses)),
        cartItemsProvider.overrideWith((ref) => Stream.value(const [])),
        subscriptionStreamProvider.overrideWith((ref) => Stream.value(null)),
        orignabaseProvider.overrideWithValue(mockOrignaBase),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        userRepositoryProvider.overrideWithValue(mockUserRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: CheckoutScreen(items: items, total: total),
    );
  }

  group('CheckoutScreen Comprehensive Test', () {
    testWidgets('processes checkout successfully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 3000);
      tester.view.devicePixelRatio = 1.0;

      final mockItem = models.CartItemDetailModel(
        productId: 'prod_1',
        name: 'Smartphone',
        description: 'Great phone',
        price: 50.0,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: models.Address(street: '123 Seller St', city: 'Toronto', state: 'ON', postalCode: 'M5V 2L7', country: 'Canada'),
        sellerId: 'seller_123',
        sellerName: 'Best Seller',
        status: 'active',
      );

      final mockAddress = models.Address(street: '456 Buyer Ave', city: 'Toronto', state: 'ON', postalCode: 'M1M 1M1', country: 'Canada', isDefault: true);

      when(mockOrignaBase.request('POST', any, body: anyNamed('body')))
          .thenAnswer((_) async => {'hasChanges': false});

      when(mockOrderRepo.createCheckoutSession(any)).thenAnswer(
        (_) async => {'checkoutUrl': 'https://stripe.com/checkout/test_session', 'sessionId': 'sess_123', 'orderId': 'order_123', 'taxAmountCents': 650},
      );

      await tester.pumpWidget(buildTestWidget(items: [mockItem], total: 50.0, addresses: [mockAddress]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkout_terms_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkout_place_order_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkout_confirm_pay_button')));
      await tester.pump(const Duration(seconds: 1));

      verify(mockOrderRepo.createCheckoutSession(any)).called(1);
      tester.view.resetPhysicalSize();
    });

    testWidgets('Place Order button is disabled when terms not accepted', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 3000);
      final mockItem = models.CartItemDetailModel(
        productId: 'p1',
        name: 'P',
        description: '',
        price: 10,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: models.Address.empty(),
        sellerId: 's1',
        sellerName: 'S1',
      );
      final mockAddress = models.Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M 1M1', country: 'CA', isDefault: true);

      await tester.pumpWidget(buildTestWidget(items: [mockItem], total: 10.0, addresses: [mockAddress]));
      await tester.pumpAndSettle();

      final placeOrderBtn = tester.widget<ModernButton>(find.byKey(const Key('checkout_place_order_button')));
      expect(placeOrderBtn.onPressed, isNull);
      tester.view.resetPhysicalSize();
    });

    testWidgets('shows error SnackBar on checkout failure', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 3000);
      final mockItem = models.CartItemDetailModel(
        productId: 'p1',
        name: 'P',
        description: '',
        price: 10,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: models.Address.empty(),
        sellerId: 's1',
        sellerName: 'S1',
      );
      final mockAddress = models.Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M 1M1', country: 'CA', isDefault: true);

      when(mockOrignaBase.request('POST', any, body: anyNamed('body')))
          .thenAnswer((_) async => {'hasChanges': false});

      when(mockOrderRepo.createCheckoutSession(any)).thenThrow(Exception('Payment failed'));

      await tester.pumpWidget(buildTestWidget(items: [mockItem], total: 10.0, addresses: [mockAddress]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('checkout_terms_checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkout_place_order_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkout_confirm_pay_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsAtLeast(1));
      tester.view.resetPhysicalSize();
    });

    testWidgets('digital only view without address', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 3000);
      final mockItem = models.CartItemDetailModel(
        productId: 'p1',
        name: 'Software',
        description: '',
        price: 10,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: models.Address.empty(),
        sellerId: 's1',
        sellerName: 'S1',
        isDigital: true,
      );

      await tester.pumpWidget(buildTestWidget(items: [mockItem], total: 10.0, addresses: []));
      await tester.pumpAndSettle();

      // Check for the icon instead of text to be safe
      expect(find.byIcon(Icons.download_done), findsOneWidget);
      tester.view.resetPhysicalSize();
    });

    testWidgets('desktop layout rendering', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000); // Desktop size
      tester.view.devicePixelRatio = 1.0;

      final mockItem = models.CartItemDetailModel(
        productId: 'p1',
        name: 'P',
        description: '',
        price: 10,
        imageUrls: [],
        quantity: 1,
        createdAt: DateTime.now(),
        sellerAddress: models.Address.empty(),
        sellerId: 's1',
        sellerName: 'S1',
      );
      final mockAddress = models.Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M 1M1', country: 'CA', isDefault: true);

      await tester.pumpWidget(buildTestWidget(items: [mockItem], total: 10.0, addresses: [mockAddress]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkout_summary_section')), findsOneWidget);
      tester.view.resetPhysicalSize();
    });
  });
}
