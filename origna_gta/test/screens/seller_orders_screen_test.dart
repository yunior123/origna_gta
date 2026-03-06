import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/screens/seller_orders_screen.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/orders/seller_orders_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../test_utils.dart';

@GenerateNiceMocks([
  MockSpec<auth.User>(),
  MockSpec<SellerOrdersViewModel>(),
  MockSpec<NavigatorObserver>(),
])
import 'seller_orders_screen_test.mocks.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });

  late MockUser mockUser;
  late MockSellerOrdersViewModel mockViewModel;
  late MockNavigatorObserver mockNavigatorObserver;

  final testAddress = Address(
    street: '123 Main St',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5V 3A8',
    country: 'Canada',
  );

  final testUser = UserModel(
    uid: 'seller_123',
    email: 'seller@example.com',
    name: 'Test Seller',
    roles: ['seller'],
    createdAt: DateTime.now(),
    address: testAddress,
  );

  final testOrderItem = OrderItem(
    productId: 'prod_1',
    name: 'Test Product',
    price: 50.0,
    quantity: 2,
    sellerId: 'seller_123',
    status: 'pending',
    imageUrls: ['https://example.com/image.png'],
  );

  final testOrder = Order(
    orderId: 'order_123456789',
    buyerId: 'buyer_123',
    items: [testOrderItem],
    total: 113.0,
    subtotal: 100.0,
    taxTotal: 13.0,
    platformFeeTotal: 5.0,
    createdAt: DateTime.now(),
    orderStatus: OrderStatus.pending,
    paymentStatus: PaymentStatus.paid,
    shippingAddress: testAddress,
  );

  setUp(() {
    mockUser = MockUser();
    mockViewModel = MockSellerOrdersViewModel();
    mockNavigatorObserver = MockNavigatorObserver();
    when(mockUser.uid).thenReturn('seller_123');
    when(mockUser.email).thenReturn('seller@example.com');
    when(mockUser.displayName).thenReturn('Test Seller');
    
    // Default viewmodel state
    when(mockViewModel.state).thenReturn(const SellerOrdersState());
  });

  Widget createSellerOrdersScreen({
    List<Override> overrides = const [],
  }) {
    return TestWrapper(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        userProfileProvider.overrideWith((ref) => Stream.value(testUser)),
        sellerOrdersViewModelProvider.notifier.overrideWithValue(mockViewModel),
        ...overrides,
      ],
      navigatorObservers: [mockNavigatorObserver],
      child: const SellerOrdersScreen(),
    );
  }

  void setupScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
  }

  group('SellerOrdersScreen Tests', () {
    testWidgets('renders empty state correctly', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Manage Orders'), findsWidgets);
      expect(find.textContaining('No orders yet'), findsOneWidget);
    });

    testWidgets('renders loading state', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => const Stream.empty()),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      expect(find.byType(ModernLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders orders correctly', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([testOrder])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('ORDER_12345678'), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.textContaining('\$95.00'), findsOneWidget); // Net: 100 - 5% fee
      expect(find.textContaining('Total Earnings'), findsOneWidget);
    });

    testWidgets('shows unanswered Q&A badge when count > 0', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(5)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows authorization banner when payment status is awaitingPayment', (WidgetTester tester) async {
      final authOrder = testOrder.copyWith(paymentStatus: PaymentStatus.awaitingPayment, actualShipping: 0.0);
      
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([authOrder])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Payment Authorized'), findsOneWidget);
      expect(find.textContaining('Confirm Shipping & Ship'), findsOneWidget);
    });

    testWidgets('can open mark as shipped dialog', (WidgetTester tester) async {
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([testOrder])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final shipBtn = find.byTooltip('Mark as Shipped');
      expect(shipBtn, findsOneWidget);
      await tester.tap(shipBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Mark as Shipped'), findsWidgets);
      expect(find.textContaining('Carrier'), findsWidgets);
      expect(find.textContaining('Tracking Number'), findsWidgets);
    });

    testWidgets('shows account suspended message when user is suspended', (WidgetTester tester) async {
      final suspendedUser = testUser.copyWith(suspended: true);
      
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(suspendedUser)),
          sellerOrdersProvider.overrideWith((ref) => Stream.value([])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Account Suspended'), findsOneWidget);
    });

    testWidgets('renders digital product badge', (WidgetTester tester) async {
      final digitalItem = testOrderItem.copyWith(isDigital: true);
      final digitalOrder = testOrder.copyWith(items: [digitalItem]);
      
      setupScreenSize(tester);
      await tester.pumpWidget(createSellerOrdersScreen(
        overrides: [
          sellerOrdersProvider.overrideWith((ref) => Stream.value([digitalOrder])),
          sellerUnansweredQaProvider('seller_123').overrideWith((ref) => Stream.value(0)),
        ],
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Digital'), findsOneWidget);
      // Mark as shipped button should NOT be present for digital items
      expect(find.byTooltip('Mark as Shipped'), findsNothing);
    });
  });
}
