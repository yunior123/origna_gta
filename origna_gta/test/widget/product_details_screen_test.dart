import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/features/products/product_detail_viewmodel.dart';
import 'package:origna_gta/core/repositories/auth_repository.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/cart/cart_provider.dart';
import 'package:origna_gta/features/orders/orders_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/features/qa/qa_provider.dart';
import 'package:origna_gta/features/subscription/subscription_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/models.dart' as models;
import 'package:origna_gta/screens/productdetails_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';
@GenerateNiceMocks([
  MockSpec<CartController>(),
])
import 'product_details_screen_test.mocks.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> ensureUserDocumentExists() async {}

  @override
  Future<bool> isEmailVerified() async => true;

  @override
  Future<void> registerWithEmail(
    String email,
    String password,
    String name, {
    bool marketingOptIn = false,
  }) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> validateCurrentUser() async => true;

  @override
  Stream<models.UserModel?> watchProfile(String userId) => const Stream.empty();
}

void main() {
  late MockCartController mockCartController;

  setUp(() {
    mockCartController = MockCartController();

    SharedPreferences.setMockInitialValues({});
    initTestMocks();
  });

  final testProduct = Product(
    productId: 'p1',
    name: 'Honey',
    priceCents: 1000,
    imageUrls: const ['images/33.png'],
    description: 'Sweet honey from Canada.',
    sellerId: 's1',
    stockQuantity: 10,
    categoryId: 1,
    createdAt: DateTime.now(),
    isDigital: false,
    rating: 4.5,
    ratingCount: 10,
    isLocalDeliveryOnly: false,
    sellerAddress: const Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M 1M1', country: 'CA'),
  );
  const signedInUser = AppAuthUser(
    uid: 'u1',
    email: 'test@example.com',
    emailVerified: true,
  );
  final fakeAuthRepository = FakeAuthRepository();

  Widget createTestApp({required Widget child, List<Override> overrides = const []}) {
    return TestWrapper(
      overrides: [
        obUserIdProvider.overrideWithValue(null),
        obAuthStateProvider.overrideWith((ref) => const Stream.empty()),
        sellerMetricsProvider('s1').overrideWith((ref) => const Stream.empty()),
        sellerMetricsProvider('seller_123').overrideWith((ref) => const Stream.empty()),
        buyerOrdersProvider.overrideWith((ref) => Stream.value(const <Order>[])),
        similarProductsProvider((
          excludeProductId: 'p1',
          categoryId: 1,
        )).overrideWith((ref) => Future.value(const <Product>[])),
        ...overrides,
      ],
      child: child,
    );
  }

  group('ProductDetailScreen Comprehensive Tests', () {
    testWidgets('renders all product sections', (tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            productByIdProvider('p1').overrideWith((ref) => testProduct),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(models.UserModel(uid: 'u1', name: 'User', email: 'e', roles: const [UserRole.buyer], createdAt: DateTime.now())),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(signedInUser)),
            currentUserProvider.overrideWithValue(signedInUser),
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
            qaListProvider('p1').overrideWith((ref) => const Stream.empty()),
            productRatingsProvider('p1').overrideWith((ref) => const Stream.empty()),
            cartControllerProvider.overrideWithValue(mockCartController),
          ],
          child: const ProductDetailScreen(productId: 'p1'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Honey'), findsWidgets);
      expect(find.textContaining('Sweet honey'), findsOneWidget);
    });

    testWidgets('handles variant selection', (tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final variantProduct = testProduct.copyWith(
        hasVariants: true,
        variantOptions: const [
          VariantOption(name: 'Size', values: ['Small', 'Large']),
        ],
        variants: [
          const ProductVariant(variantId: 'v1', optionValues: {'Size': 'Small'}, priceCents: 1000, stockQuantity: 5, sku: 'S1'),
          const ProductVariant(variantId: 'v2', optionValues: {'Size': 'Large'}, priceCents: 1500, stockQuantity: 2, sku: 'L1'),
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            productByIdProvider('p1').overrideWith((ref) => variantProduct),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(models.UserModel(uid: 'u1', name: 'User', email: 'e', roles: const [UserRole.buyer], createdAt: DateTime.now())),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(signedInUser)),
            currentUserProvider.overrideWithValue(signedInUser),
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
            qaListProvider('p1').overrideWith((ref) => const Stream.empty()),
            productRatingsProvider('p1').overrideWith((ref) => const Stream.empty()),
            cartControllerProvider.overrideWithValue(mockCartController),
          ],
          child: const ProductDetailScreen(productId: 'p1'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final largeOption = find.text('Large');
      await tester.ensureVisible(largeOption);
      await tester.tap(largeOption);
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('15.00'), findsAtLeast(1));
    });

    testWidgets('add to cart interaction', (tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      when(mockCartController.addToCart(any, any, variantId: anyNamed('variantId'))).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            productByIdProvider('p1').overrideWith((ref) => testProduct),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(models.UserModel(uid: 'u1', name: 'User', email: 'e', roles: const [UserRole.buyer], createdAt: DateTime.now())),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(signedInUser)),
            currentUserProvider.overrideWithValue(signedInUser),
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            subscriptionStreamProvider.overrideWith((ref) => const Stream.empty()),
            qaListProvider('p1').overrideWith((ref) => const Stream.empty()),
            productRatingsProvider('p1').overrideWith((ref) => const Stream.empty()),
            cartControllerProvider.overrideWithValue(mockCartController),
          ],
          child: const ProductDetailScreen(productId: 'p1'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final cartBtn = find.byKey(const Key('product_add_to_cart_button'));
      await tester.ensureVisible(cartBtn);
      await tester.tap(cartBtn);
      await tester.pump(const Duration(seconds: 1));

      verify(mockCartController.addToCart('p1', 1, variantId: null)).called(1);
    });
  });
}
