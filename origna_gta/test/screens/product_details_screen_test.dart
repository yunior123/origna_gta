import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/models.dart' as app_models;
import '../test_utils.dart';

void main() {
  setUpAll(() {
    initTestMocks();
  });
  const signedInUser = AppAuthUser(
    uid: 'test_user_123',
    email: 'test@example.com',
    emailVerified: true,
  );

  setUp(() {
  });

  group('ProductDetailScreen Smoke Test', () {
    testWidgets('renders product details correctly', (WidgetTester tester) async {
      // Use a very large size to avoid overflows in this complex screen
      tester.view.physicalSize = const Size(2000, 3000);
      tester.view.devicePixelRatio = 1.0;

      // Create a dummy product
      final testProduct = Product(
        productId: 'prod_123',
        name: 'Test Product',
        description: 'This is a test product description.',
        priceCents: 9999,
        sellerId: 'seller_123',
        categoryId: 1,
        imageUrls: const ['images/33.png'],
        stockQuantity: 10,
        rating: 4.5,
        ratingCount: 10,
        createdAt: DateTime.now(),
        isDigital: false,
        freeShipping: true,
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            obUserIdProvider.overrideWithValue(null),
            obAuthStateProvider.overrideWith((ref) => const Stream.empty()),
            sellerMetricsProvider('seller_123').overrideWith((ref) => const Stream.empty()),
            currentUserProvider.overrideWithValue(signedInUser),
            authStateProvider.overrideWith((ref) => Stream.value(signedInUser)),
            productByIdProvider('prod_123').overrideWith((ref) => Future.value(testProduct)),
            productRatingsProvider('prod_123').overrideWith((ref) => const Stream.empty()),
            qaListProvider('prod_123').overrideWith((ref) => const Stream.empty()),
            subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
            buyerOrdersProvider.overrideWith((ref) => Stream.value(const <Order>[])),
            similarProductsProvider((
              excludeProductId: 'prod_123',
              categoryId: 1,
            )).overrideWith((ref) => Future.value(const <Product>[])),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(
                app_models.UserModel(
                  uid: signedInUser.uid,
                  email: signedInUser.email ?? 'test@example.com',
                  name: 'Test User',
                  roles: const [UserRole.buyer],
                  createdAt: DateTime.now(),
                ),
              ),
            ),
          ],
          child: const ProductDetailScreen(productId: 'prod_123'),
        ),
      );

      // Use pump() instead of pumpAndSettle() due to infinite animations
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('\$99.99'), findsOneWidget);
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
