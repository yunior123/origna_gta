import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/features/admin/tabs/admin_products_tab.dart';
import 'package:origna_gta/features/admin/admin_providers.dart';
import 'package:origna_gta/features/admin/admin_actions_viewmodel.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

import '../test_utils.dart';

class MockAdminRepository extends Fake implements AdminRepository {
  @override
  Stream<List<UserModel>> watchSellers({int limit = 50}) => Stream.value([]);

  @override
  Stream<List<UserModel>> watchUsers({int limit = 50}) => Stream.value([]);

  @override
  Stream<List<OrderModel>> watchOrders({String? status, int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<ProductModel>> watchProducts({
    int limit = 50,
    String? sellerId,
  }) => Stream.value([]);

  @override
  Stream<List<ProductModel>> watchPendingReviewProducts({int limit = 50}) =>
      Stream.value([]);

  @override
  Stream<List<Map<String, dynamic>>> watchReviews({
    bool flaggedOnly = false,
    bool hasPhotosOnly = false,
    int limit = 50,
  }) => Stream.value([]);

  @override
  Future<Map<String, dynamic>> getPaymentProviders() async => {
    'providers': {
      'stripe': {'enabled': true, 'configured': true, 'missingKeys': []},
    },
    'enabledProviders': ['stripe'],
  };

  @override
  Future<void> approveProduct(String productId) async {}

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<void> deleteReview(String reviewId) async {}

  @override
  Future<void> disableAdminMfa(String code) async {}

  @override
  Future<Map<String, dynamic>> enableAdminMfa() async => {
    ApiKeys.secret: 'test-secret',
    ApiKeys.provisioningUri: 'otpauth://totp/test',
    ApiKeys.backupCodes: ['code1', 'code2'],
  };

  @override
  Future<UserModel?> fetchUserById(String userId) async => null;

  @override
  Future<void> flagReview(String reviewId, {required bool flagged}) async {}

  @override
  Future<void> refundOrder(
    String orderId, {
    String reason = 'Admin refund',
  }) async {}

  @override
  Future<void> rejectProduct(String productId, String reason) async {}

  @override
  Future<void> setUserSuspended(String userId, bool suspended) async {}

  @override
  Future<void> updatePaymentProvider(
    String provider,
    bool enabled, {
    String? reason,
  }) async {}

  @override
  Future<void> updateProductStock(String productId, int quantity) async {}

  @override
  Future<void> updateUserRoles(
    String userId, {
    List<String> add = const [],
    List<String> remove = const [],
    String? reason,
  }) async {}

  @override
  Future<Map<String, dynamic>> verifyAdminMfa(String code) async => {
    'success': true,
  };
}

void main() {
  setUpAll(() {
    initTestMocks();
  });

  final testAddress = Address(
    street: '123 Main St',
    city: 'Toronto',
    state: 'ON',
    postalCode: 'M5V 3A8',
    country: 'Canada',
  );

  final testProduct = ProductModel(
    id: 'p1',
    name: 'Honey',
    priceCents: 1000,
    imageUrls: [],
    sellerAddress: testAddress,
    description: 'Sweet honey',
    sellerId: 's1',
    stockQuantity: 10,
    categoryId: 1,
    keywords: ['honey'],
    lifecycleStatus: ProductLifecycleStatusValues.active,
  );

  final mockAdminRepo = MockAdminRepository();

  Widget createTestWidget({List<ProductModel> products = const []}) {
    return TestWrapper(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
        adminProductsProvider(
          null,
        ).overrideWith((ref) => Stream.value(products)),
      ],
      child: const Scaffold(body: AdminProductsTab()),
    );
  }

  group('AdminProductsTab Widget Tests', () {
    testWidgets('renders search and filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders list of products', (tester) async {
      await tester.pumpWidget(createTestWidget(products: [testProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Honey'), findsOneWidget);
      expect(find.text('\$10.00'), findsOneWidget);
    });

    testWidgets('can filter by stock status', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final outOfStockProduct = ProductModel(
        id: 'p2',
        name: 'Sold Out',
        priceCents: 1000,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'None',
        sellerId: 's1',
        stockQuantity: 0,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.active,
      );

      await tester.pumpWidget(
        createTestWidget(products: [testProduct, outOfStockProduct]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Honey'), findsOneWidget);
      expect(find.text('Sold Out'), findsOneWidget);
    });

    testWidgets('can search for products', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final otherProduct = ProductModel(
        id: 'p2',
        name: 'Maple Syrup',
        priceCents: 1000,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'None',
        sellerId: 's1',
        stockQuantity: 10,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.active,
      );

      await tester.pumpWidget(
        createTestWidget(products: [testProduct, otherProduct]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), 'maple');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Honey'), findsNothing);
      expect(find.text('Maple Syrup'), findsOneWidget);
    });

    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(createTestWidget(products: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('renders product card with correct stock status', (
      tester,
    ) async {
      final lowStockProduct = ProductModel(
        id: 'p2',
        name: 'Low Stock Item',
        priceCents: 500,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Low',
        sellerId: 's1',
        stockQuantity: 3,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.active,
      );

      await tester.pumpWidget(createTestWidget(products: [lowStockProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Low Stock Item'), findsOneWidget);
    });

    testWidgets('renders product with pending review status', (tester) async {
      final pendingProduct = ProductModel(
        id: 'p3',
        name: 'Pending Product',
        priceCents: 2000,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Pending',
        sellerId: 's1',
        stockQuantity: 5,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.underReview,
      );

      await tester.pumpWidget(createTestWidget(products: [pendingProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pending Product'), findsOneWidget);
    });

    testWidgets('search clears with clear button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(products: [testProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('filter chips are tappable', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(products: [testProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('loading state renders correctly', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            adminProductsProvider(
              null,
            ).overrideWith((ref) => const Stream.empty()),
          ],
          child: const Scaffold(body: AdminProductsTab()),
        ),
      );
      await tester.pump();

      expect(find.byType(AdminProductsTab), findsOneWidget);
    });

    testWidgets('error state renders error message', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            adminRepositoryProvider.overrideWithValue(mockAdminRepo),
            adminProductsProvider(
              null,
            ).overrideWith((ref) => Stream.error('Error loading products')),
          ],
          child: const Scaffold(body: AdminProductsTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminProductsTab), findsOneWidget);
    });

    testWidgets('product card shows price correctly', (tester) async {
      final expensiveProduct = ProductModel(
        id: 'p4',
        name: 'Expensive Item',
        priceCents: 9999,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Expensive',
        sellerId: 's1',
        stockQuantity: 1,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.active,
      );

      await tester.pumpWidget(createTestWidget(products: [expensiveProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('\$99.99'), findsOneWidget);
    });

    testWidgets('renders multiple products', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final products = List.generate(
        5,
        (i) => ProductModel(
          id: 'p$i',
          name: 'Product $i',
          priceCents: (i + 1) * 1000,
          imageUrls: [],
          sellerAddress: testAddress,
          description: 'Product $i',
          sellerId: 's1',
          stockQuantity: i + 1,
          categoryId: 1,
          keywords: [],
          lifecycleStatus: ProductLifecycleStatusValues.active,
        ),
      );

      await tester.pumpWidget(createTestWidget(products: products));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Product 0'), findsOneWidget);
      expect(find.text('Product 4'), findsOneWidget);
    });

    testWidgets('rejected product shows rejected badge', (tester) async {
      final rejectedProduct = ProductModel(
        id: 'p5',
        name: 'Rejected Product',
        priceCents: 1500,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Rejected',
        sellerId: 's1',
        stockQuantity: 2,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.rejected,
      );

      await tester.pumpWidget(createTestWidget(products: [rejectedProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Rejected Product'), findsOneWidget);
    });

    testWidgets('product card has popup menu button', (tester) async {
      await tester.pumpWidget(createTestWidget(products: [testProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('out of stock product displays correctly', (tester) async {
      final outOfStock = ProductModel(
        id: 'p6',
        name: 'OutOfStock Item',
        priceCents: 500,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Empty',
        sellerId: 's1',
        stockQuantity: 0,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.active,
      );

      await tester.pumpWidget(createTestWidget(products: [outOfStock]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('OutOfStock Item'), findsOneWidget);
    });

    testWidgets('approved product shows approved badge', (tester) async {
      final approvedProduct = ProductModel(
        id: 'p7',
        name: 'Approved Product',
        priceCents: 2500,
        imageUrls: [],
        sellerAddress: testAddress,
        description: 'Approved',
        sellerId: 's1',
        stockQuantity: 15,
        categoryId: 1,
        keywords: [],
        lifecycleStatus: ProductLifecycleStatusValues.approved,
      );

      await tester.pumpWidget(createTestWidget(products: [approvedProduct]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Approved Product'), findsOneWidget);
    });
  });
}
