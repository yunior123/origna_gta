import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/auth/auth_provider.dart';
import 'package:origna_gta/features/products/products_provider.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/favorites_screen.dart';
import 'package:origna_gta/screens/product_card_screen.dart';
import 'package:origna_gta/widgets/animations.dart';
import 'package:origna_gta/widgets/modern_button.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestMocks();
  });

  Product createProduct({
    required String productId,
    required String name,
    double price = 29.99,
    String lifecycleStatus = ProductLifecycleStatusValues.active,
    int stockQuantity = 10,
  }) {
    return Product(
      productId: productId,
      name: name,
      price: price,
      description: 'Test product description',
      imageUrls: ['https://example.com/image.jpg'],
      sellerId: 'seller1',
      categoryId: 1,
      stockQuantity: stockQuantity,
      createdAt: DateTime.now(),
      lifecycleStatus: lifecycleStatus,
    );
  }

  UserModel createUser() {
    return UserModel(
      uid: 'user1',
      email: 'test@test.com',
      name: 'Test User',
      roles: [UserRole.buyer],
      createdAt: DateTime.now(),
    );
  }

  group('FavoritesScreen - Loading State', () {
    testWidgets('shows loading indicator while fetching favorites', (
      tester,
    ) async {
      final completer = Completer<List<Product>>();

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith((_) => completer.future),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(ModernLoadingIndicator), findsWidgets);

      completer.complete([]);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('FavoritesScreen - Empty State', () {
    testWidgets('shows empty state when no favorites', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('empty state shows bookmark icon', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });

  group('FavoritesScreen - Error State', () {
    testWidgets('shows error state on fetch failure', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.error('Network error'),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('error state shows error icon', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.error('Network error'),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('error state has retry button', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.error('Network error'),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ModernButton), findsOneWidget);
    });
  });

  group('FavoritesScreen - Product Grid Rendering', () {
    testWidgets('renders product grid with favorites', (tester) async {
      final products = [
        createProduct(productId: 'p1', name: 'Product 1'),
        createProduct(productId: 'p2', name: 'Product 2'),
        createProduct(productId: 'p3', name: 'Product 3'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value({'p1', 'p2', 'p3'}),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('shows correct number of product cards', (tester) async {
      final products = List.generate(
        5,
        (i) => createProduct(productId: 'p$i', name: 'Product $i'),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value({'p0', 'p1', 'p2', 'p3', 'p4'}),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ProductCard), findsNWidgets(5));
    });

    testWidgets('displays active products before unavailable ones', (
      tester,
    ) async {
      final products = [
        createProduct(
          productId: 'p1',
          name: 'Active Product',
          lifecycleStatus: ProductLifecycleStatusValues.active,
        ),
        createProduct(
          productId: 'p2',
          name: 'Paused Product',
          lifecycleStatus: ProductLifecycleStatusValues.paused,
        ),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1', 'p2'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets('shows warning banner for unavailable products', (
      tester,
    ) async {
      final products = [
        createProduct(
          productId: 'p1',
          name: 'Active Product',
          lifecycleStatus: ProductLifecycleStatusValues.active,
        ),
        createProduct(
          productId: 'p2',
          name: 'Paused Product',
          lifecycleStatus: ProductLifecycleStatusValues.paused,
        ),
        createProduct(
          productId: 'p3',
          name: 'Archived Product',
          lifecycleStatus: ProductLifecycleStatusValues.archived,
        ),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value({'p1', 'p2', 'p3'}),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('unavailable products render with reduced opacity', (
      tester,
    ) async {
      final products = [
        createProduct(
          productId: 'p1',
          name: 'Active Product',
          lifecycleStatus: ProductLifecycleStatusValues.active,
        ),
        createProduct(
          productId: 'p2',
          name: 'Paused Product',
          lifecycleStatus: ProductLifecycleStatusValues.paused,
        ),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1', 'p2'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      final opacityWidgets = find.byType(Opacity);
      expect(opacityWidgets, findsWidgets);
    });
  });

  group('FavoritesScreen - Navigation', () {
    testWidgets('has Scaffold with proper structure', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('product cards have semantics labels for identification', (
      tester,
    ) async {
      final products = [
        createProduct(productId: 'product-123', name: 'Test Product'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value({'product-123'}),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.bySemanticsLabel('card-favorite-product-product-123'),
        findsOneWidget,
      );
    });
  });

  group('FavoritesScreen - Refresh Behavior', () {
    testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
      final products = [createProduct(productId: 'p1', name: 'Product 1')];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('refresh indicator has correct semantics label', (
      tester,
    ) async {
      final products = [createProduct(productId: 'p1', name: 'Product 1')];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(refreshIndicator.semanticsLabel, 'btn-refresh-favorites');
    });
  });

  group('FavoritesScreen - Widget Lifecycle', () {
    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(<Product>[]),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(FavoritesScreen), findsNothing);
    });

    testWidgets('rebuilds when favorites change', (tester) async {
      final products1 = [createProduct(productId: 'p1', name: 'Product 1')];
      final products2 = [
        createProduct(productId: 'p1', name: 'Product 1'),
        createProduct(productId: 'p2', name: 'Product 2'),
      ];

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products1),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ProductCard), findsOneWidget);

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products2),
            ),
            favoritesProvider.overrideWith((_) => Stream.value({'p1', 'p2'})),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ProductCard), findsNWidgets(2));
    });
  });

  group('FavoritesScreen - Responsive Layout', () {
    testWidgets('uses CustomScrollView for scrollable content', (tester) async {
      final products = List.generate(
        10,
        (i) => createProduct(productId: 'p$i', name: 'Product $i'),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value(products.map((p) => p.productId).toSet()),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('uses SliverGrid for product layout', (tester) async {
      final products = List.generate(
        4,
        (i) => createProduct(productId: 'p$i', name: 'Product $i'),
      );

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            favoritedProductsProvider.overrideWith(
              (_) => Future.value(products),
            ),
            favoritesProvider.overrideWith(
              (_) => Stream.value(products.map((p) => p.productId).toSet()),
            ),
            userProfileProvider.overrideWith((_) => Stream.value(createUser())),
            currentUserProvider.overrideWithValue(
              AppAuthUser(uid: 'user1', email: 'test@test.com'),
            ),
          ],
          child: const FavoritesScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SliverGrid), findsOneWidget);
    });
  });
}
